#!/usr/bin/env bash
# Install / verify the shared commit-msg gate described in ~/.claude/COMMIT-FORMAT.md
#
#   install-commit-format.sh            install and verify
#   install-commit-format.sh check      verify only, change nothing
#   install-commit-format.sh disable    stop enforcing in the current repo
#   install-commit-format.sh enable     resume enforcing in the current repo
set -euo pipefail

HOOKS_DIR="$HOME/.claude/git-hooks"
HOOK="$HOOKS_DIR/commit-msg"
SPEC="$HOME/.claude/COMMIT-FORMAT.md"

fail() { printf '\033[31m✗ %s\033[0m\n' "$*" >&2; exit 1; }
ok()   { printf '\033[32m✓ %s\033[0m\n' "$*"; }
info() { printf '  %s\n' "$*"; }

case "${1:-install}" in
  disable)
    git rev-parse --git-dir >/dev/null 2>&1 || fail "not inside a git repository"
    git config commitformat.enabled false
    ok "commit format gate disabled in $(git rev-parse --show-toplevel)"
    exit 0
    ;;
  enable)
    git rev-parse --git-dir >/dev/null 2>&1 || fail "not inside a git repository"
    git config --unset commitformat.enabled 2>/dev/null || true
    ok "commit format gate enabled in $(git rev-parse --show-toplevel)"
    exit 0
    ;;
  check|install) ;;
  *) fail "unknown argument: $1 (use: install | check | disable | enable)" ;;
esac

[ -f "$SPEC" ] || fail "spec missing: $SPEC"
[ -f "$HOOK" ] || fail "hook missing: $HOOK"

if [ "${1:-install}" = "install" ]; then
  chmod +x "$HOOK"
  # Warn rather than clobber if hooksPath already points elsewhere.
  current="$(git config --global --get core.hooksPath || true)"
  if [ -n "$current" ] && [ "$current" != "$HOOKS_DIR" ]; then
    fail "core.hooksPath is already set to '$current'. Not overwriting it. Merge by hand."
  fi
  git config --global core.hooksPath "$HOOKS_DIR"
fi

# --- verification -----------------------------------------------------------
[ -x "$HOOK" ] || fail "hook is not executable: $HOOK"
[ "$(git config --global --get core.hooksPath || true)" = "$HOOKS_DIR" ] \
  || fail "core.hooksPath is not $HOOKS_DIR"

# The gate must be able to turn red. Prove it on a throwaway message, never on a
# real commit: a guard that has only ever been observed passing is not a guard.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

printf 'Add a thing without any type prefix\n' > "$tmp/bad"
if "$HOOK" "$tmp/bad" >/dev/null 2>&1; then
  fail "GATE IS DEAD: it accepted a message with no type prefix"
fi

printf 'chore: Rename the worker entry point\n' > "$tmp/good"
if ! "$HOOK" "$tmp/good" >/dev/null 2>&1; then
  fail "GATE IS WRONG: it rejected a valid chore message"
fi

printf 'fix: Stop paying for the same homepage twice\n\nThe discovery pass fetched it twice.\n\nTests: pytest -q -> 96 passed\n' > "$tmp/good2"
if ! "$HOOK" "$tmp/good2" >/dev/null 2>&1; then
  fail "GATE IS WRONG: it rejected a valid fix message"
fi

printf 'fix: Stop paying for the same homepage twice\n\nThe discovery pass fetched it twice.\n' > "$tmp/bad2"
if "$HOOK" "$tmp/bad2" >/dev/null 2>&1; then
  fail "GATE IS DEAD: it accepted a fix with no Tests:/Evidence: trailer"
fi

ok "commit format gate installed and proven able to fail"
info "spec:      $SPEC"
info "hook:      $HOOK"
info "scope:     every repo on this machine, including new clones and worktrees"
info "opt out:   git config commitformat.enabled false   (per repo)"
info "bypass:    git commit --no-verify                  (per commit)"
