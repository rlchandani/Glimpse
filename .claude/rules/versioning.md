---
paths:
  - "Glimpse.xcodeproj/project.pbxproj"
  - "README.md"
---

# Version Consistency Rules

The app version must be synchronized across 3 locations. Missing any one will
cause release failures or users not receiving updates.

## Locations

1. `Glimpse.xcodeproj/project.pbxproj` → `MARKETING_VERSION` (4 occurrences)
2. `Glimpse.xcodeproj/project.pbxproj` → `CURRENT_PROJECT_VERSION` (4 occurrences)
3. `README.md` → version badge

## Rules

- When changing version in ANY of these files, update ALL of them
- Build number (`CURRENT_PROJECT_VERSION`) MUST increment on every release —
  Sparkle uses it to determine update ordering
- MARKETING_VERSION and CURRENT_PROJECT_VERSION each appear exactly 4 times in
  project.pbxproj (Debug/Release × App/Tests) — update all 4
- After editing, verify with: `grep MARKETING_VERSION Glimpse.xcodeproj/project.pbxproj | grep -c "X.Y.Z"` (expect 4)
- Use `/bump` command to automate this process
