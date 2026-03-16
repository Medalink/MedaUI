local MedaUI = LibStub("MedaUI-2.0")
---@cast MedaUI MedaUILibrary

local OptionsHostState = MedaUI.OptionsHostState or {}
MedaUI.OptionsHostState = OptionsHostState

function OptionsHostState.GetModuleState(host, moduleId)
    local state = host.moduleStates[moduleId]
    if not state then
        state = {
            pages = nil,
            selectedPageId = nil,
            pageStates = {},
            root = nil,
            pageHost = nil,
            tabBar = nil,
        }
        host.moduleStates[moduleId] = state
    end
    return state
end

function OptionsHostState.GetPageState(moduleState, pageId)
    local state = moduleState.pageStates[pageId]
    if not state then
        state = { frame = nil, body = nil, built = false }
        moduleState.pageStates[pageId] = state
    end
    return state
end

function OptionsHostState.ResolvePage(moduleState, pageId)
    for _, page in ipairs(moduleState.pages or {}) do
        if page.id == pageId then
            return page
        end
    end
end

function OptionsHostState.EnsureModuleRoot(moduleId, moduleConfig, moduleState, parentFrame, host)
    if not moduleState.root then
        moduleState.root = CreateFrame("Frame", nil, parentFrame)
        moduleState.root:SetPoint("TOPLEFT", 0, 0)
        moduleState.root:SetPoint("RIGHT", 0, 0)
        moduleState.root:SetHeight(5000)
        moduleState.pageHost = moduleState.root

        if #moduleState.pages > 1 then
            local tabs = {}
            for _, page in ipairs(moduleState.pages) do
                tabs[#tabs + 1] = { id = page.id, label = page.label }
            end

            moduleState.tabBar = MedaUI:CreateTabBar(moduleState.root, tabs)
            moduleState.tabBar:SetPoint("TOPLEFT", 0, 0)
            moduleState.tabBar:SetPoint("RIGHT", 0, 0)

            moduleState.pageHost = CreateFrame("Frame", nil, moduleState.root)
            moduleState.pageHost:SetPoint("TOPLEFT", 0, -36)
            moduleState.pageHost:SetPoint("RIGHT", 0, 0)
            moduleState.pageHost:SetHeight(5000)

            moduleState.tabBar.OnTabChanged = function(_, tabId)
                moduleState.selectedPageId = tabId
                host.activePageId = tabId
                if host.OnSelectionChanged then
                    host.OnSelectionChanged(moduleId, tabId)
                end
                host:RefreshActivePage(true)
            end
        end

        return
    end

    moduleState.root:SetParent(parentFrame)
    moduleState.root:ClearAllPoints()
    moduleState.root:SetPoint("TOPLEFT", 0, 0)
    moduleState.root:SetPoint("RIGHT", 0, 0)
    moduleState.root:Show()
end

function OptionsHostState.HideInactivePages(moduleState, activePageId)
    for id, state in pairs(moduleState.pageStates) do
        if id ~= activePageId and state.frame then
            state.frame:Hide()
        end
    end
end

function OptionsHostState.EnsurePageFrame(moduleState, pageState)
    if not pageState.frame then
        pageState.frame = CreateFrame("Frame", nil, moduleState.pageHost)
        pageState.frame:SetPoint("TOPLEFT", 0, 0)
        pageState.frame:SetPoint("RIGHT", 0, 0)
        pageState.frame:SetHeight(5000)
    else
        pageState.frame:SetParent(moduleState.pageHost)
    end

    pageState.frame:Show()
end
