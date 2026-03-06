--[[
    MedaUI DataTable Widget
    Table with headers, columns, alternating rows, and selection support
]]

local MedaUI = LibStub("MedaUI-1.0")
local Pixel = LibStub("MedaUI-1.0").Pixel

local PLAIN_BACKDROP = { bgFile = "Interface\\Buttons\\WHITE8x8" }

local function Row_OnEnter(self)
    local Theme = MedaUI.Theme
    self:SetBackdropColor(unpack(Theme.highlight))
end

local function Row_OnLeave(self)
    local dt = self._dataTable
    if dt and dt.selectedRow == self then
        local Theme = MedaUI.Theme
        self:SetBackdropColor(unpack(Theme.highlight))
    else
        self:SetBackdropColor(unpack(self.bgColor))
    end
end

local function Row_OnClick(self)
    local dt = self._dataTable
    if not dt then return end
    local Theme = MedaUI.Theme

    if dt.selectable then
        if dt.selectedRow and dt.selectedRow ~= self then
            dt.selectedRow:SetBackdropColor(unpack(dt.selectedRow.bgColor))
        end
        dt.selectedRow = self
        self:SetBackdropColor(unpack(Theme.highlight))

        if dt.OnSelectionChanged then
            dt:OnSelectionChanged(self.data, self.dataIndex)
        end
    end

    if dt.OnRowClick then
        dt:OnRowClick(self, self.data, self.dataIndex)
    end
end

local function Row_OnDoubleClick(self)
    local dt = self._dataTable
    if dt and dt.OnRowDoubleClick then
        dt:OnRowDoubleClick(self, self.data, self.dataIndex)
    end
end

