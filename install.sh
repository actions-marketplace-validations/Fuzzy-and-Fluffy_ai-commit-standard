#!/usr/bin/env bash
# Install the commit-format toolkit on this machine.
#
#   ./install.sh            install everything and verify
#   ./install.sh check      verify only; also report drift between repo and installed copies
#
# What install does:
#   1. Copies the hook, spec, analytics, and check tool into ~/.claude
#   2. Copies the Claude Code skill into ~/.claude/skills/commit-format
#   3. Splices the agent instructions into ~/.claude/CLAUDE.md and
#      ~/.codex/AGENTS.md between managed-block markers (idempotent:
#      re-running replaces the block, never duplicates it)
#   4. Sets global core.hooksPath and proves the gate can fail
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
CLAUDE="$HOME/.claude"
MODE="${1:-install}"

fail() { printf '\033[31m✗ %s\033[0m\n' "$*" >&2; exit 1; }
ok()   { printf '\033[32m✓ %s\033[0m\n' "$*"; }
info() { printf '  %s\n' "$*"; }

PAIRS=(
  "hooks/commit-msg|$CLAUDE/git-hooks/commit-msg"
  "COMMIT-FORMAT.md|$CLAUDE/COMMIT-FORMAT.md"
  "scripts/commit-stats.py|$CLAUDE/scripts/commit-stats.py"
  "scripts/install-commit-format.sh|$CLAUDE/scripts/install-commit-format.sh"
  "skill/commit-format/SKILL.md|$CLAUDE/skills/commit-format/SKILL.md"
)

splice() {  # splice <target-file> <snippet-file>
  python3 - "$1" "$2" <<'EOF'
import os, sys
target, snippet = sys.argv[1], sys.argv[2]
BEGIN = "<!-- BEGIN commit-format managed block -->"
END = "<!-- END commit-format managed block -->"
block = BEGIN + "\n" + open(snippet).read().strip("\n") + "\n" + END + "\n"
os.makedirs(os.path.dirname(target), exist_ok=True)
text = open(target).read() if os.path.exists(target) else ""
if BEGIN in text and END in text:
    head, rest = text.split(BEGIN, 1)
    _, tail = rest.split(END, 1)
    text = head + block + tail.lstrip("\n")
    action = "updated"
elif text.strip():
    text = text.rstrip("\n") + "\n\n" + block
    action = "appended"
else:
    text = block
    action = "created"
open(target, "w").write(text)
print("  %s managed block in %s" % (action, target))
EOF
}

case "$MODE" in
  check)
    drift=0
    for pair in "${PAIRS[@]}"; do
      src="$REPO/${pair%%|*}"; dst="${pair##*|}"
      if [ ! -f "$dst" ]; then info "MISSING: $dst"; drift=1
      elif ! diff -q "$src" "$dst" >/dev/null; then info "DRIFT:   $dst differs from repo"; drift=1
      fi
    done
    [ "$drift" = 0 ] && ok "installed copies match the repo" || info "run ./install.sh to update"
    exec "$CLAUDE/scripts/install-commit-format.sh" check
    ;;
  install) ;;
  *) fail "unknown argument: $MODE (use: install | check)" ;;
esac

mkdir -p "$CLAUDE/git-hooks" "$CLAUDE/scripts" "$CLAUDE/skills/commit-format"
for pair in "${PAIRS[@]}"; do
  cp "$REPO/${pair%%|*}" "${pair##*|}"
done
chmod +x "$CLAUDE/git-hooks/commit-msg" "$CLAUDE/scripts/install-commit-format.sh"

splice "$CLAUDE/CLAUDE.md" "$REPO/snippets/global-CLAUDE.md"
splice "$HOME/.codex/AGENTS.md" "$REPO/snippets/global-AGENTS.md"

# hooksPath + prove-the-gate-can-fail live in the check tool; delegate.
"$CLAUDE/scripts/install-commit-format.sh" install

ok "commit-format toolkit installed from $REPO"
info "per-repo CI gate: see README.md (uses: Fuzzy-and-Fluffy/commit-format/action@main)"
