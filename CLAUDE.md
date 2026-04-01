# Glimpse — Dev Notes for Agents

## Code Review Requirements

Before any commit, run `/review` to apply the full pre-production checklist from `.claude/rules/pre-production-review.md`. All rule files in `.claude/rules/` must be checked.

## Project Overview

Glimpse is a macOS menu bar calendar app built with TCA and Swift 6. Click the date in the menu bar to see the current month at a glance, with AI-powered date navigation, EventKit events, and configurable display options.

## Build & Development Commands

```bash
# Build (requires -skipMacroValidation for TCA macros)
xcodebuild -project Glimpse.xcodeproj -scheme Glimpse -configuration Release -skipMacroValidation build

# App tests (18 tests, 3 suites)
xcodebuild -project Glimpse.xcodeproj -scheme Glimpse -skipMacroValidation test

# GlimpseCore tests (32 TCA TestStore tests, 3 suites)
cd GlimpseCore && swift test

# Local run (re-sign Sparkle for ad-hoc)
find Glimpse.app/Contents/Frameworks -name "*.framework" -exec codesign --force --sign - --timestamp {} \;
codesign --force --sign - --timestamp --deep Glimpse.app
open Glimpse.app
```

## Architecture

**TCA** (The Composable Architecture) for all state management. Swift 6, `SWIFT_STRICT_CONCURRENCY = complete`.

### App Target (Glimpse/)
| File | Purpose |
|---|---|
| `GlimpseApp.swift` | @main entry, AppDelegate |
| `CalendarPanel.swift` | NSPanel (non-activating, pin support, text input, preferences collapse) |
| `CalendarStatusItem.swift` | NSStatusItem, panel positioning, midnight refresh, NotificationCenter observer |
| `StatusItemView.swift` | Menu bar rendering — bordered/filled, icon + text, `draw(_ dirtyRect:)` |
| `StatusItemPreview.swift` | NSViewRepresentable wrapping StatusItemView for SwiftUI preferences preview |
| `CalendarPopoverView.swift` | Main calendar UI, date selection, AI field, events, footer with quit confirm |
| `PreferencesView.swift` | Grouped cards layout (Display, Calendar, Features) |
| `MonthBorderShape.swift` | Contoured month border (SwiftUI Shape) |
| `DateIconRenderer.swift` | Date number + red accent menu bar icon, configurable text color |
| `GlobalHotkey.swift` | Carbon EventHotKey, configurable combo with persistence |
| `AIDateHelper.swift` | Routes between proxy API and FoundationModels |
| `ProxyProvider.swift` | Auris proxy REST API integration |
| `ProxyConfig.swift` | XOR-obfuscated app secret, device ID, auth headers |
| `SparkleUpdater.swift` | Inline update UI with SPUUserDriver (all status states) |
| `AboutWindow.swift` | Floating window with version, updates, diagnostics, links |
| `AppDesign.swift` | Design tokens (spacing, colors, corner radius, animation) |
| `AppLogger.swift` | os.Logger categories |

### Core Package (GlimpseCore/)
| Directory | Contents |
|---|---|
| `Features/` | CalendarFeature, PreferencesFeature, MenuBarFeature |
| `Dependencies/` | PreferencesClient, CalendarClient, EventKitClient, LaunchAtLoginClient |
| `Models/` | CalendarDay, CalendarEvent, GridInfo, MenuBarDisplayOptions, AIProvider |

## Important Implementation Details

### 1. NSPanel + TextField
`.nonactivatingPanel` prevents SwiftUI TextField from working. Must call `NSApp.activate(ignoringOtherApps: true)` via `panel.activateForTextInput()`. Previous app stored and restored on deactivate.

### 2. Preferences Collapse on Reopen
`onAppear` does NOT fire when NSPanel is reused via orderOut/orderFront. `CalendarPanel` stores a reference to the TCA store and `collapsePreferencesIfNeeded()` is called from `CalendarStatusItem.showPanel()`.

### 3. Menu Bar Refresh
`onChange` on TCA `@ObservableState` bindings does NOT reliably fire. PreferencesView uses custom `Binding`s that post `NotificationCenter.menuBarDisplayDidChange`. CalendarStatusItem observes this and calls `updateMenuBarDisplay()`.

### 4. Filled Background Mode
`StatusItemView.draw(_ dirtyRect:)` renders either bordered (stroke only) or filled (solid light gray + dark text). `DateIconRenderer.render(textColor:)` accepts color param for icon text. `StatusItemPreview` (NSViewRepresentable) ensures the preferences preview uses the identical rendering path.

### 5. Key Monitor Eats Enter
`NSEvent.addLocalMonitorForEvents` intercepts keyCode 36 before SwiftUI `onSubmit`. Handle Enter explicitly in the monitor when AI field is active.

### 6. AI Proxy
Uses shared Auris proxy at `proxy.auris.workers.dev/refine`. App secret is XOR-obfuscated in `ProxyConfig`. Device ID for rate limiting. No API keys needed.

## Storage

| What | Where | Format |
|---|---|---|
| Display options | UserDefaults | Bool per key (showIcon, showDayOfWeek, etc.) |
| Workdays | UserDefaults | `[Int]` array |
| Start of weekday | UserDefaults | `Int` |
| AI settings | UserDefaults | Bool (showAISearch), String (aiProvider) |
| Hotkey combo | UserDefaults | UInt32 (keyCode, modifiers) |
| Launch at login | SMAppService | System managed |

## Release Infrastructure

- **Sparkle 2.x** for auto-updates with EdDSA signing
- **InlineUpdateDriver** (custom SPUUserDriver) for in-app update status
- **GitHub Actions** (`release.yml`) builds on push to main when version changes
- **DMG** created via xcodebuild archive + export

## Secrets (GitHub)

| Secret | Purpose |
|---|---|
| `MACOS_CERTIFICATE` | Base64 Developer ID .p12 |
| `MACOS_CERTIFICATE_PWD` | .p12 password |
| `SPARKLE_PRIVATE_KEY` | EdDSA key for Sparkle signing |
| `DEVELOPMENT_TEAM` | Apple Team ID (5D7M37QQLU) |

## Testing Rules

- All tests use Swift Testing (`@Test`, `#expect`) — no XCTest
- TCA tests use `TestStore` with explicit `withDependencies`
- Provide `$0.date = .constant(...)` for any reducer using `@Dependency(\.date)`
- Provide `$0.eventKitClient.authorizationStatus = { .notDetermined }` for CalendarFeature tests
- Avoid `Result<Void, Error>` in TCA actions — causes Swift compiler crashes

## Git Commit Guidelines

- Conventional commits: `feat:`, `fix:`, `refactor:`, `test:`, `chore:`
- No AI/Claude attribution in commits or code
- No `Co-Authored-By` lines

## File Counts

- App source files: ~17
- GlimpseCore source files: ~12
- Test files: 6
- Total tests: 50