--- Create a data table widget
--- @param parent Frame The parent frame
--- @param width number Table width
--- @param height number Table height
--- @param config table|nil Configuration {columns, rowHeight, selectable, alternateColors, showHeaders}
--- @return table The data table widget
function MedaUI:CreateDataTable(parent, width, height, config)
    config = config or {}

    local table = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    Pixel.SetSize(table, width, height)
    table:SetBackdrop(self:CreateBackdrop(true))

    local Theme = self.Theme

    -- State
    table.columns = config.columns or {}
    table.rowHeight = config.rowHeight or 22
    table.selectable = config.selectable ~= false
    table.alternateColors = config.alternateColors ~= false
    table.showHeaders = config.showHeaders ~= false
    table.data = {}
    table.groups = {}
    table.selectedRow = nil
    table.rows = {}
    table.headerRow = nil

    -- Pools
    table._rowPool = {}
    table._groupHeaderPool = {}

    -- Callbacks
    table.OnRowClick = nil
    table.OnRowDoubleClick = nil
    table.OnSelectionChanged = nil

    -- Header height
    local headerHeight = table.showHeaders and 20 or 0

    -- Scroll frame (AF custom scrollbar)
    local scrollParent = self:CreateScrollFrame(table)
    Pixel.SetPoint(scrollParent, "TOPLEFT", 1, -(1 + headerHeight))
    Pixel.SetPoint(scrollParent, "BOTTOMRIGHT", -1, 1)
    scrollParent:SetScrollStep(66)
    table.scrollParent = scrollParent

    local scrollChild = scrollParent.scrollContent
    table.scrollChild = scrollChild

    -- Header row (if enabled)
    if table.showHeaders then
        local headerFrame = CreateFrame("Frame", nil, table, "BackdropTemplate")
        Pixel.SetHeight(headerFrame, headerHeight)
        Pixel.SetPoint(headerFrame, "TOPLEFT", 1, -1)
        Pixel.SetPoint(headerFrame, "TOPRIGHT", -1, -1)
        headerFrame:SetBackdrop(PLAIN_BACKDROP)
        table.headerRow = headerFrame
    end

    -- Apply theme
    local function ApplyTheme()
        local Theme = MedaUI.Theme
        table:SetBackdropColor(unpack(Theme.backgroundDark))
        table:SetBackdropBorderColor(unpack(Theme.border))

        if table.headerRow then
            table.headerRow:SetBackdropColor(unpack(Theme.rowHeader))
        end
    end
    table._ApplyTheme = ApplyTheme
    table._themeHandle = MedaUI:RegisterThemedWidget(table, ApplyTheme)
    ApplyTheme()

    --- Set the column definitions
    --- @param columns table Array of {key, label, width, align}
    function table:SetColumns(columns)
        self.columns = columns

        if self.headerRow then
            for _, child in ipairs({self.headerRow:GetRegions()}) do
                if child:GetObjectType() == "FontString" then
                    child:Hide()
                end
            end

            local xPos = 8
            for _, col in ipairs(columns) do
                local headerLabel = self.headerRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                Pixel.SetPoint(headerLabel, "LEFT", xPos, 0)
                Pixel.SetWidth(headerLabel, col.width - 5)
                headerLabel:SetJustifyH(col.align or "LEFT")
                headerLabel:SetText(col.label or col.key)
                headerLabel:SetTextColor(unpack(MedaUI.Theme.goldDim))
                xPos = xPos + col.width
            end
        end
    end

    --- Set the data to display
    --- @param data table Array of data objects
    function table:SetData(data)
        self.data = data
        self.groups = {}
        self:Refresh()
    end

    --- Add a group header and items
    --- @param headerText string Group header text
    --- @param items table Array of data items in this group
    function table:AddGroup(headerText, items)
        self.groups[#self.groups + 1] = {
            header = headerText,
            items = items,
        }
    end

    --- Clear all data and groups
    function table:Clear()
        self.data = {}
        self.groups = {}
        self.selectedRow = nil
        self:Refresh()
    end

    local function AcquireRow(dt)
        local row = tremove(dt._rowPool)
        if row then
            row:SetParent(dt.scrollChild)
            row:Show()
            return row
        end

        row = CreateFrame("Button", nil, dt.scrollChild, "BackdropTemplate")
        row:SetBackdrop(PLAIN_BACKDROP)
        row._dataTable = dt
        row._cells = {}
        row:SetScript("OnEnter", Row_OnEnter)
        row:SetScript("OnLeave", Row_OnLeave)
        row:SetScript("OnClick", Row_OnClick)
        row:SetScript("OnDoubleClick", Row_OnDoubleClick)
        return row
    end

    local function AcquireGroupHeader(dt)
        local hdr = tremove(dt._groupHeaderPool)
        if hdr then
            hdr:SetParent(dt.scrollChild)
            hdr:Show()
            return hdr
        end

        hdr = CreateFrame("Frame", nil, dt.scrollChild, "BackdropTemplate")
        hdr:SetBackdrop(PLAIN_BACKDROP)
        hdr._isGroupHeader = true
        hdr._text = hdr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        Pixel.SetPoint(hdr._text, "LEFT", 8, 0)
        return hdr
    end

    local function ReleaseRows(dt)
        for i = #dt.rows, 1, -1 do
            local row = dt.rows[i]
            row:Hide()
            row:ClearAllPoints()
            if row._isGroupHeader then
                dt._groupHeaderPool[#dt._groupHeaderPool + 1] = row
            else
                dt._rowPool[#dt._rowPool + 1] = row
            end
            dt.rows[i] = nil
        end
    end

    local function PopulateRow(dt, row, data, index, yOffset)
        local Theme = MedaUI.Theme
        local columns = dt.columns

        Pixel.SetSize(row, dt.scrollChild:GetWidth(), dt.rowHeight)
        Pixel.SetPoint(row, "TOPLEFT", 0, yOffset)

        row.data = data
        row.dataIndex = index
        row.bgColor = (dt.alternateColors and index % 2 == 0) and Theme.rowEven or Theme.rowOdd
        row:SetBackdropColor(unpack(row.bgColor))

        local numCols = #columns
        for ci = 1, numCols do
            local col = columns[ci]
            local cellText = row._cells[ci]
            if not cellText then
                cellText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                row._cells[ci] = cellText
            end

            local xPos = 8
            for k = 1, ci - 1 do xPos = xPos + columns[k].width end

            cellText:ClearAllPoints()
            Pixel.SetPoint(cellText, "LEFT", xPos, 0)
            Pixel.SetWidth(cellText, col.width - 5)
            cellText:SetJustifyH(col.align or "LEFT")

            local value = data[col.key] or ""
            cellText:SetText(tostring(value))

            if col.colorKey and data[col.colorKey] then
                local color = data[col.colorKey]
                if type(color) == "table" then
                    cellText:SetTextColor(unpack(color))
                end
            elseif col.color then
                cellText:SetTextColor(unpack(col.color))
            else
                cellText:SetTextColor(unpack(Theme.text))
            end

            cellText:Show()
        end

        -- Hide excess cells from a previous column layout
        for ci = numCols + 1, #row._cells do
            row._cells[ci]:Hide()
        end
    end

    --- Refresh the display
    function table:Refresh()
        local Theme = MedaUI.Theme

        ReleaseRows(self)

        local yOffset = 0
        local rowIndex = 0

        if #self.groups > 0 then
            for _, group in ipairs(self.groups) do
                local groupHeader = AcquireGroupHeader(self)
                Pixel.SetSize(groupHeader, self.scrollChild:GetWidth(), self.rowHeight + 4)
                Pixel.SetPoint(groupHeader, "TOPLEFT", 0, yOffset)
                groupHeader:SetBackdropColor(unpack(Theme.rowHeader))
                groupHeader._text:SetText(group.header)
                groupHeader._text:SetTextColor(unpack(Theme.gold))

                self.rows[#self.rows + 1] = groupHeader
                yOffset = yOffset - (self.rowHeight + 4)

                for _, item in ipairs(group.items) do
                    rowIndex = rowIndex + 1
                    local row = AcquireRow(self)
                    PopulateRow(self, row, item, rowIndex, yOffset)
                    self.rows[#self.rows + 1] = row
                    yOffset = yOffset - self.rowHeight
                end

                yOffset = yOffset - 8
            end
        else
            for _, item in ipairs(self.data) do
                rowIndex = rowIndex + 1
                local row = AcquireRow(self)
                PopulateRow(self, row, item, rowIndex, yOffset)
                self.rows[#self.rows + 1] = row
                yOffset = yOffset - self.rowHeight
            end
        end

        Pixel.SetHeight(self.scrollChild, math.abs(yOffset) + 10)
    end

    --- Get the selected row data
    --- @return table|nil The selected row data
    function table:GetSelected()
        if self.selectedRow then
            return self.selectedRow.data
        end
        return nil
    end

    --- Select a row by index
    --- @param index number The row index to select
    function table:SelectRow(index)
        for _, row in ipairs(self.rows) do
            if row.dataIndex == index then
                row:Click()
                break
            end
        end
    end

    --- Scroll to a specific row
    --- @param index number The row index to scroll to
    function table:ScrollToRow(index)
        local yPos = (index - 1) * self.rowHeight
        scrollParent:SetScroll(yPos)
    end

    return table
end
