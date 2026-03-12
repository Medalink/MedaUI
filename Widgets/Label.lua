--[[
    MedaUI Label Widget
    Lightweight themed text primitive for module UIs.
]]

local MedaUI = LibStub("MedaUI-1.0")
local Pixel = LibStub("MedaUI-1.0").Pixel

local TONE_KEYS = {
    text = "text",
    dim = "textDim",
    bright = "textBright",
    gold = "gold",
    warning = "warning",
    success = "success",
    danger = "danger",
}

local function ResolveColor(tone, override)
    if override then
        return override
    end

    local Theme = MedaUI.Theme
    local themeKey = TONE_KEYS[tone or "text"] or "text"
    return Theme[themeKey] or Theme.text or { 1, 1, 1, 1 }
end

--- Create a themed label.
--- @param parent Frame
--- @param text string|nil
--- @param config table|nil { fontObject, tone, width, justifyH, justifyV, wrap, layer, alpha, shadow }
--- @return FontString
function MedaUI:CreateLabel(parent, text, config)
    config = config or {}

    local label = Pixel.CreateFontString(parent, text, config.fontObject or "GameFontNormal", config.layer or "OVERLAY")

    if config.width then
        Pixel.SetWidth(label, config.width)
    end

    label:SetJustifyH(config.justifyH or "LEFT")
    label:SetJustifyV(config.justifyV or "MIDDLE")
    label:SetWordWrap(config.wrap ~= false)

    label._tone = config.tone or "text"
    label._alphaMultiplier = config.alpha or 1
    label._colorOverride = config.color

    if config.shadow then
        label:SetShadowOffset(1, -1)
        label:SetShadowColor(0, 0, 0, 0.8)
    end

    local function ApplyTheme()
        local color = ResolveColor(label._tone, label._colorOverride)
        local alpha = (color[4] or 1) * (label._alphaMultiplier or 1)
        label:SetTextColor(color[1] or 1, color[2] or 1, color[3] or 1, alpha)
    end

    label._ApplyTheme = ApplyTheme
    label._themeHandle = MedaUI:RegisterThemedWidget(label, ApplyTheme)
    ApplyTheme()

    function label:SetTone(tone)
        self._tone = tone or "text"
        self:_ApplyTheme()
    end

    function label:SetAlphaMultiplier(alpha)
        self._alphaMultiplier = alpha or 1
        self:_ApplyTheme()
    end

    function label:SetColorOverride(r, g, b, a)
        if r then
            self._colorOverride = { r, g, b, a or 1 }
        else
            self._colorOverride = nil
        end
        self:_ApplyTheme()
    end

    return label
end
