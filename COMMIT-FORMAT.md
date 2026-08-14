# Commit format

Single source of truth for commit messages in every repo on this machine.
Enforced mechanically by `~/.claude/git-hooks/commit-msg`.
History analytics over these types: `~/.claude/scripts/commit-stats.py`.

This format takes the one thing Conventional Commits gets right — a
machine-readable type that is visible in `git log --oneline` and in the GitHub
commit list — and fixes the three things it gets wrong: an undecidable type
list, a scope that costs characters and decides nothing, and no notion of
evidence.

## Shape

```
<type>: <Imperative sentence naming the user-visible outcome>

<Body: what was wrong before, why this change and not another.
Prose paragraphs, wrapped at ~78 columns.>

<Trailers>
```

## The two-axis rule

The core design decision, and the main departure from Conventional Commits:

- **Type is a partition.** Exactly one type per commit, never zero, never two.
- **Trailers are orthogonal facts.** Any number, in any combination. Security,
  breaking-ness, evidence, and issue links are all independent of type — a
  security fix can be a `feat`, a `fix`, or a `build`, so security is a
  trailer, not a type.

Conventional Commits conflates the two axes, which is why its `refactor` vs
`chore` vs `style` is a coin flip and why real-world histories collapse into
`fix`/`chore`.

## Types — ordered ladder, first match wins

Walk top to bottom, stop at the first `yes`. The ordering guarantees exactly
one answer, so the type is never a judgement call. The first six rungs classify
by **what changed for the user**; the next five classify user-invisible work by
**which artifact class changed**, which is what makes the history analysable
(how much rework, how much refactoring, how much test investment, how much
toil).

| # | Type | Ask |
|---|------|-----|
| 1 | `wip` | Is this knowingly incomplete, or has it not been reviewed yet? Must not be merged as-is. |
| 2 | `revert` | Does this undo an earlier commit? Name the undone commit in the body. |
| 3 | `release` | Does this only ship what already exists — version/build bump, release notes, tag prep? |
| 4 | `feat` | Can the user now do something they could not do before? |
| 5 | `fix` | Was something the user could already do broken or wrong, and is it now correct? |
| 6 | `perf` | Is the behaviour identical, but measurably faster or cheaper? No number, no `perf` — an unmeasured speed-up is a `refactor`. |
| 7 | `refactor` | Did production code change while runtime behaviour stayed identical? Renames, moves, structure, formatting. |
| 8 | `docs` | Did only prose change — README, specs, comments — with no behaviour change? |
| 9 | `test` | Did only test code or fixtures change? |
| 10 | `ci` | Did only pipeline automation change — workflows, hooks, deploy/release scripts? |
| 11 | `build` | Did only how-the-artifact-is-made change — project files, packaging, signing, dependencies? |
| 12 | `chore` | Residue: repo hygiene that fits nothing above (.gitignore, licence, folder moves). Rare by design — if you are here, re-walk the ladder once. |

Notes that keep the ladder deterministic:

- Classify by **what changed for the user**, not by what the author was doing.
  A three-day refactor the user cannot observe is `refactor`. A one-line change
  that unblocks a button is `feat`. "The user" is whoever operates the thing.
- `wip` outranks everything because "do not merge this" is the most important
  fact about the commit. Squash or amend `wip` commits into properly typed
  commits before merging.
- `revert` outranks `fix`: backing out a bad commit is a failure signal worth
  measuring on its own, even when the revert also fixes the bug. Git-generated
  `Revert "..."` subjects are accepted unchanged; hand-written back-outs use
  `revert:`.
- A commit that changes production code **and** its tests takes the production
  code's type (the artifact-class rungs all say *only*). A commit mixing
  several maintenance classes (tests + CI + deps) lands in `chore` — split it
  if you want the signal. Atomic commits are what make the analytics honest.
- Formatting-only changes are `refactor`, not a separate `style` type: same
  sharp question (code changed, behaviour identical), and it removes the
  classic coin flip.
- Dependency bumps are `build`: they change what the artifact is made of.
- Changing a release *script* is `ci`; bumping the version it ships is
  `release`.
- No scope. The repository is the scope. `feat(keyboard):` spends ten
  characters to say what the repo name already says.

### Mapping from Conventional Commits (Angular convention)

`feat` `fix` `docs` `refactor` `perf` `test` `build` `ci` `chore` `revert`
keep their names. `style` is folded into `refactor`. `wip` and `release` are
added because "do not merge" and "ships existing work" are the two states the
Angular list cannot express. Legacy history written in the Angular convention
therefore stays machine-readable by the same tooling.

## Subject rules

- Imperative mood: `Add`, `Stop`, `Give`, `Reject` — never `Added`, `Adds`,
  `Adding`, `Fixed`, `Updates`.
- Capitalised first word after the type.
- No trailing period.
- Name the outcome, not the file. `fix: Stop paying for the same homepage
  twice` beats `fix: Correct caching logic in fetcher.py`.
