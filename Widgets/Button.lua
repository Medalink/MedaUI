--[[
    MedaUI Button Widget
    Creates themed buttons with hover effects
]]

local MedaUI = LibStub("MedaUI-2.0")
---@cast MedaUI MedaUILibrary
local Pixel = LibStub("MedaUI-2.0").Pixel

-- Button constants
local MIN_HEIGHT = 28
local HORIZONTAL_PADDING = 16  -- Padding on each side

--- Create a themed button
--- @param parent Frame The parent frame
--- @param text string Button label text
--- @param width number|nil Button width (nil for auto-size based on text)
--- @param height number Button height (default: 28)
--- @return Button The created button
function MedaUI.CreateButton(library, parent, text, width, height)
    height = math.max(height or MIN_HEIGHT, MIN_HEIGHT)

    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetBackdrop(library:CreateBackdrop(true))

    -- Button text
    button.text = Pixel.CreateFontString(button, text)
    Pixel.SetPoint(button.text, "CENTER")

    -- Calculate width if not provided
    if width then
        Pixel.SetSize(button, width, height)
    else
        -- Auto-size based on text width + horizontal padding
        local textWidth = button.text:GetStringWidth()
        Pixel.SetSize(button, textWidth + (HORIZONTAL_PADDING * 2), height)
    end

    -- Track state for theme refresh
    button._isHovered = false
    button._isEnabled = true

    -- Apply theme colors
    local function ApplyTheme()
        local theme = MedaUI.Theme
        if button._isEnabled then
            if button._isHovered then
                button:SetBackdropColor(unpack(theme.buttonHover))
                button:SetBackdropBorderColor(unpack(theme.gold))
            else
                button:SetBackdropColor(unpack(theme.button))
                button:SetBackdropBorderColor(unpack(theme.border))
            end
            button.text:SetTextColor(unpack(theme.text))
        else
            button:SetBackdropColor(unpack(theme.buttonDisabled))
            button:SetBackdropBorderColor(unpack(theme.border))
            button.text:SetTextColor(unpack(theme.textDisabled))
        end
    end
    button._ApplyTheme = ApplyTheme

    -- Register for theme updates
    button._themeHandle = MedaUI:RegisterThemedWidget(button, ApplyTheme)

    -- Initial theme application
    ApplyTheme()

    -- Hover effect
    button:SetScript("OnEnter", function(widget)
        if widget._isEnabled then
            widget._isHovered = true
            MedaUI:PlaySound("hover")
            local theme = MedaUI.Theme
            widget:SetBackdropColor(unpack(theme.buttonHover))
            widget:SetBackdropBorderColor(unpack(theme.gold))
        end
    end)

    button:SetScript("OnLeave", function(widget)
        if widget._isEnabled then
            widget._isHovered = false
            local theme = MedaUI.Theme
            widget:SetBackdropColor(unpack(theme.button))
            widget:SetBackdropBorderColor(unpack(theme.border))
        end
    end)

    -- Click handler
    button:SetScript("OnClick", function(widget, btn)
        MedaUI:PlaySound("click")
        if widget.OnClick then
            widget:OnClick(btn)
        end
    end)

    -- Click feedback (intentionally raw WoW SetPoint for animation)
    button:SetScript("OnMouseDown", function(widget)
        if widget:IsEnabled() then
            widget.text:SetPoint("CENTER", 1, -1)
        end
    end)

    button:SetScript("OnMouseUp", function(widget)
        widget.text:SetPoint("CENTER", 0, 0)
    end)

    -- Disabled state handling
    local originalSetEnabled = button.SetEnabled
    button.SetEnabled = function(widget, enabled)
        originalSetEnabled(widget, enabled)
        widget._isEnabled = enabled
        local theme = MedaUI.Theme
        if enabled then
            widget:SetBackdropColor(unpack(theme.button))
            widget:SetBackdropBorderColor(unpack(theme.border))
            widget.text:SetTextColor(unpack(theme.text))
        else
            widget:SetBackdropColor(unpack(theme.buttonDisabled))
            widget:SetBackdropBorderColor(unpack(theme.border))
            widget.text:SetTextColor(unpack(theme.textDisabled))
        end
    end

    -- SetText helper
    button.SetText = function(widget, newText)
        widget.text:SetText(newText)
    end

    return button
end
