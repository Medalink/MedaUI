--[[
    MedaUI Checkbox Widget
    Creates themed checkboxes with labels
]]

local MedaUI = LibStub("MedaUI-1.0")
local Pixel = LibStub("MedaUI-1.0").Pixel

--- Create a themed checkbox
--- @param parent Frame The parent frame
--- @param label string Checkbox label text
--- @return Frame The checkbox container frame
function MedaUI:CreateCheckbox(parent, label)
    local container = CreateFrame("Frame", nil, parent)
    Pixel.SetSize(container, 200, 20)

    -- Checkbox box
    local box = CreateFrame("Button", nil, container, "BackdropTemplate")
    Pixel.SetSize(box, 16, 16)
    Pixel.SetPoint(box, "LEFT", 0, 0)
    box:SetBackdrop(self:CreateBackdrop(true))

    -- Checkmark texture
    box.check = box:CreateTexture(nil, "OVERLAY")
    box.check:SetTexture(MedaUI.mediaPath .. "Textures\\checkmark.tga")
    Pixel.SetPoint(box.check, "CENTER", 0, 0)
    Pixel.SetSize(box.check, 12, 12)
    box.check:Hide()

    -- Label (8px gap from box for consistent spacing)
    container.label = Pixel.CreateFontString(container, label)
    Pixel.SetPoint(container.label, "LEFT", box, "RIGHT", 8, 0)

    -- State
    container.checked = false
    container.box = box
    container._isHovered = false

    -- Apply theme colors
    local function ApplyTheme()
        local Theme = MedaUI.Theme
        box:SetBackdropColor(unpack(Theme.input))
        if container._isHovered then
            box:SetBackdropBorderColor(unpack(Theme.goldDim))
        else
            box:SetBackdropBorderColor(unpack(Theme.border))
        end
        box.check:SetVertexColor(1, 1, 1, 1)
        container.label:SetTextColor(unpack(Theme.text))
    end
    container._ApplyTheme = ApplyTheme

    -- Register for theme updates
    container._themeHandle = MedaUI:RegisterThemedWidget(container, ApplyTheme)

    -- Initial theme application
    ApplyTheme()

    -- Click behavior
    box:SetScript("OnClick", function()
        container.checked = not container.checked
        if container.checked then box.check:Show() else box.check:Hide() end
        if container.OnValueChanged then
            container:OnValueChanged(container.checked)
        end
    end)

    -- Hover effect
    box:SetScript("OnEnter", function(self)
        container._isHovered = true
        local Theme = MedaUI.Theme
        self:SetBackdropBorderColor(unpack(Theme.goldDim))
    end)

    box:SetScript("OnLeave", function(self)
        container._isHovered = false
        local Theme = MedaUI.Theme
        self:SetBackdropBorderColor(unpack(Theme.border))
    end)

    -- API methods
    function container:SetChecked(value)
        self.checked = value
        if value then box.check:Show() else box.check:Hide() end
    end

    function container:GetChecked()
        return self.checked
    end

    function container:SetLabel(text)
        self.label:SetText(text)
    end

    -- Forward SetScript for OnClick to the internal box button
    local originalSetScript = container.SetScript
    function container:SetScript(scriptType, handler)
        if scriptType == "OnClick" then
            box:SetScript("OnClick", function()
                if handler then
                    handler(self)
                end
                if self.OnValueChanged then
                    self:OnValueChanged(self.checked)
                end
            end)
        else
            originalSetScript(self, scriptType, handler)
        end
    end

    -- Forward GetScript for OnClick
    local originalGetScript = container.GetScript
    function container:GetScript(scriptType)
        if scriptType == "OnClick" then
            return box:GetScript("OnClick")
        else
            return originalGetScript(self, scriptType)
        end
    end

    return container
end
