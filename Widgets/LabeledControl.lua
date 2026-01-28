--[[
    MedaUI LabeledControl Widget
    Wrapper that combines a label with a control widget
]]

local MedaUI = LibStub("MedaUI-1.0")

--- Create a labeled slider
--- @param parent Frame The parent frame
--- @param labelText string Label text
--- @param width number Slider width
--- @param min number Minimum value
--- @param max number Maximum value
--- @param step number Step value
--- @return table The labeled control wrapper
function MedaUI:CreateLabeledSlider(parent, labelText, width, min, max, step)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width + 10, 50)

    -- Label
    local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", 0, 0)
    label:SetText(labelText)

    -- Slider
    local slider = self:CreateSlider(container, width, min, max, step)
    slider:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -12)

    -- Apply theme to label
    local function ApplyTheme()
        local Theme = MedaUI.Theme
        label:SetTextColor(unpack(Theme.text))
    end
    container._ApplyTheme = ApplyTheme
    container._themeHandle = MedaUI:RegisterThemedWidget(container, ApplyTheme)
    ApplyTheme()

    -- Store references
    container.label = label
    container.control = slider

    -- API methods
    function container:GetControl()
        return self.control
    end

    function container:SetLabel(text)
        self.label:SetText(text)
    end

    function container:GetValue()
        return self.control:GetValue()
    end

    function container:SetValue(value)
        self.control:SetValue(value)
    end

    -- Forward OnValueChanged
    container.OnValueChanged = nil
    slider.OnValueChanged = function(_, value)
        if container.OnValueChanged then
            container:OnValueChanged(value)
        end
    end

    return container
end

--- Create a labeled dropdown
--- @param parent Frame The parent frame
--- @param labelText string Label text
--- @param width number Dropdown width
--- @param options table Array of {label, value} options
--- @return table The labeled control wrapper
function MedaUI:CreateLabeledDropdown(parent, labelText, width, options)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width + 10, 55)

    -- Label
    local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", 0, 0)
    label:SetText(labelText)

    -- Dropdown
    local dropdown = self:CreateDropdown(container, width, options)
    dropdown:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -4)

    -- Apply theme to label
    local function ApplyTheme()
        local Theme = MedaUI.Theme
        label:SetTextColor(unpack(Theme.text))
    end
    container._ApplyTheme = ApplyTheme
    container._themeHandle = MedaUI:RegisterThemedWidget(container, ApplyTheme)
    ApplyTheme()

    -- Store references
    container.label = label
    container.control = dropdown

    -- API methods
    function container:GetControl()
        return self.control
    end

    function container:SetLabel(text)
        self.label:SetText(text)
    end

    function container:GetSelected()
        return self.control:GetSelected()
    end

    function container:SetSelected(value)
        self.control:SetSelected(value)
    end

    function container:SetOptions(opts)
        self.control:SetOptions(opts)
    end

    -- Forward OnValueChanged
    container.OnValueChanged = nil
    dropdown.OnValueChanged = function(_, value)
        if container.OnValueChanged then
            container:OnValueChanged(value)
        end
    end

    return container
end

--- Create a labeled color picker
--- @param parent Frame The parent frame
--- @param labelText string Label text
--- @param size number|nil Swatch size (default: 26)
--- @param hasAlpha boolean|nil Whether to include alpha channel
--- @return table The labeled control wrapper
function MedaUI:CreateLabeledColorPicker(parent, labelText, size, hasAlpha)
    size = size or 26
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(200, 26)

    -- Label
    local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", 0, 0)
    label:SetText(labelText)

    -- Color picker
    local colorPicker = self:CreateColorPicker(container, size, size, hasAlpha)
    colorPicker:SetPoint("LEFT", label, "RIGHT", 10, 0)

    -- Apply theme to label
    local function ApplyTheme()
        local Theme = MedaUI.Theme
        label:SetTextColor(unpack(Theme.text))
    end
    container._ApplyTheme = ApplyTheme
    container._themeHandle = MedaUI:RegisterThemedWidget(container, ApplyTheme)
    ApplyTheme()

    -- Store references
    container.label = label
    container.control = colorPicker

    -- API methods
    function container:GetControl()
        return self.control
    end

    function container:SetLabel(text)
        self.label:SetText(text)
    end

    function container:GetColor()
        return self.control:GetColor()
    end

    function container:SetColor(r, g, b, a)
        self.control:SetColor(r, g, b, a)
    end

    -- Forward OnColorChanged
    container.OnColorChanged = nil
    colorPicker.OnColorChanged = function(_, r, g, b, a)
        if container.OnColorChanged then
            container:OnColorChanged(r, g, b, a)
        end
    end

    return container
end

--- Create a labeled checkbox
--- @param parent Frame The parent frame
--- @param labelText string Label text (used for the checkbox itself)
--- @param headerText string|nil Optional header text above the checkbox
--- @return table The labeled control wrapper (or just the checkbox if no header)
function MedaUI:CreateLabeledCheckbox(parent, labelText, headerText)
    if not headerText then
        -- Just return a regular checkbox
        return self:CreateCheckbox(parent, labelText)
    end

    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(200, 40)

    -- Header label
    local header = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetText(headerText)

    -- Checkbox
    local checkbox = self:CreateCheckbox(container, labelText)
    checkbox:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)

    -- Apply theme to header
    local function ApplyTheme()
        local Theme = MedaUI.Theme
        header:SetTextColor(unpack(Theme.text))
    end
    container._ApplyTheme = ApplyTheme
    container._themeHandle = MedaUI:RegisterThemedWidget(container, ApplyTheme)
    ApplyTheme()

    -- Store references
    container.header = header
    container.control = checkbox

    -- API methods
    function container:GetControl()
        return self.control
    end

    function container:GetChecked()
        return self.control:GetChecked()
    end

    function container:SetChecked(value)
        self.control:SetChecked(value)
    end

    -- Forward OnValueChanged
    container.OnValueChanged = nil
    checkbox.OnValueChanged = function(_, checked)
        if container.OnValueChanged then
            container:OnValueChanged(checked)
        end
    end

    return container
end

--- Create a labeled edit box
--- @param parent Frame The parent frame
--- @param labelText string Label text
--- @param width number Edit box width
--- @param height number|nil Edit box height (default: 24)
--- @return table The labeled control wrapper
function MedaUI:CreateLabeledEditBox(parent, labelText, width, height)
    height = height or 24
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width + 10, 45)

    -- Label
    local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", 0, 0)
    label:SetText(labelText)

    -- Edit box
    local editBox = self:CreateEditBox(container, width, height)
    editBox:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -4)

    -- Apply theme to label
    local function ApplyTheme()
        local Theme = MedaUI.Theme
        label:SetTextColor(unpack(Theme.text))
    end
    container._ApplyTheme = ApplyTheme
    container._themeHandle = MedaUI:RegisterThemedWidget(container, ApplyTheme)
    ApplyTheme()

    -- Store references
    container.label = label
    container.control = editBox

    -- API methods
    function container:GetControl()
        return self.control
    end

    function container:SetLabel(text)
        self.label:SetText(text)
    end

    function container:GetText()
        return self.control:GetText()
    end

    function container:SetText(text)
        self.control:SetText(text)
    end

    -- Forward OnEnterPressed
    container.OnEnterPressed = nil
    editBox.OnEnterPressed = function(_, text)
        if container.OnEnterPressed then
            container:OnEnterPressed(text)
        end
    end

    return container
end
