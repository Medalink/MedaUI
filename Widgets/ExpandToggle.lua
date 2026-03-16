--[[
    MedaUI ExpandToggle Widget
    A small clickable "Show N more..." / "Show less" text link used beneath
    collapsed sections to let users reveal hidden items.
]]

local MedaUI = LibStub("MedaUI-2.0")
---@cast MedaUI MedaUILibrary
local Pixel = LibStub("MedaUI-2.0").Pixel

local GLYPH_MORE = " |TInterface\\AddOns\\MedaUI\\Media\\Textures\\chevron-right.tga:10:10|t"
local GLYPH_LESS = " |TInterface\\AddOns\\MedaUI\\Media\\Textures\\chevron-up.tga:10:10|t"
local TOGGLE_HEIGHT = 20

--- Create an expand/collapse toggle link.
--- @param parent Frame
--- @param config table { hiddenCount, expanded, onToggle }
--- @return Button toggle
function MedaUI.CreateExpandToggle(_, parent, config)
    config = config or {}
    local hiddenCount = config.hiddenCount or 0
    local expanded    = config.expanded or false
    local onToggle    = config.onToggle

    local btn = CreateFrame("Button", nil, parent)
    Pixel.SetHeight(btn, TOGGLE_HEIGHT)
    btn:EnableMouse(true)
    btn._expanded = expanded

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    Pixel.SetPoint(label, "LEFT", btn, "LEFT", 12, 0)
    label:SetJustifyH("LEFT")

    local function UpdateLabel()
        if btn._expanded then
            label:SetText("Show less" .. GLYPH_LESS)
        else
            local n = hiddenCount
            if n <= 0 then
                label:SetText("")
            else
                label:SetText("Show " .. n .. " more..." .. GLYPH_MORE)
            end
        end
    end
    UpdateLabel()

    -- Theme colors
    local function ApplyTheme()
        local theme = MedaUI.Theme
        local dim = theme.textDim or {0.6, 0.6, 0.6}
        label:SetTextColor(dim[1], dim[2], dim[3])
    end
    btn._ApplyTheme = ApplyTheme
    btn._themeHandle = MedaUI:RegisterThemedWidget(btn, ApplyTheme)
    ApplyTheme()

    -- Hover: brighten text
    btn:SetScript("OnEnter", function()
        local theme = MedaUI.Theme
        local bright = theme.textBright or theme.text or {1, 1, 1}
        label:SetTextColor(bright[1], bright[2], bright[3])
    end)
    btn:SetScript("OnLeave", function()
        ApplyTheme()
    end)

    btn:SetScript("OnClick", function(toggle)
        toggle._expanded = not toggle._expanded
        UpdateLabel()
        if onToggle then
            onToggle(toggle._expanded)
        end
    end)

    btn.label = label

    -- Public API --

    function btn:SetHiddenCount(n)
        hiddenCount = n or 0
        UpdateLabel()
    end

    function btn:SetExpanded(val)
        self._expanded = val and true or false
        UpdateLabel()
    end

    function btn:IsExpanded()
        return self._expanded
    end

    function btn:GetHeight()
        return TOGGLE_HEIGHT
    end

    function btn:SetOnToggle(fn)
        onToggle = fn
    end

    return btn
end
