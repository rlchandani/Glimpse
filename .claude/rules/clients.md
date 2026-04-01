---
paths:
  - "GlimpseCore/Sources/GlimpseCore/Dependencies/**/*.swift"
---

# Dependency Client Rules

- Clients use `@DependencyClient` macro with `Sendable` conformance
- Client struct has closure properties with sensible defaults
- Register via `DependencyKey` with `liveValue` (static computed property)
- Access in features via `@Dependency(\.clientName)`
- `testValue` provided by `@DependencyClient` macro automatically
- UserDefaults access: `nonisolated(unsafe) let defaults` with safety comment
- Error handling: log errors via AppLogger, don't silently swallow with `try?`
- New preferences fields need: client load/save closures, UserDefaults key, model property
