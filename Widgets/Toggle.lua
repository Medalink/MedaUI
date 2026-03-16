--[[
    MedaUI Toggle Widget
    Pill-shaped track with sliding knob (matches rend mu-toggle)
    Track: 32x16, Knob: 10x10, slides 16px right when on
]]

local MedaUI = LibStub("MedaUI-2.0")
---@cast MedaUI MedaUILibrary
local Pixel = MedaUI.Pixel

local TRACK_W, TRACK_H = 32, 16
local KNOB_SIZE = 10
local KNOB_INSET = 2
local KNOB_TRAVEL = 16

--- Create a themed toggle switch
--- @param parent Frame The parent frame
--- @param label string|nil Optional label text
--- @return Frame The toggle container frame
function MedaUI.CreateToggle(_, parent, label)
    local container = CreateFrame("Frame", nil, parent)
    Pixel.SetSize(container, label and 200 or TRACK_W, TRACK_H)

    local track = CreateFrame("Button", nil, container, "BackdropTemplate")
    Pixel.SetSize(track, TRACK_W, TRACK_H)
    Pixel.SetPoint(track, "LEFT", 0, 0)
    track:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })

    local trackTex = track:CreateTexture(nil, "ARTWORK")
    trackTex:SetTexture(MedaUI.mediaPath .. "Textures\\track-pill.tga")
    trackTex:SetAllPoints()
    trackTex:SetAlpha(0.15)

    local knob = track:CreateTexture(nil, "OVERLAY")
    knob:SetTexture(MedaUI.mediaPath .. "Textures\\knob-circle.tga")
    Pixel.SetSize(knob, KNOB_SIZE, KNOB_SIZE)

    container.track = track
    container.trackTex = trackTex
    container.knob = knob
    container.checked = false

    if label then
        container.label = Pixel.CreateFontString(container, label)
        Pixel.SetPoint(container.label, "LEFT", track, "RIGHT", 10, 0)
    end

    local function PositionKnob()
        knob:ClearAllPoints()
        if container.checked then
            Pixel.SetPoint(knob, "LEFT", track, "LEFT", KNOB_INSET + KNOB_TRAVEL, 0)
        else
            Pixel.SetPoint(knob, "LEFT", track, "LEFT", KNOB_INSET, 0)
        end
    end

    local function ApplyTheme()
        local theme = MedaUI.Theme
        if container.checked then
            track:SetBackdropColor(unpack(theme.toggleOn or theme.gold))
            track:SetBackdropBorderColor(unpack(theme.borderLight or theme.border))
            knob:SetVertexColor(unpack(theme.toggleKnobOn or { 1, 1, 1, 1 }))
        else
            track:SetBackdropColor(unpack(theme.toggleOff or theme.button))
            track:SetBackdropBorderColor(unpack(theme.border))
            knob:SetVertexColor(unpack(theme.toggleKnob or { 1, 1, 1, 0.78 }))
        end
        if container.label then
            container.label:SetTextColor(unpack(theme.text))
        end
    end
    container._ApplyTheme = ApplyTheme

    container._themeHandle = MedaUI:RegisterThemedWidget(container, ApplyTheme)

    PositionKnob()
    ApplyTheme()

    track:SetScript("OnClick", function()
        container.checked = not container.checked
        PositionKnob()
        ApplyTheme()
        MedaUI:PlaySound(container.checked and "toggleOn" or "toggleOff")
        if container.OnValueChanged then
            container:OnValueChanged(container.checked)
        end
    end)

    track:SetScript("OnEnter", function()
        MedaUI:PlaySound("hover")
        local theme = MedaUI.Theme
        if not container.checked then
            track:SetBackdropColor(unpack(theme.buttonHover or theme.button))
        end
    end)

    track:SetScript("OnLeave", function()
        ApplyTheme()
    end)

    function container:SetChecked(value)
        self.checked = value and true or false
        PositionKnob()
        ApplyTheme()
    end

    function container:GetChecked()
        return self.checked
    end

    function container:SetLabel(text)
        if self.label then
            self.label:SetText(text)
        end
    end

    local originalSetScript = container.SetScript
    function container:SetScript(scriptType, handler)
        if scriptType == "OnClick" then
            track:SetScript("OnClick", function()
                self.checked = not self.checked
                PositionKnob()
                ApplyTheme()
                MedaUI:PlaySound(self.checked and "toggleOn" or "toggleOff")
                if handler then handler(self) end
                if self.OnValueChanged then self:OnValueChanged(self.checked) end
            end)
        else
            originalSetScript(self, scriptType, handler)
        end
    end

    return container
end
