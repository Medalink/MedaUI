--[[
    MedaUI CollapsibleSectionHeader Widget
    A section header with click-to-toggle expand/collapse, chevron indicator,
    and optional item count badge. Extends the visual style of SectionHeader.
]]

local MedaUI = LibStub("MedaUI-1.0")
local Pixel = LibStub("MedaUI-1.0").Pixel

local CHEVRON_RIGHT_TEX = "Interface\\AddOns\\MedaUI\\Media\\Textures\\chevron-right.tga"
local CHEVRON_DOWN_TEX  = "Interface\\AddOns\\MedaUI\\Media\\Textures\\chevron-down.tga"
local CHEVRON_SIZE = 10

--- Create a collapsible section header with toggle chevron and count badge.
--- @param parent Frame
--- @param config table { text, width, count, expanded, onToggle }
--- @return Frame container
function MedaUI:CreateCollapsibleSectionHeader(parent, config)
    config = config or {}
    local width    = config.width or 280
    local text     = config.text or ""
    local count    = config.count or 0
    local expanded = config.expanded or false
    local onToggle = config.onToggle

    local container = CreateFrame("Button", nil, parent)
    Pixel.SetSize(container, width, 32)
    container:EnableMouse(true)
    container._expanded = expanded

    -- Chevron icon
    local chevron = container:CreateTexture(nil, "ARTWORK")
    Pixel.SetSize(chevron, CHEVRON_SIZE, CHEVRON_SIZE)
    Pixel.SetPoint(chevron, "TOPLEFT", 2, -2)
    chevron:SetTexture(expanded and CHEVRON_DOWN_TEX or CHEVRON_RIGHT_TEX)

    -- Header text (next to chevron)
    local header = Pixel.CreateFontString(container, text)
    Pixel.SetPoint(header, "LEFT", chevron, "RIGHT", 4, 0)

    -- Count badge
    local badge = Pixel.CreateFontString(container, "")
    Pixel.SetPoint(badge, "LEFT", header, "RIGHT", 6, 0)
    badge:SetJustifyH("LEFT")

    -- Gradient underline (matches SectionHeader)
    local line = container:CreateTexture(nil, "ARTWORK")
    Pixel.SetPoint(line, "TOPLEFT", container, "TOPLEFT", 0, -28)
    Pixel.SetSize(line, width, 2)

    -- Theme application
    local function ApplyTheme()
        local Theme = MedaUI.Theme
        local gold = Theme.gold or {1, 0.82, 0}
        local dim  = Theme.textDim or {0.6, 0.6, 0.6}

        header:SetTextColor(unpack(gold))
        chevron:SetVertexColor(unpack(dim))
        badge:SetTextColor(unpack(dim))

        if Theme.sectionGradientStart and Theme.sectionGradientEnd and line.SetGradient then
            line:SetColorTexture(1, 1, 1, 1)
            local success = pcall(function()
                line:SetGradient("HORIZONTAL", {
                    r = Theme.sectionGradientStart[1],
                    g = Theme.sectionGradientStart[2],
                    b = Theme.sectionGradientStart[3],
                    a = Theme.sectionGradientStart[4],
                }, {
                    r = Theme.sectionGradientEnd[1],
                    g = Theme.sectionGradientEnd[2],
                    b = Theme.sectionGradientEnd[3],
                    a = Theme.sectionGradientEnd[4],
                })
            end)
            if not success then
                line:SetColorTexture(unpack(gold))
            end
        else
            line:SetColorTexture(unpack(gold))
        end
    end

    container._ApplyTheme = ApplyTheme
    container._themeHandle = MedaUI:RegisterThemedWidget(container, ApplyTheme)
    ApplyTheme()

    -- Hover feedback
    container:SetScript("OnEnter", function(self)
        local Theme = MedaUI.Theme
        local bright = Theme.textBright or Theme.text or {1, 1, 1}
        chevron:SetVertexColor(unpack(bright))
    end)
    container:SetScript("OnLeave", function(self)
        local Theme = MedaUI.Theme
        local dim = Theme.textDim or {0.6, 0.6, 0.6}
        chevron:SetVertexColor(unpack(dim))
    end)

    -- Click handler
    container:SetScript("OnClick", function(self)
        self._expanded = not self._expanded
        chevron:SetTexture(self._expanded and CHEVRON_DOWN_TEX or CHEVRON_RIGHT_TEX)
        if onToggle then onToggle(self._expanded) end
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
