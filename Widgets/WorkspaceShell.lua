--[[
    MedaUI WorkspaceShell Widget
    Two-column workspace with left navigation rail, right page chrome,
    persistent freshness strip, and scrollable content host.
]]

local MedaUI = LibStub("MedaUI-1.0")
local Pixel = LibStub("MedaUI-1.0").Pixel

local NAV_WIDTH = 190
local HEADER_HEIGHT = 84
local SUMMARY_HEIGHT = 18
local FRESHNESS_HEIGHT = 86
local TOOLBAR_WIDTH = 250
local HEADER_TEXT_RIGHT_GAP = TOOLBAR_WIDTH + 20
local NAV_GROUP_HEIGHT = 28
local NAV_ITEM_HEIGHT = 24
local CONTENT_INSET = 8

local function SafeColor(color, fallback)
    return color or fallback or { 1, 1, 1, 1 }
end

local function GetFreshnessState(lastFetched)
    if not lastFetched or lastFetched == 0 then
        return "unknown"
    end

    local age = time() - lastFetched
    if age < 0 then age = 0 end
    if age < 86400 then
        return "fresh"
    end
    if age < (86400 * 3) then
        return "aging"
    end
    return "stale"
end

local function GetRelativeTime(lastFetched)
    if not lastFetched or lastFetched == 0 then return "unknown" end

    local diff = time() - lastFetched
    if diff < 0 then return "just now" end

    local days = math.floor(diff / 86400)
    local hours = math.floor((diff % 86400) / 3600)
    local mins = math.floor((diff % 3600) / 60)

    if days > 0 then
        return string.format("%dd ago", days)
    end
    if hours > 0 then
        return string.format("%dhr ago", hours)
    end
    if mins > 0 then
        return string.format("%dm ago", mins)
    end
    return "just now"
end

