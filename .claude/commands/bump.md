Bump the app version. Argument: `$ARGUMENTS` (e.g., "1.3.0" or "patch"/"minor"/"major").

Steps:

1. Determine the new version:
   - If a semver string is given (e.g., "1.3.0"), use it directly
   - If "patch", "minor", or "major" is given, read the current version from `project.pbxproj` and increment accordingly
   - If no argument given, increment the minor version (e.g., 1.2.0 → 1.3.0)

2. Read the current build number from `Glimpse.xcodeproj/project.pbxproj` (`CURRENT_PROJECT_VERSION`) and increment it by 1.

3. Update ALL 3 locations (missing any will break the release):
   - `Glimpse.xcodeproj/project.pbxproj` → `MARKETING_VERSION` (4 occurrences: Debug/Release × App/Tests)
   - `Glimpse.xcodeproj/project.pbxproj` → `CURRENT_PROJECT_VERSION` (4 occurrences)
   - `README.md` → version badge `[![Version](https://img.shields.io/badge/version-X.Y.Z-green)]`

4. After updating, verify consistency by grepping all locations and printing a summary table:
   ```
   VERSION BUMP: X.Y.Z (build NN)
   ✅ project.pbxproj MARKETING_VERSION (4 occurrences)
   ✅ project.pbxproj CURRENT_PROJECT_VERSION (4 occurrences)
   ✅ README.md badge
   ```

5. Do NOT commit — just make the edits and report. The user will commit when ready.

Important:
- Build number MUST always increment (Sparkle uses it for update ordering)
- MARKETING_VERSION and CURRENT_PROJECT_VERSION each appear 4 times in project.pbxproj — update ALL of them
