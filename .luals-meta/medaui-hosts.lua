---@meta

---@alias ColorTuple number[]

---@class FontString
---@field GetStringWidth fun(self: FontString): number
---@field GetStringHeight fun(self: FontString): number

---@class Texture
---@field SetRotation fun(self: Texture, radians: number)

---@class MedaUITheme
---@field error ColorTuple?
---@field textDisabled ColorTuple?
---@field goldDim ColorTuple?
---@field input ColorTuple?
---@field menuBackground ColorTuple?
---@field backgroundLight ColorTuple?
---@field panelGlow ColorTuple?
---@field rowEven ColorTuple?
---@field rowOdd ColorTuple?
---@field accent ColorTuple?
---@field buttonDisabled ColorTuple?
---@field warning ColorTuple?

---@class MedaUIScrollFrame: Frame
---@field scrollContent Frame
---@field scrollFrame Frame
---@field SetContentHeight fun(self: MedaUIScrollFrame, height: number, refreshLayout?: boolean, preserveScroll?: boolean)
---@field SetScrollStep fun(self: MedaUIScrollFrame, step: number)
---@field ResetScroll fun(self: MedaUIScrollFrame)

---@class MedaUIPanelState

---@class MedaUIPanel: Frame
---@field GetContent fun(self: MedaUIPanel): Frame
---@field SetHeadless fun(self: MedaUIPanel, value: boolean)
---@field SetResizable fun(self: MedaUIPanel, enabled: boolean, options?: table)
---@field SetDragZone fun(self: MedaUIPanel, zone: Frame)
---@field GetState fun(self: MedaUIPanel): MedaUIPanelState
---@field RestoreState fun(self: MedaUIPanel, state: MedaUIPanelState)

---@class MedaUIButton: Frame
---@field SetPoint fun(self: MedaUIButton, ...)
---@field SetScript fun(self: MedaUIButton, scriptType: string, handler: function)

---@class MedaUITabBar: Frame
---@field OnTabChanged fun(self: MedaUITabBar, tabId: string)?

---@class MedaUILibrary
---@field Pixel table
---@field Theme MedaUITheme
---@field mediaPath string
---@field HostSupport table
---@field OptionsHostState table
---@field OptionsHostSidebar table
---@field OptionsHostView table
---@field WorkspaceHostSupport table
---@field WorkspaceHostNavigation table
---@field WorkspaceHostState table
---@field WorkspaceHostView table
---@field CreateBackdrop fun(self: MedaUILibrary, withInset?: boolean): table
---@field CreateScrollFrame fun(self: MedaUILibrary, parent: Frame, name?: string, width?: number, height?: number): MedaUIScrollFrame
---@field RegisterThemedWidget fun(self: MedaUILibrary, widget: Frame, refreshFunc: function): integer?
---@field ReleaseThemedWidgetTree fun(self: MedaUILibrary, widget: Frame)
---@field CreateButton fun(self: MedaUILibrary, parent: Frame, text: string, width?: number, height?: number): MedaUIButton
---@field CreateTabBar fun(self: MedaUILibrary, parent: Frame, tabs: table): MedaUITabBar
---@field CreatePanel fun(self: MedaUILibrary, name: string, width: number, height: number, title?: string): MedaUIPanel
---@field PlaySound fun(self: MedaUILibrary, name: string)
---@field CreateOptionsHost fun(self: MedaUILibrary, config?: table): table
---@field CreateWorkspaceHost fun(self: MedaUILibrary, parent: Frame, config?: table): WorkspaceHostShell

---@class OptionsHostSidebarButton: Frame
---@field label FontString
---@field _getEnabled fun(): boolean
---@field _refresh fun()
---@field SetHeight fun(self: OptionsHostSidebarButton, height: number)
---@field SetPoint fun(self: OptionsHostSidebarButton, ...)
---@field SetBackdrop fun(self: OptionsHostSidebarButton, backdrop: table)
---@field SetBackdropColor fun(self: OptionsHostSidebarButton, ...)
---@field SetScript fun(self: OptionsHostSidebarButton, scriptType: string, handler: function)
---@field CreateFontString fun(self: OptionsHostSidebarButton, name?: string, layer?: string, inheritsFrom?: string): FontString?
---@field CreateTexture fun(self: OptionsHostSidebarButton, name?: string, layer?: string, subLevel?: number): Texture?

