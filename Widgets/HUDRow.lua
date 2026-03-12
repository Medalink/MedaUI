--[[
    MedaUI HUDRow Widget
    Compact overlay row for transparent HUD displays.
    Layout: [state] [icon] [text............] [timer] [delta]
    Designed for in-game overlays (prophecy timelines, objective trackers, etc.)
]]

local MedaUI = LibStub("MedaUI-1.0")
local Pixel = LibStub("MedaUI-1.0").Pixel

local DEFAULT_WIDTH = 260
local DEFAULT_ICON_SIZE = 16
local DEFAULT_ROW_HEIGHT = 20
local STATE_WIDTH = 14
local TIMER_WIDTH = 52
local DELTA_WIDTH = 52
local PAD = 4

local STATE_MARKERS = {
    active    = "\226\151\139",  -- ○
    fulfilled = "\226\156\147",  -- ✓
    dormant   = "\194\183",      -- ·
    dismissed = "\226\128\148",  -- —
    paused    = "\226\128\150",  -- ‖
}

local floor = math.floor
local format = string.format
local abs = math.abs
local unpack = unpack

local function FormatDelta(seconds)
    local sign = seconds >= 0 and "+" or "-"
    local s = abs(seconds)
    return format("%s%d:%02d", sign, floor(s / 60), s % 60)
end

