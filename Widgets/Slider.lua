--[[
    MedaUI Slider Widget
    Creates themed sliders with value display (matches MedaBinds style)
]]

local MedaUI = LibStub("MedaUI-1.0")

--- Create a themed slider
--- @param parent Frame The parent frame
--- @param width number Slider width
--- @param min number Minimum value
--- @param max number Maximum value
--- @param step number|nil Step increment (default: 1)
--- @return Frame The slider container frame
function MedaUI:CreateSlider(parent, width, min, max, step)
    step = step or 1

    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width, 24)

    -- Custom slider frame using native WoW Slider
    local slider = CreateFrame("Slider", nil, container, "BackdropTemplate")
    slider:SetPoint("LEFT", 0, 0)
    slider:SetSize(width - 40, 8)
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetOrientation("HORIZONTAL")
    slider:EnableMouse(true)

    -- Track background
    slider:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })

    -- Custom thumb texture
    local thumb = slider:CreateTexture(nil, "ARTWORK")
    thumb:SetSize(12, 12)
    slider:SetThumbTexture(thumb)

    -- Value display
    local valueText = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    valueText:SetPoint("LEFT", slider, "RIGHT", 8, 0)
    valueText:SetWidth(32)
    valueText:SetJustifyH("RIGHT")

    -- State
    container.min = min
    container.max = max
    container.step = step
    container.value = min
    container.slider = slider
    container.valueText = valueText
    container.thumb = thumb
    container._isHovered = false

    -- Apply theme colors
    local function ApplyTheme()
        local Theme = MedaUI.Theme
        slider:SetBackdropColor(unpack(Theme.backgroundDark))
        slider:SetBackdropBorderColor(unpack(Theme.border))
        valueText:SetTextColor(unpack(Theme.gold))
        if container._isHovered then
            thumb:SetColorTexture(unpack(Theme.goldBright))
        else
            thumb:SetColorTexture(unpack(Theme.gold))
        end
    end
    container._ApplyTheme = ApplyTheme

    -- Register for theme updates
    container._themeHandle = MedaUI:RegisterThemedWidget(container, ApplyTheme)

    -- Initial theme application
    ApplyTheme()

    -- Thumb hover effect
    slider:SetScript("OnEnter", function(self)
        container._isHovered = true
        local Theme = MedaUI.Theme
        thumb:SetColorTexture(unpack(Theme.goldBright))
    end)
    slider:SetScript("OnLeave", function(self)
        container._isHovered = false
        local Theme = MedaUI.Theme
        thumb:SetColorTexture(unpack(Theme.gold))
    end)

    -- Helper to update value display
    local function UpdateValueText(value)
        if step < 1 then
            valueText:SetText(string.format("%.1f", value))
        else
            valueText:SetText(tostring(math.floor(value + 0.5)))
        end
    end

    -- OnValueChanged handler
    slider:SetScript("OnValueChanged", function(self, value)
        if step >= 1 then
            value = math.floor(value + 0.5)
        end
        container.value = value
        UpdateValueText(value)
        if container.OnValueChanged then
            container:OnValueChanged(value)
        end
    end)

    -- API methods
    function container:SetValue(value)
        value = math.max(self.min, math.min(self.max, value))
        if self.step >= 1 then
            value = math.floor(value / self.step + 0.5) * self.step
        end
        self.value = value
        self.slider:SetValue(value)
        UpdateValueText(value)
    end

    function container:GetValue()
        return self.value
    end

    function container:SetMinMaxValues(newMin, newMax)
        self.min = newMin
        self.max = newMax
        self.slider:SetMinMaxValues(newMin, newMax)
        self:SetValue(self.value)
    end

    -- Forward SetScript for OnValueChanged
    local originalSetScript = container.SetScript
    function container:SetScript(scriptType, handler)
        if scriptType == "OnValueChanged" then
            self.OnValueChanged = handler
        else
            originalSetScript(self, scriptType, handler)
        end
    end

    -- Forward GetScript for OnValueChanged
    local originalGetScript = container.GetScript
    function container:GetScript(scriptType)
        if scriptType == "OnValueChanged" then
            return self.OnValueChanged
        else
            return originalGetScript(self, scriptType)
        end
    end

    -- Initialize
    slider:SetValue(min)
    UpdateValueText(min)

    return container
end
