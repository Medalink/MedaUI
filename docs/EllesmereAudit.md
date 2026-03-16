# MedaUI Ellesmere Audit

## Current Architecture Summary

MedaUI is a shared UI library, not a full addon feature module. That changes the exact lifecycle expectations, but the Ellesmere-style rules still apply:

- shared core should load explicitly and minimally
- host shells should be separated from generic primitives
- heavy or stateful UI work should happen only when requested
- recurring runtime work should be narrow and short-lived

Current MedaUI shape before this refactor:

- `MedaUI.lua` owned core theme registration, media lookup, sound helpers, status-color helpers, and shared factories
- `Pixel.lua` owned low-level layout and scroll mechanics
- `Themes/*.lua` registered theme data
- `Widgets/*.lua` defined reusable primitives and composites
- `Hosts/*.lua` existed as higher-level shells, but they were not loaded by `MedaUI.toc`
- `Core/Bootstrap.lua` existed, but it was also not loaded by `MedaUI.toc`

## Ellesmere Gaps

### Core Lifecycle Boundary

- `Core/Bootstrap.lua` was not in the `.toc`, so the library had no explicit core registration boundary.
- `MedaUI.lua` assumed `LibStub("MedaUI-2.0")` was already registered by something else. That is not a disciplined startup path.
- `Hosts/Hosts.xml` was not in the `.toc`, so the shared host-shell layer existed in the repo but not in the public library load path.

### Shared-Core Ownership

- The theme registry held strong references to registered widgets and had no release path for discarded widget trees.
- Page invalidation and detached temporary config frames could leave themed widgets retained indefinitely.
- This violates Ellesmere-style ownership discipline because shared core should not keep stale runtime UI alive.

### Runtime Performance

- `Widgets/ReorderableList.lua` installed a permanent `OnUpdate` on every list instance even when idle.
- `Widgets/NotificationBanner.lua` used a per-frame countdown update for simple timed dismissal.
- `Widgets/Effects.lua` used a manual `OnUpdate` loop for pulse animation instead of Blizzard animation groups.

### Remaining Structural Debt

- the core split is in place, but it still needs to stay enforced as the permanent ownership boundary instead of drifting back into `MedaUI.lua`
- `Hosts/OptionsHost.lua` is no longer carrying most of its shell/view construction, but the remaining orchestration path is still the central module contract and cache owner, so that boundary should stay narrow.
- `Hosts/WorkspaceHost.lua` is now reduced to page-state orchestration, but its validation story still depends on repository-wide WoW globals/stubs being modeled cleanly for LuaLS.
- There is still no dedicated test harness or perf-check routine for widget lifecycles.

## Refactor Applied In This Pass

### Load Order

- added `Core/Bootstrap.lua` to `MedaUI.toc`
- added `Hosts/Hosts.xml` to `MedaUI.toc`
- aligned `.toc` dependency loading with `MedaUI.xml` so minimap-button support is not packaging-mode dependent

### Theme Registry Safety

- separated refresh callbacks from widget references so widget ownership can be weak on the shared-core side
- added widget-to-handle tracking
- added explicit release helpers for single widgets and entire widget trees
- updated host invalidation paths to release themed trees only when frames are truly discarded, not when cached UI is merely detached

### Core Split

- reduced `MedaUI.lua` to a thin root initializer
- moved theme ownership and widget-theme lifecycle into `Core/ThemeRegistry.lua`
- moved sound/status/backdrop/scroll helpers into `Core/RuntimeHelpers.lua`
- moved media/font/sound registries into `Core/MediaRegistry.lua`

### Host Support

- extracted shared host helpers into `Hosts/HostSupport.lua`
- unified page normalization and frame teardown across options/workspace shells
- removed a broken internal `Orphan(...)` call path in `OptionsHost`
- moved options host module/page cache primitives into `Hosts/OptionsHostState.lua`
- moved options host sidebar grouping/sorting policy into `Hosts/OptionsHostSidebar.lua`
- moved options host shell/view construction into `Hosts/OptionsHostView.lua` so `OptionsHost.lua` now owns orchestration and cache policy instead of sidebar/footer/legend/widget assembly
- moved workspace host freshness support into `Hosts/WorkspaceHostSupport.lua`
- moved workspace host navigation rendering/state helpers into `Hosts/WorkspaceHostNavigation.lua`
- moved workspace host page registry/cache behavior into `Hosts/WorkspaceHostState.lua`
- moved workspace host shell/view construction into `Hosts/WorkspaceHostView.lua` so `WorkspaceHost.lua` now owns page registration, invalidation, refresh, and deferred layout refresh only
- removed dead `activePageState` cleanup bookkeeping from `OptionsHost`
- fixed dynamic sidebar/footer rebuild paths so discarded themed widgets are destroyed instead of merely hidden
- prevented duplicate `WorkspaceHost:RegisterPage(...)` calls from growing `pageOrder`

