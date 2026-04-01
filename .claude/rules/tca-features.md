---
paths:
  - "GlimpseCore/Sources/GlimpseCore/Features/**/*.swift"
---

# TCA Feature Rules

- Every feature uses `@Reducer` macro with `@ObservableState` struct for State
- Use `@Dependency` for all client access — never instantiate clients directly
- Long-running effects must use `CancelID` enum and `.cancellable(id:)`
- Capture specific values before `.run` closures, never `[state]`
- Side effects belong in `.run` blocks, never in the reducer's synchronous path
- Child features are composed via `Scope(state:action:)`
- Actions that only set state return `.none`
- Use delegate actions (`.delegate(.preferencesChanged)`) for cross-feature communication
- `@Dependency(\.date)` instead of `Date()` for deterministic testing
- Avoid `Result<Void, Error>` in TCA actions — causes Swift compiler crashes. Use separate success/failure actions.
