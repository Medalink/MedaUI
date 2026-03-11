--[[
    MedaUI ImportExportDialog Widget
    Modal dialog for importing/exporting text content (config strings, Lua code, etc.).
    Supports "export" mode (read-only, select-all + copy) and "import" mode (editable, with Import button).
]]

local MedaUI = LibStub("MedaUI-1.0")
local Pixel = MedaUI.Pixel

--- Create a reusable import/export dialog.
--- @param config table|nil Optional defaults: { width, height, title }
--- @return table Dialog API
function MedaUI:CreateImportExportDialog(config)
    config = config or {}

    local dialogName = "MedaUIImportExport_" .. tostring(math.random(100000, 999999))

    local frame = CreateFrame("Frame", dialogName, UIParent, "BackdropTemplate")
    Pixel.SetSize(frame, config.width or 520, config.height or 260)
    Pixel.SetPoint(frame, "CENTER")
    frame:SetBackdrop(self:CreateBackdrop(true))
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    tinsert(UISpecialFrames, dialogName)

    -- Title
    local titleLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleLabel:SetPoint("TOP", 0, -10)
    titleLabel:SetText(config.title or "Import / Export")

    -- Scroll background
    local scrollBg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    scrollBg:SetPoint("TOPLEFT", 12, -32)
    scrollBg:SetPoint("BOTTOMRIGHT", -12, 42)
    scrollBg:SetBackdrop(self:CreateBackdrop(true))

    local function ApplyInputTheme(focused)
        local Theme = MedaUI.Theme
        scrollBg:SetBackdropColor(unpack(Theme.input or { 0.08, 0.08, 0.12, 0.98 }))
        scrollBg:SetBackdropBorderColor(unpack(focused and (Theme.gold or { 1, 0.82, 0 }) or (Theme.border or { 0.3, 0.3, 0.3, 1 })))
    end

    -- Scroll frame
    local scrollParent = self:CreateScrollFrame(scrollBg)
    Pixel.SetPoint(scrollParent, "TOPLEFT", 6, -6)
    Pixel.SetPoint(scrollParent, "BOTTOMRIGHT", -6, 6)
    scrollParent:SetScrollStep(40)

    -- Edit box
    local editBox = CreateFrame("EditBox", nil, scrollParent.scrollContent)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetMaxLetters(0)
    editBox:SetPoint("TOPLEFT")
    editBox:SetPoint("TOPRIGHT")
    editBox:SetHeight(200)
    editBox:SetTextInsets(8, 8, 8, 8)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    editBox:SetScript("OnEditFocusGained", function() ApplyInputTheme(true) end)
    editBox:SetScript("OnEditFocusLost", function() ApplyInputTheme(false) end)
    editBox:HookScript("OnTextChanged", function()
        local h = editBox:GetHeight()
        scrollParent:SetContentHeight(h, true, true)
    end)

    scrollBg:EnableMouse(true)
    scrollBg:SetScript("OnMouseDown", function() editBox:SetFocus() end)
    scrollParent.scrollFrame:EnableMouse(true)
    scrollParent.scrollFrame:SetScript("OnMouseDown", function() editBox:SetFocus() end)

    -- Buttons
    local closeBtn = MedaUI:CreateButton(frame, "Close")
    closeBtn:SetSize(80, 24)
    closeBtn:SetPoint("BOTTOMRIGHT", -12, 12)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    local importBtn = MedaUI:CreateButton(frame, "Import")
    importBtn:SetSize(80, 24)
    importBtn:SetPoint("RIGHT", closeBtn, "LEFT", -8, 0)
    importBtn:Hide()

    -- Theme
    local function ApplyTheme()
        local Theme = MedaUI.Theme
        frame:SetBackdropColor(unpack(Theme.backgroundDark))
        frame:SetBackdropBorderColor(unpack(Theme.border))
        titleLabel:SetTextColor(unpack(Theme.gold))
        ApplyInputTheme(editBox:HasFocus())
    end
    MedaUI:RegisterThemedWidget(frame, ApplyTheme)
    ApplyTheme()

    -- API wrapper
    local dialog = {}
    dialog.frame = frame

    --- Show the dialog in export mode (text is pre-filled, highlighted for copy).
    function dialog:ShowExport(title, text)
        titleLabel:SetText(title or "Export")
        editBox:SetText(text or "")
        importBtn:Hide()
        frame:Show()
        editBox:HighlightText()
        editBox:SetFocus()
    end

    --- Show the dialog in import mode (empty or pre-filled, with Import button).
    --- @param title string Dialog title
    --- @param text string|nil Pre-fill text
    --- @param onImport function Callback(text) when Import is clicked
    function dialog:ShowImport(title, text, onImport)
        titleLabel:SetText(title or "Import")
        editBox:SetText(text or "")
        importBtn:Show()
        importBtn:SetScript("OnClick", function()
            if onImport then
                onImport(editBox:GetText())
            end
        end)
        frame:Show()
        editBox:SetFocus()
    end

    function dialog:Hide()
        frame:Hide()
    end

    function dialog:GetText()
        return editBox:GetText()
    end

    function dialog:SetText(text)
        editBox:SetText(text or "")
    end

    function dialog:SetTitle(title)
        titleLabel:SetText(title or "")
    end

    function dialog:IsShown()
        return frame:IsShown()
    end

    return dialog
end

--- Shared singleton import/export dialog.
local sharedDialog
function MedaUI:GetSharedImportExportDialog()
    if not sharedDialog then
        sharedDialog = self:CreateImportExportDialog()
    end
    return sharedDialog
end