--- Create a compact HUD overlay row with state marker, icon, text, timer, and delta.
--- @param parent Frame The parent frame
--- @param config table|nil Configuration overrides
--- @return Frame The HUD row widget
---
--- Config keys:
---   width      (number, default 260) -- row width (nil to fill parent)
---   iconSize   (number, default 16)  -- type icon size
---   showTimer  (boolean, default true)  -- show right-aligned countdown
---   showDelta  (boolean, default true)  -- show delta indicator
---   showState  (boolean, default true)  -- show left state marker
---   interactive (boolean, default true) -- enable right-click handlers
function MedaUI:CreateHUDRow(parent, config)
    config = config or {}

    local width = config.width or DEFAULT_WIDTH
    local iconSize = config.iconSize or DEFAULT_ICON_SIZE
    local showTimer = config.showTimer ~= false
    local showDelta = config.showDelta ~= false
    local showState = config.showState ~= false
    local interactive = config.interactive ~= false

    local row = CreateFrame("Frame", nil, parent)
    Pixel.SetSize(row, width, DEFAULT_ROW_HEIGHT)

    -- State marker (○ ✓ · — ‖)
    row.stateMarker = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    Pixel.SetPoint(row.stateMarker, "LEFT", 0, 0)
    Pixel.SetWidth(row.stateMarker, showState and STATE_WIDTH or 0)
    row.stateMarker:SetJustifyH("CENTER")
    row.stateMarker:SetText(STATE_MARKERS.active)
    if not showState then
        row.stateMarker:Hide()
    end

    -- Type icon
    row.icon = row:CreateTexture(nil, "ARTWORK")
    Pixel.SetSize(row.icon, iconSize, iconSize)
    Pixel.SetPoint(row.icon, "LEFT", showState and STATE_WIDTH or 0, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon:Hide()

    local textLeftAnchor = (showState and STATE_WIDTH or 0) + iconSize + PAD

    -- Delta text (rightmost, anchored to right edge)
    row.delta = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    Pixel.SetPoint(row.delta, "RIGHT", 0, 0)
    Pixel.SetWidth(row.delta, DELTA_WIDTH)
    row.delta:SetJustifyH("RIGHT")
    if not showDelta then row.delta:Hide() end

    -- Timer text (left of delta)
    row.timer = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    if showDelta then
        Pixel.SetPoint(row.timer, "RIGHT", row.delta, "LEFT", -PAD, 0)
    else
        Pixel.SetPoint(row.timer, "RIGHT", 0, 0)
    end
    Pixel.SetWidth(row.timer, TIMER_WIDTH)
    row.timer:SetJustifyH("RIGHT")
    if not showTimer then row.timer:Hide() end

    -- Main text (fills remaining space between icon and timer/delta)
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    Pixel.SetPoint(row.text, "LEFT", textLeftAnchor, 0)
    if showTimer then
        Pixel.SetPoint(row.text, "RIGHT", row.timer, "LEFT", -PAD, 0)
    elseif showDelta then
        Pixel.SetPoint(row.text, "RIGHT", row.delta, "LEFT", -PAD, 0)
    else
        Pixel.SetPoint(row.text, "RIGHT", -PAD, 0)
    end
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(false)

    -- Shadow for readability over game world
    row.text:SetShadowOffset(1, -1)
    row.text:SetShadowColor(0, 0, 0, 0.8)
    row.timer:SetShadowOffset(1, -1)
    row.timer:SetShadowColor(0, 0, 0, 0.8)
    row.delta:SetShadowOffset(1, -1)
    row.delta:SetShadowColor(0, 0, 0, 0.8)
    row.stateMarker:SetShadowOffset(1, -1)
    row.stateMarker:SetShadowColor(0, 0, 0, 0.8)

    -- Internal state
    row._state = "active"
    row._deltaSeconds = nil
    row._onFulfill = nil
    row._onDismiss = nil
    row._showTimer = showTimer
    row._showDelta = showDelta
    row._showState = showState

    -- Right-click interaction
    if interactive then
        row:EnableMouse(true)
        row:SetScript("OnMouseUp", function(self, button)
            if button == "RightButton" then
                if IsShiftKeyDown() then
                    if self._onDismiss then self._onDismiss(self) end
                else
                    if self._onFulfill then self._onFulfill(self) end
                end
            end
        end)

        row:SetScript("OnEnter", function(self)
            self.text:SetTextColor(unpack(MedaUI.Theme.textBright or MedaUI.Theme.text or {1, 1, 1}))
        end)
        row:SetScript("OnLeave", function(self)
            self:_ApplyStateColor()
        end)
    end

    -- Theme support
    local function ApplyTheme()
        row:_ApplyStateColor()
        row.timer:SetTextColor(unpack(MedaUI.Theme.textDim or {0.7, 0.7, 0.7}))
        if row._deltaSeconds then
            row:SetDelta(row._deltaSeconds)
        end
    end
    row._ApplyThemeFunc = ApplyTheme
    row._themeHandle = MedaUI:RegisterThemedWidget(row, ApplyTheme)

    -- ----------------------------------------------------------------
    -- Internal helpers
    -- ----------------------------------------------------------------

    function row:_ApplyStateColor()
        local Theme = MedaUI.Theme
        local state = self._state
        if state == "fulfilled" then
            self.stateMarker:SetTextColor(unpack(Theme.success or {0.35, 0.8, 0.45}))
            self.text:SetTextColor(unpack(Theme.textDim or {0.7, 0.7, 0.7}))
        elseif state == "dormant" or state == "dismissed" then
            self.stateMarker:SetTextColor(unpack(Theme.textDisabled or {0.4, 0.4, 0.4}))
            self.text:SetTextColor(unpack(Theme.textDisabled or {0.4, 0.4, 0.4}))
        elseif state == "paused" then
            self.stateMarker:SetTextColor(unpack(Theme.warning or {1, 0.62, 0.12}))
            self.text:SetTextColor(unpack(Theme.text or {1, 1, 1}))
        else
            self.stateMarker:SetTextColor(unpack(Theme.text or {1, 1, 1}))
            self.text:SetTextColor(unpack(Theme.text or {1, 1, 1}))
        end
    end

    -- ----------------------------------------------------------------
    -- Public API
    -- ----------------------------------------------------------------

    --- Set the visual state of the row.
    --- @param state string One of "active", "fulfilled", "dormant", "dismissed", "paused"
    function row:SetState(state)
        self._state = state
        if self._showState then
            self.stateMarker:SetText(STATE_MARKERS[state] or STATE_MARKERS.active)
        end
        self:_ApplyStateColor()
    end

    --- Set the type icon.
    --- @param texture number|string|nil Texture ID, path, or nil to hide
    function row:SetIcon(texture)
        if texture then
            self.icon:SetTexture(texture)
            self.icon:Show()
        else
            self.icon:Hide()
        end
    end

    --- Set a colored circle as the icon instead of a texture.
    --- @param r number Red (0-1)
    --- @param g number Green (0-1)
    --- @param b number Blue (0-1)
    function row:SetIconColor(r, g, b)
        self.icon:SetColorTexture(r, g, b, 1)
        self.icon:Show()
    end

    function row:SetIconDesaturated(desaturated)
        self.icon:SetDesaturated(desaturated and true or false)
    end

    --- Set the main prophecy text.
    --- @param text string
    function row:SetText(text)
        self.text:SetText(text or "")
    end

    --- Set the countdown timer string.
    --- @param text string|nil Timer text (e.g. "~3:22", "0:12", "paused") or nil to clear
    function row:SetTimer(text)
        self.timer:SetText(text or "")
    end

    --- Set the delta indicator.
    --- Auto-formats seconds as "+M:SS" / "-M:SS" and colors by threshold.
    --- @param seconds number|nil Delta in seconds (positive = behind, negative = ahead), nil to clear
    --- @param thresholds table|nil Optional {neutral = 15, mild = 60} overrides
    function row:SetDelta(seconds, thresholds)
        self._deltaSeconds = seconds
        if seconds == nil then
            self.delta:SetText("")
            return
        end

        local Theme = MedaUI.Theme
        local neutral = thresholds and thresholds.neutral or 15
        local mild = thresholds and thresholds.mild or 60

        self.delta:SetText(FormatDelta(seconds))

        local s = abs(seconds)
        if s <= neutral then
            self.delta:SetTextColor(unpack(Theme.textDim or {0.7, 0.7, 0.7}))
        elseif seconds > 0 then
            if s <= mild then
                self.delta:SetTextColor(unpack(Theme.warning or {1, 0.62, 0.12}))
            else
                self.delta:SetTextColor(unpack(Theme.error or {1, 0.42, 0.42}))
            end
        else
            self.delta:SetTextColor(unpack(Theme.success or {0.35, 0.8, 0.45}))
        end
    end

    --- Set the right-click fulfill callback.
    --- @param fn function|nil Called with (row) on right-click
    function row:SetOnFulfill(fn)
        self._onFulfill = fn
    end

    --- Set the shift+right-click dismiss callback.
    --- @param fn function|nil Called with (row) on shift+right-click
    function row:SetOnDismiss(fn)
        self._onDismiss = fn
    end

    --- Reset the row to its default empty state.
    function row:Reset()
        self:SetState("active")
        self:SetIcon(nil)
        self:SetText("")
        self:SetTimer("")
        self._deltaSeconds = nil
        self.delta:SetText("")
        self._onFulfill = nil
        self._onDismiss = nil
    end

    -- Apply initial theme
    ApplyTheme()

    return row
end
