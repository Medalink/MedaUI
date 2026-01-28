--[[
    MedaUI Badge Widget
    Small count indicator that attaches to other elements
]]

local MedaUI = LibStub("MedaUI-1.0")

--- Create a badge (count indicator)
--- @param parent Frame Parent frame to attach to
--- @return Frame The badge frame
function MedaUI:CreateBadge(parent)
    local badge = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    badge:SetSize(18, 16)
    badge:SetBackdrop(self:CreateBackdrop(false))
    badge:SetBackdropColor(0.8, 0.2, 0.2, 1) -- Red by default

    -- Round the corners slightly with a texture overlay
    badge.text = badge:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    badge.text:SetPoint("CENTER", 0, 0)
    badge.text:SetTextColor(1, 1, 1, 1)
    badge.text:SetText("0")

    badge:SetFrameLevel(parent:GetFrameLevel() + 10)
    badge:Hide()

    -- Store count and custom color flag
    badge.count = 0
    badge._hasCustomColor = false

    -- Apply theme colors (only if not using custom color)
    local function ApplyTheme()
        -- Badge uses custom color by default (red), not theme colors
        -- Only refresh if not using custom color
        if not badge._hasCustomColor then
            -- Use tabBadge color from theme if available
            local Theme = MedaUI.Theme
            if Theme.tabBadge then
                badge:SetBackdropColor(unpack(Theme.tabBadge))
            end
        end
    end
    badge._ApplyTheme = ApplyTheme

    -- Register for theme updates
    badge._themeHandle = MedaUI:RegisterThemedWidget(badge, ApplyTheme)

    --- Set the badge count
    --- @param count number The count to display
    function badge:SetCount(count)
        self.count = count
        if count <= 0 then
            self:Hide()
        else
            self:Show()
            if count > 99 then
                self.text:SetText("99+")
                self:SetWidth(26)
            else
                self.text:SetText(tostring(count))
                self:SetWidth(count >= 10 and 22 or 18)
            end
        end
    end

    --- Get the current count
    --- @return number The current count
    function badge:GetCount()
        return self.count
    end

    --- Set the badge color
    --- @param r number Red (0-1)
    --- @param g number Green (0-1)
    --- @param b number Blue (0-1)
    --- @param a number|nil Alpha (0-1, default 1)
    function badge:SetColor(r, g, b, a)
        self._hasCustomColor = true
        self:SetBackdropColor(r, g, b, a or 1)
    end

    --- Attach badge to a frame at specified position
    --- @param frame Frame Frame to attach to
    --- @param point string Anchor point (default "TOPRIGHT")
    --- @param xOffset number X offset (default -2)
    --- @param yOffset number Y offset (default 2)
    function badge:AttachTo(frame, point, xOffset, yOffset)
        self:ClearAllPoints()
        self:SetParent(frame)
        self:SetPoint(point or "TOPRIGHT", frame, point or "TOPRIGHT", xOffset or -2, yOffset or 2)
        self:SetFrameLevel(frame:GetFrameLevel() + 10)
    end

    return badge
end
