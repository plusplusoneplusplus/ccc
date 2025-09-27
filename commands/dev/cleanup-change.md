### Clean up temporary or abandoned changes

Use this when a change includes exploratory edits, temporary scaffolding, debug-only code, ad-hoc test files, or leftover configs/flags. The goal is a minimal, coherent repo with no dead code or stray artifacts.

#### Scope (examples)
- Debug-only logs or probes; commented-out snippets
- Temporary test files or repros not meant to ship
- One-off scripts, sample data, generated artifacts, or local notes
- Temporary flags/config toggles and unused abstractions

#### How to proceed (high level)
1) Review the current diffs and status
2) Decide per item: keep, gate (dev-only), or remove
3) Apply the minimal necessary cleanup; update docs if behavior changes
4) Verify build, tests, and lint pass with only intentional changes left

#### Deliverables
- 1–3 sentence summary of what was cleaned
- Bullet list of removals/changes with brief rationale
- Confirmation that build/tests/lints pass