--[[
    MedaUI NodeConnector Widget
    Draws directional arrow lines between frames to visualize
    parent-child / chain relationships using WoW Line textures.
]]

local MedaUI = LibStub("MedaUI-1.0")
local Pixel = LibStub("MedaUI-1.0").Pixel

local DEFAULT_LINE_WIDTH = 2
local DEFAULT_ARROW_SIZE = 8
local DEFAULT_CURVE_OFFSET = 20

local pairs = pairs
local ipairs = ipairs
local abs = math.abs

--- Create a node connector that draws arrows between frames.
--- @param parent Frame Parent frame (connections are drawn within this)
--- @param config table|nil Configuration
--- @return table The node connector API object
---
--- Config keys:
---   lineWidth    (number, default 2)  -- arrow line thickness
---   arrowSize    (number, default 8)  -- arrowhead size
---   color        (table|nil)          -- default line color {r,g,b,a} (theme-aware fallback)
---   curveOffset  (number, default 20) -- horizontal offset for curved routing
function MedaUI:CreateNodeConnector(parent, config)
    config = config or {}

    local lineWidth = config.lineWidth or DEFAULT_LINE_WIDTH
    local arrowSize = config.arrowSize or DEFAULT_ARROW_SIZE
    local curveOffset = config.curveOffset or DEFAULT_CURVE_OFFSET

    local connector = {}
    connector._parent = parent
    connector._connections = {}
    connector._linePool = {}
    connector._arrowPool = {}
    connector._poolIndex = 0
    connector._defaultColor = config.color

    -- Theme tracking
    local themeFrame = CreateFrame("Frame", nil, parent)
    themeFrame:SetSize(1, 1)
    themeFrame:SetPoint("TOPLEFT")

    local function GetColor()
        if connector._defaultColor then
            return connector._defaultColor
        end
        local Theme = MedaUI.Theme
        return Theme.textDim or {0.5, 0.5, 0.5, 0.6}
    end

    local function ApplyTheme()
        connector:Refresh()
    end
    themeFrame._ApplyTheme = ApplyTheme
    themeFrame._themeHandle = MedaUI:RegisterThemedWidget(themeFrame, ApplyTheme)

    -- ----------------------------------------------------------------
    -- Line/arrow pool
    -- ----------------------------------------------------------------

    local function AcquireLine()
        connector._poolIndex = connector._poolIndex + 1
        local idx = connector._poolIndex
        local line = connector._linePool[idx]
        if not line then
            line = parent:CreateLine(nil, "OVERLAY")
            connector._linePool[idx] = line
        end
        line:Show()
        return line
    end

    local function AcquireArrow()
        connector._poolIndex = connector._poolIndex + 1
        local idx = connector._poolIndex
        local arrow = connector._arrowPool[idx]
        if not arrow then
            arrow = parent:CreateTexture(nil, "OVERLAY")
            connector._arrowPool[idx] = arrow
        end
        arrow:Show()
        return arrow
    end

    local function HideAll()
        for _, l in pairs(connector._linePool) do l:Hide() end
        for _, a in pairs(connector._arrowPool) do a:Hide() end
        connector._poolIndex = 0
    end

    -- ----------------------------------------------------------------
    -- Drawing
    -- ----------------------------------------------------------------

    local function DrawConnection(conn)
        local source = conn.source
        local target = conn.target
        if not source or not target or not source:IsVisible() or not target:IsVisible() then
            return
        end

        local color = conn.color or GetColor()
        local r, g, b, a = color[1], color[2], color[3], color[4] or 0.6

        local sx, sy = source:GetCenter()
        local tx, ty = target:GetCenter()
        if not sx or not tx then return end

        local srcX = sx
        local srcY = source:GetBottom() or (sy - select(2, source:GetSize()) / 2)
        local tgtX = tx
        local tgtY = target:GetTop() or (ty + select(2, target:GetSize()) / 2)

        local dx = abs(srcX - tgtX)

        if dx < curveOffset then
            -- Straight line
            local line = AcquireLine()
            line:SetThickness(lineWidth)
            line:SetColorTexture(r, g, b, a)
            line:SetStartPoint("BOTTOM", source, 0, 0)
            line:SetEndPoint("TOP", target, 0, 0)
        else
            -- Curved path: source down -> horizontal -> target up
            -- Segment 1: vertical from source bottom
            local midY = (srcY + tgtY) / 2

            local line1 = AcquireLine()
            line1:SetThickness(lineWidth)
            line1:SetColorTexture(r, g, b, a)
            line1:SetStartPoint("BOTTOM", source, 0, 0)
            line1:SetEndPoint("BOTTOMLEFT", parent, srcX - parent:GetLeft(), midY - parent:GetBottom())

            -- Segment 2: horizontal
            local line2 = AcquireLine()
            line2:SetThickness(lineWidth)
            line2:SetColorTexture(r, g, b, a)
            line2:SetEndPoint("BOTTOMLEFT", parent, srcX - parent:GetLeft(), midY - parent:GetBottom())
            line2:SetStartPoint("BOTTOMLEFT", parent, tgtX - parent:GetLeft(), midY - parent:GetBottom())

            -- Segment 3: vertical to target top
            local line3 = AcquireLine()
            line3:SetThickness(lineWidth)
            line3:SetColorTexture(r, g, b, a)
            line3:SetStartPoint("BOTTOMLEFT", parent, tgtX - parent:GetLeft(), midY - parent:GetBottom())
            line3:SetEndPoint("TOP", target, 0, 0)
        end

        -- Arrowhead (small triangle at target top)
        local arrow = AcquireArrow()
        Pixel.SetSize(arrow, arrowSize, arrowSize)
        arrow:SetPoint("BOTTOM", target, "TOP", 0, -1)
        arrow:SetColorTexture(r, g, b, a)
    end

    -- ----------------------------------------------------------------
    -- Public API
    -- ----------------------------------------------------------------

    --- Draw an arrow from source to target frame.
    --- @param sourceFrame Frame Source frame (arrow leaves bottom-center)
    --- @param targetFrame Frame Target frame (arrow arrives top-center)
    --- @param opts table|nil {color = {r,g,b,a}, dashed = bool, label = string}
    function connector:Connect(sourceFrame, targetFrame, opts)
        opts = opts or {}
        self._connections[#self._connections + 1] = {
            source = sourceFrame,
            target = targetFrame,
            color  = opts.color,
            dashed = opts.dashed,
            label  = opts.label,
        }
    end

    --- Remove a specific connection between two frames.
    --- @param sourceFrame Frame
    --- @param targetFrame Frame
    function connector:Disconnect(sourceFrame, targetFrame)
        for i = #self._connections, 1, -1 do
            local c = self._connections[i]
            if c.source == sourceFrame and c.target == targetFrame then
                table.remove(self._connections, i)
            end
        end
    end

    --- Remove all connections.
    function connector:DisconnectAll()
        wipe(self._connections)
        HideAll()
    end

    --- Recalculate and redraw all connections.
    --- Call after layout changes (reorder, scroll, resize).
    function connector:Refresh()
        HideAll()
        for _, conn in ipairs(self._connections) do
            DrawConnection(conn)
        end
    end

    --- Update the default line color.
    --- @param r number Red (0-1)
    --- @param g number Green (0-1)
    --- @param b number Blue (0-1)
    --- @param a number|nil Alpha (0-1, default 0.6)
    function connector:SetColor(r, g, b, a)
        self._defaultColor = {r, g, b, a or 0.6}
    end

    return connector
end
