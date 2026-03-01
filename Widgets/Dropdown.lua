--[[
    MedaUI Dropdown Widget
    Select menu with options list

    textureMode (optional 4th arg to CreateDropdown):
      "fill"    – option.texture fills entire row; text overlaid with outline
      "preview" – square preview panel anchored to the right of the dropdown
      nil       – plain text items (default)
]]

local MedaUI = LibStub("MedaUI-1.0")

-- Dropdown counter for unique names
local dropdownCounter = 0

--- Create a dropdown select menu
--- @param parent Frame Parent frame
--- @param width number Dropdown width
--- @param options table Array of {value, label, texture?} options
--- @param textureMode string|nil "fill", "preview", or nil
--- @return Frame The dropdown frame
function MedaUI:CreateDropdown(parent, width, options, textureMode)
    dropdownCounter = dropdownCounter + 1
    local name = "MedaUIDropdown" .. dropdownCounter

    local dropdown = CreateFrame("Frame", name, parent, "BackdropTemplate")
    dropdown:SetSize(width, 24)
    dropdown:SetBackdrop(self:CreateBackdrop(true))

    dropdown.options = options or {}
    dropdown.selectedValue = nil
    dropdown.selectedLabel = nil
    dropdown.OnValueChanged = nil
    dropdown.isOpen = false
    dropdown.enabled = true
    dropdown._isHovered = false
    dropdown._textureMode = textureMode
    dropdown._selectedTexture = nil

    -- ================================================================
    -- Fill mode: texture behind selected text in the main dropdown bar
    -- ================================================================
    if textureMode == "fill" then
        dropdown.fillTex = dropdown:CreateTexture(nil, "BORDER")
        dropdown.fillTex:SetPoint("TOPLEFT", 1, -1)
        dropdown.fillTex:SetPoint("BOTTOMRIGHT", -23, 1)
        dropdown.fillTex:Hide()
    end

    -- ================================================================
    -- Preview mode: square panel to the right of the dropdown
    -- ================================================================
    if textureMode == "preview" then
        local pvSize = 48
        local pv = CreateFrame("Frame", nil, dropdown, "BackdropTemplate")
        pv:SetSize(pvSize, pvSize)
        pv:SetPoint("LEFT", dropdown, "RIGHT", 6, 0)
        pv:SetBackdrop(self:CreateBackdrop(true))
        pv:SetBackdropColor(0.04, 0.04, 0.06, 0.9)
        pv:SetBackdropBorderColor(0.25, 0.25, 0.35, 0.6)

        local pvTex = pv:CreateTexture(nil, "ARTWORK")
        pvTex:SetPoint("TOPLEFT", 3, -3)
        pvTex:SetPoint("BOTTOMRIGHT", -3, 3)
        pvTex:SetTexCoord(0, 1, 0, 1)
        pv.tex = pvTex

        dropdown.previewPanel = pv
    end

    -- Selected text display
    dropdown.text = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dropdown.text:SetPoint("LEFT", 8, 0)
    dropdown.text:SetPoint("RIGHT", -26, 0)
    dropdown.text:SetJustifyH("LEFT")
    dropdown.text:SetWordWrap(false)
    dropdown.text:SetText("Select...")

    if textureMode == "fill" then
        dropdown.text:SetShadowOffset(2, -2)
        dropdown.text:SetShadowColor(0, 0, 0, 1)
    end

    -- Arrow separator line
    dropdown.arrowSeparator = dropdown:CreateTexture(nil, "ARTWORK")
    dropdown.arrowSeparator:SetSize(1, 16)
    dropdown.arrowSeparator:SetPoint("RIGHT", -22, 0)

    -- Arrow icon (texture-based chevron)
    dropdown.arrow = dropdown:CreateTexture(nil, "OVERLAY")
    dropdown.arrow:SetSize(12, 12)
    dropdown.arrow:SetPoint("RIGHT", -6, 0)

    -- Try Atlas first, fall back to rotated expand arrow
    local atlasSet = pcall(function()
        dropdown.arrow:SetAtlas("common-dropdown-icon")
    end)

    if not atlasSet or not dropdown.arrow:GetAtlas() then
        dropdown.arrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
        dropdown.arrow:SetRotation(math.rad(90))  -- Point down
    end

    dropdown.arrow:SetDesaturated(true)
    dropdown.arrowRotation = 0  -- Track rotation state (0 = down, 180 = up)

    -- Click area
    dropdown.button = CreateFrame("Button", nil, dropdown)
    dropdown.button:SetAllPoints()

    -- Options list (dropdown menu)
    dropdown.menu = CreateFrame("Frame", name .. "Menu", dropdown, "BackdropTemplate")
    dropdown.menu:SetBackdrop(self:CreateBackdrop(true))
    dropdown.menu:SetFrameStrata("FULLSCREEN_DIALOG")
    dropdown.menu:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
    dropdown.menu:SetWidth(width)
    dropdown.menu:Hide()
    dropdown.menu.items = {}

    -- Scroll frame for menu items
    dropdown.menu.scrollFrame = CreateFrame("ScrollFrame", name .. "MenuScroll", dropdown.menu, "UIPanelScrollFrameTemplate")
    dropdown.menu.scrollFrame:SetPoint("TOPLEFT", 2, -2)
    dropdown.menu.scrollFrame:SetPoint("BOTTOMRIGHT", -20, 2)

    -- Scroll child (content)
    dropdown.menu.scrollChild = CreateFrame("Frame", nil, dropdown.menu.scrollFrame)
    dropdown.menu.scrollChild:SetWidth(width - 24)
    dropdown.menu.scrollFrame:SetScrollChild(dropdown.menu.scrollChild)

    -- Apply theme colors
    local function ApplyTheme()
        local Theme = MedaUI.Theme
        if dropdown.enabled then
            dropdown:SetBackdropColor(unpack(Theme.input))
            if dropdown._isHovered or dropdown.isOpen then
                dropdown:SetBackdropBorderColor(unpack(Theme.gold))
            else
                dropdown:SetBackdropBorderColor(unpack(Theme.border))
            end
            if textureMode == "fill" and dropdown._selectedTexture then
                dropdown.text:SetTextColor(1, 1, 1, 1)
            else
                dropdown.text:SetTextColor(unpack(Theme.text))
            end
            dropdown.arrow:SetVertexColor(unpack(Theme.textDim))
            dropdown.arrowSeparator:SetColorTexture(unpack(Theme.border))
        else
            dropdown:SetBackdropColor(unpack(Theme.buttonDisabled))
            dropdown:SetBackdropBorderColor(unpack(Theme.border))
            dropdown.text:SetTextColor(unpack(Theme.textDisabled))
            dropdown.arrow:SetVertexColor(unpack(Theme.textDisabled))
            dropdown.arrowSeparator:SetColorTexture(unpack(Theme.textDisabled))
        end
        dropdown.menu:SetBackdropColor(unpack(Theme.menuBackground))
        dropdown.menu:SetBackdropBorderColor(unpack(Theme.border))

        if textureMode == "preview" and dropdown.previewPanel then
            dropdown.previewPanel:SetBackdropColor(0.04, 0.04, 0.06, 0.9)
            dropdown.previewPanel:SetBackdropBorderColor(unpack(Theme.border))
        end
    end
    dropdown._ApplyTheme = ApplyTheme

    -- Register for theme updates
    dropdown._themeHandle = MedaUI:RegisterThemedWidget(dropdown, ApplyTheme)

    -- Initial theme application
    ApplyTheme()

    -- Build options list
    local function BuildMenu()
        local Theme = MedaUI.Theme
        -- Clear existing items
        for _, item in ipairs(dropdown.menu.items) do
            item:Hide()
            item:SetParent(nil)
        end
        wipe(dropdown.menu.items)

        local itemHeight = (textureMode == "fill") and 24 or 22
        local maxVisibleItems = 10
        local totalHeight = #dropdown.options * itemHeight
        local menuHeight = math.min(totalHeight + 4, maxVisibleItems * itemHeight + 4)
        dropdown.menu:SetHeight(menuHeight)
        dropdown.menu.scrollChild:SetHeight(totalHeight)

        for i, opt in ipairs(dropdown.options) do
            local item = CreateFrame("Button", nil, dropdown.menu.scrollChild, "BackdropTemplate")
            item:SetSize(width - 24, itemHeight)
            item:SetPoint("TOPLEFT", 0, -(i - 1) * itemHeight)
            item:SetBackdrop(MedaUI:CreateBackdrop(false))
            item:SetBackdropColor(0, 0, 0, 0)

            item.value = opt.value
            item.label = opt.label
            item._texture = opt.texture

            -- Fill mode: texture fills entire item row
            if textureMode == "fill" and opt.texture then
                local fill = item:CreateTexture(nil, "ARTWORK")
                fill:SetAllPoints()
                fill:SetTexture(opt.texture)
                fill:SetAlpha(0.85)

                item.text = item:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                item.text:SetPoint("LEFT", 8, 0)
                item.text:SetPoint("RIGHT", -4, 0)
                item.text:SetJustifyH("LEFT")
                item.text:SetWordWrap(false)
                item.text:SetText(opt.label)
                item.text:SetTextColor(1, 1, 1, 1)
                item.text:SetShadowOffset(2, -2)
                item.text:SetShadowColor(0, 0, 0, 1)
            else
                item.text = item:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                item.text:SetPoint("LEFT", 8, 0)
                item.text:SetPoint("RIGHT", -4, 0)
                item.text:SetJustifyH("LEFT")
                item.text:SetWordWrap(false)
                item.text:SetText(opt.label)
                item.text:SetTextColor(unpack(Theme.text))
            end

            -- Hover / leave
            if textureMode == "preview" then
                item:SetScript("OnEnter", function(self)
                    local Theme = MedaUI.Theme
                    self:SetBackdropColor(unpack(Theme.buttonHover))
                    if self._texture and dropdown.previewPanel then
                        dropdown.previewPanel.tex:SetTexture(self._texture)
                    end
                end)
                item:SetScript("OnLeave", function(self)
                    self:SetBackdropColor(0, 0, 0, 0)
                    if dropdown._selectedTexture and dropdown.previewPanel then
                        dropdown.previewPanel.tex:SetTexture(dropdown._selectedTexture)
                    end
                end)
            else
                item:SetScript("OnEnter", function(self)
                    local Theme = MedaUI.Theme
                    self:SetBackdropColor(unpack(Theme.buttonHover))
                end)
                item:SetScript("OnLeave", function(self)
                    self:SetBackdropColor(0, 0, 0, 0)
                end)
            end

            item:SetScript("OnClick", function(self)
                dropdown:SetSelected(self.value)
                dropdown.menu:Hide()
                dropdown.isOpen = false
                dropdown.arrow:SetRotation(math.rad(90))  -- Point down
                local Theme = MedaUI.Theme
                dropdown:SetBackdropBorderColor(unpack(Theme.border))
            end)

            dropdown.menu.items[i] = item
        end

        -- Reset scroll position
        dropdown.menu.scrollFrame:SetVerticalScroll(0)
    end

    -- Toggle dropdown
    dropdown.button:SetScript("OnClick", function()
        if not dropdown.enabled then return end

        if dropdown.isOpen then
            dropdown.menu:Hide()
            dropdown.isOpen = false
            dropdown.arrow:SetRotation(math.rad(90))  -- Point down
            local Theme = MedaUI.Theme
            if not dropdown._isHovered then
                dropdown:SetBackdropBorderColor(unpack(Theme.border))
            end
        else
            BuildMenu()
            dropdown.menu:Show()
            dropdown.isOpen = true
            dropdown.arrow:SetRotation(math.rad(-90))  -- Point up
        end
    end)

    -- Close when clicking elsewhere
    dropdown.menu:SetScript("OnShow", function()
        dropdown.menu:SetFrameLevel(dropdown:GetFrameLevel() + 100)
    end)

    -- Hover effects on main dropdown
    dropdown.button:SetScript("OnEnter", function()
        if dropdown.enabled then
            dropdown._isHovered = true
            local Theme = MedaUI.Theme
            dropdown:SetBackdropBorderColor(unpack(Theme.gold))
        end
    end)

    dropdown.button:SetScript("OnLeave", function()
        dropdown._isHovered = false
        if not dropdown.isOpen then
            local Theme = MedaUI.Theme
            dropdown:SetBackdropBorderColor(unpack(Theme.border))
        end
    end)

    --- Set the selected value
    --- @param value any The value to select
    function dropdown:SetSelected(value)
        local previousValue = self.selectedValue
        self.selectedValue = value

        local foundTexture = nil
        for _, opt in ipairs(self.options) do
            if opt.value == value then
                self.selectedLabel = opt.label
                self.text:SetText(opt.label)
                foundTexture = opt.texture
                break
            end
        end

        self._selectedTexture = foundTexture

        -- Fill mode: show texture behind selected text
        if textureMode == "fill" then
            if foundTexture then
                self.fillTex:SetTexture(foundTexture)
                self.fillTex:Show()
                self.text:SetTextColor(1, 1, 1, 1)
            else
                self.fillTex:Hide()
                local Theme = MedaUI.Theme
                self.text:SetTextColor(unpack(Theme.text))
            end
        end

        -- Preview mode: update side panel
        if textureMode == "preview" and self.previewPanel then
            if foundTexture then
                self.previewPanel.tex:SetTexture(foundTexture)
            end
        end

        -- Fire callback if changed
        if previousValue ~= value and self.OnValueChanged then
            self:OnValueChanged(value, self.selectedLabel)
        end
    end

    --- Get the selected value
    --- @return any The selected value
    function dropdown:GetSelected()
        return self.selectedValue
    end

    --- Get the selected label
    --- @return string|nil The selected label
    function dropdown:GetSelectedLabel()
        return self.selectedLabel
    end

    --- Set the options list
    --- @param newOptions table Array of {value, label} options
    function dropdown:SetOptions(newOptions)
        self.options = newOptions
        -- Reset selection if current value not in new options
        local found = false
        for _, opt in ipairs(newOptions) do
            if opt.value == self.selectedValue then
                found = true
                break
            end
        end
        if not found then
            self.selectedValue = nil
            self.selectedLabel = nil
            self._selectedTexture = nil
            self.text:SetText("Select...")
            if textureMode == "fill" and self.fillTex then
                self.fillTex:Hide()
            end
        end
    end

    --- Enable or disable the dropdown
    --- @param enabled boolean Whether dropdown is enabled
    function dropdown:SetEnabled(enabled)
        self.enabled = enabled
        local Theme = MedaUI.Theme
        if enabled then
            if textureMode == "fill" and self._selectedTexture then
                self.text:SetTextColor(1, 1, 1, 1)
            else
                self.text:SetTextColor(unpack(Theme.text))
            end
            self.arrow:SetVertexColor(unpack(Theme.textDim))
            self.arrowSeparator:SetColorTexture(unpack(Theme.border))
            self:SetBackdropColor(unpack(Theme.input))
        else
            self.text:SetTextColor(unpack(Theme.textDisabled))
            self.arrow:SetVertexColor(unpack(Theme.textDisabled))
            self.arrowSeparator:SetColorTexture(unpack(Theme.textDisabled))
            self:SetBackdropColor(unpack(Theme.buttonDisabled))
            -- Close menu if open
            if self.isOpen then
                self.menu:Hide()
                self.isOpen = false
                self.arrow:SetRotation(math.rad(90))  -- Point down
            end
        end
    end

    -- Set first option as selected by default if options provided
    if options and options[1] then
        dropdown:SetSelected(options[1].value)
    end

    return dropdown
end
