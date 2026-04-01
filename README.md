# Glimpse

[![Release](https://github.com/rlchandani/Glimpse/actions/workflows/release.yml/badge.svg)](https://github.com/rlchandani/Glimpse/actions/workflows/release.yml)
[![Download](https://img.shields.io/github/v/release/rlchandani/Glimpse?label=Download&sort=semver)](https://github.com/rlchandani/Glimpse/releases/latest)
[![License](https://img.shields.io/github/license/rlchandani/Glimpse)](https://github.com/rlchandani/Glimpse/blob/main/LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue)]()
[![Swift](https://img.shields.io/badge/Swift-6.0-orange)]()

A lightweight macOS menu bar calendar app. Click the date icon to see the current month at a glance.

## Features

- **Menu bar popover** with month grid, week numbers, and contoured month border
- **Date selection** — click any day to see full date info and week number
- **AI date search** — press ⌘G and type "next Friday" or "Christmas"
- **Today's events** — EventKit integration shows calendar events in the popover
- **Global hotkey** — configurable shortcut (default ⌘⇧C) to toggle from anywhere
- **Customizable menu bar** — toggle icon, day, month, date, year with live preview
- **Filled background mode** — solid pill style for the menu bar item
- **Workday highlighting** — configure which days are workdays
- **Pin window** — keep the calendar visible while working
- **Grouped preferences** — Display, Calendar, Features cards with branded divider
- **Auto-updates** — Sparkle with inline status in About window
- **Shortcuts.app** — "Show Glimpse Calendar" available via Siri and Shortcuts
- **Launch at login** — via macOS SMAppService

## Setup

1. Download the latest release from [GitHub Releases](https://github.com/rlchandani/Glimpse/releases/latest)
2. Move `Glimpse.app` to `/Applications`
3. Launch — the date icon appears in the menu bar
4. Click it to see the calendar, click the gear icon for preferences

## Architecture

Built with [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) (TCA) and Swift 6 strict concurrency.

- `CalendarFeature` → month navigation, date selection, events, AI
- `PreferencesFeature` → all preference state with delegate actions
- `MenuBarFeature` → display options, date string formatting
- `@Dependency` clients: `PreferencesClient`, `CalendarClient`, `EventKitClient`, `LaunchAtLoginClient`
- `@Dependency(\.date)` for deterministic reducer testing
- `AppDesign` tokens for spacing, corner radius, colors, animation
- `os.Logger` via `AppLogger` for diagnostics

## Requirements

- macOS 14.0 (Sonoma) or later
- macOS 26.0 (Tahoe) for on-device AI date search
- Xcode 16+
- Swift 6.0

## Development

### Building

```bash
# Command line
xcodebuild -project Glimpse.xcodeproj -scheme Glimpse -configuration Release -skipMacroValidation build

# Xcode GUI
# Open Glimpse.xcodeproj → Trust & Enable macro plugins when prompted → Build
```

> `-skipMacroValidation` is required for TCA macro plugins.

The built app is at:
```
~/Library/Developer/Xcode/DerivedData/Glimpse-*/Build/Products/Release/Glimpse.app
```

### Testing

```bash
# App tests (18 tests)
xcodebuild -project Glimpse.xcodeproj -scheme Glimpse -skipMacroValidation test

# GlimpseCore tests (30 TCA TestStore tests)
cd GlimpseCore && swift test
```

48 tests total. All use Swift Testing (`@Test`, `#expect`) — no XCTest.

### Code Signing (Local)

Ad-hoc signing for local development (Sparkle framework needs re-signing):

```bash
find Glimpse.app/Contents/Frameworks -name "*.framework" -exec codesign --force --sign - --timestamp {} \;
codesign --force --sign - --timestamp --deep Glimpse.app
open Glimpse.app
```

## Project Structure

```
Glimpse/                             # App target
├── GlimpseApp.swift                 # @main entry, AppDelegate
├── CalendarPanel.swift              # NSPanel (non-activating, pin, text input)
├── CalendarStatusItem.swift         # NSStatusItem, positioning, midnight refresh
├── StatusItemView.swift             # Menu bar rendering (bordered/filled)
├── StatusItemPreview.swift          # NSViewRepresentable for preferences preview
├── CalendarPopoverView.swift        # SwiftUI calendar, date selection, AI field
├── PreferencesView.swift            # Grouped cards preferences (Display/Calendar/Features)
├── MonthBorderShape.swift           # Contoured month border (SwiftUI Shape)
├── DateIconRenderer.swift           # Date number + red accent menu bar icon
├── GlobalHotkey.swift               # Carbon EventHotKey, configurable combo
├── AppIntents.swift                 # Shortcuts.app integration
├── AIDateHelper.swift               # AI date parsing (proxy + FoundationModels)
├── ProxyProvider.swift              # Auris proxy API integration
├── ProxyConfig.swift                # XOR-obfuscated auth
├── SparkleUpdater.swift             # Inline update UI with SPUUserDriver
├── AboutWindow.swift                # Version, updates, diagnostics
├── AppDesign.swift                  # Design tokens
├── AppLogger.swift                  # os.Logger categories
├── PrivacyInfo.xcprivacy
├── Info.plist
├── Glimpse.entitlements
└── Assets.xcassets/

GlimpseCore/                         # Local Swift Package (business logic)
├── Sources/GlimpseCore/
│   ├── Dependencies/                # PreferencesClient, CalendarClient,
│   │                                # EventKitClient, LaunchAtLoginClient
│   ├── Features/                    # CalendarFeature, PreferencesFeature,
│   │                                # MenuBarFeature
│   └── Models/                      # CalendarDay, CalendarEvent, GridInfo,
│                                    # MenuBarDisplayOptions, AIProvider
└── Tests/GlimpseCoreTests/          # 30 TCA TestStore tests

GlimpseTests/                        # 18 app-level tests
```

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| ⌘⇧C (configurable) | Toggle calendar from anywhere |
| ← → | Previous / next month |
| ↑ ↓ | Previous / next year |
| Enter | Go to today |
| Escape | Close preferences or calendar |
| ⌘G | AI date search |

## Permissions

| Permission | Why | When Requested |
|---|---|---|
| **Calendar** | Show today's events (EventKit) | Click "Show today's events" |

No other permissions required. The app runs as a menu bar accessory (no dock icon).

## Releasing

### GitHub Actions (Automated)

Push to `main` with a version bump triggers the release workflow:
1. Checks version against latest git tag
2. Runs all tests
3. Archives and exports with Developer ID signing
4. Creates GitHub Release with ZIP

### Required Secrets

| Secret | Purpose |
|---|---|
| `MACOS_CERTIFICATE` | Base64 Developer ID .p12 |
| `MACOS_CERTIFICATE_PWD` | .p12 password |
| `SPARKLE_PRIVATE_KEY` | EdDSA key for Sparkle signing |
| `DEVELOPMENT_TEAM` | Apple Team ID |

## License

MIT

## Author

[Rohit Chandani](https://rlchandani.dev/)
