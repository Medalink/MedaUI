local MedaUI = LibStub("MedaUI-2.0")

local TEXTURE_EXT = ".tga"
local MEDIA_PATH = MedaUI.mediaPath
local SOURCE_ORDER = { builtin = 1, custom = 2, lsm = 3 }

local function SortBySourceThenName(a, b)
    local leftOrder = SOURCE_ORDER[a.source] or 99
    local rightOrder = SOURCE_ORDER[b.source] or 99
    if leftOrder ~= rightOrder then
        return leftOrder < rightOrder
    end
    return a.name:lower() < b.name:lower()
end

MedaUI.Media = MedaUI.Media or {
    bars = {
        { id = "solid", name = "Solid", description = "Clean solid bar with subtle depth", file = "bar-solid", source = "builtin" },
        { id = "blizzard", name = "Blizzard", description = "Default WoW status bar", path = "Interface\\TargetingFrame\\UI-StatusBar", source = "builtin" },
        { id = "flat", name = "Flat", description = "Flat single-colour fill with no texture", path = "Interface\\Buttons\\WHITE8x8", source = "builtin" },
        { id = "raid", name = "Raid", description = "Compact bar used in raid frames", path = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill", source = "builtin" },
        { id = "spark", name = "Spark", description = "Glowing ember-like bar texture", path = "Interface\\CastingBar\\UI-CastingBar-Spark", source = "builtin" },
        { id = "shiny", name = "Shiny", description = "Bright metallic sheen", path = "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar", source = "builtin" },
        { id = "smooth", name = "Smooth", description = "Subtle smooth gradient", path = "Interface\\TargetingFrame\\UI-TargetingFrame-BarFill", source = "builtin" },
    },
    orbs = {
        { id = "solid", name = "Solid", description = "Clean simple orb with solid fill", mask = "orb-classic-mask", ring = "orb-classic-ring", source = "builtin" },
        { id = "glow", name = "Glow", description = "Soft outer glow effect", mask = "orb-glow-mask", ring = "orb-glow-ring", source = "builtin" },
        { id = "glass", name = "Glass", description = "Glossy glass-like with highlight", mask = "orb-glass-mask", ring = "orb-glass-ring", source = "builtin" },
    },
}

function MedaUI:RegisterBarTexture(id, name, path, description)
    if not id or not name or not path then
        return
    end

    local bars = self.Media.bars
    for _, entry in ipairs(bars) do
        if entry.id == id then
            entry.name = name
            entry.path = path
            entry.description = description
            return
        end
    end

    bars[#bars + 1] = { id = id, name = name, path = path, description = description or "", source = "custom" }
end

function MedaUI:RegisterOrbTexture(id, name, maskPath, ringPath, description)
    if not id or not name or not maskPath or not ringPath then
        return
    end

    local orbs = self.Media.orbs
    for _, entry in ipairs(orbs) do
        if entry.id == id then
            entry.name = name
            entry.maskPath = maskPath
            entry.ringPath = ringPath
            entry.description = description
            return
        end
    end

    orbs[#orbs + 1] = { id = id, name = name, maskPath = maskPath, ringPath = ringPath, description = description or "", source = "custom" }
end

function MedaUI:GetMediaPath(category, id)
    local categoryData = self.Media[category]
    if not categoryData then
        return nil
    end

    for _, entry in ipairs(categoryData) do
        if entry.id == id then
            if entry.path then
                return entry.path
            end
            return MEDIA_PATH .. entry.file .. TEXTURE_EXT
        end
    end

    return nil
end

function MedaUI:GetBarTexture(id)
    return self:GetMediaPath("bars", id) or (MEDIA_PATH .. "bar-solid" .. TEXTURE_EXT)
end

function MedaUI:GetMediaList(category)
    local categoryData = self.Media[category]
    if not categoryData then
        return {}
    end

    local list = {}
    for _, entry in ipairs(categoryData) do
        list[#list + 1] = {
            id = entry.id,
            name = entry.name,
            description = entry.description,
            source = entry.source or "builtin",
        }
    end

    table.sort(list, SortBySourceThenName)
    return list
end

function MedaUI:GetBarTextureList()
    local seen = {}
    local list = {}

    for _, entry in ipairs(self.Media.bars) do
        if not seen[entry.id] then
            list[#list + 1] = {
                id = entry.id,
                name = entry.name,
                description = entry.description,
                source = entry.source or "builtin",
            }
            seen[entry.id] = true
        end
    end

    local lsm = LibStub and LibStub("LibSharedMedia-3.0", true)
    if lsm then
        local lsmBars = lsm:HashTable("statusbar")
        if lsmBars then
            for lsmName, lsmPath in pairs(lsmBars) do
                local id = "lsm:" .. lsmName
                if not seen[id] then
                    list[#list + 1] = {
                        id = id,
                        name = lsmName,
                        description = "LibSharedMedia",
                        source = "lsm",
                    }
                    self.Media.bars[#self.Media.bars + 1] = {
                        id = id,
                        name = lsmName,
                        path = lsmPath,
                        description = "LibSharedMedia",
                        source = "lsm",
                    }
                    seen[id] = true
                end
            end
        end
    end

    table.sort(list, SortBySourceThenName)
    return list
end

function MedaUI:GetOrbTextures(id)
    local categoryData = self.Media.orbs
    if categoryData then
        for _, entry in ipairs(categoryData) do
            if entry.id == id then
                if entry.maskPath then
                    return entry.maskPath, entry.ringPath
                end
                return MEDIA_PATH .. entry.mask .. TEXTURE_EXT, MEDIA_PATH .. entry.ring .. TEXTURE_EXT
            end
        end
    end

    return MEDIA_PATH .. "orb-classic-mask" .. TEXTURE_EXT, MEDIA_PATH .. "orb-classic-ring" .. TEXTURE_EXT
end

function MedaUI:GetFontList()
    local seen = {}
    local fonts = {}

    local lsm = LibStub and LibStub("LibSharedMedia-3.0", true)
    if lsm then
        local lsmFonts = lsm:HashTable("font")
        if lsmFonts then
            for name, path in pairs(lsmFonts) do
                if not seen[path] then
                    fonts[#fonts + 1] = { value = path, label = name, path = path }
                    seen[path] = true
                end
            end
        end
    end

    if #fonts == 0 then
        local builtins = {
            { value = "Fonts\\FRIZQT__.TTF", label = "Friz Quadrata", path = "Fonts\\FRIZQT__.TTF" },
            { value = "Fonts\\ARIALN.TTF", label = "Arial Narrow", path = "Fonts\\ARIALN.TTF" },
            { value = "Fonts\\MORPHEUS.TTF", label = "Morpheus", path = "Fonts\\MORPHEUS.TTF" },
            { value = "Fonts\\skurri.TTF", label = "Skurri", path = "Fonts\\skurri.TTF" },
        }
        for _, font in ipairs(builtins) do
            if not seen[font.value] then
                fonts[#fonts + 1] = font
                seen[font.value] = true
            end
        end
    end

    table.sort(fonts, function(a, b)
        return a.label:lower() < b.label:lower()
    end)

    local list = { { value = "default", label = "Default (Game Font)", path = nil } }
    for _, font in ipairs(fonts) do
        list[#list + 1] = font
    end
    return list
end

function MedaUI:GetFontPath(value)
    if not value or value == "default" then
        return nil
    end
    return value
end

function MedaUI:GetSoundList()
    local seen = {}
    local sounds = {}

    local lsm = LibStub and LibStub("LibSharedMedia-3.0", true)
    if lsm then
        local lsmSounds = lsm:HashTable("sound")
        if lsmSounds then
            for name, path in pairs(lsmSounds) do
                if not seen[path] then
                    sounds[#sounds + 1] = { value = path, label = name }
                    seen[path] = true
                end
            end
        end
    end

    if #sounds == 0 then
        local builtins = {
            { value = "soundkit:RAID_WARNING", label = "Raid Warning" },
            { value = "soundkit:READY_CHECK", label = "Ready Check" },
            { value = "soundkit:ALARM_CLOCK_WARNING_3", label = "Alarm Clock" },
            { value = "soundkit:LEVELUP", label = "Level Up" },
        }
        for _, sound in ipairs(builtins) do
            if not seen[sound.value] then
                sounds[#sounds + 1] = sound
                seen[sound.value] = true
            end
        end
    end

    table.sort(sounds, function(a, b)
        return a.label:lower() < b.label:lower()
    end)

    local list = { { value = "none", label = "None (silent)" } }
    for _, sound in ipairs(sounds) do
        list[#list + 1] = sound
    end
    return list
end

function MedaUI:GetSoundPath(value)
    if not value or value == "none" then
        return nil
    end
    return value
end

function MedaUI:GetOrbTextureList()
    local categoryData = self.Media.orbs
    if not categoryData then
        return {}
    end

    local list = {}
    for _, entry in ipairs(categoryData) do
        list[#list + 1] = {
            id = entry.id,
            name = entry.name,
            description = entry.description,
        }
    end
    return list
end
