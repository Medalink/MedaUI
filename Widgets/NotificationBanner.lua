--[[
    MedaUI NotificationBanner Widget
    Timed notification banner with optional countdown bar.
    Shows a text message and auto-hides after a configurable duration.
]]

local MedaUI = LibStub("MedaUI-1.0")

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
function MedaUI:CreateNotificationBanner(name, config)
    config = config or {}

    local frame = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    frame:SetFrameStrata(config.strata or "MEDIUM")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetSize(config.width or 220, config.height or 36)
    frame:RegisterForDrag("LeftButton")

    MedaUI:ApplyBackdrop(frame, "backgroundDark", "border")

    -- State
    frame._duration = config.duration or 3
    frame._hideTime = nil
    frame._locked = config.locked or false

    -- Drag
    frame:SetScript("OnDragStart", function(self)
        if not self._locked then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    -- Text
    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.text:SetPoint("CENTER", 0, 0)
    frame.text:SetJustifyH("CENTER")

    -- Bar background
    frame.barBg = CreateFrame("Frame", nil, frame)
    frame.barBg:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 2, 0)
    frame.barBg:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", -2, 0)
    frame.barBg:SetHeight((config.barHeight or 4) + 2)

    local bgTex = frame.barBg:CreateTexture(nil, "BACKGROUND")
    bgTex:SetAllPoints()
    bgTex:SetColorTexture(0, 0, 0, 0.4)

    -- Countdown bar
    frame.bar = CreateFrame("StatusBar", nil, frame)
    frame.bar:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 2, 0)
    frame.bar:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", -2, 0)
    frame.bar:SetHeight(config.barHeight or 4)
    frame.bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    frame.bar:SetMinMaxValues(0, 1)
    frame.bar:SetValue(1)

    if config.showBar == false then
        frame.bar:Hide()
        frame.barBg:Hide()
    end

    -- OnUpdate drives the countdown
    frame.bar:SetScript("OnUpdate", function(self)
        if not frame._hideTime then return end
        local remaining = frame._hideTime - GetTime()
        if remaining <= 0 then
            frame:Hide()
            frame._hideTime = nil
            self:SetValue(0)
            if frame.OnHide then frame:OnHide() end
            return
        end
        self:SetValue(remaining / frame._duration)
    end)

    frame:Hide()

    -- Theme support
    local function ApplyTheme()
        local Theme = MedaUI.Theme
        frame:SetBackdropBorderColor(unpack(Theme.border))
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
        self:SetWidth(math.max(textW + 30, 160))

        local dur = duration or self._duration
        self._duration = dur
        self._hideTime = GetTime() + dur

        if self.bar:IsShown() then
            self.bar:SetValue(1)
        end

        getmetatable(self).__index.Show(self)

        if self.OnShow then self:OnShow(text) end
    end

    function frame:Dismiss()
        self._hideTime = nil
        self:Hide()
        if self.OnHide then self:OnHide() end
    end

    function frame:SetDuration(sec)
        self._duration = sec
    end

    function frame:SetBarHeight(h)
        self.bar:SetHeight(h)
        self.barBg:SetHeight(h + 2)
    end

    function frame:SetShowBar(show)
        if show then
            self.bar:Show()
            self.barBg:Show()
        else
            self.bar:Hide()
            self.barBg:Hide()
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
        local Theme = MedaUI.Theme
        local r, g, b = Theme.backgroundDark[1], Theme.backgroundDark[2], Theme.backgroundDark[3]
        self:SetBackdropColor(r, g, b, alpha)
    end

    function frame:SavePosition()
        local point, _, _, x, y = self:GetPoint()
        return { point = point or "CENTER", x = x or 0, y = y or 0 }
    end

    function frame:RestorePosition(tbl)
        self:ClearAllPoints()
        if tbl then
            self:SetPoint(tbl.point or "TOP", UIParent, tbl.point or "TOP", tbl.x or 0, tbl.y or -100)
        else
            self:SetPoint("TOP", UIParent, "TOP", 0, -100)
        end
    end

    function frame:ResetPosition()
        self:RestorePosition(nil)
    end

    --- Show the banner in static preview mode (no countdown, always visible).
    --- Useful for settings panels where the user needs to position the banner.
    --- @param text string The preview text to display
    function frame:ShowPreview(text)
        self._hideTime = nil
        self.text:SetText(text or "Preview")

        local textW = self.text:GetStringWidth()
        self:SetWidth(math.max(textW + 30, 160))

        if self.bar:IsShown() then
            self.bar:SetValue(0.65)
        end

        getmetatable(self).__index.Show(self)
    end

    --- Hide the banner from preview mode.
    function frame:DismissPreview()
        self._hideTime = nil
        getmetatable(self).__index.Hide(self)
    end

    return frame
end
