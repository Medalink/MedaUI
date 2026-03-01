--[[
    MedaUI - Shared UI Library
    A themed UI component library for Medalink's WoW addons
]]

-- Library registration with LibStub
local MAJOR, MINOR = "MedaUI-1.0", 1
local MedaUI = LibStub:NewLibrary(MAJOR, MINOR)
if not MedaUI then return end  -- Newer version already loaded

-- ============================================================================
-- Theme System Infrastructure
-- ============================================================================

-- Theme registry - stores all registered themes
MedaUI.themes = MedaUI.themes or {}

-- Active theme name
MedaUI.activeThemeName = MedaUI.activeThemeName or nil

-- Widget registry for theme updates
MedaUI._widgetRegistry = MedaUI._widgetRegistry or {}
MedaUI._widgetHandleCounter = MedaUI._widgetHandleCounter or 0

-- Initialize CallbackHandler for theme change events
MedaUI.callbacks = MedaUI.callbacks or LibStub("CallbackHandler-1.0"):New(MedaUI)

-- Current theme table (replaced on theme switch)
MedaUI.Theme = MedaUI.Theme or {}

-- ============================================================================
-- Theme Registration and Switching API
-- ============================================================================

--- Register a new theme
--- @param name string Unique theme identifier
--- @param colors table Theme color definitions
--- @param metadata table|nil Optional metadata {displayName, description}
function MedaUI:RegisterTheme(name, colors, metadata)
    metadata = metadata or {}
    self.themes[name] = {
        name = name,
        colors = colors,
        displayName = metadata.displayName or name,
        description = metadata.description or "",
    }

    -- If this is the first theme registered and no theme is active, activate it
    if not self.activeThemeName then
        self:SetTheme(name)
    end
end

--- Set the active theme
--- @param name string The theme name to activate
--- @return boolean success Whether the theme was successfully set
function MedaUI:SetTheme(name)
    local themeData = self.themes[name]
    if not themeData then
        return false
    end

    local previousTheme = self.activeThemeName
    self.activeThemeName = name

    -- Replace MedaUI.Theme with the new theme's colors
    -- We replace the table contents rather than the reference to maintain
    -- compatibility with widgets that may have captured the table reference
    wipe(self.Theme)
    for key, value in pairs(themeData.colors) do
        self.Theme[key] = value
    end

    -- Notify all registered widgets
    for handle, entry in pairs(self._widgetRegistry) do
        if entry.refreshFunc then
            -- pcall to prevent one widget from breaking others
            local success, err = pcall(entry.refreshFunc)
            if not success then
                -- Silent fail, or could log error
            end
        end
    end

    -- Fire callback for external listeners
    self.callbacks:Fire("THEME_CHANGED", name, previousTheme)

    return true
end

--- Get the currently active theme name
--- @return string|nil The active theme name
function MedaUI:GetActiveThemeName()
    return self.activeThemeName
end

--- Get a list of all available themes
--- @return table Array of {name, displayName, description} for each theme
function MedaUI:GetAvailableThemes()
    local themes = {}
    for name, data in pairs(self.themes) do
        themes[#themes + 1] = {
            name = data.name,
            displayName = data.displayName,
            description = data.description,
        }
    end
    -- Sort alphabetically by display name
    table.sort(themes, function(a, b)
        return a.displayName < b.displayName
    end)
    return themes
end

--- Register a widget for theme updates
--- @param widget table The widget object (used as identifier)
--- @param refreshFunc function Function to call when theme changes
--- @return number handle Handle for unregistering
function MedaUI:RegisterThemedWidget(widget, refreshFunc)
    self._widgetHandleCounter = self._widgetHandleCounter + 1
    local handle = self._widgetHandleCounter

    self._widgetRegistry[handle] = {
        widget = widget,
        refreshFunc = refreshFunc,
    }

    return handle
end

--- Unregister a widget from theme updates
--- @param handle number The handle returned from RegisterThemedWidget
function MedaUI:UnregisterThemedWidget(handle)
    self._widgetRegistry[handle] = nil
end

-- ============================================================================
-- Theme Access API
-- ============================================================================

--- Get the theme table
--- @return table The complete theme color table
function MedaUI:GetTheme()
    return self.Theme
end

--- Get a specific color from the theme
--- @param key string The color key (e.g., "gold", "background")
--- @return table|nil The color as {r, g, b, a} or nil if not found
function MedaUI:GetColor(key)
    return self.Theme[key]
end

