--[[
    MedaUI StatusRow Widget
    Compact themed row for displaying labeled status with icon and severity accent.
    Used for at-a-glance capability/coverage display.
]]

local MedaUI = LibStub("MedaUI-2.0")
---@cast MedaUI MedaUILibrary
local Pixel = LibStub("MedaUI-2.0").Pixel

local DEFAULT_WIDTH = 280
local DEFAULT_ICON_SIZE = 20
local DEFAULT_ACCENT_WIDTH = 3
local TEXT_LEFT_PAD = 6
local NOTE_TOP_PAD = 2
local CARD_PAD_X = 10
local CARD_PAD_Y = 10
local CARD_STATUS_WIDTH = 130

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
function MedaUI.CreateStatusRow(library, parent, config)
    config = config or {}

    local width = config.width or DEFAULT_WIDTH
    local iconSize = config.iconSize or DEFAULT_ICON_SIZE
    local accentWidth = config.accentWidth or DEFAULT_ACCENT_WIDTH
    local showNote = config.showNote ~= false
    local cardStyle = config.cardStyle == true

    local row = CreateFrame("Frame", nil, parent, cardStyle and "BackdropTemplate" or nil)
    Pixel.SetWidth(row, width)
    row._cardStyle = cardStyle
    if cardStyle then
        row:SetBackdrop(library:CreateBackdrop(true))
    end

    -- Accent bar (left edge, severity-colored)
    row.accent = row:CreateTexture(nil, "ARTWORK")
    Pixel.SetPoint(row.accent, "TOPLEFT", 0, 0)
    Pixel.SetPoint(row.accent, "BOTTOMLEFT", 0, 0)
    Pixel.SetWidth(row.accent, accentWidth)
    row.accent:SetColorTexture(0.4, 0.4, 0.4, 1)

    if cardStyle then
        row.iconFrame = CreateFrame("Frame", nil, row, "BackdropTemplate")
        row.iconFrame:SetBackdrop(library:CreateBackdrop(true))
        Pixel.SetSize(row.iconFrame, iconSize, iconSize)
        Pixel.SetPoint(row.iconFrame, "TOPLEFT", row, "TOPLEFT", accentWidth + CARD_PAD_X, -CARD_PAD_Y)
    end

    -- Icon (square, zoom-cropped)
    row.icon = (row.iconFrame or row):CreateTexture(nil, "ARTWORK")
    Pixel.SetSize(row.icon, iconSize, iconSize)
    if cardStyle then
        row.icon:SetAllPoints()
    else
        Pixel.SetPoint(row.icon, "TOPLEFT", accentWidth + TEXT_LEFT_PAD + 1, -2)
    end
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Label text (bold, left of icon)
    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if cardStyle then
        Pixel.SetPoint(row.label, "TOPLEFT", row.iconFrame, "TOPRIGHT", 10, -1)
        Pixel.SetPoint(row.label, "RIGHT", row, "RIGHT", -(CARD_PAD_X + CARD_STATUS_WIDTH + 8), 0)
    else
        Pixel.SetPoint(row.label, "TOPLEFT", row.icon, "TOPRIGHT", TEXT_LEFT_PAD, -1)
        Pixel.SetPoint(row.label, "RIGHT", row, "RIGHT", -136, 0)
    end
    row.label:SetJustifyH("LEFT")
    row.label:SetWordWrap(false)

    -- Status text (right-aligned)
    row.status = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    if cardStyle then
        Pixel.SetPoint(row.status, "TOPRIGHT", row, "TOPRIGHT", -CARD_PAD_X, -CARD_PAD_Y + 1)
    else
        Pixel.SetPoint(row.status, "TOPRIGHT", row, "TOPRIGHT", -4, -3)
    end
    row.status:SetJustifyH("RIGHT")
    row.status:SetWordWrap(false)
    Pixel.SetWidth(row.status, CARD_STATUS_WIDTH)

    -- Note sub-line (dim, full width, below icon row)
    row.note = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    if cardStyle then
        Pixel.SetPoint(row.note, "TOPLEFT", row.label, "BOTTOMLEFT", 0, -NOTE_TOP_PAD - 1)
        Pixel.SetPoint(row.note, "RIGHT", row, "RIGHT", -CARD_PAD_X, 0)
    else
        Pixel.SetPoint(row.note, "TOPLEFT", row.icon, "BOTTOMLEFT", 0, -NOTE_TOP_PAD)
        Pixel.SetPoint(row.note, "RIGHT", row, "RIGHT", -4, 0)
    end
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
    row._hasIcon = true

    local function UpdateLayoutAnchors()
        row.label:ClearAllPoints()
        row.note:ClearAllPoints()

        if row._cardStyle then
            local labelLeftAnchor = (row._hasIcon and row.iconFrame) or row
            local labelLeftPoint = row._hasIcon and "TOPRIGHT" or "TOPLEFT"
            local labelLeftX = row._hasIcon and 10 or (accentWidth + CARD_PAD_X)

            Pixel.SetPoint(row.label, "TOPLEFT", labelLeftAnchor, labelLeftPoint, labelLeftX, -CARD_PAD_Y + 1)
            Pixel.SetPoint(row.label, "RIGHT", row, "RIGHT", -(CARD_PAD_X + CARD_STATUS_WIDTH + 8), 0)
            Pixel.SetPoint(row.note, "TOPLEFT", row.label, "BOTTOMLEFT", 0, -NOTE_TOP_PAD - 1)
            Pixel.SetPoint(row.note, "RIGHT", row, "RIGHT", -CARD_PAD_X, 0)
        else
            local iconAnchor = row._hasIcon and row.icon or row
            local iconPoint = row._hasIcon and "TOPRIGHT" or "TOPLEFT"
            local iconX = row._hasIcon and TEXT_LEFT_PAD or (accentWidth + 6)

            Pixel.SetPoint(row.label, "TOPLEFT", iconAnchor, iconPoint, iconX, -1)
            Pixel.SetPoint(row.label, "RIGHT", row, "RIGHT", -136, 0)
            Pixel.SetPoint(row.note, "TOPLEFT", row._hasIcon and row.icon or row.label, row._hasIcon and "BOTTOMLEFT" or "BOTTOMLEFT", 0, -NOTE_TOP_PAD)
            Pixel.SetPoint(row.note, "RIGHT", row, "RIGHT", -4, 0)
        end
    end

    -- Tooltip
    row:EnableMouse(true)
    row:SetScript("OnEnter", function(frame)
        if frame._tooltipFunc then
            GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
            frame._tooltipFunc(frame, GameTooltip)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local function UpdateHeight()
        local h
        if row._cardStyle then
            local contentHeight = row.label:GetStringHeight() + 6
            if row._showNote and row.note:IsShown() and row.note:GetText() and row.note:GetText() ~= "" then
                contentHeight = contentHeight + row.note:GetStringHeight() + NOTE_TOP_PAD + 1
            end
            h = math.max(iconSize + (CARD_PAD_Y * 2), contentHeight + (CARD_PAD_Y * 2))
        else
            h = math.max(iconSize + 4, row.label:GetStringHeight() + 6)
            if row._showNote and row.note:IsShown() and row.note:GetText() and row.note:GetText() ~= "" then
                h = h + row.note:GetStringHeight() + NOTE_TOP_PAD
            end
        end
        Pixel.SetHeight(row, math.max(h, iconSize + 6))
    end

    -- Theme support
    local function ApplyTheme()
        local theme = MedaUI.Theme
        if row._cardStyle then
            local border = theme.border or {0.2, 0.2, 0.22, 0.6}
            local background = theme.backgroundDark or theme.background or {0.08, 0.08, 0.09, 0.9}
            row:SetBackdropColor(background[1], background[2], background[3], 0.72)
            row:SetBackdropBorderColor(border[1], border[2], border[3], (border[4] or 0.6) * 1.1)
            if row.iconFrame then
                row.iconFrame:SetBackdropColor(0, 0, 0, 0.45)
                row.iconFrame:SetBackdropBorderColor(border[1], border[2], border[3], 0.65)
            end
            row.highlight:SetColorTexture(1, 1, 1, 0.04)
        end
        row.label:SetTextColor(unpack(theme.textBright or theme.text or {1, 1, 1}))
        if not row._statusColorOverride then
            row.status:SetTextColor(unpack(theme.textDim or theme.text or {0.8, 0.8, 0.8}))
        end
        if not row._noteColorOverride then
            row.note:SetTextColor(unpack(theme.textDim or {0.6, 0.6, 0.6}))
        end
    end
    row._ApplyTheme = ApplyTheme
    row._themeHandle = MedaUI:RegisterThemedWidget(row, ApplyTheme)
    ApplyTheme()
    UpdateLayoutAnchors()

    -- Initial height
    Pixel.SetHeight(row, cardStyle and (iconSize + (CARD_PAD_Y * 2)) or (iconSize + 6))

    -- ----------------------------------------------------------------
    -- Public API
    -- ----------------------------------------------------------------

    function row:SetIcon(textureID)
        if textureID then
            self.icon:SetTexture(textureID)
            self.icon:Show()
            if self.iconFrame then
                self.iconFrame:Show()
            end
            self._hasIcon = true
        else
            self.icon:Hide()
            if self.iconFrame then
                self.iconFrame:Hide()
            end
            self._hasIcon = false
        end
        UpdateLayoutAnchors()
        UpdateHeight()
    end

    function row:SetLabel(text)
        self.label:SetText(text or "")
        UpdateHeight()
    end

    function row:SetStatus(text, r, g, b)
        self.status:SetText(text or "")
        if r then
            self.status:SetTextColor(r, g, b)
            self._statusColorOverride = true
        else
            self._statusColorOverride = false
            local theme = MedaUI.Theme
            self.status:SetTextColor(unpack(theme.textDim or theme.text or {0.8, 0.8, 0.8}))
        end
    end

    function row:SetNote(text, r, g, b)
        self.note:SetText(text or "")
        if r then
            self.note:SetTextColor(r, g, b)
            self._noteColorOverride = true
        else
            self._noteColorOverride = false
            local theme = MedaUI.Theme
            self.note:SetTextColor(unpack(theme.textDim or {0.6, 0.6, 0.6}))
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
        self._statusColorOverride = false
    end

    return row
end
