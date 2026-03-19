# Glimpse

A lightweight macOS menu bar calendar app. Click the date icon to see the current month at a glance.

## Features

- **Menu bar date display** — shows today's date as a small calendar icon with optional day, month, date, and year text
- **Monthly calendar popover** — click to see a full month view with navigation
- **Contoured month border** — visual outline wraps only the current month's days
- **Week numbers** — ISO week numbers displayed alongside the calendar grid
- **Workday highlighting** — subtle column tinting for configured workdays
- **Weekend labels** — Saturday and Sunday headers highlighted
- **Keyboard navigation** — left/right arrows for months, Enter for today, Escape to close
- **Scroll wheel navigation** — scroll to change months with dampened sensitivity
- **Pin window** — keep the calendar visible while working
- **Multi-screen support** — repositions to the correct screen via status item click
- **Customizable menu bar** — toggle icon, day of week, month, date, and year independently with a live preview
- **Configurable start of week** — Sunday, Monday, or any day
- **Launch at login** — via macOS SMAppService

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later

## Build

```bash
xcodebuild -project Glimpse.xcodeproj -scheme Glimpse -configuration Release build
```

## Test

```bash
xcodebuild -project Glimpse.xcodeproj -scheme Glimpse test
```

35 unit tests covering calendar math, preferences logic, border shape computation, and icon rendering.

## Project Structure

```
Glimpse/
├── GlimpseApp.swift             # App entry point, AppDelegate
├── CalendarPanel.swift          # Custom NSPanel with pin support
├── CalendarStatusItem.swift     # NSStatusItem management, positioning
├── StatusItemView.swift         # Bordered menu bar view (icon + text)
├── CalendarPopoverView.swift    # SwiftUI calendar with month grid
├── CalendarGridHelper.swift     # Pure calendar math (testable)
├── CalendarPreferences.swift    # @Observable preferences, UserDefaults
├── PreferencesView.swift        # SwiftUI preferences panel
├── DateIconRenderer.swift       # Renders date number as menu bar icon
├── Info.plist                   # LSUIElement (menu bar only)
└── Assets.xcassets/
GlimpseTests/
├── CalendarPreferencesTests.swift
├── CalendarGridHelperTests.swift
├── MonthBorderShapeTests.swift
└── DateIconRendererTests.swift
```

## Preferences

Access preferences via the gear icon in the calendar footer:

- **Menu bar display** — toggle icon, day of week, month, date, year
- **Week starts on** — pick any day of the week
- **Workdays** — select which days are workdays (highlighted in the grid)
- **Launch at login** — auto-start on macOS login

## License

MIT
