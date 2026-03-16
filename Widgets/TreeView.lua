--[[
    MedaUI TreeView Widget
    Expandable/collapsible tree for hierarchical data
]]

local MedaUI = LibStub("MedaUI-2.0")
---@cast MedaUI MedaUILibrary
local Pixel = LibStub("MedaUI-2.0").Pixel

local function TreeRow_OnEnter(self)
    local tv = self._treeView
    if tv and tv.selectedNode ~= self._node then
        local theme = MedaUI.Theme
        self:SetBackdropColor(unpack(theme.buttonHover))
    end
end

local function TreeRow_OnLeave(self)
    local tv = self._treeView
    if tv and tv.selectedNode ~= self._node then
        self:SetBackdropColor(0, 0, 0, 0)
    end
end

local function TreeRow_OnClick(self, button)
    local tv = self._treeView
    if not tv then return end
    if button == "LeftButton" then
        tv:SelectNode(self._node)
        if tv.OnNodeClick then
            tv:OnNodeClick(self._node, self._path)
        end
    elseif button == "RightButton" then
        if tv.OnNodeRightClick then
            tv:OnNodeRightClick(self._node, self._path)
        end
    end
end

local function ExpandBtn_OnClick(self)
    local row = self:GetParent()
    local tv = row._treeView
    if not tv then return end
    local node = row._node
    node.expanded = not node.expanded
    if tv.OnNodeExpand then
        tv:OnNodeExpand(node, node.expanded)
    end
    tv:Refresh()
end

