--[[
    MedaUI ReorderableList Widget
    ScrollList extension with drag-to-reorder support.
    Adds drag handle zones, a floating clone that follows cursor,
    and an insertion line indicator at the drop target position.
]]

local MedaUI = LibStub("MedaUI-2.0")
---@cast MedaUI MedaUILibrary
local Pixel = LibStub("MedaUI-2.0").Pixel

local DEFAULT_DRAG_HANDLE_WIDTH = 20
local DRAG_THRESHOLD = 4
local INSERTION_LINE_HEIGHT = 2

--- Create a reorderable scrolling list.
--- @param parent Frame Parent frame
--- @param width number List width
--- @param height number List height
--- @param config table Configuration
--- @return MedaUIReorderableList The reorderable list widget
---
--- Config keys:
---   rowHeight       (number, default 32)    -- row height
---   renderRow       (function)              -- function(row, data, index) renders a data row
---   onReorder       (function|nil)          -- function(data, fromIndex, toIndex) after reorder
---   dragEnabled     (boolean, default true) -- can be toggled for read-only views
---   dragHandleWidth (number, default 20)    -- width of the drag handle zone on the left
function MedaUI.CreateReorderableList(library, parent, width, height, config)
    config = config or {}
    local rowHeight = config.rowHeight or 32
    local dragHandleWidth = config.dragHandleWidth or DEFAULT_DRAG_HANDLE_WIDTH

    local list = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    ---@cast list MedaUIReorderableList
    Pixel.SetSize(list, width, height)
    list:SetBackdrop(library:CreateBackdrop(true))

    list.data = {}
    list.filteredData = nil
    list.filterFunc = nil
    list.rowHeight = rowHeight
    list.renderRow = config.renderRow
    list.rowPool = {}
    list.visibleRows = {}
    list._dragEnabled = config.dragEnabled ~= false
    list._onReorder = config.onReorder
    list._selectedIndex = nil

    -- Drag state
    list._dragging = false
    list._dragFromIndex = nil
    list._dragStartX = nil
    list._dragStartY = nil

    -- Scroll frame
    local scrollParent = library:CreateScrollFrame(list)
    Pixel.SetPoint(scrollParent, "TOPLEFT", 6, -6)
    Pixel.SetPoint(scrollParent, "BOTTOMRIGHT", -6, 6)
    scrollParent:SetScrollStep(rowHeight * 3)

    local scrollFrame = scrollParent.scrollFrame
    local content = scrollParent.scrollContent
    list.content = content
    list.scrollFrame = scrollFrame
    list.scrollParent = scrollParent

    local visibleRowCount = math.ceil(height / rowHeight) + 1

    -- Insertion line (shown at drop target)
    local insertLine = CreateFrame("Frame", nil, content)
    Pixel.SetHeight(insertLine, INSERTION_LINE_HEIGHT)
    Pixel.SetPoint(insertLine, "LEFT", 0, 0)
    Pixel.SetPoint(insertLine, "RIGHT", 0, 0)
    insertLine:SetFrameLevel(content:GetFrameLevel() + 10)
    local insertTex = insertLine:CreateTexture(nil, "OVERLAY")
    ---@cast insertTex Texture
    insertTex:SetAllPoints()
    insertLine._tex = insertTex
    insertLine:Hide()
    list._insertLine = insertLine

    -- Drag clone (floating copy that follows cursor)
    local dragClone = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    Pixel.SetSize(dragClone, width - 12, rowHeight)
    dragClone:SetBackdrop(MedaUI:CreateBackdrop(true))
    dragClone:SetFrameStrata("TOOLTIP")
    dragClone:SetAlpha(0.7)
    dragClone:Hide()
    list._dragClone = dragClone

    -- Theme
    local function ApplyTheme()
        local theme = MedaUI.Theme
        list:SetBackdropColor(unpack(theme.backgroundDark))
        list:SetBackdropBorderColor(unpack(theme.border))
        insertTex:SetColorTexture(unpack(theme.accent or theme.gold or {0.8, 0.8, 0.8, 1}))
        dragClone:SetBackdropColor(unpack(theme.backgroundLight))
        dragClone:SetBackdropBorderColor(unpack(theme.accent or theme.gold or {0.8, 0.8, 0.8, 1}))
    end
    list._ApplyTheme = ApplyTheme
    list._themeHandle = MedaUI:RegisterThemedWidget(list, function()
        ApplyTheme()
        list:Refresh()
    end)
    ApplyTheme()

    local function StopDragTracking()
        if list:GetScript("OnUpdate") then
            list:SetScript("OnUpdate", nil)
        end
    end

    local function CancelDrag()
        list._dragging = false
        list._dragPending = false
        list._dragFromIndex = nil
        list._dragTargetIndex = nil
        list._dragClone:Hide()
        list._insertLine:Hide()
        ResetCursor()
        StopDragTracking()
    end

    local function Drag_OnUpdate()
        if (not list._dragPending and not list._dragging) or not list:IsVisible() then
            CancelDrag()
            return
        end

        local cx, cy = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        cx, cy = cx / scale, cy / scale

        if list._dragPending and not list._dragging then
            local dx = math.abs(cx * scale - list._dragStartX)
            local dy = math.abs(cy * scale - list._dragStartY)
            if dx > DRAG_THRESHOLD or dy > DRAG_THRESHOLD then
                list._dragging = true
                list._dragPending = false
                list._dragClone:Show()

                local dataSource = list.filteredData or list.data
                local idx = list._dragFromIndex
                if idx and idx >= 1 and idx <= #dataSource and list.renderRow then
                    list.renderRow(list._dragClone, dataSource[idx], idx)
                end
            end
        end

        if not list._dragging then
            return
        end

        list._dragClone:ClearAllPoints()
        list._dragClone:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx, cy)

        local _, listY = content:GetCenter()
        local scrollPos = scrollFrame:GetVerticalScroll()
        local relY = (listY + (content:GetHeight() / 2)) - cy
        local targetIndex = math.floor((relY + scrollPos) / rowHeight) + 1
        local dataSource = list.filteredData or list.data
        targetIndex = math.max(1, math.min(targetIndex, #dataSource + 1))
        list._dragTargetIndex = targetIndex

        insertLine:ClearAllPoints()
        Pixel.SetPoint(insertLine, "TOPLEFT", content, "TOPLEFT", 0, -((targetIndex - 1) * rowHeight) + 1)
        Pixel.SetPoint(insertLine, "RIGHT", content, "RIGHT", 0, 0)
        insertLine:Show()
    end

    local function StartDragTracking()
        if list:GetScript("OnUpdate") then
            return
        end
        list:SetScript("OnUpdate", Drag_OnUpdate)
    end

    -- ----------------------------------------------------------------
    -- Row pool and rendering
    -- ----------------------------------------------------------------

    local function GetRow(slot)
        local row = list.rowPool[slot]
        if not row then
            row = CreateFrame("Frame", nil, content, "BackdropTemplate")
            ---@cast row MedaUIReorderableRow
            Pixel.SetHeight(row, rowHeight)
            Pixel.SetPoint(row, "RIGHT")
            row:SetBackdrop(MedaUI:CreateBackdrop(false))

            -- Drag handle zone (left strip with grip dots)
            local handle = CreateFrame("Frame", nil, row)
            Pixel.SetPoint(handle, "TOPLEFT", 0, 0)
            Pixel.SetPoint(handle, "BOTTOMLEFT", 0, 0)
            Pixel.SetWidth(handle, dragHandleWidth)
            handle:EnableMouse(true)

            local grip = handle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            ---@cast grip FontString
            grip:SetPoint("CENTER")
            grip:SetText("\226\139\174")  -- ⋮
            grip:SetTextColor(1, 1, 1, 0.25)
            row._grip = grip

            handle:SetScript("OnEnter", function()
                if list._dragEnabled then
                    grip:SetTextColor(1, 1, 1, 0.6)
                    SetCursor("Interface\\CURSOR\\UI-Cursor-Move")
                end
            end)
            handle:SetScript("OnLeave", function()
                grip:SetTextColor(1, 1, 1, 0.25)
                ResetCursor()
            end)

            handle:SetScript("OnMouseDown", function(_, button)
                if button == "LeftButton" and list._dragEnabled then
                    local x, y = GetCursorPosition()
                    list._dragStartX = x
                    list._dragStartY = y
                    list._dragFromIndex = row._dataIndex
                    list._dragPending = true
                    StartDragTracking()
                end
            end)

            handle:SetScript("OnMouseUp", function()
                if list._dragging then
                    list:_FinishDrag()
                    return
                end
                CancelDrag()
            end)

            row._handle = handle
            list.rowPool[slot] = row
        end
        return row
    end

    local function UpdateRows()
        local theme = MedaUI.Theme
        local dataSource = list.filteredData or list.data
        local totalHeight = #dataSource * rowHeight
        Pixel.SetHeight(content, math.max(totalHeight, height - 8))

        for _, r in ipairs(list.visibleRows) do r:Hide() end
        wipe(list.visibleRows)

        if #dataSource == 0 then return end

        local scrollPos = scrollFrame:GetVerticalScroll()
        local firstVisible = math.floor(scrollPos / rowHeight) + 1
        local lastVisible = math.min(firstVisible + visibleRowCount, #dataSource)

        local slot = 0
        for i = firstVisible, lastVisible do
            slot = slot + 1
            local row = GetRow(slot)
            row:ClearAllPoints()
            Pixel.SetPoint(row, "TOPLEFT", 0, -((i - 1) * rowHeight))
            Pixel.SetPoint(row, "RIGHT")

            if i % 2 == 0 then
                row:SetBackdropColor(unpack(theme.rowEven))
            else
                row:SetBackdropColor(unpack(theme.rowOdd))
            end

            row._dataIndex = i

            -- Show/hide grip based on drag state
            if list._dragEnabled then
                row._handle:Show()
                row._grip:Show()
            else
                row._handle:Hide()
                row._grip:Hide()
            end

            if list.renderRow then
                list.renderRow(row, dataSource[i], i)
            end

            row:Show()
            list.visibleRows[#list.visibleRows + 1] = row
        end
    end

    scrollFrame:HookScript("OnVerticalScroll", function()
        UpdateRows()
    end)

    -- ----------------------------------------------------------------
    -- Drag completion
    -- ----------------------------------------------------------------

    function list:_FinishDrag()
        local from = self._dragFromIndex
        local to = self._dragTargetIndex
        CancelDrag()
        if not from or not to or from == to or from == to - 1 then return end

        local dataSource = self.filteredData or self.data
        if from < 1 or from > #dataSource then return end

        local item = table.remove(dataSource, from)
        local insertAt = to > from and to - 1 or to
        table.insert(dataSource, insertAt, item)

        if self._onReorder then
            self._onReorder(dataSource, from, insertAt)
        end

        self:Refresh()
    end

    -- ----------------------------------------------------------------
    -- Public API
    -- ----------------------------------------------------------------

    function list:SetData(data)
        self.data = data or {}
        self.filteredData = nil
        if self.filterFunc then
            self:ApplyFilter()
        else
            UpdateRows()
        end
    end

    function list:GetData()
        return self.filteredData or self.data
    end

    function list:SetFilter(filterFunc)
        self.filterFunc = filterFunc
        self:ApplyFilter()
    end

    function list:ApplyFilter()
        if self.filterFunc then
            self.filteredData = {}
            for _, item in ipairs(self.data) do
                if self.filterFunc(item) then
                    self.filteredData[#self.filteredData + 1] = item
                end
            end
        else
            self.filteredData = nil
        end
        UpdateRows()
    end

    function list:ClearFilter()
        self.filterFunc = nil
        self.filteredData = nil
        UpdateRows()
    end

    function list:Refresh()
        if self.filterFunc then
            self:ApplyFilter()
        else
            UpdateRows()
        end
    end

    function list:ScrollToIndex(index)
        scrollParent:SetScroll((index - 1) * rowHeight)
    end

    function list:GetItemCount()
        return #(self.filteredData or self.data)
    end

    --- Toggle drag-to-reorder.
    --- @param enabled boolean
    function list:SetDragEnabled(enabled)
        self._dragEnabled = enabled
        if not enabled then
            CancelDrag()
        end
        self:Refresh()
    end

    --- Update the reorder callback.
    --- @param fn function|nil function(data, fromIndex, toIndex)
    function list:SetOnReorder(fn)
        self._onReorder = fn
    end

    --- Get/set selected index (for click-to-select behavior).
    function list:SetSelected(index)
        self._selectedIndex = index
        self:Refresh()
    end

    function list:GetSelected()
        return self._selectedIndex
    end

    list:HookScript("OnHide", CancelDrag)

    return list
end
