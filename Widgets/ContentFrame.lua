--[[
    MedaUI ContentFrame Widget
    Simple themed or unthemed layout container for module view stacks.
]]

local MedaUI = LibStub("MedaUI-1.0")
local Pixel = LibStub("MedaUI-1.0").Pixel

--- Create a content container.
--- @param parent Frame
--- @param config table|nil { fillParent, insets, width, height, backdrop, mouse }
--- @return Frame
function MedaUI:CreateContentFrame(parent, config)
    config = config or {}

    local template = config.backdrop and "BackdropTemplate" or nil
    local frame = CreateFrame("Frame", nil, parent, template)

    if config.fillParent then
        local insets = config.insets or {}
        Pixel.SetPoint(frame, "TOPLEFT", parent, "TOPLEFT", insets.left or 0, -(insets.top or 0))
        Pixel.SetPoint(frame, "BOTTOMRIGHT", parent, "BOTTOMRIGHT", -(insets.right or 0), insets.bottom or 0)
    elseif config.width or config.height then
        Pixel.SetSize(frame, config.width or 1, config.height or 1)
    end

    if config.mouse then
        frame:EnableMouse(true)
    end

    if config.backdrop then
        frame:SetBackdrop(MedaUI:CreateBackdrop(true))

        local function ApplyTheme()
            local Theme = MedaUI.Theme
            frame:SetBackdropColor(unpack(Theme.backgroundDark or Theme.background))
            frame:SetBackdropBorderColor(unpack(Theme.border))
        end

        frame._ApplyTheme = ApplyTheme
        frame._themeHandle = MedaUI:RegisterThemedWidget(frame, ApplyTheme)
        ApplyTheme()
    end

    function frame:GetContent()
        return self
    end

    return frame
end
