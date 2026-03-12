--[[
    MedaUI HUDSection Widget
    Draggable transparent section intended to live inside a HUDGroup.
]]

local MedaUI = LibStub("MedaUI-1.0")
local Pixel = LibStub("MedaUI-1.0").Pixel

--- Create a draggable HUD section.
--- @param parent Frame
--- @param config table|nil { width, height, locked, showBackground, backgroundOpacity, backdropColor, title, titleFont, titleTone, titleAlpha, positionMode }
--- @return Frame
function MedaUI:CreateHUDSection(parent, config)
    config = config or {}

    local section = CreateFrame("Frame", nil, parent)
    Pixel.SetSize(section, config.width or 200, config.height or 40)
    section:SetMovable(true)
    section:SetClampedToScreen(true)
    section:EnableMouse(true)
    section:RegisterForDrag("LeftButton")

    section._locked = config.locked and true or false
    section._positionMode = config.positionMode or "screen"
    section._showBackground = config.showBackground or false
    section._backgroundOpacity = config.backgroundOpacity or 0.4
    section._backgroundColor = config.backdropColor or { 0, 0, 0 }

    section.background = section:CreateTexture(nil, "BACKGROUND")
    section.background:SetAllPoints()

    if config.title then
        section.title = MedaUI:CreateLabel(section, config.title, {
            fontObject = config.titleFont or "GameFontNormal",
            tone = config.titleTone or "dim",
            alpha = config.titleAlpha or 0.6,
            shadow = true,
        })
        Pixel.SetPoint(section.title, "TOPLEFT", 4, 0)
    end

    section:SetScript("OnDragStart", function(self)
        if not self._locked then
            self:StartMoving()
        end
    end)

    section:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if self.OnMove then
            if self._positionMode == "relative" then
                self:OnMove(self:SaveRelativePosition())
            else
                self:OnMove(self:SavePosition())
            end
        end
    end)

    local function ApplyTheme()
        if section._showBackground then
            local color = section._backgroundColor or { 0, 0, 0 }
            section.background:SetColorTexture(color[1] or 0, color[2] or 0, color[3] or 0, section._backgroundOpacity)
            section.background:Show()
        else
            section.background:Hide()
        end
    end

    section._ApplyTheme = ApplyTheme
    section._themeHandle = MedaUI:RegisterThemedWidget(section, ApplyTheme)
    ApplyTheme()

    function section:SetLocked(locked)
        self._locked = locked and true or false
    end

    function section:SetBackgroundVisible(show)
        self._showBackground = show and true or false
        self:_ApplyTheme()
    end

    function section:SetBackgroundOpacity(alpha)
        self._backgroundOpacity = alpha or 0.4
        self:_ApplyTheme()
    end

    function section:SetBackgroundColor(r, g, b)
        self._backgroundColor = { r or 0, g or 0, b or 0 }
        self:_ApplyTheme()
    end

    function section:SetTitle(text)
        if not self.title then
            self.title = MedaUI:CreateLabel(self, text or "", {
                fontObject = config.titleFont or "GameFontNormal",
                tone = config.titleTone or "dim",
                alpha = config.titleAlpha or 0.6,
                shadow = true,
            })
            Pixel.SetPoint(self.title, "TOPLEFT", 4, 0)
        else
            self.title:SetText(text or "")
        end
    end

    function section:SaveRelativePosition()
        local parentFrame = self:GetParent() or UIParent
        local selfX, selfY = self:GetCenter()
        local parentX, parentY = parentFrame:GetCenter()
        if not selfX or not selfY or not parentX or not parentY then
            return { x = 0, y = 0 }
        end

        return {
            x = selfX - parentX,
            y = selfY - parentY,
        }
    end

    function section:SavePosition()
        local point, _, relativePoint, x, y = self:GetPoint()
        return {
            point = point or "CENTER",
            relativePoint = relativePoint or point or "CENTER",
            x = x or 0,
            y = y or 0,
        }
    end

    function section:RestoreRelativePosition(position, fallback)
        self:ClearAllPoints()
        if position and (position.x or position.y) then
            self:SetPoint("CENTER", self:GetParent() or UIParent, "CENTER", position.x or 0, position.y or 0)
        elseif fallback then
            self:SetPoint("CENTER", self:GetParent() or UIParent, "CENTER", fallback.x or 0, fallback.y or 0)
        else
            self:SetPoint("CENTER", self:GetParent() or UIParent, "CENTER", 0, 0)
        end
    end

    function section:RestorePosition(position, fallback)
        self:ClearAllPoints()
        if position then
            self:SetPoint(
                position.point or "CENTER",
                UIParent,
                position.relativePoint or position.point or "CENTER",
                position.x or 0,
                position.y or 0
            )
        elseif fallback then
            self:SetPoint(
                fallback.point or "CENTER",
                UIParent,
                fallback.relativePoint or fallback.point or "CENTER",
                fallback.x or 0,
                fallback.y or 0
            )
        else
            self:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
    end

    return section
end
