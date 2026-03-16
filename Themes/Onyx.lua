--[[
    MedaUI Onyx Theme
    Ultra-dark neutral palette with cool gray accents
]]

local MedaUI = LibStub("MedaUI-2.0")

MedaUI:RegisterTheme("onyx", {
    -- Font Size Hierarchy
    fontSize = {
        xs = 11,
        sm = 12,
        md = 14,
        lg = 15,
        xl = 16,
    },

    -- Spacing System
    spacing = {
        xs = 4,
        sm = 8,
        md = 12,
        lg = 16,
        xl = 24,
    },

    -- Gradient Colors (muted silver)
    titleGradientStart = { 0.78, 0.80, 0.84, 0.20 },
    titleGradientEnd = { 0.52, 0.55, 0.60, 0.06 },
    sectionGradientStart = { 0.72, 0.74, 0.79, 0.18 },
    sectionGradientEnd = { 0.72, 0.74, 0.79, 0.03 },

    -- Backgrounds
    background = { 0.11, 0.11, 0.12, 0.99 },
    backgroundLight = { 0.14, 0.14, 0.155, 1 },
    backgroundDark = { 0.085, 0.085, 0.095, 1 },

    -- Borders
    border = { 1, 1, 1, 0.06 },
    borderLight = { 1, 1, 1, 0.10 },

    -- Accent colors (neutral silver replaces gold)
    gold = { 0.78, 0.80, 0.84, 1 },
    goldBright = { 0.90, 0.92, 0.96, 1 },
    goldDim = { 0.48, 0.50, 0.55, 1 },
    accent = { 0.70, 0.73, 0.78, 1 },

    -- Text colors
    text = { 1, 1, 1, 0.97 },
    textDim = { 1, 1, 1, 0.82 },
    textDisabled = { 1, 1, 1, 0.36 },
    textGreen = { 0.45, 0.85, 0.55, 1 },

    -- Interactive elements
    button = { 1, 1, 1, 0.026 },
    buttonHover = { 1, 1, 1, 0.048 },
    buttonDisabled = { 1, 1, 1, 0.015 },
    input = { 1, 1, 1, 0.02 },

    -- Tabs
    tabActive = { 1, 1, 1, 0.02 },
    tabInactive = { 0, 0, 0, 0 },
    tabHover = { 1, 1, 1, 0.028 },
    tabBadge = { 0.80, 0.82, 0.86, 0.34 },

    -- Table rows
    rowEven = { 1, 1, 1, 0.012 },
    rowOdd = { 0, 0, 0, 0 },
    rowHeader = { 1, 1, 1, 0.022 },
    rowSubheader = { 1, 1, 1, 0.018 },

    -- Highlights
    highlight = { 0.78, 0.80, 0.84, 0.07 },

    -- Code/monospace styling
    codeBackground = { 0, 0, 0, 0.22 },
    codeBorder = { 1, 1, 1, 0.05 },
    codeLineNumber = { 1, 1, 1, 0.22 },
    codeHighlight = { 0.78, 0.80, 0.84, 0.08 },
    codeKeyword = { 0.82, 0.84, 0.90, 1 },
    codeLiteral = { 0.78, 0.82, 0.94, 1 },
    codeComment = { 0.50, 0.72, 0.55, 1 },
    codeString = { 0.88, 0.64, 0.38, 1 },
    codeNumber = { 0.52, 0.80, 1.0, 1 },
    codeFunction = { 0.84, 0.87, 0.96, 1 },

    -- Tree styling
    treeIndent = 16,
    treeExpandIcon = { 1, 1, 1, 0.32 },

    -- Dropdown styling
    dropdownArrow = { 1, 1, 1, 0.36 },
    dropdownHover = { 1, 1, 1, 0.03 },

    -- Context menu
    menuBackground = { 0.09, 0.09, 0.10, 0.995 },
    menuHover = { 1, 1, 1, 0.032 },
    menuSeparator = { 1, 1, 1, 0.05 },

    -- Message levels
    levelDebug = { 1, 1, 1, 0.52 },
    levelInfo = { 1, 1, 1, 0.96 },
    levelWarn = { 1, 0.76, 0.28, 1 },
    levelError = { 1, 0.42, 0.42, 1 },

    -- Misc
    closeHover = { 1, 0.45, 0.45, 1 },
    resizeHandle = { 1, 1, 1, 0.14 },

    -- Slider
    sliderFill = { 0.76, 0.79, 0.84, 0.58 },
    sliderTrack = { 1, 1, 1, 0.055 },
    sliderThumb = { 0.82, 0.84, 0.88, 0.92 },
    sliderThumbHover = { 0.94, 0.96, 1, 1 },

    -- Toggle
    toggleOn = { 0.72, 0.75, 0.80, 0.56 },
    toggleOff = { 1, 1, 1, 0.07 },
    toggleKnob = { 1, 1, 1, 0.78 },
    toggleKnobOn = { 1, 1, 1, 0.98 },

    -- Primary button
    buttonPrimary = { 0.16, 0.16, 0.18, 1 },
    buttonPrimaryHover = { 0.20, 0.20, 0.22, 1 },
    buttonPrimaryText = { 1, 1, 1, 0.96 },

    -- Panel chrome
    panelGlow = { 0.78, 0.80, 0.84, 0.10 },
    textSection = { 1, 1, 1, 0.42 },

    -- Checkbox
    checkboxBg = { 1, 1, 1, 0.03 },
    checkboxBorder = { 1, 1, 1, 0.12 },
    checkboxBgHover = { 1, 1, 1, 0.06 },
    checkboxBorderHover = { 1, 1, 1, 0.22 },
    checkboxBgChecked = { 0.72, 0.75, 0.80, 0.12 },
    checkboxBorderChecked = { 0.72, 0.75, 0.80, 0.44 },
    checkboxMark = { 0.88, 0.90, 0.94, 0.92 },

    -- Semantic UI colors
    divider = { 1, 1, 1, 0.05 },
    hoverSubtle = { 1, 1, 1, 0.010 },
    selectedSubtle = { 1, 1, 1, 0.020 },
    success = { 0.35, 0.80, 0.45, 1 },
    warning = { 1.0, 0.62, 0.12, 1 },
    error = { 1, 0.42, 0.42, 1 },
}, {
    displayName = "Onyx (Gray)",
    description = "Ultra-dark neutral palette with cool gray accents",
})
