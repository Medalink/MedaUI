local MedaUI = LibStub("MedaUI-1.0")
local Pixel = {}
MedaUI.Pixel = Pixel

local floor, ceil, abs = math.floor, math.ceil, math.abs
local max, min = math.max, math.min
local select, type = select, type
local Mixin, CreateFrame = Mixin, CreateFrame
local GetPhysicalScreenSize = GetPhysicalScreenSize
local GetCursorPosition = GetCursorPosition

-- ============================================================================
-- Pixel-Snapping Core
-- ============================================================================

local cachedPixelFactor
local function GetPixelFactor()
    if cachedPixelFactor then return cachedPixelFactor end
    local _, h = GetPhysicalScreenSize()
    cachedPixelFactor = 768.0 / h
    return cachedPixelFactor
end

-- Invalidate cache when display size or UI scale changes
local scaleWatcher = CreateFrame("Frame")
scaleWatcher:RegisterEvent("UI_SCALE_CHANGED")
scaleWatcher:RegisterEvent("DISPLAY_SIZE_CHANGED")
scaleWatcher:SetScript("OnEvent", function()
    cachedPixelFactor = nil
end)

local function Round(n)
    return n < 0 and ceil(n - 0.5) or floor(n + 0.5)
end

local function Snap(size, scale, minPx)
    if size == 0 and (not minPx or minPx == 0) then return 0 end
    local f = GetPixelFactor()
    local px = Round((size * scale) / f)
    if minPx then
        if size < 0 then
            if px > -minPx then px = -minPx end
        else
            if px < minPx then px = minPx end
        end
    end
    return px * f / scale
end

local function Clamp(value, lo, hi)
    if lo > hi then lo, hi = hi, lo end
    if value < lo then return lo end
    if value > hi then return hi end
    return value
end

-- ============================================================================
-- Layout Functions
-- ============================================================================

function Pixel.SetWidth(region, width, minPx)
    region:SetWidth(Snap(width, region:GetEffectiveScale(), minPx))
end

function Pixel.SetHeight(region, height, minPx)
    region:SetHeight(Snap(height, region:GetEffectiveScale(), minPx))
end

function Pixel.SetSize(region, width, height)
    if width then Pixel.SetWidth(region, width) end
    if height then Pixel.SetHeight(region, height) end
end

function Pixel.SetPoint(region, ...)
    local point, relativeTo, relativePoint, offsetX, offsetY

    local n = select("#", ...)
    if n == 1 then
        point = ...
    elseif n == 2 then
        if type(select(2, ...)) == "number" then
            point, offsetX = ...
        else
            point, relativeTo = ...
        end
    elseif n == 3 then
        if type(select(2, ...)) == "number" then
            point, offsetX, offsetY = ...
        else
            point, relativeTo, relativePoint = ...
        end
    elseif n == 4 then
        point, relativeTo, offsetX, offsetY = ...
    else
        point, relativeTo, relativePoint, offsetX, offsetY = ...
    end

    offsetX = offsetX or 0
    offsetY = offsetY or 0
    relativeTo = relativeTo or region:GetParent()
    relativePoint = relativePoint or point

    local scale = region:GetEffectiveScale()
    region:SetPoint(point, relativeTo, relativePoint,
        Snap(offsetX, scale), Snap(offsetY, scale))
end

function Pixel.ClearPoints(region)
    region:ClearAllPoints()
end

-- ============================================================================
-- Font Factory
-- ============================================================================

function Pixel.CreateFontString(parent, text, font, layer)
    local fs = parent:CreateFontString(nil, layer or "OVERLAY")
    fs:SetFontObject(font or "GameFontHighlightSmall")
    if text then fs:SetText(text) end
    return fs
end

-- ============================================================================
-- Frame Factory
-- ============================================================================

