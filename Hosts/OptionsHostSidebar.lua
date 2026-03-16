local MedaUI = LibStub("MedaUI-2.0")
---@cast MedaUI MedaUILibrary

local OptionsHostSidebar = MedaUI.OptionsHostSidebar or {}
MedaUI.OptionsHostSidebar = OptionsHostSidebar

function OptionsHostSidebar.BuildSections(host, config)
    local grouped = {}
    local groupOrder = {}

    for _, moduleId in ipairs(host.moduleOrder) do
        local moduleConfig = host.modules[moduleId]
        local groupName = moduleConfig.sidebarGroup or "Modules"
        if not grouped[groupName] then
            grouped[groupName] = {}
            groupOrder[#groupOrder + 1] = groupName
        end
        grouped[groupName][#grouped[groupName] + 1] = moduleId
    end

    local sections = {}
    for _, groupName in ipairs(config.groupOrder or groupOrder) do
        local moduleIds = grouped[groupName]
        if moduleIds and #moduleIds > 0 then
            table.sort(moduleIds, function(leftId, rightId)
                local left = host.modules[leftId]
                local right = host.modules[rightId]
                local leftOrder = left.sidebarOrder or math.huge
                local rightOrder = right.sidebarOrder or math.huge
                if leftOrder ~= rightOrder then
                    return leftOrder < rightOrder
                end
                return (left.sidebarLabel or left.title or leftId) < (right.sidebarLabel or right.title or rightId)
            end)

            sections[#sections + 1] = {
                title = groupName,
                moduleIds = moduleIds,
            }
        end
    end

    return sections
end
