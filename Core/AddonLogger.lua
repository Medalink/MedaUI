local MedaUI = LibStub("MedaUI-2.0")

local InCombatLockdown = InCombatLockdown
local print = print
local pcall = pcall
local tostring = tostring
local type = type
local unpack = unpack

local DEFAULT_LOG_POLICY = {
    enabled = true,
    minLevel = "WARN",
    combatMode = "always",
    chatFallback = false,
}

local LOG_LEVEL_ORDER = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4,
    OFF = 5,
}

local LOG_LEVEL_OPTIONS = {
    { label = "Debug", value = "DEBUG" },
    { label = "Info", value = "INFO" },
    { label = "Warn", value = "WARN" },
    { label = "Error", value = "ERROR" },
    { label = "Off", value = "OFF" },
}

local COMBAT_MODE_OPTIONS = {
    { label = "Always", value = "always" },
    { label = "Combat Only", value = "combat" },
    { label = "Out of Combat Only", value = "noncombat" },
}

local LEVEL_METHODS = {
    DEBUG = "DebugMsg",
    INFO = "Print",
    WARN = "Warn",
    ERROR = "Error",
}

local LEVEL_COLORS = {
    DEBUG = "|cff888888",
    INFO = "|cff88bbff",
    WARN = "|cffffcc00",
    ERROR = "|cffff6666",
}

local function DeepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, child in pairs(value) do
        copy[key] = DeepCopy(child)
    end
    return copy
end

local function NormalizeLevel(level)
    level = type(level) == "string" and level:upper() or "INFO"
    if not LOG_LEVEL_ORDER[level] then
        return "INFO"
    end
    return level
end

local function NormalizeCombatMode(combatMode)
    if combatMode == "combat" or combatMode == "noncombat" then
        return combatMode
    end
    return "always"
end

local function SafeToString(value)
    local ok, result = pcall(tostring, value)
    if ok and type(result) == "string" then
        return result
    end
    return "<unprintable>"
end

local function ResolveDebugAPI()
    local debugAPI = _G and (_G.MedaDebugAPI or _G.MedaDebug) or nil
    if type(debugAPI) == "table" then
        return debugAPI
    end
    return nil
end

function MedaUI:GetDefaultLogPolicy()
    return DeepCopy(DEFAULT_LOG_POLICY)
end

function MedaUI:GetLogLevelOptions()
    return DeepCopy(LOG_LEVEL_OPTIONS)
end

function MedaUI:GetCombatModeOptions()
    return DeepCopy(COMBAT_MODE_OPTIONS)
end

function MedaUI:NormalizeLogPolicy(policy)
    local normalized = type(policy) == "table" and DeepCopy(policy) or {}
    normalized.enabled = normalized.enabled ~= false
    normalized.minLevel = NormalizeLevel(normalized.minLevel)
    normalized.combatMode = NormalizeCombatMode(normalized.combatMode)
    normalized.chatFallback = normalized.chatFallback == true
    return normalized
end

function MedaUI:ShouldAllowLog(policy, level)
    local normalized = self:NormalizeLogPolicy(policy)
    level = NormalizeLevel(level)

    if not normalized.enabled or normalized.minLevel == "OFF" then
        return false
    end

    if LOG_LEVEL_ORDER[level] < LOG_LEVEL_ORDER[normalized.minLevel] then
        return false
    end

    local inCombat = InCombatLockdown and InCombatLockdown() or false
    if normalized.combatMode == "combat" and not inCombat then
        return false
    end
    if normalized.combatMode == "noncombat" and inCombat then
        return false
    end

    return true
end

