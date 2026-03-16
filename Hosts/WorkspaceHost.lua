local MedaUI = LibStub("MedaUI-2.0")
---@cast MedaUI MedaUILibrary
local WorkspaceHostState = MedaUI.WorkspaceHostState
local WorkspaceHostView = MedaUI.WorkspaceHostView

local DEFAULT_PAGE_HEIGHT = 800

function MedaUI.CreateWorkspaceHost(library, parent, config)
    local shell = WorkspaceHostView.Create(library, parent, config)

    function shell:RegisterPage(pageId, pageConfig)
        WorkspaceHostState.RegisterPage(self, pageId, pageConfig)
    end

    function shell:InvalidatePage(pageId)
        WorkspaceHostState.InvalidatePage(self, pageId)
    end

    function shell:RefreshActivePage(force)
        WorkspaceHostState.RefreshActivePage(self, force, DEFAULT_PAGE_HEIGHT)
    end

    function shell:ScheduleLayoutRefresh(force)
        if self._layoutRefreshPending then
            return
        end

        self._layoutRefreshPending = true
        C_Timer.After(0, function()
            self._layoutRefreshPending = false
            if not self:IsShown() or not self.activePage then
                return
            end
            self:RefreshActivePage(force)
        end)
    end

    shell:HookScript("OnShow", function()
        shell:ScheduleLayoutRefresh(true)
    end)

    return shell
end
