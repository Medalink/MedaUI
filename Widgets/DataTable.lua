--[[
    MedaUI DataTable Widget
    Table with headers, columns, alternating rows, and selection support
]]

local MedaUI = LibStub("MedaUI-1.0")

--- Create a data table widget
--- @param parent Frame The parent frame
--- @param width number Table width
--- @param height number Table height
--- @param config table|nil Configuration {columns, rowHeight, selectable, alternateColors, showHeaders}
--- @return table The data table widget
function MedaUI:CreateDataTable(parent, width, height, config)
    config = config or {}

    local table = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    table:SetSize(width, height)
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

    -- Callbacks
    table.OnRowClick = nil
    table.OnRowDoubleClick = nil
    table.OnSelectionChanged = nil

    -- Header height
    local headerHeight = table.showHeaders and 20 or 0

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, table, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 1, -(1 + headerHeight))
    scrollFrame:SetPoint("BOTTOMRIGHT", -22, 1)
    table.scrollFrame = scrollFrame

    -- Scroll child
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(width - 24, 1)
    scrollFrame:SetScrollChild(scrollChild)
    table.scrollChild = scrollChild

    -- Header row (if enabled)
    if table.showHeaders then
        local headerFrame = CreateFrame("Frame", nil, table, "BackdropTemplate")
        headerFrame:SetHeight(headerHeight)
        headerFrame:SetPoint("TOPLEFT", 1, -1)
        headerFrame:SetPoint("TOPRIGHT", -22, -1)
        headerFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
        })
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

        -- Update header if visible
        if self.headerRow then
            -- Clear existing header labels
            for _, child in ipairs({self.headerRow:GetRegions()}) do
                if child:GetObjectType() == "FontString" then
                    child:Hide()
                end
            end

            -- Create new header labels
            local xPos = 8
            for _, col in ipairs(columns) do
                local headerLabel = self.headerRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                headerLabel:SetPoint("LEFT", xPos, 0)
                headerLabel:SetWidth(col.width - 5)
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

    --- Refresh the display
    function table:Refresh()
        local Theme = MedaUI.Theme

        -- Clear existing rows
        for _, row in ipairs(self.rows) do
            row:Hide()
            row:SetParent(nil)
        end
        wipe(self.rows)

        local yOffset = 0
        local rowIndex = 0

        -- Render grouped data
        if #self.groups > 0 then
            for _, group in ipairs(self.groups) do
                -- Group header
                local groupHeader = CreateFrame("Frame", nil, self.scrollChild, "BackdropTemplate")
                groupHeader:SetSize(self.scrollChild:GetWidth(), self.rowHeight + 4)
                groupHeader:SetPoint("TOPLEFT", 0, yOffset)
                groupHeader:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8x8",
                })
                groupHeader:SetBackdropColor(unpack(Theme.rowHeader))

                local headerText = groupHeader:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                headerText:SetPoint("LEFT", 8, 0)
                headerText:SetText(group.header)
                headerText:SetTextColor(unpack(Theme.gold))

                self.rows[#self.rows + 1] = groupHeader
                yOffset = yOffset - (self.rowHeight + 4)

                -- Group items
                for _, item in ipairs(group.items) do
                    rowIndex = rowIndex + 1
                    local row = self:CreateRow(item, rowIndex, yOffset)
                    self.rows[#self.rows + 1] = row
                    yOffset = yOffset - self.rowHeight
                end

                yOffset = yOffset - 8  -- Gap between groups
            end
        else
            -- Render flat data
            for _, item in ipairs(self.data) do
                rowIndex = rowIndex + 1
                local row = self:CreateRow(item, rowIndex, yOffset)
                self.rows[#self.rows + 1] = row
                yOffset = yOffset - self.rowHeight
            end
        end

        -- Update scroll child height
        self.scrollChild:SetHeight(math.abs(yOffset) + 10)
    end

    --- Create a data row
    --- @param data table The data for this row
    --- @param index number The row index (1-based)
    --- @param yOffset number The Y position
    --- @return Frame The row frame
    function table:CreateRow(data, index, yOffset)
        local Theme = MedaUI.Theme

        local row = CreateFrame("Button", nil, self.scrollChild, "BackdropTemplate")
        row:SetSize(self.scrollChild:GetWidth(), self.rowHeight)
        row:SetPoint("TOPLEFT", 0, yOffset)
        row:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
        })

        -- Alternating row colors
        if self.alternateColors then
            if index % 2 == 0 then
                row:SetBackdropColor(unpack(Theme.rowEven))
            else
                row:SetBackdropColor(unpack(Theme.rowOdd))
            end
        else
            row:SetBackdropColor(unpack(Theme.rowOdd))
        end

        -- Store data reference and index
        row.data = data
        row.dataIndex = index
        row.bgColor = index % 2 == 0 and Theme.rowEven or Theme.rowOdd

        -- Create column cells
        local xPos = 8
        for _, col in ipairs(self.columns) do
            local cellText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            cellText:SetPoint("LEFT", xPos, 0)
            cellText:SetWidth(col.width - 5)
            cellText:SetJustifyH(col.align or "LEFT")

            local value = data[col.key] or ""
            cellText:SetText(tostring(value))

            -- Apply column-specific color if defined
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

            xPos = xPos + col.width
        end

        -- Hover effect
        row:SetScript("OnEnter", function(self)
            self:SetBackdropColor(unpack(Theme.highlight))
        end)

        row:SetScript("OnLeave", function(self)
            if table.selectedRow == self then
                self:SetBackdropColor(unpack(Theme.highlight))
            else
                self:SetBackdropColor(unpack(self.bgColor))
            end
        end)

        -- Click handler
        row:SetScript("OnClick", function(self)
            if table.selectable then
                -- Deselect previous row
                if table.selectedRow and table.selectedRow ~= self then
                    table.selectedRow:SetBackdropColor(unpack(table.selectedRow.bgColor))
                end

                -- Select this row
                table.selectedRow = self
                self:SetBackdropColor(unpack(Theme.highlight))

                if table.OnSelectionChanged then
                    table:OnSelectionChanged(self.data, self.dataIndex)
                end
            end

            if table.OnRowClick then
                table:OnRowClick(self, self.data, self.dataIndex)
            end
        end)

        row:SetScript("OnDoubleClick", function(self)
            if table.OnRowDoubleClick then
                table:OnRowDoubleClick(self, self.data, self.dataIndex)
            end
        end)

        return row
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
        self.scrollFrame:SetVerticalScroll(yPos)
    end

    return table
end
