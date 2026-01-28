--[[
    MedaUI TreeView Widget
    Expandable/collapsible tree for hierarchical data
]]

local MedaUI = LibStub("MedaUI-1.0")

--- Create a tree view
--- @param parent Frame Parent frame
--- @param width number Tree width
--- @param height number Tree height
--- @return Frame The tree view frame
function MedaUI:CreateTreeView(parent, width, height)
    local treeView = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    treeView:SetSize(width, height)
    treeView:SetBackdrop(self:CreateBackdrop(true))

    treeView.data = {}
    treeView.flattenedData = {}
    treeView.OnNodeClick = nil
    treeView.OnNodeExpand = nil
    treeView.OnNodeRightClick = nil
    treeView.selectedNode = nil
    treeView.indentSize = 16
    treeView.rowHeight = 22

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, treeView, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 4, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", -24, 4)

    -- Content frame
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(width - 28)
    scrollFrame:SetScrollChild(content)
    treeView.content = content
    treeView.scrollFrame = scrollFrame
    treeView.rowPool = {}
    treeView.visibleRows = {}

    -- Apply theme colors
    local function ApplyTheme()
        local Theme = MedaUI.Theme
        treeView:SetBackdropColor(unpack(Theme.backgroundDark))
        treeView:SetBackdropBorderColor(unpack(Theme.border))
    end
    treeView._ApplyTheme = ApplyTheme

    -- Register for theme updates
    treeView._themeHandle = MedaUI:RegisterThemedWidget(treeView, function()
        ApplyTheme()
        treeView:Refresh()
    end)

    -- Initial theme application
    ApplyTheme()

    -- Flatten tree data for display
    local function FlattenTree(nodes, depth, path, output)
        depth = depth or 0
        path = path or {}
        output = output or {}

        for i, node in ipairs(nodes) do
            local nodePath = {unpack(path)}
            nodePath[#nodePath + 1] = i

            output[#output + 1] = {
                node = node,
                depth = depth,
                path = nodePath,
                hasChildren = node.children and #node.children > 0,
                expanded = node.expanded or false,
            }

            if node.expanded and node.children then
                FlattenTree(node.children, depth + 1, nodePath, output)
            end
        end

        return output
    end

    -- Get row from pool
    local function GetRow(index)
        local row = treeView.rowPool[index]
        if not row then
            row = CreateFrame("Button", nil, content, "BackdropTemplate")
            row:SetSize(width - 28, treeView.rowHeight)
            row:SetBackdrop(MedaUI:CreateBackdrop(false))
            row:RegisterForClicks("LeftButtonUp", "RightButtonUp")

            -- Expand/collapse button
            row.expandBtn = CreateFrame("Button", nil, row)
            row.expandBtn:SetSize(16, 16)
            row.expandBtn:SetPoint("LEFT", 0, 0)

            row.expandBtn.text = row.expandBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            row.expandBtn.text:SetPoint("CENTER", 0, 0)
            row.expandBtn.text:SetText("+")

            -- Node label
            row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            row.label:SetPoint("LEFT", row.expandBtn, "RIGHT", 2, 0)
            row.label:SetPoint("RIGHT", -4, 0)
            row.label:SetJustifyH("LEFT")

            treeView.rowPool[index] = row
        end
        return row
    end

    -- Update display
    local function UpdateDisplay()
        local Theme = MedaUI.Theme

        -- Flatten current tree state
        treeView.flattenedData = FlattenTree(treeView.data)

        local totalHeight = #treeView.flattenedData * treeView.rowHeight
        content:SetHeight(math.max(totalHeight, height - 8))

        -- Hide all rows
        for _, row in ipairs(treeView.visibleRows) do
            row:Hide()
        end
        wipe(treeView.visibleRows)

        -- Create visible rows
        for i, item in ipairs(treeView.flattenedData) do
            local row = GetRow(i)
            row:SetPoint("TOPLEFT", 0, -((i - 1) * treeView.rowHeight))

            -- Indentation
            local indent = item.depth * treeView.indentSize
            row.expandBtn:SetPoint("LEFT", indent, 0)

            -- Expand button
            if item.hasChildren then
                row.expandBtn:Show()
                row.expandBtn.text:SetText(item.expanded and "-" or "+")
                row.expandBtn.text:SetTextColor(unpack(Theme.textDim))
                row.expandBtn:SetScript("OnClick", function()
                    item.node.expanded = not item.node.expanded
                    if treeView.OnNodeExpand then
                        treeView:OnNodeExpand(item.node, item.node.expanded)
                    end
                    UpdateDisplay()
                end)
            else
                row.expandBtn:Hide()
                row.expandBtn.text:SetText("")
            end

            -- Label
            row.label:SetText(item.node.label or "")
            row.label:SetTextColor(unpack(Theme.text))
            row.label:SetPoint("LEFT", row.expandBtn, "RIGHT", item.hasChildren and 2 or -12, 0)

            -- Selection highlight
            if treeView.selectedNode == item.node then
                row:SetBackdropColor(unpack(Theme.highlight))
            else
                row:SetBackdropColor(0, 0, 0, 0)
            end

            -- Row data
            row.nodeData = item

            -- Hover effect
            row:SetScript("OnEnter", function(self)
                if treeView.selectedNode ~= self.nodeData.node then
                    local Theme = MedaUI.Theme
                    self:SetBackdropColor(unpack(Theme.buttonHover))
                end
            end)

            row:SetScript("OnLeave", function(self)
                if treeView.selectedNode ~= self.nodeData.node then
                    self:SetBackdropColor(0, 0, 0, 0)
                end
            end)

            -- Click handlers
            row:SetScript("OnClick", function(self, button)
                if button == "LeftButton" then
                    treeView:SelectNode(self.nodeData.node)
                    if treeView.OnNodeClick then
                        treeView:OnNodeClick(self.nodeData.node, self.nodeData.path)
                    end
                elseif button == "RightButton" then
                    if treeView.OnNodeRightClick then
                        treeView:OnNodeRightClick(self.nodeData.node, self.nodeData.path)
                    end
                end
            end)

            row:Show()
            treeView.visibleRows[#treeView.visibleRows + 1] = row
        end
    end

    -- Mouse wheel scrolling
    treeView:EnableMouseWheel(true)
    treeView:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollFrame:GetVerticalScroll()
        local max = content:GetHeight() - (height - 8)
        local new = math.max(0, math.min(max, current - (delta * treeView.rowHeight * 3)))
        scrollFrame:SetVerticalScroll(new)
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
        UpdateDisplay()
    end

    --- Clear selection
    function treeView:ClearSelection()
        self.selectedNode = nil
        UpdateDisplay()
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
