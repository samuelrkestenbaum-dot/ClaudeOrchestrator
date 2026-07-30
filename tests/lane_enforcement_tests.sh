#!/usr/bin/env bash
# Build OS — lane enforcement tests (Gravito speed lane).
# Pins the mechanism that makes proportionality and parallelism enforceable
# instead of advisory: the five lanes and their gate-sets, the numeric `tiny`
# round budget, the escalation asymmetry, the fan-out protocol, and the
# entry-point (CLAUDE.md / global guidance) lane declaration.
#
# The canonical lane, escalation, and fan-out blocks are duplicated verbatim in
# the router and the orchestrator agent definition ON PURPOSE — an agent reads
# its own definition, a session reads the router, and prose that disagrees
# between them is exactly how a rule stops being a rule. These tests fail on
# DRIFT between the two copies, not merely on absence.
#
# No network. Deterministic. Temp dirs only. Exits non-zero if any assertion
# fails, and prints a final "==== RESULT: N passed, M failed ====" line.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROUTER="$SRC/build-os/memory/tool_router.md"
ORCH="$SRC/.claude/agents/build-orchestrator.md"
BUILDER="$SRC/.claude/agents/builder.md"
QA="$SRC/.claude/agents/qa.md"
REVIEWER="$SRC/.claude/agents/reviewer.md"
ARCHIVIST="$SRC/.claude/agents/archivist.md"
PROJ_CLAUDE="$SRC/CLAUDE.md"
GUIDANCE="$SRC/build-os/global-claude-md.md"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }
have(){ grep -qF "$2" "$1"; }
haveE(){ grep -qE "$2" "$1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Extract the text strictly BETWEEN a start and end sentinel (sentinels excluded).
block(){ awk -v s="$2" -v e="$3" 'index($0,s){f=1;next} index($0,e){f=0} f' "$1"; }

LANES=(read-only diagnosis tiny substantive architecture)
LANE_START="BUILD-OS:LANES:START"; LANE_END="BUILD-OS:LANES:END"
ESC_START="BUILD-OS:ESCALATION:START"; ESC_END="BUILD-OS:ESCALATION:END"
FAN_START="BUILD-OS:FANOUT:START"; FAN_END="BUILD-OS:FANOUT:END"

echo "== 1. The canonical lane table exists in BOTH the router and the orchestrator =="
block "$ROUTER" "$LANE_START" "$LANE_END" > "$WORK/lanes.router"
block "$ORCH"   "$LANE_START" "$LANE_END" > "$WORK/lanes.orch"
[ -s "$WORK/lanes.router" ] && ok "router carries a canonical lane block" || no "router has no canonical lane block ($LANE_START/$LANE_END)"
[ -s "$WORK/lanes.orch" ]   && ok "orchestrator carries a canonical lane block" || no "orchestrator has no canonical lane block ($LANE_START/$LANE_END)"

# VACUITY GUARD: if the row scanner matches nothing, every downstream lane
# assertion would "pass" against an empty set. Fail loudly instead.
LANE_ROW_RE='^\| `(read-only|diagnosis|tiny|substantive|architecture)` *\|'
ROWS_R="$(grep -cE "$LANE_ROW_RE" "$WORK/lanes.router" || true)"
ROWS_O="$(grep -cE "$LANE_ROW_RE" "$WORK/lanes.orch" || true)"
if [ "${ROWS_R:-0}" -ge 5 ] && [ "${ROWS_O:-0}" -ge 5 ]; then
  ok "lane-row scanner sees $ROWS_R router / $ROWS_O orchestrator rows (>= 5, not vacuous)"
else
  no "lane-row scanner matched $ROWS_R router / $ROWS_O orchestrator rows (expected >= 5) — it has gone blind, so every lane assertion below is meaningless"
fi

if diff -u "$WORK/lanes.router" "$WORK/lanes.orch" > "$WORK/lanes.diff" 2>&1; then
  ok "lane table is IDENTICAL in router and orchestrator (no drift)"
else
  no "lane table DRIFTED between router and orchestrator"
  sed -n '1,20p' "$WORK/lanes.diff" | sed 's/^/      | /'
fi

for lane in "${LANES[@]}"; do
  if grep -qE "^\| \`$lane\` *\|" "$WORK/lanes.router" && grep -qE "^\| \`$lane\` *\|" "$WORK/lanes.orch"; then
    ok "lane declared in both: $lane"
  else
    no "lane missing from router and/or orchestrator: $lane"
  fi
done

echo "== 2. Each lane states its gate-set =="
lane_row(){ grep -E "^\| \`$1\` *\|" "$WORK/lanes.router" | head -1; }
grep -qiE "answer directly|answer from evidence" <<<"$(lane_row read-only)"      && ok "read-only gate-set: answer directly, no chain"      || no "read-only lane does not state its gate-set"
grep -qiE "report" <<<"$(lane_row diagnosis)"                                     && ok "diagnosis gate-set: investigate and report"        || no "diagnosis lane does not state 'report'"
grep -qiE "do not implement|don't implement|no implementation" <<<"$(lane_row diagnosis)" && ok "diagnosis lane forbids implementing"      || no "diagnosis lane does not forbid implementing"
TINY_ROW="$(lane_row tiny)"
grep -qi "builder-lite" <<<"$TINY_ROW"                                            && ok "tiny gate-set names builder-lite"                  || no "tiny lane does not name builder-lite"
grep -qiE "ONE targeted check|one targeted check" <<<"$TINY_ROW"                  && ok "tiny gate-set names ONE targeted check"            || no "tiny lane does not name one targeted check"
for excluded in qa reviewer archivist packet receipt; do
  grep -qiE "no $excluded" <<<"$TINY_ROW" && ok "tiny lane excludes: $excluded" || no "tiny lane does not exclude: $excluded"
done
grep -qE "builder.*qa.*reviewer.*archivist" <<<"$(lane_row substantive)"          && ok "substantive gate-set is the full chain"            || no "substantive lane does not name builder/qa/reviewer/archivist"
grep -qiE "orchestrator routes first|routes first" <<<"$(lane_row architecture)"  && ok "architecture gate-set: orchestrator routes first"  || no "architecture lane does not say the orchestrator routes first"

echo "== 3. The tiny budget is stated NUMERICALLY (a budget you cannot count is not a budget) =="
haveE "$WORK/lanes.router" '\|[^|]*\b2 rounds?( max)?\b[^|]*\|' && ok "tiny round budget is numeric (2) in the lane table" || no "tiny round budget is not stated numerically in the lane table"
grep -qE "\b2 rounds?" <<<"$TINY_ROW" && ok "the numeric budget sits on the tiny row itself" || no "tiny row carries no numeric round budget"
for f in "$ROUTER" "$ORCH"; do
  haveE "$f" '\b1 round\b' && ok "single-round budget stated in $(basename "$f")" || no "no 1-round budget stated in $(basename "$f")"
done

echo "== 4. 'No gates' never means 'no go needed to push' =="
for f in "$ROUTER" "$ORCH"; do
  b="$(basename "$f")"
  if grep -qiE "every lane.*(external mutation|push|merge|deploy)|(external mutation|push/merge/deploy).*every lane" "$f"; then
    ok "$b: external mutation stays hard-gated at EVERY lane"
  else
    no "$b: no rule keeping external mutation gated at every lane"
  fi
done
if grep -qiE "no gates" "$ROUTER" && grep -qiE "never.*no go needed to push|not.*no go needed to push" "$ROUTER"; then
  ok "router explicitly denies the 'no gates = free push' reading"
else
  no "router does not explicitly deny the 'no gates = free push' reading"
fi

echo "== 5. Escalation costs a stated reason; de-escalation is free =="
block "$ROUTER" "$ESC_START" "$ESC_END" > "$WORK/esc.router"
block "$ORCH"   "$ESC_START" "$ESC_END" > "$WORK/esc.orch"
[ -s "$WORK/esc.router" ] && ok "router carries the escalation-asymmetry block" || no "router has no escalation-asymmetry block"
[ -s "$WORK/esc.orch" ]   && ok "orchestrator carries the escalation-asymmetry block" || no "orchestrator has no escalation-asymmetry block"
if diff -u "$WORK/esc.router" "$WORK/esc.orch" > "$WORK/esc.diff" 2>&1; then
  ok "escalation rule is IDENTICAL in router and orchestrator (no drift)"
else
  no "escalation rule DRIFTED between router and orchestrator"
  sed -n '1,20p' "$WORK/esc.diff" | sed 's/^/      | /'
fi
grep -qiE "de-escalat|down.*free|downward.*free" "$WORK/esc.router" && ok "de-escalation is declared free"     || no "de-escalation is not declared free"
grep -qiE "reason" "$WORK/esc.router"                                && ok "escalation requires a stated reason" || no "escalation does not require a stated reason"
for r in "defect" "dependency" "risk"; do
  grep -qi "$r" "$WORK/esc.router" && ok "escalation reason kind named: $r" || no "escalation reason kind missing: $r"
done
grep -qE "Lane: *[a-z-]+ *(→|->) *[a-z-]+" "$WORK/esc.router" && ok "escalation announcement has a concrete format" || no "escalation announcement format missing"
# The overrun rule itself.
for f in "$ROUTER" "$ORCH"; do
  b="$(basename "$f")"
  if grep -qiE "2 rounds and is not done|consumed (its )?2 rounds" "$f" && grep -qiE "re-classify|reclassify" "$f"; then
    ok "$b: a tiny task over budget must stop and re-classify"
  else
    no "$b: no stop-and-re-classify rule for an over-budget tiny task"
  fi
  grep -qiE "do not quietly keep going|don't quietly keep going" "$f" && ok "$b: forbids quietly continuing" || no "$b: does not forbid quietly continuing"
  grep -qiE "is itself a defect|is a defect" "$f" && ok "$b: names budget overrun a defect" || no "$b: does not name budget overrun a defect"
done
have "$BUILDER" "de-escalat" && ok "builder carries the escalation asymmetry" || no "builder does not carry the escalation asymmetry"
grep -qiE "Lane: *[a-z-]+ *(→|->) *[a-z-]+" "$BUILDER" && ok "builder must announce an escalation" || no "builder has no escalation announcement"

echo "== 6. Fan-out protocol: parallel by default, with all three requirements =="
block "$ROUTER" "$FAN_START" "$FAN_END" > "$WORK/fan.router"
block "$ORCH"   "$FAN_START" "$FAN_END" > "$WORK/fan.orch"
[ -s "$WORK/fan.router" ] && ok "router carries the fan-out protocol" || no "router has no fan-out protocol block"
[ -s "$WORK/fan.orch" ]   && ok "orchestrator carries the fan-out protocol" || no "orchestrator has no fan-out protocol block"
if diff -u "$WORK/fan.router" "$WORK/fan.orch" > "$WORK/fan.diff" 2>&1; then
  ok "fan-out protocol is IDENTICAL in router and orchestrator (no drift)"
else
  no "fan-out protocol DRIFTED between router and orchestrator"
  sed -n '1,20p' "$WORK/fan.diff" | sed 's/^/      | /'
fi
grep -qiE "2 .*(work items|items).*independent|independent.*fan out|fan out rather than sequence" "$WORK/fan.router" \
  && ok "fan-out triggers on >= 2 independent items" || no "fan-out trigger condition missing"
grep -qiE "disjoint file-ownership manifest" "$WORK/fan.router" && ok "requirement 1: disjoint file-ownership manifest" || no "requirement 1 missing: disjoint file-ownership manifest"
grep -qiE "non-overlapping|do not overlap"    "$WORK/fan.router" && ok "manifest must be non-overlapping"               || no "manifest non-overlap not stated"
grep -qiE "merge plan"                        "$WORK/fan.router" && ok "requirement 2: merge plan"                      || no "requirement 2 missing: merge plan"
grep -qiE "who merges"                        "$WORK/fan.router" && ok "merge plan names who merges"                    || no "merge plan does not name who merges"
grep -qiE "single verification|one verification" "$WORK/fan.router" && ok "merge plan names the single post-merge verification" || no "merge plan does not name the post-merge verification"
grep -qiE "(merger|merge owner) owns"         "$WORK/fan.router" && ok "requirement 3: merger owns the hot files"       || no "requirement 3 missing: merger owns hot files"
grep -qiE "test suite"                        "$WORK/fan.router" && ok "hot files include the test suite"               || no "hot files do not name the test suite"
grep -qiE "memory"                            "$WORK/fan.router" && ok "hot files include memory"                       || no "hot files do not name memory"
grep -qiE "worktree"                          "$WORK/fan.router" && ok "overlapping work routes to isolated worktrees + a merge pass" || no "no isolated-worktree alternative for overlapping work"
# A worked example must live in the router, where the work is routed from.
if grep -qiE "worked example" "$ROUTER" && grep -qE "^\| *(Agent|agent) ?[A-C1-3]" "$ROUTER"; then
  ok "router shows a worked fan-out example with a per-agent ownership manifest"
else
  no "router has no worked fan-out example with a per-agent ownership manifest"
fi

echo "== 7. Lanes are discoverable where the work starts (CLAUDE.md + global guidance) =="
for f in "$PROJ_CLAUDE" "$GUIDANCE"; do
  b="$(basename "$f")"
  step1="$(awk '/^1\. \*\*/{print; exit}' "$f")"
  grep -qi "lane" <<<"$step1" && ok "$b step 1 names the LANE ($(sed 's/\*//g;s/^1\. //' <<<"$step1" | cut -c1-46)…)" || no "$b step 1 does not name the lane: ${step1:-<no numbered step 1>}"
  grep -qiE "announce" <<<"$step1" && ok "$b step 1 requires announcing it" || no "$b step 1 does not require announcing the lane"
  grep -qE 'Lane: *`?tiny' "$f" && ok "$b shows a concrete lane announcement example" || no "$b shows no concrete lane announcement example"
  for lane in "${LANES[@]}"; do
    have "$f" "$lane" || no "$b never mentions lane: $lane"
  done
  grep -qE "\b2 rounds?" "$f" && ok "$b states the tiny lane's numeric budget" || no "$b omits the tiny lane's numeric budget"
done

echo "== 8. Nothing in the chain still universalises the heavy path =="
if grep -qiE "^- \*\*Always close a completed packet with a \*\*receipt" "$ORCH" || grep -qi "Always close a completed packet with a" "$ORCH"; then
  no "orchestrator still implies a receipt for EVERY change"
else
  ok "orchestrator no longer implies a receipt for every change"
fi
grep -qiE "substantive" "$ORCH" && ok "orchestrator scopes the heavy chain to the substantive lane" || no "orchestrator does not scope the heavy chain"
for f in "$QA" "$REVIEWER" "$ARCHIVIST"; do
  b="$(basename "$f")"
  grep -qi "substantive" "$f" && ok "$b states it belongs to the substantive lane only" || no "$b does not scope itself to the substantive lane"
done
# Backticks are formatting, not content — strip them before matching the claim.
tr -d '`' < "$QA" | grep -qiE "read-only, diagnosis, (and |or )?tiny" \
  && ok "qa names the lanes that do NOT invoke it" || no "qa does not name the lanes that skip it"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
