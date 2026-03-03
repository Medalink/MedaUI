--[[
    MedaUI SectionHeader Widget
    Creates labeled section dividers with gradient underline
]]

local MedaUI = LibStub("MedaUI-1.0")
local AF = _G.AbstractFramework

--- Create a themed section header with gold text and gradient underline
--- @param parent Frame The parent frame
--- @param text string Header text
--- @param width number|nil Width of the underline (default: 280)
--- @return Frame The container frame (with .header and .line properties)
function MedaUI:CreateSectionHeader(parent, text, width)
    width = width or 280

    local Theme = self.Theme

    -- Container for theme management
    local container = CreateFrame("Frame", nil, parent)
    AF.SetSize(container, width, 32)

    -- Header text
    local header = AF.CreateFontString(container, text)
    AF.SetPoint(header, "TOPLEFT", 0, 0)

    -- Gradient line (2px height)
    local line = container:CreateTexture(nil, "ARTWORK")
    AF.SetPoint(line, "TOPLEFT", header, "BOTTOMLEFT", 0, -4)
    AF.SetSize(line, width, 2)

    -- Apply theme colors
    local function ApplyTheme()
        local Theme = MedaUI.Theme
        header:SetTextColor(unpack(Theme.gold))

        -- Apply gradient to line if available, with fallback
        if Theme.sectionGradientStart and Theme.sectionGradientEnd and line.SetGradient then
            line:SetColorTexture(1, 1, 1, 1)  -- Base white texture for gradient
            local success = pcall(function()
                line:SetGradient("HORIZONTAL", {
                    r = Theme.sectionGradientStart[1],
                    g = Theme.sectionGradientStart[2],
                    b = Theme.sectionGradientStart[3],
                    a = Theme.sectionGradientStart[4],
                }, {
                    r = Theme.sectionGradientEnd[1],
                    g = Theme.sectionGradientEnd[2],
                    b = Theme.sectionGradientEnd[3],
                    a = Theme.sectionGradientEnd[4],
                })
            end)
            if not success then
                -- Fallback if SetGradient fails
                line:SetColorTexture(unpack(Theme.gold))
            end
        else
            -- Fallback to solid gold color
            line:SetColorTexture(unpack(Theme.gold))
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
        AF.SetWidth(self.line, newWidth)
        AF.SetWidth(self, newWidth)
    end

    return container
end