--- Unpack a color for use with SetBackdropColor, etc.
--- @param key string The color key
--- @return number, number, number, number r, g, b, a values
function MedaUI:UnpackColor(key)
    local color = self.Theme[key]
    if color then
        return unpack(color)
    end
    return 1, 1, 1, 1  -- Default white
end

-- ============================================================================
-- Widget Creation API (populated by widget files)
-- ============================================================================

-- These methods are defined in the individual widget files:
-- MedaUI:CreateButton(parent, text, width, height)
-- MedaUI:CreateCheckbox(parent, label)
-- MedaUI:CreateRadio(parent, label)
-- MedaUI:CreateEditBox(parent, width, height)
-- MedaUI:CreateSlider(parent, width, min, max, step)
-- MedaUI:CreatePanel(name, width, height, title)
-- MedaUI:CreateMinimapButton(name, icon, onClick, onRightClick)

-- ============================================================================
-- Status Color Utilities
-- ============================================================================

--- Get a color based on value thresholds
--- @param value number The value to evaluate
--- @param thresholds table Array of {max, color} where color is a theme key or {r,g,b}
--- @return number, number, number RGB values
function MedaUI:GetStatusColor(value, thresholds)
    local Theme = self.Theme

    for _, threshold in ipairs(thresholds) do
        if not threshold.max or value <= threshold.max then
            local color = threshold.color
            if type(color) == "string" then
                -- Theme color key
                local themeColor = Theme[color]
                if themeColor then
                    return themeColor[1], themeColor[2], themeColor[3]
                end
            elseif type(color) == "table" then
                -- Direct RGB
                return color[1], color[2], color[3]
            end
        end
    end

    -- Default to text color
    return Theme.text[1], Theme.text[2], Theme.text[3]
end

--- Get FPS color (red < 30, orange < 60, green >= 60)
--- @param fps number Current FPS
--- @return number, number, number RGB values
function MedaUI:GetFPSColor(fps)
    return self:GetStatusColor(fps, {
        { max = 30, color = { 1, 0.3, 0.3 } },      -- Red
        { max = 60, color = { 1, 0.8, 0 } },        -- Orange
        { color = { 0.4, 0.9, 0.4 } },              -- Green
    })
end

--- Get latency color (green < 100, orange < 300, red >= 300)
--- @param latency number Latency in ms
--- @return number, number, number RGB values
function MedaUI:GetLatencyColor(latency)
    return self:GetStatusColor(latency, {
        { max = 100, color = { 0.4, 0.9, 0.4 } },   -- Green
        { max = 300, color = { 1, 0.8, 0 } },       -- Orange
        { color = { 1, 0.3, 0.3 } },                -- Red
    })
end

--- Get memory color based on percentage (green < 50, orange < 80, red >= 80)
--- @param percent number Memory percentage (0-100)
--- @return number, number, number RGB values
function MedaUI:GetMemoryColor(percent)
    return self:GetStatusColor(percent, {
        { max = 50, color = { 0.4, 0.9, 0.4 } },    -- Green
        { max = 80, color = { 1, 0.8, 0 } },        -- Orange
        { color = { 1, 0.3, 0.3 } },                -- Red
    })
end

--- Get combat status color
--- @param inCombat boolean Whether in combat
--- @return number, number, number RGB values
function MedaUI:GetCombatColor(inCombat)
    if inCombat then
        return 1, 0.3, 0.3  -- Red
    else
        return 0.4, 0.9, 0.4  -- Green
    end
end

-- ============================================================================
-- Utility Functions
-- ============================================================================

--- Create a standard backdrop table for themed frames
--- @param hasEdge boolean Whether to include an edge/border
--- @return table Backdrop configuration table
function MedaUI:CreateBackdrop(hasEdge)
    local backdrop = {
        bgFile = "Interface\\Buttons\\WHITE8x8",
    }
    if hasEdge then
        backdrop.edgeFile = "Interface\\Buttons\\WHITE8x8"
        backdrop.edgeSize = 1
        backdrop.insets = { left = 1, right = 1, top = 1, bottom = 1 }
    end
    return backdrop
end

--- Apply theme colors to a backdrop frame
--- @param frame Frame The frame with BackdropTemplate
--- @param bgKey string|nil Background color key (default: "background")
--- @param borderKey string|nil Border color key (default: "border")
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

-- ============================================================================
-- Media / Texture Registry
-- ============================================================================

-- Get addon name from WoW (first arg to every file)
local LOADED_BY_ADDON = ...

-- Dynamically determine the media path based on where MedaUI is loaded from
local TEXTURE_EXT = ".tga"
local MEDIA_PATH

