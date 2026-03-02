--[[
    MedaUI InfoPanel Widget
    Self-contained, dismissable information panel with header bar,
    scrollable content area, and built-in dismiss/re-show lifecycle.
]]

local MedaUI = LibStub("MedaUI-1.0")

local HEADER_HEIGHT = 30
local FOOTER_HEIGHT = 28
local SCROLL_STEP = 30
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
    frame:SetSize(width, height)
    frame:SetBackdrop(MedaUI:CreateBackdrop(true))

    -- State
    frame._dismissed = false
    frame._locked = config.locked or false

    -- ================================================================
    -- Header bar
    -- ================================================================
    local header = CreateFrame("Frame", nil, frame)
    header:SetHeight(HEADER_HEIGHT)
    header:SetPoint("TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", -1, -1)
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
        if frame.OnPositionChanged then frame:OnPositionChanged() end
    end)

    -- Header icon
    frame.headerIcon = header:CreateTexture(nil, "ARTWORK")
    frame.headerIcon:SetSize(18, 18)
    frame.headerIcon:SetPoint("LEFT", 8, 0)
    frame.headerIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    if config.icon then
        frame.headerIcon:SetTexture(config.icon)
    else
        frame.headerIcon:Hide()
    end

    -- Header title
    frame.titleText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.titleText:SetPoint("LEFT", frame.headerIcon, "RIGHT", 6, 0)
    frame.titleText:SetPoint("RIGHT", header, "RIGHT", -28, 0)
    frame.titleText:SetJustifyH("LEFT")
    frame.titleText:SetText(config.title or "")

    -- Gold accent line under header
    local accent = header:CreateTexture(nil, "OVERLAY")
    accent:SetHeight(1)
    accent:SetPoint("BOTTOMLEFT", 0, 0)
    accent:SetPoint("BOTTOMRIGHT", 0, 0)

    -- Dismiss button
    local dismissBtn
    if config.dismissable ~= false then
        dismissBtn = MedaUI:CreateIconButton(header, {
            size = 18,
            icon = "Interface\\Buttons\\UI-StopButton",
            tooltip = "Dismiss",
        })
        dismissBtn:SetPoint("RIGHT", header, "RIGHT", -5, 0)
        dismissBtn.OnClick = function()
            frame:Dismiss()
        end
    end
    frame.dismissBtn = dismissBtn

    -- ================================================================
    -- Scroll frame and content
    -- ================================================================
    local scrollFrame = CreateFrame("ScrollFrame", name .. "Scroll", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", INSET, -(HEADER_HEIGHT + 4))
    scrollFrame:SetPoint("BOTTOMRIGHT", -INSET - 20, FOOTER_HEIGHT + 4)

    local content = CreateFrame("Frame", name .. "Content", scrollFrame)
    content:SetWidth(width - INSET * 2 - 22)
    content:SetHeight(1)
    scrollFrame:SetScrollChild(content)

    frame.scrollFrame = scrollFrame
    frame.content = content

    -- Mouse wheel scroll
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, delta)
        local cur = scrollFrame:GetVerticalScroll()
        local maxScroll = math.max(0, content:GetHeight() - scrollFrame:GetHeight())
        local newScroll = math.max(0, math.min(maxScroll, cur - delta * SCROLL_STEP))
        scrollFrame:SetVerticalScroll(newScroll)
    end)

    -- ================================================================
    -- Footer
    -- ================================================================
    local footer = CreateFrame("Frame", nil, frame)
    footer:SetHeight(FOOTER_HEIGHT)
    footer:SetPoint("BOTTOMLEFT", 1, 1)
    footer:SetPoint("BOTTOMRIGHT", -1, 1)

    local footerBg = footer:CreateTexture(nil, "BACKGROUND")
    footerBg:SetAllPoints()
    footerBg:SetColorTexture(0.1, 0.1, 0.12, 0.8)
    frame.footerBg = footerBg

    frame.footerText = footer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.footerText:SetPoint("TOPLEFT", 8, -6)
    frame.footerText:SetPoint("RIGHT", footer, "RIGHT", -8, 0)
    frame.footerText:SetJustifyH("LEFT")
    frame.footerText:SetWordWrap(true)

    footer:Hide()
    frame.footer = footer

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
        end
        frame.titleText:SetTextColor(unpack(Theme.gold))
        accent:SetColorTexture(unpack(Theme.goldDim))
        if frame.footerText:GetText() then
            frame.footerText:SetTextColor(unpack(Theme.textDim or {0.6, 0.6, 0.6}))
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
        self:ClearAllPoints()
        if tbl then
            self:SetPoint(tbl.point or "CENTER", UIParent, tbl.point or "CENTER", tbl.x or 0, tbl.y or 0)
        else
            self:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
    end

    function frame:SetFooter(text, r, g, b)
        if text and text ~= "" then
            self.footerText:SetText(text)
            if r then
                self.footerText:SetTextColor(r, g, b)
            end
            self.footer:Show()
            self.scrollFrame:SetPoint("BOTTOMRIGHT", -INSET - 20, FOOTER_HEIGHT + 4)
        else
            self.footerText:SetText("")
            self.footer:Hide()
            self.scrollFrame:SetPoint("BOTTOMRIGHT", -INSET - 20, INSET)
        end
    end

    function frame:ClearContent()
        local kids = { self.content:GetChildren() }
        for _, child in ipairs(kids) do
            child:Hide()
            child:SetParent(nil)
        end
        for _, region in ipairs({ self.content:GetRegions() }) do
            region:Hide()
        end
        self.content:SetHeight(1)
    end

    function frame:SetContentHeight(h)
        self.content:SetHeight(h)
    end

    return frame
end
