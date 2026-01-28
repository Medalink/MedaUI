--[[
    MedaUI ResizeGrip Widget
    Adds resize handles to any frame with visible grip indicator
]]

local MedaUI = LibStub("MedaUI-1.0")

--- Add resize functionality to a frame
--- @param frame Frame The frame to make resizable
--- @param config table|nil Configuration {minWidth, minHeight, onResize}
--- @return table Handle references for cleanup
function MedaUI:AddResizeGrip(frame, config)
    config = config or {}

    local minW = config.minWidth or 200
    local minH = config.minHeight or 150
    local onResize = config.onResize

    -- Set resize bounds (caller is responsible for enabling SetResizable on the frame)
    frame:SetResizeBounds(minW, minH)

    local handles = {}
    local cornerSize = 16
    local edgeSize = 8

    -- Corner handles
    local corners = {
        { point = "BOTTOMRIGHT", primary = true },
        { point = "BOTTOMLEFT", primary = false },
        { point = "TOPRIGHT", primary = false },
        { point = "TOPLEFT", primary = false },
    }

    for _, corner in ipairs(corners) do
        local handle = CreateFrame("Button", nil, frame)
        handle:SetSize(cornerSize, cornerSize)
        handle:SetPoint(corner.point)
        handle:EnableMouse(true)
        handle:RegisterForDrag("LeftButton")
        handle.direction = corner.point
        handle.isPrimary = corner.primary

        if corner.primary then
            -- Draw a visible grip pattern for the primary resize corner (bottom-right)
            -- 3x3 pixel dots with improved visibility
            handle.dots = {}
            handle._isHovered = false
            for i = 1, 3 do
                local dot1 = handle:CreateTexture(nil, "OVERLAY")
                dot1:SetSize(3, 3)  -- Increased from 2x2 to 3x3
                dot1:SetPoint("BOTTOMRIGHT", -(i * 4), (i * 4))
                handle.dots[#handle.dots + 1] = dot1

                local dot2 = handle:CreateTexture(nil, "OVERLAY")
                dot2:SetSize(3, 3)  -- Increased from 2x2 to 3x3
                dot2:SetPoint("BOTTOMRIGHT", -(i * 4) - 4, (i * 4) - 4)
                handle.dots[#handle.dots + 1] = dot2
            end

            -- Apply theme to dots
            local function ApplyTheme()
                local Theme = MedaUI.Theme
                for _, dot in ipairs(handle.dots) do
                    if handle._isHovered then
                        -- Gold color on hover
                        dot:SetColorTexture(unpack(Theme.gold))
                    else
                        -- Slightly higher base opacity (0.6 alpha)
                        local color = Theme.textDim
                        dot:SetColorTexture(color[1], color[2], color[3], 0.6)
                    end
                end
            end
            handle._ApplyTheme = ApplyTheme

            -- Hover state for gold color
            handle:SetScript("OnEnter", function(self)
                self._isHovered = true
                self._ApplyTheme()
            end)

            handle:SetScript("OnLeave", function(self)
                self._isHovered = false
                self._ApplyTheme()
            end)

            -- Register for theme updates
            handle._themeHandle = MedaUI:RegisterThemedWidget(handle, ApplyTheme)
            ApplyTheme()
        else
            -- Hidden indicator for other corners, shows on hover
            handle.texture = handle:CreateTexture(nil, "OVERLAY")
            handle.texture:SetAllPoints()
            handle.texture:Hide()

            -- Apply theme
            local function ApplyTheme()
                local Theme = MedaUI.Theme
                handle.texture:SetColorTexture(unpack(Theme.resizeHandle))
            end

            handle._themeHandle = MedaUI:RegisterThemedWidget(handle, ApplyTheme)
            ApplyTheme()

            handle:SetScript("OnEnter", function(self)
                if self.texture then self.texture:Show() end
            end)

            handle:SetScript("OnLeave", function(self)
                if self.texture then self.texture:Hide() end
            end)
        end

        handle:SetScript("OnDragStart", function(self)
            frame:StartSizing(self.direction)
        end)

        handle:SetScript("OnDragStop", function()
            frame:StopMovingOrSizing()
            if onResize then
                onResize(frame:GetWidth(), frame:GetHeight())
            end
        end)

        handles[#handles + 1] = handle
    end

    -- Bottom edge handle
    local bottomHandle = CreateFrame("Button", nil, frame)
    bottomHandle:SetHeight(edgeSize)
    bottomHandle:SetPoint("BOTTOMLEFT", cornerSize, 0)
    bottomHandle:SetPoint("BOTTOMRIGHT", -cornerSize, 0)
    bottomHandle:EnableMouse(true)
    bottomHandle:RegisterForDrag("LeftButton")
    bottomHandle.direction = "BOTTOM"
    bottomHandle:SetScript("OnDragStart", function()
        frame:StartSizing("BOTTOM")
    end)
    bottomHandle:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        if onResize then onResize(frame:GetWidth(), frame:GetHeight()) end
    end)
    handles[#handles + 1] = bottomHandle

    -- Right edge handle
    local rightHandle = CreateFrame("Button", nil, frame)
    rightHandle:SetWidth(edgeSize)
    rightHandle:SetPoint("TOPRIGHT", 0, -cornerSize)
    rightHandle:SetPoint("BOTTOMRIGHT", 0, cornerSize)
    rightHandle:EnableMouse(true)
    rightHandle:RegisterForDrag("LeftButton")
    rightHandle.direction = "RIGHT"
    rightHandle:SetScript("OnDragStart", function()
        frame:StartSizing("RIGHT")
    end)
    rightHandle:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        if onResize then onResize(frame:GetWidth(), frame:GetHeight()) end
    end)
    handles[#handles + 1] = rightHandle

    -- Left edge handle
    local leftHandle = CreateFrame("Button", nil, frame)
    leftHandle:SetWidth(edgeSize)
    leftHandle:SetPoint("TOPLEFT", 0, -cornerSize)
    leftHandle:SetPoint("BOTTOMLEFT", 0, cornerSize)
    leftHandle:EnableMouse(true)
    leftHandle:RegisterForDrag("LeftButton")
    leftHandle.direction = "LEFT"
    leftHandle:SetScript("OnDragStart", function()
        frame:StartSizing("LEFT")
    end)
    leftHandle:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        if onResize then onResize(frame:GetWidth(), frame:GetHeight()) end
    end)
    handles[#handles + 1] = leftHandle

    -- Top edge handle
    local topHandle = CreateFrame("Button", nil, frame)
    topHandle:SetHeight(edgeSize)
    topHandle:SetPoint("TOPLEFT", cornerSize, 0)
    topHandle:SetPoint("TOPRIGHT", -cornerSize, 0)
    topHandle:EnableMouse(true)
    topHandle:RegisterForDrag("LeftButton")
    topHandle.direction = "TOP"
    topHandle:SetScript("OnDragStart", function()
        frame:StartSizing("TOP")
    end)
    topHandle:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        if onResize then onResize(frame:GetWidth(), frame:GetHeight()) end
    end)
    handles[#handles + 1] = topHandle

    -- Return handle references for showing/hiding
    local grip = {
        handles = handles,

        Show = function(self)
            for _, h in ipairs(self.handles) do
                h:Show()
            end
        end,

        Hide = function(self)
            for _, h in ipairs(self.handles) do
                h:Hide()
            end
        end,

        SetEnabled = function(self, enabled)
            for _, h in ipairs(self.handles) do
                h:EnableMouse(enabled)
                if enabled then
                    h:Show()
                else
                    h:Hide()
                end
            end
        end,
    }

    return grip
end
