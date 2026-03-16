local MedaUI = LibStub("MedaUI-2.0")
---@cast MedaUI MedaUILibrary
local HostSupport = MedaUI.HostSupport
local OptionsHostState = MedaUI.OptionsHostState
local OptionsHostSidebar = MedaUI.OptionsHostSidebar
local OptionsHostView = MedaUI.OptionsHostView

local DEFAULT_CONTENT_HEIGHT = 800

function MedaUI.CreateOptionsHost(library, config)
    config = config or {}

    local panel = library:CreatePanel(config.name or "MedaUIOptionsHost", config.width or 980, config.height or 760, config.title or "Options")
    ---@cast panel MedaUIPanel
    panel:SetHeadless(true)
    panel:SetResizable(true, {
        minWidth = config.minWidth or 640,
        minHeight = config.minHeight or 420,
    })

    local ui = OptionsHostView.Create(panel, config)

    local host = {
        panel = panel,
        ui = ui,
        modules = {},
        moduleOrder = {},
        moduleStates = {},
        activeModuleId = nil,
        activePageId = nil,
        activeContentHeight = nil,
        _layoutRefreshPending = false,
    }

    local function ScheduleLayoutRefresh()
        if host._layoutRefreshPending then
            return
        end

        host._layoutRefreshPending = true
        C_Timer.After(0, function()
            host._layoutRefreshPending = false
            if not panel:IsShown() or not host.activeModuleId then
                return
            end
            host:RefreshActivePage(true)
        end)
    end

    local function RegisterModuleBuilder(moduleId)
        ui:SetContentBuilder(moduleId, function(parentFrame)
            local moduleConfig = host.modules[moduleId]
            local moduleState = OptionsHostState.GetModuleState(host, moduleId)
            moduleState.pages = moduleState.pages or HostSupport.NormalizePages(moduleConfig)
            moduleState.selectedPageId = moduleState.selectedPageId or moduleState.pages[1].id
            host.activeModuleId = moduleId
            host.activePageId = moduleState.selectedPageId
            host.activeContentHeight = nil

            OptionsHostState.EnsureModuleRoot(moduleId, moduleConfig, moduleState, parentFrame, host)

            local page = OptionsHostState.ResolvePage(moduleState, moduleState.selectedPageId) or moduleState.pages[1]
            local pageState = OptionsHostState.GetPageState(moduleState, page.id)
            OptionsHostState.HideInactivePages(moduleState, page.id)
            OptionsHostState.EnsurePageFrame(moduleState, pageState)

            if not pageState.built then
                local offset = 0
                if not moduleConfig.hideHeader then
                    offset = ui:BuildConfigHeader(pageState.frame, {
                        title = page.title or moduleConfig.title or moduleId,
                        stability = page.stability or moduleConfig.stability,
                        stabilityColors = page.stabilityColors or moduleConfig.stabilityColors,
                        version = page.version or moduleConfig.version,
                        author = page.author or moduleConfig.author,
                        description = page.description or moduleConfig.description,
                    })
                end

                pageState.body = CreateFrame("Frame", nil, pageState.frame)
                pageState.body:SetPoint("TOPLEFT", 0, -offset)
                pageState.body:SetPoint("RIGHT", 0, 0)
                pageState.body:SetHeight(5000)

                local height = moduleConfig.buildPage(page.id, pageState.body, offset, host)
                host.activeContentHeight = tonumber(height)
                pageState.built = true
            elseif moduleConfig.onPageCacheRestore then
                moduleConfig.onPageCacheRestore(page.id, pageState.frame, host)
            end

            local height = host.activeContentHeight
            if not height and type(moduleConfig.pageHeights) == "table" then
                height = moduleConfig.pageHeights[page.id]
            end
            ui:SetContentHeight(height or moduleConfig.defaultPageHeight or DEFAULT_CONTENT_HEIGHT)
        end)
    end

    function host:RegisterModule(moduleId, moduleConfig)
        moduleConfig.id = moduleId
        self.modules[moduleId] = moduleConfig
        self.moduleOrder[#self.moduleOrder + 1] = moduleId
        RegisterModuleBuilder(moduleId)
    end

    function host:ClearModules()
        for moduleId, moduleState in pairs(self.moduleStates) do
            if moduleState.root then
                HostSupport.Destroy(moduleState.root)
            end
            self.moduleStates[moduleId] = nil
        end
        wipe(self.modules)
        wipe(self.moduleOrder)
    end

    function host:GetModuleOrder()
        local modules = {}
        for index, moduleId in ipairs(self.moduleOrder) do
            modules[index] = moduleId
        end
        return modules
    end

    function host:RebuildSidebar()
        ui:BeginSidebar()
        for _, section in ipairs(OptionsHostSidebar.BuildSections(self, config)) do
            ui:AddSection(section.title)
            for _, moduleId in ipairs(section.moduleIds) do
                local moduleConfig = self.modules[moduleId]
                local entryType = moduleConfig.entryType or ((moduleConfig.getEnabled or moduleConfig.setEnabled) and "module" or "nav")
                if entryType == "module" then
                    ui:AddModuleRow(moduleId, moduleConfig.sidebarLabel or moduleConfig.title or moduleId, {
                        getEnabled = moduleConfig.getEnabled,
                        stability = moduleConfig.stability,
                        stabilityColors = moduleConfig.stabilityColors,
                        version = moduleConfig.version,
                        author = moduleConfig.author,
                        onToggle = function(_, enabled)
                            if moduleConfig.setEnabled then
                                moduleConfig.setEnabled(enabled)
                            end
                            self:RefreshModuleToggle(moduleId)
                        end,
                    })
                else
                    ui:AddNavRow(moduleId, moduleConfig.sidebarLabel or moduleConfig.title or moduleId)
                end
            end
        end

        if config.legend then
            ui:SetLegend(config.legend)
        end

        ui:EndSidebar()
    end

    function host:SelectModule(moduleId, pageId)
        local state = OptionsHostState.GetModuleState(self, moduleId)
        state.pages = state.pages or HostSupport.NormalizePages(self.modules[moduleId])
        state.selectedPageId = pageId or state.selectedPageId or state.pages[1].id
        self.activeModuleId = moduleId
        self.activePageId = state.selectedPageId
        ui:SelectItem(moduleId)
    end

    function host:RefreshActivePage(force)
        if not self.activeModuleId then
            return
        end
        if force then
            self:InvalidatePage(self.activeModuleId, self.activePageId)
        end
        self:SelectModule(self.activeModuleId, self.activePageId)
    end

    function host:InvalidatePage(moduleId, pageId)
        local moduleState = self.moduleStates[moduleId]
        if not moduleState then
            return
        end

        if pageId then
            local state = moduleState.pageStates[pageId]
            if state and state.frame then
                HostSupport.Destroy(state.frame)
            end
            moduleState.pageStates[pageId] = nil
            return
        end

        if moduleState.root then
            HostSupport.Destroy(moduleState.root)
        end
        self.moduleStates[moduleId] = nil
    end

    function host:InvalidateAllPages()
        for moduleId in pairs(self.moduleStates) do
            self:InvalidatePage(moduleId)
        end
    end

    function host:SetActivePageHeight(height)
        self.activeContentHeight = height
        ui:SetContentHeight(height)
    end

    function host:RegisterConfigCleanup(frame)
        ui:RegisterConfigCleanup(frame)
    end

    function host:CreateConfigTabs(parent, tabs)
        return ui:CreateConfigTabs(parent, tabs)
    end

    function host:RefreshModuleToggle(moduleId)
        ui:RefreshModuleToggle(moduleId)
    end

    function host:SetFooterButtons(buttons)
        ui:SetFooterButtons(buttons)
    end

    function host:SetLegend(entries)
        ui:SetLegend(entries)
    end

    function host:ScheduleLayoutRefresh()
        ScheduleLayoutRefresh()
    end

    function host:Show()
        panel:Show()
        ScheduleLayoutRefresh()
    end

    function host:Hide()
        panel:Hide()
    end

    function host:Toggle()
        if panel:IsShown() then
            panel:Hide()
        else
            panel:Show()
            ScheduleLayoutRefresh()
        end
    end

    function host:IsShown()
        return panel:IsShown()
    end

    function host:GetFrame()
        return panel
    end

    function host:GetPanel()
        return panel
    end

    function host:GetState()
        return panel:GetState()
    end

    function host:RestoreState(state)
        panel:RestoreState(state)
    end

    ui:SetOnItemSelected(function(moduleId)
        host.activeModuleId = moduleId
        local state = host.moduleStates[moduleId]
        if host.OnSelectionChanged then
            host.OnSelectionChanged(moduleId, state and state.selectedPageId)
        end
    end)

    panel:HookScript("OnShow", ScheduleLayoutRefresh)

    return host
end
