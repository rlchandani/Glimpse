# Gotchas & Hard-Won Debugging Insights

## NSPanel Behavior

- **onAppear doesn't fire on panel reshow**: NSPanel reused via orderOut/orderFront
  doesn't trigger SwiftUI onAppear. Use `CalendarPanel.collapsePreferencesIfNeeded()`
  called from CalendarStatusItem.showPanel() instead.

- **TextField in non-activating panel**: `.nonactivatingPanel` prevents keyboard focus.
  Must call `NSApp.activate(ignoringOtherApps: true)` via `panel.activateForTextInput()`.
  Restore previous app on deactivate.

- **Key monitor intercepts Enter**: `NSEvent.addLocalMonitorForEvents` intercepts
  keyCode 36 before SwiftUI `onSubmit`. Handle Enter explicitly in the monitor when
  AI field is active.

## Build & Project

- **Sparkle Team ID mismatch**: Pre-built Sparkle.framework has a different Team ID.
  Local builds need `codesign --force --sign -` on embedded frameworks. CI uses
  `xcodebuild -exportArchive`.

- **pbxproj UUID collisions**: `AA00000000000000000020` is used by Frameworks build
  phase. Use `DD`-prefixed UUIDs for new app files.

- **`-skipMacroValidation` required**: TCA macros need this flag for both build and test.

- **`#if canImport(FoundationModels)`**: Required for CI (macOS < 26). The
  `@available(macOS 26, *)` guard alone isn't enough — the import itself fails.

## TCA / SwiftUI

- **Capturing state in .run closures**: Always capture specific values before the
  `.run` block, never capture `[state]`.

- **Result<Void, Error> in TCA actions**: Causes Swift compiler crashes. Use separate
  success/failure actions.

- **onChange on TCA @ObservableState bindings**: Does NOT reliably fire. Use custom
  Bindings that post NotificationCenter notifications instead.

- **`@Dependency(\.date)` not `Date()`**: Direct Date() in reducers breaks purity
  and test determinism.

## Date Handling

- **ISO 8601 timezone**: `ISO8601DateFormatter` defaults to UTC → off-by-one dates.
  Use `DateFormatter` with `TimeZone.current`.

- **DateFormatter must be static**: Never create in loops or computed properties.

## Menu Bar

- **StatusItemView rendering**: Use `draw(_ dirtyRect:)` for reliable rendering,
  not CALayer sublayers (layer? may be nil during setupViews).

- **Menu bar refresh**: NotificationCenter `.menuBarDisplayDidChange` is the reliable
  path. Direct onChange or AppDelegate access don't work consistently.
