---@meta

---@class LibStubRegistry
---@field libs table<string, table>
---@field minors table<string, integer>
---@overload fun(major: string): table, integer
---@overload fun(major: string, silent: false): table, integer
---@overload fun(major: string, silent: true): table|nil, integer|nil
LibStub = LibStub or {}

---@generic T: table
---@param major string
---@param minor integer|string
---@return T|nil library
---@return integer|nil oldMinor
function LibStub:NewLibrary(major, minor) end

---@generic T: table
---@param major string
---@overload fun(self: LibStubRegistry, major: string): T, integer
---@overload fun(self: LibStubRegistry, major: string, silent: false): T, integer
---@param silent? boolean
---@return T|nil library
---@return integer|nil minor
function LibStub:GetLibrary(major, silent) end

function LibStub:IterateLibraries() end
