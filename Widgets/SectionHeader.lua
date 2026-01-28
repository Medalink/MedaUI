--[[
    MedaUI SectionHeader Widget
    Creates labeled section dividers with gold text and underline
]]

local MedaUI = LibStub("MedaUI-1.0")
local Theme = MedaUI.Theme

--- Create a themed section header with gold text and underline
--- @param parent Frame The parent frame
--- @param text string Header text
--- @param width number|nil Width of the underline (default: 280)
--- @return FontString, Texture The header text and separator line
function MedaUI:CreateSectionHeader(parent, text, width)
    width = width or 280

    -- Header text
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetText(text)
    header:SetTextColor(unpack(Theme.gold))

    -- Separator line
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
    line:SetSize(width, 1)
    line:SetColorTexture(unpack(Theme.border))

    -- Return both elements for positioning
    return header, line
end
