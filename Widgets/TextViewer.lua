--[[
    MedaUI TextViewer Widget
    Modal dialog for viewing and copying large text content
]]

local MedaUI = LibStub("MedaUI-1.0")

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
    viewer:SetSize(width, height)
    viewer:SetPoint("CENTER")
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
    titleText:SetPoint("TOP", 0, -12)
    titleText:SetText(title)
    viewer.titleLabel = titleText

    -- Close button
    local closeBtn = CreateFrame("Button", nil, viewer)
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", -5, -5)
    closeBtn.text = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    closeBtn.text:SetPoint("CENTER", 0, 1)
    closeBtn.text:SetText("X")
    closeBtn:SetScript("OnClick", function()
        viewer:Hide()
    end)
    closeBtn:SetScript("OnEnter", function(self)
        self.text:SetTextColor(1, 0.3, 0.3)
    end)
    closeBtn:SetScript("OnLeave", function(self)
        local Theme = MedaUI.Theme
        self.text:SetTextColor(unpack(Theme.textDim))
    end)
    viewer.closeBtn = closeBtn

    -- Scroll frame for the edit box
    local scrollFrame = CreateFrame("ScrollFrame", nil, viewer, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 45)
    viewer.scrollFrame = scrollFrame

    -- Style the scrollbar
    local scrollBar = scrollFrame.ScrollBar
    if scrollBar then
        scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 2, -16)
        scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 2, 16)
    end

    -- Edit box for text content
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject("GameFontHighlightSmall")
    editBox:SetWidth(scrollFrame:GetWidth() - 10)
    editBox:SetAutoFocus(false)
    editBox:SetScript("OnEscapePressed", function()
        viewer:Hide()
    end)
    scrollFrame:SetScrollChild(editBox)
    viewer.editBox = editBox

    -- Button container at bottom
    local buttonContainer = CreateFrame("Frame", nil, viewer)
    buttonContainer:SetHeight(30)
    buttonContainer:SetPoint("BOTTOMLEFT", 10, 10)
    buttonContainer:SetPoint("BOTTOMRIGHT", -10, 10)
    viewer.buttonContainer = buttonContainer

    -- Copy instruction label
    local copyHint = viewer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    copyHint:SetPoint("LEFT", buttonContainer, "LEFT", 0, 0)
    copyHint:SetText("Press Ctrl+C to copy")
    viewer.copyHint = copyHint

    -- Close button (bottom right)
    local closeBottomBtn = MedaUI:CreateButton(buttonContainer, "Close", 80, 24)
    closeBottomBtn:SetPoint("RIGHT", 0, 0)
    closeBottomBtn:SetScript("OnClick", function()
        viewer:Hide()
    end)
    viewer.closeBottomBtn = closeBottomBtn

    -- Select All button
    local selectAllBtn = MedaUI:CreateButton(buttonContainer, "Select All", 80, 24)
    selectAllBtn:SetPoint("RIGHT", closeBottomBtn, "LEFT", -8, 0)
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
