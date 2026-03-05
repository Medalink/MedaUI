--[[
    MedaUI Panel Widget
    Creates themed movable panels/windows with title bars
    Uses MedaUI.Pixel for pixel-perfect positioning
]]

local MedaUI = LibStub("MedaUI-1.0")

local Pixel = LibStub("MedaUI-1.0").Pixel

--- Create a themed panel/window
--- @param name string Unique frame name
--- @param width number Panel width
--- @param height number Panel height
--- @param title string|nil Panel title
--- @return Frame The created panel frame
function MedaUI:CreatePanel(name, width, height, title)
    local panel = Pixel.CreateBorderedFrame(UIParent, name, width, height)
    Pixel.SetPoint(panel, "CENTER")
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:SetClampedToScreen(true)
    panel:SetFrameStrata("DIALOG")

    -- Title bar
    local titleBar = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    Pixel.SetHeight(titleBar, 28)
    Pixel.SetPoint(titleBar, "TOPLEFT", panel, "TOPLEFT", 1, -1)
    Pixel.SetPoint(titleBar, "TOPRIGHT", panel, "TOPRIGHT", -1, -1)
    titleBar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")

    titleBar:SetScript("OnDragStart", function()
        panel:StartMoving()
    end)

    titleBar:SetScript("OnDragStop", function()
        panel:StopMovingOrSizing()
        if panel.OnMove then
            panel:OnMove(panel:GetState())
        end
    end)

    if title then
        panel.titleText = Pixel.CreateFontString(titleBar, title)
        Pixel.SetPoint(panel.titleText, "LEFT", titleBar, "LEFT", 10, 0)
    end

    -- Close button
    local closeBtn = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
    Pixel.SetSize(closeBtn, 20, 20)
    Pixel.SetPoint(closeBtn, "RIGHT", titleBar, "RIGHT", -4, 0)
    closeBtn:SetBackdrop(self:CreateBackdrop(false))
    closeBtn:SetBackdropColor(0, 0, 0, 0)

    closeBtn.icon = closeBtn:CreateTexture(nil, "OVERLAY")
    closeBtn.icon:SetTexture(MedaUI.mediaPath .. "Textures\\close-x.tga")
    Pixel.SetPoint(closeBtn.icon, "CENTER", 0, 0)
    Pixel.SetSize(closeBtn.icon, 12, 12)

    closeBtn:SetScript("OnClick", function()
        panel:Hide()
    end)

    -- Content area
    panel.content = CreateFrame("Frame", nil, panel)
    Pixel.SetPoint(panel.content, "TOPLEFT", panel, "TOPLEFT", 8, -36)
    Pixel.SetPoint(panel.content, "BOTTOMRIGHT", panel, "BOTTOMRIGHT", -8, 8)

    -- Addon icon watermark
    panel.addonIcon = panel.content:CreateTexture(nil, "BACKGROUND")
    Pixel.SetSize(panel.addonIcon, 128, 128)
    Pixel.SetPoint(panel.addonIcon, "BOTTOMRIGHT", panel.content, "BOTTOMRIGHT", -8, 8)
    panel.addonIcon:SetAlpha(0.15)
    panel.addonIcon:Hide()

    -- Gold accent line under title
    local accent = titleBar:CreateTexture(nil, "OVERLAY")
    Pixel.SetHeight(accent, 1)
    Pixel.SetPoint(accent, "BOTTOMLEFT", titleBar, "BOTTOMLEFT")
    Pixel.SetPoint(accent, "BOTTOMRIGHT", titleBar, "BOTTOMRIGHT")

    -- Store references
    panel.titleBar = titleBar
    panel.closeButton = closeBtn
    panel.accent = accent
    panel.isResizable = false
    panel.resizeGrip = nil
    panel.OnResize = nil
    panel.OnMove = nil

    -- Apply theme colors
    local function ApplyTheme()
        local Theme = MedaUI.Theme
        panel:SetBackdropColor(unpack(Theme.background))
        panel:SetBackdropBorderColor(unpack(Theme.border))
        titleBar:SetBackdropColor(unpack(Theme.backgroundLight))

        if panel.titleText then
            panel.titleText:SetTextColor(unpack(Theme.gold))
        end

        closeBtn.icon:SetAlpha(0.6)
        accent:SetColorTexture(unpack(Theme.goldDim))
    end
    panel._ApplyTheme = ApplyTheme

    panel._themeHandle = MedaUI:RegisterThemedWidget(panel, ApplyTheme)
    ApplyTheme()

    -- Close button hover effects
    closeBtn:SetScript("OnEnter", function(self)
        self.icon:SetAlpha(1.0)
    end)

    closeBtn:SetScript("OnLeave", function(self)
        self.icon:SetAlpha(0.6)
    end)

    -- API methods
    function panel:SetTitle(newTitle)
        if self.titleText then
            self.titleText:SetText(newTitle)
        end
    end

    function panel:GetContent()
        return self.content
    end

    function panel:SetAddonIcon(iconPath)
        if self.addonIcon and iconPath then
            self.addonIcon:SetTexture(iconPath)
            self.addonIcon:Show()
        end
    end

    function panel:ClearAddonIcon()
        if self.addonIcon then
            self.addonIcon:Hide()
            self.addonIcon:SetTexture(nil)
        end
    end

    local nativeSetResizable = panel.SetResizable

    function panel:SetResizable(enabled, config)
        self.isResizable = enabled
        config = config or {}

        if nativeSetResizable then
            nativeSetResizable(self, enabled)
        end

        if enabled then
            if not self.resizeGrip then
                self.resizeGrip = MedaUI:AddResizeGrip(self, {
                    minWidth = config.minWidth or 200,
                    minHeight = config.minHeight or 150,
                    onResize = function(w, h)
                        if self.OnResize then
                            self:OnResize(self:GetState())
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

    function panel:GetPanelSize()
        return self:GetWidth(), self:GetHeight()
    end

    function panel:SetPanelSize(w, h)
        Pixel.SetSize(self, w, h)
    end

    function panel:GetState()
        local point, relativeTo, relativePoint, x, y = self:GetPoint()
        return {
            position = {
                point = point,
                relativeTo = relativeTo and relativeTo:GetName() or nil,
                relativePoint = relativePoint,
                x = x,
                y = y,
            },
            size = {
                width = self:GetWidth(),
                height = self:GetHeight(),
            },
        }
    end

    function panel:RestoreState(state)
        if not state then return end

        if state.size then
            if state.size.width and state.size.height then
                Pixel.SetSize(self, state.size.width, state.size.height)
            elseif state.size.width then
                Pixel.SetWidth(self, state.size.width)
            elseif state.size.height then
                Pixel.SetHeight(self, state.size.height)
            end
        end

        if state.position and state.position.point then
            Pixel.ClearPoints(self)
            local relativeTo = state.position.relativeTo and _G[state.position.relativeTo] or UIParent
            Pixel.SetPoint(self,
                state.position.point,
                relativeTo,
                state.position.relativePoint,
                state.position.x or 0,
                state.position.y or 0
            )
        end
    end

    -- Start hidden
    panel:Hide()

    return panel
end
