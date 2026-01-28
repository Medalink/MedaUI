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
    panel.resizeHandles = {}
    panel.OnResize = nil

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
    --- @param config table|nil {minWidth, minHeight, maxWidth, maxHeight}
    function panel:SetResizable(enabled, config)
        self.isResizable = enabled
        config = config or {}
        
        local minW = config.minWidth or 200
        local minH = config.minHeight or 150
        local maxW = config.maxWidth or 2000
        local maxH = config.maxHeight or 1500
        
        if enabled then
            self:SetResizeBounds(minW, minH, maxW, maxH)
            
            -- Create resize handles if they don't exist
            if #self.resizeHandles == 0 then
                local handleSize = 8
                local handles = {
                    { point = "BOTTOMRIGHT", cursor = "BOTTOMRIGHT" },
                    { point = "BOTTOMLEFT", cursor = "BOTTOMLEFT" },
                    { point = "TOPRIGHT", cursor = "TOPRIGHT" },
                    { point = "TOPLEFT", cursor = "TOPLEFT" },
                }
                
                for _, h in ipairs(handles) do
                    local handle = CreateFrame("Button", nil, self)
                    handle:SetSize(handleSize, handleSize)
                    handle:SetPoint(h.point)
                    handle:EnableMouse(true)
                    handle:RegisterForDrag("LeftButton")
                    handle.direction = h.point
                    
                    -- Visual indicator
                    handle.texture = handle:CreateTexture(nil, "OVERLAY")
                    handle.texture:SetAllPoints()
                    handle.texture:SetColorTexture(unpack(Theme.resizeHandle or {0.3, 0.3, 0.3, 0.5}))
                    handle.texture:Hide()
                    
                    handle:SetScript("OnEnter", function(self)
                        self.texture:Show()
                    end)
                    
                    handle:SetScript("OnLeave", function(self)
                        self.texture:Hide()
                    end)
                    
                    handle:SetScript("OnDragStart", function(self)
                        panel:StartSizing(self.direction)
                    end)
                    
                    handle:SetScript("OnDragStop", function(self)
                        panel:StopMovingOrSizing()
                        if panel.OnResize then
                            panel:OnResize(panel:GetWidth(), panel:GetHeight())
                        end
                    end)
                    
                    self.resizeHandles[#self.resizeHandles + 1] = handle
                end
                
                -- Edge handles (bottom and right)
                local bottomHandle = CreateFrame("Button", nil, self)
                bottomHandle:SetHeight(handleSize)
                bottomHandle:SetPoint("BOTTOMLEFT", handleSize, 0)
                bottomHandle:SetPoint("BOTTOMRIGHT", -handleSize, 0)
                bottomHandle:EnableMouse(true)
                bottomHandle:RegisterForDrag("LeftButton")
                bottomHandle.direction = "BOTTOM"
                bottomHandle:SetScript("OnDragStart", function() panel:StartSizing("BOTTOM") end)
                bottomHandle:SetScript("OnDragStop", function()
                    panel:StopMovingOrSizing()
                    if panel.OnResize then panel:OnResize(panel:GetWidth(), panel:GetHeight()) end
                end)
                self.resizeHandles[#self.resizeHandles + 1] = bottomHandle
                
                local rightHandle = CreateFrame("Button", nil, self)
                rightHandle:SetWidth(handleSize)
                rightHandle:SetPoint("TOPRIGHT", 0, -handleSize)
                rightHandle:SetPoint("BOTTOMRIGHT", 0, handleSize)
                rightHandle:EnableMouse(true)
                rightHandle:RegisterForDrag("LeftButton")
                rightHandle.direction = "RIGHT"
                rightHandle:SetScript("OnDragStart", function() panel:StartSizing("RIGHT") end)
                rightHandle:SetScript("OnDragStop", function()
                    panel:StopMovingOrSizing()
                    if panel.OnResize then panel:OnResize(panel:GetWidth(), panel:GetHeight()) end
                end)
                self.resizeHandles[#self.resizeHandles + 1] = rightHandle
            end
            
            -- Show handles
            for _, handle in ipairs(self.resizeHandles) do
                handle:Show()
            end
        else
            -- Hide handles
            for _, handle in ipairs(self.resizeHandles) do
                handle:Hide()
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

    -- Start hidden
    panel:Hide()

    return panel
end
