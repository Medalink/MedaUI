--[[
    MedaUI SectionHeader Widget
    Creates labeled section dividers with gradient underline
]]

local MedaUI = LibStub("MedaUI-1.0")

--- Create a themed section header with gold text and gradient underline
--- @param parent Frame The parent frame
--- @param text string Header text
--- @param width number|nil Width of the underline (default: 280)
--- @return FontString, Texture, Frame The header text, separator line, and container
function MedaUI:CreateSectionHeader(parent, text, width)
    width = width or 280

    local Theme = self.Theme

    -- Container for theme management
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width, 32)  -- Increased height for proper spacing

    -- Header text
    local header = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetText(text)

    -- Gradient line (2px height)
    local line = container:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
    line:SetSize(width, 2)

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
        self.line:SetWidth(newWidth)
        self:SetWidth(newWidth)
    end

    -- Return both elements for positioning (backward compatibility)
    -- Also return the container as the third return value for theme registration
    return header, line, container
end
