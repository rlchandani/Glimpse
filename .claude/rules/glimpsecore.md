---
paths:
  - "GlimpseCore/**/*.swift"
---

# GlimpseCore Rules

- GlimpseCore is a Swift Package — no AppKit/SwiftUI imports allowed
- All types must be `Sendable` (strict concurrency)
- Use `AppLogger` for logging, not `print()`
- `@unchecked Sendable` requires a justification comment explaining why it's safe
- `nonisolated(unsafe)` requires a comment explaining the safety invariant
- New MenuBarDisplayOptions fields need: property, init parameter, default value
- New PreferencesFeature actions need: case, reducer handler, delegate if cross-feature
- Codable implementations must handle missing keys gracefully (backward compatibility)
- Tests use Swift Testing framework (`@Test`, `#expect`, `@Suite`)
- TCA tests use `TestStore` with explicit `withDependencies`
