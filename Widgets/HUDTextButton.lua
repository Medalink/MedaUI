--[[
    MedaUI HUDTextButton Widget
    Lightweight text-only button for transparent HUD sections.
]]

local MedaUI = LibStub("MedaUI-1.0")
local Pixel = LibStub("MedaUI-1.0").Pixel

--- Create a HUD text button.
--- @param parent Frame
--- @param text string
--- @param config table|nil { width, height, fontObject, tone, hoverTone, tooltip }
--- @return Button
function MedaUI:CreateHUDTextButton(parent, text, config)
    config = config or {}

    local button = CreateFrame("Button", nil, parent)
    Pixel.SetSize(button, config.width or 80, config.height or 16)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    button.label = MedaUI:CreateLabel(button, text or "", {
        fontObject = config.fontObject or "GameFontNormalSmall",
        tone = config.tone or "dim",
        justifyH = "CENTER",
        shadow = true,
        wrap = false,
    })
    button.label:SetAllPoints()

    button._normalTone = config.tone or "dim"
    button._hoverTone = config.hoverTone or "bright"
    button._tooltip = config.tooltip

    button:SetScript("OnEnter", function(self)
        self.label:SetTone(self._hoverTone)
        if self._tooltip then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(self._tooltip, 1, 1, 1)
            GameTooltip:Show()
        end
    end)

    button:SetScript("OnLeave", function(self)
        self.label:SetTone(self._normalTone)
        GameTooltip:Hide()
    end)

    function button:SetText(newText)
        self.label:SetText(newText or "")
    end

    function button:SetFontObject(fontObject)
        self.label:SetFontObject(fontObject)
    end

    function button:SetTones(normalTone, hoverTone)
        self._normalTone = normalTone or self._normalTone
        self._hoverTone = hoverTone or self._hoverTone
        self.label:SetTone(self._normalTone)
    end

    function button:SetTooltip(text)
        self._tooltip = text
    end

    return button
end
