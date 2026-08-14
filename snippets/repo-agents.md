## Commit messages (house format)

Every commit message follows this shape — enforced locally by a commit-msg
hook and in CI by the commit-format action:

```
<type>: <Imperative sentence naming the user-visible outcome>

<body: what was wrong before, why this approach and not the obvious one>

<trailers>
```

Exactly one type, chosen by walking this ladder top-to-bottom and stopping at
the first yes: `wip` (incomplete/unreviewed — must not merge) → `revert`
(undoes an earlier commit) → `release` (only ships what exists) → `feat` (user
can now do something new) → `fix` (something already possible was broken, now
correct) → `perf` (same behaviour, measurably faster — no number, no perf) →
`refactor` (production code changed, behaviour identical, incl. formatting) →
`docs` (only prose) → `test` (only tests/fixtures) → `ci` (only pipeline
automation) → `build` (project files, packaging, signing, dependencies) →
`chore` (residue; re-walk the ladder once before using it).

No scopes — the repository is the scope. Subject: imperative mood, capitalised
after the type, no trailing period, ≤72 display columns preferred (88 hard).

`feat` and `fix` require a body. `feat`, `fix`, and `perf` require a `Tests:`
or `Evidence:` trailer carrying the command actually run and its real output —
no evidence, not done. Other trailers: `Closes: #N`, `Refs: #N`, `Breaking:`,
`Security:`.

Do not bypass the hook with `--no-verify`; fix the message instead.
