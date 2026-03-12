--[[
    MedaUI InlineRadioGroup Widget
    Horizontal radio button group with an optional label.
]]

local MedaUI = LibStub("MedaUI-1.0")
local Pixel = LibStub("MedaUI-1.0").Pixel

--- Create an inline radio group.
--- @param parent Frame
--- @param config table { label, options, width, spacing, group }
--- @return Frame
function MedaUI:CreateInlineRadioGroup(parent, config)
    config = config or {}

    MedaUI._inlineRadioGroupCounter = (MedaUI._inlineRadioGroupCounter or 0) + 1

    local container = CreateFrame("Frame", nil, parent)
    Pixel.SetSize(container, config.width or 240, config.height or 44)

    local yOffset = 0
    if config.label and config.label ~= "" then
        container.label = MedaUI:CreateLabel(container, config.label, {
            fontObject = config.fontObject or "GameFontNormal",
            tone = config.tone or "text",
        })
        Pixel.SetPoint(container.label, "TOPLEFT", 0, 0)
        yOffset = 18
    end

    container.group = config.group or ("medaui_inline_radio_" .. tostring(MedaUI._inlineRadioGroupCounter))
    container.buttons = {}
    container.value = nil
    container.OnValueChanged = nil

    local xOffset = 0
    local spacing = config.spacing or 18
    for index, option in ipairs(config.options or {}) do
        local button = MedaUI:CreateRadio(container, option.label or option.value or ("Option " .. index), container.group)
        button._value = option.value
        Pixel.SetWidth(button, math.max(54, (button.label:GetStringWidth() or 0) + 28))
        Pixel.SetPoint(button, "TOPLEFT", xOffset, -yOffset)
        button:SetScript("OnClick", function(self)
            container:SetValue(self._value, true)
        end)

        container.buttons[index] = button
        xOffset = xOffset + button:GetWidth() + spacing
    end

    function container:SetValue(value, fireCallback)
        if self.value == value then
            return
        end

        self.value = value
        for _, button in ipairs(self.buttons) do
            button:SetChecked(button._value == value)
        end

        if fireCallback and self.OnValueChanged then
            self:OnValueChanged(value)
        end
    end

    function container:GetValue()
        return self.value
    end

    return container
end
