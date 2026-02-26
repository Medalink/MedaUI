--[[
    MedaUI Bricks Theme
    Windows Mica-inspired dark theme with blue/purple accents
]]

local MedaUI = LibStub("MedaUI-1.0")

MedaUI:RegisterTheme("bricks", {
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

    -- Gradient Colors (blue-based for this theme)
    titleGradientStart = { 0.38, 0.53, 0.87, 1 },
    titleGradientEnd = { 0.53, 0.67, 0.95, 1 },
    sectionGradientStart = { 0.38, 0.53, 0.87, 0.8 },
    sectionGradientEnd = { 0.38, 0.53, 0.87, 0.1 },

    -- Backgrounds (cool-tinted darks)
    background = { 0.11, 0.11, 0.14, 0.97 },      -- #1C1C24
    backgroundLight = { 0.15, 0.15, 0.19, 1 },    -- #262630
    backgroundDark = { 0.07, 0.07, 0.10, 1 },     -- #121219

    -- Borders (subtle blue-tinted)
    border = { 0.22, 0.22, 0.28, 0.6 },
    borderLight = { 0.28, 0.28, 0.35, 0.4 },

    -- Blue accent colors (replacing gold)
    gold = { 0.38, 0.53, 0.87, 1 },               -- #6187DE primary
    goldBright = { 0.53, 0.67, 0.95, 1 },         -- #87ABF2 hover/bright
    goldDim = { 0.27, 0.38, 0.65, 1 },            -- #4560A6 muted
    accent = { 0.38, 0.53, 0.87, 1 },             -- Primary accent (same as gold)

    -- Text colors (high contrast)
    text = { 0.95, 0.95, 0.97, 1 },               -- #F2F2F7
    textDim = { 0.60, 0.60, 0.65, 1 },            -- #9999A6
    textDisabled = { 0.40, 0.40, 0.45, 1 },
    textGreen = { 0.45, 0.85, 0.55, 1 },

    -- Interactive elements
    button = { 0.14, 0.14, 0.18, 1 },
    buttonHover = { 0.20, 0.20, 0.26, 1 },
    buttonDisabled = { 0.10, 0.10, 0.13, 1 },
    input = { 0.12, 0.12, 0.16, 1 },

    -- Tabs
    tabActive = { 0.16, 0.16, 0.21, 1 },
    tabInactive = { 0.12, 0.12, 0.16, 1 },
    tabHover = { 0.20, 0.20, 0.26, 1 },
    tabBadge = { 0.75, 0.30, 0.35, 1 },           -- Slightly muted red

    -- Table rows
    rowEven = { 0.11, 0.11, 0.15, 1 },
    rowOdd = { 0.09, 0.09, 0.12, 1 },
    rowHeader = { 0.14, 0.14, 0.18, 1 },
    rowSubheader = { 0.12, 0.12, 0.16, 1 },

    -- Highlights (blue-tinted)
    highlight = { 0.38, 0.53, 0.87, 0.15 },

    -- Code/monospace styling
    codeBackground = { 0.06, 0.06, 0.09, 1 },
    codeBorder = { 0.28, 0.28, 0.35, 1 },
    codeLineNumber = { 0.45, 0.45, 0.52, 1 },
    codeHighlight = { 0.25, 0.30, 0.45, 1 },

    -- Tree styling
    treeIndent = 16,
    treeExpandIcon = { 0.55, 0.55, 0.62, 1 },

    -- Dropdown styling
    dropdownArrow = { 0.55, 0.55, 0.62, 1 },
    dropdownHover = { 0.20, 0.20, 0.26, 1 },

    -- Context menu
    menuBackground = { 0.10, 0.10, 0.14, 0.98 },
    menuHover = { 0.20, 0.20, 0.26, 1 },
    menuSeparator = { 0.28, 0.28, 0.35, 1 },

    -- Message levels (for debug output)
    levelDebug = { 0.50, 0.50, 0.55, 1 },
    levelInfo = { 0.95, 0.95, 0.97, 1 },
    levelWarn = { 1, 0.75, 0.25, 1 },
    levelError = { 1, 0.40, 0.40, 1 },

    -- Misc
    closeHover = { 1, 0.45, 0.45, 1 },
    resizeHandle = { 0.35, 0.35, 0.42, 0.5 },
}, {
    displayName = "Bricks (Blue)",
    description = "Windows Mica-inspired dark theme with blue accents",
})
