local MedaUI = LibStub("MedaUI-2.0")
---@cast MedaUI MedaUILibrary
local Pixel = MedaUI.Pixel
local HostSupport = MedaUI.HostSupport

local DEFAULT_CONTENT_HEIGHT = 800

local OptionsHostView = MedaUI.OptionsHostView or {}
MedaUI.OptionsHostView = OptionsHostView

local function NormalizeVersionText(version)
    if version == nil or version == "" then
        return nil
    end

    local text = tostring(version)
    if text:sub(1, 1):lower() ~= "v" then
        text = "v" .. text
    end
    return text
end

local function ResolveStabilityColor(stability, stabilityColors, overrideColor)
    if overrideColor then
        return overrideColor
    end

    if stability and type(stabilityColors) == "table" and stabilityColors[stability] then
        return stabilityColors[stability]
    end

    local theme = MedaUI.Theme
    local token = stability and tostring(stability):lower() or ""
    if token == "" then
        return nil
    end

    if token == "stable" or token == "release" or token == "live" or token == "ready" then
        return theme.success or theme.gold or { 0.3, 0.85, 0.3, 1 }
    end

    if token == "beta" or token == "preview" or token == "experimental" or token == "wip" then
        return theme.warning or theme.gold or { 1.0, 0.6, 0.0, 1 }
    end

    if token == "alpha" or token == "unstable" or token == "deprecated" or token == "broken" then
        return theme.error or theme.warning or { 1, 0.3, 0.3, 1 }
    end

    return theme.textSection or theme.text or { 1, 1, 1, 0.7 }
end

