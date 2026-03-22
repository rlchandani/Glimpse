# Glimpse

A lightweight macOS menu bar calendar app. Click the date icon to see the current month at a glance.

## Features

### Calendar
- **Monthly calendar popover** — click the menu bar icon to see a full month view
- **Contoured month border** — visual outline wraps only the current month's days
- **Week numbers** — ISO week numbers displayed alongside the calendar grid
- **Weekend labels** — Saturday and Sunday headers highlighted
- **Workday highlighting** — subtle column tinting for configured workdays
- **Date selection** — click any day to select it; shows full date info and week number below the grid
- **Outer border** — rounded border wrapping the entire grid including headers and week numbers

### Navigation
- **Month navigation** — left/right arrow keys or header chevrons
- **Year navigation** — up/down arrow keys
- **Today button** — center dot in header (active when navigated away)
- **Scroll wheel** — scroll to change months with dampened sensitivity
- **AI date search** — press ⌘G or click "Go to date..." to type natural language queries like "next Friday", "Christmas", or "Jan 2028" (macOS 26+, powered by on-device Foundation Models)

### Menu Bar
- **Customizable display** — toggle icon, day of week, month, date, and year independently
- **Live preview** — see how your menu bar will look as you toggle options
- **Bordered status item** — pill-shaped border with separator between icon and text
- **Date icon** — shows today's date number with a red accent underline

### System Integration
- **Global keyboard shortcut** — configurable hotkey (default ⌘⇧C) to toggle the calendar from anywhere
- **Click-to-record** — click the shortcut badge in preferences to set a new key combo
- **EventKit** — shows today's calendar events in the popover (requires calendar access)
- **AppIntents / Shortcuts** — "Show Glimpse Calendar" available in Shortcuts.app and Siri
- **Launch at login** — via macOS SMAppService
- **Pin window** — keep the calendar visible while working in other apps
- **Multi-screen** — repositions to the correct screen when clicking the status item
- **Quit** — power icon in the footer

### Preferences
Access via the gear icon in the calendar footer:
- Menu bar display toggles (icon, day, month, date, year)
- Week starts on (any day)
- Workday selection (click day letters to toggle)
- Global shortcut (enable/disable, click to record new combo)
- Launch at login

## Architecture

Built with [The Composable Architecture (TCA)](https://github.com/pointfreeco/swift-composable-architecture).

| Layer | Technology |
|---|---|
| State management | TCA reducers (`CalendarFeature`, `PreferencesFeature`, `MenuBarFeature`) |
| Dependencies | `@Dependency` clients (`PreferencesClient`, `CalendarClient`, `EventKitClient`, `LaunchAtLoginClient`) |
| UI | SwiftUI views driven by `StoreOf<Feature>` |
| Window management | AppKit `NSPanel` (non-activating, floating) |
| Menu bar | AppKit `NSStatusItem` with custom `StatusItemView` |
| AI | Apple FoundationModels (`LanguageModelSession`, macOS 26+) |
| Concurrency | Swift 6, `SWIFT_STRICT_CONCURRENCY = complete` |
| Design | `AppDesign` tokens for spacing, corner radius, colors, animation |
| Logging | `os.Logger` via `AppLogger` |

## Requirements

- macOS 14.0 (Sonoma) or later
- macOS 26.0 (Tahoe) for AI date search
- Xcode 16.0 or later

## Build

```bash
xcodebuild -project Glimpse.xcodeproj -scheme Glimpse -configuration Release -skipMacroValidation build
```

## Test

```bash
# App tests
xcodebuild -project Glimpse.xcodeproj -scheme Glimpse -skipMacroValidation test

# GlimpseCore tests
cd GlimpseCore && swift test
```

40 tests total (18 app + 22 TCA reducer tests), all using Swift Testing framework.

## Project Structure

```
Glimpse/                             # App target
├── GlimpseApp.swift                 # @main entry point, AppDelegate
├── CalendarPanel.swift              # NSPanel with pin, text input activation
├── CalendarStatusItem.swift         # NSStatusItem, panel positioning, midnight refresh
├── StatusItemView.swift             # Bordered menu bar view (icon | text)
├── CalendarPopoverView.swift        # SwiftUI calendar, date selection, AI field
├── PreferencesView.swift            # Preferences panel with key recorder
├── DateIconRenderer.swift           # Renders date number as menu bar icon
├── GlobalHotkey.swift               # Carbon EventHotKey with configurable combo
├── AppIntents.swift                 # Shortcuts.app integration
├── AIDateHelper.swift               # FoundationModels natural language date parsing
├── AppDesign.swift                  # Design tokens (spacing, radius, colors)
├── AppLogger.swift                  # os.Logger categories
├── Info.plist
├── Glimpse.entitlements
└── Assets.xcassets/

GlimpseCore/                         # Local Swift Package (business logic)
├── Sources/GlimpseCore/
│   ├── Dependencies/
│   │   ├── PreferencesClient.swift  # UserDefaults wrapper
│   │   ├── CalendarClient.swift     # Calendar math, date formatting
│   │   ├── EventKitClient.swift     # EKEventStore wrapper
│   │   └── LaunchAtLoginClient.swift # SMAppService wrapper
│   ├── Features/
│   │   ├── CalendarFeature.swift    # Month nav, pin, date selection, events, AI
│   │   ├── PreferencesFeature.swift # All preference state + delegate actions
│   │   └── MenuBarFeature.swift     # Display options, date string
│   └── Models/
│       ├── CalendarDay.swift
│       ├── CalendarEvent.swift
│       ├── GridInfo.swift
│       └── MenuBarDisplayOptions.swift
└── Tests/GlimpseCoreTests/
    ├── CalendarFeatureTests.swift    # 9 TCA TestStore tests
    ├── PreferencesFeatureTests.swift # 10 TCA TestStore tests
    └── MenuBarFeatureTests.swift    # 3 TCA TestStore tests

GlimpseTests/                        # App-level tests
├── AppDesignTests.swift             # 10 design token tests
├── DateIconRendererTests.swift      # 1 icon rendering test
└── MonthBorderShapeTests.swift      # 7 border shape tests
```

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| ⌘⇧C (configurable) | Toggle calendar from anywhere |
| ← → | Previous / next month |
| ↑ ↓ | Previous / next year |
| Enter | Go to today (when not on current month) |
| Escape | Close preferences, or close calendar |
| ⌘G | Activate AI date search |

## License

MIT
