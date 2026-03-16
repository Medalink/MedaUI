local MedaUI = LibStub("MedaUI-2.0")
---@cast MedaUI MedaUILibrary
local HostSupport = MedaUI.HostSupport

local WorkspaceHostState = MedaUI.WorkspaceHostState or {}
MedaUI.WorkspaceHostState = WorkspaceHostState

function WorkspaceHostState.RegisterPage(shell, pageId, pageConfig)
    if not shell.pageRegistry[pageId] then
        shell.pageOrder[#shell.pageOrder + 1] = pageId
    end
    shell.pageRegistry[pageId] = pageConfig or {}
end

function WorkspaceHostState.InvalidatePage(shell, pageId)
    local pageState = shell.pageCache[pageId]
    if pageState and pageState.frame then
        HostSupport.Destroy(pageState.frame)
    end
    shell.pageCache[pageId] = nil
end

function WorkspaceHostState.RefreshActivePage(shell, force, defaultHeight)
    local pageId = shell.activePage
    if not pageId then
        return
    end

    if force then
        WorkspaceHostState.InvalidatePage(shell, pageId)
    end

    local pageConfig = shell.pageRegistry[pageId]
    if not pageConfig or type(pageConfig.build) ~= "function" then
        return
    end

    local pageState = shell.pageCache[pageId]
    if pageState and pageState.frame then
        shell:ClearContent()
        pageState.frame:SetParent(shell:GetContent())
        pageState.frame:Show()
        if pageConfig.onCacheRestore then
            pageConfig.onCacheRestore(pageState.frame, shell)
        end
        shell:SetContentHeight(pageConfig.height or defaultHeight)
        return
    end

    shell:ClearContent()
    local frame = CreateFrame("Frame", nil, shell:GetContent())
    frame:SetPoint("TOPLEFT", 0, 0)
    frame:SetPoint("RIGHT", 0, 0)
    frame:SetHeight(5000)
    shell.pageCache[pageId] = { frame = frame }
    local builtHeight = pageConfig.build(frame, shell)
    shell:SetContentHeight(tonumber(builtHeight) or pageConfig.height or defaultHeight)
end
