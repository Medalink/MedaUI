--[[
    MedaUI CodeBlock Widget
    Monospace text display for stack traces, code, table dumps
]]

local MedaUI = LibStub("MedaUI-2.0")
---@cast MedaUI MedaUILibrary
local Pixel = LibStub("MedaUI-2.0").Pixel

--- Create a code block
--- @param parent Frame Parent frame
--- @param width number Code block width
--- @param height number Code block height
--- @param config table|nil Configuration {showLineNumbers, wrapText}
--- @return Frame The code block frame
function MedaUI.CreateCodeBlock(library, parent, width, height, config)
    config = config or {}
    local showLineNumbers = config.showLineNumbers ~= false
    local wrapText = config.wrapText or false

    local codeBlock = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    Pixel.SetSize(codeBlock, width, height)
    codeBlock:SetBackdrop(library:CreateBackdrop(true))

    codeBlock.text = ""
    codeBlock.lines = {}
    codeBlock.highlightLine = nil
    codeBlock.showLineNumbers = showLineNumbers

    -- Scroll frame (AF custom scrollbar)
    local scrollParent = library:CreateScrollFrame(codeBlock)
    Pixel.SetPoint(scrollParent, "TOPLEFT", 4, -4)
    Pixel.SetPoint(scrollParent, "BOTTOMRIGHT", -4, 4)
    scrollParent:SetScrollStep(42)

    local content = scrollParent.scrollContent
    codeBlock.content = content
    codeBlock.scrollParent = scrollParent

    -- Line number gutter (if enabled)
    local gutterWidth = showLineNumbers and 40 or 0

    if showLineNumbers then
        codeBlock.gutter = CreateFrame("Frame", nil, codeBlock, "BackdropTemplate")
        Pixel.SetPoint(codeBlock.gutter, "TOPLEFT", 4, -4)
        Pixel.SetPoint(codeBlock.gutter, "BOTTOMLEFT", 4, 4)
        Pixel.SetWidth(codeBlock.gutter, gutterWidth)
        codeBlock.gutter:SetBackdrop(library:CreateBackdrop(false))

        -- Adjust scroll frame position
        Pixel.SetPoint(scrollParent, "TOPLEFT", gutterWidth + 6, -4)
    end

    -- Copy button
    codeBlock.copyBtn = CreateFrame("Button", nil, codeBlock, "BackdropTemplate")
    Pixel.SetSize(codeBlock.copyBtn, 50, 18)
    Pixel.SetPoint(codeBlock.copyBtn, "TOPRIGHT", -8, -6)
    codeBlock.copyBtn:SetBackdrop(library:CreateBackdrop(true))

    codeBlock.copyBtn.text = codeBlock.copyBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    Pixel.SetPoint(codeBlock.copyBtn.text, "CENTER", 0, 0)
    codeBlock.copyBtn.text:SetText("Copy")

    codeBlock.copyBtn:SetScript("OnClick", function()
        codeBlock:CopyToClipboard()
    end)

    -- Slot-based pools (keyed by visible slot, not line index)
    codeBlock.linePool = {}
    codeBlock.lineNumberPool = {}
    codeBlock.visibleLines = {}

    local lineHeight = 14
    local scrollFrame = scrollParent.scrollFrame
    local visibleLineCount = math.ceil(height / lineHeight) + 2

    -- Apply theme colors
    local function ApplyTheme()
        local theme = MedaUI.Theme
        codeBlock:SetBackdropColor(unpack(theme.codeBackground))
        codeBlock:SetBackdropBorderColor(unpack(theme.border))
        if codeBlock.gutter then
            codeBlock.gutter:SetBackdropColor(0.1, 0.1, 0.11, 1)
        end
        codeBlock.copyBtn:SetBackdropColor(unpack(theme.button))
        codeBlock.copyBtn:SetBackdropBorderColor(unpack(theme.border))
        codeBlock.copyBtn.text:SetTextColor(unpack(theme.textDim))
    end
    codeBlock._ApplyTheme = ApplyTheme

    codeBlock._themeHandle = MedaUI:RegisterThemedWidget(codeBlock, function()
        ApplyTheme()
        codeBlock:Refresh()
    end)

    ApplyTheme()

    codeBlock.copyBtn:SetScript("OnEnter", function(button)
        local theme = MedaUI.Theme
        button:SetBackdropColor(unpack(theme.buttonHover))
        button.text:SetTextColor(unpack(theme.text))
    end)

    codeBlock.copyBtn:SetScript("OnLeave", function(button)
        local theme = MedaUI.Theme
        button:SetBackdropColor(unpack(theme.button))
        button.text:SetTextColor(unpack(theme.textDim))
    end)

    local function GetLineFrame(slot)
        local line = codeBlock.linePool[slot]
        if not line then
            line = CreateFrame("Frame", nil, content, "BackdropTemplate")
            Pixel.SetHeight(line, lineHeight)
            line:SetBackdrop(MedaUI:CreateBackdrop(false))

            line.text = line:CreateFontString(nil, "OVERLAY")
            line.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
            Pixel.SetPoint(line.text, "LEFT", 4, 0)
            Pixel.SetPoint(line.text, "RIGHT", -4, 0)
            line.text:SetJustifyH("LEFT")
            line.text:SetWordWrap(wrapText and true or false)

            codeBlock.linePool[slot] = line
        end
        return line
    end

    local function GetLineNumber(slot)
        local lineNum = codeBlock.lineNumberPool[slot]
        if not lineNum then
            lineNum = codeBlock.gutter:CreateFontString(nil, "OVERLAY")
            lineNum:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
            lineNum:SetJustifyH("RIGHT")
            Pixel.SetWidth(lineNum, gutterWidth - 8)
            codeBlock.lineNumberPool[slot] = lineNum
        end
        return lineNum
    end

    -- Render only visible lines based on scroll position
    local function RenderVisible()
        local theme = MedaUI.Theme
        local lines = codeBlock.lines

        -- Hide previously visible
        for _, entry in ipairs(codeBlock.visibleLines) do
            entry.frame:Hide()
            if entry.lineNum then entry.lineNum:Hide() end
        end
        wipe(codeBlock.visibleLines)

        if #lines == 0 then return end

        local scrollPos = scrollFrame:GetVerticalScroll()
        local firstVisible = math.max(1, math.floor(scrollPos / lineHeight))
        local lastVisible = math.min(firstVisible + visibleLineCount, #lines)

        local slot = 0
        for i = firstVisible, lastVisible do
            slot = slot + 1

            -- Line number
            local lineNumObj
            if showLineNumbers then
                lineNumObj = GetLineNumber(slot)
                lineNumObj:ClearAllPoints()
                Pixel.SetPoint(lineNumObj, "TOPRIGHT", -4, -4 - (i - 1) * lineHeight)
                lineNumObj:SetText(tostring(i))
                lineNumObj:SetTextColor(unpack(theme.codeLineNumber))
                lineNumObj:Show()
            end

            -- Line content
            local line = GetLineFrame(slot)
            line:ClearAllPoints()
            Pixel.SetPoint(line, "TOPLEFT", 0, -4 - (i - 1) * lineHeight)
            Pixel.SetPoint(line, "RIGHT", 0, 0)
            line.text:SetText(lines[i])
            line.text:SetTextColor(unpack(theme.text))

            if codeBlock.highlightLine == i then
                line:SetBackdropColor(unpack(theme.codeHighlight))
            else
                line:SetBackdropColor(0, 0, 0, 0)
            end

            line:Show()
            codeBlock.visibleLines[slot] = { frame = line, lineNum = lineNumObj }
        end
    end

    -- Full update: set content height then render visible
    local function UpdateDisplay()
        local lines = codeBlock.lines
        local totalHeight = #lines * lineHeight + 8
        Pixel.SetHeight(content, math.max(totalHeight, height - 8))
        RenderVisible()
    end

    -- Re-render on scroll
    scrollFrame:HookScript("OnVerticalScroll", function()
        RenderVisible()
    end)

    --- Set the code text
    --- @param text string The code text
    function codeBlock:SetText(text)
        self.text = text or ""
        wipe(self.lines)

        for line in (text .. "\n"):gmatch("([^\n]*)\n") do
            self.lines[#self.lines + 1] = line
        end

        UpdateDisplay()
    end

    --- Get the code text
    --- @return string The code text
    function codeBlock:GetText()
        return self.text
    end

    --- Set a line to highlight
    --- @param lineNumber number|nil The line number to highlight
    function codeBlock:SetHighlightLine(lineNumber)
        self.highlightLine = lineNumber
        RenderVisible()
        if lineNumber then
            self:ScrollToLine(lineNumber)
        end
    end

    --- Clear highlight
    function codeBlock:ClearHighlight()
        self.highlightLine = nil
        RenderVisible()
    end

    --- Scroll to a specific line
    --- @param lineNumber number The line number to scroll to
    function codeBlock:ScrollToLine(lineNumber)
        local scrollPos = (lineNumber - 1) * lineHeight - (height / 2)
        scrollParent:SetScroll(scrollPos)
    end

    --- Copy text to clipboard (opens edit box dialog)
    function codeBlock:CopyToClipboard()
        local theme = MedaUI.Theme
        -- Create a popup with an edit box for copying
        if not MedaUI.copyDialog then
            local dialog = CreateFrame("Frame", "MedaUICopyDialog", UIParent, "BackdropTemplate")
            Pixel.SetSize(dialog, 400, 200)
            Pixel.SetPoint(dialog, "CENTER")
            dialog:SetBackdrop(MedaUI:CreateBackdrop(true))
            dialog:SetFrameStrata("FULLSCREEN_DIALOG")
            dialog:EnableMouse(true)

            dialog.title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            Pixel.SetPoint(dialog.title, "TOP", 0, -10)
            dialog.title:SetText("Press Ctrl+C to copy")

            dialog.editBox = CreateFrame("EditBox", nil, dialog, "BackdropTemplate")
            Pixel.SetPoint(dialog.editBox, "TOPLEFT", 10, -35)
            Pixel.SetPoint(dialog.editBox, "BOTTOMRIGHT", -10, 40)
            dialog.editBox:SetBackdrop(MedaUI:CreateBackdrop(true))
            dialog.editBox:SetMultiLine(true)
            dialog.editBox:SetFontObject(GameFontHighlightSmall)
            dialog.editBox:SetAutoFocus(true)

            dialog.closeBtn = CreateFrame("Button", nil, dialog, "BackdropTemplate")
            Pixel.SetSize(dialog.closeBtn, 80, 24)
            Pixel.SetPoint(dialog.closeBtn, "BOTTOM", 0, 10)
            dialog.closeBtn:SetBackdrop(MedaUI:CreateBackdrop(true))

            dialog.closeBtn.text = dialog.closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            Pixel.SetPoint(dialog.closeBtn.text, "CENTER")
            dialog.closeBtn.text:SetText("Close")

            dialog.closeBtn:SetScript("OnClick", function()
                dialog:Hide()
            end)

            dialog.editBox:SetScript("OnEscapePressed", function()
                dialog:Hide()
            end)

            dialog:Hide()
            MedaUI.copyDialog = dialog
        end

        -- Apply current theme to dialog
        MedaUI.copyDialog:SetBackdropColor(unpack(theme.background))
        MedaUI.copyDialog:SetBackdropBorderColor(unpack(theme.border))
        MedaUI.copyDialog.title:SetTextColor(unpack(theme.gold))
        MedaUI.copyDialog.editBox:SetBackdropColor(unpack(theme.input))
        MedaUI.copyDialog.editBox:SetBackdropBorderColor(unpack(theme.border))
        MedaUI.copyDialog.editBox:SetTextColor(unpack(theme.text))
        MedaUI.copyDialog.closeBtn:SetBackdropColor(unpack(theme.button))
        MedaUI.copyDialog.closeBtn:SetBackdropBorderColor(unpack(theme.border))
        MedaUI.copyDialog.closeBtn.text:SetTextColor(unpack(theme.text))

        MedaUI.copyDialog.editBox:SetText(self.text)
        MedaUI.copyDialog.editBox:HighlightText()
        MedaUI.copyDialog:Show()
    end

    --- Refresh the display
    function codeBlock:Refresh()
        UpdateDisplay()
    end

    --- Set whether to show line numbers
    --- @param show boolean Whether to show line numbers
    function codeBlock:SetShowLineNumbers(show)
        self.showLineNumbers = show
        -- Would need to recreate gutter, simplified for now
        UpdateDisplay()
    end

    return codeBlock
end
