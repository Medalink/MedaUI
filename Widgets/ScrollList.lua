--[[
    MedaUI ScrollList Widget
    Virtualized scrolling list for large datasets
]]

local MedaUI = LibStub("MedaUI-1.0")
local Pixel = LibStub("MedaUI-1.0").Pixel

--- Create a scrollable list
--- @param parent Frame Parent frame
--- @param width number List width
--- @param height number List height
--- @param config table Configuration {rowHeight, renderRow}
--- @return Frame The scroll list frame
function MedaUI:CreateScrollList(parent, width, height, config)
    config = config or {}
    local rowHeight = config.rowHeight or 24
    local renderRow = config.renderRow

    local scrollList = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    Pixel.SetSize(scrollList, width, height)
    scrollList:SetBackdrop(self:CreateBackdrop(true))

    scrollList.data = {}
    scrollList.filteredData = nil
    scrollList.filterFunc = nil
    scrollList.rowHeight = rowHeight
    scrollList.renderRow = renderRow
    scrollList.rowPool = {}
    scrollList.visibleRows = {}
    scrollList.scrollOffset = 0

    -- Scroll frame (AF custom scrollbar)
    local scrollParent = self:CreateScrollFrame(scrollList)
    Pixel.SetPoint(scrollParent, "TOPLEFT", 6, -6)
    Pixel.SetPoint(scrollParent, "BOTTOMRIGHT", -6, 6)
    scrollParent:SetScrollStep(rowHeight * 3)

    local scrollFrame = scrollParent.scrollFrame
    local content = scrollParent.scrollContent
    scrollList.content = content
    scrollList.scrollFrame = scrollFrame
    scrollList.scrollParent = scrollParent

    -- Calculate visible rows
    local visibleRowCount = math.ceil(height / rowHeight) + 1

    -- Apply theme colors
    local function ApplyTheme()
        local Theme = MedaUI.Theme
        scrollList:SetBackdropColor(unpack(Theme.backgroundDark))
        scrollList:SetBackdropBorderColor(unpack(Theme.border))
    end
    scrollList._ApplyTheme = ApplyTheme

    -- Register for theme updates
    scrollList._themeHandle = MedaUI:RegisterThemedWidget(scrollList, function()
        ApplyTheme()
        -- Re-render visible rows with new theme
        scrollList:Refresh()
    end)

    -- Initial theme application
    ApplyTheme()

    -- Slot-based row pool: keyed by visible slot (1..visibleRowCount+1), not data index
    local function GetRow(slot)
        local row = scrollList.rowPool[slot]
        if not row then
            row = CreateFrame("Frame", nil, content, "BackdropTemplate")
            Pixel.SetHeight(row, rowHeight)
            Pixel.SetPoint(row, "RIGHT")
            row:SetBackdrop(MedaUI:CreateBackdrop(false))
            scrollList.rowPool[slot] = row
        end
        return row
    end

    -- Update visible rows
    local function UpdateRows()
        local Theme = MedaUI.Theme
        local dataSource = scrollList.filteredData or scrollList.data
        local totalHeight = #dataSource * rowHeight
        Pixel.SetHeight(content, math.max(totalHeight, height - 8))

        -- Hide all rows first
        for _, row in ipairs(scrollList.visibleRows) do
            row:Hide()
        end
        wipe(scrollList.visibleRows)

        if #dataSource == 0 then return end

        -- Get scroll position
        local scrollPos = scrollFrame:GetVerticalScroll()
        local firstVisible = math.floor(scrollPos / rowHeight) + 1
        local lastVisible = math.min(firstVisible + visibleRowCount, #dataSource)

        -- Show and render visible rows using slot-based pool
        local slot = 0
        for i = firstVisible, lastVisible do
            slot = slot + 1
            local row = GetRow(slot)
            row:ClearAllPoints()
            Pixel.SetPoint(row, "TOPLEFT", 0, -((i - 1) * rowHeight))
            Pixel.SetPoint(row, "RIGHT")

            -- Alternating row colors
            if i % 2 == 0 then
                row:SetBackdropColor(unpack(Theme.rowEven))
            else
                row:SetBackdropColor(unpack(Theme.rowOdd))
            end

            -- Render row content
            if scrollList.renderRow then
                scrollList.renderRow(row, dataSource[i], i)
            end

            row:Show()
            scrollList.visibleRows[#scrollList.visibleRows + 1] = row
        end
    end

    -- Scroll event (hook AF's existing OnVerticalScroll)
    scrollFrame:HookScript("OnVerticalScroll", function()
        UpdateRows()
    end)

    --- Set the data source
    --- @param data table Array of items
    function scrollList:SetData(data)
        self.data = data or {}
        self.filteredData = nil
        if self.filterFunc then
            self:ApplyFilter()
        else
            UpdateRows()
        end
    end

    --- Get the current data
    --- @return table The data array
    function scrollList:GetData()
        return self.filteredData or self.data
    end

    --- Set a filter function
    --- @param filterFunc function|nil Filter function(item) returns bool
    function scrollList:SetFilter(filterFunc)
        self.filterFunc = filterFunc
        self:ApplyFilter()
    end

    --- Apply the current filter
    function scrollList:ApplyFilter()
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

    --- Clear the filter
    function scrollList:ClearFilter()
        self.filterFunc = nil
        self.filteredData = nil
        UpdateRows()
    end

    --- Refresh the display
    function scrollList:Refresh()
        if self.filterFunc then
            self:ApplyFilter()
        else
            UpdateRows()
        end
    end

    --- Scroll to bottom
    function scrollList:ScrollToBottom()
        scrollParent:ScrollToBottom()
    end

    --- Scroll to top
    function scrollList:ScrollToTop()
        scrollParent:ResetScroll()
    end

    --- Scroll to a specific index
    --- @param index number The index to scroll to
    function scrollList:ScrollToIndex(index)
        local scrollPos = (index - 1) * rowHeight
        scrollParent:SetScroll(scrollPos)
    end

    --- Get the visible range
    --- @return number, number First and last visible indices
    function scrollList:GetVisibleRange()
        local dataSource = self.filteredData or self.data
        local scrollPos = scrollFrame:GetVerticalScroll()
        local firstVisible = math.floor(scrollPos / rowHeight) + 1
        local lastVisible = math.min(firstVisible + visibleRowCount - 1, #dataSource)
        return firstVisible, lastVisible
    end

    --- Add an item to the data
    --- @param item any The item to add
    --- @param scrollToNew boolean Whether to scroll to the new item
    function scrollList:AddItem(item, scrollToNew)
        self.data[#self.data + 1] = item
        if self.filterFunc then
            self:ApplyFilter()
        else
            UpdateRows()
        end
        if scrollToNew then
            self:ScrollToBottom()
        end
    end

    --- Clear all data
    function scrollList:Clear()
        wipe(self.data)
        self.filteredData = nil
        UpdateRows()
    end

    --- Get item count
    --- @return number The number of items (filtered if filter active)
    function scrollList:GetItemCount()
        local dataSource = self.filteredData or self.data
        return #dataSource
    end

    return scrollList
end
