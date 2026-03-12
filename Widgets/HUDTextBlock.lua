--[[
    MedaUI HUDTextBlock Widget
    Simple stacked text lines for lightweight HUD sections.
]]

local MedaUI = LibStub("MedaUI-1.0")
local Pixel = LibStub("MedaUI-1.0").Pixel

--- Create a stacked HUD text block.
--- @param parent Frame
--- @param config table|nil { width, lineCount, lineHeight, fontObject, justifyH, tone, shadow }
--- @return Frame
function MedaUI:CreateHUDTextBlock(parent, config)
    config = config or {}

    local block = CreateFrame("Frame", nil, parent)
    local lineCount = config.lineCount or 1
    local lineHeight = config.lineHeight or 16
    local width = config.width or 200
    Pixel.SetSize(block, width, lineCount * lineHeight)

    block.lines = {}
    block._lineHeight = lineHeight

    for index = 1, lineCount do
        local line = MedaUI:CreateLabel(block, "", {
            fontObject = config.fontObject or "GameFontNormal",
            tone = config.tone or "text",
            justifyH = config.justifyH or "LEFT",
            shadow = config.shadow ~= false,
            wrap = false,
        })
        line:SetPoint("TOPLEFT", block, "TOPLEFT", 0, -((index - 1) * lineHeight))
        line:SetPoint("TOPRIGHT", block, "TOPRIGHT", 0, -((index - 1) * lineHeight))
        block.lines[index] = line
    end

    function block:GetLine(index)
        return self.lines[index]
    end

    function block:SetLineText(index, text)
        local line = self.lines[index]
        if line then
            line:SetText(text or "")
        end
    end

    function block:SetLineFontObject(index, fontObject)
        local line = self.lines[index]
        if line then
            line:SetFontObject(fontObject)
        end
    end

    function block:SetAllFonts(fontObject)
        for _, line in ipairs(self.lines) do
            line:SetFontObject(fontObject)
        end
    end

    return block
end
