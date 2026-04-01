Run a thorough code review of all uncommitted changes following the pre-production checklist in `.claude/rules/pre-production-review.md` (sections A1-A8).

Steps:
1. Run `git diff HEAD --stat` to identify all changed files
2. Read every changed file thoroughly — do not infer, read the actual code
3. Run all tests (`cd GlimpseCore && swift test` and `xcodebuild -project Glimpse.xcodeproj -scheme Glimpse -skipMacroValidation test`)
4. Apply every section of the review checklist (A1-A8) against the changes
5. Check `.claude/rules/gotchas.md`, `.claude/rules/known-issues.md`, `.claude/rules/clients.md`, `.claude/rules/tca-features.md`, `.claude/rules/glimpsecore.md` for rule violations

Report format:
- Table of findings with: #, File, Severity (Critical/High/Medium/Low), Finding, Proposal
- Separate table of what passed per checklist section
- Test results summary
- Do NOT fix anything automatically — present findings first and wait for approval
