--[[
    MedaUI ItemSlotCard Widget
    Themed slot-oriented card for equipment or recommendation views.
]]

local MedaUI = LibStub("MedaUI-2.0")
local Pixel = LibStub("MedaUI-2.0").Pixel

local DEFAULT_WIDTH = 260
local DEFAULT_HEIGHT = 78
local DEFAULT_ICON_SIZE = 40

function MedaUI:CreateItemSlotCard(parent, config)
    local ui = self
    config = config or {}

    local width = config.width or DEFAULT_WIDTH
    local height = config.height or DEFAULT_HEIGHT
    local iconSize = config.iconSize or DEFAULT_ICON_SIZE

    local card = CreateFrame("Button", nil, parent, "BackdropTemplate")
    card:SetBackdrop(ui:CreateBackdrop(true))
    Pixel.SetSize(card, width, height)

    card._tooltipFunc = nil
    card._progress = 0
    card._valueColor = nil
    card._accentColor = nil

    card.iconFrame = CreateFrame("Frame", nil, card, "BackdropTemplate")
    card.iconFrame:SetBackdrop(ui:CreateBackdrop(true))
    Pixel.SetSize(card.iconFrame, iconSize, iconSize)
    Pixel.SetPoint(card.iconFrame, "TOPLEFT", card, "TOPLEFT", 10, -10)

    card.icon = card.iconFrame:CreateTexture(nil, "ARTWORK")
    card.icon:SetAllPoints()
    card.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    card.slotLabel = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    Pixel.SetPoint(card.slotLabel, "TOPLEFT", card.iconFrame, "TOPRIGHT", 10, -1)
    Pixel.SetPoint(card.slotLabel, "RIGHT", card, "RIGHT", -78, 0)
    card.slotLabel:SetJustifyH("LEFT")
    card.slotLabel:SetWordWrap(false)

    card.valueLabel = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    Pixel.SetPoint(card.valueLabel, "TOPRIGHT", card, "TOPRIGHT", -10, -9)
    Pixel.SetWidth(card.valueLabel, 64)
    card.valueLabel:SetJustifyH("RIGHT")
    card.valueLabel:SetWordWrap(false)

    card.title = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    Pixel.SetPoint(card.title, "TOPLEFT", card.slotLabel, "BOTTOMLEFT", 0, -4)
    Pixel.SetPoint(card.title, "RIGHT", card, "RIGHT", -10, 0)
    Pixel.SetHeight(card.title, 16)
    card.title:SetJustifyH("LEFT")
    card.title:SetJustifyV("TOP")
    card.title:SetWordWrap(false)

    card.detail = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    Pixel.SetPoint(card.detail, "TOPLEFT", card.title, "BOTTOMLEFT", 0, -2)
    Pixel.SetPoint(card.detail, "RIGHT", card, "RIGHT", -10, 0)
    Pixel.SetHeight(card.detail, 14)
    card.detail:SetJustifyH("LEFT")
    card.detail:SetWordWrap(false)

    card.progressBg = card:CreateTexture(nil, "BACKGROUND")
    Pixel.SetPoint(card.progressBg, "BOTTOMLEFT", card, "BOTTOMLEFT", 10, 8)
    Pixel.SetPoint(card.progressBg, "BOTTOMRIGHT", card, "BOTTOMRIGHT", -10, 8)
    Pixel.SetHeight(card.progressBg, 4)

    card.progressFill = card:CreateTexture(nil, "ARTWORK")
    Pixel.SetPoint(card.progressFill, "TOPLEFT", card.progressBg, "TOPLEFT", 0, 0)
    Pixel.SetPoint(card.progressFill, "BOTTOMLEFT", card.progressBg, "BOTTOMLEFT", 0, 0)
    Pixel.SetWidth(card.progressFill, 4)

    card.hover = card:CreateTexture(nil, "HIGHLIGHT")
    card.hover:SetAllPoints()
    card.hover:SetColorTexture(1, 1, 1, 0.04)

    local function UpdateProgress()
        local usableWidth = math.max(4, card:GetWidth() - 20)
        Pixel.SetWidth(card.progressFill, math.max(4, usableWidth * math.min(math.max(card._progress or 0, 0), 1)))
    end

    local function ApplyTheme()
        local theme = MedaUI.Theme
        local border = theme.border or { 0.2, 0.2, 0.22, 0.6 }
        local background = theme.backgroundDark or { 0.08, 0.08, 0.09, 0.9 }
        local accent = card._accentColor or theme.gold or { 0.9, 0.7, 0.15, 1 }
        local valueColor = card._valueColor or theme.textDim or { 0.6, 0.6, 0.6, 1 }

        card:SetBackdropColor(background[1], background[2], background[3], 0.72)
        card:SetBackdropBorderColor(border[1], border[2], border[3], (border[4] or 0.6) * 1.1)

        card.iconFrame:SetBackdropColor(0, 0, 0, 0.45)
        card.iconFrame:SetBackdropBorderColor(border[1], border[2], border[3], 0.65)

        card.slotLabel:SetTextColor(unpack(theme.gold or { 0.9, 0.7, 0.15, 1 }))
        card.title:SetTextColor(unpack(theme.textBright or theme.text or { 0.9, 0.9, 0.9, 1 }))
        card.detail:SetTextColor(unpack(theme.textDim or { 0.6, 0.6, 0.6, 1 }))
        card.valueLabel:SetTextColor(valueColor[1], valueColor[2], valueColor[3], valueColor[4] or 1)
        card.progressBg:SetColorTexture(1, 1, 1, 0.08)
        card.progressFill:SetColorTexture(accent[1], accent[2], accent[3], accent[4] or 0.85)
    end

    card._themeHandle = ui:RegisterThemedWidget(card, ApplyTheme)

    card:SetScript("OnEnter", function(frame)
        if frame._tooltipFunc then
            GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
            frame._tooltipFunc(frame, GameTooltip)
            GameTooltip:Show()
        end
    end)

    card:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    function card.SetSlotLabel(frame, text)
        frame.slotLabel:SetText(text or "")
    end

    function card.SetValueText(frame, text, r, g, b, a)
        frame.valueLabel:SetText(text or "")
        if r then
            frame._valueColor = { r, g, b, a or 1 }
        else
            frame._valueColor = nil
        end
        ApplyTheme()
    end

    function card.SetTitle(frame, text)
        frame.title:SetText(text or "")
    end

    function card.SetDetail(frame, text)
        frame.detail:SetText((text and text ~= "") and text or " ")
    end

    function card.SetIcon(frame, texture)
        frame.icon:SetTexture(texture or 134400)
    end

    function card.SetProgress(frame, value)
        frame._progress = value or 0
        UpdateProgress()
    end

    function card.SetAccentColor(frame, r, g, b, a)
        if r then
            frame._accentColor = { r, g, b, a or 1 }
        else
            frame._accentColor = nil
        end
        ApplyTheme()
    end

    function card.SetTooltipFunc(frame, func)
        frame._tooltipFunc = func
    end

    function card.Reset(frame)
        frame:SetSlotLabel("")
        frame:SetValueText("")
        frame:SetTitle("")
        frame:SetDetail("")
        frame:SetIcon(nil)
        frame:SetProgress(0)
        frame:SetAccentColor(nil)
        frame:SetTooltipFunc(nil)
    end

    UpdateProgress()
    ApplyTheme()
    return card
end
