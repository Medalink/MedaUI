--[[
    MedaUI Panel Widget
    Creates themed movable panels/windows with title bars
    Uses MedaUI.Pixel for pixel-perfect positioning
]]

local MedaUI = LibStub("MedaUI-2.0")
---@cast MedaUI MedaUILibrary

local Pixel = LibStub("MedaUI-2.0").Pixel
local PANEL_AUTOPLACE_OFFSETS = {
    { x = 0, y = 0 },
    { x = 36, y = -24 },
    { x = 72, y = -48 },
    { x = -36, y = 24 },
    { x = -72, y = 48 },
    { x = 108, y = -72 },
}

local function GetNextPanelAutoPlacement()
    MedaUI._panelAutoPlacementIndex = (MedaUI._panelAutoPlacementIndex or 0) + 1
    local index = ((MedaUI._panelAutoPlacementIndex - 1) % #PANEL_AUTOPLACE_OFFSETS) + 1
    return PANEL_AUTOPLACE_OFFSETS[index]
end

local function IsDefaultPanelAnchor(frame)
    local point, relativeTo, relativePoint, x, y = frame:GetPoint()
    return point == "CENTER"
        and (relativeTo == nil or relativeTo == UIParent)
        and (relativePoint == nil or relativePoint == "CENTER")
        and (x or 0) == 0
        and (y or 0) == 0
end

local function ApplyAutoPlacement(frame)
    if frame._medaAutoPlacementApplied or not IsDefaultPanelAnchor(frame) then
        return
    end

    local offset = GetNextPanelAutoPlacement()
    Pixel.ClearPoints(frame)
    Pixel.SetPoint(frame, "CENTER", UIParent, "CENTER", offset.x, offset.y)
    frame._medaAutoPlacementApplied = true
end

local function BringToFront(frame)
    if frame.SetToplevel then
        frame:SetToplevel(true)
    end
    if frame.Raise then
        frame:Raise()
    end
end

--- Create a themed panel/window
--- @param name string Unique frame name
--- @param width number Panel width
--- @param height number Panel height
--- @param title string|nil Panel title
--- @return MedaUIPanel The created panel frame
function MedaUI.CreatePanel(library, name, width, height, title)
    local panel = Pixel.CreateBorderedFrame(UIParent, name, width, height)
    ---@cast panel MedaUIPanel
    Pixel.SetPoint(panel, "CENTER")
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:SetClampedToScreen(true)
    panel:SetFrameStrata("DIALOG")
    panel:SetToplevel(true)

    -- Title bar
    local titleBar = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    Pixel.SetHeight(titleBar, 28)
    Pixel.SetPoint(titleBar, "TOPLEFT", panel, "TOPLEFT", 1, -1)
    Pixel.SetPoint(titleBar, "TOPRIGHT", panel, "TOPRIGHT", -1, -1)
    titleBar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")

    titleBar:SetScript("OnDragStart", function()
        BringToFront(panel)
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
    closeBtn:SetBackdrop(library:CreateBackdrop(false))
    closeBtn:SetBackdropColor(0, 0, 0, 0)

    local closeIcon = closeBtn:CreateTexture(nil, "OVERLAY")
    ---@cast closeIcon Texture
    closeBtn.icon = closeIcon
    closeBtn.icon:SetTexture(MedaUI.mediaPath .. "Textures\\close-x.tga")
    Pixel.SetPoint(closeBtn.icon, "CENTER", 0, 0)
    Pixel.SetSize(closeBtn.icon, 12, 12)

    closeBtn:SetScript("OnClick", function()
        panel:Hide()
    end)

    panel:HookScript("OnShow", function(self)
        ApplyAutoPlacement(self)
        BringToFront(self)
        MedaUI:PlaySound("panelOpen")
    end)
    panel:HookScript("OnHide", function() MedaUI:PlaySound("panelClose") end)
    panel:HookScript("OnMouseDown", function(self)
        BringToFront(self)
    end)

    -- Content area
    panel.content = CreateFrame("Frame", nil, panel)
    Pixel.SetPoint(panel.content, "TOPLEFT", panel, "TOPLEFT", 8, -36)
    Pixel.SetPoint(panel.content, "BOTTOMRIGHT", panel, "BOTTOMRIGHT", -8, 8)

    -- Ambient texture overlays for depth/chrome
    local bgNoise = panel.content:CreateTexture(nil, "BACKGROUND", nil, 1)
    ---@cast bgNoise Texture
    bgNoise:SetTexture(MedaUI.mediaPath .. "Textures\\bg-noise.tga")
    bgNoise:SetAllPoints()
    bgNoise:SetAlpha(0.10)

    local bgVignette = panel.content:CreateTexture(nil, "BACKGROUND", nil, 2)
    ---@cast bgVignette Texture
    bgVignette:SetTexture(MedaUI.mediaPath .. "Textures\\bg-vignette.tga")
    bgVignette:SetAllPoints()
    bgVignette:SetAlpha(0.40)

    local topGlow = panel.content:CreateTexture(nil, "BACKGROUND", nil, 3)
    ---@cast topGlow Texture
    topGlow:SetTexture(MedaUI.mediaPath .. "Textures\\glow-top-ambient.tga")
    Pixel.SetHeight(topGlow, 72)
    topGlow:SetPoint("TOPLEFT", panel.content, "TOPLEFT", 0, 0)
    topGlow:SetPoint("TOPRIGHT", panel.content, "TOPRIGHT", 0, 0)
    topGlow:SetAlpha(0.12)

    local headerAmbient = titleBar:CreateTexture(nil, "BACKGROUND", nil, 1)
    ---@cast headerAmbient Texture
    headerAmbient:SetTexture(MedaUI.mediaPath .. "Textures\\header-ambient.tga")
    headerAmbient:SetAllPoints()
    headerAmbient:SetAlpha(0.08)

    local bgAtmosphere = panel.content:CreateTexture(nil, "BACKGROUND", nil, 1)
    ---@cast bgAtmosphere Texture
    bgAtmosphere:SetTexture(MedaUI.mediaPath .. "Textures\\bg-atmosphere.tga")
    bgAtmosphere:SetAllPoints()
    bgAtmosphere:SetAlpha(0.2)

    local bgMesh = panel.content:CreateTexture(nil, "BACKGROUND", nil, 1)
    ---@cast bgMesh Texture
    bgMesh:SetTexture(MedaUI.mediaPath .. "Textures\\bg-mesh.tga")
    bgMesh:SetAllPoints()
    bgMesh:SetAlpha(0.5)

    local bgDiagonal = panel.content:CreateTexture(nil, "BACKGROUND", nil, 1)
    ---@cast bgDiagonal Texture
    bgDiagonal:SetTexture(MedaUI.mediaPath .. "Textures\\bg-diagonal.tga")
    bgDiagonal:SetAllPoints()
    bgDiagonal:SetAlpha(0.18)

    local bgParticles = panel.content:CreateTexture(nil, "BACKGROUND", nil, 1)
    ---@cast bgParticles Texture
    bgParticles:SetTexture(MedaUI.mediaPath .. "Textures\\bg-particles.tga")
    bgParticles:SetAllPoints()
    bgParticles:SetAlpha(0.4)

    panel.ambientTextures = {
        bgNoise, bgVignette, topGlow, headerAmbient,
        bgAtmosphere, bgMesh, bgDiagonal, bgParticles,
    }

    -- Addon icon watermark
    local addonIcon = panel.content:CreateTexture(nil, "BACKGROUND")
    ---@cast addonIcon Texture
    panel.addonIcon = addonIcon
    Pixel.SetSize(panel.addonIcon, 128, 128)
    Pixel.SetPoint(panel.addonIcon, "BOTTOMRIGHT", panel.content, "BOTTOMRIGHT", -8, 8)
    panel.addonIcon:SetAlpha(0.6)
    panel.addonIcon:Hide()

    -- Accent line under title
    local accent = titleBar:CreateTexture(nil, "OVERLAY")
    ---@cast accent Texture
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

    function panel:BringToFront()
        BringToFront(self)
    end

    -- Apply theme colors
    local function ApplyTheme()
        local theme = MedaUI.Theme
        panel:SetBackdropColor(unpack(theme.background))
        panel:SetBackdropBorderColor(unpack(theme.border))

        if panel._headless then
            titleBar:SetBackdropColor(0, 0, 0, 0)
        else
            titleBar:SetBackdropColor(unpack(theme.backgroundLight))
        end

        if panel.titleText and not panel._headless then
            panel.titleText:SetTextColor(unpack(theme.gold))
        end

        closeBtn.icon:SetAlpha(1)
        if not panel._headless then
            accent:SetColorTexture(unpack(theme.goldDim))
        end

        if topGlow then
            local glow = theme.panelGlow
            if glow then
                topGlow:SetVertexColor(glow[1], glow[2], glow[3], 1)
                topGlow:SetAlpha(glow[4] or 0.06)
            end
        end
    end
    panel._ApplyTheme = ApplyTheme

    panel._themeHandle = MedaUI:RegisterThemedWidget(panel, ApplyTheme)
    ApplyTheme()

    closeBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(1, 0.3, 0.3, 0.15)
    end)

    closeBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0, 0, 0, 0)
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

    function panel:SetHeadless(enabled)
        if enabled then
            titleBar:SetBackdropColor(0, 0, 0, 0)
            titleBar:EnableMouse(false)
            titleBar:SetHeight(1)
            headerAmbient:SetAlpha(0)
            accent:SetAlpha(0)
            if panel.titleText then
                panel.titleText:SetAlpha(0)
            end

            panel.content:ClearAllPoints()
            Pixel.SetPoint(panel.content, "TOPLEFT", panel, "TOPLEFT", 1, -1)
            Pixel.SetPoint(panel.content, "BOTTOMRIGHT", panel, "BOTTOMRIGHT", -1, 1)

            panel:RegisterForDrag("LeftButton")
            panel:SetScript("OnDragStart", function(frame)
                frame:BringToFront()
                frame:StartMoving()
            end)
            panel:SetScript("OnDragStop", function(frame)
                frame:StopMovingOrSizing()
                if frame.OnMove then frame:OnMove(frame:GetState()) end
            end)

            closeBtn:SetParent(panel)
            closeBtn:ClearAllPoints()
            Pixel.SetSize(closeBtn, 30, 30)
            Pixel.SetPoint(closeBtn, "TOPRIGHT", panel, "TOPRIGHT", -14, -18)
            closeBtn:SetFrameStrata("TOOLTIP")
            closeBtn:SetFrameLevel(200)
            closeBtn:EnableMouse(true)
            closeBtn:SetBackdropColor(1, 1, 1, 0.022)
            closeBtn:SetBackdropBorderColor(1, 1, 1, 0.08)
            closeBtn:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
                insets = { left = 1, right = 1, top = 1, bottom = 1 },
            })
            closeBtn:SetBackdropColor(1, 1, 1, 0.022)
            closeBtn:SetBackdropBorderColor(1, 1, 1, 0.08)
            closeBtn:SetScript("OnClick", function() panel:Hide() end)

            closeBtn.icon:ClearAllPoints()
            closeBtn.icon:SetPoint("CENTER", closeBtn, "CENTER", 0, 0)
            closeBtn.icon:SetSize(14, 14)

            panel._headless = true
        end
    end

    function panel:SetDragZone(frame)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", function()
            panel:BringToFront()
            panel:StartMoving()
        end)
        frame:SetScript("OnDragStop", function()
            panel:StopMovingOrSizing()
            if panel.OnMove then panel:OnMove(panel:GetState()) end
        end)
        if frame.HookScript then
            frame:HookScript("OnMouseDown", function()
                panel:BringToFront()
            end)
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
                self.resizeGrip = library:AddResizeGrip(self, {
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
            self._medaAutoPlacementApplied = true
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
