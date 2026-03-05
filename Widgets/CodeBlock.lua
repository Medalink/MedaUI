--[[
    MedaUI CodeBlock Widget
    Monospace text display for stack traces, code, table dumps
]]

local MedaUI = LibStub("MedaUI-1.0")
local Pixel = LibStub("MedaUI-1.0").Pixel

--- Create a code block
--- @param parent Frame Parent frame
--- @param width number Code block width
--- @param height number Code block height
--- @param config table|nil Configuration {showLineNumbers, wrapText}
--- @return Frame The code block frame
function MedaUI:CreateCodeBlock(parent, width, height, config)
    config = config or {}
    local showLineNumbers = config.showLineNumbers ~= false
    local wrapText = config.wrapText or false

    local codeBlock = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    Pixel.SetSize(codeBlock, width, height)
    codeBlock:SetBackdrop(self:CreateBackdrop(true))

    codeBlock.text = ""
    codeBlock.lines = {}
    codeBlock.highlightLine = nil
    codeBlock.showLineNumbers = showLineNumbers

    -- Scroll frame (AF custom scrollbar)
    local scrollParent = self:CreateScrollFrame(codeBlock)
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
        codeBlock.gutter:SetBackdrop(self:CreateBackdrop(false))

        -- Adjust scroll frame position
        Pixel.SetPoint(scrollParent, "TOPLEFT", gutterWidth + 6, -4)
    end

    -- Copy button
    codeBlock.copyBtn = CreateFrame("Button", nil, codeBlock, "BackdropTemplate")
    Pixel.SetSize(codeBlock.copyBtn, 50, 18)
    Pixel.SetPoint(codeBlock.copyBtn, "TOPRIGHT", -8, -6)
    codeBlock.copyBtn:SetBackdrop(self:CreateBackdrop(true))

    codeBlock.copyBtn.text = codeBlock.copyBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    Pixel.SetPoint(codeBlock.copyBtn.text, "CENTER", 0, 0)
    codeBlock.copyBtn.text:SetText("Copy")

    codeBlock.copyBtn:SetScript("OnClick", function()
        codeBlock:CopyToClipboard()
    end)

    -- Line pool
    codeBlock.linePool = {}
    codeBlock.lineNumberPool = {}

    local lineHeight = 14

    -- Apply theme colors
    local function ApplyTheme()
        local Theme = MedaUI.Theme
        codeBlock:SetBackdropColor(unpack(Theme.codeBackground))
        codeBlock:SetBackdropBorderColor(unpack(Theme.border))
        if codeBlock.gutter then
            codeBlock.gutter:SetBackdropColor(0.1, 0.1, 0.11, 1)
        end
        codeBlock.copyBtn:SetBackdropColor(unpack(Theme.button))
        codeBlock.copyBtn:SetBackdropBorderColor(unpack(Theme.border))
        codeBlock.copyBtn.text:SetTextColor(unpack(Theme.textDim))
    end
    codeBlock._ApplyTheme = ApplyTheme

    -- Register for theme updates
    codeBlock._themeHandle = MedaUI:RegisterThemedWidget(codeBlock, function()
        ApplyTheme()
        codeBlock:Refresh()
    end)

    -- Initial theme application
    ApplyTheme()

    -- Copy button hover effects
    codeBlock.copyBtn:SetScript("OnEnter", function(self)
        local Theme = MedaUI.Theme
        self:SetBackdropColor(unpack(Theme.buttonHover))
        self.text:SetTextColor(unpack(Theme.text))
    end)

    codeBlock.copyBtn:SetScript("OnLeave", function(self)
        local Theme = MedaUI.Theme
        self:SetBackdropColor(unpack(Theme.button))
        self.text:SetTextColor(unpack(Theme.textDim))
    end)

    -- Update display
    local function UpdateDisplay()
        local Theme = MedaUI.Theme
        local lines = codeBlock.lines
        local totalHeight = #lines * lineHeight + 8
        Pixel.SetHeight(content, math.max(totalHeight, height - 8))

        -- Hide existing lines
        for _, line in ipairs(codeBlock.linePool) do
            line:Hide()
        end
        for _, lineNum in ipairs(codeBlock.lineNumberPool) do
            lineNum:Hide()
        end

        -- Create/show lines
        for i, lineText in ipairs(lines) do
            -- Line number
            if showLineNumbers then
                local lineNum = codeBlock.lineNumberPool[i]
                if not lineNum then
                    lineNum = codeBlock.gutter:CreateFontString(nil, "OVERLAY")
                    lineNum:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
                    lineNum:SetJustifyH("RIGHT")
                    Pixel.SetWidth(lineNum, gutterWidth - 8)
                    codeBlock.lineNumberPool[i] = lineNum
                end
                Pixel.SetPoint(lineNum, "TOPRIGHT", -4, -4 - (i - 1) * lineHeight)
                lineNum:SetText(tostring(i))
                lineNum:SetTextColor(unpack(Theme.codeLineNumber))
                lineNum:Show()
            end

            -- Line content
            local line = codeBlock.linePool[i]
            if not line then
                line = CreateFrame("Frame", nil, content, "BackdropTemplate")
                Pixel.SetHeight(line, lineHeight)
                line:SetBackdrop(MedaUI:CreateBackdrop(false))

                line.text = line:CreateFontString(nil, "OVERLAY")
                line.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
                Pixel.SetPoint(line.text, "LEFT", 4, 0)
                Pixel.SetPoint(line.text, "RIGHT", -4, 0)
                line.text:SetJustifyH("LEFT")

                codeBlock.linePool[i] = line
            end

            Pixel.SetPoint(line, "TOPLEFT", 0, -4 - (i - 1) * lineHeight)
            Pixel.SetPoint(line, "RIGHT", 0, 0)
            line.text:SetText(lineText)
            line.text:SetTextColor(unpack(Theme.text))

            -- Highlight line
            if codeBlock.highlightLine == i then
                line:SetBackdropColor(unpack(Theme.codeHighlight))
            else
                line:SetBackdropColor(0, 0, 0, 0)
            end

            line:Show()
        end
    end

    --- Set the code text
    --- @param text string The code text
    function codeBlock:SetText(text)
        self.text = text or ""
        self.lines = {}

        -- Split into lines
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
        UpdateDisplay()
        if lineNumber then
            self:ScrollToLine(lineNumber)
        end
    end

    --- Clear highlight
    function codeBlock:ClearHighlight()
        self.highlightLine = nil
        UpdateDisplay()
    end

    --- Scroll to a specific line
    --- @param lineNumber number The line number to scroll to
    function codeBlock:ScrollToLine(lineNumber)
        local scrollPos = (lineNumber - 1) * lineHeight - (height / 2)
        scrollParent:SetScroll(scrollPos)
    end

    --- Copy text to clipboard (opens edit box dialog)
    function codeBlock:CopyToClipboard()
        local Theme = MedaUI.Theme
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
        MedaUI.copyDialog:SetBackdropColor(unpack(Theme.background))
        MedaUI.copyDialog:SetBackdropBorderColor(unpack(Theme.border))
        MedaUI.copyDialog.title:SetTextColor(unpack(Theme.gold))
        MedaUI.copyDialog.editBox:SetBackdropColor(unpack(Theme.input))
        MedaUI.copyDialog.editBox:SetBackdropBorderColor(unpack(Theme.border))
        MedaUI.copyDialog.editBox:SetTextColor(unpack(Theme.text))
        MedaUI.copyDialog.closeBtn:SetBackdropColor(unpack(Theme.button))
        MedaUI.copyDialog.closeBtn:SetBackdropBorderColor(unpack(Theme.border))
        MedaUI.copyDialog.closeBtn.text:SetTextColor(unpack(Theme.text))

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
