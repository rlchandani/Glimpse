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
- **AI date search** — press ⌘G and type "next Friday" or "Christmas" (macOS 26+, on-device)
- **Today's events** — EventKit integration shows calendar events in the popover
- **Global hotkey** — configurable shortcut (default ⌘⇧C) to toggle the calendar from anywhere
- **Customizable menu bar** — toggle icon, day, month, date, year with live preview
- **Workday highlighting** — configure which days are workdays
- **Pin window** — keep the calendar visible while working
- **Shortcuts.app** — "Show Glimpse Calendar" available via Siri and Shortcuts
- **Launch at login** — via macOS SMAppService

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
- macOS 26.0 (Tahoe) for AI date search
- Xcode 16+
- Swift 6.0

## Build

```bash
xcodebuild -project Glimpse.xcodeproj -scheme Glimpse -configuration Release -skipMacroValidation build
```

> **Note:** `-skipMacroValidation` is required for TCA macro plugins. When building in Xcode GUI for the first time, click "Trust & Enable" when prompted for macro plugins.

The built app is at:
```
~/Library/Developer/Xcode/DerivedData/Glimpse-*/Build/Products/Release/Glimpse.app
```

## Test

```bash
# App tests (18 tests)
xcodebuild -project Glimpse.xcodeproj -scheme Glimpse -skipMacroValidation test

# GlimpseCore tests (29 TCA TestStore tests)
cd GlimpseCore && swift test
```

47 tests total. All use Swift Testing (`@Test`, `#expect`) — no XCTest.

## Project Structure

```
Glimpse/                             # App target
├── GlimpseApp.swift                 # @main entry, AppDelegate
├── CalendarPanel.swift              # NSPanel (non-activating, pin, text input)
├── CalendarStatusItem.swift         # NSStatusItem, positioning, midnight refresh
├── StatusItemView.swift             # Bordered menu bar view (icon | text)
├── CalendarPopoverView.swift        # SwiftUI calendar, date selection, AI field
├── PreferencesView.swift            # Preferences with key recorder
├── MonthBorderShape.swift           # Contoured month border (SwiftUI Shape)
├── DateIconRenderer.swift           # Date number + red accent menu bar icon
├── GlobalHotkey.swift               # Carbon EventHotKey, configurable combo
├── AppIntents.swift                 # Shortcuts.app integration
├── AIDateHelper.swift               # FoundationModels date parsing (macOS 26+)
├── AppDesign.swift                  # Design tokens
├── AppLogger.swift                  # os.Logger categories
├── PrivacyInfo.xcprivacy            # Privacy manifest
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
│                                    # MenuBarDisplayOptions
└── Tests/GlimpseCoreTests/          # 29 TCA TestStore tests

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

| Permission | Why |
|---|---|
| **Calendar** | Show today's events (EventKit) |

The app requests calendar access when you click "Show today's events" in the popover. No other permissions are required.

## License

MIT

## Author

[Rohit Chandani](https://rlchandani.dev/)