---@class OptionsHostLegendEntry: Frame
---@field dot Texture
---@field label FontString

---@class WorkspaceFreshnessSource
---@field id string?
---@field label string?
---@field lastFetched number?
---@field color ColorTuple?

---@class WorkspaceFreshnessRow: Frame
---@field text FontString
---@field state string?
---@field sourceColor ColorTuple?
---@field source WorkspaceFreshnessSource?
---@field _applyState fun(self: WorkspaceFreshnessRow)

---@class WorkspaceFreshnessStrip: Frame
---@field sources WorkspaceFreshnessSource[]
---@field rows WorkspaceFreshnessRow[]
---@field divider Texture
---@field label FontString
---@field listHost Frame
---@field SetSources fun(self: WorkspaceFreshnessStrip, sources: WorkspaceFreshnessSource[]?)

---@class WorkspaceHostNavButton: Frame
---@field isGroup boolean
---@field enabled boolean
---@field expanded boolean
---@field _navItemHeight integer
---@field _navGroupHeight integer
---@field text FontString
---@field chevron Texture
---@field pageId string?
---@field ApplyVisualState fun(self: WorkspaceHostNavButton)
---@field SetBackdrop fun(self: WorkspaceHostNavButton, backdrop: table)
---@field SetBackdropColor fun(self: WorkspaceHostNavButton, ...)
---@field SetScript fun(self: WorkspaceHostNavButton, scriptType: string, handler: function)
---@field CreateFontString fun(self: WorkspaceHostNavButton, name?: string, layer?: string, inheritsFrom?: string): FontString?
---@field CreateTexture fun(self: WorkspaceHostNavButton, name?: string, layer?: string, subLevel?: number): Texture?

---@class WorkspaceNavItem
---@field pageId string?
---@field label string?
---@field enabled boolean?
---@field expanded boolean?
---@field children WorkspaceNavItem[]?

---@class WorkspaceHostShell: Frame
---@field navItems WorkspaceNavItem[]
---@field navButtons table<string, WorkspaceHostNavButton>
---@field activePage string?
---@field pageRegistry table<string, table>
---@field pageCache table<string, table>
---@field pageOrder string[]
---@field _layoutRefreshPending boolean
---@field navPane Frame
---@field navFreshness WorkspaceFreshnessStrip
---@field navScroll MedaUIScrollFrame
---@field divider Texture
---@field header Frame
---@field toolbar Frame
---@field headerText Frame
---@field pageTitle FontString
---@field pageSubtitle FontString
---@field pageSummary FontString
---@field contentHost Frame
---@field contentScroll MedaUIScrollFrame
---@field content Frame
---@field OnGroupToggle fun(self: WorkspaceHostShell, pageId: string?, expanded: boolean)?
---@field OnNavigate fun(self: WorkspaceHostShell, pageId: string?)?
---@field SetNavigation fun(self: WorkspaceHostShell, items: WorkspaceNavItem[]?)
---@field SetNavigationItemEnabled fun(self: WorkspaceHostShell, pageId: string, enabled: boolean)
---@field SetPageTitle fun(self: WorkspaceHostShell, title: string?, subtitle: string?)
---@field SetPageSummary fun(self: WorkspaceHostShell, text: string?, tone: string?)
---@field GetToolbar fun(self: WorkspaceHostShell): Frame
---@field GetContent fun(self: WorkspaceHostShell): Frame
---@field ClearContent fun(self: WorkspaceHostShell)
---@field SetContentHeight fun(self: WorkspaceHostShell, height: number?)
---@field SetFreshnessSources fun(self: WorkspaceHostShell, sources: WorkspaceFreshnessSource[]?)
---@field RefreshNavigation fun(self: WorkspaceHostShell)
---@field SetActivePage fun(self: WorkspaceHostShell, pageId: string?)