function MedaUI:CreateFreshnessStrip(parent, width)
    local strip = CreateFrame("Frame", nil, parent)
    Pixel.SetSize(strip, width or 400, FRESHNESS_HEIGHT)

    strip.sources = {}
    strip.rows = {}

    strip.divider = strip:CreateTexture(nil, "ARTWORK")
    Pixel.SetHeight(strip.divider, 1)
    Pixel.SetPoint(strip.divider, "TOPLEFT", strip, "TOPLEFT", 0, 0)
    Pixel.SetPoint(strip.divider, "TOPRIGHT", strip, "TOPRIGHT", 0, 0)

    strip.label = strip:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    Pixel.SetPoint(strip.label, "TOPLEFT", 8, -8)
    strip.label:SetText("Data Freshness")

    strip.listHost = CreateFrame("Frame", nil, strip)
    Pixel.SetPoint(strip.listHost, "TOPLEFT", strip, "TOPLEFT", 8, -24)
    Pixel.SetPoint(strip.listHost, "BOTTOMRIGHT", strip, "BOTTOMRIGHT", -8, 4)

    local function GetSourceLineLabel(source)
        local labels = {
            wowhead = "wowhead",
            icyveins = "icy-veins",
            archon = "archon",
        }
        return labels[source.id] or string.lower(source.label or "unknown")
    end

    local function ApplyTheme()
        local theme = MedaUI.Theme
        strip.divider:SetColorTexture(unpack(theme.divider or { 1, 1, 1, 0.08 }))
        strip.label:SetTextColor(unpack(theme.textDim or { 0.6, 0.6, 0.6, 1 }))

        for _, row in ipairs(strip.rows) do
            if row._applyState then
                row:_applyState()
            end
        end
    end

    strip._themeHandle = MedaUI:RegisterThemedWidget(strip, ApplyTheme)
    ApplyTheme()

    local function AcquireRow(index)
        local row = strip.rows[index]
        if row then return row end

        row = CreateFrame("Frame", nil, strip.listHost)
        Pixel.SetHeight(row, 16)

        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        Pixel.SetPoint(row.text, "TOPLEFT", row, "TOPLEFT", 0, 0)
        Pixel.SetPoint(row.text, "TOPRIGHT", row, "TOPRIGHT", 0, 0)
        row.text:SetJustifyH("LEFT")
        row.text:SetWordWrap(false)

        function row:_applyState()
            local theme = MedaUI.Theme
            local state = self.state or "unknown"
            local sourceColor = SafeColor(self.sourceColor, theme.gold or { 0.9, 0.7, 0.15, 1 })
            local textColor = theme.text or { 0.9, 0.9, 0.9, 1 }

            if state == "aging" then
                sourceColor = theme.warning or { 1, 0.7, 0.2, 1 }
            elseif state == "stale" then
                sourceColor = theme.error or { 1, 0.3, 0.3, 1 }
            else
                sourceColor = theme.textDim or { 0.55, 0.55, 0.55, 1 }
                textColor = theme.textDim or { 0.55, 0.55, 0.55, 1 }
            end

            self.text:SetTextColor(textColor[1], textColor[2], textColor[3], textColor[4] or 1)
            self.text:SetText(string.format("|cff%02x%02x%02x%s|r: %s",
                math.floor(sourceColor[1] * 255),
                math.floor(sourceColor[2] * 255),
                math.floor(sourceColor[3] * 255),
                GetSourceLineLabel(self.source or {}),
                GetRelativeTime(self.source and self.source.lastFetched)))
        end

        strip.rows[index] = row
        return row
    end

    function strip:SetSources(sources)
        self.sources = sources or {}
        local sourceOrder = {
            wowhead = 1,
            icyveins = 2,
            archon = 3,
        }
        table.sort(self.sources, function(a, b)
            local aOrder = sourceOrder[a.id] or 99
            local bOrder = sourceOrder[b.id] or 99
            if aOrder ~= bOrder then
                return aOrder < bOrder
            end
            return (a.label or "") < (b.label or "")
        end)

        local y = 0

        for index, source in ipairs(self.sources) do
            local row = AcquireRow(index)
            row:Show()
            row.state = GetFreshnessState(source.lastFetched)
            row.sourceColor = source.color
            row.source = source
            Pixel.ClearPoints(row)
            Pixel.SetPoint(row, "TOPLEFT", self.listHost, "TOPLEFT", 0, y)
            Pixel.SetPoint(row, "TOPRIGHT", self.listHost, "TOPRIGHT", 0, y)
            row:_applyState()
            y = y - 18
        end

        for i = #self.sources + 1, #self.rows do
            self.rows[i]:Hide()
        end
    end

    return strip
end

