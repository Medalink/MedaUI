--[[
    MedaUI SchemaForm Widget
    Dynamic form that renders controls from a declarative schema.
    Each field definition maps to an existing MedaUI labeled widget.
]]

local MedaUI = LibStub("MedaUI-1.0")
local Pixel = LibStub("MedaUI-1.0").Pixel

local DEFAULT_LABEL_WIDTH = 100
local FIELD_SPACING = 8
local CONTROL_WIDTH_DEFAULT = 200

local type = type
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local tonumber = tonumber

--- Create a schema-driven form.
--- @param parent Frame Parent frame
--- @param width number Form width
--- @param config table Configuration
--- @return Frame The schema form widget
---
--- Config keys:
---   schema     (table)        -- array of field definitions
---   values     (table)        -- initial values keyed by field name
---   onChange   (function|nil) -- function(fieldName, newValue) on any change
---   labelWidth (number, default 100) -- label column width
function MedaUI:CreateSchemaForm(parent, width, config)
    config = config or {}

    local form = CreateFrame("Frame", nil, parent)
    Pixel.SetWidth(form, width)

    form._schema = config.schema or {}
    form._values = config.values or {}
    form._onChange = config.onChange
    form._labelWidth = config.labelWidth or DEFAULT_LABEL_WIDTH
    form._controls = {}
    form._totalHeight = 0

    -- Theme
    local function ApplyTheme()
        -- Controls are individually themed; nothing to do at form level
    end
    form._ApplyTheme = ApplyTheme
    form._themeHandle = MedaUI:RegisterThemedWidget(form, ApplyTheme)

    -- ----------------------------------------------------------------
    -- Field builders (one per supported type)
    -- ----------------------------------------------------------------

    local fieldBuilders = {}

    fieldBuilders["number"] = function(parentFrame, field, controlWidth)
        local min = field.min or 0
        local max = field.max or 100
        local step = field.step or 1
        local ctrl = MedaUI:CreateLabeledSlider(parentFrame, field.label or field.name, controlWidth, min, max, step)
        ctrl.OnValueChanged = function(_, value)
            form._values[field.name] = value
            if form._onChange then form._onChange(field.name, value) end
        end
        return ctrl, ctrl:GetHeight()
    end

    fieldBuilders["string"] = function(parentFrame, field, controlWidth)
        local ctrl = MedaUI:CreateLabeledEditBox(parentFrame, field.label or field.name, controlWidth)
        if field.placeholder and ctrl:GetControl().SetPlaceholderText then
            ctrl:GetControl():SetPlaceholderText(field.placeholder)
        end
        ctrl.OnEnterPressed = function(_, text)
            form._values[field.name] = text
            if form._onChange then form._onChange(field.name, text) end
        end
        ctrl:GetControl():HookScript("OnEditFocusLost", function(self)
            local text = self:GetText()
            form._values[field.name] = text
            if form._onChange then form._onChange(field.name, text) end
        end)
        return ctrl, ctrl:GetHeight()
    end

    fieldBuilders["boolean"] = function(parentFrame, field)
        local ctrl = MedaUI:CreateCheckbox(parentFrame, field.label or field.name)
        ctrl.OnValueChanged = function(_, checked)
            form._values[field.name] = checked
            if form._onChange then form._onChange(field.name, checked) end
        end
        return ctrl, 22
    end

    fieldBuilders["select"] = function(parentFrame, field, controlWidth)
        local options = field.options or {}
        local ctrl = MedaUI:CreateLabeledDropdown(parentFrame, field.label or field.name, controlWidth, options)
        ctrl.OnValueChanged = function(_, value)
            form._values[field.name] = value
            if form._onChange then form._onChange(field.name, value) end
        end
        return ctrl, ctrl:GetHeight()
    end

    fieldBuilders["spellIds"] = function(parentFrame, field, controlWidth)
        local ctrl = MedaUI:CreateLabeledEditBox(parentFrame, field.label or "Spell IDs", controlWidth)
        ctrl:GetControl():HookScript("OnEditFocusLost", function(self)
            local raw = self:GetText() or ""
            local ids = {}
            for id in raw:gmatch("(%d+)") do
                local n = tonumber(id)
                if n and n > 0 then
                    ids[#ids + 1] = n
                end
            end
            form._values[field.name] = ids
            if form._onChange then form._onChange(field.name, ids) end
        end)
        ctrl.OnEnterPressed = function(_, text)
            local ids = {}
            for id in text:gmatch("(%d+)") do
                local n = tonumber(id)
                if n and n > 0 then ids[#ids + 1] = n end
            end
            form._values[field.name] = ids
            if form._onChange then form._onChange(field.name, ids) end
        end
        return ctrl, ctrl:GetHeight()
    end

    fieldBuilders["prophecyRef"] = function(parentFrame, field, controlWidth)
        local getOptions = field.getOptions or function() return {} end
        local ctrl = MedaUI:CreateLabeledDropdown(parentFrame, field.label or "Prophecy", controlWidth, getOptions())
        ctrl.OnValueChanged = function(_, value)
            form._values[field.name] = value
            if form._onChange then form._onChange(field.name, value) end
        end
        ctrl._getOptions = getOptions
        return ctrl, ctrl:GetHeight()
    end

    -- ----------------------------------------------------------------
    -- Build/rebuild the form from schema
    -- ----------------------------------------------------------------

    local function BuildForm()
        -- Hide and release existing controls
        for _, entry in ipairs(form._controls) do
            if entry.widget then entry.widget:Hide() end
        end
        wipe(form._controls)

        local yOff = 0
        local controlWidth = math.min(width - 20, CONTROL_WIDTH_DEFAULT)

        for _, field in ipairs(form._schema) do
            local builder = fieldBuilders[field.type]
            if builder then
                local widget, h = builder(form, field, controlWidth)
                widget:ClearAllPoints()
                Pixel.SetPoint(widget, "TOPLEFT", form, "TOPLEFT", 0, -yOff)

                -- Set initial value
                local val = form._values[field.name]
                if val == nil then val = field.default end

                if field.type == "number" and val then
                    widget:SetValue(val)
                elseif field.type == "string" and val then
                    widget:SetText(tostring(val))
                elseif field.type == "boolean" and val ~= nil then
                    widget:SetChecked(val)
                elseif field.type == "select" and val then
                    widget:SetSelected(val)
                elseif field.type == "spellIds" and val then
                    local parts = {}
                    for _, id in ipairs(val) do parts[#parts + 1] = tostring(id) end
                    widget:SetText(table.concat(parts, ", "))
                elseif field.type == "prophecyRef" and val then
                    widget:SetSelected(val)
                end

                widget:Show()
                form._controls[#form._controls + 1] = { name = field.name, widget = widget, field = field }
                yOff = yOff + h + FIELD_SPACING
            end
        end

        form._totalHeight = yOff
        Pixel.SetHeight(form, math.max(yOff, 10))
    end

    -- ----------------------------------------------------------------
    -- Public API
    -- ----------------------------------------------------------------

    --- Rebuild the form from a new schema.
    --- @param schema table Array of field definitions
    function form:SetSchema(schema)
        self._schema = schema or {}
        BuildForm()
    end

    --- Update all field values without rebuilding.
    --- @param values table Values keyed by field name
    function form:SetValues(values)
        self._values = values or {}
        for _, entry in ipairs(self._controls) do
            local val = self._values[entry.name]
            if val == nil then val = entry.field.default end
            local ftype = entry.field.type

            if ftype == "number" and val then
                entry.widget:SetValue(val)
            elseif ftype == "string" and val then
                entry.widget:SetText(tostring(val))
            elseif ftype == "boolean" and val ~= nil then
                entry.widget:SetChecked(val)
            elseif ftype == "select" and val then
                entry.widget:SetSelected(val)
            elseif ftype == "spellIds" and val then
                local parts = {}
                for _, id in ipairs(val) do parts[#parts + 1] = tostring(id) end
                entry.widget:SetText(table.concat(parts, ", "))
            elseif ftype == "prophecyRef" and val then
                if entry.widget._getOptions then
                    entry.widget:SetOptions(entry.widget._getOptions())
                end
                entry.widget:SetSelected(val)
            end
        end
    end

    --- Get the current values table.
    --- @return table Values keyed by field name
    function form:GetValues()
        return self._values
    end

    --- Update the onChange callback.
    --- @param fn function|nil function(fieldName, newValue)
    function form:SetOnChange(fn)
        self._onChange = fn
    end

    --- Get the total rendered height of the form.
    --- @return number
    function form:GetHeight()
        return self._totalHeight
    end

    -- Initial build
    if #form._schema > 0 then
        BuildForm()
    end

    return form
end
