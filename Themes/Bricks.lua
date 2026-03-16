--[[
    MedaUI Bricks Theme
    Windows Mica-inspired dark theme with blue/purple accents
]]

local MedaUI = LibStub("MedaUI-2.0")

MedaUI:RegisterTheme("bricks", {
    -- Font Size Hierarchy
    fontSize = {
        xs = 10,
        sm = 11,
        md = 13,
        lg = 14,
        xl = 15,
    },

    -- Spacing System
    spacing = {
        xs = 4,
        sm = 8,
        md = 12,
        lg = 16,
        xl = 24,
    },

    -- Gradient Colors (blue-based, subtle)
    titleGradientStart = { 0.38, 0.53, 0.87, 0.45 },
    titleGradientEnd = { 0.53, 0.67, 0.95, 0.12 },
    sectionGradientStart = { 0.38, 0.53, 0.87, 0.45 },
    sectionGradientEnd = { 0.38, 0.53, 0.87, 0.04 },

    -- Backgrounds (soft slate-blue)
    background = { 0.13, 0.14, 0.17, 0.985 },
    backgroundLight = { 0.165, 0.175, 0.205, 1 },
    backgroundDark = { 0.11, 0.12, 0.145, 1 },

    -- Borders (white at low alpha)
    border = { 1, 1, 1, 0.05 },
    borderLight = { 1, 1, 1, 0.09 },

    -- Blue accent colors (replacing gold)
    gold = { 0.38, 0.53, 0.87, 1 },
    goldBright = { 0.53, 0.67, 0.95, 1 },
    goldDim = { 0.27, 0.38, 0.65, 1 },
    accent = { 0.38, 0.53, 0.87, 1 },

    -- Text colors
    text = { 1, 1, 1, 0.88 },
    textDim = { 1, 1, 1, 0.45 },
    textDisabled = { 1, 1, 1, 0.25 },
    textGreen = { 0.45, 0.85, 0.55, 1 },

    -- Interactive elements
    button = { 1, 1, 1, 0.05 },
    buttonHover = { 1, 1, 1, 0.08 },
    buttonDisabled = { 1, 1, 1, 0.03 },
    input = { 1, 1, 1, 0.045 },

    -- Tabs
    tabActive = { 1, 1, 1, 0.05 },
    tabInactive = { 1, 1, 1, 0.018 },
    tabHover = { 1, 1, 1, 0.05 },
    tabBadge = { 0.38, 0.53, 0.87, 0.45 },

    -- Table rows
    rowEven = { 1, 1, 1, 0.03 },
    rowOdd = { 1, 1, 1, 0.015 },
    rowHeader = { 1, 1, 1, 0.05 },
    rowSubheader = { 1, 1, 1, 0.035 },

    -- Highlights (blue-tinted)
    highlight = { 0.38, 0.53, 0.87, 0.08 },

    -- Code/monospace styling
    codeBackground = { 0, 0, 0, 0.3 },
    codeBorder = { 1, 1, 1, 0.06 },
    codeLineNumber = { 1, 1, 1, 0.25 },
    codeHighlight = { 0.38, 0.53, 0.87, 0.1 },
    codeKeyword = { 0.53, 0.67, 0.95, 1 },
    codeLiteral = { 0.72, 0.78, 0.97, 1 },
    codeComment = { 0.45, 0.72, 0.55, 1 },
    codeString = { 0.90, 0.63, 0.35, 1 },
    codeNumber = { 0.48, 0.82, 1.0, 1 },
    codeFunction = { 0.84, 0.87, 0.98, 1 },

    -- Tree styling
    treeIndent = 16,
    treeExpandIcon = { 1, 1, 1, 0.35 },

    -- Dropdown styling
    dropdownArrow = { 1, 1, 1, 0.4 },
    dropdownHover = { 1, 1, 1, 0.04 },

    -- Context menu
    menuBackground = { 0.14, 0.15, 0.18, 0.99 },
    menuHover = { 1, 1, 1, 0.06 },
    menuSeparator = { 1, 1, 1, 0.07 },

    -- Message levels
    levelDebug = { 1, 1, 1, 0.4 },
    levelInfo = { 1, 1, 1, 0.88 },
    levelWarn = { 1, 0.75, 0.25, 1 },
    levelError = { 1, 0.40, 0.40, 1 },

    -- Misc
    closeHover = { 1, 0.45, 0.45, 1 },
    resizeHandle = { 1, 1, 1, 0.15 },

    -- Slider
    sliderFill = { 0.38, 0.53, 0.87, 0.68 },
    sliderTrack = { 1, 1, 1, 0.06 },
    sliderThumb = { 0.80, 0.84, 0.92, 0.92 },
    sliderThumbHover = { 0.93, 0.96, 1, 1 },

    -- Toggle
    toggleOn = { 0.38, 0.53, 0.87, 0.72 },
    toggleOff = { 1, 1, 1, 0.08 },
    toggleKnob = { 1, 1, 1, 0.82 },
    toggleKnobOn = { 1, 1, 1, 1 },

    -- Primary button
    buttonPrimary = { 0.18, 0.21, 0.27, 1 },
    buttonPrimaryHover = { 0.22, 0.25, 0.31, 1 },
    buttonPrimaryText = { 1, 1, 1, 1 },

    -- Panel chrome
    panelGlow = { 0.38, 0.53, 0.87, 0.04 },
    textSection = { 1, 1, 1, 0.35 },

    -- Checkbox
    checkboxBg = { 1, 1, 1, 0.055 },
    checkboxBorder = { 1, 1, 1, 0.15 },
    checkboxBgHover = { 1, 1, 1, 0.08 },
    checkboxBorderHover = { 1, 1, 1, 0.25 },
    checkboxBgChecked = { 0.38, 0.53, 0.87, 0.85 },
    checkboxBorderChecked = { 0.38, 0.53, 0.87, 1 },
    checkboxMark = { 1, 1, 1, 1 },

    -- Semantic UI colors
    divider = { 1, 1, 1, 0.07 },
    hoverSubtle = { 1, 1, 1, 0.024 },
    selectedSubtle = { 1, 1, 1, 0.042 },
    success = { 0.35, 0.82, 0.45, 1 },
    warning = { 1.0, 0.65, 0.15, 1 },
    error = { 1, 0.40, 0.40, 1 },
}, {
    displayName = "Bricks (Blue)",
    description = "Windows Mica-inspired dark theme with blue accents",
})
