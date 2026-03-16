--[[
    MedaUI bootstrap
    Registers the shared embedded library before the service/widget layers load.
]]

local MAJOR, MINOR = "MedaUI-2.0", 1
local MedaUI = LibStub:NewLibrary(MAJOR, MINOR)
if not MedaUI then return end

MedaUI.MAJOR = MAJOR
MedaUI.MINOR = MINOR
