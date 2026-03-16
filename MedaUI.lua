--[[
    MedaUI - Shared UI Library
    Root initializer for shared library state and media path resolution.
]]

local MedaUI = LibStub("MedaUI-2.0")

-- Resolve the media base path from our load location so textures work
-- whether MedaUI is standalone or embedded (e.g. Libs\MedaUI\ inside an addon).
do
    local info = debugstack(1, 1, 0) or ""
    local path = info:match("(Interface[/\\]AddOns[/\\].-)[/\\]MedaUI%.lua")
    if path then
        path = path:gsub("/", "\\")
        MedaUI.mediaPath = path .. "\\Media\\"
    else
        MedaUI.mediaPath = "Interface\\AddOns\\MedaUI\\Media\\"
    end
end

-- These methods are defined in the individual widget files:
-- MedaUI:CreateButton(parent, text, width, height)
-- MedaUI:CreateCheckbox(parent, label)
-- MedaUI:CreateRadio(parent, label)
-- MedaUI:CreateEditBox(parent, width, height)
-- MedaUI:CreateSlider(parent, width, min, max, step)
-- MedaUI:CreatePanel(name, width, height, title)
-- MedaUI:CreateMinimapButton(name, icon, onClick, onRightClick)
