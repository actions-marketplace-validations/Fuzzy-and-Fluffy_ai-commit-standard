## Commit format (2026-08-14, global, enforced)
- Every commit follows `~/.claude/COMMIT-FORMAT.md`. A `commit-msg` hook at
  `~/.claude/git-hooks/` enforces it in every repo via global `core.hooksPath`.
- Shape: `<type>: <Imperative sentence naming the user-visible outcome>`, blank
  line, body explaining what was wrong before and why this approach, blank line,
  trailers. No scope — the repo is the scope.
- Type is a **partition** (exactly one), chosen by walking this ladder and
  stopping at the first yes: `wip` (incomplete/unreviewed, must not merge) →
  `revert` (undoes an earlier commit) → `release` (only ships what exists) →
  `feat` (user can now do something new) → `fix` (something already possible
  was broken, now correct) → `perf` (same behaviour, measurably faster — no
  number, no perf) → `refactor` (production code changed, behaviour identical,
  incl. formatting) → `docs` (only prose) → `test` (only tests/fixtures) →
  `ci` (only pipeline automation) → `build` (project files, packaging, signing,
  dependencies) → `chore` (residue; if you land here, re-walk the ladder once).
  Classify by the user-visible delta, not by author intent. Mixed maintenance
  commits land in `chore` — split them if you want the signal.
- Trailers are **orthogonal facts**, any number: `Tests:` / `Evidence:` /
  `Verified:` (the command actually run and its real output — **required on
  `feat`, `fix`, and `perf`**), `Closes: #N`, `Refs: #N`, `Breaking:`,
  `Security:`, `Co-Authored-By:`.
- History analytics: `~/.claude/scripts/commit-stats.py REPO...` (coverage,
  per-type counts, evidence coverage, chore share; `--weekly` for trends).
- Never reach for `--no-verify` to get past the hook. Fix the message.
