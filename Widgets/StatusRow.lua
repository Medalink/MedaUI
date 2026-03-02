--[[
    MedaUI StatusRow Widget
    Compact themed row for displaying labeled status with icon and severity accent.
    Used for at-a-glance capability/coverage display.
]]

local MedaUI = LibStub("MedaUI-1.0")

local DEFAULT_WIDTH = 280
local DEFAULT_ICON_SIZE = 20
local DEFAULT_ACCENT_WIDTH = 3
local ICON_PADDING = 1
local TEXT_LEFT_PAD = 6
local NOTE_TOP_PAD = 2

--- Create a themed status row with accent bar, icon, label, and status text.
--- @param parent Frame The parent frame
--- @param config table|nil Configuration overrides
--- @return Frame The status row widget
---
--- Config keys:
---   width (number, default 280) — row width (nil to fill parent)
---   iconSize (number, default 20) — spell icon size
---   accentWidth (number, default 3) — left severity accent bar width
---   showNote (boolean, default true) — show sub-text line below main content
function MedaUI:CreateStatusRow(parent, config)
    config = config or {}

    local width = config.width or DEFAULT_WIDTH
    local iconSize = config.iconSize or DEFAULT_ICON_SIZE
    local accentWidth = config.accentWidth or DEFAULT_ACCENT_WIDTH
    local showNote = config.showNote ~= false

    local row = CreateFrame("Frame", nil, parent)
    row:SetWidth(width)

    -- Accent bar (left edge, severity-colored)
    row.accent = row:CreateTexture(nil, "ARTWORK")
    row.accent:SetPoint("TOPLEFT", 0, 0)
    row.accent:SetPoint("BOTTOMLEFT", 0, 0)
    row.accent:SetWidth(accentWidth)
    row.accent:SetColorTexture(0.4, 0.4, 0.4, 1)

    -- Icon (square, zoom-cropped)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(iconSize, iconSize)
    row.icon:SetPoint("TOPLEFT", accentWidth + 4, -2)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Label text (bold, left of icon)
    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.label:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", TEXT_LEFT_PAD, -1)
    row.label:SetPoint("RIGHT", row, "RIGHT", -90, 0)
    row.label:SetJustifyH("LEFT")
    row.label:SetWordWrap(false)

    -- Status text (right-aligned)
    row.status = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.status:SetPoint("TOPRIGHT", row, "TOPRIGHT", -4, -3)
    row.status:SetJustifyH("RIGHT")
    row.status:SetWordWrap(false)
    row.status:SetWidth(84)

    -- Note sub-line (dim, full width, below icon row)
    row.note = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.note:SetPoint("TOPLEFT", row.icon, "BOTTOMLEFT", 0, -NOTE_TOP_PAD)
    row.note:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    row.note:SetJustifyH("LEFT")
    row.note:SetWordWrap(true)
    if not showNote then row.note:Hide() end

    -- Highlight texture (background glow for gap states)
    row.highlight = row:CreateTexture(nil, "BACKGROUND")
    row.highlight:SetAllPoints()
    row.highlight:SetColorTexture(1, 0.3, 0.3, 0.06)
    row.highlight:Hide()

    -- State
    row._showNote = showNote
    row._iconSize = iconSize
    row._tooltipFunc = nil

    -- Tooltip
    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self)
        if self._tooltipFunc then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            self._tooltipFunc(self, GameTooltip)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local function UpdateHeight()
        local h = math.max(iconSize + 4, row.label:GetStringHeight() + 6)
        if row._showNote and row.note:IsShown() and row.note:GetText() and row.note:GetText() ~= "" then
            h = h + row.note:GetStringHeight() + NOTE_TOP_PAD
        end
        row:SetHeight(math.max(h, iconSize + 6))
    end

    -- Theme support
    local function ApplyTheme()
        local Theme = MedaUI.Theme
        row.label:SetTextColor(unpack(Theme.textBright or Theme.text or {1, 1, 1}))
        if not row._noteColorOverride then
            row.note:SetTextColor(unpack(Theme.textDim or {0.6, 0.6, 0.6}))
        end
    end
    row._ApplyTheme = ApplyTheme
    row._themeHandle = MedaUI:RegisterThemedWidget(row, ApplyTheme)
    ApplyTheme()

    -- Initial height
    row:SetHeight(iconSize + 6)

    -- ----------------------------------------------------------------
    -- Public API
    -- ----------------------------------------------------------------

    function row:SetIcon(textureID)
        if textureID then
            self.icon:SetTexture(textureID)
            self.icon:Show()
        else
            self.icon:Hide()
        end
    end

    function row:SetLabel(text)
        self.label:SetText(text or "")
        UpdateHeight()
    end

    function row:SetStatus(text, r, g, b)
        self.status:SetText(text or "")
        if r then
            self.status:SetTextColor(r, g, b)
        end
    end

    function row:SetNote(text, r, g, b)
        self.note:SetText(text or "")
        if r then
            self.note:SetTextColor(r, g, b)
            self._noteColorOverride = true
        else
            self._noteColorOverride = false
            local Theme = MedaUI.Theme
            self.note:SetTextColor(unpack(Theme.textDim or {0.6, 0.6, 0.6}))
        end
        if text and text ~= "" then
            self.note:Show()
        else
            self.note:Hide()
        end
        UpdateHeight()
    end

    function row:SetAccentColor(r, g, b)
        self.accent:SetColorTexture(r, g, b, 1)
    end

    function row:SetHighlight(enabled)
        if enabled then
            self.highlight:Show()
        else
            self.highlight:Hide()
        end
    end

    function row:GetHeight()
        return getmetatable(self).__index.GetHeight(self)
    end

    function row:SetTooltipFunc(func)
        self._tooltipFunc = func
    end

    function row:Reset()
        self:SetIcon(nil)
        self:SetLabel("")
        self:SetStatus("")
        self:SetNote("")
        self:SetAccentColor(0.4, 0.4, 0.4)
        self:SetHighlight(false)
        self._tooltipFunc = nil
        self._noteColorOverride = false
    end

    return row
end
