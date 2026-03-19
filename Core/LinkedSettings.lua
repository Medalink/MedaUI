local MedaUI = LibStub("MedaUI-2.0")

local type = type
local pairs = pairs

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

local function ApplyDefaults(target, defaults)
    if type(defaults) ~= "table" then
        return target
    end

    target = type(target) == "table" and target or {}
    for key, value in pairs(defaults) do
        if target[key] == nil then
            target[key] = DeepCopy(value)
        end
    end
    return target
end

local function ResolveRoot(db, rootKey)
    if type(db) ~= "table" or type(rootKey) ~= "string" or rootKey == "" then
        return nil
    end

    local root = db[rootKey]
    if type(root) ~= "table" then
        root = {}
        db[rootKey] = root
    end

    root.shared = type(root.shared) == "table" and root.shared or {}
    root.groups = type(root.groups) == "table" and root.groups or {}
    root.links = type(root.links) == "table" and root.links or {}
    return root
end

function MedaUI:EnsureLinkedSettingsState(db, rootKey, groupIds, defaults)
    local root = ResolveRoot(db, rootKey)
    if not root then
        return nil
    end

    root.shared = ApplyDefaults(root.shared, defaults)

    if type(groupIds) == "table" then
        for _, groupId in ipairs(groupIds) do
            if type(groupId) == "string" and groupId ~= "" and groupId ~= "all" then
                root.groups[groupId] = type(root.groups[groupId]) == "table" and root.groups[groupId] or {}
                if root.links[groupId] == nil then
                    root.links[groupId] = true
                end
            end
        end
    end

    return root
end

function MedaUI:IsLinkedSettingsGroup(db, rootKey, groupId)
    if groupId == "all" then
        return true
    end

    local root = ResolveRoot(db, rootKey)
    if not root then
        return true
    end

    return root.links[groupId] ~= false
end

function MedaUI:SetLinkedSettingsGroupLinked(db, rootKey, groupId, linked, defaults)
    if groupId == "all" then
        return
    end

    local root = self:EnsureLinkedSettingsState(db, rootKey, { groupId }, defaults)
    if not root then
        return
    end

    if linked then
        root.links[groupId] = true
        root.groups[groupId] = {}
        return
    end

    root.links[groupId] = false
    root.groups[groupId] = self:GetResolvedLinkedSettings(db, rootKey, groupId, defaults)
end

function MedaUI:GetResolvedLinkedSettings(db, rootKey, groupId, defaults)
    local root = self:EnsureLinkedSettingsState(db, rootKey, groupId and { groupId } or nil, defaults)
    if not root then
        return {}
    end

    local resolved = DeepCopy(root.shared)
    if groupId and groupId ~= "all" and root.links[groupId] == false then
        for key, value in pairs(root.groups[groupId] or {}) do
            resolved[key] = DeepCopy(value)
        end
    end

    return ApplyDefaults(resolved, defaults)
end

function MedaUI:SetLinkedSettingsValue(db, rootKey, groupId, key, value, defaults)
    local root = self:EnsureLinkedSettingsState(db, rootKey, groupId and { groupId } or nil, defaults)
    if not root or type(key) ~= "string" or key == "" then
        return
    end

    if groupId and groupId ~= "all" and root.links[groupId] == false then
        root.groups[groupId][key] = DeepCopy(value)
    else
        root.shared[key] = DeepCopy(value)
    end
end
