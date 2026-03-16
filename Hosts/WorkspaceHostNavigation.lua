local MedaUI = LibStub("MedaUI-2.0")
---@cast MedaUI MedaUILibrary
local Pixel = MedaUI.Pixel

local WorkspaceHostNavigation = MedaUI.WorkspaceHostNavigation or {}
MedaUI.WorkspaceHostNavigation = WorkspaceHostNavigation

function WorkspaceHostNavigation.CreateNavButton(shell, isGroup, navItemHeight, navGroupHeight)
    local button = CreateFrame("Button", nil, shell.navScroll.scrollContent, "BackdropTemplate")
    ---@cast button WorkspaceHostNavButton
    button:SetBackdrop(MedaUI:CreateBackdrop(false))
    button.isGroup = isGroup
    button.enabled = true
    button.expanded = false
    button._navItemHeight = navItemHeight
    button._navGroupHeight = navGroupHeight

    local text = button:CreateFontString(nil, "OVERLAY", isGroup and "GameFontNormal" or "GameFontNormalSmall")
    ---@cast text FontString
    button.text = text
    Pixel.SetPoint(button.text, "LEFT", isGroup and 24 or 26, 0)
    Pixel.SetPoint(button.text, "RIGHT", -24, 0)
    button.text:SetJustifyH("LEFT")
    button.text:SetWordWrap(false)

    local chevron = button:CreateTexture(nil, "OVERLAY")
    ---@cast chevron Texture
    button.chevron = chevron
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

    button:SetScript("OnClick", function(self)
        if not self.enabled then
            return
        end

        if self.isGroup then
            self.expanded = not self.expanded
            if shell.OnGroupToggle then
                shell:OnGroupToggle(self.pageId, self.expanded)
            end
            shell:RefreshNavigation()
            return
        end

        shell:SetActivePage(self.pageId)
        if shell.OnNavigate then
            shell:OnNavigate(self.pageId)
        end
    end)

    return button
end

function WorkspaceHostNavigation.Refresh(shell, navGroupHeight, navItemHeight)
    local y = 0
    for _, button in pairs(shell.navButtons) do
        button:Hide()
    end

    local function GetButton(key, isGroup)
        local button = shell.navButtons[key]
        if not button then
            button = WorkspaceHostNavigation.CreateNavButton(shell, isGroup, navItemHeight, navGroupHeight)
            shell.navButtons[key] = button
        end
        button.isGroup = isGroup
        if isGroup then
            button.chevron:Show()
        else
            button.chevron:Hide()
        end
        return button
    end

    for rowIndex, item in ipairs(shell.navItems) do
        local groupButton = GetButton("group:" .. rowIndex, item.children and #item.children > 0)
        groupButton.pageId = item.pageId
        groupButton.expanded = item.expanded
        groupButton.enabled = item.enabled ~= false
        groupButton.text:SetText(item.label or "")
        Pixel.SetPoint(groupButton, "TOPLEFT", shell.navScroll.scrollContent, "TOPLEFT", 0, y)
        Pixel.SetPoint(groupButton, "RIGHT", shell.navScroll.scrollContent, "RIGHT", 0, 0)
        Pixel.SetHeight(groupButton, navGroupHeight)
        groupButton:Show()
        groupButton:ApplyVisualState()
        y = y - navGroupHeight - 4

        if item.children and item.expanded then
            for childIndex, child in ipairs(item.children) do
                local childButton = GetButton(string.format("child:%d:%d", rowIndex, childIndex), false)
                childButton.pageId = child.pageId
                childButton.enabled = child.enabled ~= false
                childButton.text:SetText(child.label or "")
                Pixel.SetPoint(childButton, "TOPLEFT", shell.navScroll.scrollContent, "TOPLEFT", 0, y)
                Pixel.SetPoint(childButton, "RIGHT", shell.navScroll.scrollContent, "RIGHT", 0, 0)
                Pixel.SetHeight(childButton, navItemHeight)
                childButton:Show()
                childButton:ApplyVisualState()
                y = y - navItemHeight - 2
            end
            y = y - 4
        end
    end

    shell.navScroll:SetContentHeight(math.abs(y) + 8, true, true)
end

function WorkspaceHostNavigation.SetItemEnabled(shell, pageId, enabled)
    for _, item in ipairs(shell.navItems) do
        if item.pageId == pageId then
            item.enabled = enabled
        end
        for _, child in ipairs(item.children or {}) do
            if child.pageId == pageId then
                child.enabled = enabled
            end
        end
    end
end
