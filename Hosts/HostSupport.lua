local MedaUI = LibStub("MedaUI-2.0")
---@cast MedaUI MedaUILibrary

local DEFAULT_PAGE_ID = "settings"
local DEFAULT_PAGE_LABEL = "Settings"

local HostSupport = MedaUI.HostSupport or {}
MedaUI.HostSupport = HostSupport

function HostSupport.NormalizePages(moduleConfig)
    local pages = {}
    if type(moduleConfig.pages) ~= "table" or #moduleConfig.pages == 0 then
        pages[1] = { id = DEFAULT_PAGE_ID, label = DEFAULT_PAGE_LABEL }
        return pages
    end

    for index, page in ipairs(moduleConfig.pages) do
        if type(page) == "table" then
            pages[index] = {
                id = page.id or page.name or tostring(index),
                label = page.label or page.title or page.id or tostring(index),
                title = page.title,
                description = page.description,
            }
        else
            pages[index] = { id = tostring(page), label = tostring(page) }
        end
    end

    return pages
end

function HostSupport.Detach(frame)
    if frame then
        frame:Hide()
        frame:SetParent(nil)
    end
end

function HostSupport.Destroy(frame)
    if frame then
        MedaUI:ReleaseThemedWidgetTree(frame)
        HostSupport.Detach(frame)
    end
end
