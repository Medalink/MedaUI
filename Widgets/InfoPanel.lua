--[[
    MedaUI InfoPanel Widget
    Self-contained, dismissable information panel with header bar,
    scrollable content area, and built-in dismiss/re-show lifecycle.
]]

local MedaUI = LibStub("MedaUI-1.0")
local Pixel = LibStub("MedaUI-1.0").Pixel

local HEADER_HEIGHT = 30
local FOOTER_HEIGHT = 28
local STATUS_BAR_HEIGHT = 20
local INSET = 8

--- Create a themed, dismissable info panel with header, scrollable content, and footer.
--- @param name string Unique global frame name
--- @param config table|nil Configuration overrides
--- @return Frame The info panel widget
---
--- Config keys:
---   width (number, default 300) — panel width
---   height (number, default 400) — max panel height before scrolling
---   title (string, default "") — header title text
---   icon (number|string|nil) — header icon texture
---   strata (string, default "MEDIUM") — frame strata
---   dismissable (boolean, default true) — show X button in header
---   locked (boolean, default false) — disable dragging
function MedaUI:CreateInfoPanel(name, config)
    config = config or {}

    local width = config.width or 300
    local height = config.height or 400

    -- Main frame
    local frame = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    frame:SetFrameStrata(config.strata or "MEDIUM")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    Pixel.SetSize(frame, width, height)
    frame:SetBackdrop(MedaUI:CreateBackdrop(true))

    -- State
    frame._dismissed = false
    frame._locked = config.locked or false

    -- ================================================================
    -- Header bar
    -- ================================================================
    local header = CreateFrame("Frame", nil, frame)
    Pixel.SetHeight(header, HEADER_HEIGHT)
    Pixel.SetPoint(header, "TOPLEFT", 1, -1)
    Pixel.SetPoint(header, "TOPRIGHT", -1, -1)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")

    local headerBg = header:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints()
    headerBg:SetColorTexture(0.12, 0.12, 0.14, 1)

    header:SetScript("OnDragStart", function()
        if not frame._locked then frame:StartMoving() end
    end)
    header:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        if frame.OnMove then frame:OnMove() end
    end)

    -- Header icon
    frame.headerIcon = header:CreateTexture(nil, "ARTWORK")
    Pixel.SetSize(frame.headerIcon, 18, 18)
    Pixel.SetPoint(frame.headerIcon, "LEFT", 8, 0)
    frame.headerIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    if config.icon then
        frame.headerIcon:SetTexture(config.icon)
    else
        frame.headerIcon:Hide()
    end

    -- Header title
    frame.titleText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    Pixel.SetPoint(frame.titleText, "LEFT", frame.headerIcon, "RIGHT", 6, 0)
    Pixel.SetPoint(frame.titleText, "RIGHT", header, "RIGHT", -28, 0)
    frame.titleText:SetJustifyH("LEFT")
    frame.titleText:SetText(config.title or "")

    -- Gold accent line under header
    local accent = header:CreateTexture(nil, "OVERLAY")
    Pixel.SetHeight(accent, 1)
    Pixel.SetPoint(accent, "BOTTOMLEFT", 0, 0)
    Pixel.SetPoint(accent, "BOTTOMRIGHT", 0, 0)

    -- Dismiss button (uses standard WoW close button template to match MedaAuras style)
    local dismissBtn
    if config.dismissable ~= false then
        dismissBtn = CreateFrame("Button", nil, header, "UIPanelCloseButton")
        Pixel.SetSize(dismissBtn, 22, 22)
        Pixel.SetPoint(dismissBtn, "RIGHT", header, "RIGHT", -1, 0)
        dismissBtn:SetScript("OnClick", function()
            frame:Dismiss()
        end)
    end
    frame.dismissBtn = dismissBtn

    -- ================================================================
    -- Scroll frame and content (AF custom scrollbar)
    -- ================================================================
    local scrollParent = self:CreateScrollFrame(frame)
    Pixel.SetPoint(scrollParent, "TOPLEFT", INSET, -(HEADER_HEIGHT + 4))
    Pixel.SetPoint(scrollParent, "BOTTOMRIGHT", -INSET, FOOTER_HEIGHT + 4)
    scrollParent:SetScrollStep(30)

    local content = scrollParent.scrollContent
    Pixel.SetHeight(content, 1)

    frame.scrollParent = scrollParent
    frame.content = content

    -- ================================================================
    -- Footer
    -- ================================================================
    local footer = CreateFrame("Frame", nil, frame)
    Pixel.SetHeight(footer, FOOTER_HEIGHT)
    Pixel.SetPoint(footer, "BOTTOMLEFT", 1, 1)
    Pixel.SetPoint(footer, "BOTTOMRIGHT", -1, 1)

    local footerBg = footer:CreateTexture(nil, "BACKGROUND")
    footerBg:SetAllPoints()
    footerBg:SetColorTexture(0.1, 0.1, 0.12, 0.8)
    frame.footerBg = footerBg

    frame.footerText = footer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    Pixel.SetPoint(frame.footerText, "TOPLEFT", 8, -6)
    Pixel.SetPoint(frame.footerText, "RIGHT", footer, "RIGHT", -8, 0)
    frame.footerText:SetJustifyH("LEFT")
    frame.footerText:SetWordWrap(true)

    footer:Hide()
    frame.footer = footer

    -- ================================================================
    -- Status bar (persistent bar at the very bottom of the panel)
    -- ================================================================
    local statusBar = CreateFrame("Frame", nil, frame)
    Pixel.SetHeight(statusBar, STATUS_BAR_HEIGHT)
    Pixel.SetPoint(statusBar, "BOTTOMLEFT", 1, 1)
    Pixel.SetPoint(statusBar, "BOTTOMRIGHT", -1, 1)

    local statusBarBg = statusBar:CreateTexture(nil, "BACKGROUND")
    statusBarBg:SetAllPoints()
    statusBarBg:SetColorTexture(0.08, 0.08, 0.1, 0.9)
    frame.statusBarBg = statusBarBg

    frame.statusBarText = statusBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    Pixel.SetPoint(frame.statusBarText, "LEFT", 8, 0)
    Pixel.SetPoint(frame.statusBarText, "RIGHT", statusBar, "RIGHT", -8, 0)
    frame.statusBarText:SetJustifyH("LEFT")

    statusBar:Hide()
    frame.statusBar = statusBar

    local function UpdateBottomLayout()
        local sbVisible = statusBar:IsShown()
        local ftVisible = footer:IsShown()

        local footerBottom = 1 + (sbVisible and STATUS_BAR_HEIGHT or 0)
        Pixel.ClearPoints(footer)
        Pixel.SetHeight(footer, FOOTER_HEIGHT)
        Pixel.SetPoint(footer, "BOTTOMLEFT", 1, footerBottom)
        Pixel.SetPoint(footer, "BOTTOMRIGHT", -1, footerBottom)

        local barsHeight = (sbVisible and STATUS_BAR_HEIGHT or 0)
            + (ftVisible and FOOTER_HEIGHT or 0)
        local scrollBottom = barsHeight > 0 and (barsHeight + 4) or INSET
        Pixel.ClearPoints(scrollParent)
        Pixel.SetPoint(scrollParent, "TOPLEFT", INSET, -(HEADER_HEIGHT + 4))
        Pixel.SetPoint(scrollParent, "BOTTOMRIGHT", -INSET, scrollBottom)
    end

    -- Store refs
    frame.header = header
    frame.headerBg = headerBg
    frame.accent = accent

    frame:Hide()

    -- State for background opacity override (nil = use theme defaults)
    frame._bgAlpha = nil

    -- ================================================================
    -- Theme
    -- ================================================================
    local function ApplyTheme()
        local Theme = MedaUI.Theme
        local alpha = frame._bgAlpha
        if alpha then
            frame:SetBackdropColor(Theme.background[1], Theme.background[2], Theme.background[3], alpha)
            frame:SetBackdropBorderColor(Theme.border[1], Theme.border[2], Theme.border[3], alpha > 0 and (Theme.border[4] or 0.6) or 0)
            headerBg:SetColorTexture(
                Theme.backgroundLight[1], Theme.backgroundLight[2], Theme.backgroundLight[3],
                alpha > 0 and (Theme.backgroundLight[4] or 1) or 0
            )
            footerBg:SetColorTexture(0.1, 0.1, 0.12, alpha * 0.8)
            statusBarBg:SetColorTexture(0.08, 0.08, 0.1, alpha * 0.9)
        else
            frame:SetBackdropColor(unpack(Theme.background))
            frame:SetBackdropBorderColor(unpack(Theme.border))
            headerBg:SetColorTexture(
                Theme.backgroundLight[1],
                Theme.backgroundLight[2],
                Theme.backgroundLight[3],
                Theme.backgroundLight[4] or 1
            )
            footerBg:SetColorTexture(0.1, 0.1, 0.12, 0.8)
            statusBarBg:SetColorTexture(0.08, 0.08, 0.1, 0.9)
        end
        frame.titleText:SetTextColor(unpack(Theme.gold))
        accent:SetColorTexture(unpack(Theme.goldDim))
        if frame.footerText:GetText() then
            frame.footerText:SetTextColor(unpack(Theme.textDim or {0.6, 0.6, 0.6}))
        end
        if frame.statusBarText:GetText() then
            frame.statusBarText:SetTextColor(unpack(Theme.textDim or {0.6, 0.6, 0.6}))
        end
    end
    frame._ApplyTheme = ApplyTheme
    frame._themeHandle = MedaUI:RegisterThemedWidget(frame, ApplyTheme)
    ApplyTheme()

    -- ================================================================
    -- Public API
    -- ================================================================

    function frame:SetTitle(text)
        self.titleText:SetText(text or "")
    end

    function frame:SetIcon(textureID)
        if textureID then
            self.headerIcon:SetTexture(textureID)
            self.headerIcon:Show()
        else
            self.headerIcon:Hide()
        end
    end

    function frame:GetContent()
        return self.content
    end

    function frame:Show()
        self._dismissed = false
        getmetatable(self).__index.Show(self)
        if self.OnShow then self:OnShow() end
    end

    function frame:Dismiss()
        self._dismissed = true
        self:Hide()
        if self.OnDismiss then self:OnDismiss() end
    end

    function frame:IsDismissed()
        return self._dismissed
    end

    function frame:ClearDismissed()
        self._dismissed = false
    end

    function frame:SetLocked(locked)
        self._locked = locked
    end

    function frame:SetBackgroundOpacity(alpha)
        self._bgAlpha = alpha
        self._ApplyTheme()
    end

    function frame:SavePosition()
        local point, _, _, x, y = self:GetPoint()
        return { point = point or "CENTER", x = x or 0, y = y or 0 }
    end

    function frame:RestorePosition(tbl)
        Pixel.ClearPoints(self)
        if tbl then
            Pixel.SetPoint(self, tbl.point or "CENTER", UIParent, tbl.point or "CENTER", tbl.x or 0, tbl.y or 0)
        else
            Pixel.SetPoint(self, "CENTER", UIParent, "CENTER", 0, 0)
        end
    end

    function frame:SetFooter(text, r, g, b)
        if text and text ~= "" then
            self.footerText:SetText(text)
            if r then
                self.footerText:SetTextColor(r, g, b)
            end
            self.footer:Show()
        else
            self.footerText:SetText("")
            self.footer:Hide()
        end
        UpdateBottomLayout()
    end

    function frame:SetStatusBar(text, r, g, b)
        if text and text ~= "" then
            self.statusBarText:SetText(text)
            if r then
                self.statusBarText:SetTextColor(r, g, b)
            end
            self.statusBar:Show()
        else
            self.statusBarText:SetText("")
            self.statusBar:Hide()
        end
        UpdateBottomLayout()
    end

    function frame:ClearContent()
        local kids = { self.content:GetChildren() }
        for _, child in ipairs(kids) do
            child:Hide()
            child:ClearAllPoints()
        end
        for _, region in ipairs({ self.content:GetRegions() }) do
            region:Hide()
        end
        Pixel.SetHeight(self.content, 1)
    end

    function frame:SetContentHeight(h)
        Pixel.SetHeight(self.content, h)
    end

    -- ================================================================
    -- Resize support
    -- ================================================================

    frame.isResizable = false
    frame.resizeGrip = nil
    frame.OnResize = nil

    local nativeSetResizable = frame.SetResizable

    --- Enable resizing with min/max bounds
    --- @param enabled boolean Whether resizing is enabled
    --- @param resizeConfig table|nil {minWidth, minHeight}
    function frame:SetResizable(enabled, resizeConfig)
        self.isResizable = enabled
        resizeConfig = resizeConfig or {}

        if nativeSetResizable then
            nativeSetResizable(self, enabled)
        end

        if enabled then
            if not self.resizeGrip then
                self.resizeGrip = MedaUI:AddResizeGrip(self, {
                    minWidth = resizeConfig.minWidth or 200,
                    minHeight = resizeConfig.minHeight or 150,
                    onResize = function(w, h)
                        if self.OnResize then
                            self:OnResize(w, h)
                        end
                    end,
                })
            end
            self.resizeGrip:Show()
        else
            if self.resizeGrip then
                self.resizeGrip:Hide()
            end
        end
    end

    return frame
end