### Hot-Path Cleanup

- reordered-list drag tracking now enables `OnUpdate` only while drag detection or dragging is active
- notification-banner countdown now uses timers/tickers instead of a permanent frame update handler
- pulse effect now uses animation groups instead of a manual `OnUpdate`

## Recommended Next Phases

### Phase 1

- keep the new core split as the permanent load contract and prevent new shared services from drifting back into `MedaUI.lua`

Acceptance:

- core files have single-purpose ownership
- `.toc` load order documents core, themes, widgets, and hosts clearly

### Phase 2

- keep `Hosts/OptionsHost.lua` focused on orchestration only and avoid letting shell/view code drift back into it
- tighten the remaining host registration contract so page invalidation, restore, and cleanup remain standardized
- keep `Hosts/WorkspaceHost.lua` focused on orchestration only and avoid letting shell/view code drift back into it

Acceptance:

- host shell owns navigation and cache policy only
- module/page builders own their content only

### Phase 3

- create a lightweight widget verification addon or harness for:
  - theme switching
  - repeated open/close cycles
  - page invalidation
  - drag widgets

Acceptance:

- repeated build/destroy cycles do not grow themed-widget registry state
- timed widgets stop all recurring work when hidden

## Risk Notes

- Loading `Hosts/Hosts.xml` exposes APIs that were already present in the repo; if a consumer depended on those files not loading, that consumer was already depending on a broken packaging boundary.
- Weak widget references reduce stale retention pressure, but explicit destroy paths are still the correct standard for temporary UI.

## Validation Notes

