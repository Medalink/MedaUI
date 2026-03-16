--[[
    MedaUI NotificationBanner Widget
    Timed notification banner with optional countdown bar.
    Shows a text message and auto-hides after a configurable duration.
]]

local MedaUI = LibStub("MedaUI-2.0")
---@cast MedaUI MedaUILibrary
local Pixel = LibStub("MedaUI-2.0").Pixel
local COUNTDOWN_UPDATE_INTERVAL = 0.05

--- Create a notification banner that auto-hides with an optional countdown bar.
--- @param name string Unique global frame name
--- @param config table|nil Configuration overrides
--- @return table The banner widget
---
--- Config keys:
---   duration (number, default 3) — seconds before auto-hide
---   barHeight (number, default 4) — countdown bar pixel height
---   showBar (boolean, default true) — whether the countdown bar is visible
---   strata (string, default "MEDIUM") — frame strata
---   width (number, default 220) — initial frame width
---   height (number, default 36) — frame height (text area)
---   locked (boolean, default false) — if true, frame cannot be dragged
---
--- API:
---   banner:Show(text, duration) — show with message; duration overrides config
---   banner:Dismiss() — hide immediately
---   banner:SetDuration(sec)
---   banner:SetBarHeight(h)
---   banner:SetShowBar(bool)
---   banner:SetLocked(bool)
---   banner:SetTextFont(fontObj)
---   banner:SetTextColor(r, g, b)
---   banner:SetBarColor(r, g, b)
---   banner:SetBackgroundOpacity(alpha)
---   banner:SavePosition() -> table {point, x, y}
---   banner:RestorePosition(tbl)
---   banner:ResetPosition()
---   banner.OnShow(self, text) — callback
---   banner.OnHide(self) — callback
function MedaUI.CreateNotificationBanner(library, name, config)
    config = config or {}

    local frame = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    frame:SetFrameStrata(config.strata or "MEDIUM")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    Pixel.SetSize(frame, config.width or 220, config.height or 36)
    frame:RegisterForDrag("LeftButton")
    local NativeShow = frame.Show
    local NativeHide = frame.Hide

    library:ApplyBackdrop(frame, "backgroundDark", "border")

    -- State
    frame._duration = config.duration or 3
    frame._hideTime = nil
    frame._locked = config.locked or false
    frame._countdownTicker = nil
    frame._dismissTimer = nil
    frame._countdownToken = 0

    -- Drag
    frame:SetScript("OnDragStart", function(self)
        if not self._locked then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    -- Text
    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    Pixel.SetPoint(frame.text, "CENTER", 0, 0)
    frame.text:SetJustifyH("CENTER")

    -- Bar background
    frame.barBg = CreateFrame("Frame", nil, frame)
    Pixel.SetPoint(frame.barBg, "TOPLEFT", frame, "BOTTOMLEFT", 2, 0)
    Pixel.SetPoint(frame.barBg, "TOPRIGHT", frame, "BOTTOMRIGHT", -2, 0)
    Pixel.SetHeight(frame.barBg, (config.barHeight or 4) + 2)

    local bgTex = frame.barBg:CreateTexture(nil, "BACKGROUND")
    bgTex:SetAllPoints()
    bgTex:SetColorTexture(0, 0, 0, 0.4)

    -- Countdown bar
    frame.bar = CreateFrame("StatusBar", nil, frame)
    Pixel.SetPoint(frame.bar, "TOPLEFT", frame, "BOTTOMLEFT", 2, 0)
    Pixel.SetPoint(frame.bar, "TOPRIGHT", frame, "BOTTOMRIGHT", -2, 0)
    Pixel.SetHeight(frame.bar, config.barHeight or 4)
    frame.bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    frame.bar:SetMinMaxValues(0, 1)
    frame.bar:SetValue(1)

    if config.showBar == false then
        frame.bar:Hide()
        frame.barBg:Hide()
    end

    frame:Hide()

    local function StopCountdown()
        if frame._countdownTicker then
            frame._countdownTicker:Cancel()
            frame._countdownTicker = nil
        end
        if frame._dismissTimer then
            frame._dismissTimer:Cancel()
            frame._dismissTimer = nil
        end
        frame._hideTime = nil
    end

    local function FinishCountdown()
        StopCountdown()
        frame.bar:SetValue(0)
        NativeHide(frame)
        if frame.OnHide then frame:OnHide() end
    end

    local function RefreshCountdownBar()
        if not frame._hideTime or not frame.bar:IsShown() then
            return
        end

        local remaining = frame._hideTime - GetTime()
        if remaining <= 0 then
            FinishCountdown()
            return
        end

        frame.bar:SetValue(remaining / frame._duration)
    end

    local function StartCountdown(duration)
        StopCountdown()

        frame._duration = duration
        frame._hideTime = GetTime() + duration
        frame._countdownToken = frame._countdownToken + 1

        if frame.bar:IsShown() then
            frame.bar:SetValue(1)
            frame._countdownTicker = C_Timer.NewTicker(COUNTDOWN_UPDATE_INTERVAL, RefreshCountdownBar)
        end

        local token = frame._countdownToken
        frame._dismissTimer = C_Timer.NewTimer(duration, function()
            if frame._countdownToken ~= token then
                return
            end
            FinishCountdown()
        end)
    end

    frame:HookScript("OnHide", StopCountdown)

    -- Theme support
    local function ApplyTheme()
        local theme = MedaUI.Theme
        frame:SetBackdropBorderColor(unpack(theme.border))
    end
    frame._ApplyTheme = ApplyTheme
    frame._themeHandle = MedaUI:RegisterThemedWidget(frame, ApplyTheme)
    ApplyTheme()

    -- ----------------------------------------------------------------
    -- Public API
    -- ----------------------------------------------------------------

    function frame:Show(text, duration)
        self.text:SetText(text or "")

        local textW = self.text:GetStringWidth()
        Pixel.SetWidth(self, math.max(textW + 30, 160))

        local dur = duration or self._duration
        StartCountdown(dur)
        NativeShow(self)

        if self.OnShow then self:OnShow(text) end
    end

    function frame:Dismiss()
        StopCountdown()
        NativeHide(self)
        if self.OnHide then self:OnHide() end
    end

    function frame:SetDuration(sec)
        self._duration = sec
    end

    function frame:SetBarHeight(h)
        Pixel.SetHeight(self.bar, h)
        Pixel.SetHeight(self.barBg, h + 2)
    end

    function frame:SetShowBar(show)
        if show then
            self.bar:Show()
            self.barBg:Show()
            if self._hideTime and not self._countdownTicker then
                self._countdownTicker = C_Timer.NewTicker(COUNTDOWN_UPDATE_INTERVAL, RefreshCountdownBar)
                RefreshCountdownBar()
            end
        else
            self.bar:Hide()
            self.barBg:Hide()
            if self._countdownTicker then
                self._countdownTicker:Cancel()
                self._countdownTicker = nil
            end
        end
    end

    function frame:SetLocked(locked)
        self._locked = locked
    end

    function frame:SetTextFont(fontObj)
        self.text:SetFontObject(fontObj)
    end

    function frame:SetTextColor(r, g, b)
        self.text:SetTextColor(r, g, b)
    end

    function frame:SetBarColor(r, g, b)
        self.bar:SetStatusBarColor(r, g, b, 1)
    end

    function frame:SetBackgroundOpacity(alpha)
        local theme = MedaUI.Theme
        local r, g, b = theme.backgroundDark[1], theme.backgroundDark[2], theme.backgroundDark[3]
        self:SetBackdropColor(r, g, b, alpha)
    end

    function frame:SavePosition()
        local point, _, _, x, y = self:GetPoint()
        return { point = point or "CENTER", x = x or 0, y = y or 0 }
    end

    function frame:RestorePosition(tbl)
        Pixel.ClearPoints(self)
        if tbl then
            Pixel.SetPoint(self, tbl.point or "TOP", UIParent, tbl.point or "TOP", tbl.x or 0, tbl.y or -100)
        else
            Pixel.SetPoint(self, "TOP", UIParent, "TOP", 0, -100)
        end
    end

    function frame:ResetPosition()
        self:RestorePosition(nil)
    end

    --- Show the banner in static preview mode (no countdown, always visible).
    --- Useful for settings panels where the user needs to position the banner.
    --- @param text string The preview text to display
    function frame:ShowPreview(text)
        StopCountdown()
        self.text:SetText(text or "Preview")

        local textW = self.text:GetStringWidth()
        Pixel.SetWidth(self, math.max(textW + 30, 160))

        if self.bar:IsShown() then
            self.bar:SetValue(0.65)
        end

        NativeShow(self)
    end

    --- Hide the banner from preview mode.
    function frame:DismissPreview()
        StopCountdown()
        NativeHide(self)
    end

    return frame
end
