Run all tests and validate the build. Report results clearly.

Steps:
1. Run GlimpseCore unit tests (expect 32 tests, 3 suites):
   ```bash
   cd GlimpseCore && swift test
   ```
2. Run app tests (expect 18 tests, 3 suites):
   ```bash
   xcodebuild -project Glimpse.xcodeproj -scheme Glimpse -skipMacroValidation test 2>&1 | tail -30
   ```
3. Build Release:
   ```bash
   xcodebuild -project Glimpse.xcodeproj -scheme Glimpse -configuration Release -skipMacroValidation build 2>&1 | tail -10
   ```
4. Report results:
   ```
   GLIMPSECORE TESTS: X/32 passed (Y failures)
   APP TESTS: X/18 passed (Y failures)
   RELEASE BUILD: ✅ / ❌
   ISSUES:
   - [file:line] description
   ```

If test count drops below expected, flag it — a test may have been accidentally deleted.
