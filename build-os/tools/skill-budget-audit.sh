#!/usr/bin/env bash
# Build OS — skill-budget audit (P-011).
# Counts skills per plugin/marketplace under a plugins root (default ~/.claude/plugins)
# and reports the dominators + an approximate metadata-char total, flagging when it
# exceeds Claude Code's startup skill budget (default 30000). Read-only. Portable
# (python3 only). Run on the HOST to identify which enabled plugins to trim.
#
# Usage: skill-budget-audit.sh [PLUGINS_DIR] [BUDGET_CHARS]
set -uo pipefail
DIR="${1:-$HOME/.claude/plugins}"
BUDGET="${2:-30000}"

if [ ! -d "$DIR" ]; then
  echo "skill-budget-audit: no plugins dir at $DIR (nothing to audit)"
  exit 0
fi

python3 - "$DIR" "$BUDGET" <<'PY'
import os, sys
root, budget = sys.argv[1], int(sys.argv[2])
# A "skill" is any directory containing a SKILL.md under the plugins root.
per = {}                 # top-level plugin/marketplace dir -> [skill_count, approx_chars]
total_skills = total_chars = 0
for dirpath, _dirs, files in os.walk(root):
    if "SKILL.md" in files:
        rel = os.path.relpath(dirpath, root)
        top = rel.split(os.sep)[0] if rel != "." else "(root)"
        try:
            size = os.path.getsize(os.path.join(dirpath, "SKILL.md"))
        except OSError:
            size = 0
        c = per.setdefault(top, [0, 0]); c[0] += 1; c[1] += size
        total_skills += 1; total_chars += size

print("Skill-budget audit: %s" % root)
print("  total skills: %d   approx SKILL.md chars: %d   budget: %d" % (total_skills, total_chars, budget))
print("  status: %s" % ("OVER BUDGET" if total_chars > budget else "within budget"))
print("  dominators (skills, approx chars) — trim these first:")
for top, (n, ch) in sorted(per.items(), key=lambda kv: kv[1][0], reverse=True)[:15]:
    print("    %-40s %5d skills  %8d chars" % (top, n, ch))
PY
