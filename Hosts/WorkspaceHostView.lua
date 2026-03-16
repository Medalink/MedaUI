local MedaUI = LibStub("MedaUI-2.0")
---@cast MedaUI MedaUILibrary
local Pixel = MedaUI.Pixel
local HostSupport = MedaUI.HostSupport
local WorkspaceHostSupport = MedaUI.WorkspaceHostSupport
local WorkspaceHostNavigation = MedaUI.WorkspaceHostNavigation

local NAV_WIDTH = 190
local HEADER_HEIGHT = 112
local TOOLBAR_WIDTH = 250
local CONTENT_INSET = 8
local NAV_GROUP_HEIGHT = 28
local NAV_ITEM_HEIGHT = 24

local WorkspaceHostView = MedaUI.WorkspaceHostView or {}
MedaUI.WorkspaceHostView = WorkspaceHostView

function WorkspaceHostView.Create(library, parent, config)
    config = config or {}

    local shell = CreateFrame("Frame", nil, parent)
    ---@cast shell WorkspaceHostShell
    shell:SetAllPoints()
    shell.navItems = {}
    shell.navButtons = {}
    shell.activePage = nil
    shell.pageRegistry = {}
    shell.pageCache = {}
    shell.pageOrder = {}
    shell._layoutRefreshPending = false

    shell.navPane = CreateFrame("Frame", nil, shell, "BackdropTemplate")
    shell.navPane:SetBackdrop(library:CreateBackdrop(true))
    Pixel.SetPoint(shell.navPane, "TOPLEFT", shell, "TOPLEFT", 0, 0)
    Pixel.SetPoint(shell.navPane, "BOTTOMLEFT", shell, "BOTTOMLEFT", 0, 0)
    Pixel.SetWidth(shell.navPane, config.navWidth or NAV_WIDTH)

    local navFreshness = WorkspaceHostSupport.CreateFreshnessStrip(shell.navPane, (config.navWidth or NAV_WIDTH) - 12)
    ---@cast navFreshness WorkspaceFreshnessStrip
    shell.navFreshness = navFreshness
    Pixel.SetPoint(shell.navFreshness, "BOTTOMLEFT", shell.navPane, "BOTTOMLEFT", 6, 6)
    Pixel.SetPoint(shell.navFreshness, "BOTTOMRIGHT", shell.navPane, "BOTTOMRIGHT", -6, 6)

    shell.navScroll = library:CreateScrollFrame(shell.navPane)
    Pixel.SetPoint(shell.navScroll, "TOPLEFT", shell.navPane, "TOPLEFT", 6, -6)
    Pixel.SetPoint(shell.navScroll, "BOTTOMRIGHT", shell.navFreshness, "TOPRIGHT", 0, 0)

    local divider = shell:CreateTexture(nil, "ARTWORK")
    ---@cast divider Texture
    shell.divider = divider
    Pixel.SetWidth(shell.divider, 1)
    Pixel.SetPoint(shell.divider, "TOPLEFT", shell.navPane, "TOPRIGHT", 0, -8)
    Pixel.SetPoint(shell.divider, "BOTTOMLEFT", shell.navPane, "BOTTOMRIGHT", 0, 8)

    shell.header = CreateFrame("Frame", nil, shell)
    Pixel.SetPoint(shell.header, "TOPLEFT", shell.navPane, "TOPRIGHT", 10, 0)
    Pixel.SetPoint(shell.header, "TOPRIGHT", shell, "TOPRIGHT", 0, 0)
    Pixel.SetHeight(shell.header, HEADER_HEIGHT)

    shell.toolbar = CreateFrame("Frame", nil, shell.header)
    Pixel.SetPoint(shell.toolbar, "BOTTOMRIGHT", shell.header, "BOTTOMRIGHT", 0, 0)
    Pixel.SetSize(shell.toolbar, config.toolbarWidth or TOOLBAR_WIDTH, 24)

    shell.headerText = CreateFrame("Frame", nil, shell.header)
    Pixel.SetPoint(shell.headerText, "TOPLEFT", shell.header, "TOPLEFT", 0, 0)
    Pixel.SetPoint(shell.headerText, "TOPRIGHT", shell.header, "TOPRIGHT", 0, 0)
    Pixel.SetPoint(shell.headerText, "BOTTOM", shell.toolbar, "TOP", 0, 10)

    local pageTitle = shell.headerText:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    ---@cast pageTitle FontString
    shell.pageTitle = pageTitle
    Pixel.SetPoint(shell.pageTitle, "TOPLEFT", shell.headerText, "TOPLEFT", 0, -2)
    Pixel.SetPoint(shell.pageTitle, "TOPRIGHT", shell.headerText, "TOPRIGHT", 0, -2)
    shell.pageTitle:SetJustifyH("LEFT")
    shell.pageTitle:SetWordWrap(false)

    local pageSubtitle = shell.headerText:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ---@cast pageSubtitle FontString
    shell.pageSubtitle = pageSubtitle
    Pixel.SetPoint(shell.pageSubtitle, "TOPLEFT", shell.pageTitle, "BOTTOMLEFT", 0, -6)
    Pixel.SetPoint(shell.pageSubtitle, "TOPRIGHT", shell.headerText, "TOPRIGHT", 0, -30)
    shell.pageSubtitle:SetJustifyH("LEFT")
    shell.pageSubtitle:SetWordWrap(true)

    local pageSummary = shell.headerText:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ---@cast pageSummary FontString
    shell.pageSummary = pageSummary
    Pixel.SetPoint(shell.pageSummary, "BOTTOMLEFT", shell.headerText, "BOTTOMLEFT", 0, 2)
    Pixel.SetPoint(shell.pageSummary, "BOTTOMRIGHT", shell.headerText, "BOTTOMRIGHT", 0, 2)
    shell.pageSummary:SetJustifyH("LEFT")
    shell.pageSummary:SetWordWrap(true)

    shell.contentHost = CreateFrame("Frame", nil, shell, "BackdropTemplate")
    shell.contentHost:SetBackdrop(library:CreateBackdrop(true))
    Pixel.SetPoint(shell.contentHost, "TOPLEFT", shell.header, "BOTTOMLEFT", 0, -6)
    Pixel.SetPoint(shell.contentHost, "BOTTOMRIGHT", shell, "BOTTOMRIGHT", 0, 0)

    shell.contentScroll = library:CreateScrollFrame(shell.contentHost)
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

    MedaUI:RegisterThemedWidget(shell, ApplyTheme)
    ApplyTheme()

    function shell:SetNavigation(items)
        self.navItems = items or {}
        self:RefreshNavigation()
    end

    function shell:RefreshNavigation()
        WorkspaceHostNavigation.Refresh(self, NAV_GROUP_HEIGHT, NAV_ITEM_HEIGHT)
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
        WorkspaceHostNavigation.SetItemEnabled(self, pageId, enabled)
        self:RefreshNavigation()
    end

    function shell:SetPageTitle(title, subtitle)
        self.pageTitle:SetText(title or "")
        self.pageSubtitle:SetText(subtitle or "")
    end

    function shell:SetPageSummary(text, tone)
        self.pageSummary:SetText(text or "")
        local theme = MedaUI.Theme
        if tone == "error" then
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
            HostSupport.Detach(child)
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
