--[[
    MedaUI FloatingToolbar Widget
    Floating status/toolbar window for modal editing and status display
]]

local MedaUI = LibStub("MedaUI-1.0")

--- Create a floating toolbar
--- @param name string Unique frame name
--- @param width number Toolbar width
--- @param title string|nil Toolbar title
--- @param config table|nil Configuration {draggable, closeable, showTitle}
--- @return table The floating toolbar widget
function MedaUI:CreateFloatingToolbar(name, width, title, config)
    config = config or {}

    local toolbar = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    toolbar:SetSize(width, 80)
    toolbar:SetFrameStrata("HIGH")
    toolbar:SetBackdrop(self:CreateBackdrop(true))
    toolbar:Hide()

    local Theme = self.Theme

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
        toolbar:SetScript("OnDragStart", function(self)
            self:StartMoving()
        end)
        toolbar:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            -- Fire callback
            if toolbar.OnMove then
                local point, _, relPoint, x, y = self:GetPoint()
                toolbar:OnMove({ point = point, relPoint = relPoint, x = x, y = y })
            end
        end)
    end

    -- Title bar (if title provided)
    local yOffset = -8
    if title then
        local titleText = toolbar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        titleText:SetPoint("TOP", 0, -8)
        titleText:SetText(title)
        toolbar.titleLabel = titleText
        yOffset = -26
    end

    -- Close button (top right)
    if toolbar.closeable then
        local closeBtn = CreateFrame("Button", nil, toolbar)
        closeBtn:SetSize(18, 18)
        closeBtn:SetPoint("TOPRIGHT", -4, -4)

        closeBtn.text = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        closeBtn.text:SetPoint("CENTER", 0, 1)
        closeBtn.text:SetText("X")

        closeBtn:SetScript("OnClick", function()
            toolbar:Hide()
            if toolbar.OnClose then
                toolbar:OnClose()
            end
        end)

        closeBtn:SetScript("OnEnter", function(self)
            self.text:SetTextColor(1, 0.3, 0.3)
        end)

        closeBtn:SetScript("OnLeave", function(self)
            local Theme = MedaUI.Theme
            self.text:SetTextColor(unpack(Theme.textDim))
        end)

        toolbar.closeBtn = closeBtn
    end

    -- Instructions area
    local instructions = toolbar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    instructions:SetPoint("TOPLEFT", 12, yOffset)
    instructions:SetPoint("TOPRIGHT", -12, yOffset)
    instructions:SetJustifyH("LEFT")
    instructions:SetWordWrap(true)
    toolbar.instructionsLabel = instructions

    -- Status area
    local status = toolbar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    status:SetPoint("BOTTOMLEFT", 12, 12)
    status:SetPoint("BOTTOMRIGHT", -12, 12)
    status:SetJustifyH("LEFT")
    toolbar.statusLabel = status

    -- Button container
    toolbar.buttonContainer = CreateFrame("Frame", nil, toolbar)
    toolbar.buttonContainer:SetHeight(30)
    toolbar.buttonContainer:SetPoint("BOTTOMLEFT", 8, 36)
    toolbar.buttonContainer:SetPoint("BOTTOMRIGHT", -8, 36)

    -- Apply theme
    local function ApplyTheme()
        local Theme = MedaUI.Theme
        toolbar:SetBackdropColor(unpack(Theme.background))
        toolbar:SetBackdropBorderColor(unpack(Theme.gold))

        if toolbar.titleLabel then
            toolbar.titleLabel:SetTextColor(unpack(Theme.gold))
        end

        toolbar.instructionsLabel:SetTextColor(unpack(Theme.text))
        toolbar.statusLabel:SetTextColor(unpack(Theme.textDim))

        if toolbar.closeBtn then
            toolbar.closeBtn.text:SetTextColor(unpack(Theme.textDim))
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
        local btn = MedaUI:CreateButton(self.buttonContainer, label, nil, 24)

        -- Position based on existing buttons
        if #self.buttons == 0 then
            btn:SetPoint("LEFT", 0, 0)
        else
            local prevBtn = self.buttons[#self.buttons]
            btn:SetPoint("LEFT", prevBtn, "RIGHT", 8, 0)
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
        local Theme = MedaUI.Theme
        for _, btn in ipairs(self.buttons) do
            if btn.isToggle and btn.getActive then
                if btn.getActive() then
                    btn:SetBackdropColor(unpack(Theme.gold))
                    btn.text:SetTextColor(0.1, 0.1, 0.1)
                else
                    btn:SetBackdropColor(unpack(Theme.button))
                    btn.text:SetTextColor(unpack(Theme.text))
                end
            end
        end
    end

    --- Clear all buttons
    function toolbar:ClearButtons()
        for _, btn in ipairs(self.buttons) do
            btn:Hide()
            btn:SetParent(nil)
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

        self:SetHeight(height)
    end

    --- Position the toolbar at screen center
    function toolbar:CenterOnScreen()
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    end

    --- Position the toolbar near a specific frame
    --- @param frame Frame The frame to position near
    --- @param offset number|nil Vertical offset (default: 60)
    function toolbar:PositionNear(frame, offset)
        offset = offset or 60
        self:ClearAllPoints()
        self:SetPoint("TOP", frame, "BOTTOM", 0, -offset)
    end

    -- Register for ESC to close
    if toolbar.closeable then
        tinsert(UISpecialFrames, name)
    end

    return toolbar
end
