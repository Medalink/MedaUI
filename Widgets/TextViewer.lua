--[[
    MedaUI TextViewer Widget
    Modal dialog for viewing and copying large text content
]]

local MedaUI = LibStub("MedaUI-1.0")
local Pixel = LibStub("MedaUI-1.0").Pixel

--- Create a text viewer dialog
--- @param title string Dialog title
--- @param width number Dialog width
--- @param height number Dialog height
--- @return table The text viewer widget
function MedaUI:CreateTextViewer(title, width, height)
    width = width or 500
    height = height or 350

    -- Generate unique name
    local dialogName = "MedaUITextViewer_" .. tostring(math.random(100000, 999999))

    local viewer = CreateFrame("Frame", dialogName, UIParent, "BackdropTemplate")
    Pixel.SetSize(viewer, width, height)
    Pixel.SetPoint(viewer, "CENTER")
    viewer:SetBackdrop(self:CreateBackdrop(true))
    viewer:SetFrameStrata("DIALOG")
    viewer:SetMovable(true)
    viewer:EnableMouse(true)
    viewer:RegisterForDrag("LeftButton")
    viewer:SetScript("OnDragStart", viewer.StartMoving)
    viewer:SetScript("OnDragStop", viewer.StopMovingOrSizing)
    viewer:Hide()

    local Theme = self.Theme

    -- State
    viewer.title = title
    viewer.text = ""

    -- Title bar
    local titleText = viewer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    Pixel.SetPoint(titleText, "TOP", 0, -12)
    titleText:SetText(title)
    viewer.titleLabel = titleText

    -- Close button
    local closeBtn = CreateFrame("Button", nil, viewer)
    Pixel.SetSize(closeBtn, 20, 20)
    Pixel.SetPoint(closeBtn, "TOPRIGHT", -5, -5)
    closeBtn.text = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    Pixel.SetPoint(closeBtn.text, "CENTER", 0, 1)
    closeBtn.text:SetText("X")
    closeBtn:SetScript("OnClick", function()
        viewer:Hide()
    end)
    closeBtn:SetScript("OnEnter", function(self)
        local Theme = MedaUI.Theme
        self.text:SetTextColor(unpack(Theme.text))
    end)
    closeBtn:SetScript("OnLeave", function(self)
        local Theme = MedaUI.Theme
        self.text:SetTextColor(unpack(Theme.textDim))
    end)
    viewer.closeBtn = closeBtn

    -- Scroll frame for the edit box (AF custom scrollbar)
    local scrollParent = self:CreateScrollFrame(viewer)
    Pixel.SetPoint(scrollParent, "TOPLEFT", 10, -40)
    Pixel.SetPoint(scrollParent, "BOTTOMRIGHT", -10, 45)
    scrollParent:SetScrollStep(40)
    viewer.scrollParent = scrollParent

    -- Edit box for text content
    local editBox = CreateFrame("EditBox", nil, scrollParent.scrollContent)
    editBox:SetMultiLine(true)
    editBox:SetFontObject("GameFontHighlightSmall")
    editBox:SetPoint("TOPLEFT")
    editBox:SetPoint("TOPRIGHT")
    editBox:SetAutoFocus(false)
    editBox:SetScript("OnEscapePressed", function()
        viewer:Hide()
    end)
    editBox:HookScript("OnTextChanged", function(self)
        scrollParent:SetContentHeight(self:GetHeight(), true, true)
    end)
    viewer.editBox = editBox

    -- Button container at bottom
    local buttonContainer = CreateFrame("Frame", nil, viewer)
    Pixel.SetHeight(buttonContainer, 30)
    Pixel.SetPoint(buttonContainer, "BOTTOMLEFT", 10, 10)
    Pixel.SetPoint(buttonContainer, "BOTTOMRIGHT", -10, 10)
    viewer.buttonContainer = buttonContainer

    -- Copy instruction label
    local copyHint = viewer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    Pixel.SetPoint(copyHint, "LEFT", buttonContainer, "LEFT", 0, 0)
    copyHint:SetText("Press Ctrl+C to copy")
    viewer.copyHint = copyHint

    -- Close button (bottom right)
    local closeBottomBtn = MedaUI:CreateButton(buttonContainer, "Close", 80, 24)
    Pixel.SetPoint(closeBottomBtn, "RIGHT", 0, 0)
    closeBottomBtn:SetScript("OnClick", function()
        viewer:Hide()
    end)
    viewer.closeBottomBtn = closeBottomBtn

    -- Select All button
    local selectAllBtn = MedaUI:CreateButton(buttonContainer, "Select All", 80, 24)
    Pixel.SetPoint(selectAllBtn, "RIGHT", closeBottomBtn, "LEFT", -8, 0)
    selectAllBtn:SetScript("OnClick", function()
        editBox:HighlightText()
        editBox:SetFocus()
    end)
    viewer.selectAllBtn = selectAllBtn

    -- Apply theme
    local function ApplyTheme()
        local Theme = MedaUI.Theme
        viewer:SetBackdropColor(0.1, 0.1, 0.1, 0.97)
        viewer:SetBackdropBorderColor(unpack(Theme.border))

        titleText:SetTextColor(unpack(Theme.gold))
        closeBtn.text:SetTextColor(unpack(Theme.textDim))
        copyHint:SetTextColor(unpack(Theme.textDim))
    end
    viewer._ApplyTheme = ApplyTheme
    viewer._themeHandle = MedaUI:RegisterThemedWidget(viewer, ApplyTheme)
    ApplyTheme()

    --- Set the dialog title
    --- @param newTitle string The new title
    function viewer:SetTitle(newTitle)
        self.title = newTitle
        self.titleLabel:SetText(newTitle)
    end

    --- Set the text content
    --- @param text string The text to display
    function viewer:SetText(text)
        self.text = text
        self.editBox:SetText(text)
    end

    --- Get the text content
    --- @return string The current text
    function viewer:GetText()
        return self.editBox:GetText()
    end

    --- Show the viewer and optionally set text
    --- @param text string|nil Optional text to display
    function viewer:ShowWithText(text)
        if text then
            self:SetText(text)
        end
        self:Show()
        self.editBox:HighlightText()
        self.editBox:SetFocus()
    end

    -- Register for ESC
    tinsert(UISpecialFrames, dialogName)

    return viewer
end

--- Create a shared text viewer instance (singleton pattern)
--- Use this when you only need one viewer at a time
--- @return table The shared text viewer instance
local sharedViewer = nil
function MedaUI:GetSharedTextViewer()
    if not sharedViewer then
        sharedViewer = self:CreateTextViewer("Text Viewer", 600, 400)
    end
    return sharedViewer
end

--- Quick helper to show text in the shared viewer
--- @param title string Dialog title
--- @param text string Text to display
function MedaUI:ShowTextViewer(title, text)
    local viewer = self:GetSharedTextViewer()
    viewer:SetTitle(title)
    viewer:ShowWithText(text)
end
