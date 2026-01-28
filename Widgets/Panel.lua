--[[
    MedaUI Panel Widget
    Creates themed movable panels/windows with title bars
]]

local MedaUI = LibStub("MedaUI-1.0")
local Theme = MedaUI.Theme

--- Create a themed panel/window
--- @param name string Unique frame name
--- @param width number Panel width
--- @param height number Panel height
--- @param title string|nil Panel title
--- @return Frame The created panel frame
function MedaUI:CreatePanel(name, width, height, title)
    -- Main panel frame
    local panel = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    panel:SetSize(width, height)
    panel:SetPoint("CENTER")
    panel:SetBackdrop(self:CreateBackdrop(true))
    panel:SetBackdropColor(unpack(Theme.background))
    panel:SetBackdropBorderColor(unpack(Theme.border))
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:SetClampedToScreen(true)
    panel:SetFrameStrata("DIALOG")

    -- Title bar
    local titleBar = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    titleBar:SetHeight(28)
    titleBar:SetPoint("TOPLEFT", 1, -1)
    titleBar:SetPoint("TOPRIGHT", -1, -1)
    titleBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    titleBar:SetBackdropColor(unpack(Theme.backgroundLight))
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

    -- Title text
    if title then
        panel.titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        panel.titleText:SetPoint("LEFT", 10, 0)
        panel.titleText:SetText(title)
        panel.titleText:SetTextColor(unpack(Theme.gold))
    end

    -- Close button
    local closeBtn = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("RIGHT", -4, 0)
    closeBtn:SetBackdrop(self:CreateBackdrop(false))
    closeBtn:SetBackdropColor(0, 0, 0, 0)

    closeBtn.text = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    closeBtn.text:SetPoint("CENTER", 0, 1)
    closeBtn.text:SetText("x")
    closeBtn.text:SetTextColor(unpack(Theme.textDim))

    closeBtn:SetScript("OnEnter", function(self)
        self.text:SetTextColor(unpack(Theme.closeHover))
    end)

    closeBtn:SetScript("OnLeave", function(self)
        self.text:SetTextColor(unpack(Theme.textDim))
    end)

    closeBtn:SetScript("OnClick", function()
        panel:Hide()
    end)

    -- Content area
    panel.content = CreateFrame("Frame", nil, panel)
    panel.content:SetPoint("TOPLEFT", 8, -36)
    panel.content:SetPoint("BOTTOMRIGHT", -8, 8)

    -- Gold accent line under title
    local accent = titleBar:CreateTexture(nil, "OVERLAY")
    accent:SetHeight(1)
    accent:SetPoint("BOTTOMLEFT", 0, 0)
    accent:SetPoint("BOTTOMRIGHT", 0, 0)
    accent:SetColorTexture(unpack(Theme.goldDim))

    -- API methods
    panel.titleBar = titleBar
    panel.closeButton = closeBtn
    panel.isResizable = false
    panel.resizeGrip = nil
    panel.OnResize = nil
    panel.OnMove = nil

    function panel:SetTitle(newTitle)
        if self.titleText then
            self.titleText:SetText(newTitle)
        end
    end

    function panel:GetContent()
        return self.content
    end

    --- Enable resizing with min/max bounds
    --- @param enabled boolean Whether resizing is enabled
    --- @param config table|nil {minWidth, minHeight}
    function panel:SetResizable(enabled, config)
        self.isResizable = enabled
        config = config or {}

        if enabled then
            -- Create resize grip if it doesn't exist
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

    --- Get the current size
    --- @return number, number width, height
    function panel:GetPanelSize()
        return self:GetWidth(), self:GetHeight()
    end

    --- Set the panel size
    --- @param w number Width
    --- @param h number Height
    function panel:SetPanelSize(w, h)
        self:SetSize(w, h)
    end

    --- Get the current state (position and size)
    --- @return table {position = {point, relativeTo, relativePoint, x, y}, size = {width, height}}
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

    --- Restore panel state (position and size)
    --- @param state table {position = {...}, size = {...}}
    function panel:RestoreState(state)
        if not state then return end

        if state.size then
            if state.size.width then self:SetWidth(state.size.width) end
            if state.size.height then self:SetHeight(state.size.height) end
        end

        if state.position and state.position.point then
            self:ClearAllPoints()
            local relativeTo = state.position.relativeTo and _G[state.position.relativeTo] or UIParent
            self:SetPoint(
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
