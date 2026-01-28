--[[
    MedaUI ColorPicker Widget
    Creates themed color picker with swatch button and opacity support
]]

local MedaUI = LibStub("MedaUI-1.0")
local Theme = MedaUI.Theme

--- Create a themed color picker
--- @param parent Frame The parent frame
--- @param width number Swatch width (default: 24)
--- @param height number Swatch height (default: 24)
--- @param hasOpacity boolean|nil Whether to show opacity slider (default: false)
--- @return Frame The color picker container frame
function MedaUI:CreateColorPicker(parent, width, height, hasOpacity)
    width = width or 24
    height = height or 24
    hasOpacity = hasOpacity or false

    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    container:SetSize(width, height)

    -- Swatch button (shows current color)
    local swatch = CreateFrame("Button", nil, container, "BackdropTemplate")
    swatch:SetAllPoints()
    swatch:SetBackdrop(self:CreateBackdrop(true))
    swatch:SetBackdropBorderColor(unpack(Theme.border))

    -- Color texture inside swatch
    local colorTex = swatch:CreateTexture(nil, "OVERLAY")
    colorTex:SetPoint("TOPLEFT", 2, -2)
    colorTex:SetPoint("BOTTOMRIGHT", -2, 2)

    -- Checkerboard pattern for transparency visualization
    local checkerboard = swatch:CreateTexture(nil, "BACKGROUND")
    checkerboard:SetPoint("TOPLEFT", 2, -2)
    checkerboard:SetPoint("BOTTOMRIGHT", -2, 2)
    checkerboard:SetColorTexture(0.3, 0.3, 0.3, 1)

    -- State
    container.r = 1
    container.g = 1
    container.b = 1
    container.a = 1
    container.hasOpacity = hasOpacity

    -- Helper to update swatch visual
    local function UpdateSwatch()
        colorTex:SetColorTexture(container.r, container.g, container.b, container.a)
        -- Show checkerboard through transparent colors
        if container.a < 1 then
            checkerboard:Show()
        else
            checkerboard:Hide()
        end
    end

    -- Open color picker
    local function OpenColorPicker()
        local info = {}
        info.r = container.r
        info.g = container.g
        info.b = container.b
        info.opacity = 1 - container.a  -- WoW uses inverted opacity
        info.hasOpacity = container.hasOpacity

        info.swatchFunc = function()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            container.r = r
            container.g = g
            container.b = b
            if container.hasOpacity then
                container.a = 1 - ColorPickerFrame:GetColorAlpha()
            end
            UpdateSwatch()
            if container.OnColorChanged then
                container:OnColorChanged(container.r, container.g, container.b, container.a)
            end
        end

        info.opacityFunc = function()
            container.a = 1 - ColorPickerFrame:GetColorAlpha()
            UpdateSwatch()
            if container.OnColorChanged then
                container:OnColorChanged(container.r, container.g, container.b, container.a)
            end
        end

        info.cancelFunc = function(previousValues)
            container.r = previousValues.r
            container.g = previousValues.g
            container.b = previousValues.b
            container.a = 1 - (previousValues.opacity or 0)
            UpdateSwatch()
            if container.OnColorChanged then
                container:OnColorChanged(container.r, container.g, container.b, container.a)
            end
        end

        -- Store previous values for cancel
        info.previousValues = {
            r = container.r,
            g = container.g,
            b = container.b,
            opacity = 1 - container.a
        }

        -- Use the appropriate API based on WoW version
        if ColorPickerFrame.SetupColorPickerAndShow then
            -- Retail 10.0+
            ColorPickerFrame:SetupColorPickerAndShow(info)
        else
            -- Classic / older retail
            ColorPickerFrame:SetColorRGB(info.r, info.g, info.b)
            ColorPickerFrame.hasOpacity = info.hasOpacity
            ColorPickerFrame.opacity = info.opacity
            ColorPickerFrame.previousValues = info.previousValues
            ColorPickerFrame.func = info.swatchFunc
            ColorPickerFrame.opacityFunc = info.opacityFunc
            ColorPickerFrame.cancelFunc = info.cancelFunc
            ColorPickerFrame:Hide()  -- Force update
            ColorPickerFrame:Show()
        end
    end

    swatch:SetScript("OnClick", OpenColorPicker)

    -- Hover effects
    swatch:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(unpack(Theme.gold))
    end)

    swatch:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(unpack(Theme.border))
    end)

    -- Tooltip
    swatch:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(unpack(Theme.gold))
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Click to change color", 1, 1, 1)
        GameTooltip:Show()
    end)

    swatch:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(unpack(Theme.border))
        GameTooltip:Hide()
    end)

    -- API methods
    function container:SetColor(r, g, b, a)
        self.r = r or 1
        self.g = g or 1
        self.b = b or 1
        self.a = a or 1
        UpdateSwatch()
    end

    function container:GetColor()
        return self.r, self.g, self.b, self.a
    end

    function container:SetHasOpacity(hasOpacity)
        self.hasOpacity = hasOpacity
    end

    -- Forward SetScript for OnColorChanged
    local originalSetScript = container.SetScript
    function container:SetScript(scriptType, handler)
        if scriptType == "OnColorChanged" then
            self.OnColorChanged = handler
        else
            originalSetScript(self, scriptType, handler)
        end
    end

    -- Forward GetScript for OnColorChanged
    local originalGetScript = container.GetScript
    function container:GetScript(scriptType)
        if scriptType == "OnColorChanged" then
            return self.OnColorChanged
        else
            return originalGetScript(self, scriptType)
        end
    end

    -- Expose swatch for external styling
    container.swatch = swatch
    container.colorTexture = colorTex

    -- Initialize
    UpdateSwatch()

    return container
end
