--[[
    MedaUI ImportExportDialog Widget
    Modal dialog for importing/exporting text content (config strings, Lua code, etc.).
    Supports "export" mode (read-only, select-all + copy) and "import" mode (editable, with Import button).
]]

local MedaUI = LibStub("MedaUI-2.0")
---@cast MedaUI MedaUILibrary
local Pixel = MedaUI.Pixel

--- Create a reusable import/export dialog.
--- @param config table|nil Optional defaults: { width, height, title }
--- @return table Dialog API
function MedaUI.CreateImportExportDialog(library, config)
    config = config or {}

    local dialogName = "MedaUIImportExport_" .. tostring(math.random(100000, 999999))

    local frame = CreateFrame("Frame", dialogName, UIParent, "BackdropTemplate")
    Pixel.SetSize(frame, config.width or 520, config.height or 260)
    Pixel.SetPoint(frame, "CENTER")
    frame:SetBackdrop(library:CreateBackdrop(true))
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    tinsert(UISpecialFrames, dialogName)

    -- Title
    local titleLabel = MedaUI:CreateLabel(frame, config.title or "Import / Export", {
        fontObject = "GameFontNormal",
        tone = "gold",
    })
    titleLabel:SetPoint("TOP", 0, -10)

    -- Scroll background
    local scrollBg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    scrollBg:SetPoint("TOPLEFT", 12, -32)
    scrollBg:SetPoint("BOTTOMRIGHT", -12, 42)
    scrollBg:SetBackdrop(library:CreateBackdrop(true))

    local function ApplyInputTheme(focused)
        local theme = MedaUI.Theme
        scrollBg:SetBackdropColor(unpack(theme.input or { 0.08, 0.08, 0.12, 0.98 }))
        scrollBg:SetBackdropBorderColor(unpack(focused and (theme.gold or { 1, 0.82, 0 }) or (theme.border or { 0.3, 0.3, 0.3, 1 })))
    end

    -- Scroll frame
    local scrollParent = library:CreateScrollFrame(scrollBg)
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
    editBox:SetScript("OnEscapePressed", function() frame:Hide() end)

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

    local hintLabel = MedaUI:CreateLabel(frame, "", {
        fontObject = "GameFontNormalSmall",
        tone = "dim",
    })
    hintLabel:SetPoint("BOTTOMLEFT", 12, 18)
    hintLabel:SetJustifyH("LEFT")
    hintLabel:Hide()

    -- Theme
    local function ApplyTheme()
        local theme = MedaUI.Theme
        frame:SetBackdropColor(unpack(theme.backgroundDark))
        frame:SetBackdropBorderColor(unpack(theme.border))
        ApplyInputTheme(editBox:HasFocus())
    end
    MedaUI:RegisterThemedWidget(frame, ApplyTheme)
    ApplyTheme()

    -- API wrapper
    local dialog = {}
    dialog.frame = frame
    dialog.mode = config.mode or "export"
    dialog.title = config.title or "Import / Export"
    dialog.exportText = config.exportText or ""
    dialog.importText = config.importText or config.text or ""
    dialog.hintText = config.hintText or ""
    dialog.onImport = config.onImport

    --- Show the dialog in export mode (text is pre-filled, highlighted for copy).
    function dialog:ShowExport(title, text)
        self.mode = "export"
        self.title = title or "Export"
        self.exportText = text or ""
        titleLabel:SetText(self.title)
        editBox:SetText(text or "")
        importBtn:Hide()
        self:SetHint(self.hintText ~= "" and self.hintText or "Press Ctrl+A to select all, then Ctrl+C to copy.")
        frame:Show()
        editBox:HighlightText()
        editBox:SetFocus()
    end

    --- Show the dialog in import mode (empty or pre-filled, with Import button).
    --- @param title string Dialog title
    --- @param text string|nil Pre-fill text
    --- @param onImport function Callback(text) when Import is clicked
    function dialog:ShowImport(title, text, onImport)
        self.mode = "import"
        self.title = title or "Import"
        self.importText = text or ""
        self.onImport = onImport
        titleLabel:SetText(self.title)
        editBox:SetText(text or "")
        importBtn:Show()
        self:SetHint(self.hintText ~= "" and self.hintText or "Paste the text to import, then click Import.")
        importBtn:SetScript("OnClick", function()
            if onImport then
                onImport(editBox:GetText())
            end
        end)
        frame:Show()
        editBox:SetFocus()
    end

    function dialog:Show()
        if self.mode == "import" then
            self:ShowImport(self.title, self.importText, self.onImport)
        else
            self:ShowExport(self.title, self.exportText)
        end
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
        self.title = title or ""
        titleLabel:SetText(title or "")
    end

    function dialog:IsShown()
        return frame:IsShown()
    end

    function dialog:SetHint(text)
        self.hintText = text or ""
        if self.hintText ~= "" then
            hintLabel:SetText(self.hintText)
            hintLabel:Show()
        else
            hintLabel:SetText("")
            hintLabel:Hide()
        end
    end

    function dialog:SetMode(mode)
        self.mode = mode or "export"
    end

    function dialog:SetImportCallback(callback)
        self.onImport = callback
    end

    dialog:SetHint(dialog.hintText)

    return dialog
end

--- Shared singleton import/export dialog.
local sharedDialog
function MedaUI.GetSharedImportExportDialog(library)
    if not sharedDialog then
        sharedDialog = library:CreateImportExportDialog()
    end
    return sharedDialog
end
