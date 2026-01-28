--[[
    MedaUI EditBox Widget
    Creates themed text input fields
]]

local MedaUI = LibStub("MedaUI-1.0")

--- Create a themed edit box
--- @param parent Frame The parent frame
--- @param width number Edit box width
--- @param height number Edit box height (default: 24)
--- @param isMultiLine boolean|nil Whether to allow multiple lines
--- @return EditBox The created edit box
function MedaUI:CreateEditBox(parent, width, height, isMultiLine)
    height = height or 24

    -- Container with backdrop
    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    container:SetSize(width, height)
    container:SetBackdrop(self:CreateBackdrop(true))

    -- EditBox
    local editBox = CreateFrame("EditBox", nil, container)
    editBox:SetPoint("TOPLEFT", 6, -4)
    editBox:SetPoint("BOTTOMRIGHT", -6, 4)
    editBox:SetFontObject("GameFontHighlight")
    editBox:SetAutoFocus(false)
    editBox:SetMultiLine(isMultiLine or false)

    if not isMultiLine then
        editBox:SetMaxLetters(256)
    end

    -- State tracking
    container._hasFocus = false
    container._isHovered = false
    container._isEnabled = true

    -- Apply theme colors
    local function ApplyTheme()
        local Theme = MedaUI.Theme
        container:SetBackdropColor(unpack(container._isEnabled and Theme.input or Theme.backgroundDark))

        if container._hasFocus then
            container:SetBackdropBorderColor(unpack(Theme.gold))
        elseif container._isHovered then
            container:SetBackdropBorderColor(unpack(Theme.borderLight))
        else
            container:SetBackdropBorderColor(unpack(Theme.border))
        end

        if container._isEnabled then
            -- Check if placeholder is showing
            if container.placeholder and editBox:GetText() == container.placeholder then
                editBox:SetTextColor(unpack(Theme.textDim))
            else
                editBox:SetTextColor(unpack(Theme.text))
            end
        else
            editBox:SetTextColor(unpack(Theme.textDim))
        end
    end
    container._ApplyTheme = ApplyTheme

    -- Register for theme updates
    container._themeHandle = MedaUI:RegisterThemedWidget(container, ApplyTheme)

    -- Initial theme application
    ApplyTheme()

    -- Focus effects
    editBox:SetScript("OnEditFocusGained", function()
        container._hasFocus = true
        local Theme = MedaUI.Theme
        container:SetBackdropBorderColor(unpack(Theme.gold))
    end)

    editBox:SetScript("OnEditFocusLost", function()
        container._hasFocus = false
        local Theme = MedaUI.Theme
        container:SetBackdropBorderColor(unpack(Theme.border))
    end)

    -- Enter key handling (single line)
    if not isMultiLine then
        editBox:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
            if container.OnEnterPressed then
                container:OnEnterPressed(self:GetText())
            end
        end)
    end

    -- Escape to clear focus
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    -- Text changed callback
    editBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput and container.OnTextChanged then
            container:OnTextChanged(self:GetText())
        end
    end)

    -- Hover effect on container
    container:SetScript("OnEnter", function(self)
        self._isHovered = true
        if not editBox:HasFocus() then
            local Theme = MedaUI.Theme
            self:SetBackdropBorderColor(unpack(Theme.borderLight))
        end
    end)

    container:SetScript("OnLeave", function(self)
        self._isHovered = false
        if not editBox:HasFocus() then
            local Theme = MedaUI.Theme
            self:SetBackdropBorderColor(unpack(Theme.border))
        end
    end)

    -- Click container to focus
    container:SetScript("OnMouseDown", function()
        editBox:SetFocus()
    end)

    -- Expose editBox methods on container
    container.editBox = editBox

    function container:SetText(text)
        self.editBox:SetText(text or "")
    end

    function container:GetText()
        return self.editBox:GetText()
    end

    function container:SetPlaceholder(text)
        -- Simple placeholder implementation
        self.placeholder = text
        if self.editBox:GetText() == "" then
            self.editBox:SetText(text)
            local Theme = MedaUI.Theme
            self.editBox:SetTextColor(unpack(Theme.textDim))
        end

        self.editBox:HookScript("OnEditFocusGained", function(eb)
            if eb:GetText() == self.placeholder then
                eb:SetText("")
                local Theme = MedaUI.Theme
                eb:SetTextColor(unpack(Theme.text))
            end
        end)

        self.editBox:HookScript("OnEditFocusLost", function(eb)
            if eb:GetText() == "" then
                eb:SetText(self.placeholder)
                local Theme = MedaUI.Theme
                eb:SetTextColor(unpack(Theme.textDim))
            end
        end)
    end

    function container:ClearFocus()
        self.editBox:ClearFocus()
    end

    function container:SetFocus()
        self.editBox:SetFocus()
    end

    function container:Enable()
        self._isEnabled = true
        self.editBox:Enable()
        local Theme = MedaUI.Theme
        self:SetBackdropColor(unpack(Theme.input))
        self.editBox:SetTextColor(unpack(Theme.text))
    end

    function container:Disable()
        self._isEnabled = false
        self.editBox:Disable()
        local Theme = MedaUI.Theme
        self:SetBackdropColor(unpack(Theme.backgroundDark))
        self.editBox:SetTextColor(unpack(Theme.textDim))
    end

    return container
end