- targeted `luacheck` now passes cleanly for `Hosts/OptionsHost.lua`, `Hosts/OptionsHostView.lua`, `Hosts/WorkspaceHost.lua`, `Hosts/WorkspaceHostNavigation.lua`, `Hosts/WorkspaceHostSupport.lua`, `Hosts/WorkspaceHostView.lua`, `Widgets/Dropdown.lua`, `Widgets/InfoPanel.lua`, `Widgets/Panel.lua`, `Widgets/ReorderableList.lua`, `Widgets/LabeledControl.lua`, `.luals-meta/medaui-hosts.lua`, `.luals-meta/medaui-widgets.lua`, `.luals-meta/libstub.lua`, and `Pixel.lua`
- full-repo `luacheck` dropped from 502 warnings to 366 warnings, largely by removing avoidable host/widget-layer `self` shadowing noise and dead locals on the touched surface
- LuaLS config is now in CLI-compatible `Lua.*` form, ignores vendored `Libs`, disables diagnostics for library files, and includes `.luals-meta/libstub.lua`, `.luals-meta/medaui-hosts.lua`, `.luals-meta/medaui-widgets.lua`, plus a root-safe wrapper at `tools/validate-lua.ps1`
- LuaLS is no longer dominated by missing WoW globals or bogus Lua 5.4 `deprecated` noise when run through the repo config/workflow
- `Hosts/` now validates cleanly under LuaLS when run through `tools/validate-lua.ps1`; the remaining LuaLS debt is outside the host shell after adding WoW UI metadata for custom host frame shapes
- full-workspace LuaLS is down to 1791 diagnostics; the top buckets are still `inject-field` (789), `undefined-field` (554), and `need-check-nil` (406), with `undefined-global` reduced to a small residual set instead of dominating the report
- after the widget typing pass, the biggest remaining LuaLS files are `Widgets/HUDRow.lua`, `Widgets/StatusRow.lua`, `Widgets/CodeBlock.lua`, `Widgets/NotificationBanner.lua`, `Widgets/AutoHideContainer.lua`, and `Widgets/FloatingToolbar.lua`
- the host files were normalized back to Ellesmere-style `LibStub("MedaUI-2.0")` access, with LuaLS support handled through casts and `.luals-meta` contracts instead of runtime `assert(...)`
- a broader widget cleanup pass normalized Ellesmere-style constructors and removed shadowing/dead-local noise in `Widgets/Button.lua`, `Widgets/Checkbox.lua`, `Widgets/ColorPicker.lua`, `Widgets/DataTable.lua`, `Widgets/EditBox.lua`, `Widgets/SearchBox.lua`, `Widgets/Badge.lua`, `Widgets/ExpandToggle.lua`, `Widgets/HUDTextButton.lua`, `Widgets/IconButton.lua`, `Widgets/InlineRadioGroup.lua`, `Widgets/Radio.lua`, `Widgets/TabBar.lua`, `Widgets/Toggle.lua`, `Widgets/ContentFrame.lua`, `Widgets/Label.lua`, `Widgets/MinimapButton.lua`, and `Widgets/SectionHeader.lua`
- `.luals-meta/medaui-widgets.lua` now models those widget families directly so LuaLS can see stable frame fields and factory returns instead of treating them as dynamic field injection
- targeted `luacheck` is clean for every file touched in that widget tranche plus `.luals-meta/medaui-widgets.lua`
- full-repo `luacheck` is now down to 154 warnings, and the remaining warnings are concentrated in broader composite widgets such as `Widgets/Effects.lua`, `Widgets/ContextMenu.lua`, `Widgets/ImportExportDialog.lua`, `Widgets/HUDSection.lua`, `Widgets/TextViewer.lua`, `Widgets/Slider.lua`, and `Widgets/CollapsibleSectionHeader.lua`
- full-workspace LuaLS is now down to 1678 diagnostics; the current top buckets are `inject-field` (789), `undefined-field` (600), and `need-check-nil` (233)
- the current heaviest LuaLS files are `Widgets/StatusRow.lua`, `Widgets/HUDRow.lua`, `Widgets/CodeBlock.lua`, `Widgets/Panel.lua`, `Widgets/ScrollList.lua`, `Widgets/NotificationBanner.lua`, `Widgets/AutoHideContainer.lua`, `Widgets/ColorPicker.lua`, `Widgets/FloatingToolbar.lua`, and `Widgets/TextViewer.lua`
- the remaining composite-widget cleanup pass normalized constructor/style usage in `Widgets/Effects.lua`, `Widgets/ContextMenu.lua`, `Widgets/ImportExportDialog.lua`, `Widgets/HUDSection.lua`, `Widgets/TextViewer.lua`, `Widgets/Slider.lua`, `Widgets/CollapsibleSectionHeader.lua`, `Widgets/EventTimeline.lua`, `Widgets/HUDGroup.lua`, `Widgets/HUDTextBlock.lua`, `Widgets/NodeConnector.lua`, `Widgets/ThemeSelector.lua`, `Widgets/OverlayContainer.lua`, `Widgets/ResizeGrip.lua`, `Widgets/SchemaForm.lua`, `Widgets/TreeView.lua`, and `Widgets/TwoColumnLayout.lua`
- full-repo `luacheck` is now clean at `0 warnings / 0 errors`
- full-workspace LuaLS is now down to `1638` diagnostics; the current top buckets are `inject-field` (812), `undefined-field` (620), and `need-check-nil` (150)
- the current heaviest LuaLS files are `Widgets/StatusRow.lua`, `Widgets/HUDRow.lua`, `Widgets/CodeBlock.lua`, `Widgets/Panel.lua`, `Widgets/ScrollList.lua`, `Widgets/NotificationBanner.lua`, `Widgets/AutoHideContainer.lua`, `Widgets/CollapsibleSectionHeader.lua`, `Widgets/ColorPicker.lua`, `Widgets/FloatingToolbar.lua`, `Widgets/DataTable.lua`, and `Widgets/EditBox.lua`
- at this point the remaining validation debt is overwhelmingly LuaLS modeling debt, not lint hygiene debt; the next productive seam is expanding `.luals-meta/medaui-widgets.lua` for the higher-complexity widget classes and reducing dynamic field injection in those modules
