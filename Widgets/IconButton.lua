--[[
    MedaUI IconButton Widget
    Creates a small themed button displaying a texture icon
    with optional toggle state, hover effects, and tooltip support
]]

local MedaUI = LibStub("MedaUI-2.0")
---@cast MedaUI MedaUILibrary
local Pixel = LibStub("MedaUI-2.0").Pixel

local DEFAULT_SIZE = 18
local ICON_PADDING = 2

--- Create a themed icon button
--- @param parent Frame The parent frame
--- @param config table { size, icon, iconActive, tooltip, tooltipActive, toggle, atlas, flat }
--- @return Button The created icon button
function MedaUI.CreateIconButton(library, parent, config)
    config = config or {}
    local size = config.size or DEFAULT_SIZE

    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    Pixel.SetSize(button, size, size)
    button:SetBackdrop(library:CreateBackdrop(true))
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    -- Icon texture
    button.icon = button:CreateTexture(nil, "ARTWORK")
    Pixel.SetPoint(button.icon, "TOPLEFT", ICON_PADDING, -ICON_PADDING)
    Pixel.SetPoint(button.icon, "BOTTOMRIGHT", -ICON_PADDING, ICON_PADDING)
    if config.atlas then
        button.icon:SetAtlas(config.atlas)
    elseif config.icon then
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
    button._flat = config.flat or false

    local function ApplyTheme()
        local theme = MedaUI.Theme
        if not button._isEnabled then
            if button._flat then
                button:SetBackdropColor(0, 0, 0, 0)
                button:SetBackdropBorderColor(0, 0, 0, 0)
            else
                button:SetBackdropColor(unpack(theme.buttonDisabled))
                button:SetBackdropBorderColor(unpack(theme.border))
            end
            button.icon:SetAlpha(0.35)
            return
        end

        button.icon:SetAlpha(1)

        if button._flat then
            button:SetBackdropColor(0, 0, 0, 0)
            button:SetBackdropBorderColor(0, 0, 0, 0)
        elseif button._isHovered then
            button:SetBackdropColor(unpack(theme.buttonHover))
            button:SetBackdropBorderColor(unpack(theme.gold))
        elseif button._active then
            button:SetBackdropColor(unpack(theme.buttonHover))
            button:SetBackdropBorderColor(unpack(theme.border))
        else
            button:SetBackdropColor(unpack(theme.button))
            button:SetBackdropBorderColor(unpack(theme.border))
        end
    end
    button._ApplyTheme = ApplyTheme

    button._themeHandle = MedaUI:RegisterThemedWidget(button, ApplyTheme)

    ApplyTheme()

    -- Hover
    button:SetScript("OnEnter", function(widget)
        if not widget._isEnabled then return end
        widget._isHovered = true
        MedaUI:PlaySound("hover")
        if not widget._flat then
            local theme = MedaUI.Theme
            widget:SetBackdropColor(unpack(theme.buttonHover))
            widget:SetBackdropBorderColor(unpack(theme.gold))
        end
        widget.icon:SetAlpha(1)

        local tip = widget._active and widget._tooltipActiveText or widget._tooltipText
        if tip then
            GameTooltip:SetOwner(widget, "ANCHOR_TOP")
            GameTooltip:SetText(tip, 1, 1, 1)
            GameTooltip:Show()
        end
    end)

    button:SetScript("OnLeave", function(widget)
        if not widget._isEnabled then return end
        widget._isHovered = false
        ApplyTheme()
        GameTooltip:Hide()
    end)

    -- Click
    button:SetScript("OnClick", function(widget, btn)
        if not widget._isEnabled then return end
        MedaUI:PlaySound("click")

        if widget._isToggle then
            widget._active = not widget._active
            -- Swap icon texture when toggling
            if widget._active and widget._iconActivePath then
                widget.icon:SetTexture(widget._iconActivePath)
            elseif not widget._active and widget._iconPath then
                widget.icon:SetTexture(widget._iconPath)
            end
            ApplyTheme()
        end

        if widget.OnClick then
            widget:OnClick(btn, widget._active)
        end
    end)

    -- Click feedback (raw SetPoint for animation)
    button:SetScript("OnMouseDown", function(widget)
        if widget._isEnabled then
            widget.icon:SetPoint("TOPLEFT", ICON_PADDING + 1, -ICON_PADDING - 1)
            widget.icon:SetPoint("BOTTOMRIGHT", -ICON_PADDING + 1, ICON_PADDING - 1)
        end
    end)

    button:SetScript("OnMouseUp", function(widget)
        widget.icon:SetPoint("TOPLEFT", ICON_PADDING, -ICON_PADDING)
        widget.icon:SetPoint("BOTTOMRIGHT", -ICON_PADDING, ICON_PADDING)
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

    --- Update the icon to use an atlas.
    --- @param atlas string
    function button:SetAtlas(atlas)
        self._iconPath = nil
        self.icon:SetAtlas(atlas)
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

    function button:SetIconDesaturated(desaturated)
        self.icon:SetDesaturated(desaturated and true or false)
    end

    -- Disabled state
    local originalSetEnabled = button.SetEnabled
    button.SetEnabled = function(widget, enabled)
        originalSetEnabled(widget, enabled)
        widget._isEnabled = enabled
        ApplyTheme()
    end

    return button
end