--- Create a tree view
--- @param parent Frame Parent frame
--- @param width number Tree width
--- @param height number Tree height
--- @return Frame The tree view frame
function MedaUI.CreateTreeView(library, parent, width, height)
    local treeView = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    Pixel.SetSize(treeView, width, height)
    treeView:SetBackdrop(library:CreateBackdrop(true))

    treeView.data = {}
    treeView.flattenedData = {}
    treeView.OnNodeClick = nil
    treeView.OnNodeExpand = nil
    treeView.OnNodeRightClick = nil
    treeView.selectedNode = nil
    treeView.indentSize = 16
    treeView.rowHeight = 22

    -- Scroll frame (AF custom scrollbar)
    local scrollParent = library:CreateScrollFrame(treeView)
    Pixel.SetPoint(scrollParent, "TOPLEFT", 4, -4)
    Pixel.SetPoint(scrollParent, "BOTTOMRIGHT", -4, 4)
    scrollParent:SetScrollStep(66)

    local scrollFrame = scrollParent.scrollFrame
    local content = scrollParent.scrollContent
    treeView.content = content
    treeView.scrollParent = scrollParent
    treeView.rowPool = {}
    treeView.visibleRows = {}

    local visibleRowCount = math.ceil(height / treeView.rowHeight) + 1

    -- Apply theme colors
    local function ApplyTheme()
        local theme = MedaUI.Theme
        treeView:SetBackdropColor(unpack(theme.backgroundDark))
        treeView:SetBackdropBorderColor(unpack(theme.border))
    end
    treeView._ApplyTheme = ApplyTheme

    treeView._themeHandle = MedaUI:RegisterThemedWidget(treeView, function()
        ApplyTheme()
        treeView:Refresh()
    end)

    ApplyTheme()

    -- Flatten tree data for display (avoids {unpack(path)} per node)
    local pathBuf = {}
    local function FlattenTree(nodes, depth, output)
        for i, node in ipairs(nodes) do
            depth = depth or 0
            pathBuf[depth + 1] = i
            -- Build path by copying only the needed portion of the buffer
            local nodePath = {}
            for d = 1, depth + 1 do nodePath[d] = pathBuf[d] end

            output[#output + 1] = {
                node = node,
                depth = depth,
                path = nodePath,
                hasChildren = node.children and #node.children > 0,
                expanded = node.expanded or false,
            }

            if node.expanded and node.children then
                FlattenTree(node.children, depth + 1, output)
            end
        end
        return output
    end

    -- Slot-based row pool
    local function GetRow(slot)
        local row = treeView.rowPool[slot]
        if not row then
            row = CreateFrame("Button", nil, content, "BackdropTemplate")
            Pixel.SetSize(row, width - 28, treeView.rowHeight)
            row:SetBackdrop(library:CreateBackdrop(false))
            row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            row._treeView = treeView

            row.expandBtn = CreateFrame("Button", nil, row)
            Pixel.SetSize(row.expandBtn, 16, 16)
            Pixel.SetPoint(row.expandBtn, "LEFT", 0, 0)

            row.expandBtn.text = row.expandBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            Pixel.SetPoint(row.expandBtn.text, "CENTER", 0, 0)

            row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            Pixel.SetPoint(row.label, "LEFT", row.expandBtn, "RIGHT", 2, 0)
            Pixel.SetPoint(row.label, "RIGHT", -4, 0)
            row.label:SetJustifyH("LEFT")

            row:SetScript("OnEnter", TreeRow_OnEnter)
            row:SetScript("OnLeave", TreeRow_OnLeave)
            row:SetScript("OnClick", TreeRow_OnClick)
            row.expandBtn:SetScript("OnClick", ExpandBtn_OnClick)

            treeView.rowPool[slot] = row
        end
        return row
    end

    -- Render only the visible portion of flattenedData
    local function RenderVisible()
        local Theme = MedaUI.Theme
        local flat = treeView.flattenedData
        local rh = treeView.rowHeight

        for _, row in ipairs(treeView.visibleRows) do
            row:Hide()
        end
        wipe(treeView.visibleRows)

        if #flat == 0 then return end

        local scrollPos = scrollFrame:GetVerticalScroll()
        local firstVisible = math.floor(scrollPos / rh) + 1
        local lastVisible = math.min(firstVisible + visibleRowCount, #flat)

        local slot = 0
        for i = firstVisible, lastVisible do
            slot = slot + 1
            local item = flat[i]
            local row = GetRow(slot)

            row:ClearAllPoints()
            Pixel.SetPoint(row, "TOPLEFT", 0, -((i - 1) * rh))

            local indent = item.depth * treeView.indentSize
            row.expandBtn:ClearAllPoints()
            Pixel.SetPoint(row.expandBtn, "LEFT", indent, 0)

            if item.hasChildren then
                row.expandBtn:Show()
                row.expandBtn.text:SetText(item.expanded and "-" or "+")
                row.expandBtn.text:SetTextColor(unpack(Theme.textDim))
            else
                row.expandBtn:Hide()
                row.expandBtn.text:SetText("")
            end

            row.label:SetText(item.node.label or "")
            row.label:SetTextColor(unpack(Theme.text))
            row.label:ClearAllPoints()
            Pixel.SetPoint(row.label, "LEFT", row.expandBtn, "RIGHT", item.hasChildren and 2 or -12, 0)
            Pixel.SetPoint(row.label, "RIGHT", -4, 0)

            if treeView.selectedNode == item.node then
                row:SetBackdropColor(unpack(Theme.highlight))
            else
                row:SetBackdropColor(0, 0, 0, 0)
            end

            row._node = item.node
            row._path = item.path
            row.nodeData = item

            row:Show()
            treeView.visibleRows[#treeView.visibleRows + 1] = row
        end
    end

    -- Full update: flatten then render visible
    local function UpdateDisplay()
        wipe(treeView.flattenedData)
        FlattenTree(treeView.data, 0, treeView.flattenedData)

        local totalHeight = #treeView.flattenedData * treeView.rowHeight
        Pixel.SetHeight(content, math.max(totalHeight, height - 8))

        RenderVisible()
    end

    -- Re-render visible rows on scroll
    scrollFrame:HookScript("OnVerticalScroll", function()
        RenderVisible()
    end)

    --- Set the tree data
    --- @param data table Array of {label, expanded?, children?} nodes
    function treeView:SetData(data)
        self.data = data or {}
        self.selectedNode = nil
        UpdateDisplay()
    end

    --- Select a node
    --- @param node table The node to select
    function treeView:SelectNode(node)
        self.selectedNode = node
        RenderVisible()
    end

    --- Clear selection
    function treeView:ClearSelection()
        self.selectedNode = nil
        RenderVisible()
    end

    --- Expand all nodes
    function treeView:ExpandAll()
        local function ExpandNodes(nodes)
            for _, node in ipairs(nodes) do
                if node.children and #node.children > 0 then
                    node.expanded = true
                    ExpandNodes(node.children)
                end
            end
        end
        ExpandNodes(self.data)
        UpdateDisplay()
    end

    --- Collapse all nodes
    function treeView:CollapseAll()
        local function CollapseNodes(nodes)
            for _, node in ipairs(nodes) do
                node.expanded = false
                if node.children then
                    CollapseNodes(node.children)
                end
            end
        end
        CollapseNodes(self.data)
        UpdateDisplay()
    end

    --- Expand to a specific path
    --- @param path table Array of indices to expand
    function treeView:ExpandPath(path)
        local current = self.data
        for i, idx in ipairs(path) do
            if current[idx] then
                if i < #path and current[idx].children then
                    current[idx].expanded = true
                    current = current[idx].children
                end
            else
                break
            end
        end
        UpdateDisplay()
    end

    --- Refresh the display
    function treeView:Refresh()
        UpdateDisplay()
    end

    --- Get the selected node
    --- @return table|nil The selected node
    function treeView:GetSelectedNode()
        return self.selectedNode
    end

    return treeView
end