function OptionsHostView.Create(panel, config)
    config = config or {}

    local content = panel:GetContent()
    local sidebarWidth = config.sidebarWidth or 260
    local footerHeight = 44
    local contentInset = 12

    local sidebar = CreateFrame("Frame", nil, content, "BackdropTemplate")
    sidebar:SetWidth(sidebarWidth)
    sidebar:SetPoint("TOPLEFT", 0, 0)
    sidebar:SetPoint("BOTTOMLEFT", 0, 0)
    sidebar:SetBackdrop(MedaUI:CreateBackdrop(false))

    ---@type MedaUIScrollFrame
    local sidebarScroll = MedaUI:CreateScrollFrame(sidebar)
    Pixel.SetPoint(sidebarScroll, "TOPLEFT", 0, -52)
    Pixel.SetPoint(sidebarScroll, "BOTTOMRIGHT", 0, 28)
    sidebarScroll:SetScrollStep(30)
    local sidebarContent = sidebarScroll.scrollContent
    Pixel.SetHeight(sidebarContent, 1)

    ---@type MedaUIScrollFrame
    local contentScroll = MedaUI:CreateScrollFrame(content)
    Pixel.SetPoint(contentScroll, "TOPLEFT", sidebar, "TOPRIGHT", contentInset + 1, -contentInset)
    Pixel.SetPoint(contentScroll, "BOTTOMRIGHT", -contentInset, contentInset + footerHeight)
    contentScroll:SetScrollStep(30)
    local contentFrame = contentScroll.scrollContent
    Pixel.SetHeight(contentFrame, 1)

    local footer = CreateFrame("Frame", nil, content)
    footer:SetHeight(footerHeight)
    footer:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMRIGHT", contentInset + 1, 0)
    footer:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -contentInset, 0)

    local divider = content:CreateTexture(nil, "ARTWORK")
    divider:SetWidth(1)
    divider:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 0, 0)
    divider:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMRIGHT", 0, 0)

    local brand = CreateFrame("Frame", nil, sidebar)
    brand:SetHeight(50)
    brand:SetPoint("TOPLEFT", 0, 0)
    brand:SetPoint("TOPRIGHT", 0, 0)
    panel:SetDragZone(brand)

    local brandLabel = brand:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    ---@cast brandLabel FontString
    brandLabel:SetPoint("TOPLEFT", 14, -10)
    brandLabel:SetText(strupper(config.title or "OPTIONS"))

    local brandSub = brand:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ---@cast brandSub FontString
    brandSub:SetPoint("TOPLEFT", brandLabel, "BOTTOMLEFT", 0, -2)
    brandSub:SetText(config.subtitle or "C O N F I G U R A T I O N")

    local legendSep = sidebar:CreateTexture(nil, "ARTWORK")
    ---@cast legendSep Texture
    legendSep:SetHeight(1)
    legendSep:SetPoint("BOTTOMLEFT", 10, 24)
    legendSep:SetPoint("BOTTOMRIGHT", -10, 24)

    local legend = CreateFrame("Frame", nil, sidebar)
    legend:SetHeight(20)
    legend:SetPoint("BOTTOMLEFT", 8, 4)
    legend:SetPoint("BOTTOMRIGHT", -8, 4)
    legend:Hide()

    if config.watermarkTexture then
        local watermark = content:CreateTexture(nil, "BACKGROUND", nil, -1)
        Pixel.SetSize(watermark, 620, 620)
        watermark:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 80, -200)
        watermark:SetTexture(config.watermarkTexture)
        watermark:SetAlpha(0.3)
    end

    local function ApplyTheme()
        local theme = MedaUI.Theme
        sidebar:SetBackdropColor(unpack(theme.backgroundDark or theme.background))
        divider:SetColorTexture(unpack(theme.divider or { 1, 1, 1, 0.06 }))
        legendSep:SetColorTexture(unpack(theme.divider or { 1, 1, 1, 0.06 }))
        brandLabel:SetTextColor(unpack(theme.gold or { 0.9, 0.7, 0.15, 1 }))
        brandSub:SetTextColor(1, 1, 1, 0.38)
    end

    MedaUI:RegisterThemedWidget(panel, ApplyTheme)
    ApplyTheme()

    ---@type table<string, OptionsHostSidebarButton>
    local sidebarButtons = {}
    ---@type Frame[]
    local sidebarRows = {}
    ---@type OptionsHostLegendEntry[]
    local legendEntries = {}
    ---@type MedaUIButton[]
    local footerButtons = {}
    local contentBuilders = {}
    local cleanupFrames = {}
    local selectedItem
    local onItemSelected
    local yOff = 0
    local headerOffset = 0

    local function ClearContent()
        for _, frame in ipairs(cleanupFrames) do
            HostSupport.Destroy(frame)
        end
        wipe(cleanupFrames)

        local children = { contentFrame:GetChildren() }
        for _, child in ipairs(children) do
            HostSupport.Detach(child)
        end

        local regions = { contentFrame:GetRegions() }
        for _, region in ipairs(regions) do
            region:Hide()
        end

        contentScroll:ResetScroll()
    end

    local function UpdateSelection()
        local theme = MedaUI.Theme
        for key, button in pairs(sidebarButtons) do
            if key == selectedItem then
                button:SetBackdropColor(unpack(theme.selectedSubtle or { 1, 1, 1, 0.024 }))
            else
                button:SetBackdropColor(0, 0, 0, 0)
            end

            if button._refresh then
                button:_refresh()
            end
        end
    end

    local function LoadItem(key)
        selectedItem = key
        ClearContent()
        UpdateSelection()
        headerOffset = 0

        local builder = contentBuilders[key]
        if builder then
            builder(contentFrame)
        end

        if onItemSelected then
            onItemSelected(key)
        end
    end

    local view = {}

    function view:BeginSidebar()
        for _, row in ipairs(sidebarRows) do
            HostSupport.Destroy(row)
        end
        wipe(sidebarRows)
        wipe(sidebarButtons)
        yOff = -4
    end

    function view:AddSection(text)
        ---@type Frame
        local row = CreateFrame("Frame", nil, sidebarContent)
        row:SetHeight(28)
        row:SetPoint("TOPLEFT", 0, yOff)
        row:SetPoint("TOPRIGHT", 0, yOff)

        local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        ---@cast label FontString
        label:SetPoint("LEFT", 14, 0)
        label:SetText(strupper(text))

        MedaUI:RegisterThemedWidget(row, function()
            label:SetTextColor(unpack(MedaUI.Theme.textSection or { 1, 1, 1, 0.42 }))
        end)

        sidebarRows[#sidebarRows + 1] = row
        yOff = yOff - 28
    end

    local function CreateSidebarButton(left, right, height, key, labelText)
        local button = CreateFrame("Button", nil, sidebarContent, "BackdropTemplate")
        ---@cast button OptionsHostSidebarButton
        button:SetHeight(height)
        button:SetPoint("TOPLEFT", left, yOff)
        button:SetPoint("TOPRIGHT", right, yOff)
        button:SetBackdrop(MedaUI:CreateBackdrop(false))
        button:SetBackdropColor(0, 0, 0, 0)

        local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ---@cast label FontString
        button.label = label
        button.label:SetPoint("LEFT", 14, 0)
        button.label:SetJustifyH("LEFT")
        button.label:SetWordWrap(false)
        button.label:SetText(labelText)

        button:SetScript("OnClick", function()
            MedaUI:PlaySound("click")
            LoadItem(key)
        end)

        button:SetScript("OnEnter", function(self)
            if key ~= selectedItem then
                self:SetBackdropColor(unpack(MedaUI.Theme.hoverSubtle or { 1, 1, 1, 0.012 }))
            end
        end)

        button:SetScript("OnLeave", function(self)
            if key ~= selectedItem then
                self:SetBackdropColor(0, 0, 0, 0)
            end
        end)

        sidebarRows[#sidebarRows + 1] = button
        sidebarButtons[key] = button
        yOff = yOff - height
        return button
    end

    function view:AddNavRow(key, label)
        local button = CreateSidebarButton(6, -6, 30, key, label)
        MedaUI:RegisterThemedWidget(button, function()
            button.label:SetTextColor(unpack(MedaUI.Theme.text or { 1, 1, 1, 1 }))
        end)
    end

    function view:AddModuleRow(key, label, rowConfig)
        rowConfig = rowConfig or {}
        local button = CreateSidebarButton(0, 0, 44, key, label)

        ---@type Frame
        local toggle = CreateFrame("Button", nil, button, "BackdropTemplate")
        Pixel.SetSize(toggle, 16, 16)
        toggle:SetPoint("LEFT", 14, 0)
        toggle:SetBackdrop(MedaUI:CreateBackdrop(true))

        local check = toggle:CreateTexture(nil, "OVERLAY")
        ---@cast check Texture
        check:SetTexture(MedaUI.mediaPath .. "Textures\\checkmark.tga")
        Pixel.SetSize(check, 12, 12)
        Pixel.SetPoint(check, "CENTER", 0, 0)

        button.label:SetPoint("LEFT", 52, 0)
        button._getEnabled = rowConfig.getEnabled

        local accent = button:CreateTexture(nil, "OVERLAY")
        ---@cast accent Texture
        accent:SetWidth(3)
        accent:SetPoint("TOPLEFT", 0, -4)
        accent:SetPoint("BOTTOMLEFT", 0, 4)

        local tagText = rowConfig.customTag
        local versionText = NormalizeVersionText(rowConfig.version)

        local tagLabel
        if tagText and tagText ~= "" then
            tagLabel = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            ---@cast tagLabel FontString
            tagLabel:SetPoint("RIGHT", -14, 0)
            tagLabel:SetText(tagText)
        end

        local versionLabel
        if versionText then
            versionLabel = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            ---@cast versionLabel FontString
            if tagLabel then
                versionLabel:SetPoint("RIGHT", tagLabel, "LEFT", -6, 0)
            else
                versionLabel:SetPoint("RIGHT", -14, 0)
            end
            versionLabel:SetText(versionText)
        end

        local function RefreshToggle()
            local theme = MedaUI.Theme
            local stabilityColor = ResolveStabilityColor(rowConfig.stability, rowConfig.stabilityColors, rowConfig.customColor)
            local enabled = button._getEnabled and button._getEnabled() or false
            check:SetShown(enabled)

            if enabled then
                toggle:SetBackdropColor(unpack(theme.checkboxBgChecked or { 0.72, 0.75, 0.80, 0.12 }))
                toggle:SetBackdropBorderColor(unpack(theme.checkboxBorderChecked or { 0.72, 0.75, 0.80, 0.44 }))
            else
                toggle:SetBackdropColor(unpack(theme.checkboxBg or { 1, 1, 1, 0.03 }))
                toggle:SetBackdropBorderColor(unpack(theme.checkboxBorder or { 1, 1, 1, 0.12 }))
            end

            if selectedItem == key then
                accent:SetColorTexture(unpack(theme.gold or { 0.9, 0.7, 0.15, 1 }))
            elseif enabled then
                accent:SetColorTexture(unpack(theme.success or { 0.3, 0.85, 0.3, 1 }))
            else
                accent:SetColorTexture(1, 1, 1, 0.10)
            end

            if stabilityColor then
                button.label:SetTextColor(unpack(stabilityColor))
            else
                button.label:SetTextColor(unpack(theme.text or { 1, 1, 1, 1 }))
            end

            if tagLabel then
                tagLabel:SetTextColor(unpack(stabilityColor or theme.textSection or theme.text or { 1, 1, 1, 0.7 }))
            end

            if versionLabel then
                versionLabel:SetTextColor(1, 1, 1, 0.28)
            end
        end

        if versionLabel then
            button.label:SetPoint("RIGHT", versionLabel, "LEFT", -6, 0)
        elseif tagLabel then
            button.label:SetPoint("RIGHT", tagLabel, "LEFT", -6, 0)
        else
            button.label:SetPoint("RIGHT", -14, 0)
        end

        button._refresh = RefreshToggle

        toggle:SetScript("OnClick", function()
            local enabled = button._getEnabled and button._getEnabled() or false
            if rowConfig.onToggle then
                rowConfig.onToggle(key, not enabled)
            end
            RefreshToggle()
            if selectedItem == key then
                LoadItem(key)
            end
        end)

        MedaUI:RegisterThemedWidget(button, function()
            RefreshToggle()
        end)

        RefreshToggle()
    end

    function view:EndSidebar()
        sidebarScroll:SetContentHeight(math.abs(yOff) + 8, true, true)
        UpdateSelection()
    end

    function view:SetLegend(entries)
        if not entries or #entries == 0 then
            legend:Hide()
            legendSep:Hide()
            for _, entryFrame in ipairs(legendEntries) do
                entryFrame:Hide()
            end
            return
        end

        local function AcquireLegendEntry(index)
            local entryFrame = legendEntries[index]
            if entryFrame then
                return entryFrame
            end

            local newEntryFrame = CreateFrame("Frame", nil, legend)
            ---@cast newEntryFrame OptionsHostLegendEntry
            newEntryFrame:SetHeight(20)
            local dot = newEntryFrame:CreateTexture(nil, "ARTWORK")
            ---@cast dot Texture
            newEntryFrame.dot = dot
            newEntryFrame.dot:SetSize(6, 6)
            newEntryFrame.dot:SetPoint("LEFT", 0, 0)
            local label = newEntryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            ---@cast label FontString
            newEntryFrame.label = label
            newEntryFrame.label:SetPoint("LEFT", newEntryFrame.dot, "RIGHT", 3, 0)
            legendEntries[index] = newEntryFrame
            return newEntryFrame
        end

        legend:Show()
        legendSep:Show()

        local x = 0
        for index, entry in ipairs(entries) do
            local entryFrame = AcquireLegendEntry(index)
            entryFrame:Show()
            entryFrame:ClearAllPoints()
            entryFrame:SetPoint("LEFT", legend, "LEFT", x, 0)
            entryFrame.dot:SetColorTexture(unpack(entry.color))
            entryFrame.label:SetText(entry.label)
            entryFrame.label:SetTextColor(unpack(entry.color))
            entryFrame:SetWidth(9 + entryFrame.label:GetStringWidth())
            x = x + entryFrame:GetWidth() + 10
        end

        for index = #entries + 1, #legendEntries do
            legendEntries[index]:Hide()
        end
    end

    function view:SetContentBuilder(key, builder)
        contentBuilders[key] = builder
    end

    function view:SetOnItemSelected(callback)
        onItemSelected = callback
    end

    function view:SelectItem(key)
        LoadItem(key)
    end

    function view:SetContentHeight(height)
        contentFrame:SetHeight(math.max((height or DEFAULT_CONTENT_HEIGHT) + headerOffset, contentScroll.scrollFrame:GetHeight()))
    end

    function view:RegisterConfigCleanup(frame)
        cleanupFrames[#cleanupFrames + 1] = frame
    end

    function view:BuildConfigHeader(parent, headerConfig)
        local theme = MedaUI.Theme
        local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        ---@cast title FontString
        title:SetPoint("TOPLEFT", 0, 0)
        title:SetText(headerConfig.title or "Module")
        title:SetTextColor(1, 1, 1, 0.98)
        local height = 28

        local stabilityText = headerConfig.stability
        local stabilityColor = ResolveStabilityColor(stabilityText, headerConfig.stabilityColors, headerConfig.customColor)
        if stabilityText and stabilityText ~= "" then
            local badge = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            ---@cast badge FontString
            badge:SetPoint("LEFT", title, "RIGHT", 10, 0)
            badge:SetText(stabilityText)
            badge:SetTextColor(unpack(stabilityColor or theme.textSection or theme.text or { 1, 1, 1, 0.7 }))
        end

        local metaParts = {}
        local versionText = NormalizeVersionText(headerConfig.version)
        if versionText then
            metaParts[#metaParts + 1] = versionText
        end
        if headerConfig.author and headerConfig.author ~= "" then
            metaParts[#metaParts + 1] = "by " .. tostring(headerConfig.author)
        end
        if #metaParts > 0 then
            local meta = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            ---@cast meta FontString
            meta:SetPoint("TOPLEFT", 0, -height)
            meta:SetText(table.concat(metaParts, "  "))
            meta:SetTextColor(1, 1, 1, 0.36)
            height = height + 18
        end

        if headerConfig.description and headerConfig.description ~= "" then
            local desc = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            ---@cast desc FontString
            desc:SetPoint("TOPLEFT", 0, -height)
            desc:SetPoint("RIGHT", 0, 0)
            desc:SetJustifyH("LEFT")
            desc:SetWordWrap(true)
            desc:SetText(headerConfig.description)
            desc:SetTextColor(1, 1, 1, 0.78)
            height = height + desc:GetStringHeight() + 18
        end

        headerOffset = height + 16
        return headerOffset
    end

    function view:SetFooterButtons(buttons)
        for _, button in ipairs(footerButtons) do
            HostSupport.Destroy(button)
        end
        wipe(footerButtons)

        local leftIndex = 0
        local rightIndex = 0
        for _, definition in ipairs(buttons or {}) do
            local width = definition.width or 120
            local button = MedaUI:CreateButton(footer, definition.text, width, 34)
            ---@cast button MedaUIButton
            if definition.align == "left" then
                button:SetPoint("BOTTOMLEFT", leftIndex * (width + 8), 6)
                leftIndex = leftIndex + 1
            else
                button:SetPoint("BOTTOMRIGHT", -(rightIndex * (width + 8)), 6)
                rightIndex = rightIndex + 1
            end
            button:SetScript("OnClick", definition.onClick)
            footerButtons[#footerButtons + 1] = button
        end
    end

    function view:RefreshModuleToggle(moduleId)
        local button = sidebarButtons[moduleId]
        if button and button._refresh then
            button:_refresh()
        end
    end

    function view:CreateConfigTabs(parent, tabs)
        ---@type MedaUITabBar
        local tabBar = MedaUI:CreateTabBar(parent, tabs)
        tabBar:SetPoint("TOPLEFT", 0, 0)
        tabBar:SetPoint("RIGHT", 0, 0)

        local frames = {}
        for _, tab in ipairs(tabs) do
            local frame = CreateFrame("Frame", nil, parent)
            frame:SetPoint("TOPLEFT", 0, -36)
            frame:SetPoint("RIGHT", 0, 0)
            frame:SetHeight(5000)
            frame:Hide()
            frames[tab.id] = frame
        end

        if tabs[1] then
            frames[tabs[1].id]:Show()
        end

        tabBar.OnTabChanged = function(_, tabId)
            for id, frame in pairs(frames) do
                if id == tabId then
                    frame:Show()
                else
                    frame:Hide()
                end
            end
        end

        return tabBar, frames
    end

    panel:HookScript("OnHide", ClearContent)

    return view
end
