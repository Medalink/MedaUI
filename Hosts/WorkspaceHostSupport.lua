local MedaUI = LibStub("MedaUI-2.0")
---@cast MedaUI MedaUILibrary
local Pixel = MedaUI.Pixel

local WorkspaceHostSupport = MedaUI.WorkspaceHostSupport or {}
MedaUI.WorkspaceHostSupport = WorkspaceHostSupport

local function SafeColor(color, fallback)
    return color or fallback or { 1, 1, 1, 1 }
end

local function GetDisplayText(source)
    if source and source.detailText and source.detailText ~= "" then
        return source.detailText
    end

    return WorkspaceHostSupport.GetRelativeTime(source and source.lastFetched)
end

function WorkspaceHostSupport.GetFreshnessState(lastFetched)
    if not lastFetched or lastFetched == 0 then
        return "unknown"
    end

    local age = time() - lastFetched
    if age < 86400 then
        return "fresh"
    end
    if age < 86400 * 3 then
        return "aging"
    end
    return "stale"
end

function WorkspaceHostSupport.GetRelativeTime(lastFetched)
    if not lastFetched or lastFetched == 0 then
        return "unknown"
    end

    local diff = time() - lastFetched
    if diff < 0 then
        return "just now"
    end

    local days = math.floor(diff / 86400)
    local hours = math.floor((diff % 86400) / 3600)
    local mins = math.floor((diff % 3600) / 60)
    if days > 0 then return string.format("%dd ago", days) end
    if hours > 0 then return string.format("%dhr ago", hours) end
    if mins > 0 then return string.format("%dm ago", mins) end
    return "just now"
end

function WorkspaceHostSupport.CreateFreshnessStrip(parent, width)
    local strip = CreateFrame("Frame", nil, parent)
    ---@cast strip WorkspaceFreshnessStrip
    Pixel.SetSize(strip, width or 400, 86)
    strip.sources = {}
    strip.rows = {}

    local divider = strip:CreateTexture(nil, "ARTWORK")
    ---@cast divider Texture
    strip.divider = divider
    Pixel.SetHeight(strip.divider, 1)
    Pixel.SetPoint(strip.divider, "TOPLEFT", strip, "TOPLEFT", 0, 0)
    Pixel.SetPoint(strip.divider, "TOPRIGHT", strip, "TOPRIGHT", 0, 0)

    local label = strip:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ---@cast label FontString
    strip.label = label
    Pixel.SetPoint(strip.label, "TOPLEFT", 8, -8)
    strip.label:SetText("Data Freshness")

    strip.listHost = CreateFrame("Frame", nil, strip)
    Pixel.SetPoint(strip.listHost, "TOPLEFT", strip, "TOPLEFT", 8, -24)
    Pixel.SetPoint(strip.listHost, "BOTTOMRIGHT", strip, "BOTTOMRIGHT", -8, 4)

    local function ApplyTheme()
        local theme = MedaUI.Theme
        strip.divider:SetColorTexture(unpack(theme.divider or { 1, 1, 1, 0.08 }))
        strip.label:SetTextColor(unpack(theme.textDim or { 0.6, 0.6, 0.6, 1 }))
        for _, row in ipairs(strip.rows) do
            if row._applyState then
                row:_applyState()
            end
        end
    end

    MedaUI:RegisterThemedWidget(strip, ApplyTheme)
    ApplyTheme()

    local function AcquireRow(index)
        local row = strip.rows[index]
        if row then
            return row
        end

        local newRow = CreateFrame("Frame", nil, strip.listHost)
        ---@cast newRow WorkspaceFreshnessRow
        Pixel.SetHeight(newRow, 16)
        local rowText = newRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        ---@cast rowText FontString
        newRow.text = rowText
        Pixel.SetPoint(newRow.text, "TOPLEFT", newRow, "TOPLEFT", 0, 0)
        Pixel.SetPoint(newRow.text, "TOPRIGHT", newRow, "TOPRIGHT", 0, 0)
        newRow.text:SetJustifyH("LEFT")
        newRow.text:SetWordWrap(false)
        function newRow:_applyState()
            local theme = MedaUI.Theme
            local sourceColor = SafeColor(self.sourceColor, theme.gold)
            local textColor = theme.textDim or { 0.55, 0.55, 0.55, 1 }
            if self.state == "aging" then
                sourceColor = theme.warning or { 1, 0.7, 0.2, 1 }
            elseif self.state == "stale" then
                sourceColor = theme.error or { 1, 0.3, 0.3, 1 }
            end

            self.text:SetTextColor(unpack(textColor))
            self.text:SetText(string.format("|cff%02x%02x%02x%s|r: %s",
                math.floor(sourceColor[1] * 255),
                math.floor(sourceColor[2] * 255),
                math.floor(sourceColor[3] * 255),
                string.lower((self.source and self.source.label) or (self.source and self.source.id) or "unknown"),
                GetDisplayText(self.source)
            ))
        end

        strip.rows[index] = newRow
        return newRow
    end

    function strip:SetSources(sources)
        self.sources = sources or {}
        local y = 0
        for index, source in ipairs(self.sources) do
            local row = AcquireRow(index)
            row:Show()
            row.state = WorkspaceHostSupport.GetFreshnessState(source.lastFetched)
            row.sourceColor = source.color
            row.source = source
            Pixel.SetPoint(row, "TOPLEFT", self.listHost, "TOPLEFT", 0, y)
            Pixel.SetPoint(row, "TOPRIGHT", self.listHost, "TOPRIGHT", 0, y)
            row:_applyState()
            y = y - 18
        end

        for index = #self.sources + 1, #self.rows do
            self.rows[index]:Hide()
        end
    end

    return strip
end
