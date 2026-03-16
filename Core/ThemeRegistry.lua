local MedaUI = LibStub("MedaUI-2.0")

MedaUI.themes = MedaUI.themes or {}
MedaUI.activeThemeName = MedaUI.activeThemeName or nil

local function EnsureWeakValueTable(tbl)
    local meta = getmetatable(tbl)
    if not meta then
        setmetatable(tbl, { __mode = "v" })
    elseif meta.__mode ~= "v" then
        meta.__mode = "v"
    end
    return tbl
end

local function EnsureWeakKeyTable(tbl)
    local meta = getmetatable(tbl)
    if not meta then
        setmetatable(tbl, { __mode = "k" })
    elseif meta.__mode ~= "k" then
        meta.__mode = "k"
    end
    return tbl
end

MedaUI._widgetRegistry = MedaUI._widgetRegistry or {}
MedaUI._widgetByHandle = EnsureWeakValueTable(MedaUI._widgetByHandle or {})
MedaUI._widgetHandlesByWidget = EnsureWeakKeyTable(MedaUI._widgetHandlesByWidget or {})
MedaUI._widgetHandleCounter = MedaUI._widgetHandleCounter or 0
MedaUI.callbacks = MedaUI.callbacks or LibStub("CallbackHandler-1.0"):New(MedaUI)
MedaUI.Theme = MedaUI.Theme or {}

local function TrackWidgetHandle(self, widget, handle)
    if not widget or not handle then
        return
    end

    local handles = self._widgetHandlesByWidget[widget]
    if not handles then
        handles = {}
        self._widgetHandlesByWidget[widget] = handles
    end

    handles[handle] = true
end

local function UntrackWidgetHandle(self, widget, handle)
    if not widget or not handle then
        return
    end

    local handles = self._widgetHandlesByWidget[widget]
    if not handles then
        return
    end

    handles[handle] = nil
    if not next(handles) then
        self._widgetHandlesByWidget[widget] = nil
    end
end

local function ReleaseThemedWidgetTree(self, widget)
    if not widget then
        return
    end

    self:ReleaseThemedWidget(widget)

    if type(widget.GetChildren) == "function" then
        local children = { widget:GetChildren() }
        for _, child in ipairs(children) do
            ReleaseThemedWidgetTree(self, child)
        end
    end

    if type(widget.GetRegions) == "function" then
        local regions = { widget:GetRegions() }
        for _, region in ipairs(regions) do
            self:ReleaseThemedWidget(region)
        end
    end
end

function MedaUI:RegisterTheme(name, colors, metadata)
    metadata = metadata or {}
    self.themes[name] = {
        name = name,
        colors = colors,
        displayName = metadata.displayName or name,
        description = metadata.description or "",
    }

    if not self.activeThemeName then
        self:SetTheme(name)
    end
end

function MedaUI:SetTheme(name)
    local themeData = self.themes[name]
    if not themeData then
        return false
    end

    local previousTheme = self.activeThemeName
    self.activeThemeName = name

    wipe(self.Theme)
    for key, value in pairs(themeData.colors) do
        self.Theme[key] = value
    end

    for handle, refreshFunc in pairs(self._widgetRegistry) do
        local widget = self._widgetByHandle[handle]
        if widget then
            pcall(refreshFunc, widget)
        else
            self._widgetRegistry[handle] = nil
        end
    end

    self.callbacks:Fire("THEME_CHANGED", name, previousTheme)
    return true
end

function MedaUI:GetActiveThemeName()
    return self.activeThemeName
end

function MedaUI:GetAvailableThemes()
    local themes = {}
    for name, data in pairs(self.themes) do
        themes[#themes + 1] = {
            name = data.name,
            displayName = data.displayName,
            description = data.description,
        }
    end

    table.sort(themes, function(a, b)
        return a.displayName < b.displayName
    end)
    return themes
end

function MedaUI:RegisterThemedWidget(widget, refreshFunc)
    if not widget or type(refreshFunc) ~= "function" then
        return nil
    end

    local oldHandle = widget._themeHandle
    if oldHandle then
        self:UnregisterThemedWidget(oldHandle)
    end

    self._widgetHandleCounter = self._widgetHandleCounter + 1
    local handle = self._widgetHandleCounter

    self._widgetRegistry[handle] = refreshFunc
    self._widgetByHandle[handle] = widget
    TrackWidgetHandle(self, widget, handle)
    widget._themeHandle = handle
    return handle
end

function MedaUI:UnregisterThemedWidget(handle)
    if not self._widgetRegistry[handle] then
        return
    end

    local widget = self._widgetByHandle[handle]
    UntrackWidgetHandle(self, widget, handle)
    if widget and widget._themeHandle == handle then
        widget._themeHandle = nil
    end

    self._widgetRegistry[handle] = nil
    self._widgetByHandle[handle] = nil
end

function MedaUI:ReleaseThemedWidget(widget)
    if not widget then
        return
    end

    local handles = self._widgetHandlesByWidget[widget]
    if not handles then
        return
    end

    local pending = {}
    for handle in pairs(handles) do
        pending[#pending + 1] = handle
    end

    for _, handle in ipairs(pending) do
        self:UnregisterThemedWidget(handle)
    end
end

function MedaUI:ReleaseThemedWidgetTree(widget)
    ReleaseThemedWidgetTree(self, widget)
end

function MedaUI:GetTheme()
    return self.Theme
end

function MedaUI:GetColor(key)
    return self.Theme[key]
end

function MedaUI:UnpackColor(key)
    local color = self.Theme[key]
    if color then
        return unpack(color)
    end
    return 1, 1, 1, 1
end
