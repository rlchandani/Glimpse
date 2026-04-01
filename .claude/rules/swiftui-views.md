---
paths:
  - "Glimpse/**/*View.swift"
  - "Glimpse/CalendarPopoverView.swift"
---

# SwiftUI View Rules

- Views take `StoreOf<Feature>` via `@Bindable var store`
- Use `store.scope(state:action:)` to pass child stores
- Use `$store.property.sending(\.action)` for bindings to TCA state
- Keep `body` lightweight — move heavy computation to the reducer
- Use `AppDesign` tokens for spacing, colors, corner radius, animation
- All buttons use `.buttonStyle(.plain)` and `.focusable(false)` to prevent focus rings
- Use `.contentShape()` to expand tap targets beyond visible content
- Avoid force unwraps in views — use `guard let` or `if let`
- Log errors in catch blocks — never use empty `catch {}`
- NSViewRepresentable for sharing AppKit views (e.g. StatusItemPreview)