function MedaUI:CreateAddonLogger(config)
    config = type(config) == "table" and config or {}

    local addonName = type(config.addonName) == "string" and config.addonName or "Addon"
    local addonColor = type(config.color) == "table" and config.color or { 0.6, 0.8, 1 }
    local prefix = type(config.prefix) == "string" and config.prefix or ("[" .. addonName .. "]")
    local state = {
        debugAPI = nil,
        registered = false,
    }

    local logger = {}

    local function GetPolicy()
        if type(config.getPolicy) == "function" then
            return MedaUI:NormalizeLogPolicy(config.getPolicy())
        end
        return MedaUI:GetDefaultLogPolicy()
    end

    local function SetPolicy(policy)
        local normalized = MedaUI:NormalizeLogPolicy(policy)
        if type(config.setPolicy) == "function" then
            config.setPolicy(normalized)
        end
        return normalized
    end

    local function EnsureRegistered(debugAPI)
        if state.registered or not debugAPI or type(debugAPI.RegisterAddon) ~= "function" then
            return
        end

        debugAPI:RegisterAddon(addonName, {
            color = addonColor,
            prefix = prefix,
            getLogPolicy = type(config.getPolicy) == "function" and config.getPolicy or nil,
            setLogPolicy = type(config.setPolicy) == "function" and config.setPolicy or nil,
        })
        state.registered = true
    end

    local function RefreshSink()
        local debugAPI = ResolveDebugAPI()
        if debugAPI then
            state.debugAPI = debugAPI
            EnsureRegistered(debugAPI)
        end
        return state.debugAPI
    end

    local function DispatchToDebugAPI(debugAPI, level, message, sourceInfo)
        if type(debugAPI.API) == "table" and type(debugAPI.API.Output) == "function" then
            return debugAPI.API:Output(addonName, message, level, sourceInfo)
        end

        local methodName = LEVEL_METHODS[level]
        if methodName and type(debugAPI[methodName]) == "function" then
            return debugAPI[methodName](debugAPI, addonName, message, sourceInfo)
        end

        if type(debugAPI.Output) == "function" then
            return debugAPI:Output(addonName, message, level, sourceInfo)
        end

        return nil
    end

    local function BuildChatPrefix(level)
        local color = LEVEL_COLORS[level] or LEVEL_COLORS.INFO
        return color .. prefix .. "|r"
    end

    function logger:GetPolicy()
        return GetPolicy()
    end

    function logger:SetPolicy(policy)
        return SetPolicy(policy)
    end

    function logger:RefreshSink()
        return RefreshSink()
    end

    function logger:HasSink()
        return RefreshSink() ~= nil
    end

    function logger:IsLevelConfigured(level)
        local policy = GetPolicy()
        level = NormalizeLevel(level)

        if not policy.enabled or policy.minLevel == "OFF" then
            return false
        end

        return LOG_LEVEL_ORDER[level] >= LOG_LEVEL_ORDER[policy.minLevel]
    end

    function logger:CanEmit(level)
        local policy = GetPolicy()
        if not MedaUI:ShouldAllowLog(policy, level) then
            return false
        end

        if RefreshSink() then
            return true
        end

        return policy.chatFallback == true
    end

    function logger:Emit(level, message, sourceInfo)
        level = NormalizeLevel(level)
        if not self:CanEmit(level) then
            return nil
        end

        local safeMessage = SafeToString(message)
        local debugAPI = RefreshSink()
        if debugAPI then
            return DispatchToDebugAPI(debugAPI, level, safeMessage, sourceInfo)
        end

        local chatPrefix = BuildChatPrefix(level)
        print(chatPrefix .. " " .. safeMessage)
        return safeMessage
    end

    function logger:EmitLazy(level, producer, sourceInfo)
        level = NormalizeLevel(level)
        if not self:CanEmit(level) then
            return nil
        end

        if type(producer) ~= "function" then
            return self:Emit(level, producer, sourceInfo)
        end

        local ok, message = pcall(producer)
        if not ok then
            return self:Emit("ERROR", "Log producer failed: " .. SafeToString(message), sourceInfo)
        end

        return self:Emit(level, message, sourceInfo)
    end

    function logger:GetColor()
        return unpack(addonColor)
    end

    return logger