do
    -- Try multiple path patterns to find the textures
    -- Pattern 1: Embedded as library (Interface/AddOns/AddonName/Libs/MedaUI/Media/)
    -- Pattern 2: Standalone addon (Interface/AddOns/MedaUI/Media/)

    if LOADED_BY_ADDON and LOADED_BY_ADDON ~= "MedaUI" then
        -- Loaded as embedded library - construct path based on loading addon
        MEDIA_PATH = "Interface\\AddOns\\" .. LOADED_BY_ADDON .. "\\Libs\\MedaUI\\Media\\"
    else
        -- Standalone installation or addon name is MedaUI
        MEDIA_PATH = "Interface\\AddOns\\MedaUI\\Media\\"
    end
end

-- Debug: Store path for inspection (can be viewed with /dump MedaUI._mediaPath)
MedaUI._mediaPath = MEDIA_PATH
MedaUI._loadedByAddon = LOADED_BY_ADDON

-- Texture registry organized by category
MedaUI.Media = MedaUI.Media or {
    -- Bar textures (256x32, horizontal status bars)
    bars = {
        {
            id = "solid",
            name = "Solid",
            description = "Clean solid bar with subtle depth",
            file = "bar-solid",
            source = "builtin",
        },
        {
            id = "blizzard",
            name = "Blizzard",
            description = "Default WoW status bar",
            path = "Interface\\TargetingFrame\\UI-StatusBar",
            source = "builtin",
        },
        {
            id = "flat",
            name = "Flat",
            description = "Flat single-colour fill with no texture",
            path = "Interface\\Buttons\\WHITE8x8",
            source = "builtin",
        },
        {
            id = "raid",
            name = "Raid",
            description = "Compact bar used in raid frames",
            path = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill",
            source = "builtin",
        },
        {
            id = "spark",
            name = "Spark",
            description = "Glowing ember-like bar texture",
            path = "Interface\\CastingBar\\UI-CastingBar-Spark",
            source = "builtin",
        },
        {
            id = "shiny",
            name = "Shiny",
            description = "Bright metallic sheen",
            path = "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar",
            source = "builtin",
        },
        {
            id = "smooth",
            name = "Smooth",
            description = "Subtle smooth gradient",
            path = "Interface\\TargetingFrame\\UI-TargetingFrame-BarFill",
            source = "builtin",
        },
    },

    -- Orb textures (64x64, circular for mana/health orbs)
    orbs = {
        {
            id = "solid",
            name = "Solid",
            description = "Clean simple orb with solid fill",
            mask = "orb-classic-mask",
            ring = "orb-classic-ring",
            source = "builtin",
        },
        {
            id = "glow",
            name = "Glow",
            description = "Soft outer glow effect",
            mask = "orb-glow-mask",
            ring = "orb-glow-ring",
            source = "builtin",
        },
        {
            id = "glass",
            name = "Glass",
            description = "Glossy glass-like with highlight",
            mask = "orb-glass-mask",
            ring = "orb-glass-ring",
            source = "builtin",
        },
    },
}

--- Register a custom bar texture from another addon
--- @param id string Unique texture id
--- @param name string Display name
--- @param path string Full WoW texture path (e.g., "Interface\\AddOns\\MyAddon\\bar")
--- @param description string|nil Optional description
function MedaUI:RegisterBarTexture(id, name, path, description)
    if not id or not name or not path then return end
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

--- Register a custom orb texture from another addon
--- @param id string Unique texture id
--- @param name string Display name
--- @param maskPath string Full WoW path to the mask texture
--- @param ringPath string Full WoW path to the ring texture
--- @param description string|nil Optional description
function MedaUI:RegisterOrbTexture(id, name, maskPath, ringPath, description)
    if not id or not name or not maskPath or not ringPath then return end
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

--- Get the full texture path for a media file
--- @param category string The media category (e.g., "bars")
--- @param id string The texture id within the category
--- @return string|nil The full texture path, or nil if not found
function MedaUI:GetMediaPath(category, id)
    local categoryData = self.Media[category]
    if not categoryData then return nil end

    for _, entry in ipairs(categoryData) do
        if entry.id == id then
            if entry.path then return entry.path end
            return MEDIA_PATH .. entry.file .. TEXTURE_EXT
        end
    end
    return nil
end

--- Get a bar texture path by id
--- @param id string The bar texture id (e.g., "glass", "frosted")
--- @return string The full texture path (defaults to "solid" if not found)
function MedaUI:GetBarTexture(id)
    return self:GetMediaPath("bars", id) or (MEDIA_PATH .. "bar-solid" .. TEXTURE_EXT)
