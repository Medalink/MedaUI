--[[
    MedaUI ScrollList Widget
    Virtualized scrolling list for large datasets
]]

local MedaUI = LibStub("MedaUI-2.0")
local Pixel = LibStub("MedaUI-2.0").Pixel

--- Create a scrollable list
--- @param parent Frame Parent frame
--- @param width number List width
--- @param height number List height
--- @param config table Configuration {rowHeight, renderRow}
--- @return Frame The scroll list frame
function MedaUI.CreateScrollList(ui, parent, width, height, config)
    config = config or {}
    local rowHeight = config.rowHeight or 24
    local renderRow = config.renderRow
    local safeRender = config.safeRender and true or false

    local scrollList = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    Pixel.SetSize(scrollList, width, height)
    scrollList:SetBackdrop(ui:CreateBackdrop(true))

    scrollList.data = {}
    scrollList.filteredData = nil
    scrollList.filterFunc = nil
    scrollList.rowHeight = rowHeight
    scrollList.renderRow = renderRow
    scrollList.rowPool = {}
    scrollList.freeRows = {}
    scrollList.visibleRows = {}
    scrollList.visibleRowsByIndex = {}
    scrollList.scrollOffset = 0
    scrollList._lastFirstVisible = nil
    scrollList._lastLastVisible = nil
    scrollList._lastContentWidth = nil
    scrollList._lastContentHeight = nil
    scrollList._needsRender = true

    -- Scroll frame (AF custom scrollbar)
    local scrollParent = ui:CreateScrollFrame(scrollList)
    Pixel.SetPoint(scrollParent, "TOPLEFT", 6, -6)
    Pixel.SetPoint(scrollParent, "BOTTOMRIGHT", -6, 6)
    scrollParent:SetScrollStep(rowHeight * 3)

    local scrollFrame = scrollParent.scrollFrame
    local content = scrollParent.scrollContent
    scrollList.content = content
    scrollList.scrollFrame = scrollFrame
    scrollList.scrollParent = scrollParent

    local function GetLayoutMetrics()
        local currentHeight = scrollList:GetHeight()
        if not currentHeight or currentHeight <= 0 then
            currentHeight = height
        end

        local visibleRowCount = math.ceil(currentHeight / rowHeight) + 1
        return currentHeight, visibleRowCount
    end

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
    local releaseIndexScratch = {}

    local function AcquireRow()
        local row = table.remove(scrollList.freeRows)
        if not row then
            row = CreateFrame("Frame", nil, content, "BackdropTemplate")
            Pixel.SetHeight(row, rowHeight)
            row:SetBackdrop(MedaUI:CreateBackdrop(false))
            scrollList.rowPool[#scrollList.rowPool + 1] = row
        end
        return row
    end

    local function RebuildVisibleRows(firstVisible, lastVisible)
        wipe(scrollList.visibleRows)
        for i = firstVisible, lastVisible do
            local row = scrollList.visibleRowsByIndex[i]
            if row then
                scrollList.visibleRows[#scrollList.visibleRows + 1] = row
            end
        end
    end

    local function ReleaseRow(index)
        local row = scrollList.visibleRowsByIndex[index]
        if not row then
            return
        end

        scrollList.visibleRowsByIndex[index] = nil
        row._dataIndex = nil
        row._dataRef = nil
        row:Hide()
        scrollList.freeRows[#scrollList.freeRows + 1] = row
    end

    local function ReleaseAllRows()
        local count = 0
        for index in pairs(scrollList.visibleRowsByIndex) do
            count = count + 1
            releaseIndexScratch[count] = index
        end
        for i = 1, count do
            ReleaseRow(releaseIndexScratch[i])
            releaseIndexScratch[i] = nil
        end
        wipe(scrollList.visibleRows)
    end

    local function ApplyRowFrame(row, index, theme, force)
        if row._dataIndex ~= index or force then
            row:ClearAllPoints()
            Pixel.SetPoint(row, "TOPLEFT", 0, -((index - 1) * rowHeight))
            Pixel.SetPoint(row, "TOPRIGHT", 0, -((index - 1) * rowHeight))
            Pixel.SetHeight(row, rowHeight)
        end

        local isEven = (index % 2 == 0)
        if force or row._isEven ~= isEven then
            if isEven then
                row:SetBackdropColor(unpack(theme.rowEven))
            else
                row:SetBackdropColor(unpack(theme.rowOdd))
            end
            row._isEven = isEven
        end
    end

    local function RenderRowContent(row, data, index, theme)
        if not scrollList.renderRow then
            return
        end

        if safeRender then
            local ok, err = pcall(scrollList.renderRow, row, data, index)
            if not ok then
                if not row.renderErrorText then
                    row.renderErrorText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    row.renderErrorText:SetPoint("TOPLEFT", 8, -6)
                    row.renderErrorText:SetPoint("TOPRIGHT", -8, -6)
                    row.renderErrorText:SetJustifyH("LEFT")
                    row.renderErrorText:SetWordWrap(true)
                end
                row.renderErrorText:SetText("Row render failed: " .. tostring(err))
                row.renderErrorText:SetTextColor(unpack(theme.levelError or { 1, 0.3, 0.3, 1 }))
                row.renderErrorText:Show()
            elseif row.renderErrorText then
                row.renderErrorText:Hide()
            end
        else
            if row.renderErrorText then
                row.renderErrorText:Hide()
            end
            scrollList.renderRow(row, data, index)
        end
    end

    local function UpdateRows(force)
        local Theme = MedaUI.Theme
        local dataSource = scrollList.filteredData or scrollList.data
        local currentHeight, visibleRowCount = GetLayoutMetrics()
        local currentWidth = scrollFrame:GetWidth()
        if currentWidth and currentWidth > 0 then
            if scrollList._lastContentWidth ~= currentWidth then
                content:SetWidth(currentWidth)
                scrollList._lastContentWidth = currentWidth
                force = true
            end
        end
        local totalHeight = #dataSource * rowHeight
        local contentHeight = math.max(totalHeight, currentHeight - 8)
        if scrollList._lastContentHeight ~= contentHeight then
            Pixel.SetHeight(content, contentHeight)
            scrollList._lastContentHeight = contentHeight
        end

        if #dataSource == 0 then
            ReleaseAllRows()
            scrollList._lastFirstVisible = nil
            scrollList._lastLastVisible = nil
            scrollList._needsRender = false
            return
        end

        -- Get scroll position
        local scrollPos = scrollFrame:GetVerticalScroll()
        local firstVisible = math.floor(scrollPos / rowHeight) + 1
        local lastVisible = math.min(firstVisible + visibleRowCount, #dataSource)

        if not force
            and not scrollList._needsRender
            and scrollList._lastFirstVisible == firstVisible
            and scrollList._lastLastVisible == lastVisible then
            return
        end

        local releaseCount = 0
        for index in pairs(scrollList.visibleRowsByIndex) do
            if index < firstVisible or index > lastVisible then
                releaseCount = releaseCount + 1
                releaseIndexScratch[releaseCount] = index
            end
        end
        for i = 1, releaseCount do
            ReleaseRow(releaseIndexScratch[i])
            releaseIndexScratch[i] = nil
        end

        for i = firstVisible, lastVisible do
            local row = scrollList.visibleRowsByIndex[i]
            local data = dataSource[i]
            local needsRender = force or scrollList._needsRender

            if not row then
                row = AcquireRow()
                scrollList.visibleRowsByIndex[i] = row
                needsRender = true
            end

            ApplyRowFrame(row, i, Theme, force)

            if needsRender or row._dataRef ~= data then
                RenderRowContent(row, data, i, Theme)
            end

            row._dataIndex = i
            row._dataRef = data
            row:Show()
        end

        RebuildVisibleRows(firstVisible, lastVisible)

        scrollList._lastFirstVisible = firstVisible
        scrollList._lastLastVisible = lastVisible
        scrollList._needsRender = false
    end

    -- Scroll event (hook AF's existing OnVerticalScroll)
    scrollFrame:HookScript("OnVerticalScroll", function()
        UpdateRows()
    end)

    scrollList:SetScript("OnSizeChanged", function()
        UpdateRows()
    end)

    --- Set the data source
    --- @param data table Array of items
    function scrollList:SetData(data)
        scrollList.data = data or {}
        scrollList.filteredData = nil
        scrollList._needsRender = true
        if scrollList.filterFunc then
            scrollList:ApplyFilter()
        else
            UpdateRows(true)
        end
    end

    --- Get the current data
    --- @return table The data array
    function scrollList:GetData()
        return scrollList.filteredData or scrollList.data
    end

    --- Set a filter function
    --- @param filterFunc function|nil Filter function(item) returns bool
    function scrollList:SetFilter(filterFunc)
        scrollList.filterFunc = filterFunc
        scrollList:ApplyFilter()
    end

    --- Apply the current filter
    function scrollList:ApplyFilter()
        if scrollList.filterFunc then
            scrollList.filteredData = {}
            for _, item in ipairs(scrollList.data) do
                if scrollList.filterFunc(item) then
                    scrollList.filteredData[#scrollList.filteredData + 1] = item
                end
            end
        else
            scrollList.filteredData = nil
        end
        scrollList._needsRender = true
        UpdateRows(true)
    end

    --- Clear the filter
    function scrollList:ClearFilter()
        scrollList.filterFunc = nil
        scrollList.filteredData = nil
        scrollList._needsRender = true
        UpdateRows(true)
    end

    --- Refresh the display
    function scrollList:Refresh()
        if scrollList.filterFunc then
            scrollList:ApplyFilter()
        else
            scrollList._needsRender = true
            UpdateRows(true)
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
        local dataSource = scrollList.filteredData or scrollList.data
        local scrollPos = scrollFrame:GetVerticalScroll()
        local _, visibleRowCount = GetLayoutMetrics()
        local firstVisible = math.floor(scrollPos / rowHeight) + 1
        local lastVisible = math.min(firstVisible + visibleRowCount - 1, #dataSource)
        return firstVisible, lastVisible
    end

    --- Add an item to the data
    --- @param item any The item to add
    --- @param scrollToNew boolean Whether to scroll to the new item
    function scrollList:AddItem(item, scrollToNew)
        scrollList.data[#scrollList.data + 1] = item
        if scrollList.filterFunc then
            scrollList._needsRender = true
            scrollList:ApplyFilter()
        else
            UpdateRows(scrollToNew and true or false)
        end
        if scrollToNew then
            self:ScrollToBottom()
        end
    end

    --- Clear all data
    function scrollList:Clear()
        wipe(scrollList.data)
        scrollList.filteredData = nil
        scrollList._needsRender = true
        ReleaseAllRows()
        UpdateRows(true)
    end

    --- Get item count
    --- @return number The number of items (filtered if filter active)
    function scrollList:GetItemCount()
        local dataSource = scrollList.filteredData or scrollList.data
        return #dataSource
    end

    return scrollList
end
