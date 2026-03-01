--[[
    MedaUI IconButton Widget
    Creates a small themed button displaying a texture icon
    with optional toggle state, hover effects, and tooltip support
]]

local MedaUI = LibStub("MedaUI-1.0")

local DEFAULT_SIZE = 18
local ICON_PADDING = 2

--- Create a themed icon button
--- @param parent Frame The parent frame
--- @param config table { size, icon, iconActive, tooltip, tooltipActive, toggle }
--- @return Button The created icon button
function MedaUI:CreateIconButton(parent, config)
    config = config or {}
    local size = config.size or DEFAULT_SIZE

    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(size, size)
    button:SetBackdrop(self:CreateBackdrop(true))
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    -- Icon texture
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", ICON_PADDING, -ICON_PADDING)
    button.icon:SetPoint("BOTTOMRIGHT", -ICON_PADDING, ICON_PADDING)
    if config.icon then
        button.icon:SetTexture(config.icon)
    end

    -- State
    button._isHovered = false
    button._isEnabled = true
    button._isToggle = config.toggle or false
    button._active = false
    button._iconPath = config.icon
    button._iconActivePath = config.iconActive
    button._tooltipText = config.tooltip
    button._tooltipActiveText = config.tooltipActive

    local function ApplyTheme()
        local Theme = MedaUI.Theme
        if not button._isEnabled then
            button:SetBackdropColor(unpack(Theme.buttonDisabled))
            button:SetBackdropBorderColor(unpack(Theme.border))
            button.icon:SetAlpha(0.35)
            return
        end

        if button._isHovered then
            button:SetBackdropColor(unpack(Theme.buttonHover))
            button:SetBackdropBorderColor(unpack(Theme.gold))
            button.icon:SetAlpha(1)
        elseif button._active then
            button:SetBackdropColor(unpack(Theme.buttonHover))
            button:SetBackdropBorderColor(unpack(Theme.border))
            button.icon:SetAlpha(0.9)
        else
            button:SetBackdropColor(unpack(Theme.button))
            button:SetBackdropBorderColor(unpack(Theme.border))
            button.icon:SetAlpha(0.7)
        end
    end
    button._ApplyTheme = ApplyTheme

    button._themeHandle = MedaUI:RegisterThemedWidget(button, ApplyTheme)

    ApplyTheme()

    -- Hover
    button:SetScript("OnEnter", function(self)
        if not self._isEnabled then return end
        self._isHovered = true
        local Theme = MedaUI.Theme
        self:SetBackdropColor(unpack(Theme.buttonHover))
        self:SetBackdropBorderColor(unpack(Theme.gold))
        self.icon:SetAlpha(1)

        local tip = self._active and self._tooltipActiveText or self._tooltipText
        if tip then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(tip, 1, 1, 1)
            GameTooltip:Show()
        end
    end)

    button:SetScript("OnLeave", function(self)
        if not self._isEnabled then return end
        self._isHovered = false
        ApplyTheme()
        GameTooltip:Hide()
    end)

    -- Click
    button:SetScript("OnClick", function(self, btn)
        if not self._isEnabled then return end

        if self._isToggle then
            self._active = not self._active
            -- Swap icon texture when toggling
            if self._active and self._iconActivePath then
                self.icon:SetTexture(self._iconActivePath)
            elseif not self._active and self._iconPath then
                self.icon:SetTexture(self._iconPath)
            end
            ApplyTheme()
        end

        if self.OnClick then
            self:OnClick(btn, self._active)
        end
    end)

    -- Click feedback
    button:SetScript("OnMouseDown", function(self)
        if self._isEnabled then
            self.icon:SetPoint("TOPLEFT", ICON_PADDING + 1, -ICON_PADDING - 1)
            self.icon:SetPoint("BOTTOMRIGHT", -ICON_PADDING + 1, ICON_PADDING - 1)
        end
    end)

    button:SetScript("OnMouseUp", function(self)
        self.icon:SetPoint("TOPLEFT", ICON_PADDING, -ICON_PADDING)
        self.icon:SetPoint("BOTTOMRIGHT", -ICON_PADDING, ICON_PADDING)
    end)

    --- Set active/toggled state programmatically
    function button:SetActive(active)
        self._active = active
        if active and self._iconActivePath then
            self.icon:SetTexture(self._iconActivePath)
        elseif not active and self._iconPath then
            self.icon:SetTexture(self._iconPath)
        end
        ApplyTheme()
    end

    --- Get active/toggled state
    function button:IsActive()
        return self._active
    end

    --- Update the normal-state icon texture
    function button:SetIcon(path)
        self._iconPath = path
        if not self._active then
            self.icon:SetTexture(path)
        end
    end

    --- Update the active-state icon texture
    function button:SetActiveIcon(path)
        self._iconActivePath = path
        if self._active then
            self.icon:SetTexture(path)
        end
    end

    --- Update tooltip text for both states
    function button:SetTooltipText(normal, active)
        self._tooltipText = normal
        self._tooltipActiveText = active
    end

    -- Disabled state
    local originalSetEnabled = button.SetEnabled
    button.SetEnabled = function(self, enabled)
        originalSetEnabled(self, enabled)
        self._isEnabled = enabled
        ApplyTheme()
    end

    return button
end
