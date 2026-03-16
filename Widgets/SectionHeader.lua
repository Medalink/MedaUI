--[[
    MedaUI SectionHeader Widget
    Creates labeled section dividers with gradient underline
]]

local MedaUI = LibStub("MedaUI-2.0")
---@cast MedaUI MedaUILibrary
local Pixel = LibStub("MedaUI-2.0").Pixel

--- Create a themed section header with gold text and gradient underline
--- @param parent Frame The parent frame
--- @param text string Header text
--- @param width number|nil Width of the underline (default: 280)
--- @return Frame The container frame (with .header and .line properties)
function MedaUI.CreateSectionHeader(_, parent, text, width)
    width = width or 280

    -- Container for theme management
    local container = CreateFrame("Frame", nil, parent)
    Pixel.SetSize(container, width, 32)

    -- Header text
    local header = Pixel.CreateFontString(container, text)
    Pixel.SetPoint(header, "TOPLEFT", 0, 0)

    -- Gradient line (2px height)
    local line = container:CreateTexture(nil, "ARTWORK")
    Pixel.SetPoint(line, "TOPLEFT", header, "BOTTOMLEFT", 0, -4)
    Pixel.SetSize(line, width, 2)

    -- Apply theme colors
    local function ApplyTheme()
        local theme = MedaUI.Theme
        header:SetTextColor(unpack(theme.gold))

        -- Apply gradient to line if available, with fallback
        if theme.sectionGradientStart and theme.sectionGradientEnd and line.SetGradient then
            line:SetColorTexture(1, 1, 1, 1)  -- Base white texture for gradient
            local success = pcall(function()
                line:SetGradient("HORIZONTAL", {
                    r = theme.sectionGradientStart[1],
                    g = theme.sectionGradientStart[2],
                    b = theme.sectionGradientStart[3],
                    a = theme.sectionGradientStart[4],
                }, {
                    r = theme.sectionGradientEnd[1],
                    g = theme.sectionGradientEnd[2],
                    b = theme.sectionGradientEnd[3],
                    a = theme.sectionGradientEnd[4],
                })
            end)
            if not success then
                -- Fallback if SetGradient fails
                line:SetColorTexture(unpack(theme.gold))
            end
        else
            -- Fallback to solid gold color
            line:SetColorTexture(unpack(theme.gold))
        end
    end
    container._ApplyTheme = ApplyTheme

    -- Register for theme updates
    container._themeHandle = MedaUI:RegisterThemedWidget(container, ApplyTheme)

    -- Initial theme application
    ApplyTheme()

    -- Store references
    container.header = header
    container.line = line

    --- Set the header text
    --- @param newText string The new header text
    function container:SetText(newText)
        self.header:SetText(newText)
    end

    --- Get the header text
    --- @return string The header text
    function container:GetText()
        return self.header:GetText()
    end

    --- Set the line width
    --- @param newWidth number The new line width
    function container:SetLineWidth(newWidth)
        Pixel.SetWidth(self.line, newWidth)
        Pixel.SetWidth(self, newWidth)
    end

    return container
end
