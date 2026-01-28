--[[
    MedaUI ContextMenu Widget
    Right-click popup menu with items and submenus
]]

local MedaUI = LibStub("MedaUI-1.0")
local Theme = MedaUI.Theme

-- Shared menu pool
local menuPool = {}
local activeMenus = {}

--- Create a context menu
--- @param items table Array of menu items
--- @return table The context menu object
function MedaUI:CreateContextMenu(items)
    local menu = {}
    menu.items = items or {}
    menu.frame = nil
    menu.submenus = {}
    
    local itemHeight = 24
    local menuWidth = 160
    local separatorHeight = 8
    
    -- Calculate menu height
    local function CalculateHeight(menuItems)
        local h = 8 -- padding
        for _, item in ipairs(menuItems) do
            if item.separator then
                h = h + separatorHeight
            else
                h = h + itemHeight
            end
        end
        return h
    end
    
    -- Create menu frame
    local function CreateMenuFrame(parentFrame)
        local frame = tremove(menuPool) -- Reuse from pool
        if not frame then
            frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
            frame:SetBackdrop(MedaUI:CreateBackdrop(true))
            frame:SetFrameStrata("FULLSCREEN_DIALOG")
            frame.itemFrames = {}
        end
        
        frame:SetBackdropColor(unpack(Theme.menuBackground))
        frame:SetBackdropBorderColor(unpack(Theme.border))
        frame:Show()
        
        return frame
    end
    
    -- Build menu items
    local function BuildMenu(frame, menuItems, parentMenu)
        -- Hide existing items
        for _, itemFrame in ipairs(frame.itemFrames) do
            itemFrame:Hide()
        end
        
        local menuHeight = CalculateHeight(menuItems)
        frame:SetSize(menuWidth, menuHeight)
        
        local yOffset = -4
        for i, item in ipairs(menuItems) do
            local itemFrame = frame.itemFrames[i]
            
            if item.separator then
                -- Separator
                if not itemFrame or not itemFrame.isSeparator then
                    itemFrame = CreateFrame("Frame", nil, frame)
                    itemFrame.isSeparator = true
                    itemFrame.line = itemFrame:CreateTexture(nil, "ARTWORK")
                    itemFrame.line:SetHeight(1)
                    itemFrame.line:SetPoint("LEFT", 8, 0)
                    itemFrame.line:SetPoint("RIGHT", -8, 0)
                    itemFrame.line:SetColorTexture(unpack(Theme.border))
                    frame.itemFrames[i] = itemFrame
                end
                itemFrame:SetSize(menuWidth - 8, separatorHeight)
                itemFrame:SetPoint("TOPLEFT", 4, yOffset)
                itemFrame:Show()
                yOffset = yOffset - separatorHeight
            else
                -- Regular item
                if not itemFrame or itemFrame.isSeparator then
                    itemFrame = CreateFrame("Button", nil, frame, "BackdropTemplate")
                    itemFrame.isSeparator = false
                    itemFrame:SetBackdrop(MedaUI:CreateBackdrop(false))
                    
                    itemFrame.text = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    itemFrame.text:SetPoint("LEFT", 12, 0)
                    itemFrame.text:SetJustifyH("LEFT")
                    
                    itemFrame.arrow = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    itemFrame.arrow:SetPoint("RIGHT", -8, 0)
                    itemFrame.arrow:SetText("▶")
                    
                    frame.itemFrames[i] = itemFrame
                end
                
                itemFrame:SetSize(menuWidth - 8, itemHeight)
                itemFrame:SetPoint("TOPLEFT", 4, yOffset)
                itemFrame:SetBackdropColor(0, 0, 0, 0)
                
                itemFrame.text:SetText(item.label or "")
                
                -- Disabled state
                if item.disabled then
                    itemFrame.text:SetTextColor(unpack(Theme.textDisabled))
                    itemFrame:SetScript("OnClick", nil)
                else
                    itemFrame.text:SetTextColor(unpack(Theme.text))
                end
                
                -- Submenu arrow
                if item.submenu then
                    itemFrame.arrow:Show()
                    itemFrame.arrow:SetTextColor(unpack(Theme.textDim))
                else
                    itemFrame.arrow:Hide()
                end
                
                -- Hover effects
                itemFrame:SetScript("OnEnter", function(self)
                    if not item.disabled then
                        self:SetBackdropColor(unpack(Theme.buttonHover))
                    end
                    
                    -- Show submenu if present
                    if item.submenu then
                        menu:ShowSubmenu(item.submenu, self)
                    else
                        menu:HideSubmenus()
                    end
                end)
                
                itemFrame:SetScript("OnLeave", function(self)
                    self:SetBackdropColor(0, 0, 0, 0)
                end)
                
                -- Click handler
                if not item.disabled and not item.submenu then
                    itemFrame:SetScript("OnClick", function()
                        if item.onClick then
                            item.onClick(item)
                        end
                        menu:Hide()
                    end)
                else
                    itemFrame:SetScript("OnClick", nil)
                end
                
                itemFrame:Show()
                yOffset = yOffset - itemHeight
            end
        end
    end
    
    --- Show the menu at a position
    --- @param parent Frame|nil Parent frame (for anchoring)
    --- @param x number X position
    --- @param y number Y position
    function menu:Show(parent, x, y)
        self:Hide() -- Hide any existing menu first
        
        self.frame = CreateMenuFrame()
        BuildMenu(self.frame, self.items, nil)
        
        -- Position menu
        self.frame:ClearAllPoints()
        if parent then
            self.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
        else
            self.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
        end
        
        -- Keep on screen
        local screenWidth, screenHeight = GetScreenWidth(), GetScreenHeight()
        local menuWidth, menuHeight = self.frame:GetSize()
        local left = self.frame:GetLeft() or 0
        local top = self.frame:GetTop() or screenHeight
        
        if left + menuWidth > screenWidth then
            local newX = x - menuWidth
            self.frame:ClearAllPoints()
            if parent then
                self.frame:SetPoint("TOPRIGHT", parent, "TOPLEFT", x, y)
            else
                self.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", screenWidth - menuWidth, y)
            end
        end
        
        if top - menuHeight < 0 then
            self.frame:ClearAllPoints()
            self.frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, 0)
        end
        
        activeMenus[self] = true
        
        -- Auto-close when clicking elsewhere
        self.closeHandler = CreateFrame("Button", nil, UIParent)
        self.closeHandler:SetAllPoints(UIParent)
        self.closeHandler:SetFrameStrata("FULLSCREEN")
        self.closeHandler:SetScript("OnClick", function()
            menu:Hide()
        end)
        self.closeHandler:SetScript("OnEnter", function()
            -- Give a small delay before closing
            C_Timer.After(0.1, function()
                if not MouseIsOver(self.frame) then
                    local overSubmenu = false
                    for _, sub in ipairs(self.submenus) do
                        if sub:IsShown() and MouseIsOver(sub) then
                            overSubmenu = true
                            break
                        end
                    end
                    if not overSubmenu then
                        -- menu:Hide()
                    end
                end
            end)
        end)
    end
    
    --- Show the menu at cursor position
    function menu:ShowAtCursor()
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        self:Show(nil, x / scale, y / scale)
    end
    
    --- Show a submenu
    --- @param submenuItems table Submenu items
    --- @param parentItem Frame The parent menu item
    function menu:ShowSubmenu(submenuItems, parentItem)
        self:HideSubmenus()
        
        local subFrame = CreateMenuFrame()
        BuildMenu(subFrame, submenuItems, self)
        
        subFrame:ClearAllPoints()
        subFrame:SetPoint("TOPLEFT", parentItem, "TOPRIGHT", 2, 0)
        
        self.submenus[#self.submenus + 1] = subFrame
    end
    
    --- Hide all submenus
    function menu:HideSubmenus()
        for _, sub in ipairs(self.submenus) do
            sub:Hide()
            tinsert(menuPool, sub)
        end
        wipe(self.submenus)
    end
    
    --- Hide the menu
    function menu:Hide()
        self:HideSubmenus()
        
        if self.frame then
            self.frame:Hide()
            tinsert(menuPool, self.frame)
            self.frame = nil
        end
        
        if self.closeHandler then
            self.closeHandler:Hide()
            self.closeHandler:SetParent(nil)
            self.closeHandler = nil
        end
        
        activeMenus[self] = nil
    end
    
    --- Set new items
    --- @param newItems table New menu items
    function menu:SetItems(newItems)
        self.items = newItems
        if self.frame and self.frame:IsShown() then
            BuildMenu(self.frame, self.items, nil)
        end
    end
    
    --- Check if menu is shown
    --- @return boolean Whether menu is visible
    function menu:IsShown()
        return self.frame and self.frame:IsShown()
    end
    
    return menu
end

-- Global function to hide all context menus
function MedaUI:HideAllContextMenus()
    for menu in pairs(activeMenus) do
        menu:Hide()
    end
end