end

--- Get list of available textures in a category, sorted by source then name.
--- @param category string The media category (e.g., "bars")
--- @return table Array of {id, name, description, source} for each texture
function MedaUI:GetMediaList(category)
    local categoryData = self.Media[category]
    if not categoryData then return {} end

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

local SOURCE_ORDER = { builtin = 1, custom = 2, lsm = 3 }

local function SortBySourceThenName(a, b)
    local oa = SOURCE_ORDER[a.source] or 99
    local ob = SOURCE_ORDER[b.source] or 99
    if oa ~= ob then return oa < ob end
    return a.name:lower() < b.name:lower()
end

--- Get list of available bar textures, including LibSharedMedia statusbar
--- textures when the library is installed. Sorted by source group (Built-in,
--- Custom, LibSharedMedia) then alphabetically within each group.
--- @return table Array of {id, name, description, source} for each bar texture
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

    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM then
        local lsmBars = LSM:HashTable("statusbar")
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

--- Get orb texture paths by id (returns both mask and ring)
--- @param id string The orb texture id (e.g., "glass", "frosted")
--- @return string, string The mask path and ring path (defaults to "classic" if not found)
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

--- Get list of available fonts, including LibSharedMedia fonts when installed.
--- Sorted alphabetically with "Default (Game Font)" always first.
--- Each entry has {value, label, path} suitable for CreateDropdown with "font" textureMode.
--- @return table Array of {value, label, path}
function MedaUI:GetFontList()
    local seen = {}
    local fonts = {}

    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM then
        local lsmFonts = LSM:HashTable("font")
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
            { value = "Fonts\\FRIZQT__.TTF",  label = "Friz Quadrata",  path = "Fonts\\FRIZQT__.TTF" },
            { value = "Fonts\\ARIALN.TTF",    label = "Arial Narrow",   path = "Fonts\\ARIALN.TTF" },
            { value = "Fonts\\MORPHEUS.TTF",  label = "Morpheus",       path = "Fonts\\MORPHEUS.TTF" },
            { value = "Fonts\\skurri.TTF",    label = "Skurri",         path = "Fonts\\skurri.TTF" },
        }
        for _, f in ipairs(builtins) do
            if not seen[f.value] then
                fonts[#fonts + 1] = f
                seen[f.value] = true
            end
        end
    end

    table.sort(fonts, function(a, b) return a.label:lower() < b.label:lower() end)

    local list = { { value = "default", label = "Default (Game Font)", path = nil } }
    for _, f in ipairs(fonts) do
        list[#list + 1] = f
    end
    return list
end

--- Resolve a font value from GetFontList to a usable font path.
--- @param value string The font value (path or "default")
--- @return string|nil The font file path, or nil for the game default
function MedaUI:GetFontPath(value)
    if not value or value == "default" then return nil end
    return value
end

--- Get list of available sounds, including LibSharedMedia sounds when installed.
--- Sorted alphabetically with "None" always first.
--- Each entry has {value, label} suitable for CreateDropdown.
--- @return table Array of {value, label}
function MedaUI:GetSoundList()
    local seen = {}
    local sounds = {}

    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM then
        local lsmSounds = LSM:HashTable("sound")
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
            { value = "Sound\\Interface\\RaidWarning.ogg", label = "Raid Warning" },
            { value = "Sound\\Interface\\ReadyCheck.ogg", label = "Ready Check" },
            { value = "Sound\\Interface\\AlarmClockWarning3.ogg", label = "Alarm Clock" },
            { value = "Sound\\Interface\\levelup2.ogg", label = "Level Up" },
        }
        for _, s in ipairs(builtins) do
            if not seen[s.value] then
                sounds[#sounds + 1] = s
                seen[s.value] = true
            end
        end
    end

    table.sort(sounds, function(a, b) return a.label:lower() < b.label:lower() end)

    local list = { { value = "none", label = "None (silent)" } }
    for _, s in ipairs(sounds) do
        list[#list + 1] = s
    end
    return list
end

--- Resolve a sound value from GetSoundList to a playable path.
--- @param value string The sound value (path or "none")
--- @return string|nil The sound file path, or nil for no sound
function MedaUI:GetSoundPath(value)
    if not value or value == "none" then return nil end
    return value
end

--- Get list of available orb textures (convenience method)
--- @return table Array of {id, name, description} for each orb texture
function MedaUI:GetOrbTextureList()
    local categoryData = self.Media.orbs
    if not categoryData then return {} end

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
