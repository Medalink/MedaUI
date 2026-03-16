--[[
    MedaUI EventTimeline Widget
    Vertical timestamped event timeline with markers, connecting line, and scroll.
    Each entry shows a timestamp, a colored marker dot, and descriptive text.
]]

local MedaUI = LibStub("MedaUI-2.0")
---@cast MedaUI MedaUILibrary
local Pixel = LibStub("MedaUI-2.0").Pixel

local DEFAULT_MARKER_SIZE = 10
local DEFAULT_LINE_WIDTH = 2
local TIMESTAMP_WIDTH = 44
local ENTRY_HEIGHT = 28
local LINE_GAP = 4
local TEXT_LEFT_PAD = 8

local floor = math.floor
local format = string.format

local function DefaultFormatTimestamp(seconds)
    local s = floor(seconds)
    return format("%d:%02d", floor(s / 60), s % 60)
end

--- Create a vertical event timeline.
--- @param parent Frame Parent frame
--- @param width number Timeline width
--- @param height number Timeline height
--- @param config table|nil Configuration
--- @return Frame The event timeline widget
---
--- Config keys:
---   markerSize       (number, default 10) -- marker dot diameter
---   lineWidth        (number, default 2)  -- connecting line width
---   renderEntry      (function|nil)       -- custom renderer function(entryFrame, data, index)
---   formatTimestamp   (function|nil)       -- function(seconds) -> string
function MedaUI.CreateEventTimeline(library, parent, width, height, config)
    config = config or {}
    local markerSize = config.markerSize or DEFAULT_MARKER_SIZE
    local lineWidth = config.lineWidth or DEFAULT_LINE_WIDTH
    local formatTimestamp = config.formatTimestamp or DefaultFormatTimestamp
    local renderEntry = config.renderEntry

    local timeline = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    Pixel.SetSize(timeline, width, height)
    timeline:SetBackdrop(library:CreateBackdrop(true))

    timeline._data = {}
    timeline._entryPool = {}
    timeline._linePool = {}
    timeline._highlightIndex = nil
    timeline._formatTimestamp = formatTimestamp

    -- Scroll frame
    local scrollParent = library:CreateScrollFrame(timeline)
    Pixel.SetPoint(scrollParent, "TOPLEFT", 6, -6)
    Pixel.SetPoint(scrollParent, "BOTTOMRIGHT", -6, 6)
    scrollParent:SetScrollStep(ENTRY_HEIGHT * 3)

    local content = scrollParent.scrollContent
    timeline._content = content
    timeline._scrollParent = scrollParent
    timeline._scrollFrame = scrollParent.scrollFrame

    -- Theme
    local function ApplyTheme()
        local theme = MedaUI.Theme
        timeline:SetBackdropColor(unpack(theme.backgroundDark))
        timeline:SetBackdropBorderColor(unpack(theme.border))
    end
    timeline._ApplyTheme = ApplyTheme
    timeline._themeHandle = MedaUI:RegisterThemedWidget(timeline, function()
        ApplyTheme()
        timeline:_Render()
    end)
    ApplyTheme()

    -- ----------------------------------------------------------------
    -- Entry pool
    -- ----------------------------------------------------------------

    local function GetEntry(index)
        local entry = timeline._entryPool[index]
        if not entry then
            entry = CreateFrame("Frame", nil, content)
            Pixel.SetHeight(entry, ENTRY_HEIGHT)

            -- Timestamp
            entry.timestamp = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            Pixel.SetPoint(entry.timestamp, "LEFT", 4, 0)
            Pixel.SetWidth(entry.timestamp, TIMESTAMP_WIDTH)
            entry.timestamp:SetJustifyH("RIGHT")

            -- Marker dot
            entry.marker = entry:CreateTexture(nil, "ARTWORK")
            Pixel.SetSize(entry.marker, markerSize, markerSize)
            Pixel.SetPoint(entry.marker, "LEFT", TIMESTAMP_WIDTH + TEXT_LEFT_PAD, 0)

            -- Entry text
            entry.text = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            Pixel.SetPoint(entry.text, "LEFT", entry.marker, "RIGHT", TEXT_LEFT_PAD, 0)
            Pixel.SetPoint(entry.text, "RIGHT", entry, "RIGHT", -4, 0)
            entry.text:SetJustifyH("LEFT")
            entry.text:SetWordWrap(false)

            -- Highlight background
            entry.highlight = entry:CreateTexture(nil, "BACKGROUND")
            entry.highlight:SetAllPoints()
            entry.highlight:Hide()

            timeline._entryPool[index] = entry
        end
        return entry
    end

    local function GetLine(index)
        local line = timeline._linePool[index]
        if not line then
            line = content:CreateTexture(nil, "ARTWORK", nil, -1)
            Pixel.SetWidth(line, lineWidth)
            timeline._linePool[index] = line
        end
        return line
    end

    -- ----------------------------------------------------------------
    -- Rendering
    -- ----------------------------------------------------------------

    function timeline:_Render()
        local Theme = MedaUI.Theme
        local data = self._data

        -- Hide all entries and lines
        for _, e in pairs(self._entryPool) do e:Hide() end
        for _, l in pairs(self._linePool) do l:Hide() end

        local totalHeight = #data * ENTRY_HEIGHT
        Pixel.SetHeight(content, math.max(totalHeight, height - 12))

        if #data == 0 then return end

        local lineColor = Theme.textDim or {0.5, 0.5, 0.5, 0.5}
        local markerX = TIMESTAMP_WIDTH + TEXT_LEFT_PAD + (markerSize / 2)

        for i, d in ipairs(data) do
            local entry = GetEntry(i)
            entry:ClearAllPoints()
            Pixel.SetPoint(entry, "TOPLEFT", content, "TOPLEFT", 0, -((i - 1) * ENTRY_HEIGHT))
            Pixel.SetPoint(entry, "RIGHT", content, "RIGHT", 0, 0)

            -- Timestamp
            entry.timestamp:SetText(self._formatTimestamp(d.t or 0))
            entry.timestamp:SetTextColor(unpack(Theme.textDim or {0.6, 0.6, 0.6}))

            -- Marker color
            local color = d.color or Theme.text or {1, 1, 1, 1}
            entry.marker:SetColorTexture(color[1], color[2], color[3], color[4] or 1)

            -- Text
            if renderEntry then
                renderEntry(entry, d, i)
            else
                entry.text:SetText(d.text or "")
                entry.text:SetTextColor(unpack(Theme.text or {1, 1, 1}))
            end

            -- Highlight
            if i == self._highlightIndex then
                entry.highlight:SetColorTexture(unpack(Theme.highlight or {1, 1, 1, 0.07}))
                entry.highlight:Show()
            else
                entry.highlight:Hide()
            end

            entry:Show()

            -- Connecting line to next entry
            if i < #data then
                local line = GetLine(i)
                line:ClearAllPoints()
                line:SetPoint("TOP", entry.marker, "BOTTOM", 0, -LINE_GAP)
                line:SetPoint("BOTTOM", content, "TOPLEFT", markerX, -((i) * ENTRY_HEIGHT) + (ENTRY_HEIGHT / 2) + LINE_GAP)
                line:SetColorTexture(lineColor[1], lineColor[2], lineColor[3], lineColor[4] or 0.4)
                line:Show()
            end
        end
    end

    -- ----------------------------------------------------------------
    -- Public API
    -- ----------------------------------------------------------------

    --- Set timeline data entries.
    --- @param entries table Array of {t = seconds, text = string, color = {r,g,b}, type = string}
    function timeline:SetData(entries)
        self._data = entries or {}
        self:_Render()
    end

    --- Highlight a specific entry by index.
    --- @param index number|nil Index to highlight, nil to clear
    function timeline:SetHighlight(index)
        self._highlightIndex = index
        self:_Render()
    end

    --- Scroll to bring a specific entry into view.
    --- @param index number Entry index
    function timeline:ScrollToEntry(index)
        local scrollPos = (index - 1) * ENTRY_HEIGHT
        self._scrollParent:SetScroll(scrollPos)
    end

    --- Set a custom timestamp formatter.
    --- @param fn function function(seconds) -> string
    function timeline:SetFormatTimestamp(fn)
        self._formatTimestamp = fn or DefaultFormatTimestamp
        self:_Render()
    end

    return timeline
end