local PLAIN_TEXTURE = "Interface\\Buttons\\WHITE8x8"
local DEFAULT_BACKDROP = {
    bgFile = PLAIN_TEXTURE,
    edgeFile = PLAIN_TEXTURE,
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

local function ResolveColor(c, fallback)
    if c == "none" then return 0, 0, 0, 0 end
    if type(c) == "table" then return unpack(c) end
    return unpack(fallback)
end

function Pixel.CreateBorderedFrame(parent, name, width, height, color, borderColor)
    local f = CreateFrame("Frame", name, parent, "BackdropTemplate")
    f:SetBackdrop(DEFAULT_BACKDROP)

    local r, g, b, a = ResolveColor(color, { 0.1, 0.1, 0.1, 0.9 })
    f:SetBackdropColor(r, g, b, a)

    r, g, b, a = ResolveColor(borderColor, { 0.3, 0.3, 0.3, 1 })
    f:SetBackdropBorderColor(r, g, b, a)

    if width and height then Pixel.SetSize(f, width, height) end
    return f
end

-- ============================================================================
-- Scroll Frame
-- ============================================================================

local MIN_SCROLL_THUMB_HEIGHT = 20

local UpdateScrollThumb
local UpdateScrollFrameAnchor

local ScrollFrameMixin = {}

function ScrollFrameMixin:ResetHeight()
    Pixel.SetHeight(self.scrollContent, 1)
end

function ScrollFrameMixin:ResetScroll()
    self.scrollFrame:SetVerticalScroll(0)
end

function ScrollFrameMixin:GetVerticalScrollRange()
    local range = self.scrollContent:GetHeight() - self.scrollFrame:GetHeight()
    return range > 0 and range or 0
end

function ScrollFrameMixin:CanScroll()
    return self:GetVerticalScrollRange() > 0
end

function ScrollFrameMixin:VerticalScroll(step)
    local scroll = self.scrollFrame:GetVerticalScroll() + step
    scroll = Clamp(scroll, 0, self:GetVerticalScrollRange())
    self.scrollFrame:SetVerticalScroll(scroll)
    UpdateScrollThumb(self.scrollFrame)
end

function ScrollFrameMixin:ScrollToBottom()
    self.scrollFrame:SetVerticalScroll(self:GetVerticalScrollRange())
end

function ScrollFrameMixin:SetContentHeight(height, useRawValue, skipScrollReset)
    if useRawValue then
        self.scrollContent:SetHeight(height)
    else
        Pixel.SetHeight(self.scrollContent, height)
    end
    if not skipScrollReset then
        self:ResetScroll()
    end
end

function ScrollFrameMixin:SetScrollStep(step)
    self.step = step or 50
end

function ScrollFrameMixin:GetScrollStep()
    return self.step
end

function ScrollFrameMixin:SetScroll(offset)
    self.scrollFrame:SetVerticalScroll(Clamp(offset, 0, self:GetVerticalScrollRange()))
end

function ScrollFrameMixin:GetScroll()
    return self.scrollFrame:GetVerticalScroll()
end

function ScrollFrameMixin:Reset()
    local children = { self.scrollContent:GetChildren() }
    for _, c in pairs(children) do
        c:ClearAllPoints()
        c:Hide()
    end
    self:ResetHeight()
    self:ResetScroll()
end

function ScrollFrameMixin:EnableScroll(enabled)
    self:EnableMouseWheel(enabled and true or false)
end

function ScrollFrameMixin:DisableScrollFrameReanchor(disabled)
    self.disableScrollFrameReanchor = disabled
    UpdateScrollFrameAnchor(self)
end

UpdateScrollThumb = function(scrollFrame)
    local scrollParent = scrollFrame:GetParent()
    local scrollBar = scrollParent.scrollBar
    local scrollThumb = scrollParent.scrollThumb

    if scrollParent:GetVerticalScrollRange() ~= 0 then
        local scrollP = scrollFrame:GetVerticalScroll() / scrollParent:GetVerticalScrollRange()
        local offsetY = -((scrollBar:GetHeight() - scrollThumb:GetHeight()) * scrollP)
        scrollThumb:SetPoint("TOP", 0, offsetY)
    else
        scrollThumb:SetPoint("TOP")
    end
end

UpdateScrollFrameAnchor = function(self)
    if self.disableScrollFrameReanchor or not self:CanScroll() then
        Pixel.SetPoint(self.scrollFrame, "BOTTOMRIGHT")
    else
        Pixel.SetPoint(self.scrollFrame, "BOTTOMRIGHT", -7, 0)
    end
end

local function ScrollContent_OnSizeChanged(scrollContent)
    local scrollFrame = scrollContent:GetParent()
    local scrollParent = scrollFrame:GetParent()
    local scrollBar = scrollParent.scrollBar
    local scrollThumb = scrollParent.scrollThumb

    local p = scrollFrame:GetHeight() / scrollContent:GetHeight()
    p = floor(p * 1000 + 0.5) / 1000
    if p < 1 then
        local height = max(scrollBar:GetHeight() * p, MIN_SCROLL_THUMB_HEIGHT)
        scrollThumb:SetHeight(height)
        UpdateScrollThumb(scrollFrame)
        scrollBar:Show()
        scrollParent:SetScroll(scrollFrame:GetVerticalScroll())
    else
        scrollBar:Hide()
        scrollParent:SetScroll(0)
    end

    UpdateScrollFrameAnchor(scrollParent)
end

local function ScrollFrame_OnSizeChanged(scrollFrame)
    local scrollContent = scrollFrame:GetScrollChild()
    local oldWidth = scrollContent:GetWidth()
    local newWidth = scrollFrame:GetWidth()
    if abs(oldWidth - newWidth) <= 0.01 then
        ScrollContent_OnSizeChanged(scrollContent)
    else
        scrollContent:SetWidth(newWidth)
    end
end

local function ScrollThumb_OnEnter(self)
    self:SetBackdropColor(self.r, self.g, self.b, 0.9)
end

local function ScrollThumb_OnLeave(self)
    self:SetBackdropColor(self.r, self.g, self.b, 0.7)
end

local function ScrollThumb_OnMouseDown(scrollThumb, button)
    if button ~= "LeftButton" then return end

    local scrollParent = scrollThumb:GetParent():GetParent()
    local scrollBar = scrollParent.scrollBar

    local offsetY = select(5, scrollThumb:GetPoint(1))
    local mouseY = select(2, GetCursorPosition())
    local scale = scrollThumb:GetEffectiveScale()
    local maxOffsetY = scrollBar:GetHeight() - scrollThumb:GetHeight()

    scrollThumb:SetScript("OnUpdate", function()
        local newMouseY = select(2, GetCursorPosition())
        local newOffsetY = offsetY + (newMouseY - mouseY) / scale

        if newOffsetY >= 0 then
            newOffsetY = 0
        elseif -newOffsetY >= maxOffsetY then
            newOffsetY = -maxOffsetY
        end

        local vs = (-newOffsetY / maxOffsetY) * scrollParent:GetVerticalScrollRange()
        scrollParent.scrollFrame:SetVerticalScroll(vs)
    end)
end

local function ScrollThumb_OnMouseUp(scrollThumb)
    scrollThumb:SetScript("OnUpdate", nil)
end

local function ScrollParent_OnMouseWheel(self, delta)
    local step = Snap(self.step, self:GetEffectiveScale())
    if delta == 1 then
        self:VerticalScroll(-step)
    elseif delta == -1 then
        self:VerticalScroll(step)
    end
end

function Pixel.CreateScrollFrame(parent, name, width, height, color, borderColor)
    local scrollParent = Pixel.CreateBorderedFrame(parent, name, width, height, color, borderColor)

    local scrollFrame = CreateFrame("ScrollFrame", nil, scrollParent, "BackdropTemplate")
    scrollParent.scrollFrame = scrollFrame
    Pixel.SetPoint(scrollFrame, "TOPLEFT")
    Pixel.SetPoint(scrollFrame, "BOTTOMRIGHT")

    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollParent.scrollContent = scrollContent
    scrollContent:SetHeight(1)
    scrollContent:SetWidth(scrollFrame:GetWidth())
    scrollFrame:SetScrollChild(scrollContent)

    local scrollBar = Pixel.CreateBorderedFrame(scrollParent, nil, 5, nil, color, borderColor)
    scrollParent.scrollBar = scrollBar
    Pixel.SetPoint(scrollBar, "TOPRIGHT")
    Pixel.SetPoint(scrollBar, "BOTTOMRIGHT")
    scrollBar:Hide()

    local scrollThumb = Pixel.CreateBorderedFrame(scrollBar, nil, 5, nil, { 0.9, 0.7, 0.15, 0.8 })
    scrollParent.scrollThumb = scrollThumb
    Pixel.SetPoint(scrollThumb, "TOP")
    scrollThumb:EnableMouse(true)
    scrollThumb:SetMovable(true)
    scrollThumb:SetHitRectInsets(-5, -5, 0, 0)

    scrollThumb.r, scrollThumb.g, scrollThumb.b = 0.9, 0.7, 0.15
    scrollThumb:SetScript("OnEnter", ScrollThumb_OnEnter)
    scrollThumb:SetScript("OnLeave", ScrollThumb_OnLeave)

    Mixin(scrollParent, ScrollFrameMixin)

    scrollFrame:SetScript("OnSizeChanged", ScrollFrame_OnSizeChanged)
    scrollFrame:SetScript("OnVerticalScroll", UpdateScrollThumb)
    scrollContent:SetScript("OnSizeChanged", ScrollContent_OnSizeChanged)

    scrollThumb:SetScript("OnMouseDown", ScrollThumb_OnMouseDown)
    scrollThumb:SetScript("OnMouseUp", ScrollThumb_OnMouseUp)

    scrollParent:SetScrollStep()
    scrollParent:EnableMouseWheel(true)
    scrollParent:SetScript("OnMouseWheel", ScrollParent_OnMouseWheel)

    return scrollParent
end
