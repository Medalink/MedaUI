--[[
    MedaUI SectionHeader Widget
    Creates labeled section dividers with gold text and underline
]]

local MedaUI = LibStub("MedaUI-1.0")

--- Create a themed section header with gold text and underline
--- @param parent Frame The parent frame
--- @param text string Header text
--- @param width number|nil Width of the underline (default: 280)
--- @return FontString, Texture The header text and separator line
function MedaUI:CreateSectionHeader(parent, text, width)
    width = width or 280

    -- Container for theme management
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width, 24)

    -- Header text
    local header = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetText(text)

    -- Separator line
    local line = container:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
    line:SetSize(width, 1)

    -- Apply theme colors
    local function ApplyTheme()
        local Theme = MedaUI.Theme
        header:SetTextColor(unpack(Theme.gold))
        line:SetColorTexture(unpack(Theme.border))
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
