--[[
    MedaUI ThemeSelector Widget
    Dropdown-based theme selector with optional preview swatch
]]

local MedaUI = LibStub("MedaUI-1.0")

--- Create a theme selector dropdown
--- @param parent Frame Parent frame
--- @param width number Dropdown width
--- @param config table|nil Configuration {showPreview: bool, onChange: func}
--- @return Frame The theme selector container
function MedaUI:CreateThemeSelector(parent, width, config)
    config = config or {}
    local showPreview = config.showPreview ~= false
    local onChange = config.onChange

    local container = CreateFrame("Frame", nil, parent)

    -- Calculate container size based on preview option
    local previewWidth = showPreview and 28 or 0
    local previewSpacing = showPreview and 8 or 0
    local dropdownWidth = width - previewWidth - previewSpacing

    container:SetSize(width, 24)

    -- Preview swatch (shows accent color of current theme)
    local previewSwatch
    if showPreview then
        previewSwatch = CreateFrame("Frame", nil, container, "BackdropTemplate")
        previewSwatch:SetSize(24, 24)
        previewSwatch:SetPoint("LEFT", 0, 0)
        previewSwatch:SetBackdrop(self:CreateBackdrop(true))
        previewSwatch:SetBackdropBorderColor(unpack(MedaUI.Theme.border))

        -- Inner color texture
        previewSwatch.colorTex = previewSwatch:CreateTexture(nil, "OVERLAY")
        previewSwatch.colorTex:SetPoint("TOPLEFT", 2, -2)
        previewSwatch.colorTex:SetPoint("BOTTOMRIGHT", -2, 2)

        container.previewSwatch = previewSwatch
    end

    -- Build options from available themes
    local function BuildOptions()
        local themes = MedaUI:GetAvailableThemes()
        local options = {}
        for _, theme in ipairs(themes) do
            options[#options + 1] = {
                value = theme.name,
                label = theme.displayName,
            }
        end
        return options
    end

    -- Create dropdown
    local dropdown = self:CreateDropdown(container, dropdownWidth, BuildOptions())
    if showPreview then
        dropdown:SetPoint("LEFT", previewSwatch, "RIGHT", previewSpacing, 0)
    else
        dropdown:SetPoint("LEFT", 0, 0)
    end

    container.dropdown = dropdown

    -- Update preview swatch color
    local function UpdatePreview()
        if previewSwatch then
            local Theme = MedaUI.Theme
            previewSwatch.colorTex:SetColorTexture(unpack(Theme.gold))
            previewSwatch:SetBackdropBorderColor(unpack(Theme.border))
        end
    end

    -- Set initial selection to current theme
    local currentTheme = MedaUI:GetActiveThemeName()
    if currentTheme then
        dropdown:SetSelected(currentTheme)
    end
    UpdatePreview()

    -- Handle dropdown selection
    dropdown.OnValueChanged = function(self, value, label)
        MedaUI:SetTheme(value)
        UpdatePreview()
        if onChange then
            onChange(value)
        end
    end

    -- Register for external theme changes
    local function OnThemeChanged(callback, newTheme, oldTheme)
        -- Update dropdown selection if theme was changed externally
        if dropdown:GetSelected() ~= newTheme then
            dropdown:SetSelected(newTheme)
        end
        UpdatePreview()
    end

    MedaUI.RegisterCallback(container, "THEME_CHANGED", OnThemeChanged)

    -- API methods
    --- Get the currently selected theme
    --- @return string The selected theme name
    function container:GetSelected()
        return self.dropdown:GetSelected()
    end

    --- Set the selected theme (also switches the active theme)
    --- @param themeName string The theme name to select
    function container:SetSelected(themeName)
        self.dropdown:SetSelected(themeName)
        MedaUI:SetTheme(themeName)
    end

    --- Refresh the dropdown options (call after registering new themes)
    function container:RefreshOptions()
        self.dropdown:SetOptions(BuildOptions())
        local currentTheme = MedaUI:GetActiveThemeName()
        if currentTheme then
            self.dropdown:SetSelected(currentTheme)
        end
    end

    --- Enable or disable the selector
    --- @param enabled boolean Whether selector is enabled
    function container:SetEnabled(enabled)
        self.dropdown:SetEnabled(enabled)
    end

    return container
end
