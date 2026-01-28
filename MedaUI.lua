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
