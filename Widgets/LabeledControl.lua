--[[
    MedaUI LabeledControl Widget
    Wrapper that combines a label with a control widget
]]

local MedaUI = LibStub("MedaUI-2.0")
---@cast MedaUI MedaUILibrary
local Pixel = LibStub("MedaUI-2.0").Pixel

---@param container MedaUILabelControl
---@param label FontString
local function RegisterLabelTheme(container, label)
    local function ApplyTheme()
        local theme = MedaUI.Theme
        label:SetTextColor(unpack(theme.text))
    end

    container._ApplyTheme = ApplyTheme
    container._themeHandle = MedaUI:RegisterThemedWidget(container, ApplyTheme)
    ApplyTheme()
end

---@param parent Frame
---@param width number
---@param height number
---@return MedaUILabelControl
local function CreateLabeledContainer(parent, width, height)
    local container = CreateFrame("Frame", nil, parent)
    ---@cast container MedaUILabelControl
    Pixel.SetSize(container, width, height)
    return container
end

--- Create a labeled slider
--- @param parent Frame The parent frame
--- @param labelText string Label text
--- @param width number Slider width
--- @param min number Minimum value
--- @param max number Maximum value
--- @param step number Step value
--- @return table The labeled control wrapper
function MedaUI.CreateLabeledSlider(library, parent, labelText, width, min, max, step)
    local container = CreateLabeledContainer(parent, width + 10, 50)

    -- Label
    local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ---@cast label FontString
    Pixel.SetPoint(label, "TOPLEFT", 0, 0)
    label:SetText(labelText)

    -- Slider
    local slider = library:CreateSlider(container, width, min, max, step)
    Pixel.SetPoint(slider, "TOPLEFT", label, "BOTTOMLEFT", 0, -12)
    RegisterLabelTheme(container, label)

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
--- @param textureMode string|nil Optional textureMode passed to CreateDropdown ("fill", "preview", "font")
--- @return table The labeled control wrapper
function MedaUI.CreateLabeledDropdown(library, parent, labelText, width, options, textureMode)
    local container = CreateLabeledContainer(parent, width + 10, 55)

    -- Label
    local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ---@cast label FontString
    Pixel.SetPoint(label, "TOPLEFT", 0, 0)
    label:SetText(labelText)

    -- Dropdown
    local dropdown = library:CreateDropdown(container, width, options, textureMode)
    Pixel.SetPoint(dropdown, "TOPLEFT", label, "BOTTOMLEFT", 0, -4)
    RegisterLabelTheme(container, label)

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
function MedaUI.CreateLabeledColorPicker(library, parent, labelText, size, hasAlpha)
    size = size or 26
    local container = CreateLabeledContainer(parent, 200, 26)

    -- Label
    local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ---@cast label FontString
    Pixel.SetPoint(label, "LEFT", 0, 0)
    label:SetText(labelText)

    -- Color picker
    local colorPicker = library:CreateColorPicker(container, size, size, hasAlpha)
    Pixel.SetPoint(colorPicker, "LEFT", label, "RIGHT", 10, 0)
    RegisterLabelTheme(container, label)

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
function MedaUI.CreateLabeledCheckbox(library, parent, labelText, headerText)
    if not headerText then
        -- Just return a regular checkbox
        return library:CreateCheckbox(parent, labelText)
    end

    local container = CreateLabeledContainer(parent, 200, 40)

    -- Header label
    local header = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ---@cast header FontString
    Pixel.SetPoint(header, "TOPLEFT", 0, 0)
    header:SetText(headerText)

    -- Checkbox
    local checkbox = library:CreateCheckbox(container, labelText)
    Pixel.SetPoint(checkbox, "TOPLEFT", header, "BOTTOMLEFT", 0, -4)
    RegisterLabelTheme(container, header)

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
function MedaUI.CreateLabeledEditBox(library, parent, labelText, width, height)
    height = height or 24
    local container = CreateLabeledContainer(parent, width + 10, 45)

    -- Label
    local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ---@cast label FontString
    Pixel.SetPoint(label, "TOPLEFT", 0, 0)
    label:SetText(labelText)

    -- Edit box
    local editBox = library:CreateEditBox(container, width, height)
    Pixel.SetPoint(editBox, "TOPLEFT", label, "BOTTOMLEFT", 0, -4)
    RegisterLabelTheme(container, label)

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

    function container:Enable()
        if self.control and self.control.Enable then
            self.control:Enable()
        end
    end

    function container:Disable()
        if self.control and self.control.Disable then
            self.control:Disable()
        end
    end

    function container:SetEnabled(enabled)
        if enabled then
            self:Enable()
        else
            self:Disable()
        end
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
