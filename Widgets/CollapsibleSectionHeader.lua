--[[
    MedaUI CollapsibleSectionHeader Widget
    A section header with click-to-toggle expand/collapse, chevron indicator,
    and optional item count badge. Extends the visual style of SectionHeader.
]]

local MedaUI = LibStub("MedaUI-2.0")
---@cast MedaUI MedaUILibrary
local Pixel = LibStub("MedaUI-2.0").Pixel

local CHEVRON_RIGHT_TEX = "Interface\\AddOns\\MedaUI\\Media\\Textures\\chevron-right.tga"
local CHEVRON_DOWN_TEX  = "Interface\\AddOns\\MedaUI\\Media\\Textures\\chevron-down.tga"
local CHEVRON_SIZE = 10

--- Create a collapsible section header with toggle chevron and count badge.
--- @param parent Frame
--- @param config table { text, width, count, expanded, onToggle }
--- @return Frame container
function MedaUI.CreateCollapsibleSectionHeader(_, parent, config)
    config = config or {}
    local width    = config.width or 280
    local height   = config.height or 32
    local text     = config.text or ""
    local count    = config.count or 0
    local expanded = config.expanded or false
    local onToggle = config.onToggle
    local showLine = config.showLine ~= false
    local tone     = config.tone or "gold"
    local dimTone  = config.dimTone or "textDim"

    local container = CreateFrame("Button", nil, parent)
    Pixel.SetSize(container, width, height)
    container:EnableMouse(true)
    container._expanded = expanded

    -- Chevron icon
    local chevron = container:CreateTexture(nil, "ARTWORK")
    Pixel.SetSize(chevron, CHEVRON_SIZE, CHEVRON_SIZE)
    Pixel.SetPoint(chevron, "LEFT", 2, 0)
    chevron:SetTexture(expanded and CHEVRON_DOWN_TEX or CHEVRON_RIGHT_TEX)

    -- Header text (next to chevron)
    local header = Pixel.CreateFontString(container, text)
    header:SetFontObject(config.fontObject or "GameFontHighlightSmall")
    Pixel.SetPoint(header, "LEFT", chevron, "RIGHT", 4, 0)

    -- Count badge
    local badge = Pixel.CreateFontString(container, "")
    badge:SetFontObject(config.fontObject or "GameFontHighlightSmall")
    Pixel.SetPoint(badge, "LEFT", header, "RIGHT", 6, 0)
    badge:SetJustifyH("LEFT")

    -- Gradient underline (matches SectionHeader)
    local line = container:CreateTexture(nil, "ARTWORK")
    Pixel.SetPoint(line, "TOPLEFT", container, "TOPLEFT", 0, -math.max(height - 4, 1))
    Pixel.SetSize(line, width, 2)

    -- Theme application
    local function ApplyTheme()
        local theme = MedaUI.Theme
        local headerColor = theme[tone] or theme.gold or {1, 0.82, 0}
        local dim  = theme[dimTone] or theme.textDim or {0.6, 0.6, 0.6}

        header:SetTextColor(unpack(headerColor))
        chevron:SetVertexColor(unpack(dim))
        badge:SetTextColor(unpack(dim))

        if not showLine then
            line:Hide()
        elseif theme.sectionGradientStart and theme.sectionGradientEnd and line.SetGradient then
            line:Show()
            line:SetColorTexture(1, 1, 1, 1)
            local success = pcall(function()
                line:SetGradient("HORIZONTAL", {
                    r = theme.sectionGradientStart[1],
                    g = theme.sectionGradientStart[2],
                    b = theme.sectionGradientStart[3],
                    a = theme.sectionGradientStart[4],
                }, {
                    r = theme.sectionGradientEnd[1],
                    g = theme.sectionGradientEnd[2],
                    b = theme.sectionGradientEnd[3],
                    a = theme.sectionGradientEnd[4],
                })
            end)
            if not success then
                line:SetColorTexture(unpack(headerColor))
            end
        else
            line:Show()
            line:SetColorTexture(unpack(headerColor))
        end
    end

    container._ApplyTheme = ApplyTheme
    container._themeHandle = MedaUI:RegisterThemedWidget(container, ApplyTheme)
    ApplyTheme()

    -- Hover feedback
    container:SetScript("OnEnter", function()
        local theme = MedaUI.Theme
        local bright = theme.textBright or theme.text or {1, 1, 1}
        chevron:SetVertexColor(unpack(bright))
    end)
    container:SetScript("OnLeave", function()
        local theme = MedaUI.Theme
        local dim = theme[dimTone] or theme.textDim or {0.6, 0.6, 0.6}
        chevron:SetVertexColor(unpack(dim))
    end)

    -- Click handler
    container:SetScript("OnClick", function(widget)
        widget._expanded = not widget._expanded
        chevron:SetTexture(widget._expanded and CHEVRON_DOWN_TEX or CHEVRON_RIGHT_TEX)
        if onToggle then
            onToggle(widget._expanded)
        end
    end)

    -- Internal refs
    container.header  = header
    container.chevron = chevron
    container.badge   = badge
    container.line    = line

    -- Update count badge text
    local function UpdateBadge()
        if count and count > 0 then
            badge:SetText("(" .. count .. ")")
            badge:Show()
        else
            badge:Hide()
        end
    end
    UpdateBadge()

    -- Public API --

    function container:SetText(newText)
        self.header:SetText(newText or "")
    end

    function container:GetText()
        return self.header:GetText()
    end

    function container:SetCount(n)
        count = n or 0
        UpdateBadge()
    end

    function container:SetExpanded(val)
        self._expanded = val and true or false
        chevron:SetTexture(self._expanded and CHEVRON_DOWN_TEX or CHEVRON_RIGHT_TEX)
    end

    function container:IsExpanded()
        return self._expanded
    end

    function container:SetLineWidth(newWidth)
        Pixel.SetWidth(self.line, newWidth)
        Pixel.SetWidth(self, newWidth)
    end

    function container:SetOnToggle(fn)
        onToggle = fn
    end

    return container
end
