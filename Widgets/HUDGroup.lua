--[[
    MedaUI HUDGroup Widget
    Lightweight root container for grouped HUD sections with shared fade behavior.
]]

local MedaUI = LibStub("MedaUI-2.0")
---@cast MedaUI MedaUILibrary
local Pixel = LibStub("MedaUI-2.0").Pixel

--- Create a HUD root container.
--- @param name string
--- @param config table|nil { point, strata, frameLevel, fadeInDuration, fadeOutDuration, opacity, scale }
--- @return Frame
function MedaUI.CreateHUDGroup(_, name, config)
    config = config or {}

    local frame = CreateFrame("Frame", name, UIParent)
    Pixel.SetSize(frame, 1, 1)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata(config.strata or "MEDIUM")
    frame:SetFrameLevel(config.frameLevel or 1)
    frame:Hide()

    if config.point then
        frame:ClearAllPoints()
        frame:SetPoint(
            config.point.point or "CENTER",
            config.point.relativeTo or UIParent,
            config.point.relativePoint or config.point.point or "CENTER",
            config.point.x or 0,
            config.point.y or 0
        )
    end

    frame._hudOpacity = config.opacity or 1
    frame._hudScale = config.scale or 1
    frame:SetScale(frame._hudScale)
    frame:SetAlpha(frame._hudOpacity)

    frame.fadeEffect = MedaUI:CreateFadeEffect(frame, {
        fadeInDuration = config.fadeInDuration or 0.2,
        fadeOutDuration = config.fadeOutDuration or 0.3,
        fromAlpha = 0,
        toAlpha = frame._hudOpacity,
    })

    function frame:SetHUDScale(scale)
        self._hudScale = scale or 1
        self:SetScale(self._hudScale)
    end

    function frame:SetHUDOpacity(alpha)
        self._hudOpacity = alpha or 1
        if self.fadeEffect and self.fadeEffect.SetAlphaRange then
            self.fadeEffect:SetAlphaRange(0, self._hudOpacity)
        end
        if self:IsShown() then
            self:SetAlpha(self._hudOpacity)
        end
    end

    function frame:SetFadeDurations(fadeIn, fadeOut)
        if self.fadeEffect and self.fadeEffect.SetDurations then
            self.fadeEffect:SetDurations(fadeIn or 0.2, fadeOut or 0.3)
        end
    end

    function frame:FadeIn()
        if self.fadeEffect then
            self.fadeEffect:FadeIn()
        else
            self:SetAlpha(self._hudOpacity)
            self:Show()
        end
    end

    function frame:FadeOut()
        if self.fadeEffect then
            self.fadeEffect:FadeOut()
        else
            self:SetAlpha(0)
            self:Hide()
        end
    end

    return frame
end