function MedaUI:CreateWorkspaceShell(parent, config)
    config = config or {}
    local toolbarWidth = config.toolbarWidth or TOOLBAR_WIDTH
    local headerTextRightGap = config.headerTextRightGap or (toolbarWidth + 20)

    local shell = CreateFrame("Frame", nil, parent)
    shell:SetAllPoints()
    shell.navItems = {}
    shell.navButtons = {}
    shell.activePage = nil
    shell.OnNavigate = nil
    shell.OnGroupToggle = nil

    shell.navPane = CreateFrame("Frame", nil, shell, "BackdropTemplate")
    shell.navPane:SetBackdrop(self:CreateBackdrop(true))
    Pixel.SetPoint(shell.navPane, "TOPLEFT", shell, "TOPLEFT", 0, 0)
    Pixel.SetPoint(shell.navPane, "BOTTOMLEFT", shell, "BOTTOMLEFT", 0, 0)
    Pixel.SetWidth(shell.navPane, config.navWidth or NAV_WIDTH)

    shell.navFreshness = self:CreateFreshnessStrip(shell.navPane, (config.navWidth or NAV_WIDTH) - 12)
    Pixel.SetPoint(shell.navFreshness, "BOTTOMLEFT", shell.navPane, "BOTTOMLEFT", 6, 6)
    Pixel.SetPoint(shell.navFreshness, "BOTTOMRIGHT", shell.navPane, "BOTTOMRIGHT", -6, 6)

    shell.navScroll = self:CreateScrollFrame(shell.navPane)
    Pixel.SetPoint(shell.navScroll, "TOPLEFT", shell.navPane, "TOPLEFT", 6, -6)
    Pixel.SetPoint(shell.navScroll, "BOTTOMRIGHT", shell.navFreshness, "TOPRIGHT", -0, 0)

    shell.divider = shell:CreateTexture(nil, "ARTWORK")
    Pixel.SetWidth(shell.divider, 1)
    Pixel.SetPoint(shell.divider, "TOPLEFT", shell.navPane, "TOPRIGHT", 0, -8)
    Pixel.SetPoint(shell.divider, "BOTTOMLEFT", shell.navPane, "BOTTOMRIGHT", 0, 8)

    shell.header = CreateFrame("Frame", nil, shell)
    Pixel.SetPoint(shell.header, "TOPLEFT", shell.navPane, "TOPRIGHT", 10, 0)
    Pixel.SetPoint(shell.header, "TOPRIGHT", shell, "TOPRIGHT", 0, 0)
    Pixel.SetHeight(shell.header, HEADER_HEIGHT)

    shell.pageTitle = shell.header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    Pixel.SetPoint(shell.pageTitle, "TOPLEFT", 0, -2)
    Pixel.SetPoint(shell.pageTitle, "RIGHT", shell.header, "RIGHT", -headerTextRightGap, 0)
    shell.pageTitle:SetJustifyH("LEFT")

    shell.pageSubtitle = shell.header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    Pixel.SetPoint(shell.pageSubtitle, "TOPLEFT", shell.pageTitle, "BOTTOMLEFT", 0, -6)
    Pixel.SetPoint(shell.pageSubtitle, "RIGHT", shell.header, "RIGHT", -headerTextRightGap, 0)
    shell.pageSubtitle:SetJustifyH("LEFT")
    shell.pageSubtitle:SetWordWrap(true)

    shell.toolbar = CreateFrame("Frame", nil, shell.header)
    Pixel.SetPoint(shell.toolbar, "TOPRIGHT", shell.header, "TOPRIGHT", 0, -2)
    Pixel.SetSize(shell.toolbar, toolbarWidth, 24)

    shell.pageSummary = shell.header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    Pixel.SetPoint(shell.pageSummary, "BOTTOMLEFT", shell.header, "BOTTOMLEFT", 0, 2)
    Pixel.SetPoint(shell.pageSummary, "BOTTOMRIGHT", shell.header, "BOTTOMRIGHT", -headerTextRightGap, 2)
    shell.pageSummary:SetJustifyH("LEFT")
    shell.pageSummary:SetWordWrap(true)

    shell.contentHost = CreateFrame("Frame", nil, shell, "BackdropTemplate")
    shell.contentHost:SetBackdrop(self:CreateBackdrop(true))
    Pixel.SetPoint(shell.contentHost, "TOPLEFT", shell.header, "BOTTOMLEFT", 0, -6)
    Pixel.SetPoint(shell.contentHost, "BOTTOMRIGHT", shell, "BOTTOMRIGHT", 0, 0)

    shell.contentScroll = self:CreateScrollFrame(shell.contentHost)
    Pixel.SetPoint(shell.contentScroll, "TOPLEFT", shell.contentHost, "TOPLEFT", CONTENT_INSET, -CONTENT_INSET)
    Pixel.SetPoint(shell.contentScroll, "BOTTOMRIGHT", shell.contentHost, "BOTTOMRIGHT", -CONTENT_INSET, CONTENT_INSET)
    shell.contentScroll:SetScrollStep(36)
    shell.content = shell.contentScroll.scrollContent
    Pixel.SetHeight(shell.content, 1)

    local function ApplyTheme()
        local theme = MedaUI.Theme
        shell.navPane:SetBackdropColor(unpack(theme.backgroundDark or { 0.08, 0.08, 0.09, 0.9 }))
        shell.navPane:SetBackdropBorderColor(unpack(theme.border or { 0.2, 0.2, 0.22, 0.6 }))
        shell.contentHost:SetBackdropColor(unpack(theme.backgroundDark or { 0.08, 0.08, 0.09, 0.9 }))
        shell.contentHost:SetBackdropBorderColor(unpack(theme.border or { 0.2, 0.2, 0.22, 0.6 }))
        shell.divider:SetColorTexture(unpack(theme.divider or { 1, 1, 1, 0.08 }))
        shell.pageTitle:SetTextColor(unpack(theme.gold or { 0.9, 0.7, 0.15, 1 }))
        shell.pageSubtitle:SetTextColor(unpack(theme.text or { 0.95, 0.95, 0.95, 1 }))
        shell.pageSummary:SetTextColor(unpack(theme.text or { 0.95, 0.95, 0.95, 1 }))

        for _, button in pairs(shell.navButtons) do
            if button.ApplyVisualState then
                button:ApplyVisualState()
            end
        end
    end

    shell._themeHandle = self:RegisterThemedWidget(shell, ApplyTheme)
    ApplyTheme()

    local function CreateNavButton(isGroup)
        local button = CreateFrame("Button", nil, shell.navScroll.scrollContent, "BackdropTemplate")
        button:SetBackdrop(MedaUI:CreateBackdrop(false))
        button.isGroup = isGroup
        button.enabled = true
        button.expanded = false

        button.text = button:CreateFontString(nil, "OVERLAY", isGroup and "GameFontNormal" or "GameFontNormalSmall")
        Pixel.SetPoint(button.text, "LEFT", isGroup and 10 or 26, 0)
        Pixel.SetPoint(button.text, "RIGHT", -24, 0)
        button.text:SetJustifyH("LEFT")
        button.text:SetWordWrap(false)

        button.chevron = button:CreateTexture(nil, "OVERLAY")
        button.chevron:SetTexture(MedaUI.mediaPath .. "Textures\\chevron-right.tga")
        Pixel.SetSize(button.chevron, 10, 10)
        Pixel.SetPoint(button.chevron, "LEFT", 10, 0)
        if not isGroup then
            button.chevron:Hide()
        end

        function button:ApplyVisualState()
            local theme = MedaUI.Theme
            if not self.enabled then
                self:SetBackdropColor(0, 0, 0, 0)
                self.text:SetTextColor(unpack(theme.textDisabled or { 0.35, 0.35, 0.35, 1 }))
                self.chevron:SetVertexColor(unpack(theme.textDisabled or { 0.35, 0.35, 0.35, 1 }))
                return
            end

            if shell.activePage == self.pageId then
                self:SetBackdropColor(unpack(theme.selectedSubtle or { 1, 1, 1, 0.05 }))
                self.text:SetTextColor(unpack(theme.gold or { 0.9, 0.7, 0.15, 1 }))
            else
                self:SetBackdropColor(0, 0, 0, 0)
                self.text:SetTextColor(unpack(theme.text or { 0.9, 0.9, 0.9, 1 }))
            end

            self.chevron:SetVertexColor(unpack(theme.textDim or { 0.6, 0.6, 0.6, 1 }))
            self.chevron:SetRotation(self.expanded and math.rad(90) or 0)
        end

        button:SetScript("OnEnter", function(self)
            if not self.enabled or shell.activePage == self.pageId then return end
            local theme = MedaUI.Theme
            self:SetBackdropColor(unpack(theme.hoverSubtle or { 1, 1, 1, 0.02 }))
        end)

        button:SetScript("OnLeave", function(self)
            self:ApplyVisualState()
        end)

        button:SetScript("OnClick", function(self)
            if not self.enabled then return end
            if self.isGroup then
                self.expanded = not self.expanded
                if shell.OnGroupToggle then
                    shell:OnGroupToggle(self.pageId, self.expanded)
                end
                shell:RefreshNavigation()
                return
            end

            MedaUI:PlaySound("tabSwitch")
            shell:SetActivePage(self.pageId)
            if shell.OnNavigate then
                shell:OnNavigate(self.pageId)
            end
        end)

        return button
    end

    function shell:SetNavigation(items)
        self.navItems = items or {}
        self:RefreshNavigation()
    end

    function shell:RefreshNavigation()
        local y = 0
        local rowIndex = 0

        for _, button in pairs(self.navButtons) do
            button:Hide()
        end

        local function GetButton(key, isGroup)
            local button = self.navButtons[key]
            if not button then
                button = CreateNavButton(isGroup)
                self.navButtons[key] = button
            end
            button.isGroup = isGroup
            if isGroup then
                button.chevron:Show()
            else
                button.chevron:Hide()
            end
            return button
        end

        for _, item in ipairs(self.navItems) do
            rowIndex = rowIndex + 1
            local groupButton = GetButton("group:" .. tostring(rowIndex), item.children and #item.children > 0)
            groupButton.pageId = item.pageId
            groupButton.expanded = item.expanded
            groupButton.enabled = item.enabled ~= false
            groupButton.text:SetText(item.label or "")
            Pixel.SetPoint(groupButton, "TOPLEFT", self.navScroll.scrollContent, "TOPLEFT", 0, y)
            Pixel.SetPoint(groupButton, "RIGHT", self.navScroll.scrollContent, "RIGHT", 0, 0)
            Pixel.SetHeight(groupButton, NAV_GROUP_HEIGHT)
            groupButton:Show()
            groupButton:ApplyVisualState()
            y = y - NAV_GROUP_HEIGHT - 4

            if item.children and item.expanded then
                for childIndex, child in ipairs(item.children) do
                    local childButton = GetButton(string.format("child:%d:%d", rowIndex, childIndex), false)
                    childButton.pageId = child.pageId
                    childButton.enabled = child.enabled ~= false
                    childButton.text:SetText(child.label or "")
                    Pixel.SetPoint(childButton, "TOPLEFT", self.navScroll.scrollContent, "TOPLEFT", 0, y)
                    Pixel.SetPoint(childButton, "RIGHT", self.navScroll.scrollContent, "RIGHT", 0, 0)
                    Pixel.SetHeight(childButton, NAV_ITEM_HEIGHT)
                    childButton:Show()
                    childButton:ApplyVisualState()
                    y = y - NAV_ITEM_HEIGHT - 2
                end
                y = y - 4
            end
        end

        self.contentScroll.scrollContent:SetWidth(self.contentHost:GetWidth() - (CONTENT_INSET * 2))
        self.navScroll:SetContentHeight(math.abs(y) + 8, true, true)
    end

    function shell:SetActivePage(pageId)
        self.activePage = pageId
        for _, button in pairs(self.navButtons) do
            if button.ApplyVisualState then
                button:ApplyVisualState()
            end
        end
    end

    function shell:SetNavigationItemEnabled(pageId, enabled)
        for _, item in ipairs(self.navItems) do
            if item.pageId == pageId then
                item.enabled = enabled
            end
            for _, child in ipairs(item.children or {}) do
                if child.pageId == pageId then
                    child.enabled = enabled
                end
            end
        end
        self:RefreshNavigation()
    end

    function shell:SetPageTitle(title, subtitle)
        self.pageTitle:SetText(title or "")
        self.pageSubtitle:SetText(subtitle or "")
    end

    function shell:SetPageSummary(text, tone)
        self.pageSummary:SetText(text or "")
        local theme = MedaUI.Theme
        if tone == "warning" then
            self.pageSummary:SetTextColor(unpack(theme.text or { 0.95, 0.95, 0.95, 1 }))
        elseif tone == "error" then
            self.pageSummary:SetTextColor(unpack(theme.error or { 1, 0.3, 0.3, 1 }))
        else
            self.pageSummary:SetTextColor(unpack(theme.text or { 0.95, 0.95, 0.95, 1 }))
        end
    end

    function shell:GetToolbar()
        return self.toolbar
    end

    function shell:GetContent()
        return self.content
    end

    function shell:ClearContent()
        local children = { self.content:GetChildren() }
        for _, child in ipairs(children) do
            child:Hide()
            child:SetParent(nil)
        end
        local regions = { self.content:GetRegions() }
        for _, region in ipairs(regions) do
            region:Hide()
        end
        self.contentScroll:ResetScroll()
    end

    function shell:SetContentHeight(height)
        self.contentScroll:SetContentHeight(height or 1, true, true)
    end

    function shell:SetFreshnessSources(sources)
        self.navFreshness:SetSources(sources)
    end

    return shell
end
