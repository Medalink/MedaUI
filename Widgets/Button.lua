--[[
    MedaUI Button Widget
    Creates themed buttons with hover effects
]]

local MedaUI = LibStub("MedaUI-1.0")

--- Create a themed button
--- @param parent Frame The parent frame
--- @param text string Button label text
--- @param width number Button width
--- @param height number Button height (default: 24)
--- @return Button The created button
function MedaUI:CreateButton(parent, text, width, height)
    height = height or 24

    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width, height)
    button:SetBackdrop(self:CreateBackdrop(true))

    -- Button text
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.text:SetPoint("CENTER")
    button.text:SetText(text)

    -- Track state for theme refresh
    button._isHovered = false
    button._isEnabled = true

    -- Apply theme colors
    local function ApplyTheme()
        local Theme = MedaUI.Theme
        if button._isEnabled then
            if button._isHovered then
                button:SetBackdropColor(unpack(Theme.buttonHover))
                button:SetBackdropBorderColor(unpack(Theme.gold))
            else
                button:SetBackdropColor(unpack(Theme.button))
                button:SetBackdropBorderColor(unpack(Theme.border))
            end
            button.text:SetTextColor(unpack(Theme.text))
        else
            button:SetBackdropColor(unpack(Theme.buttonDisabled))
            button:SetBackdropBorderColor(unpack(Theme.border))
            button.text:SetTextColor(unpack(Theme.textDisabled))
        end
    end
    button._ApplyTheme = ApplyTheme

    -- Register for theme updates
    button._themeHandle = MedaUI:RegisterThemedWidget(button, ApplyTheme)

    -- Initial theme application
    ApplyTheme()

    -- Hover effect
    button:SetScript("OnEnter", function(self)
        if self._isEnabled then
            self._isHovered = true
            local Theme = MedaUI.Theme
            self:SetBackdropColor(unpack(Theme.buttonHover))
            self:SetBackdropBorderColor(unpack(Theme.gold))
        end
    end)

    button:SetScript("OnLeave", function(self)
        if self._isEnabled then
            self._isHovered = false
            local Theme = MedaUI.Theme
            self:SetBackdropColor(unpack(Theme.button))
            self:SetBackdropBorderColor(unpack(Theme.border))
        end
    end)

    -- Click feedback
    button:SetScript("OnMouseDown", function(self)
        if self:IsEnabled() then
            self.text:SetPoint("CENTER", 1, -1)
        end
    end)

    button:SetScript("OnMouseUp", function(self)
        self.text:SetPoint("CENTER", 0, 0)
    end)

    -- Disabled state handling
    local originalSetEnabled = button.SetEnabled
    button.SetEnabled = function(self, enabled)
        originalSetEnabled(self, enabled)
        self._isEnabled = enabled
        local Theme = MedaUI.Theme
        if enabled then
            self:SetBackdropColor(unpack(Theme.button))
            self:SetBackdropBorderColor(unpack(Theme.border))
            self.text:SetTextColor(unpack(Theme.text))
        else
            self:SetBackdropColor(unpack(Theme.buttonDisabled))
            self:SetBackdropBorderColor(unpack(Theme.border))
            self.text:SetTextColor(unpack(Theme.textDisabled))
        end
    end

    -- SetText helper
    button.SetText = function(self, newText)
        self.text:SetText(newText)
    end

    return button
end
