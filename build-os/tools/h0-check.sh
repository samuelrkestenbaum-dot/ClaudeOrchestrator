#!/usr/bin/env bash
# H0_system — Zone 2 system homeostasis: ONE deterministic pre-work health
# surface producing TYPED facts and a derived safe-agency verdict.
#
# Division of labor (no duplicate controls): `gravito preflight` answers
# "may Gravito be INSTALLED here"; `gravito diagnose` is the SUPPORT bundle;
# h0-check answers "what agency is SAFE right now" and is consulted before
# work (gravito run calls it first: state -> H0 -> reachability -> authority
# -> dispatch). Overlapping primitives (git validity, engine presence) are
# re-read facts, not competing controls.
#
# AUTHORITY RULES (Neurocosmology Zone 2, Class A/B):
#   - HARD BLOCK (exit 4) only for named Class-A invariants with direct
#     evidence: unreadable git state; goal installed but gate tool missing
#     (an unenforceable contract must not silently become no contract);
#     corrupt spend ledger (budget enforcement impossible => mutation
#     authority unverifiable).
#   - Everything else NARROWS or ANNOTATES agency — degraded noncritical
#     inputs never become a vague universal stop.
#
#   h0-check.sh [DIR]          human-readable + receipt; exit 0 ok / 4 blocked
#   h0-check.sh --json [DIR]   JSON facts only on stdout (same exit codes)
#   h0-check.sh --gate [DIR]   CLASS-A FACTS ONLY, fast, for per-mutation
#                              boundaries (PreToolUse). Exit 0 pass / 4 block
#                              with one reason line on stdout. No narrowing
#                              computation, no receipt churn — the caller owns
#                              the refusal receipt. This is the SAME canonical
#                              contract as the full surface, evaluated fresh at
#                              each boundary crossing (per-boundary evaluation,
#                              not double-application of one decision).
set -u
JSON=0; GATE=0; case "${1:-}" in --json) JSON=1; shift ;; --gate) GATE=1; shift ;; esac
D="${1:-$(pwd)}"; D="$(cd "$D" 2>/dev/null && pwd)" || { echo "h0: no such directory" >&2; exit 4; }

if [ "$GATE" -eq 1 ]; then
  git -C "$D" rev-parse --git-dir >/dev/null 2>&1 || { echo "H0 Class-A: not a readable git repository"; exit 4; }
  if [ -f "$D/gravito.goal" ]; then
    GC="$D/build-os/tools/goal-check.sh"; [ -x "$GC" ] || GC="$(dirname "${BASH_SOURCE[0]}")/goal-check.sh"
    [ -x "$GC" ] || { echo "H0 Class-A: gravito.goal installed but goal-check.sh missing (unenforceable contract)"; exit 4; }
  fi
  L="$D/build-os/memory/spend-ledger.jsonl"
  if [ -f "$L" ] && BAD=$(grep -cvE '^\{.*\}$' "$L") && [ "${BAD:-0}" -gt 0 ]; then
    echo "H0 Class-A: corrupt spend ledger ($BAD bad line(s)) — budget enforcement impossible"; exit 4
  fi
  exit 0
fi

FACTS=(); NARROW=(); BLOCK=()
fact(){ FACTS+=("{\"check\":\"$1\",\"ok\":$2,\"detail\":\"$3\"}"); }

# -- Class-A candidates ------------------------------------------------------
if git -C "$D" rev-parse --git-dir >/dev/null 2>&1; then
  fact git_state true "repository readable, branch $(git -C "$D" branch --show-current 2>/dev/null || echo '?')"
else
  fact git_state false "not a readable git repository"
  BLOCK+=("git_state: not a readable git repository (Class A: substrate identity unverifiable)")
fi

if [ -f "$D/gravito.goal" ]; then
  GC="$D/build-os/tools/goal-check.sh"; [ -x "$GC" ] || GC="$(dirname "${BASH_SOURCE[0]}")/goal-check.sh"
  if [ -x "$GC" ]; then fact goal_gate_tool true "goal installed, gate tool present"
  else fact goal_gate_tool false "gravito.goal installed but goal-check.sh missing"
       BLOCK+=("goal_gate_tool: contract installed but unenforceable (Class A)"); fi
else
  fact goal_gate_tool true "no goal installed — gate inactive by contract scope"
fi

