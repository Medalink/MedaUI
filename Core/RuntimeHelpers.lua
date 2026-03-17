local MedaUI = LibStub("MedaUI-2.0")
local gsub = string.gsub
local lower = string.lower

if MedaUI.soundsEnabled == nil then
    MedaUI.soundsEnabled = true
end

local SOUND_COOLDOWN = 0.05
local lastSoundTime = {}
local LEGACY_SOUNDKIT_MAP = {
    ["sound\\interface\\raidwarning.ogg"] = "RAID_WARNING",
    ["sound\\interface\\readycheck.ogg"] = "READY_CHECK",
    ["sound\\interface\\alarmclockwarning3.ogg"] = "ALARM_CLOCK_WARNING_3",
    ["sound\\interface\\levelup2.ogg"] = "LEVELUP",
}

local BACKDROP_WITH_EDGE = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

local BACKDROP_NO_EDGE = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
}

function MedaUI:SetSoundsEnabled(enabled)
    self.soundsEnabled = enabled
end

function MedaUI:AreSoundsEnabled()
    return self.soundsEnabled
end

function MedaUI:PlaySound(name)
    if not name or not self.soundsEnabled then
        return
    end

    local now = GetTime()
    if lastSoundTime[name] and (now - lastSoundTime[name]) < SOUND_COOLDOWN then
        return
    end

    lastSoundTime[name] = now
    pcall(PlaySoundFile, self.mediaPath .. "Sounds\\" .. name .. ".ogg", "Master")
end

function MedaUI:PlaySoundPath(path)
    if not path or not self.soundsEnabled then
        return
    end

    local soundKit
    if type(path) == "string" then
        local token = path:match("^soundkit:(.+)$")
        if not token then
            local normalized = lower(gsub(path, "/", "\\"))
            token = LEGACY_SOUNDKIT_MAP[normalized]
        end
        if token then
            if tonumber(token) then
                soundKit = tonumber(token)
            elseif SOUNDKIT then
                soundKit = SOUNDKIT[token]
            end
        end
    end

    if soundKit then
        local ok, played = pcall(PlaySound, soundKit, "Master")
        if ok and played ~= false then
            return true
        end
    end

    local ok, played = pcall(PlaySoundFile, path, "Master")
    if ok and played ~= false then
        return true
    end

    ok, played = pcall(PlaySoundFile, path, "SFX")
    if ok and played ~= false then
        return true
    end

    if MedaAuras and MedaAuras.LogDebug then
        MedaAuras.LogDebug(format("[MedaUI] Failed to play sound path: %s", tostring(path)))
    end
    return false
end

function MedaUI:GetStatusColor(value, thresholds)
    local theme = self.Theme

    for _, threshold in ipairs(thresholds) do
        if not threshold.max or value <= threshold.max then
            local color = threshold.color
            if type(color) == "string" then
                local themeColor = theme[color]
                if themeColor then
                    return themeColor[1], themeColor[2], themeColor[3]
                end
            elseif type(color) == "table" then
                return color[1], color[2], color[3]
            end
        end
    end

    local fallback = theme.text or { 1, 1, 1, 1 }
    return fallback[1], fallback[2], fallback[3]
end

function MedaUI:GetFPSColor(fps)
    return self:GetStatusColor(fps, {
        { max = 30, color = { 1, 0.3, 0.3 } },
        { max = 60, color = { 1, 0.8, 0 } },
        { color = { 0.4, 0.9, 0.4 } },
    })
end

function MedaUI:GetLatencyColor(latency)
    return self:GetStatusColor(latency, {
        { max = 100, color = { 0.4, 0.9, 0.4 } },
        { max = 300, color = { 1, 0.8, 0 } },
        { color = { 1, 0.3, 0.3 } },
    })
end

function MedaUI:GetMemoryColor(percent)
    return self:GetStatusColor(percent, {
        { max = 50, color = { 0.4, 0.9, 0.4 } },
        { max = 80, color = { 1, 0.8, 0 } },
        { color = { 1, 0.3, 0.3 } },
    })
end

function MedaUI:GetCombatColor(inCombat)
    if inCombat then
        return 1, 0.3, 0.3
    end

    return 0.4, 0.9, 0.4
end

function MedaUI:CreateScrollFrame(parent, name, width, height)
    local scrollParent = self.Pixel.CreateScrollFrame(parent, name, width, height, "none", "none")

    local function ApplyThemeToScrollbar()
        local color = self.Theme.gold or self.Theme.accent or { 0.9, 0.7, 0.15, 1 }
        local thumb = scrollParent.scrollThumb
        if thumb then
            thumb.r, thumb.g, thumb.b = color[1], color[2], color[3]
            thumb:SetBackdropColor(color[1], color[2], color[3], 0.7)
        end
    end

    ApplyThemeToScrollbar()
    self:RegisterThemedWidget(scrollParent, ApplyThemeToScrollbar)
    return scrollParent
end

function MedaUI:CreateBackdrop(hasEdge)
    return hasEdge and BACKDROP_WITH_EDGE or BACKDROP_NO_EDGE
end

function MedaUI:CreateThemedFrame(parent, name, width, height, bgKey, borderKey)
    local frame = self.Pixel.CreateBorderedFrame(parent, name, width, height)
    self:ApplyBackdrop(frame, bgKey or "background", borderKey or "border")
    return frame
end

function MedaUI:ApplyBackdrop(frame, bgKey, borderKey)
    bgKey = bgKey or "background"
    borderKey = borderKey or "border"

    if self.Theme[bgKey] then
        frame:SetBackdropColor(unpack(self.Theme[bgKey]))
    end
    if self.Theme[borderKey] then
        frame:SetBackdropBorderColor(unpack(self.Theme[borderKey]))
    end
end
