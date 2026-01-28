--[[
    MedaUI Minimap Button Widget
    Creates minimap buttons using LibDBIcon (standard library)
]]

local MedaUI = LibStub("MedaUI-1.0")

-- Try to get LibDataBroker and LibDBIcon
local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LibStub("LibDBIcon-1.0", true)

--- Create a minimap button using LibDBIcon
--- @param name string Unique button name
--- @param icon string|number Icon texture path or fileID
--- @param onClick function|nil Left-click handler
--- @param onRightClick function|nil Right-click handler
--- @param savedVarsTable table|nil Table to store minimap button position (requires .minimap subtable)
--- @return table|nil The data broker object, or nil if libraries not available
function MedaUI:CreateMinimapButton(name, icon, onClick, onRightClick, savedVarsTable)
    if not LDB or not LDBIcon then
        print("|cFFFF0000MedaUI:|r LibDataBroker-1.1 or LibDBIcon-1.0 not found. Minimap button disabled.")
        return nil
    end

    -- Create the data broker object
    local dataObj = LDB:NewDataObject(name, {
        type = "launcher",
        icon = icon,
        OnClick = function(self, button)
            if button == "LeftButton" and onClick then
                onClick()
            elseif button == "RightButton" and onRightClick then
                onRightClick()
            end
        end,
        OnTooltipShow = function(tooltip)
            local Theme = MedaUI.Theme
            tooltip:AddLine(name, unpack(Theme.gold))
            tooltip:AddLine(" ")
            tooltip:AddLine("Left-click to open settings", unpack(Theme.text))
            tooltip:AddLine("Right-click for options", unpack(Theme.text))
            tooltip:AddLine("Drag to move", unpack(Theme.textDim))
        end,
    })

    -- Register with LibDBIcon
    -- Use provided saved vars table or create a default
    local minimapData = savedVarsTable and savedVarsTable.minimap or { hide = false }
    LDBIcon:Register(name, dataObj, minimapData)

    -- Return the data object for further customization
    dataObj.ShowButton = function()
        LDBIcon:Show(name)
    end

    dataObj.HideButton = function()
        LDBIcon:Hide(name)
    end

    dataObj.IsButtonShown = function()
        return not LDBIcon:IsButtonHidden(name)
    end

    dataObj.SetIcon = function(self, newIcon)
        self.icon = newIcon
    end

    return dataObj
end