LEDGER="$D/build-os/memory/spend-ledger.jsonl"
if [ -f "$LEDGER" ]; then
  if BAD=$(grep -cvE '^\{.*\}$' "$LEDGER") && [ "${BAD:-0}" -gt 0 ]; then
    fact ledger_integrity false "$BAD non-JSON line(s) in spend ledger"
    BLOCK+=("ledger_integrity: corrupt spend ledger — budget enforcement impossible (Class A)")
  else
    fact ledger_integrity true "$(grep -c . "$LEDGER") intact entries"
  fi
else
  fact ledger_integrity true "no ledger yet (zero spend)"
fi

# -- Class-B: narrow or annotate, never universally stop ---------------------
for rel in .claude/hooks/routing-gate.sh build-os/tools/goal-check.sh; do
  [ -f "$D/$rel" ] || { fact "engine:$rel" false "missing"; NARROW+=("engine file $rel missing — tool-level gating degraded; run gravito update"); }
done
[ ${#NARROW[@]} -eq 0 ] && fact engine_files true "gating engine files present" || true

PIDF="$D/build-os/receipts/run.pid"
if [ -f "$PIDF" ]; then
  if kill -0 "$(cat "$PIDF")" 2>/dev/null; then
    fact executor true "worker pid $(cat "$PIDF") live"
    NARROW+=("a worker is already running — no concurrent dispatch")
  else
    fact executor false "stale run.pid (process dead)"
    NARROW+=("stale run.pid — previous worker died; safe to clear (gravito stop)")
  fi
else
  fact executor true "no worker in flight"
fi

if command -v claude >/dev/null 2>&1; then fact provider_cli true "claude CLI on PATH (liveness NOT probed — probing costs spend)"
else fact provider_cli false "claude CLI absent"; NARROW+=("provider CLI absent — worker dispatch unavailable; local edits unaffected"); fi

AVAIL_KB=$(df -k "$D" 2>/dev/null | awk 'NR==2{print $4}'); AVAIL_KB="${AVAIL_KB:-0}"
if [ "$AVAIL_KB" -lt 51200 ]; then fact storage false "${AVAIL_KB}KB free"; NARROW+=("under 50MB free — no new run streams; cleanup first")
else fact storage true "${AVAIL_KB}KB free"; fi

if [ -d "$D/build-os/memory" ]; then
  if [ -f "$D/build-os/memory/.project-identity" ]; then fact memory_integrity true "identity stamp present"
  else fact memory_integrity false "memory store without identity stamp"; NARROW+=("un-stamped memory store — session-start will ADOPT or QUARANTINE; verify before relying on memory"); fi
else
  fact memory_integrity true "no memory store yet"
fi

fact context_capacity true "NOT OBSERVABLE from this surface — never inferred"

# -- derive agency -----------------------------------------------------------
if [ ${#BLOCK[@]} -gt 0 ]; then AGENCY="blocked"
elif [ ${#NARROW[@]} -gt 0 ]; then AGENCY="narrowed"
else AGENCY="full"; fi

TS="$(date -u +%FT%TZ)"
JOUT="{\"artifact\":\"h0_system\",\"at\":\"$TS\",\"dir\":\"$D\",\"agency\":\"$AGENCY\",\"facts\":[$(IFS=,; echo "${FACTS[*]}")],\"narrowed_by\":[$(printf '"%s",' "${NARROW[@]:-}" | sed 's/,$//; s/""//')],\"blocked_by\":[$(printf '"%s",' "${BLOCK[@]:-}" | sed 's/,$//; s/""//')]}"
mkdir -p "$D/build-os/receipts" 2>/dev/null && printf '%s\n' "$JOUT" > "$D/build-os/receipts/h0-latest.json" || true

if [ "$JSON" -eq 1 ]; then printf '%s\n' "$JOUT"
else
  echo "H0_system @ $TS — agency: $AGENCY"
  for f in "${FACTS[@]}"; do echo "  $f" | sed 's/[{}"]//g; s/check://; s/,ok:/ ok=/; s/,detail:/ — /'; done
  for n in "${NARROW[@]:-}"; do [ -n "$n" ] && echo "  NARROWED: $n"; done
  for b in "${BLOCK[@]:-}"; do [ -n "$b" ] && echo "  BLOCKED:  $b"; done
  echo "receipt: build-os/receipts/h0-latest.json"
fi
[ "$AGENCY" = "blocked" ] && exit 4 || exit 0