end

function MedaUI:BuildLogPolicyControls(parent, getPolicy, setPolicy, opts)
    opts = type(opts) == "table" and opts or {}

    local width = opts.width or 240
    local includeChatFallback = opts.includeChatFallback == true
    local yOff = 0
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width + 20, 1)

    local function ReadPolicy()
        if type(getPolicy) == "function" then
            return MedaUI:NormalizeLogPolicy(getPolicy())
        end
        return MedaUI:GetDefaultLogPolicy()
    end

    local function WritePolicy(policy)
        if type(setPolicy) == "function" then
            setPolicy(MedaUI:NormalizeLogPolicy(policy))
        end
    end

    if type(opts.description) == "string" and opts.description ~= "" then
        local description = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        description:SetPoint("TOPLEFT", 0, yOff)
        description:SetPoint("RIGHT", container, "RIGHT", 0, 0)
        description:SetJustifyH("LEFT")
        description:SetWordWrap(true)
        description:SetText(opts.description)
        description:SetTextColor(unpack(MedaUI.Theme.textDim or { 0.7, 0.7, 0.7, 1 }))
        yOff = yOff - description:GetStringHeight() - 14
    end

    local enabledCheckbox = MedaUI:CreateCheckbox(container, opts.enabledLabel or "Enable logging")
    enabledCheckbox:SetPoint("TOPLEFT", 0, yOff)
    yOff = yOff - 30

    local minLevelDropdown = MedaUI:CreateLabeledDropdown(
        container,
        opts.minLevelLabel or "Minimum Level",
        width,
        MedaUI:GetLogLevelOptions()
    )
    minLevelDropdown:SetPoint("TOPLEFT", 0, yOff)
    yOff = yOff - 64

    local combatModeDropdown = MedaUI:CreateLabeledDropdown(
        container,
        opts.combatModeLabel or "Combat Mode",
        width,
        MedaUI:GetCombatModeOptions()
    )
    combatModeDropdown:SetPoint("TOPLEFT", 0, yOff)
    yOff = yOff - 64

    local chatFallbackCheckbox
    if includeChatFallback then
        chatFallbackCheckbox = MedaUI:CreateCheckbox(container, opts.chatFallbackLabel or "Send to chat when MedaDebug is unavailable")
        chatFallbackCheckbox:SetPoint("TOPLEFT", 0, yOff)
        yOff = yOff - 30
    end

    local function UpdatePolicy(mutator)
        local policy = ReadPolicy()
        mutator(policy)
        WritePolicy(policy)
        container:Refresh()
    end

    enabledCheckbox.OnValueChanged = function(_, checked)
        UpdatePolicy(function(policy)
            policy.enabled = checked
        end)
    end

    minLevelDropdown.OnValueChanged = function(_, value)
        UpdatePolicy(function(policy)
            policy.minLevel = value
        end)
    end

    combatModeDropdown.OnValueChanged = function(_, value)
        UpdatePolicy(function(policy)
            policy.combatMode = value
        end)
    end

    if chatFallbackCheckbox then
        chatFallbackCheckbox.OnValueChanged = function(_, checked)
            UpdatePolicy(function(policy)
                policy.chatFallback = checked
            end)
        end
    end

    function container:Refresh()
        local policy = ReadPolicy()
        enabledCheckbox:SetChecked(policy.enabled)
        minLevelDropdown:SetSelected(policy.minLevel)
        combatModeDropdown:SetSelected(policy.combatMode)
        if chatFallbackCheckbox then
            chatFallbackCheckbox:SetChecked(policy.chatFallback)
        end
    end

    container.enabledCheckbox = enabledCheckbox
    container.minLevelDropdown = minLevelDropdown
    container.combatModeDropdown = combatModeDropdown
    container.chatFallbackCheckbox = chatFallbackCheckbox
    container:SetHeight(math.abs(yOff) + 8)
    container:Refresh()

    return container
end
