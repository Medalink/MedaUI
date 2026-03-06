--[[
    MedaUI ContextMenu Widget
    Right-click popup menu with items and submenus
]]

local MedaUI = LibStub("MedaUI-1.0")
local Pixel = LibStub("MedaUI-1.0").Pixel

-- Shared menu pool
local menuPool = {}
local activeMenus = {}
local closeHandlerPool = {}

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
        local Theme = MedaUI.Theme
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

    -- Shared item handlers (read data from frame fields)
    local function MenuItem_OnEnter(self)
        if not self._disabled then
            local Theme = MedaUI.Theme
            self:SetBackdropColor(unpack(Theme.buttonHover))
        end
        if self._submenu then
            self._menuObj:ShowSubmenu(self._submenu, self)
        else
            self._menuObj:HideSubmenus()
        end
    end

    local function MenuItem_OnLeave(self)
        self:SetBackdropColor(0, 0, 0, 0)
    end

    local function MenuItem_OnClick(self)
        local itemData = self._itemData
        if itemData and itemData.onClick then
            itemData.onClick(itemData)
        end
        self._menuObj:Hide()
    end

    -- Build menu items (reuses existing itemFrames)
    local function BuildMenu(frame, menuItems, parentMenu)
        local Theme = MedaUI.Theme

        for _, itemFrame in ipairs(frame.itemFrames) do
            itemFrame:Hide()
        end

        local menuHeight = CalculateHeight(menuItems)
        Pixel.SetSize(frame, menuWidth, menuHeight)

        local yOffset = -4
        for i, item in ipairs(menuItems) do
            local itemFrame = frame.itemFrames[i]

            if item.separator then
                if not itemFrame or not itemFrame.isSeparator then
                    itemFrame = CreateFrame("Frame", nil, frame)
                    itemFrame.isSeparator = true
                    itemFrame.line = itemFrame:CreateTexture(nil, "ARTWORK")
                    Pixel.SetHeight(itemFrame.line, 1)
                    Pixel.SetPoint(itemFrame.line, "LEFT", 8, 0)
                    Pixel.SetPoint(itemFrame.line, "RIGHT", -8, 0)
                    frame.itemFrames[i] = itemFrame
                end
                itemFrame.line:SetColorTexture(unpack(Theme.border))
                Pixel.SetSize(itemFrame, menuWidth - 8, separatorHeight)
                Pixel.SetPoint(itemFrame, "TOPLEFT", 4, yOffset)
                itemFrame:Show()
                yOffset = yOffset - separatorHeight
            else
                if not itemFrame or itemFrame.isSeparator then
                    itemFrame = CreateFrame("Button", nil, frame, "BackdropTemplate")
                    itemFrame.isSeparator = false
                    itemFrame:SetBackdrop(MedaUI:CreateBackdrop(false))

                    itemFrame.text = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    Pixel.SetPoint(itemFrame.text, "LEFT", 12, 0)
                    itemFrame.text:SetJustifyH("LEFT")

                    itemFrame.arrow = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    Pixel.SetPoint(itemFrame.arrow, "RIGHT", -8, 0)
                    itemFrame.arrow:SetText(">")

                    itemFrame:SetScript("OnEnter", MenuItem_OnEnter)
                    itemFrame:SetScript("OnLeave", MenuItem_OnLeave)

                    frame.itemFrames[i] = itemFrame
                end

                -- Store data on the frame for shared handlers
                itemFrame._menuObj = menu
                itemFrame._itemData = item
                itemFrame._disabled = item.disabled
                itemFrame._submenu = item.submenu

                Pixel.SetSize(itemFrame, menuWidth - 8, itemHeight)
                Pixel.SetPoint(itemFrame, "TOPLEFT", 4, yOffset)
                itemFrame:SetBackdropColor(0, 0, 0, 0)

                itemFrame.text:SetText(item.label or "")

                if item.disabled then
                    itemFrame.text:SetTextColor(unpack(Theme.textDisabled))
                    itemFrame:SetScript("OnClick", nil)
                else
                    itemFrame.text:SetTextColor(unpack(Theme.text))
                end

                if item.submenu then
                    itemFrame.arrow:Show()
                    itemFrame.arrow:SetTextColor(unpack(Theme.textDim))
                    itemFrame:SetScript("OnClick", nil)
                else
                    itemFrame.arrow:Hide()
                    if not item.disabled then
                        itemFrame:SetScript("OnClick", MenuItem_OnClick)
                    end
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
        Pixel.ClearPoints(self.frame)
        if parent then
            Pixel.SetPoint(self.frame, "TOPLEFT", parent, "TOPLEFT", x, y)
        else
            Pixel.SetPoint(self.frame, "TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
        end

        -- Keep on screen
        local screenWidth, screenHeight = GetScreenWidth(), GetScreenHeight()
        local menuWidth, menuHeight = self.frame:GetSize()
        local left = self.frame:GetLeft() or 0
        local top = self.frame:GetTop() or screenHeight

        if left + menuWidth > screenWidth then
            local newX = x - menuWidth
            Pixel.ClearPoints(self.frame)
            if parent then
                Pixel.SetPoint(self.frame, "TOPRIGHT", parent, "TOPLEFT", x, y)
            else
                Pixel.SetPoint(self.frame, "TOPLEFT", UIParent, "BOTTOMLEFT", screenWidth - menuWidth, y)
            end
        end

        if top - menuHeight < 0 then
            Pixel.ClearPoints(self.frame)
            Pixel.SetPoint(self.frame, "BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, 0)
        end

        activeMenus[self] = true

        -- Reuse or create the click-away close handler
        local handler = tremove(closeHandlerPool)
        if not handler then
            handler = CreateFrame("Button", nil, UIParent)
        else
            handler:SetParent(UIParent)
        end
        handler:SetAllPoints(UIParent)
        handler:SetFrameStrata("FULLSCREEN")
        handler._menu = menu
        handler:SetScript("OnClick", function(h)
            h._menu:Hide()
        end)
        handler:Show()
        self.closeHandler = handler
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

        Pixel.ClearPoints(subFrame)
        Pixel.SetPoint(subFrame, "TOPLEFT", parentItem, "TOPRIGHT", 2, 0)

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
            self.closeHandler._menu = nil
            closeHandlerPool[#closeHandlerPool + 1] = self.closeHandler
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
