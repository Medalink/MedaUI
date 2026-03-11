--[[
    MedaUI SettingsPanel Widget
    Reusable sidebar + content settings panel for addon configuration.
    Provides themed sidebar with section headers, nav rows, module rows
    (with toggle, accent bar, stability badge), a scrollable content area,
    config header builder, footer button bar, and watermark support.
]]

local MedaUI = LibStub("MedaUI-1.0")
local Pixel = MedaUI.Pixel

local CONTENT_INSET = 14

-- ============================================================================
-- SettingsPanel factory
-- ============================================================================

--- Create a themed settings panel with sidebar + content layout.
--- @param name string Global frame name
--- @param config table Configuration table
--- @return table SettingsPanel API object
function MedaUI:CreateSettingsPanel(name, config)
    config = config or {}

    local panelWidth    = config.width or 900
    local panelHeight   = config.height or 640
    local sidebarWidth  = config.sidebarWidth or 200
    local brandTitle    = config.title or name
    local brandSubtitle = config.subtitle or "C O N F I G U R A T I O N"

    -- Internal state
    local selectedItem
    local sidebarButtons = {}
    local sidebarDynamicFrames = {}
    local scrollParent, scrollFrame, scrollChild, contentFrame
    local sidebarScrollParent, sidebarScrollContent
    local configHeaderOffset = 0
    local configCleanupFrames = {}

    -- Builder callbacks: key -> function(contentFrame, headerOffset)
    local contentBuilders = {}
    -- Item select callback
    local onItemSelected  -- function(key)

    -- -----------------------------------------------------------------------
    -- Base panel
    -- -----------------------------------------------------------------------
    local panel = MedaUI:CreatePanel(name, panelWidth, panelHeight, brandTitle)
    panel:SetHeadless(true)
    panel:SetResizable(true, {
        minWidth  = config.minWidth or (sidebarWidth + 300),
        minHeight = config.minHeight or 400,
    })

    local content = panel:GetContent()

    -- -----------------------------------------------------------------------
    -- Sidebar frame
    -- -----------------------------------------------------------------------
    local sidebarFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
    sidebarFrame:SetWidth(sidebarWidth)
    sidebarFrame:SetPoint("TOPLEFT", 0, 0)
    sidebarFrame:SetPoint("BOTTOMLEFT", 0, 0)
    sidebarFrame:SetBackdrop(MedaUI:CreateBackdrop(false))

    local function ApplySidebarTheme()
        local Theme = MedaUI.Theme
        sidebarFrame:SetBackdropColor(unpack(Theme.backgroundDark))
    end
    MedaUI:RegisterThemedWidget(sidebarFrame, ApplySidebarTheme)
    ApplySidebarTheme()

    -- Sidebar divider
    local divider = content:CreateTexture(nil, "ARTWORK")
    divider:SetWidth(1)
    divider:SetPoint("TOPLEFT", sidebarFrame, "TOPRIGHT", 0, 0)
    divider:SetPoint("BOTTOMLEFT", sidebarFrame, "BOTTOMRIGHT", 0, 0)
    divider:SetColorTexture(unpack(MedaUI.Theme.divider or { 1, 1, 1, 0.06 }))
    MedaUI:RegisterThemedWidget(divider, function()
        divider:SetColorTexture(unpack(MedaUI.Theme.divider or { 1, 1, 1, 0.06 }))
    end)

    -- Sidebar gradients
    local sidebarGrad = sidebarFrame:CreateTexture(nil, "BACKGROUND", nil, 1)
    sidebarGrad:SetAllPoints()
    sidebarGrad:SetColorTexture(1, 1, 1, 1)
    local gradOk = pcall(function()
        sidebarGrad:SetGradient("HORIZONTAL",
            CreateColor(1, 1, 1, 0.016),
            CreateColor(1, 1, 1, 0.006)
        )
    end)
    if not gradOk then
        sidebarGrad:SetColorTexture(1, 1, 1, 0.008)
    end

    local sidebarVertGrad = sidebarFrame:CreateTexture(nil, "BACKGROUND", nil, 2)
    sidebarVertGrad:SetAllPoints()
    sidebarVertGrad:SetColorTexture(0, 0, 0, 1)
    pcall(function()
        sidebarVertGrad:SetGradient("VERTICAL",
            CreateColor(0, 0, 0, 0.06),
            CreateColor(0, 0, 0, 0)
        )
    end)

    -- -----------------------------------------------------------------------
    -- Brand header
    -- -----------------------------------------------------------------------
    local brandFrame = CreateFrame("Frame", nil, sidebarFrame)
    brandFrame:SetHeight(50)
    brandFrame:SetPoint("TOPLEFT", 0, 0)
    brandFrame:SetPoint("TOPRIGHT", 0, 0)

    local brandLabel = brandFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    brandLabel:SetPoint("TOPLEFT", 14, -10)
    brandLabel:SetText(strupper(brandTitle))
    local brandFont, _, brandFlags = brandLabel:GetFont()
    brandLabel:SetFont(brandFont, 17, brandFlags)
    brandLabel:SetTextColor(unpack(MedaUI.Theme.gold))
    brandLabel:SetSpacing(1)

    local brandSub = brandFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    brandSub:SetPoint("TOPLEFT", brandLabel, "BOTTOMLEFT", 0, -2)
    brandSub:SetText(brandSubtitle)
    local subFont, _, subFlags = brandSub:GetFont()
    brandSub:SetFont(subFont, 9, subFlags)
    brandSub:SetTextColor(1, 1, 1, 0.38)

    MedaUI:RegisterThemedWidget(brandFrame, function()
        brandLabel:SetTextColor(unpack(MedaUI.Theme.gold))
        brandSub:SetTextColor(1, 1, 1, 0.38)
    end)

    panel:SetDragZone(brandFrame)

    -- -----------------------------------------------------------------------
    -- Content header band
    -- -----------------------------------------------------------------------
    local FOOTER_HEIGHT = 44

    local contentHeaderBand = content:CreateTexture(nil, "ARTWORK", nil, -1)
    contentHeaderBand:SetHeight(72)
    contentHeaderBand:SetPoint("TOPLEFT", sidebarFrame, "TOPRIGHT", 1, 0)
    contentHeaderBand:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 0)
    contentHeaderBand:SetColorTexture(1, 1, 1, 1)
    pcall(function()
        contentHeaderBand:SetGradient("VERTICAL",
            CreateColor(1, 1, 1, 0.008),
            CreateColor(1, 1, 1, 0.022)
        )
    end)

    local contentHeaderTopLine = content:CreateTexture(nil, "ARTWORK")
    contentHeaderTopLine:SetHeight(1)
    contentHeaderTopLine:SetPoint("TOPLEFT", sidebarFrame, "TOPRIGHT", 1, 0)
    contentHeaderTopLine:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 0)
    contentHeaderTopLine:SetColorTexture(unpack(MedaUI.Theme.divider or { 1, 1, 1, 0.06 }))

    local contentHeaderBottomLine = content:CreateTexture(nil, "ARTWORK")
    contentHeaderBottomLine:SetHeight(1)
    contentHeaderBottomLine:SetPoint("TOPLEFT", sidebarFrame, "TOPRIGHT", 1, -72)
    contentHeaderBottomLine:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -72)
    contentHeaderBottomLine:SetColorTexture(unpack(MedaUI.Theme.divider or { 1, 1, 1, 0.06 }))

    MedaUI:RegisterThemedWidget(contentHeaderTopLine, function()
        contentHeaderTopLine:SetColorTexture(unpack(MedaUI.Theme.divider or { 1, 1, 1, 0.06 }))
        contentHeaderBottomLine:SetColorTexture(unpack(MedaUI.Theme.divider or { 1, 1, 1, 0.06 }))
    end)

    -- -----------------------------------------------------------------------
    -- Scroll frame (main content area)
    -- -----------------------------------------------------------------------
    scrollParent = MedaUI:CreateScrollFrame(content)
    Pixel.SetPoint(scrollParent, "TOPLEFT", sidebarFrame, "TOPRIGHT", CONTENT_INSET + 1, -CONTENT_INSET)
    Pixel.SetPoint(scrollParent, "BOTTOMRIGHT", -CONTENT_INSET, CONTENT_INSET + FOOTER_HEIGHT)
    scrollParent:SetScrollStep(30)

    scrollFrame = scrollParent.scrollFrame
    scrollChild = scrollParent.scrollContent
    Pixel.SetHeight(scrollChild, 1)

    contentFrame = scrollChild

    -- -----------------------------------------------------------------------
    -- Footer button bar
    -- -----------------------------------------------------------------------
    local buttonBar = CreateFrame("Frame", nil, content)
    buttonBar:SetHeight(FOOTER_HEIGHT)
    buttonBar:SetPoint("BOTTOMLEFT", sidebarFrame, "BOTTOMRIGHT", CONTENT_INSET + 1, 0)
    buttonBar:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -CONTENT_INSET, 0)

    local buttonBarSep = buttonBar:CreateTexture(nil, "ARTWORK")
    buttonBarSep:SetHeight(1)
    buttonBarSep:SetPoint("TOPLEFT", 0, 0)
    buttonBarSep:SetPoint("TOPRIGHT", 0, 0)
    buttonBarSep:SetColorTexture(unpack(MedaUI.Theme.divider or { 1, 1, 1, 0.06 }))

    MedaUI:RegisterThemedWidget(buttonBar, function()
        buttonBarSep:SetColorTexture(unpack(MedaUI.Theme.divider or { 1, 1, 1, 0.06 }))
    end)

    local footerButtons = {}

    -- -----------------------------------------------------------------------
    -- Sidebar scroll area
    -- -----------------------------------------------------------------------
    sidebarScrollParent = MedaUI:CreateScrollFrame(sidebarFrame)
    Pixel.SetPoint(sidebarScrollParent, "TOPLEFT", 0, -52)
    Pixel.SetPoint(sidebarScrollParent, "BOTTOMRIGHT", 0, 30)
    sidebarScrollParent:SetScrollStep(30)
    sidebarScrollContent = sidebarScrollParent.scrollContent
    Pixel.SetHeight(sidebarScrollContent, 1)

    -- -----------------------------------------------------------------------
    -- Watermark
    -- -----------------------------------------------------------------------
    local watermark = content:CreateTexture(nil, "BACKGROUND", nil, -1)
    Pixel.SetSize(watermark, 620, 620)
    watermark:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 80, -200)
    watermark:SetAlpha(0.3)
    watermark:Hide()

    if config.watermarkTexture then
        watermark:SetTexture(config.watermarkTexture)
        watermark:Show()
    end

    -- -----------------------------------------------------------------------
    -- Legend frame (bottom of sidebar, above bottom edge)
    -- -----------------------------------------------------------------------
    local legendSep = sidebarFrame:CreateTexture(nil, "ARTWORK")
    legendSep:SetHeight(1)
    legendSep:SetPoint("BOTTOMLEFT", 10, 24)
    legendSep:SetPoint("BOTTOMRIGHT", -10, 24)
    legendSep:SetColorTexture(unpack(MedaUI.Theme.divider or { 1, 1, 1, 0.06 }))

    local legendFrame = CreateFrame("Frame", nil, sidebarFrame)
    legendFrame:SetHeight(20)
    legendFrame:SetPoint("BOTTOMLEFT", 8, 4)
    legendFrame:SetPoint("BOTTOMRIGHT", -8, 4)
    legendFrame:Hide()

    MedaUI:RegisterThemedWidget(legendFrame, function()
        legendSep:SetColorTexture(unpack(MedaUI.Theme.divider or { 1, 1, 1, 0.06 }))
    end)

    -- -----------------------------------------------------------------------
    -- Internal helpers
    -- -----------------------------------------------------------------------
    local NAV_ROW_HEIGHT = 30
    local MODULE_ROW_HEIGHT = 44

    local function TrackSidebarFrame(frame)
        sidebarDynamicFrames[#sidebarDynamicFrames + 1] = frame
        return frame
    end

    local function ClearSidebarFrames()
        for _, frame in ipairs(sidebarDynamicFrames) do
            frame:Hide()
            frame:SetParent(nil)
        end
        wipe(sidebarDynamicFrames)
        wipe(sidebarButtons)
    end

    local function ClearContent()
        for _, f in ipairs(configCleanupFrames) do
            f:Hide()
            f:SetParent(nil)
        end
        wipe(configCleanupFrames)

        local children = { contentFrame:GetChildren() }
        for _, child in ipairs(children) do
            child:Hide()
            child:SetParent(nil)
        end
        local regions = { contentFrame:GetRegions() }
        for _, region in ipairs(regions) do
            region:Hide()
        end
        if scrollParent then
            scrollParent:ResetScroll()
        end
    end

    local function UpdateSidebarSelection()
        for itemKey, btn in pairs(sidebarButtons) do
            local Theme = MedaUI.Theme
            if itemKey == selectedItem then
                btn:SetBackdropColor(unpack(Theme.selectedSubtle or { 1, 1, 1, 0.024 }))
                btn:SetBackdropBorderColor(0, 0, 0, 0)
                if btn.accentBar then
                    btn.accentBar:SetColorTexture(unpack(Theme.gold))
                end
                if btn.selectionWash then
                    btn.selectionWash:Show()
                end
            else
                btn:SetBackdropColor(0, 0, 0, 0)
                btn:SetBackdropBorderColor(0, 0, 0, 0)
                if btn.accentBar then
                    if btn._getEnabled then
                        local enabled = btn._getEnabled()
                        if enabled then
                            btn.accentBar:SetColorTexture(unpack(Theme.success or { 0.3, 0.85, 0.3, 1 }))
                        else
                            btn.accentBar:SetColorTexture(1, 1, 1, 0.10)
                        end
                    end
                end
                if btn.selectionWash then
                    btn.selectionWash:Hide()
                end
            end
        end
    end

    local function LoadItem(key)
        selectedItem = key
        ClearContent()
        UpdateSidebarSelection()
        configHeaderOffset = 0

        local builder = contentBuilders[key]
        if builder then
            builder(contentFrame)
        end

        if onItemSelected then
            onItemSelected(key)
        end
    end

    -- -----------------------------------------------------------------------
    -- Sidebar building API (called from RebuildSidebar)
    -- -----------------------------------------------------------------------
    local yOff = 0

    local api = {}
    api.panel = panel
    api.sidebarButtons = sidebarButtons

    function api:GetPanel()
        return panel
    end

    function api:GetFrame()
        return panel
    end

    function api:GetContentFrame()
        return contentFrame
    end

    function api:GetSelectedItem()
        return selectedItem
    end

    --- Start a sidebar rebuild. Clears existing sidebar items.
    function api:BeginSidebar()
        ClearSidebarFrames()
        yOff = -4
    end

    --- Add a section header to the sidebar.
    function api:AddSection(text)
        local header = TrackSidebarFrame(CreateFrame("Frame", nil, sidebarScrollContent))
        header:SetHeight(28)
        header:SetPoint("TOPLEFT", 0, yOff)
        header:SetPoint("TOPRIGHT", 0, yOff)

        local label = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("LEFT", 14, 0)
        label:SetText(strupper(text))
        label:SetTextColor(unpack(MedaUI.Theme.textSection or { 1, 1, 1, 0.42 }))

        local line = header:CreateTexture(nil, "ARTWORK")
        line:SetHeight(1)
        line:SetPoint("LEFT", label, "RIGHT", 8, 0)
        line:SetPoint("RIGHT", -14, 0)
        line:SetTexture(MedaUI.mediaPath .. "Textures\\section-tech-line.tga")
        line:SetVertexColor(1, 1, 1, 0.10)

        MedaUI:RegisterThemedWidget(header, function()
            label:SetTextColor(unpack(MedaUI.Theme.textSection or { 1, 1, 1, 0.42 }))
            line:SetVertexColor(1, 1, 1, 0.10)
        end)

        yOff = yOff - 28
    end

    --- Add a simple navigation row to the sidebar.
    function api:AddNavRow(key, displayText)
        local btn = TrackSidebarFrame(CreateFrame("Button", nil, sidebarScrollContent, "BackdropTemplate"))
        btn:SetHeight(NAV_ROW_HEIGHT)
        btn:SetPoint("TOPLEFT", 6, yOff)
        btn:SetPoint("TOPRIGHT", -6, yOff)
        btn:SetBackdrop(MedaUI:CreateBackdrop(false))
        btn:SetBackdropColor(0, 0, 0, 0)

        local wash = btn:CreateTexture(nil, "BACKGROUND")
        wash:SetTexture(MedaUI.mediaPath .. "Textures\\selection-wash.tga")
        wash:SetAllPoints()
        wash:SetAlpha(0.08)
        wash:Hide()
        btn.selectionWash = wash

        btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.label:SetJustifyH("LEFT")
        btn.label:SetWordWrap(false)
        btn.label:SetText(displayText)
        btn.label:SetPoint("LEFT", 14, 0)
        btn.label:SetTextColor(unpack(MedaUI.Theme.text))

        local chevron = btn:CreateTexture(nil, "OVERLAY")
        chevron:SetTexture(MedaUI.mediaPath .. "Textures\\chevron-right.tga")
        Pixel.SetSize(chevron, 10, 10)
        chevron:SetPoint("RIGHT", -10, 0)
        chevron:SetVertexColor(1, 1, 1, 0.22)

        btn:SetScript("OnClick", function()
            MedaUI:PlaySound("click")
            LoadItem(key)
        end)

        btn:SetScript("OnEnter", function(self)
            MedaUI:PlaySound("hover")
            if key ~= selectedItem then
                self:SetBackdropColor(unpack(MedaUI.Theme.hoverSubtle or { 1, 1, 1, 0.012 }))
            end
            chevron:SetVertexColor(1, 1, 1, 0.40)
        end)

        btn:SetScript("OnLeave", function(self)
            if key ~= selectedItem then
                self:SetBackdropColor(0, 0, 0, 0)
            end
            chevron:SetVertexColor(1, 1, 1, 0.22)
            GameTooltip:Hide()
        end)

        MedaUI:RegisterThemedWidget(btn, function()
            local Theme = MedaUI.Theme
            btn.label:SetTextColor(unpack(Theme.text))
            if key == selectedItem then
                btn:SetBackdropColor(unpack(Theme.selectedSubtle or { 1, 1, 1, 0.024 }))
                if wash then wash:Show() end
            else
                btn:SetBackdropColor(0, 0, 0, 0)
                if wash then wash:Hide() end
            end
        end)

        sidebarButtons[key] = btn
        yOff = yOff - NAV_ROW_HEIGHT
    end

    --- Add a module row with toggle, accent bar, optional stability/version badges.
    --- @param key string Unique key for this row
    --- @param displayText string Display name
    --- @param rowConfig table Optional config: enabled, stability, stabilityColors, version, author, customTag, customColor, slashCommands, onToggle, getEnabled
    function api:AddModuleRow(key, displayText, rowConfig)
        rowConfig = rowConfig or {}

        local btn = TrackSidebarFrame(CreateFrame("Button", nil, sidebarScrollContent, "BackdropTemplate"))
        btn:SetHeight(MODULE_ROW_HEIGHT)
        btn:SetPoint("TOPLEFT", 0, yOff)
        btn:SetPoint("TOPRIGHT", 0, yOff)
        btn:SetBackdrop(MedaUI:CreateBackdrop(false))
        btn:SetBackdropColor(0, 0, 0, 0)

        local wash = btn:CreateTexture(nil, "BACKGROUND")
        wash:SetTexture(MedaUI.mediaPath .. "Textures\\selection-wash.tga")
        wash:SetAllPoints()
        wash:SetAlpha(0.08)
        wash:Hide()
        btn.selectionWash = wash

        local topBorder = btn:CreateTexture(nil, "BACKGROUND", nil, 1)
        topBorder:SetHeight(1)
        topBorder:SetPoint("TOPLEFT", 0, 0)
        topBorder:SetPoint("TOPRIGHT", 0, 0)
        topBorder:SetColorTexture(1, 1, 1, 0.018)

        -- Accent bar (left edge)
        local accentBar = btn:CreateTexture(nil, "OVERLAY")
        accentBar:SetWidth(3)
        accentBar:SetPoint("TOPLEFT", 0, -4)
        accentBar:SetPoint("BOTTOMLEFT", 0, 4)
        local isEnabled = rowConfig.enabled or false
        if isEnabled then
            accentBar:SetColorTexture(unpack(MedaUI.Theme.success or { 0.3, 0.85, 0.3, 1 }))
        else
            accentBar:SetColorTexture(1, 1, 1, 0.10)
        end
        btn.accentBar = accentBar
        btn._getEnabled = rowConfig.getEnabled

        -- Toggle checkbox
        local toggleBox = CreateFrame("Button", nil, btn, "BackdropTemplate")
        Pixel.SetSize(toggleBox, 16, 16)
        toggleBox:SetPoint("LEFT", 14, 0)
        toggleBox:SetBackdrop(MedaUI:CreateBackdrop(true))
        toggleBox:SetBackdropColor(unpack(MedaUI.Theme.checkboxBg))
        toggleBox:SetBackdropBorderColor(unpack(MedaUI.Theme.checkboxBorder))

        local toggleCheck = toggleBox:CreateTexture(nil, "OVERLAY")
        toggleCheck:SetTexture(MedaUI.mediaPath .. "Textures\\checkmark.tga")
        Pixel.SetSize(toggleCheck, 12, 12)
        Pixel.SetPoint(toggleCheck, "CENTER", 0, 0)
        toggleCheck:SetVertexColor(unpack(MedaUI.Theme.checkboxMark or { 0.78, 0.80, 0.84, 0.9 }))
        toggleCheck:SetShown(isEnabled)
        btn.toggle = toggleBox
        btn.toggleCheck = toggleCheck

        local function UpdateToggleVisual()
            local Theme = MedaUI.Theme
            if isEnabled then
                toggleBox:SetBackdropColor(unpack(Theme.checkboxBgChecked or { 0.72, 0.75, 0.80, 0.12 }))
                toggleBox:SetBackdropBorderColor(unpack(Theme.checkboxBorderChecked or { 0.72, 0.75, 0.80, 0.44 }))
                toggleCheck:Show()
            else
                toggleBox:SetBackdropColor(unpack(Theme.checkboxBg or { 1, 1, 1, 0.03 }))
                toggleBox:SetBackdropBorderColor(unpack(Theme.checkboxBorder or { 1, 1, 1, 0.12 }))
                toggleCheck:Hide()
            end
        end
        UpdateToggleVisual()

        toggleBox:SetScript("OnClick", function()
            MedaUI:PlaySound("click")
            isEnabled = not isEnabled
            UpdateToggleVisual()
            if rowConfig.onToggle then
                rowConfig.onToggle(key, isEnabled)
            end
            if selectedItem == key then
                LoadItem(key)
            end
        end)

        -- Label
        local labelLeft = 52
        btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.label:SetJustifyH("LEFT")
        btn.label:SetWordWrap(false)
        btn.label:SetText(displayText)

        local stabColors = rowConfig.stabilityColors
        local stabColor = rowConfig.customColor or (stabColors and stabColors[rowConfig.stability or ""])
        if stabColor then
            btn.label:SetTextColor(unpack(stabColor))
        else
            btn.label:SetTextColor(unpack(MedaUI.Theme.text))
        end
        btn.label:SetPoint("LEFT", labelLeft, 0)

        -- Chevron
        local chevron = btn:CreateTexture(nil, "OVERLAY")
        chevron:SetTexture(MedaUI.mediaPath .. "Textures\\chevron-right.tga")
        Pixel.SetSize(chevron, 10, 10)
        chevron:SetPoint("RIGHT", -10, 0)
        chevron:SetVertexColor(1, 1, 1, 0.18)

        -- Custom tag
        if rowConfig.customTag then
            btn.tagLabel = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            btn.tagLabel:SetPoint("RIGHT", chevron, "LEFT", -8, 0)
            btn.tagLabel:SetText(rowConfig.customTag)
            btn.tagLabel:SetTextColor(unpack(rowConfig.customColor or { 0.35, 0.85, 1.0 }))
        end

        -- Version label
        if rowConfig.version then
            btn.versionLabel = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            if btn.tagLabel then
                btn.versionLabel:SetPoint("RIGHT", btn.tagLabel, "LEFT", -6, 0)
            else
                btn.versionLabel:SetPoint("RIGHT", chevron, "LEFT", -8, 0)
            end
            btn.versionLabel:SetTextColor(1, 1, 1, 0.28)
            local ver = tostring(rowConfig.version or "")
            if ver:sub(1, 1):lower() ~= "v" then ver = "v" .. ver end
            btn.versionLabel:SetText(ver)
            btn.label:SetPoint("RIGHT", btn.versionLabel, "LEFT", -6, 0)
        else
            btn.label:SetPoint("RIGHT", chevron, "LEFT", -6, 0)
        end

        -- Click / hover scripts
        btn:SetScript("OnClick", function()
            MedaUI:PlaySound("click")
            LoadItem(key)
        end)

        btn:SetScript("OnEnter", function(self)
            MedaUI:PlaySound("hover")
            if key ~= selectedItem then
                self:SetBackdropColor(unpack(MedaUI.Theme.hoverSubtle or { 1, 1, 1, 0.012 }))
            end
            chevron:SetVertexColor(1, 1, 1, 0.40)

            if rowConfig.slashCommands then
                local cmds = {}
                for cmd in pairs(rowConfig.slashCommands) do
                    if cmd ~= "" then cmds[#cmds + 1] = cmd end
                end
                if #cmds > 0 then
                    table.sort(cmds)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 4, 0)
                    GameTooltip:AddLine(displayText, 1, 0.82, 0)
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("Slash Commands:", 0.65, 0.65, 0.65)
                    local slug = key:lower()
                    for _, cmd in ipairs(cmds) do
                        GameTooltip:AddLine(format("  %s %s", rowConfig.slashPrefix or slug, cmd), 0.4, 0.78, 1)
                    end
                    GameTooltip:Show()
                end
            end
        end)

        btn:SetScript("OnLeave", function(self)
            if key ~= selectedItem then
                self:SetBackdropColor(0, 0, 0, 0)
            end
            chevron:SetVertexColor(1, 1, 1, 0.18)
            GameTooltip:Hide()
        end)

        MedaUI:RegisterThemedWidget(btn, function()
            local Theme = MedaUI.Theme
            if stabColor then
                btn.label:SetTextColor(unpack(stabColor))
            else
                btn.label:SetTextColor(unpack(Theme.text))
            end
            if btn.versionLabel then
                btn.versionLabel:SetTextColor(1, 1, 1, 0.28)
            end
            if btn.tagLabel then
                btn.tagLabel:SetTextColor(unpack(rowConfig.customColor or { 0.35, 0.85, 1.0 }))
            end
            toggleCheck:SetVertexColor(unpack(Theme.checkboxMark or { 0.78, 0.80, 0.84, 0.9 }))
            UpdateToggleVisual()
            if key == selectedItem then
                btn:SetBackdropColor(unpack(Theme.selectedSubtle or { 1, 1, 1, 0.024 }))
                if accentBar then accentBar:SetColorTexture(unpack(Theme.gold)) end
                if wash then wash:Show() end
            else
                btn:SetBackdropColor(0, 0, 0, 0)
                if wash then wash:Hide() end
                if btn._getEnabled then
                    local en = btn._getEnabled()
                    if accentBar then
                        if en then
                            accentBar:SetColorTexture(unpack(Theme.success or { 0.3, 0.85, 0.3, 1 }))
                        else
                            accentBar:SetColorTexture(1, 1, 1, 0.10)
                        end
                    end
                end
            end
        end)

        sidebarButtons[key] = btn
        yOff = yOff - MODULE_ROW_HEIGHT
    end

    --- Add an action button to the sidebar (e.g. "Import").
    function api:AddActionButton(text, onClick)
        local abtn = TrackSidebarFrame(MedaUI:CreateButton(sidebarScrollContent, text))
        abtn:SetHeight(22)
        abtn:SetPoint("TOPLEFT", 12, yOff)
        abtn:SetPoint("TOPRIGHT", -12, yOff)
        abtn:SetScript("OnClick", onClick)
        yOff = yOff - 28
    end

    --- Finish sidebar construction (sets scroll height).
    function api:EndSidebar()
        if sidebarScrollParent then
            sidebarScrollParent:SetContentHeight(math.abs(yOff) + 8, true, true)
        end
        if selectedItem and not sidebarButtons[selectedItem] then
            selectedItem = nil
        end
        UpdateSidebarSelection()
    end

    --- Set the legend entries shown at the bottom of the sidebar.
    --- @param entries table|nil Array of {label, color}. nil hides the legend.
    function api:SetLegend(entries)
        -- Clear existing children
        local oldRegions = { legendFrame:GetRegions() }
        for _, r in ipairs(oldRegions) do r:Hide() end

        if not entries or #entries == 0 then
            legendFrame:Hide()
            legendSep:Hide()
            return
        end

        legendFrame:Show()
        legendSep:Show()

        local lx = 0
        for _, entry in ipairs(entries) do
            local dot = legendFrame:CreateTexture(nil, "ARTWORK")
            dot:SetSize(6, 6)
            dot:SetPoint("LEFT", lx, 0)
            dot:SetColorTexture(unpack(entry.color))

            local lbl = legendFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lbl:SetPoint("LEFT", lx + 9, 0)
            lbl:SetText(entry.label)
            lbl:SetTextColor(unpack(entry.color))

            lx = lx + 9 + lbl:GetStringWidth() + 10
        end
    end

    --- Register a content builder for a sidebar item key.
    --- builder(contentFrame) is called when the item is selected.
    function api:SetContentBuilder(key, builder)
        contentBuilders[key] = builder
    end

    --- Set a callback for when any sidebar item is selected.
    function api:SetOnItemSelected(callback)
        onItemSelected = callback
    end

    --- Select a sidebar item and load its content.
    function api:SelectItem(key)
        LoadItem(key)
    end

    --- Set the scroll content height (call after building config UI).
    function api:SetContentHeight(height)
        if scrollChild and scrollFrame then
            scrollChild:SetHeight(math.max(height + configHeaderOffset, scrollFrame:GetHeight()))
        end
    end

    --- Register a frame for cleanup when content is cleared.
    function api:RegisterConfigCleanup(frame)
        configCleanupFrames[#configCleanupFrames + 1] = frame
    end

    --- Build a standard module config header (title, stability, version, description).
    --- Returns the total header height consumed.
    --- @param parent Frame The content parent frame
    --- @param headerConfig table { title, stability, stabilityColors, version, author, description }
    --- @return number headerHeight
    function api:BuildConfigHeader(parent, headerConfig)
        local Theme = MedaUI.Theme
        local headerHeight = 0

        local titleStr = headerConfig.title or "Module"
        local stability = headerConfig.stability
        local version = headerConfig.version
        local author = headerConfig.author or "Unknown"
        local description = headerConfig.description
        local stabColors = headerConfig.stabilityColors

        local titleText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        titleText:SetPoint("TOPLEFT", 0, 0)
        titleText:SetText(titleStr)
        titleText:SetTextColor(1, 1, 1, 0.98)
        local fontPath, _, fontFlags = titleText:GetFont()
        titleText:SetFont(fontPath, 22, fontFlags)

        if stability and stabColors and stabColors[stability] then
            local badge = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            badge:SetPoint("LEFT", titleText, "RIGHT", 10, 0)
            badge:SetText(stability)
            badge:SetTextColor(unpack(stabColors[stability]))
        end
        headerHeight = headerHeight + 28

        if version then
            local meta = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            meta:SetPoint("TOPLEFT", 0, -headerHeight)
            local ver = tostring(version)
            if ver:sub(1, 1):lower() ~= "v" then ver = "v" .. ver end
            meta:SetText(strupper(ver .. "  BY  " .. (author or "UNKNOWN")))
            meta:SetTextColor(1, 1, 1, 0.36)
            headerHeight = headerHeight + 18
        end

        if description and description ~= "" then
            headerHeight = headerHeight + 14

            local descBox = MedaUI:CreateThemedFrame(parent, nil, nil, nil, "background", "border")
            descBox:SetPoint("TOPLEFT", 0, -headerHeight)
            descBox:SetPoint("RIGHT", 0, 0)
            descBox:SetBackdropColor(1, 1, 1, 0.012)
            descBox:SetBackdropBorderColor(1, 1, 1, 0.035)

            local descAccent = descBox:CreateTexture(nil, "OVERLAY")
            descAccent:SetWidth(2)
            descAccent:SetPoint("TOPLEFT", 0, 0)
            descAccent:SetPoint("BOTTOMLEFT", 0, 0)
            descAccent:SetColorTexture(unpack(Theme.gold))

            local descText = descBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            descText:SetPoint("TOPLEFT", 10, -10)
            descText:SetPoint("RIGHT", -14, 0)
            descText:SetJustifyH("LEFT")
            descText:SetWordWrap(true)
            descText:SetText(description)
            descText:SetTextColor(1, 1, 1, 0.78)

            local descH = descText:GetStringHeight() + 20
            descBox:SetHeight(math.max(descH, 44))
            headerHeight = headerHeight + math.max(descH, 52)
        end

        headerHeight = headerHeight + 22
        configHeaderOffset = headerHeight
        return headerHeight
    end

    --- Add buttons to the footer bar.
    --- @param buttons table Array of { text, onClick, align = "left"|"right" }
    function api:SetFooterButtons(buttons)
        for _, b in ipairs(footerButtons) do b:Hide() end
        wipe(footerButtons)

        for _, def in ipairs(buttons) do
            local btn = MedaUI:CreateButton(buttonBar, def.text)
            Pixel.SetSize(btn, def.width or 120, 34)
            if def.align == "left" then
                btn:SetPoint("BOTTOMLEFT", 0, 6)
            else
                btn:SetPoint("BOTTOMRIGHT", 0, 6)
            end
            btn:SetScript("OnClick", def.onClick)
            footerButtons[#footerButtons + 1] = btn
        end
    end

    --- Set the watermark texture path.
    function api:SetWatermark(texturePath)
        if texturePath then
            watermark:SetTexture(texturePath)
            watermark:Show()
        else
            watermark:Hide()
        end
    end

    --- Show/hide the panel.
    function api:Show()
        panel:Show()
    end

    function api:Hide()
        panel:Hide()
    end

    function api:Toggle()
        if panel:IsShown() then
            panel:Hide()
        else
            panel:Show()
        end
    end

    function api:IsShown()
        return panel:IsShown()
    end

    --- Update the toggle visual for a specific module row by key.
    function api:RefreshModuleToggle(key)
        local btn = sidebarButtons[key]
        if not btn then return end

        local enabled = btn._getEnabled and btn._getEnabled() or false

        if btn.toggleCheck then
            btn.toggleCheck:SetShown(enabled)
            local Theme = MedaUI.Theme
            if btn.toggle then
                if enabled then
                    btn.toggle:SetBackdropColor(unpack(Theme.checkboxBgChecked or { 0.72, 0.75, 0.80, 0.12 }))
                    btn.toggle:SetBackdropBorderColor(unpack(Theme.checkboxBorderChecked or { 0.72, 0.75, 0.80, 0.44 }))
                else
                    btn.toggle:SetBackdropColor(unpack(Theme.checkboxBg or { 1, 1, 1, 0.03 }))
                    btn.toggle:SetBackdropBorderColor(unpack(Theme.checkboxBorder or { 1, 1, 1, 0.12 }))
                end
            end
        end

        if btn.accentBar then
            local Theme = MedaUI.Theme
            if key == selectedItem then
                btn.accentBar:SetColorTexture(unpack(Theme.gold))
            elseif enabled then
                btn.accentBar:SetColorTexture(unpack(Theme.success or { 0.3, 0.85, 0.3, 1 }))
            else
                btn.accentBar:SetColorTexture(1, 1, 1, 0.10)
            end
        end
    end

    --- Pass-through: CreateConfigTabs helper for content area tab bars.
    function api:CreateConfigTabs(parent, tabs)
        local tabBar = MedaUI:CreateTabBar(parent, tabs)
        tabBar:SetPoint("TOPLEFT", 0, 0)
        tabBar:SetPoint("RIGHT", 0, 0)

        local frames = {}
        for _, tab in ipairs(tabs) do
            local f = CreateFrame("Frame", nil, parent)
            f:SetPoint("TOPLEFT", 0, -36)
            f:SetPoint("RIGHT", 0, 0)
            f:SetHeight(5000)
            f:Hide()
            frames[tab.id] = f
        end

        frames[tabs[1].id]:Show()

        tabBar.OnTabChanged = function(_, tabId)
            for id, f in pairs(frames) do
                if id == tabId then f:Show() else f:Hide() end
            end
        end

        return tabBar, frames
    end

    --- Restore saved panel state.
    function api:RestoreState(state)
        panel:RestoreState(state)
    end

    --- Get saved panel state.
    function api:GetState()
        return panel:GetState()
    end

    return api
end
