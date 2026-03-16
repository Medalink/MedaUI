--[[
    MedaUI FloatingToolbar Widget
    Floating status/toolbar window for modal editing and status display
]]

local MedaUI = LibStub("MedaUI-2.0")
---@cast MedaUI MedaUILibrary
local Pixel = LibStub("MedaUI-2.0").Pixel

--- Create a floating toolbar
--- @param name string Unique frame name
--- @param width number Toolbar width
--- @param title string|nil Toolbar title
--- @param config table|nil Configuration {draggable, closeable, showTitle}
--- @return table The floating toolbar widget
function MedaUI.CreateFloatingToolbar(library, name, width, title, config)
    config = config or {}

    local toolbar = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    Pixel.SetSize(toolbar, width, 80)
    toolbar:SetFrameStrata("HIGH")
    toolbar:SetBackdrop(library:CreateBackdrop(true))
    toolbar:Hide()

    -- State
    toolbar.title = title
    toolbar.draggable = config.draggable ~= false
    toolbar.closeable = config.closeable ~= false
    toolbar.buttons = {}
    toolbar.instructionsText = nil
    toolbar.statusText = nil

    -- Make draggable
    if toolbar.draggable then
        toolbar:SetMovable(true)
        toolbar:EnableMouse(true)
        toolbar:RegisterForDrag("LeftButton")
        toolbar:SetScript("OnDragStart", function(frame)
            frame:StartMoving()
        end)
        toolbar:SetScript("OnDragStop", function(frame)
            frame:StopMovingOrSizing()
            -- Fire callback
            if toolbar.OnMove then
                local point, _, relPoint, x, y = frame:GetPoint()
                toolbar:OnMove({ point = point, relPoint = relPoint, x = x, y = y })
            end
        end)
    end

    -- Title bar (if title provided)
    local yOffset = -8
    if title then
        local titleText = toolbar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        Pixel.SetPoint(titleText, "TOP", 0, -8)
        titleText:SetText(title)
        toolbar.titleLabel = titleText
        yOffset = -26
    end

    -- Close button (top right)
    if toolbar.closeable then
        local closeBtn = CreateFrame("Button", nil, toolbar)
        Pixel.SetSize(closeBtn, 18, 18)
        Pixel.SetPoint(closeBtn, "TOPRIGHT", -4, -4)

        closeBtn.text = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        Pixel.SetPoint(closeBtn.text, "CENTER", 0, 1)
        closeBtn.text:SetText("X")

        closeBtn:SetScript("OnClick", function()
            toolbar:Hide()
            if toolbar.OnClose then
                toolbar:OnClose()
            end
        end)

        closeBtn:SetScript("OnEnter", function(button)
            local theme = MedaUI.Theme
            button.text:SetTextColor(unpack(theme.text))
        end)

        closeBtn:SetScript("OnLeave", function(button)
            local theme = MedaUI.Theme
            button.text:SetTextColor(unpack(theme.textDim))
        end)

        toolbar.closeBtn = closeBtn
    end

    -- Instructions area
    local instructions = toolbar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    Pixel.SetPoint(instructions, "TOPLEFT", 12, yOffset)
    Pixel.SetPoint(instructions, "TOPRIGHT", -12, yOffset)
    instructions:SetJustifyH("LEFT")
    instructions:SetWordWrap(true)
    toolbar.instructionsLabel = instructions

    -- Status area
    local status = toolbar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    Pixel.SetPoint(status, "BOTTOMLEFT", 12, 12)
    Pixel.SetPoint(status, "BOTTOMRIGHT", -12, 12)
    status:SetJustifyH("LEFT")
    toolbar.statusLabel = status

    -- Button container
    toolbar.buttonContainer = CreateFrame("Frame", nil, toolbar)
    Pixel.SetHeight(toolbar.buttonContainer, 30)
    Pixel.SetPoint(toolbar.buttonContainer, "BOTTOMLEFT", 8, 36)
    Pixel.SetPoint(toolbar.buttonContainer, "BOTTOMRIGHT", -8, 36)

    -- Apply theme
    local function ApplyTheme()
        local theme = MedaUI.Theme
        toolbar:SetBackdropColor(unpack(theme.background))
        toolbar:SetBackdropBorderColor(unpack(theme.gold))

        if toolbar.titleLabel then
            toolbar.titleLabel:SetTextColor(unpack(theme.gold))
        end

        toolbar.instructionsLabel:SetTextColor(unpack(theme.text))
        toolbar.statusLabel:SetTextColor(unpack(theme.textDim))

        if toolbar.closeBtn then
            toolbar.closeBtn.text:SetTextColor(unpack(theme.textDim))
        end
    end
    toolbar._ApplyTheme = ApplyTheme
    toolbar._themeHandle = MedaUI:RegisterThemedWidget(toolbar, ApplyTheme)
    ApplyTheme()

    -- Callbacks
    toolbar.OnClose = nil
    toolbar.OnMove = nil

    --- Set the instructions text
    --- @param text string Instructions to display
    function toolbar:SetInstructions(text)
        self.instructionsText = text
        self.instructionsLabel:SetText(text)
        self:UpdateHeight()
    end

    --- Set the status text
    --- @param text string Status to display
    function toolbar:SetStatus(text)
        self.statusText = text
        self.statusLabel:SetText(text)
    end

    --- Set status with color
    --- @param text string Status text
    --- @param r number Red (0-1)
    --- @param g number Green (0-1)
    --- @param b number Blue (0-1)
    function toolbar:SetStatusColor(text, r, g, b)
        self.statusLabel:SetText(text)
        self.statusLabel:SetTextColor(r, g, b)
    end

    --- Add a button to the toolbar
    --- @param label string Button text
    --- @param onClick function Click handler
    --- @return Button The created button
    function toolbar:AddButton(label, onClick)
        local btn = tremove(self._buttonPool)
        if btn then
            btn:SetParent(self.buttonContainer)
            btn.text:SetText(label)
            btn:Show()
        else
            btn = library:CreateButton(self.buttonContainer, label, nil, 24)
        end

        btn:ClearAllPoints()
        if #self.buttons == 0 then
            Pixel.SetPoint(btn, "LEFT", 0, 0)
        else
            local prevBtn = self.buttons[#self.buttons]
            Pixel.SetPoint(btn, "LEFT", prevBtn, "RIGHT", 8, 0)
        end

        btn:SetScript("OnClick", onClick)
        self.buttons[#self.buttons + 1] = btn

        return btn
    end

    --- Add a toggle button to the toolbar
    --- @param label string Button text
    --- @param onClick function Click handler
    --- @param isActive boolean|function Initial state or function returning state
    --- @return Button The created button
    function toolbar:AddToggleButton(label, onClick, isActive)
        local btn = self:AddButton(label, function()
            onClick()
            self:RefreshToggleButtons()
        end)

        btn.isToggle = true
        btn.getActive = type(isActive) == "function" and isActive or function() return isActive end

        return btn
    end

    --- Refresh toggle button states
    function toolbar:RefreshToggleButtons()
        local theme = MedaUI.Theme
        for _, btn in ipairs(self.buttons) do
            if btn.isToggle and btn.getActive then
                if btn.getActive() then
                    btn:SetBackdropColor(unpack(theme.gold))
                    btn.text:SetTextColor(0.1, 0.1, 0.1)
                else
                    btn:SetBackdropColor(unpack(theme.button))
                    btn.text:SetTextColor(unpack(theme.text))
                end
            end
        end
    end

    toolbar._buttonPool = {}

    --- Clear all buttons (pools them for reuse)
    function toolbar:ClearButtons()
        for _, btn in ipairs(self.buttons) do
            btn:Hide()
            btn:ClearAllPoints()
            btn:SetScript("OnClick", nil)
            btn.isToggle = nil
            btn.getActive = nil
            self._buttonPool[#self._buttonPool + 1] = btn
        end
        wipe(self.buttons)
    end

    --- Update toolbar height based on content
    function toolbar:UpdateHeight()
        local height = 80  -- Base height

        -- Add space for title
        if self.title then
            height = height + 18
        end

        -- Add space for multi-line instructions
        if self.instructionsText then
            local textHeight = self.instructionsLabel:GetStringHeight()
            if textHeight > 20 then
                height = height + (textHeight - 20)
            end
        end

        Pixel.SetHeight(self, height)
    end

    --- Position the toolbar at screen center
    function toolbar:CenterOnScreen()
        Pixel.ClearPoints(self)
        Pixel.SetPoint(self, "CENTER", UIParent, "CENTER", 0, 200)
    end

    --- Position the toolbar near a specific frame
    --- @param frame Frame The frame to position near
    --- @param offset number|nil Vertical offset (default: 60)
    function toolbar:PositionNear(frame, offset)
        offset = offset or 60
        Pixel.ClearPoints(self)
        Pixel.SetPoint(self, "TOP", frame, "BOTTOM", 0, -offset)
    end

    -- Register for ESC to close
    if toolbar.closeable then
        tinsert(UISpecialFrames, name)
    end

    return toolbar
end
