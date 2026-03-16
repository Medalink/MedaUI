--[[
    MedaUI Default Theme
    Dark Grey + Gold - Modern Material UI inspired theme
]]

local MedaUI = LibStub("MedaUI-2.0")

MedaUI:RegisterTheme("default", {
    -- Font Size Hierarchy
    fontSize = {
        xs = 10,      -- Small labels, hints
        sm = 11,      -- Secondary text, descriptions
        md = 12,      -- Body text, widget labels (default)
        lg = 14,      -- Section headers
        xl = 16,      -- Panel titles
    },

    -- Spacing System
    spacing = {
        xs = 4,
        sm = 8,
        md = 12,
        lg = 16,
        xl = 24,
    },

    -- Gradient Colors
    titleGradientStart = { 0.9, 0.7, 0.15, 1 },
    titleGradientEnd = { 1.0, 0.85, 0.3, 1 },
    sectionGradientStart = { 0.9, 0.7, 0.15, 0.8 },
    sectionGradientEnd = { 0.9, 0.7, 0.15, 0.1 },

    -- Backgrounds
    background = { 0.11, 0.11, 0.12, 0.97 },
    backgroundLight = { 0.16, 0.16, 0.17, 1 },
    backgroundDark = { 0.09, 0.09, 0.1, 1 },

    -- Borders
    border = { 0.2, 0.2, 0.21, 0.6 },
    borderLight = { 0.25, 0.25, 0.26, 0.4 },

    -- Gold accent colors
    gold = { 0.9, 0.7, 0.15, 1 },
    goldBright = { 1, 0.78, 0.2, 1 },
    goldDim = { 0.7, 0.55, 0.1, 1 },
    accent = { 0.9, 0.7, 0.15, 1 },  -- Primary accent (same as gold)

    -- Text colors
    text = { 0.9, 0.9, 0.9, 1 },
    textDim = { 0.55, 0.55, 0.55, 1 },
    textDisabled = { 0.35, 0.35, 0.35, 1 },
    textGreen = { 0.4, 0.9, 0.4, 1 },

    -- Interactive elements
    button = { 0.16, 0.16, 0.17, 1 },
    buttonHover = { 0.22, 0.22, 0.23, 1 },
    buttonDisabled = { 0.1, 0.1, 0.11, 1 },
    input = { 0.13, 0.13, 0.14, 1 },

    -- Tabs
    tabActive = { 0.18, 0.18, 0.19, 1 },
    tabInactive = { 0.13, 0.13, 0.14, 1 },
    tabHover = { 0.22, 0.22, 0.23, 1 },
    tabBadge = { 0.8, 0.2, 0.2, 1 },

    -- Table rows
    rowEven = { 0.12, 0.12, 0.13, 1 },
    rowOdd = { 0.1, 0.1, 0.11, 1 },
    rowHeader = { 0.16, 0.16, 0.17, 1 },
    rowSubheader = { 0.13, 0.13, 0.14, 1 },

    -- Highlights
    highlight = { 0.9, 0.7, 0.15, 0.15 },

    -- Code/monospace styling
    codeBackground = { 0.08, 0.08, 0.09, 1 },
    codeBorder = { 0.25, 0.25, 0.26, 1 },
    codeLineNumber = { 0.4, 0.4, 0.4, 1 },
    codeHighlight = { 0.3, 0.3, 0.1, 1 },
    codeKeyword = { 0.93, 0.76, 0.28, 1 },
    codeLiteral = { 0.88, 0.68, 0.28, 1 },
    codeComment = { 0.42, 0.68, 0.44, 1 },
    codeString = { 0.86, 0.58, 0.32, 1 },
    codeNumber = { 0.42, 0.76, 1.0, 1 },
    codeFunction = { 0.82, 0.86, 1.0, 1 },

    -- Tree styling
    treeIndent = 16,
    treeExpandIcon = { 0.6, 0.6, 0.6, 1 },

    -- Dropdown styling
    dropdownArrow = { 0.6, 0.6, 0.6, 1 },
    dropdownHover = { 0.22, 0.22, 0.23, 1 },

    -- Context menu
    menuBackground = { 0.12, 0.12, 0.13, 0.98 },
    menuHover = { 0.22, 0.22, 0.23, 1 },
    menuSeparator = { 0.25, 0.25, 0.26, 1 },

    -- Message levels (for debug output)
    levelDebug = { 0.5, 0.5, 0.5, 1 },
    levelInfo = { 0.9, 0.9, 0.9, 1 },
    levelWarn = { 1, 0.8, 0, 1 },
    levelError = { 1, 0.3, 0.3, 1 },

    -- Misc
    closeHover = { 1, 0.4, 0.4, 1 },
    resizeHandle = { 0.3, 0.3, 0.3, 0.5 },

    -- Slider
    sliderFill = { 0.9, 0.7, 0.15, 0.75 },
    sliderTrack = { 1, 1, 1, 0.16 },
    sliderThumb = { 0.9, 0.7, 0.15, 1 },
    sliderThumbHover = { 1, 0.78, 0.2, 1 },

    -- Toggle
    toggleOn = { 0.9, 0.7, 0.15, 0.75 },
    toggleOff = { 0.267, 0.267, 0.267, 0.65 },
    toggleKnob = { 1, 1, 1, 0.5 },
    toggleKnobOn = { 1, 1, 1, 1 },

    -- Primary button
    buttonPrimary = { 0.9, 0.7, 0.15, 1 },
    buttonPrimaryHover = { 1, 0.78, 0.2, 1 },
    buttonPrimaryText = { 1, 1, 1, 1 },

    -- Panel chrome
    panelGlow = { 0.9, 0.7, 0.15, 0.12 },
    textSection = { 1, 1, 1, 0.41 },

    -- Checkbox
    checkboxBg = { 1, 1, 1, 0.06 },
    checkboxBorder = { 1, 1, 1, 0.15 },
    checkboxBgHover = { 1, 1, 1, 0.08 },
    checkboxBorderHover = { 1, 1, 1, 0.25 },
    checkboxBgChecked = { 0.9, 0.7, 0.15, 1 },
    checkboxBorderChecked = { 0.9, 0.7, 0.15, 1 },
    checkboxMark = { 1, 1, 1, 1 },

    -- Semantic UI colors
    divider = { 1, 1, 1, 0.06 },
    hoverSubtle = { 1, 1, 1, 0.012 },
    selectedSubtle = { 1, 1, 1, 0.024 },
    success = { 0.3, 0.85, 0.3, 1 },
    warning = { 1.0, 0.6, 0.0, 1 },
    error = { 1, 0.3, 0.3, 1 },
}, {
    displayName = "Default (Gold)",
    description = "Dark grey with gold accents",
})
