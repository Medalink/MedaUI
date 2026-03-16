--[[
    MedaUI TabBar Widget
    Horizontal tab strip for switching views
]]

local MedaUI = LibStub("MedaUI-2.0")
---@cast MedaUI MedaUILibrary
local Pixel = LibStub("MedaUI-2.0").Pixel

--- Create a tab bar
--- @param parent Frame Parent frame
--- @param tabs table Array of {id, label, badge?} tab definitions
--- @return Frame The tab bar frame
function MedaUI.CreateTabBar(library, parent, tabs)
    local tabBar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    Pixel.SetHeight(tabBar, 28)
    tabBar:SetBackdrop(library:CreateBackdrop(false))

    tabBar.tabs = {}
    tabBar.tabButtons = {}
    tabBar.activeTab = nil
    tabBar.OnTabChanged = nil

    local tabPadding = 4
    local minTabWidth = 60
    local tabHorizontalPadding = 40  -- Total padding (20px each side)

    -- Apply theme colors to the tab bar background
    local function ApplyTheme()
        local theme = MedaUI.Theme
        tabBar:SetBackdropColor(unpack(theme.backgroundDark))

        -- Update all tab buttons
        for id, tab in pairs(tabBar.tabButtons) do
            if id == tabBar.activeTab then
                tab:SetBackdropColor(unpack(theme.tabActive))
                tab.text:SetTextColor(unpack(theme.gold))
                tab.activeIndicator:SetColorTexture(unpack(theme.gold))
            else
                tab:SetBackdropColor(unpack(theme.tabInactive))
                tab.text:SetTextColor(unpack(theme.textDim))
            end
        end
    end
    tabBar._ApplyTheme = ApplyTheme

    -- Register for theme updates
    tabBar._themeHandle = MedaUI:RegisterThemedWidget(tabBar, ApplyTheme)

    -- Create tab buttons
    local xOffset = tabPadding
    for i, tabDef in ipairs(tabs) do
        local tab = CreateFrame("Button", nil, tabBar, "BackdropTemplate")
        Pixel.SetHeight(tab, 26)
        tab:SetBackdrop(library:CreateBackdrop(false))

        tab.id = tabDef.id
        tab.label = tabDef.label

        -- Tab text
        tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        Pixel.SetPoint(tab.text, "CENTER", 0, 0)
        tab.text:SetText(tabDef.label)

        -- Calculate tab width based on actual text width + padding
        local textWidth = tab.text:GetStringWidth()
        local tabWidth = math.max(minTabWidth, textWidth + tabHorizontalPadding)
        Pixel.SetSize(tab, tabWidth, 26)
        Pixel.SetPoint(tab, "LEFT", xOffset, 0)
        xOffset = xOffset + tabWidth + tabPadding

        -- Active indicator (gold line at bottom)
        tab.activeIndicator = tab:CreateTexture(nil, "OVERLAY")
        Pixel.SetHeight(tab.activeIndicator, 2)
        Pixel.SetPoint(tab.activeIndicator, "BOTTOMLEFT", 0, 0)
        Pixel.SetPoint(tab.activeIndicator, "BOTTOMRIGHT", 0, 0)
        tab.activeIndicator:Hide()

        -- Badge (optional)
        if tabDef.badge then
            tab.badge = library:CreateBadge(tab)
            Pixel.SetPoint(tab.badge, "RIGHT", tab, "RIGHT", -4, 0)
            tab.badge:SetCount(tabDef.badge)
        end

        -- Hover effects
        tab:SetScript("OnEnter", function(widget)
            if tabBar.activeTab ~= widget.id then
                MedaUI:PlaySound("hover")
                local theme = MedaUI.Theme
                widget:SetBackdropColor(unpack(theme.buttonHover))
                widget.text:SetTextColor(unpack(theme.text))
            end
        end)

        tab:SetScript("OnLeave", function(widget)
            if tabBar.activeTab ~= widget.id then
                local theme = MedaUI.Theme
                widget:SetBackdropColor(unpack(theme.tabInactive))
                widget.text:SetTextColor(unpack(theme.textDim))
            end
        end)

        -- Click handler
        tab:SetScript("OnClick", function(widget)
            MedaUI:PlaySound("tabSwitch")
            tabBar:SetActiveTab(widget.id)
        end)

        tabBar.tabButtons[tabDef.id] = tab
        tabBar.tabs[i] = tabDef
    end

    -- Set total width (xOffset already includes final padding)
    Pixel.SetWidth(tabBar, xOffset)

    -- Initial theme application
    ApplyTheme()

    --- Set the active tab
    --- @param tabId string The tab id to activate
    function tabBar:SetActiveTab(tabId)
        local previousTab = self.activeTab
        self.activeTab = tabId
        local theme = MedaUI.Theme

        -- Update visual states
        for id, tab in pairs(self.tabButtons) do
            if id == tabId then
                tab:SetBackdropColor(unpack(theme.tabActive))
                tab.text:SetTextColor(unpack(theme.gold))
                tab.activeIndicator:SetColorTexture(unpack(theme.gold))
                tab.activeIndicator:Show()
            else
                tab:SetBackdropColor(unpack(theme.tabInactive))
                tab.text:SetTextColor(unpack(theme.textDim))
                tab.activeIndicator:Hide()
            end
        end

        -- Fire callback if tab changed
        if previousTab ~= tabId and self.OnTabChanged then
            self:OnTabChanged(tabId, previousTab)
        end
    end

    --- Get the currently active tab
    --- @return string|nil The active tab id
    function tabBar:GetActiveTab()
        return self.activeTab
    end

    --- Set badge count for a tab
    --- @param tabId string The tab id
    --- @param count number The badge count
    function tabBar:SetBadge(tabId, count)
        local tab = self.tabButtons[tabId]
        if tab then
            if not tab.badge then
                tab.badge = library:CreateBadge(tab)
                Pixel.SetPoint(tab.badge, "RIGHT", tab, "RIGHT", -4, 0)
            end
            tab.badge:SetCount(count)
        end
    end

    --- Get a tab button by id
    --- @param tabId string The tab id
    --- @return Button|nil The tab button
    function tabBar:GetTab(tabId)
        return self.tabButtons[tabId]
    end

    -- Set first tab as active by default
    if tabs[1] then
        tabBar:SetActiveTab(tabs[1].id)
    end

    return tabBar
end
