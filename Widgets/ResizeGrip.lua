--[[
    MedaUI ResizeGrip Widget
    Adds resize handles to any frame with visible grip indicator
]]

local MedaUI = LibStub("MedaUI-1.0")
local Pixel = LibStub("MedaUI-1.0").Pixel

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

    -- Corner handles (TOPRIGHT omitted to avoid conflicting with title bar close button)
    local corners = {
        { point = "BOTTOMRIGHT", primary = true },
        { point = "BOTTOMLEFT", primary = false },
        { point = "TOPLEFT", primary = false },
    }

    for _, corner in ipairs(corners) do
        local handle = CreateFrame("Button", nil, frame)
        Pixel.SetSize(handle, cornerSize, cornerSize)
        Pixel.SetPoint(handle, corner.point)
        handle:EnableMouse(true)
        handle:RegisterForDrag("LeftButton")
        handle.direction = corner.point
        handle.isPrimary = corner.primary

        if corner.primary then
            handle._isHovered = false
            handle.triangle = handle:CreateTexture(nil, "OVERLAY")
            Pixel.SetSize(handle.triangle, 14, 14)
            Pixel.SetPoint(handle.triangle, "BOTTOMRIGHT", 0, 0)
            handle.triangle:SetTexture(MedaUI.mediaPath .. "Textures\\Triangle_BottomRight.tga")

            local function ApplyTheme()
                local Theme = MedaUI.Theme
                if handle._isHovered then
                    handle.triangle:SetVertexColor(unpack(Theme.gold))
                    handle.triangle:SetAlpha(0.8)
                else
                    local c = Theme.resizeHandle
                    handle.triangle:SetVertexColor(c[1], c[2], c[3])
                    handle.triangle:SetAlpha(c[4] or 0.6)
                end
            end
            handle._ApplyTheme = ApplyTheme

            handle:SetScript("OnEnter", function(self)
                self._isHovered = true
                self._ApplyTheme()
            end)

            handle:SetScript("OnLeave", function(self)
                self._isHovered = false
                self._ApplyTheme()
            end)

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
    Pixel.SetHeight(bottomHandle, edgeSize)
    Pixel.SetPoint(bottomHandle, "BOTTOMLEFT", cornerSize, 0)
    Pixel.SetPoint(bottomHandle, "BOTTOMRIGHT", -cornerSize, 0)
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
    Pixel.SetWidth(rightHandle, edgeSize)
    Pixel.SetPoint(rightHandle, "TOPRIGHT", 0, -cornerSize)
    Pixel.SetPoint(rightHandle, "BOTTOMRIGHT", 0, cornerSize)
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
    Pixel.SetWidth(leftHandle, edgeSize)
    Pixel.SetPoint(leftHandle, "TOPLEFT", 0, -cornerSize)
    Pixel.SetPoint(leftHandle, "BOTTOMLEFT", 0, cornerSize)
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
    Pixel.SetHeight(topHandle, edgeSize)
    Pixel.SetPoint(topHandle, "TOPLEFT", cornerSize, 0)
    Pixel.SetPoint(topHandle, "TOPRIGHT", -cornerSize, 0)
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
