# commit-format

A portable commit-message standard and its enforcement toolkit. One decidable
type per commit, evidence required where it matters, and analytics that make
the history worth studying.

Full specification: [COMMIT-FORMAT.md](COMMIT-FORMAT.md). In short:

```
<type>: <Imperative sentence naming the user-visible outcome>

<body: what was wrong before, why this approach>

Tests: uv run pytest -q -> 96 passed
Closes: #31
```

The type is picked by walking a 12-rung ladder top-to-bottom and stopping at
the first yes — `wip → revert → release → feat → fix → perf → refactor → docs
→ test → ci → build → chore` — so classification is never a judgement call.
`feat`, `fix`, and `perf` mechanically require a `Tests:`/`Evidence:` trailer:
no evidence, not done. Scopes are opt-in per repo via a checked-in
`.commit-scopes` registry — validated, never free-form.

## Install on a machine (local enforcement)

```bash
git clone https://github.com/Fuzzy-and-Fluffy/commit-format.git && cd commit-format && ./install.sh
```

Idempotent; re-run any time. This installs, for every repo on the machine
(including future clones and worktrees):

- `~/.claude/git-hooks/commit-msg` — the gate, wired via global
  `core.hooksPath`; chains to any per-repo hooks so they keep working
- `~/.claude/COMMIT-FORMAT.md` — the spec
- `~/.claude/scripts/commit-stats.py` — history analytics
- `~/.claude/scripts/install-commit-format.sh` — check / enable / disable tool
- `~/.claude/skills/commit-format/` — Claude Code skill
- Managed instruction blocks in `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`
  so Claude Code and Codex write conforming messages by default

The installer ends by proving the gate can fail (a bad message must be
rejected, a good one accepted) — an installer that only copies files would
happily install a dead gate.

## Gate a repo in CI (covers cloud agents, other machines, collaborators)

A local hook cannot reach a cloud sandbox or a collaborator's laptop. The CI
action checks every commit server-side on push/PR:

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0
- uses: Fuzzy-and-Fluffy/commit-format/action@main
  with:
    forbid-wip: 'true'   # PRs targeting main: wip must be squashed first
```

For cloud agents to *write* conforming messages (their sandboxes have no
`~/.claude`), copy [snippets/repo-agents.md](snippets/repo-agents.md) into the
target repo's `AGENTS.md` / `CLAUDE.md`.

## Analytics

```bash
python3 ~/.claude/scripts/commit-stats.py --weekly --gaps --ref origin/main REPO
```

Reports typed coverage, per-type counts, evidence coverage on feat/fix/perf,
chore share (residue health), weekly trends, and the exact offending commits.
Legacy Angular-style prefixes (`feat(scope):`, `style:`) are folded in, so
pre-format history stays comparable.

## Layout

```
COMMIT-FORMAT.md          the specification (single source of truth)
install.sh                machine installer (install | check)
hooks/commit-msg          the commit-msg gate (python3, no dependencies)
hooks/pre-push            chains repo-local pre-push hooks + optional privacy scan
scripts/commit-stats.py   history analytics
scripts/install-commit-format.sh   check / enable / disable tool
action/                   composite GitHub Action (server-side gate)
skill/commit-format/      Claude Code skill
snippets/                 agent-instruction blocks (global + per-repo)
tests/test_commit_gate.py adversarial suite: 44 cases, run by CI
```

## Escape hatches

- Per repo (someone else's project, their rules):
  `git config commitformat.enabled false`
- Per commit: `git commit --no-verify` — the commit is then unchecked; prefer
  fixing the message
- Whole machine: `git config --global --unset core.hooksPath`
