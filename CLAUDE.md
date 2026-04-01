# Glimpse — Dev Notes for Agents

## Project Overview

Glimpse is a macOS menu bar calendar app built with TCA and Swift 6. It shows the current month at a glance with AI-powered date navigation.

## Build & Test Commands

```bash
# Build (requires -skipMacroValidation for TCA macros)
xcodebuild -project Glimpse.xcodeproj -scheme Glimpse -configuration Release -skipMacroValidation build

# App tests (18 tests)
xcodebuild -project Glimpse.xcodeproj -scheme Glimpse -skipMacroValidation test

# GlimpseCore tests (33 TCA TestStore tests)
cd GlimpseCore && swift test

# Local run (re-sign Sparkle for ad-hoc)
find Glimpse.app/Contents/Frameworks -name "*.framework" -exec codesign --force --sign - --timestamp {} \;
codesign --force --sign - --timestamp --deep Glimpse.app
open Glimpse.app
```

## Architecture

**TCA** (The Composable Architecture) for all state management. Swift 6, `SWIFT_STRICT_CONCURRENCY = complete`.

### App Target (Glimpse/)
- `GlimpseApp.swift` — @main entry, AppDelegate
- `CalendarPanel.swift` — NSPanel (non-activating, pin support, text input activation)
- `CalendarStatusItem.swift` — NSStatusItem, panel positioning, midnight refresh
- `CalendarPopoverView.swift` — Main calendar UI, date selection, AI field, events
- `PreferencesView.swift` — All preferences with key recorder, Groq key, diagnostics
- `GlobalHotkey.swift` — Carbon EventHotKey, configurable combo
- `AIDateHelper.swift` — Routes between Groq API and FoundationModels
- `GroqProvider.swift` — Groq REST API integration
- `SparkleUpdater.swift` — Inline update UI with SPUUserDriver

### Core Package (GlimpseCore/)
- `Features/` — CalendarFeature, PreferencesFeature, MenuBarFeature
- `Dependencies/` — PreferencesClient, CalendarClient, EventKitClient, LaunchAtLoginClient, KeychainClient
- `Models/` — CalendarDay, CalendarEvent, GridInfo, MenuBarDisplayOptions, AIProvider

## Key Gotchas

1. **NSPanel + TextField**: `.nonactivatingPanel` prevents SwiftUI TextField from working. Must call `NSApp.activate(ignoringOtherApps: true)` via `panel.activateForTextInput()`. Restore previous app on deactivate.

2. **Key monitor eats Enter**: `NSEvent.addLocalMonitorForEvents` intercepts keyCode 36 before SwiftUI `onSubmit`. Handle Enter explicitly in the monitor when AI field is active.

3. **Sparkle Team ID mismatch**: Pre-built Sparkle.framework has a different Team ID. Local builds need `codesign --force --sign -` on embedded frameworks. CI uses `xcodebuild -exportArchive`.

4. **`#if canImport(FoundationModels)`**: Required for CI (macOS < 26). The `@available(macOS 26, *)` guard alone isn't enough — `import FoundationModels` fails at compile time.

5. **`Date()` in TCA reducers**: Use `@Dependency(\.date)` with `date.now`. Direct `Date()` breaks reducer purity and test determinism.

6. **pbxproj UUID collisions**: `AA00000000000000000020` is used by Frameworks build phase. Use `DD`-prefixed UUIDs for new app files.

7. **ISO 8601 timezone**: `ISO8601DateFormatter` defaults to UTC → off-by-one dates. Use `DateFormatter` with `TimeZone.current`.

8. **API keys in Keychain**: Never UserDefaults, never logs. Use KeychainClient with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`.

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
- Avoid `Result<Void, Error>` in TCA actions — causes Swift compiler crashes. Use separate success/failure actions.

## File Counts

- App source files: ~15
- GlimpseCore source files: ~12
- Test files: 6
- Total tests: 51
