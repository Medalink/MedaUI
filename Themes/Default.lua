--[[
    MedaUI Default Theme
    Dark Grey + Gold - Modern Material UI inspired theme
]]

local MedaUI = LibStub("MedaUI-1.0")

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
}, {
    displayName = "Default (Gold)",
    description = "Dark grey with gold accents",
})
