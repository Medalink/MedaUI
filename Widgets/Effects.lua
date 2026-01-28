--[[
    MedaUI Effects Widget
    Reusable animation effects: pulse, glow, fade, etc.
]]

local MedaUI = LibStub("MedaUI-1.0")

--- Create a pulsing highlight effect
--- @param frame Frame The frame to apply the effect to
--- @param config table|nil Configuration {color, minAlpha, maxAlpha, speed, texture}
--- @return table The pulse effect controller
function MedaUI:CreatePulseEffect(frame, config)
    config = config or {}

    local pulse = {
        frame = frame,
        color = config.color or { 0.9, 0.7, 0.15, 1 },  -- Gold by default
        minAlpha = config.minAlpha or 0.15,
        maxAlpha = config.maxAlpha or 0.5,
        speed = config.speed or 2,  -- Cycles per second
        isPlaying = false,
        elapsed = 0,
    }

    -- Create overlay texture if not provided
    if not pulse.overlay then
        pulse.overlay = frame:CreateTexture(nil, "OVERLAY")
        pulse.overlay:SetAllPoints()
        if config.texture then
            pulse.overlay:SetTexture(config.texture)
        else
            pulse.overlay:SetColorTexture(1, 1, 1, 1)
        end
        pulse.overlay:Hide()
    end

    -- Update function for animation
    local function OnUpdate(self, elapsed)
        pulse.elapsed = pulse.elapsed + elapsed

        -- Sine wave for smooth pulsing
        local t = pulse.elapsed * pulse.speed * math.pi * 2
        local alpha = pulse.minAlpha + (pulse.maxAlpha - pulse.minAlpha) * (0.5 + 0.5 * math.sin(t))

        pulse.overlay:SetAlpha(alpha)
    end

    -- Animation frame
    pulse.animFrame = CreateFrame("Frame")
    pulse.animFrame:SetScript("OnUpdate", OnUpdate)
    pulse.animFrame:Hide()

    --- Start the pulse effect
    function pulse:Start()
        if self.isPlaying then return end
        self.isPlaying = true
        self.elapsed = 0

        -- Apply color
        local r, g, b = self.color[1], self.color[2], self.color[3]
        self.overlay:SetVertexColor(r, g, b)
        self.overlay:SetAlpha(self.minAlpha)
        self.overlay:Show()

        self.animFrame:Show()
    end

    --- Stop the pulse effect
    function pulse:Stop()
        if not self.isPlaying then return end
        self.isPlaying = false

        self.animFrame:Hide()
        self.overlay:Hide()
    end

    --- Set the pulse color
    --- @param r number Red (0-1)
    --- @param g number Green (0-1)
    --- @param b number Blue (0-1)
    function pulse:SetColor(r, g, b)
        self.color = { r, g, b, 1 }
        if self.isPlaying then
            self.overlay:SetVertexColor(r, g, b)
        end
    end

    --- Set the alpha range
    --- @param minAlpha number Minimum alpha (0-1)
    --- @param maxAlpha number Maximum alpha (0-1)
    function pulse:SetAlphaRange(minAlpha, maxAlpha)
        self.minAlpha = minAlpha
        self.maxAlpha = maxAlpha
    end

    --- Set the pulse speed
    --- @param speed number Cycles per second
    function pulse:SetSpeed(speed)
        self.speed = speed
    end

    --- Check if effect is playing
    --- @return boolean
    function pulse:IsPlaying()
        return self.isPlaying
    end

    return pulse
end

--- Create a glow effect (static, not animated)
--- @param frame Frame The frame to apply the glow to
--- @param config table|nil Configuration {color, alpha, size, texture}
--- @return table The glow effect controller
function MedaUI:CreateGlowEffect(frame, config)
    config = config or {}

    local glow = {
        frame = frame,
        color = config.color or { 0.9, 0.7, 0.15, 1 },
        alpha = config.alpha or 0.5,
        size = config.size or 4,  -- Size of glow expansion
        isVisible = false,
    }

    -- Create glow texture
    glow.texture = frame:CreateTexture(nil, "BACKGROUND")
    glow.texture:SetPoint("TOPLEFT", -glow.size, glow.size)
    glow.texture:SetPoint("BOTTOMRIGHT", glow.size, -glow.size)
    glow.texture:SetColorTexture(glow.color[1], glow.color[2], glow.color[3], glow.alpha)
    glow.texture:Hide()

    --- Show the glow effect
    function glow:Show()
        self.isVisible = true
        self.texture:Show()
    end

    --- Hide the glow effect
    function glow:Hide()
        self.isVisible = false
        self.texture:Hide()
    end

    --- Toggle the glow effect
    function glow:Toggle()
        if self.isVisible then
            self:Hide()
        else
            self:Show()
        end
    end

    --- Set the glow color
    --- @param r number Red (0-1)
    --- @param g number Green (0-1)
    --- @param b number Blue (0-1)
    function glow:SetColor(r, g, b)
        self.color = { r, g, b, 1 }
        self.texture:SetColorTexture(r, g, b, self.alpha)
    end

    --- Set the glow alpha
    --- @param alpha number Alpha (0-1)
    function glow:SetAlpha(alpha)
        self.alpha = alpha
        self.texture:SetColorTexture(self.color[1], self.color[2], self.color[3], alpha)
    end

    return glow
