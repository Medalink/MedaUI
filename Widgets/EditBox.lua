--[[
    MedaUI EditBox Widget
    Creates themed text input fields
]]

local MedaUI = LibStub("MedaUI-2.0")
---@cast MedaUI MedaUILibrary
local Pixel = LibStub("MedaUI-2.0").Pixel

--- Create a themed edit box
--- @param parent Frame The parent frame
--- @param width number Edit box width
--- @param height number Edit box height (default: 24)
--- @param isMultiLine boolean|nil Whether to allow multiple lines
--- @return EditBox The created edit box
function MedaUI.CreateEditBox(library, parent, width, height, isMultiLine)
    height = height or 24

    -- Container with backdrop
    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    Pixel.SetSize(container, width, height)
    container:SetBackdrop(library:CreateBackdrop(true))

    -- EditBox
    local editBox = CreateFrame("EditBox", nil, container)
    Pixel.SetPoint(editBox, "TOPLEFT", 6, -4)
    Pixel.SetPoint(editBox, "BOTTOMRIGHT", -6, 4)
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
        local theme = MedaUI.Theme
        container:SetBackdropColor(unpack(container._isEnabled and theme.input or theme.backgroundDark))

        if container._hasFocus then
            container:SetBackdropBorderColor(unpack(theme.gold))
        elseif container._isHovered then
            container:SetBackdropBorderColor(unpack(theme.borderLight))
        else
            container:SetBackdropBorderColor(unpack(theme.border))
        end

        if container._isEnabled then
            -- Check if placeholder is showing
            if container.placeholder and editBox:GetText() == container.placeholder then
                editBox:SetTextColor(unpack(theme.textDim))
            else
                editBox:SetTextColor(unpack(theme.text))
            end
        else
            editBox:SetTextColor(unpack(theme.textDim))
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
        local theme = MedaUI.Theme
        container:SetBackdropBorderColor(unpack(theme.gold))
    end)

    editBox:SetScript("OnEditFocusLost", function()
        container._hasFocus = false
        local theme = MedaUI.Theme
        container:SetBackdropBorderColor(unpack(theme.border))
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
    container:SetScript("OnEnter", function(widget)
        widget._isHovered = true
        if not editBox:HasFocus() then
            local theme = MedaUI.Theme
            widget:SetBackdropBorderColor(unpack(theme.borderLight))
        end
    end)

    container:SetScript("OnLeave", function(widget)
        widget._isHovered = false
        if not editBox:HasFocus() then
            local theme = MedaUI.Theme
            widget:SetBackdropBorderColor(unpack(theme.border))
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
        self.placeholder = text
        if self.editBox:GetText() == "" then
            self.editBox:SetText(text)
            local theme = MedaUI.Theme
            self.editBox:SetTextColor(unpack(theme.textDim))
        end

        -- Only install hooks once; subsequent calls just update self.placeholder
        if not self._placeholderHooked then
            self._placeholderHooked = true

            self.editBox:HookScript("OnEditFocusGained", function(eb)
                if self.placeholder and eb:GetText() == self.placeholder then
                    eb:SetText("")
                    local theme = MedaUI.Theme
                    eb:SetTextColor(unpack(theme.text))
                end
            end)

            self.editBox:HookScript("OnEditFocusLost", function(eb)
                if self.placeholder and eb:GetText() == "" then
                    eb:SetText(self.placeholder)
                    local theme = MedaUI.Theme
                    eb:SetTextColor(unpack(theme.textDim))
                end
            end)
        end
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
        local theme = MedaUI.Theme
        self:SetBackdropColor(unpack(theme.input))
        self.editBox:SetTextColor(unpack(theme.text))
    end

    function container:Disable()
        self._isEnabled = false
        self.editBox:Disable()
        local theme = MedaUI.Theme
        self:SetBackdropColor(unpack(theme.backgroundDark))
        self.editBox:SetTextColor(unpack(theme.textDim))
    end

    return container
end
