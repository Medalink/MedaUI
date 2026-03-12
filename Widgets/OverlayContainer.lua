--[[
    MedaUI OverlayContainer Widget
    Lightweight draggable HUD container with themed title text and optional background.
]]

local MedaUI = LibStub("MedaUI-1.0")
local Pixel = LibStub("MedaUI-1.0").Pixel

--- Create an overlay container.
--- @param name string
--- @param config table|nil { width, height, strata, title, titleFont, titleTone, titleAlpha, point, showBackground, backgroundOpacity, locked }
--- @return Frame
function MedaUI:CreateOverlayContainer(name, config)
    config = config or {}

    local frame = CreateFrame("Frame", name, UIParent)
    Pixel.SetSize(frame, config.width or 280, config.height or 300)
    frame:SetFrameStrata(config.strata or "MEDIUM")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")

    if config.point then
        Pixel.SetPoint(
            frame,
            config.point.point or "CENTER",
            config.point.relativeTo or UIParent,
            config.point.relativePoint or config.point.point or "CENTER",
            config.point.x or 0,
            config.point.y or 0
        )
    else
        Pixel.SetPoint(frame, "CENTER")
    end

    frame._locked = config.locked or false
    frame._showBackground = config.showBackground or false
    frame._backgroundOpacity = config.backgroundOpacity or 0.4

    frame.background = frame:CreateTexture(nil, "BACKGROUND")
    frame.background:SetAllPoints()

    frame.title = MedaUI:CreateLabel(frame, config.title or "", {
        fontObject = config.titleFont or "GameFontNormal",
        tone = config.titleTone or "dim",
        alpha = config.titleAlpha or 0.6,
        shadow = true,
    })
    Pixel.SetPoint(frame.title, "TOPLEFT", 4, 0)

    frame:SetScript("OnDragStart", function(self)
        if not self._locked then
            self:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if self.OnMove then
            self:OnMove(self:SavePosition())
        end
    end)

    local function ApplyTheme()
        frame.background:SetColorTexture(0, 0, 0, frame._backgroundOpacity)
        if frame._showBackground then
            frame.background:Show()
        else
            frame.background:Hide()
        end
    end

    frame._ApplyTheme = ApplyTheme
    frame._themeHandle = MedaUI:RegisterThemedWidget(frame, ApplyTheme)
    ApplyTheme()

    function frame:SetTitle(text)
        self.title:SetText(text or "")
    end

    function frame:SetLocked(locked)
        self._locked = locked and true or false
    end

    function frame:SetBackgroundVisible(show)
        self._showBackground = show and true or false
        self:_ApplyTheme()
    end

    function frame:SetBackgroundOpacity(alpha)
        self._backgroundOpacity = alpha or 0.4
        self:_ApplyTheme()
    end

    function frame:GetContent()
        return self
    end

    function frame:SavePosition()
        local point, _, relativePoint, x, y = self:GetPoint()
        return {
            point = point or "CENTER",
            relativePoint = relativePoint or point or "CENTER",
            x = x or 0,
            y = y or 0,
        }
    end

    function frame:RestorePosition(position, fallback)
        Pixel.ClearPoints(self)
        if position then
            Pixel.SetPoint(
                self,
                position.point or "CENTER",
                UIParent,
                position.relativePoint or position.point or "CENTER",
                position.x or 0,
                position.y or 0
            )
        elseif fallback then
            Pixel.SetPoint(
                self,
                fallback.point or "CENTER",
                UIParent,
                fallback.relativePoint or fallback.point or "CENTER",
                fallback.x or 0,
                fallback.y or 0
            )
        else
            Pixel.SetPoint(self, "CENTER")
        end
    end

    return frame
end
