--[[
    MedaUI Radio Button Widget
    Creates themed radio buttons for option groups
]]

local MedaUI = LibStub("MedaUI-2.0")
---@cast MedaUI MedaUILibrary
local Pixel = LibStub("MedaUI-2.0").Pixel

-- Radio group management
MedaUI.RadioGroups = MedaUI.RadioGroups or {}

--- Create a themed radio button
--- @param parent Frame The parent frame
--- @param label string Radio button label text
--- @param group string|nil Optional group name for mutual exclusion
--- @return Frame The radio button container frame
function MedaUI.CreateRadio(library, parent, label, group)
    local container = CreateFrame("Frame", nil, parent)
    Pixel.SetSize(container, 200, 20)
    container.group = group

    -- Radio circle (using a square with rounded appearance via backdrop)
    local box = CreateFrame("Button", nil, container, "BackdropTemplate")
    Pixel.SetSize(box, 16, 16)
    Pixel.SetPoint(box, "LEFT", 0, 0)
    box:SetBackdrop(library:CreateBackdrop(true))

    -- Selected indicator (inner dot)
    box.dot = box:CreateTexture(nil, "OVERLAY")
    Pixel.SetSize(box.dot, 8, 8)
    Pixel.SetPoint(box.dot, "CENTER")
    box.dot:Hide()

    -- Label (8px gap from box for consistent spacing)
    container.label = Pixel.CreateFontString(container, label)
    Pixel.SetPoint(container.label, "LEFT", box, "RIGHT", 8, 0)

    -- State
    container.selected = false
    container.box = box

    -- Register with group
    if group then
        library.RadioGroups[group] = library.RadioGroups[group] or {}
        table.insert(library.RadioGroups[group], container)
    end

    -- Apply theme colors
    local function ApplyTheme()
        local theme = MedaUI.Theme
        box:SetBackdropColor(unpack(theme.input))
        box.dot:SetColorTexture(unpack(theme.gold))
        container.label:SetTextColor(unpack(theme.text))
        if container.selected then
            box:SetBackdropBorderColor(unpack(theme.gold))
        else
            box:SetBackdropBorderColor(unpack(theme.border))
        end
    end
    container._ApplyTheme = ApplyTheme

    -- Register for theme updates
    container._themeHandle = MedaUI:RegisterThemedWidget(container, ApplyTheme)

    -- Initial theme application
    ApplyTheme()

    -- Click behavior
    box:SetScript("OnClick", function()
        MedaUI:PlaySound("click")
        container:SetSelected(true)
        if container.OnValueChanged then
            container:OnValueChanged(true)
        end
    end)

    -- Hover effect
    box:SetScript("OnEnter", function(widget)
        MedaUI:PlaySound("hover")
        local theme = MedaUI.Theme
        widget:SetBackdropBorderColor(unpack(theme.gold))
    end)

    box:SetScript("OnLeave", function(widget)
        if not container.selected then
            local theme = MedaUI.Theme
            widget:SetBackdropBorderColor(unpack(theme.border))
        end
    end)

    -- API methods
    function container:SetSelected(value)
        local theme = MedaUI.Theme
        -- Deselect others in group
        if value and self.group and MedaUI.RadioGroups[self.group] then
            for _, radio in ipairs(MedaUI.RadioGroups[self.group]) do
                if radio ~= self then
                    radio.selected = false
                    radio.box.dot:Hide()
                    radio.box:SetBackdropBorderColor(unpack(theme.border))
                end
            end
        end

        self.selected = value
        if value then
            box.dot:Show()
            box:SetBackdropBorderColor(unpack(theme.gold))
        else
            box.dot:Hide()
            box:SetBackdropBorderColor(unpack(theme.border))
        end
    end

    function container:GetSelected()
        return self.selected
    end

    function container:SetLabel(text)
        self.label:SetText(text)
    end

    -- Alias for SetSelected/GetSelected for checkbox-like API compatibility
    function container:SetChecked(value)
        self:SetSelected(value)
    end

    function container:GetChecked()
        return self:GetSelected()
    end

    -- Forward SetScript for OnClick to the internal box button
    local originalSetScript = container.SetScript
    function container:SetScript(scriptType, handler)
        if scriptType == "OnClick" then
            box:SetScript("OnClick", function()
                self:SetSelected(true)
                if handler then
                    handler(self)
                end
                if self.OnValueChanged then
                    self:OnValueChanged(true)
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

--- Get the selected radio button in a group
--- @param group string The group name
--- @return Frame|nil The selected radio button or nil
function MedaUI:GetSelectedRadio(group)
    if self.RadioGroups[group] then
        for _, radio in ipairs(self.RadioGroups[group]) do
            if radio.selected then
                return radio
            end
        end
    end
    return nil
end