- Width: warn above 72 display columns, blocked above 88, measured in columns
  (CJK counts as 2) rather than bytes.

## Body

Required for `feat` and `fix`. Optional but expected elsewhere.

Explain what was wrong before, and why this approach rather than the obvious
alternative. The diff already says what changed; the body is the only place the
reasoning survives. State rejected alternatives explicitly — a reader six
months out cannot tell "I considered X and it was worse" from "I never thought
of X".

## Trailers

Any number, at the end, one per line, `Key: value`.

| Trailer | Meaning |
|---------|---------|
| `Tests:` | The command actually run and its real result. **Required for `feat`, `fix`, and `perf`.** |
| `Evidence:` | Same requirement, for what tests cannot show — screenshot path, probe output, a live-run number. Satisfies the requirement in place of `Tests:`. |
| `Verified:` | Alias of `Evidence:` for on-device / on-build verification. |
| `Closes: #N` | Issue this commit closes. |
| `Refs: #N` | Issue this commit relates to but does not close. |
| `Breaking:` | What breaks, and what the caller must do instead. |
| `Security:` | What exposure this closes, or knowingly creates. Independent of type. |
| `Co-Authored-By:` | Standard git trailer. |

`Tests:`/`Evidence:` being mechanically required on `feat`, `fix`, and `perf`
is the iron rule "no evidence = not done" made unbypassable. For `perf` the
evidence must contain the measurement — that is what separates it from
`refactor`. The evidence must exercise the user-visible capability, not a
proxy for it — `BUILD SUCCEEDED` is not evidence that a feature works.

## Examples

```
feat: Give notes somewhere to record which 收藏夹 they came from

Notes arrived with no trace of the collection folder they were filed under, so
a note about a rink and a note about a lease looked identical once imported.
Persist the source folder on the note and surface it in the list.

Storing the folder id rather than its name was rejected: the folders are
renamed often and the name is what she actually recognises.

Tests: uv run pytest tests/test_notes.py -q -> 48 passed
Closes: #31
```

```
perf: Stop paying for the same homepage twice

The discovery pass fetched the retailer homepage once to find the search form
and again to resolve the first product link, doubling the per-run cost for no
new information. Cache the first response for the lifetime of the run.

Evidence: full run against petcircle.com.au -> 41 requests, was 78
```

```
refactor: Extract the pack-size parser into one module

Three scrapers carried diverging copies of the same parsing rules; two had
already drifted. One module, one rule set.

Tests: uv run pytest -q -> 118 passed
```

```
revert: Back out the eager homepage cache

Reverts 41d2c07 (perf: Stop paying for the same homepage twice): the cache
served a logged-out page to logged-in runs. Undo first, rediagnose separately.

Refs: #31
```

```
build: Move identity values out of the repository into the environment

The worker read a legal name and bank details from a checked-in constants
file, so every clone carried them.

Security: removes personally identifying values from the work tree; the values
now come from the environment and are absent from history going forward.
```

## History analytics

`~/.claude/scripts/commit-stats.py REPO [REPO ...]` buckets history by type:
per-repo coverage (share of commits carrying a valid type), per-type counts,
evidence coverage on `feat`/`fix`/`perf`, and `chore` share as the
residue-health metric. It is descriptive where the hook is normative: it also
accepts legacy Angular-style prefixes (scoped `feat(x):`, `style:`) so
pre-format history stays countable.

## Bypasses

- `Merge ...`, `Revert "..."`, `fixup!`, `squash!`, `amend!` are accepted
  unchanged — git generates them.
- `git commit --no-verify` skips the hook entirely. It exists; using it means
  the commit is unchecked, so prefer fixing the message.
- A repo opts out permanently with `git config commitformat.enabled false`.

## Enforcement

`git config --global core.hooksPath ~/.claude/git-hooks` points every repo at
the shared hook, including new clones and worktrees. The hook chains to a
repo's own `.git/hooks/commit-msg` if one exists, so per-repo hooks keep
working.

Re-run `~/.claude/scripts/install-commit-format.sh` to (re)install or verify.

## Distribution

The canonical source is the `commit-format` repo; the `~/.claude` copies are
its installed artifacts. Three layers cover every environment:

1. **This machine, every repo**: the commit-msg hook via global
   `core.hooksPath` — installed by `install.sh` from the repo.
2. **Agents**: managed blocks in `~/.claude/CLAUDE.md` (Claude Code) and
   `~/.codex/AGENTS.md` (Codex) teach the format; for cloud sandboxes without
   `~/.claude`, copy `snippets/repo-agents.md` into the project's own
   `AGENTS.md`/`CLAUDE.md`.
3. **Server-side, every contributor and every cloud run**: the GitHub Action
   (`action/`) validates each commit on push/PR — the only layer that can
   gate environments the local hook cannot reach.

New machine: `git clone <repo> && ./install.sh`. Drift check:
`./install.sh check`.
