--[[
    MedaUI SearchBox Widget
    EditBox with search icon, clear button, and debounced search
]]

local MedaUI = LibStub("MedaUI-1.0")

--- Create a search box
--- @param parent Frame Parent frame
--- @param width number Search box width
--- @return Frame The search box frame
function MedaUI:CreateSearchBox(parent, width)
    local searchBox = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    searchBox:SetSize(width, 24)
    searchBox:SetBackdrop(self:CreateBackdrop(true))

    searchBox.OnSearch = nil
    searchBox.debounceTime = 0.3
    searchBox.debounceTimer = nil
    searchBox._hasFocus = false

    -- Search icon (use texture instead of emoji)
    searchBox.icon = searchBox:CreateTexture(nil, "OVERLAY")
    searchBox.icon:SetSize(14, 14)
    searchBox.icon:SetPoint("LEFT", 8, 0)
    searchBox.icon:SetAtlas("common-search-magnifyingglass")
    searchBox.icon:SetDesaturated(true)

    -- Edit box for input
    searchBox.editBox = CreateFrame("EditBox", nil, searchBox)
    searchBox.editBox:SetPoint("LEFT", 26, 0)
    searchBox.editBox:SetPoint("RIGHT", -24, 0)
    searchBox.editBox:SetHeight(20)
    searchBox.editBox:SetFontObject(GameFontNormalSmall)
    searchBox.editBox:SetAutoFocus(false)
    searchBox.editBox:SetMaxLetters(100)

    -- Placeholder text
    searchBox.placeholder = searchBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    searchBox.placeholder:SetPoint("LEFT", searchBox.editBox, "LEFT", 2, 0)
    searchBox.placeholder:SetText("Search...")

    -- Clear button
    searchBox.clearBtn = CreateFrame("Button", nil, searchBox)
    searchBox.clearBtn:SetSize(16, 16)
    searchBox.clearBtn:SetPoint("RIGHT", -6, 0)
    searchBox.clearBtn:Hide()

    searchBox.clearBtn.text = searchBox.clearBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    searchBox.clearBtn.text:SetPoint("CENTER", 0, 1)
    searchBox.clearBtn.text:SetText("x")

    -- Apply theme colors
    local function ApplyTheme()
        local Theme = MedaUI.Theme
        searchBox:SetBackdropColor(unpack(Theme.input))
        if searchBox._hasFocus then
            searchBox:SetBackdropBorderColor(unpack(Theme.gold))
        else
            searchBox:SetBackdropBorderColor(unpack(Theme.border))
        end
        searchBox.icon:SetVertexColor(unpack(Theme.textDim))
        searchBox.editBox:SetTextColor(unpack(Theme.text))
        searchBox.placeholder:SetTextColor(unpack(Theme.textDim))
        searchBox.clearBtn.text:SetTextColor(unpack(Theme.textDim))
    end
    searchBox._ApplyTheme = ApplyTheme

    -- Register for theme updates
    searchBox._themeHandle = MedaUI:RegisterThemedWidget(searchBox, ApplyTheme)

    -- Initial theme application
    ApplyTheme()

    searchBox.clearBtn:SetScript("OnEnter", function(self)
        local Theme = MedaUI.Theme
        self.text:SetTextColor(unpack(Theme.text))
    end)

    searchBox.clearBtn:SetScript("OnLeave", function(self)
        local Theme = MedaUI.Theme
        self.text:SetTextColor(unpack(Theme.textDim))
    end)

    searchBox.clearBtn:SetScript("OnClick", function()
        searchBox:Clear()
    end)

    -- Debounced search function
    local function TriggerSearch()
        if searchBox.OnSearch then
            searchBox:OnSearch(searchBox.editBox:GetText())
        end
    end

    local function DebouncedSearch()
        if searchBox.debounceTimer then
            searchBox.debounceTimer:Cancel()
        end
        searchBox.debounceTimer = C_Timer.NewTimer(searchBox.debounceTime, TriggerSearch)
    end

    -- EditBox scripts
    searchBox.editBox:SetScript("OnTextChanged", function(self, userInput)
        local text = self:GetText()
        if text and text ~= "" then
            searchBox.placeholder:Hide()
            searchBox.clearBtn:Show()
        else
            searchBox.placeholder:Show()
            searchBox.clearBtn:Hide()
        end

        if userInput then
            DebouncedSearch()
        end
    end)

    searchBox.editBox:SetScript("OnEnterPressed", function(self)
        -- Immediate search on enter
        if searchBox.debounceTimer then
            searchBox.debounceTimer:Cancel()
        end
        TriggerSearch()
        self:ClearFocus()
    end)

    searchBox.editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    searchBox.editBox:SetScript("OnEditFocusGained", function()
        searchBox._hasFocus = true
        local Theme = MedaUI.Theme
        searchBox:SetBackdropBorderColor(unpack(Theme.gold))
    end)

    searchBox.editBox:SetScript("OnEditFocusLost", function()
        searchBox._hasFocus = false
        local Theme = MedaUI.Theme
        searchBox:SetBackdropBorderColor(unpack(Theme.border))
    end)

    -- Click on container focuses editbox
    searchBox:SetScript("OnMouseDown", function()
        searchBox.editBox:SetFocus()
    end)

    --- Get the current search text
    --- @return string The search text
    function searchBox:GetText()
        return self.editBox:GetText()
    end

    --- Set the search text
    --- @param text string The text to set
    function searchBox:SetText(text)
        self.editBox:SetText(text or "")
    end

    --- Clear the search box
    function searchBox:Clear()
        self.editBox:SetText("")
        self.editBox:ClearFocus()
        if self.OnSearch then
            self:OnSearch("")
        end
    end

    --- Set the placeholder text
    --- @param text string The placeholder text
    function searchBox:SetPlaceholder(text)
        self.placeholder:SetText(text)
    end

    --- Set the debounce time
    --- @param seconds number Debounce delay in seconds
    function searchBox:SetDebounceTime(seconds)
        self.debounceTime = seconds
    end

    --- Focus the search box
    function searchBox:SetFocus()
        self.editBox:SetFocus()
    end

    --- Clear focus from the search box
    function searchBox:ClearFocus()
        self.editBox:ClearFocus()
    end

    return searchBox
end
