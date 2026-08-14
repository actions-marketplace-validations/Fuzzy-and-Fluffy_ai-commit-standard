---
name: commit-format
version: 1.0.0
description: |
  The house commit-message format: a 12-type first-match-wins ladder plus
  evidence trailers, mechanically enforced by a commit-msg hook and a CI
  action. Use when the user asks about commit message format, types
  (feat/fix/refactor/...), 提交规范 / commit 格式, why a commit was rejected
  by the hook, how to install the format on a new machine, how to add the CI
  gate to a repo, or wants commit-history analytics (commit-stats).
---

# commit-format

Single source of truth: `COMMIT-FORMAT.md` at the repo root (installed copy:
`~/.claude/COMMIT-FORMAT.md`). Read it before answering detailed questions.

## The format in one screen

```
<type>: <Imperative sentence naming the user-visible outcome>

<body: what was wrong before, why this approach and not the obvious one>

<trailers>
```

Exactly one type — walk the ladder top-to-bottom, stop at the first yes:

| Type | Ask |
|------|-----|
| `wip` | Knowingly incomplete or unreviewed? Must not be merged. |
| `revert` | Undoes an earlier commit? |
| `release` | Only ships what already exists (version/build bump)? |
| `feat` | User can now do something they could not before? |
| `fix` | Something already possible was broken, now correct? |
| `perf` | Same behaviour, measurably faster? No number, no perf. |
| `refactor` | Production code changed, behaviour identical (incl. formatting)? |
| `docs` | Only prose changed? |
| `test` | Only test code/fixtures changed? |
| `ci` | Only pipeline automation changed? |
| `build` | Only how-the-artifact-is-made changed (project files, packaging, signing, deps)? |
| `chore` | Residue. Rare by design — re-walk the ladder once first. |

Scopes are opt-in per repo: allowed only when the repo root has a
`.commit-scopes` registry listing them (`feat(dictation): ...`), rejected
otherwise. Subject: imperative, capitalised after the type, no trailing
period, ≤72 display columns preferred (88 hard, CJK counts as 2).

Trailers (any number): `Tests:` / `Evidence:` / `Verified:` — **required on
feat, fix, and perf**, carrying the command actually run and its real output —
plus `Closes: #N`, `Refs: #N`, `Breaking:`, `Security:`, `Co-Authored-By:`.

## Operations

All commands assume the toolkit repo is cloned somewhere (referred to as
`<repo>`; clone: https://github.com/Fuzzy-and-Fluffy/commit-format); on an installed machine the tools also live under `~/.claude`.

- **Install on this machine** (hook + spec + skill + agent instructions):
  `cd <repo> && ./install.sh` — idempotent, re-run any time.
- **Verify the gate works**: `<repo>/install.sh check` (or
  `~/.claude/scripts/install-commit-format.sh check`). This proves the gate
  can fail, not just that files exist.
- **History analytics**: `python3 ~/.claude/scripts/commit-stats.py
  [--since DATE] [--until DATE] [--ref origin/main] [--weekly] [--gaps] REPO...`
  Key metrics: typed coverage, evidence coverage on feat/fix/perf, chore share.
- **Enable scopes in a multi-module repo**: create `.commit-scopes` at the
  repo root, one module name per line (`#` comments allowed); commit it.
- **New module mid-work (agent-managed, no human step)**: before inventing a
  scope, check the registry for a near-synonym (merge spellings, never fork);
  if it is a genuinely new lasting module, add its line to `.commit-scopes`
  in the same commit that first uses it. One-off features get no scope.
- **Per-repo opt-out** (someone else's project, their rules):
  `git config commitformat.enabled false`; re-enable with
  `~/.claude/scripts/install-commit-format.sh enable`.
- **CI gate for a repo** (covers cloud agents, other machines, collaborators —
  environments where the local hook does not exist): add to a workflow:

  ```yaml
  - uses: actions/checkout@v4
    with:
      fetch-depth: 0
  - uses: Fuzzy-and-Fluffy/commit-format/action@main
    with:
      forbid-wip: 'true'   # on PRs targeting main
  ```

- **Cloud agents writing conforming messages**: copy
  `snippets/repo-agents.md` into the target repo's `AGENTS.md` / `CLAUDE.md`
  so sandboxed agents (no `~/.claude`) still know the rules.

## When a commit is rejected

The hook's error names the exact rule and shows the ladder. Fix the message —
never suggest `--no-verify` (it exists for emergencies; a bypassed commit is
unchecked). Common cases: missing type → pick from the ladder; `feat`/`fix`
without `Tests:`/`Evidence:` → run the verification and paste the real
result; `style:`/`feature:`/`bugfix:`/`deps:` → the error's hint names the
correct type.
