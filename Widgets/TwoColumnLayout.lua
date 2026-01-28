--[[
    MedaUI TwoColumnLayout Widget
    Helper for creating two-column form layouts
]]

local MedaUI = LibStub("MedaUI-1.0")

--- Create a two-column layout helper
--- @param parent Frame The parent frame
--- @param config table|nil Configuration {leftWidth, rightWidth, columnGap, startY, leftX, rightX}
--- @return table The layout manager
function MedaUI:CreateTwoColumnLayout(parent, config)
    config = config or {}

    local layout = {
        parent = parent,
        leftWidth = config.leftWidth or 280,
        rightWidth = config.rightWidth or 280,
        columnGap = config.columnGap or 20,
        startY = config.startY or -10,
        leftX = config.leftX or 15,
        rightX = config.rightX,  -- Calculated if not provided

        -- Current Y positions for each column
        leftY = config.startY or -10,
        rightY = config.startY or -10,

        -- Track widgets for theme updates
        widgets = {},
    }

    -- Calculate right column X if not provided
    if not layout.rightX then
        layout.rightX = layout.leftX + layout.leftWidth + layout.columnGap
    end

    --- Add a widget to the left column
    --- @param widget Frame The widget to add
    --- @param yOffset number|nil Additional Y offset (negative for down)
    --- @return Frame The widget (for chaining)
    function layout:AddToLeft(widget, yOffset)
        yOffset = yOffset or 0
        widget:SetPoint("TOPLEFT", self.parent, "TOPLEFT", self.leftX, self.leftY + yOffset)
        table.insert(self.widgets, widget)
        return widget
    end

    --- Add a widget to the right column
    --- @param widget Frame The widget to add
    --- @param yOffset number|nil Additional Y offset (negative for down)
    --- @return Frame The widget (for chaining)
    function layout:AddToRight(widget, yOffset)
        yOffset = yOffset or 0
        widget:SetPoint("TOPLEFT", self.parent, "TOPLEFT", self.rightX, self.rightY + yOffset)
        table.insert(self.widgets, widget)
        return widget
    end

    --- Move to the next row in both columns
    --- @param spacing number|nil Row spacing (default: 30)
    function layout:NextRow(spacing)
        spacing = spacing or 30
        self.leftY = self.leftY - spacing
        self.rightY = self.rightY - spacing
    end

    --- Advance left column by a specific amount
    --- @param amount number Amount to advance (positive = down)
    function layout:AdvanceLeft(amount)
        self.leftY = self.leftY - amount
    end

    --- Advance right column by a specific amount
    --- @param amount number Amount to advance (positive = down)
    function layout:AdvanceRight(amount)
        self.rightY = self.rightY - amount
    end

    --- Sync both columns to the lowest Y position
    function layout:SyncColumns()
        local lowest = math.min(self.leftY, self.rightY)
        self.leftY = lowest
        self.rightY = lowest
    end

    --- Get current Y position for left column
    --- @return number The current Y position
    function layout:GetLeftY()
        return self.leftY
    end

    --- Get current Y position for right column
    --- @return number The current Y position
    function layout:GetRightY()
        return self.rightY
    end

    --- Get the lowest Y position (useful for calculating total height)
    --- @return number The lowest Y position
    function layout:GetCurrentY()
        return math.min(self.leftY, self.rightY)
    end

    --- Get total content height
    --- @return number The total height used
    function layout:GetContentHeight()
        return math.abs(self:GetCurrentY() - self.startY)
    end

    --- Reset layout to starting position
    function layout:Reset()
        self.leftY = self.startY
        self.rightY = self.startY
    end

    --- Add a full-width section header spanning both columns
    --- @param text string Header text
    --- @param width number|nil Width (default: full width)
    --- @return FontString, Texture, Frame The header elements
    function layout:AddSectionHeader(text, width)
        width = width or (self.rightX - self.leftX + self.rightWidth)
        local header, line, container = MedaUI:CreateSectionHeader(self.parent, text, width)
        header:SetPoint("TOPLEFT", self.parent, "TOPLEFT", self.leftX, self:GetCurrentY())
        self:NextRow(32)
        table.insert(self.widgets, container)
        return header, line, container
    end

    --- Add a full-width widget (spans both columns)
    --- @param widget Frame The widget to add
    --- @param yOffset number|nil Additional Y offset
    --- @return Frame The widget
    function layout:AddFullWidth(widget, yOffset)
        yOffset = yOffset or 0
        widget:SetPoint("TOPLEFT", self.parent, "TOPLEFT", self.leftX, self:GetCurrentY() + yOffset)
        table.insert(self.widgets, widget)
        return widget
    end

    return layout
end
