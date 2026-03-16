--[[
    MedaUI Dropdown Widget
    Select menu with options list

    textureMode (optional 4th arg to CreateDropdown):
      "fill"    – option.texture fills entire row; text overlaid with outline
      "preview" – square preview panel anchored to the right of the dropdown
      nil       – plain text items (default)
]]

local MedaUI = LibStub("MedaUI-2.0")
---@cast MedaUI MedaUILibrary
local Pixel = LibStub("MedaUI-2.0").Pixel

-- Dropdown counter for unique names
local dropdownCounter = 0

-- Font object cache for "font" textureMode
local fontPreviewCache = {}
local function GetFontPreviewObject(fontPath, size)
    if not fontPath then return nil end
    local key = fontPath .. "_" .. size
    if fontPreviewCache[key] then return fontPreviewCache[key] end
    local fo = CreateFont("MedaUIDropdownFont_" .. key:gsub("[^%w]", "_"))
    fo:SetFont(fontPath, size, "")
    fontPreviewCache[key] = fo
    return fo
end

--- Create a dropdown select menu
--- @param parent Frame Parent frame
--- @param width number Dropdown width
--- @param options table Array of {value, label, texture?} options
--- @param textureMode string|nil "fill", "preview", or nil
--- @return MedaUIDropdown The dropdown frame
function MedaUI.CreateDropdown(library, parent, width, options, textureMode)
    dropdownCounter = dropdownCounter + 1
    local name = "MedaUIDropdown" .. dropdownCounter

    local dropdown = CreateFrame("Frame", name, parent, "BackdropTemplate")
    ---@cast dropdown MedaUIDropdown
    Pixel.SetSize(dropdown, width, 24)
    dropdown:SetBackdrop(library:CreateBackdrop(true))

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
        local fillTex = dropdown:CreateTexture(nil, "BORDER")
        ---@cast fillTex Texture
        dropdown.fillTex = fillTex
        Pixel.SetPoint(dropdown.fillTex, "TOPLEFT", 1, -1)
        Pixel.SetPoint(dropdown.fillTex, "BOTTOMRIGHT", -23, 1)
        dropdown.fillTex:Hide()
    end

    -- ================================================================
    -- Preview mode: square panel to the right of the dropdown
    -- ================================================================
    if textureMode == "preview" then
        local pvSize = 48
        local pv = CreateFrame("Frame", nil, dropdown, "BackdropTemplate")
        ---@cast pv MedaUIDropdownPreviewPanel
        Pixel.SetSize(pv, pvSize, pvSize)
        Pixel.SetPoint(pv, "LEFT", dropdown, "RIGHT", 6, 0)
        pv:SetBackdrop(library:CreateBackdrop(true))
        pv:SetBackdropColor(0.04, 0.04, 0.06, 0.9)
        pv:SetBackdropBorderColor(0.25, 0.25, 0.35, 0.6)

        local pvTex = pv:CreateTexture(nil, "ARTWORK")
        ---@cast pvTex Texture
        Pixel.SetPoint(pvTex, "TOPLEFT", 3, -3)
        Pixel.SetPoint(pvTex, "BOTTOMRIGHT", -3, 3)
        pvTex:SetTexCoord(0, 1, 0, 1)
        pv.tex = pvTex

        dropdown.previewPanel = pv
    end

    -- Selected text display
    local text = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ---@cast text FontString
    dropdown.text = text
    Pixel.SetPoint(dropdown.text, "LEFT", 8, 0)
    Pixel.SetPoint(dropdown.text, "RIGHT", -26, 0)
    dropdown.text:SetJustifyH("LEFT")
    dropdown.text:SetWordWrap(false)
    dropdown.text:SetText("Select...")

    if textureMode == "fill" then
        dropdown.text:SetShadowOffset(2, -2)
        dropdown.text:SetShadowColor(0, 0, 0, 1)
    end

    -- Arrow separator line
    local arrowSeparator = dropdown:CreateTexture(nil, "ARTWORK")
    ---@cast arrowSeparator Texture
    dropdown.arrowSeparator = arrowSeparator
    Pixel.SetSize(dropdown.arrowSeparator, 1, 16)
    Pixel.SetPoint(dropdown.arrowSeparator, "RIGHT", -22, 0)

    -- Arrow icon (texture-based chevron)
    local arrow = dropdown:CreateTexture(nil, "OVERLAY")
    ---@cast arrow Texture
    dropdown.arrow = arrow
    Pixel.SetSize(dropdown.arrow, 12, 12)
    Pixel.SetPoint(dropdown.arrow, "RIGHT", -6, 0)

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
    local button = CreateFrame("Button", nil, dropdown)
    ---@cast button Button
    dropdown.button = button
    dropdown.button:SetAllPoints()

    -- Options list (dropdown menu)
    dropdown.menu = CreateFrame("Frame", name .. "Menu", dropdown, "BackdropTemplate")
    ---@cast dropdown.menu MedaUIDropdownMenu
    dropdown.menu:SetBackdrop(library:CreateBackdrop(true))
    dropdown.menu:SetFrameStrata("FULLSCREEN_DIALOG")
    Pixel.SetPoint(dropdown.menu, "TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
    Pixel.SetWidth(dropdown.menu, width)
    dropdown.menu:Hide()
    dropdown.menu.items = {}

    -- Scroll frame for menu items (AF custom scrollbar)
    dropdown.menu.scrollParent = library:CreateScrollFrame(dropdown.menu)
    Pixel.SetPoint(dropdown.menu.scrollParent, "TOPLEFT", 2, -2)
    Pixel.SetPoint(dropdown.menu.scrollParent, "BOTTOMRIGHT", -2, 2)
    dropdown.menu.scrollParent:SetScrollStep(66)

    dropdown.menu.scrollChild = dropdown.menu.scrollParent.scrollContent

    -- Apply theme colors
    local function ApplyTheme()
        local theme = MedaUI.Theme
        if dropdown.enabled then
            dropdown:SetBackdropColor(unpack(theme.input))
            if dropdown._isHovered or dropdown.isOpen then
                dropdown:SetBackdropBorderColor(unpack(theme.gold))
            else
                dropdown:SetBackdropBorderColor(unpack(theme.border))
            end
            if textureMode == "fill" and dropdown._selectedTexture then
                dropdown.text:SetTextColor(1, 1, 1, 1)
            else
                dropdown.text:SetTextColor(unpack(theme.text))
            end
            dropdown.arrow:SetVertexColor(unpack(theme.textDim))
            dropdown.arrowSeparator:SetColorTexture(unpack(theme.border))
        else
            dropdown:SetBackdropColor(unpack(theme.buttonDisabled))
            dropdown:SetBackdropBorderColor(unpack(theme.border))
            dropdown.text:SetTextColor(unpack(theme.textDisabled))
            dropdown.arrow:SetVertexColor(unpack(theme.textDisabled))
            dropdown.arrowSeparator:SetColorTexture(unpack(theme.textDisabled))
        end
        dropdown.menu:SetBackdropColor(unpack(theme.menuBackground))
        dropdown.menu:SetBackdropBorderColor(unpack(theme.border))

        if textureMode == "preview" and dropdown.previewPanel then
            dropdown.previewPanel:SetBackdropColor(0.04, 0.04, 0.06, 0.9)
            dropdown.previewPanel:SetBackdropBorderColor(unpack(theme.border))
        end
    end
    dropdown._ApplyTheme = ApplyTheme

    -- Register for theme updates
    dropdown._themeHandle = MedaUI:RegisterThemedWidget(dropdown, ApplyTheme)

    -- Initial theme application
    ApplyTheme()

    -- Shared item handlers (capture dropdown via item._dropdown)
    local function ItemOnEnter(item)
        local theme = MedaUI.Theme
        item:SetBackdropColor(unpack(theme.buttonHover))
    end

    local function ItemOnEnterPreview(item)
        local theme = MedaUI.Theme
        item:SetBackdropColor(unpack(theme.buttonHover))
        local dd = item._dropdown
        if item._texture and dd and dd.previewPanel then
            dd.previewPanel.tex:SetTexture(item._texture)
        end
    end

    local function ItemOnLeave(item)
        item:SetBackdropColor(0, 0, 0, 0)
    end

    local function ItemOnLeavePreview(item)
        item:SetBackdropColor(0, 0, 0, 0)
        local dd = item._dropdown
        if dd and dd._selectedTexture and dd.previewPanel then
            dd.previewPanel.tex:SetTexture(dd._selectedTexture)
        end
    end

    local function ItemOnClick(item)
        local dd = item._dropdown
        if not dd then return end
        dd:SetSelected(item.value)
        dd.menu:Hide()
        dd.isOpen = false
        dd.arrow:SetRotation(math.rad(90))
        local theme = MedaUI.Theme
        dd:SetBackdropBorderColor(unpack(theme.border))
    end

    local itemBackdrop = MedaUI:CreateBackdrop(false)

    local function AcquireItem(dd, index)
        local items = dd.menu.items
        local item = items[index]
        if item then return item, false end

        item = CreateFrame("Button", nil, dd.menu.scrollChild, "BackdropTemplate")
        ---@cast item MedaUIDropdownItem
        item:SetBackdrop(itemBackdrop)
        item._dropdown = dd

        local itemText = item:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        ---@cast itemText FontString
        item.text = itemText
        Pixel.SetPoint(item.text, "LEFT", 8, 0)
        Pixel.SetPoint(item.text, "RIGHT", -4, 0)
        item.text:SetJustifyH("LEFT")
        item.text:SetWordWrap(false)

        if textureMode == "fill" then
            local fillTex = item:CreateTexture(nil, "ARTWORK")
            ---@cast fillTex Texture
            item._fillTex = fillTex
            item._fillTex:SetAllPoints()
            item._fillTex:Hide()
            item.text:SetShadowOffset(2, -2)
            item.text:SetShadowColor(0, 0, 0, 1)
        end

        if textureMode == "preview" then
            item:SetScript("OnEnter", ItemOnEnterPreview)
            item:SetScript("OnLeave", ItemOnLeavePreview)
        else
            item:SetScript("OnEnter", ItemOnEnter)
            item:SetScript("OnLeave", ItemOnLeave)
        end

        items[index] = item
        return item, true
    end

    -- Build options list (reuses existing item frames)
    local function BuildMenu()
        local theme = MedaUI.Theme
        local opts = dropdown.options
        local itemHeight = (textureMode == "fill") and 24 or 22
        local maxVisibleItems = 10
        local totalHeight = #opts * itemHeight
        local menuHeight = math.min(totalHeight + 4, maxVisibleItems * itemHeight + 4)
        Pixel.SetHeight(dropdown.menu, menuHeight)
        dropdown.menu.scrollParent:SetContentHeight(totalHeight, true, true)

        for i, opt in ipairs(opts) do
            local item = AcquireItem(dropdown, i)

            item:ClearAllPoints()
            Pixel.SetHeight(item, itemHeight)
            Pixel.SetPoint(item, "TOPLEFT", 0, -(i - 1) * itemHeight)
            Pixel.SetPoint(item, "RIGHT")
            item:SetBackdropColor(0, 0, 0, 0)

            item.value = opt.value
            item.label = opt.label
            item._texture = opt.texture

            if textureMode == "fill" and item._fillTex then
                if opt.texture then
                    item._fillTex:SetTexture(opt.texture)
                    item._fillTex:SetAlpha(0.85)
                    item._fillTex:Show()
                    item.text:SetTextColor(1, 1, 1, 1)
                else
                    item._fillTex:Hide()
                    item.text:SetTextColor(unpack(theme.text))
                end
            else
                item.text:SetTextColor(unpack(theme.text))
                if textureMode == "font" and opt.path then
                    local fo = GetFontPreviewObject(opt.path, 12)
                    if fo then item.text:SetFontObject(fo) end
                elseif textureMode == "font" then
                    item.text:SetFontObject(GameFontNormalSmall)
                end
            end

            item.text:SetText(opt.label)

            if opt.disabled then
                item:Disable()
                item:SetScript("OnClick", nil)
            else
                item:Enable()
                item:SetScript("OnClick", ItemOnClick)
            end

            item:Show()
        end

        -- Hide excess items from a previous larger option set
        for i = #opts + 1, #dropdown.menu.items do
            dropdown.menu.items[i]:Hide()
        end

        dropdown.menu.scrollParent:ResetScroll()
    end

    -- Toggle dropdown
    dropdown.button:SetScript("OnClick", function()
        if not dropdown.enabled then return end

        if dropdown.isOpen then
            dropdown.menu:Hide()
            dropdown.isOpen = false
            dropdown.arrow:SetRotation(math.rad(90))  -- Point down
            local theme = MedaUI.Theme
            if not dropdown._isHovered then
                dropdown:SetBackdropBorderColor(unpack(theme.border))
            end
        else
            MedaUI:PlaySound("dropdownOpen")
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
            MedaUI:PlaySound("hover")
            local theme = MedaUI.Theme
            dropdown:SetBackdropBorderColor(unpack(theme.gold))
        end
    end)

    dropdown.button:SetScript("OnLeave", function()
        dropdown._isHovered = false
        if not dropdown.isOpen then
            local theme = MedaUI.Theme
            dropdown:SetBackdropBorderColor(unpack(theme.border))
        end
    end)

    --- Set the selected value
    --- @param value any The value to select
    function dropdown:SetSelected(value)
        local previousValue = self.selectedValue
        self.selectedValue = value

        local foundTexture = nil
        local foundFontPath = nil
        for _, opt in ipairs(self.options) do
            if opt.value == value then
                self.selectedLabel = opt.label
                self.text:SetText(opt.label)
                foundTexture = opt.texture
                foundFontPath = opt.path
                break
            end
        end

        self._selectedTexture = foundTexture

        -- Font mode: render selected text in the chosen font
        if textureMode == "font" then
            if foundFontPath then
                local fo = GetFontPreviewObject(foundFontPath, 11)
                if fo then self.text:SetFontObject(fo) end
            else
                self.text:SetFontObject(GameFontNormalSmall)
            end
        end

        -- Fill mode: show texture behind selected text
        if textureMode == "fill" then
            if foundTexture then
                self.fillTex:SetTexture(foundTexture)
                self.fillTex:Show()
                self.text:SetTextColor(1, 1, 1, 1)
            else
                self.fillTex:Hide()
                local theme = MedaUI.Theme
                self.text:SetTextColor(unpack(theme.text))
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
        local theme = MedaUI.Theme
        if enabled then
            if textureMode == "fill" and self._selectedTexture then
                self.text:SetTextColor(1, 1, 1, 1)
            else
                self.text:SetTextColor(unpack(theme.text))
            end
            self.arrow:SetVertexColor(unpack(theme.textDim))
            self.arrowSeparator:SetColorTexture(unpack(theme.border))
            self:SetBackdropColor(unpack(theme.input))
        else
            self.text:SetTextColor(unpack(theme.textDisabled))
            self.arrow:SetVertexColor(unpack(theme.textDisabled))
            self.arrowSeparator:SetColorTexture(unpack(theme.textDisabled))
            self:SetBackdropColor(unpack(theme.buttonDisabled))
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