end

--- Create a fade-in/fade-out controller
--- @param frame Frame The frame to fade
--- @param config table|nil Configuration {fadeInDuration, fadeOutDuration, fromAlpha, toAlpha}
--- @return table The fade controller
function MedaUI:CreateFadeEffect(frame, config)
    config = config or {}

    local fade = {
        frame = frame,
        fadeInDuration = config.fadeInDuration or 0.2,
        fadeOutDuration = config.fadeOutDuration or 0.3,
        fromAlpha = config.fromAlpha or 0,
        toAlpha = config.toAlpha or 1,
    }

    -- Create animation groups
    fade.fadeInGroup = frame:CreateAnimationGroup()
    local fadeInAnim = fade.fadeInGroup:CreateAnimation("Alpha")
    fadeInAnim:SetFromAlpha(fade.fromAlpha)
    fadeInAnim:SetToAlpha(fade.toAlpha)
    fadeInAnim:SetDuration(fade.fadeInDuration)
    fadeInAnim:SetSmoothing("OUT")

    fade.fadeInGroup:SetScript("OnPlay", function()
        frame:Show()
    end)

    fade.fadeInGroup:SetScript("OnFinished", function()
        frame:SetAlpha(fade.toAlpha)
    end)

    fade.fadeOutGroup = frame:CreateAnimationGroup()
    local fadeOutAnim = fade.fadeOutGroup:CreateAnimation("Alpha")
    fadeOutAnim:SetFromAlpha(fade.toAlpha)
    fadeOutAnim:SetToAlpha(fade.fromAlpha)
    fadeOutAnim:SetDuration(fade.fadeOutDuration)
    fadeOutAnim:SetSmoothing("IN")

    fade.fadeOutGroup:SetScript("OnFinished", function()
        frame:SetAlpha(fade.fromAlpha)
        frame:Hide()
    end)

    --- Fade the frame in
    function fade:FadeIn()
        self.fadeOutGroup:Stop()
        self.fadeInGroup:Play()
    end

    --- Fade the frame out
    function fade:FadeOut()
        self.fadeInGroup:Stop()
        self.fadeOutGroup:Play()
    end

    --- Set fade durations
    --- @param fadeIn number Fade in duration in seconds
    --- @param fadeOut number Fade out duration in seconds
    function fade:SetDurations(fadeIn, fadeOut)
        self.fadeInDuration = fadeIn
        self.fadeOutDuration = fadeOut
        fadeInAnim:SetDuration(fadeIn)
        fadeOutAnim:SetDuration(fadeOut)
    end

    return fade
end

--- Create a highlight effect that appears on hover
--- @param frame Frame The frame to apply the highlight to
--- @param config table|nil Configuration {color, alpha}
--- @return table The highlight effect controller
function MedaUI:CreateHoverHighlight(frame, config)
    config = config or {}

    local highlight = {
        frame = frame,
        color = config.color or MedaUI.Theme.highlight,
        alpha = config.alpha or 0.3,
    }

    -- Create highlight texture
    highlight.texture = frame:CreateTexture(nil, "HIGHLIGHT")
    highlight.texture:SetAllPoints()
    local color = highlight.color
    highlight.texture:SetColorTexture(color[1], color[2], color[3], highlight.alpha)

    --- Set the highlight color
    --- @param r number Red (0-1)
    --- @param g number Green (0-1)
    --- @param b number Blue (0-1)
    function highlight:SetColor(r, g, b)
        self.color = { r, g, b, 1 }
        self.texture:SetColorTexture(r, g, b, self.alpha)
    end

    --- Set the highlight alpha
    --- @param alpha number Alpha (0-1)
    function highlight:SetAlpha(alpha)
        self.alpha = alpha
        self.texture:SetColorTexture(self.color[1], self.color[2], self.color[3], alpha)
    end

    return highlight
end
