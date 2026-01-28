--[[
    MedaUI Dropdown Widget
    Select menu with options list
]]

local MedaUI = LibStub("MedaUI-1.0")
local Theme = MedaUI.Theme

-- Dropdown counter for unique names
local dropdownCounter = 0

--- Create a dropdown select menu
--- @param parent Frame Parent frame
--- @param width number Dropdown width
--- @param options table Array of {value, label} options
--- @return Frame The dropdown frame
function MedaUI:CreateDropdown(parent, width, options)
    dropdownCounter = dropdownCounter + 1
    local name = "MedaUIDropdown" .. dropdownCounter
    
    local dropdown = CreateFrame("Frame", name, parent, "BackdropTemplate")
    dropdown:SetSize(width, 24)
    dropdown:SetBackdrop(self:CreateBackdrop(true))
    dropdown:SetBackdropColor(unpack(Theme.input))
    dropdown:SetBackdropBorderColor(unpack(Theme.border))
    
    dropdown.options = options or {}
    dropdown.selectedValue = nil
    dropdown.selectedLabel = nil
    dropdown.OnValueChanged = nil
    dropdown.isOpen = false
    dropdown.enabled = true
    
    -- Selected text display
    dropdown.text = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dropdown.text:SetPoint("LEFT", 8, 0)
    dropdown.text:SetPoint("RIGHT", -24, 0)
    dropdown.text:SetJustifyH("LEFT")
    dropdown.text:SetTextColor(unpack(Theme.text))
    dropdown.text:SetText("Select...")
    
    -- Arrow separator line
    dropdown.arrowSeparator = dropdown:CreateTexture(nil, "ARTWORK")
    dropdown.arrowSeparator:SetSize(1, 16)
    dropdown.arrowSeparator:SetPoint("RIGHT", -22, 0)
    dropdown.arrowSeparator:SetColorTexture(unpack(Theme.border))
    
    -- Arrow icon (texture-based chevron)
    dropdown.arrow = dropdown:CreateTexture(nil, "OVERLAY")
    dropdown.arrow:SetSize(12, 12)
    dropdown.arrow:SetPoint("RIGHT", -6, 0)
    
    -- Try Atlas first, fall back to rotated expand arrow
    local atlasSet = pcall(function()
        dropdown.arrow:SetAtlas("common-dropdown-icon")
    end)
    
    if not atlasSet or not dropdown.arrow:GetAtlas() then
        dropdown.arrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
        dropdown.arrow:SetRotation(math.rad(90))  -- Point down
    end
    
    dropdown.arrow:SetDesaturated(true)
    dropdown.arrow:SetVertexColor(unpack(Theme.textDim))
    dropdown.arrowRotation = 0  -- Track rotation state (0 = down, 180 = up)
    
    -- Click area
    dropdown.button = CreateFrame("Button", nil, dropdown)
    dropdown.button:SetAllPoints()
    
    -- Options list (dropdown menu)
    dropdown.menu = CreateFrame("Frame", name .. "Menu", dropdown, "BackdropTemplate")
    dropdown.menu:SetBackdrop(self:CreateBackdrop(true))
    dropdown.menu:SetBackdropColor(unpack(Theme.menuBackground))
    dropdown.menu:SetBackdropBorderColor(unpack(Theme.border))
    dropdown.menu:SetFrameStrata("FULLSCREEN_DIALOG")
    dropdown.menu:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
    dropdown.menu:SetWidth(width)
    dropdown.menu:Hide()
    dropdown.menu.items = {}
    
    -- Build options list
    local function BuildMenu()
        -- Clear existing items
        for _, item in ipairs(dropdown.menu.items) do
            item:Hide()
            item:SetParent(nil)
        end
        wipe(dropdown.menu.items)
        
        local itemHeight = 22
        local menuHeight = #dropdown.options * itemHeight + 4
        dropdown.menu:SetHeight(math.min(menuHeight, 200))
        
        for i, opt in ipairs(dropdown.options) do
            local item = CreateFrame("Button", nil, dropdown.menu, "BackdropTemplate")
            item:SetSize(width - 4, itemHeight)
            item:SetPoint("TOPLEFT", 2, -2 - (i - 1) * itemHeight)
            item:SetBackdrop(self:CreateBackdrop(false))
            item:SetBackdropColor(0, 0, 0, 0)
            
            item.value = opt.value
            item.label = opt.label
            
            item.text = item:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            item.text:SetPoint("LEFT", 8, 0)
            item.text:SetText(opt.label)
            item.text:SetTextColor(unpack(Theme.text))
            
            item:SetScript("OnEnter", function(self)
                self:SetBackdropColor(unpack(Theme.buttonHover))
            end)
            
            item:SetScript("OnLeave", function(self)
                self:SetBackdropColor(0, 0, 0, 0)
            end)
            
            item:SetScript("OnClick", function(self)
                dropdown:SetSelected(self.value)
                dropdown.menu:Hide()
                dropdown.isOpen = false
                dropdown.arrow:SetRotation(math.rad(90))  -- Point down
            end)
            
            dropdown.menu.items[i] = item
        end
    end
    
    -- Toggle dropdown
    dropdown.button:SetScript("OnClick", function()
        if not dropdown.enabled then return end
        
        if dropdown.isOpen then
            dropdown.menu:Hide()
            dropdown.isOpen = false
            dropdown.arrow:SetRotation(math.rad(90))  -- Point down
        else
            BuildMenu()
            dropdown.menu:Show()
            dropdown.isOpen = true
            dropdown.arrow:SetRotation(math.rad(-90))  -- Point up
        end
    end)
    
    -- Close when clicking elsewhere
    dropdown.menu:SetScript("OnShow", function()
        dropdown.menu:SetFrameLevel(dropdown:GetFrameLevel() + 100)
    end)
    
    -- Hover effects on main dropdown
    dropdown.button:SetScript("OnEnter", function()
        if dropdown.enabled then
            dropdown:SetBackdropBorderColor(unpack(Theme.gold))
        end
    end)
    
    dropdown.button:SetScript("OnLeave", function()
        if not dropdown.isOpen then
            dropdown:SetBackdropBorderColor(unpack(Theme.border))
        end
    end)
    
    --- Set the selected value
    --- @param value any The value to select
    function dropdown:SetSelected(value)
        local previousValue = self.selectedValue
        self.selectedValue = value
        
        -- Find label for value
        for _, opt in ipairs(self.options) do
            if opt.value == value then
                self.selectedLabel = opt.label
                self.text:SetText(opt.label)
                break
            end
        end
        
        -- Fire callback if changed
        if previousValue ~= value and self.OnValueChanged then
            self:OnValueChanged(value, self.selectedLabel)
        end
    end
    
    --- Get the selected value
    --- @return any The selected value
    function dropdown:GetSelected()
        return self.selectedValue
    end
    
    --- Get the selected label
    --- @return string|nil The selected label
    function dropdown:GetSelectedLabel()
        return self.selectedLabel
    end
    
    --- Set the options list
    --- @param newOptions table Array of {value, label} options
    function dropdown:SetOptions(newOptions)
        self.options = newOptions
        -- Reset selection if current value not in new options
        local found = false
        for _, opt in ipairs(newOptions) do
            if opt.value == self.selectedValue then
                found = true
                break
            end
        end
        if not found then
            self.selectedValue = nil
            self.selectedLabel = nil
            self.text:SetText("Select...")
        end
    end
    
    --- Enable or disable the dropdown
    --- @param enabled boolean Whether dropdown is enabled
    function dropdown:SetEnabled(enabled)
        self.enabled = enabled
        if enabled then
            self.text:SetTextColor(unpack(Theme.text))
            self.arrow:SetVertexColor(unpack(Theme.textDim))
            self.arrowSeparator:SetColorTexture(unpack(Theme.border))
            self:SetBackdropColor(unpack(Theme.input))
        else
            self.text:SetTextColor(unpack(Theme.textDisabled))
            self.arrow:SetVertexColor(unpack(Theme.textDisabled))
            self.arrowSeparator:SetColorTexture(unpack(Theme.textDisabled))
            self:SetBackdropColor(unpack(Theme.buttonDisabled))
            -- Close menu if open
            if self.isOpen then
                self.menu:Hide()
                self.isOpen = false
                self.arrow:SetRotation(math.rad(90))  -- Point down
            end
        end
    end
    
    -- Set first option as selected by default if options provided
    if options and options[1] then
        dropdown:SetSelected(options[1].value)
    end
    
    return dropdown
end
