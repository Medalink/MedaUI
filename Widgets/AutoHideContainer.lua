--[[
    MedaUI AutoHideContainer Widget
    Container that fades in on hover, fades out on leave
]]

local MedaUI = LibStub("MedaUI-1.0")

--- Create an auto-hiding container
--- @param name string Unique frame name
--- @param config table|nil Configuration {fadeInDuration, fadeOutDuration, hideDelay, locked, width, height}
--- @return table The auto-hide container widget
function MedaUI:CreateAutoHideContainer(name, config)
    config = config or {}

    -- Create hitbox (always present for hover detection)
    local hitbox = CreateFrame("Frame", name .. "Hitbox", UIParent)
    hitbox:SetSize(config.width or 100, config.height or 100)
    hitbox:SetFrameStrata("MEDIUM")
    hitbox:SetFrameLevel(1)
    hitbox:EnableMouse(true)

    -- Create visible container
    local container = CreateFrame("Frame", name, hitbox, "BackdropTemplate")
    container:SetAllPoints()
    container:SetFrameStrata("MEDIUM")
    container:SetFrameLevel(5)
    container:SetBackdrop(MedaUI:CreateBackdrop(true))

    local Theme = self.Theme

    -- Create content area
    local content = CreateFrame("Frame", nil, container)
    content:SetPoint("TOPLEFT", 4, -4)
    content:SetPoint("BOTTOMRIGHT", -4, 4)

    -- State
    container.hitbox = hitbox
    container.content = content
    container.isHovered = false
    container.isLocked = not (config.locked == false)  -- Default to locked (auto-hide mode)
    container.fadeInDuration = config.fadeInDuration or 0.15
    container.fadeOutDuration = config.fadeOutDuration or 0.2
    container.hideDelay = config.hideDelay or 0.5
    container.fadeOutTimer = nil
    container.fadeIn = nil
    container.fadeOut = nil

    -- Callbacks
    container.OnShow = nil
    container.OnHide = nil
    container.OnMove = nil

    -- Setup animations
    local function SetupAnimations()
        -- Fade in animation
        container.fadeIn = container:CreateAnimationGroup()
        local fadeInAlpha = container.fadeIn:CreateAnimation("Alpha")
        fadeInAlpha:SetFromAlpha(0)
        fadeInAlpha:SetToAlpha(1)
        fadeInAlpha:SetDuration(container.fadeInDuration)
        fadeInAlpha:SetSmoothing("OUT")

        container.fadeIn:SetScript("OnPlay", function()
            container:Show()
        end)

        container.fadeIn:SetScript("OnFinished", function()
            container:SetAlpha(1)
            if container.OnShow then
                container:OnShow()
            end
        end)

        -- Fade out animation
        container.fadeOut = container:CreateAnimationGroup()
        local fadeOutAlpha = container.fadeOut:CreateAnimation("Alpha")
        fadeOutAlpha:SetFromAlpha(1)
        fadeOutAlpha:SetToAlpha(0)
        fadeOutAlpha:SetDuration(container.fadeOutDuration)
        fadeOutAlpha:SetSmoothing("IN")

        container.fadeOut:SetScript("OnFinished", function()
            container:SetAlpha(0)
            container:Hide()
            if container.OnHide then
                container:OnHide()
            end
        end)
    end
    SetupAnimations()

    -- Mouse enter handler
    local function OnMouseEnter()
        container.isHovered = true

        -- Cancel any pending fade out
        if container.fadeOutTimer then
            container.fadeOutTimer:Cancel()
            container.fadeOutTimer = nil
        end

        -- Show if in auto-hide mode (locked)
        if container.isLocked then
            container.fadeOut:Stop()
            container.fadeIn:Play()
        end
    end

    -- Mouse leave handler
    local function OnMouseLeave()
        -- Check if mouse is still over hitbox or container
        if hitbox:IsMouseOver() or container:IsMouseOver() then
            return
        end

        container.isHovered = false

        -- Start fade out timer if in auto-hide mode
        if container.isLocked then
            if container.fadeOutTimer then
                container.fadeOutTimer:Cancel()
            end

            container.fadeOutTimer = C_Timer.NewTimer(container.hideDelay, function()
                -- Double-check mouse is still not over
                if not hitbox:IsMouseOver() and not container:IsMouseOver() then
                    container.fadeIn:Stop()
                    container.fadeOut:Play()
                end
                container.fadeOutTimer = nil
            end)
        end
    end

    -- Setup hover scripts
    hitbox:SetScript("OnEnter", OnMouseEnter)
    hitbox:SetScript("OnLeave", OnMouseLeave)
    container:SetScript("OnEnter", OnMouseEnter)
    container:SetScript("OnLeave", OnMouseLeave)

    -- Apply theme
    local function ApplyTheme()
        local Theme = MedaUI.Theme
        container:SetBackdropColor(unpack(Theme.background))
        container:SetBackdropBorderColor(unpack(Theme.border))
    end
    container._ApplyTheme = ApplyTheme
    container._themeHandle = MedaUI:RegisterThemedWidget(container, ApplyTheme)
    ApplyTheme()

    --- Set locked state (auto-hide mode)
    --- @param locked boolean When true, container auto-hides; when false, always visible
    function container:SetLocked(locked)
        self.isLocked = locked

        if locked then
            -- Auto-hide mode: hide unless hovered
            if not self.isHovered then
                self:SetAlpha(0)
                self:Hide()
            end
        else
            -- Always visible mode
            self.fadeIn:Stop()
            self.fadeOut:Stop()

            if self.fadeOutTimer then
                self.fadeOutTimer:Cancel()
                self.fadeOutTimer = nil
            end

            self:SetAlpha(1)
            self:Show()
        end
    end

    --- Get locked state
    --- @return boolean Whether container is in auto-hide mode
    function container:IsLocked()
        return self.isLocked
    end

    --- Get the content frame (for adding child elements)
    --- @return Frame The content frame
    function container:GetContent()
        return self.content
    end

    --- Get the hitbox frame
    --- @return Frame The hitbox frame
    function container:GetHitbox()
        return self.hitbox
    end

    --- Set container size
    --- @param width number Container width
    --- @param height number Container height
    function container:SetContainerSize(width, height)
        self.hitbox:SetSize(width, height)
    end

    --- Set fade durations
    --- @param fadeIn number Fade in duration in seconds
    --- @param fadeOut number Fade out duration in seconds
    function container:SetFadeDurations(fadeIn, fadeOut)
        self.fadeInDuration = fadeIn
        self.fadeOutDuration = fadeOut
        -- Recreate animations with new durations
        SetupAnimations()
    end

    --- Set hide delay
    --- @param delay number Delay before hiding in seconds
    function container:SetHideDelay(delay)
        self.hideDelay = delay
    end

    --- Enable dragging
    --- @param saveCallback function|nil Callback with position data when drag stops
    function container:EnableDragging(saveCallback)
        hitbox:SetMovable(true)
        hitbox:RegisterForDrag("LeftButton")

        hitbox:SetScript("OnDragStart", function(frame)
            if not self.isLocked then
                frame:StartMoving()
            end
        end)

        hitbox:SetScript("OnDragStop", function(frame)
            frame:StopMovingOrSizing()
            if saveCallback then
                local point, _, relPoint, x, y = frame:GetPoint()
                saveCallback({
                    point = point,
                    relativePoint = relPoint,
                    x = x,
                    y = y,
                })
            end
            if self.OnMove then
                local point, _, relPoint, x, y = frame:GetPoint()
                self:OnMove({ point = point, relativePoint = relPoint, x = x, y = y })
            end
        end)

        -- Also allow dragging from container
        container:SetScript("OnMouseDown", function(frame, button)
            if button == "LeftButton" and not self.isLocked then
                hitbox:StartMoving()
            end
        end)

        container:SetScript("OnMouseUp", function(frame, button)
            if button == "LeftButton" then
                hitbox:StopMovingOrSizing()
                if saveCallback then
                    local point, _, relPoint, x, y = hitbox:GetPoint()
                    saveCallback({
                        point = point,
                        relativePoint = relPoint,
                        x = x,
                        y = y,
                    })
                end
            end
        end)
    end

    --- Set position
    --- @param point string Anchor point
    --- @param relativeTo Frame|string|nil Relative frame
    --- @param relativePoint string|nil Relative point
    --- @param x number X offset
    --- @param y number Y offset
    function container:SetContainerPosition(point, relativeTo, relativePoint, x, y)
        hitbox:ClearAllPoints()
        if type(relativeTo) == "string" then
            relativeTo = _G[relativeTo] or UIParent
        end
        hitbox:SetPoint(point, relativeTo, relativePoint or point, x, y)
    end

    --- Show the container (force)
    function container:ForceShow()
        hitbox:Show()
        self:SetAlpha(1)
        self:Show()
    end

    --- Hide the container (force)
    function container:ForceHide()
        hitbox:Hide()
        self:Hide()
    end

    -- Initial state based on lock setting
    if container.isLocked then
        container:SetAlpha(0)
        container:Hide()
    end

    return container
end
