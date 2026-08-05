#!/usr/bin/env bash
# Build OS — routing enforcement: the binding mode selector, the routing
# receipt, and the close-time gate (PACKET-0050-routing-enforcement).
#
# THE TWO EXECUTED DEFECTS THIS SUITE EXISTS AGAINST, from EXP-0002's sealed
# records (build-os/experiments/EXP-0002-sustained-workload/runs/):
#
#   1. ENFORCEMENT — buildos T5 executed Full ceremony (4 subagent dispatches,
#      $4.80, 7.4M total tokens) while its own run record carried
#      `mode_selector_says: gravito_light`. The verdict was recorded and then
#      ignored, silently. The mechanical half of the fix is the routing receipt
#      plus routing-check.sh: an executed_mode above the selected_mode with no
#      escalation record is a REFUSAL at close, not a footnote.
#   2. CALIBRATION — buildos T3 was scored `gravito_full` by the frozen
#      heuristic and the correctly-selected Full ceremony cost 3.9x (5
#      dispatches, $3.63) on a bounded feature. The fix is the recalibrated
#      product selector: complexity alone no longer grants Full; at least one
#      VALUE factor must also be true, or Full is withheld with a printed note.
#
# WHY THE GATE CHAINS HERE AND NOT INSIDE scan-controls.sh check: the prior
# checks that chain on scan-controls' `check` path (anchors_check, counts_check)
# are INTERNAL functions of that file — scan-controls.sh invokes no external
# script. Every external refusal-capable tool in this tree (bandwidth-check.sh,
# authority-envelope.sh, claim-evidence.sh, ...) is instead driven by a chained
# test suite. This file is that suite, chained via tests/build_os_tests.sh
# section 26, and section 6 below runs the close-time sweep against the LIVE
# receipt store on every suite run — so the gate executes as often as the scan
# does, without making scan-controls.sh a launcher it has never been.
#
# No network. Deterministic. Fixture receipts live in mktemp dirs; only the
# live-sweep section reads (never writes) build-os/packets/routing/.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="$SRC/build-os/tools/mode-select.mjs"
ROUTE="$SRC/build-os/tools/route-task.sh"
RCHECK="$SRC/build-os/tools/routing-check.sh"
CONTRACT="$SRC/build-os/memory/routing_contract.md"
LIVE_DIR="$SRC/build-os/packets/routing"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# One descriptor builder, so every test case states only what it varies.
# mkdesc <files> <tests> <sessions> <prior> <handoff> <consequence> <value-csv>
# value-csv names the value factors set true; every other value factor is false.
mkdesc(){
  local files="$1" tests="$2" sessions="$3" prior="$4" handoff="$5" cons="$6" vals="${7:-}"
  local f v
  printf '{'
  printf '"expected_files_changed":%s,"requires_tests":%s,"expected_session_count":%s,' "$files" "$tests" "$sessions"
  printf '"prior_context_required":%s,"handoff_required":%s,"consequence_level":"%s"' "$prior" "$handoff" "$cons"
  for f in irreversible_or_external_mutation high_blast_radius unclear_acceptance_criteria \
           security_or_compliance_consequence parallel_workstreams_benefit high_rework_history \
           nondeterministic_verification; do
    v=false
    case ",$vals," in *",$f,"*) v=true ;; esac
    printf ',"%s":%s' "$f" "$v"
  done
  printf '}'
}

echo "== 1. The three tools exist, are executable, and the contract file is present =="
[ -f "$MODE" ]   && ok "mode-select.mjs exists"    || no "mode-select.mjs missing"
[ -x "$MODE" ]   && ok "mode-select.mjs is executable (build-os/tools convention)" || no "mode-select.mjs not executable"
[ -x "$ROUTE" ]  && ok "route-task.sh present + executable"    || no "route-task.sh missing/not executable"
[ -x "$RCHECK" ] && ok "routing-check.sh present + executable" || no "routing-check.sh missing/not executable"
[ -f "$CONTRACT" ] && ok "routing_contract.md exists" || no "routing_contract.md missing"

echo "== 2. mode-select: the recalibration — complexity alone no longer buys Full =="
# T3's defect, replayed: a multi-step descriptor (files >= 4) with NO value
# factor. The frozen experiment selector says gravito_full here; the product
# selector must withhold Full and say why.
D_T3="$(mkdesc 4 true 1 true false medium)"
OUT="$(node "$MODE" "$D_T3" 2>"$WORK/note.err")"; RC=$?
{ [ "$RC" = "0" ] && [ "$OUT" = "gravito_light" ]; } \
  && ok "multi-step descriptor with zero value factors -> gravito_light (Full withheld)" \
  || no "expected gravito_light for complexity-without-value, got \"$OUT\" (exit $RC)"
grep -qi "withheld" "$WORK/note.err" \
  && ok "the withholding is a printed note, not a silent downgrade" \
  || no "no note printed naming why Full was withheld"
grep -qi "value factor" "$WORK/note.err" \
  && ok "the note names the missing value evidence" \
  || no "the note does not name the value-factor rule"
# ...and the SAME complexity descriptor WITH one value factor is granted Full.
for vf in irreversible_or_external_mutation high_blast_radius unclear_acceptance_criteria \
          security_or_compliance_consequence parallel_workstreams_benefit high_rework_history \
          nondeterministic_verification; do
  OUT="$(node "$MODE" "$(mkdesc 4 true 1 true false medium "$vf")" 2>/dev/null)"
  [ "$OUT" = "gravito_full" ] \
    && ok "complexity + $vf -> gravito_full" \
    || no "complexity + $vf gave \"$OUT\", not gravito_full"
done
# Multi-session and high-consequence complexity triggers behave the same way.
OUT="$(node "$MODE" "$(mkdesc 2 true 3 true false medium)" 2>/dev/null)"
[ "$OUT" = "gravito_light" ] \
  && ok "multi-session without value evidence is also withheld to gravito_light" \
  || no "multi-session without value evidence gave \"$OUT\""
OUT="$(node "$MODE" "$(mkdesc 2 true 3 true false medium high_rework_history)" 2>/dev/null)"
[ "$OUT" = "gravito_full" ] \
  && ok "multi-session with a value factor is granted gravito_full" \
  || no "multi-session with a value factor gave \"$OUT\""

echo "== 3. mode-select: the frozen rules that survive, and the refusals =="
OUT="$(node "$MODE" "$(mkdesc 1 false 1 false false low)" 2>/dev/null)"
[ "$OUT" = "direct" ] \
  && ok "tiny + isolated + low -> direct (rule preserved from the experiment selector)" \
  || no "tiny/isolated/low gave \"$OUT\", not direct"
OUT="$(node "$MODE" "$(mkdesc 2 true 1 true false medium)" 2>/dev/null)"
[ "$OUT" = "gravito_light" ] \
  && ok "bounded one-session context-bearing work -> gravito_light" \
  || no "bounded work gave \"$OUT\", not gravito_light"
# A value factor WITHOUT a complexity trigger does not manufacture Full: the
# rule is complexity AND value, per the packet's recalibration.
OUT="$(node "$MODE" "$(mkdesc 2 true 1 true false medium high_blast_radius)" 2>/dev/null)"
[ "$OUT" = "gravito_light" ] \
  && ok "a value factor without a complexity trigger stays gravito_light (value alone is not multi-step)" \
  || no "value-without-complexity gave \"$OUT\""
# Refusals: a partial descriptor is REFUSED, never guessed (an unknown is not a zero).
PARTIAL='{"expected_files_changed":2,"requires_tests":true,"expected_session_count":1,"prior_context_required":true,"handoff_required":false,"consequence_level":"medium"}'
node "$MODE" "$PARTIAL" >/dev/null 2>"$WORK/p.err"; RC=$?
[ "$RC" = "2" ] \
  && ok "a six-field (experiment-shape) descriptor missing the value factors is REFUSED (exit 2)" \
  || no "partial descriptor got exit $RC, not 2"
grep -q "irreversible_or_external_mutation" "$WORK/p.err" \
  && ok "the refusal names the first missing field" \
  || no "the refusal does not name what is missing"
node "$MODE" 'not json' >/dev/null 2>&1; RC=$?
[ "$RC" = "2" ] && ok "malformed JSON is refused (exit 2)" || no "malformed JSON got exit $RC"
BADBOOL="$(mkdesc 4 true 1 true false medium | sed 's/"high_blast_radius":false/"high_blast_radius":"yes"/')"
node "$MODE" "$BADBOOL" >/dev/null 2>&1; RC=$?
[ "$RC" = "2" ] && ok "a non-boolean value factor is refused (exit 2)" || no "non-boolean value factor got exit $RC"
# Determinism: two runs over one descriptor are byte-identical, and nothing is written.
node "$MODE" "$D_T3" >"$WORK/d1.out" 2>"$WORK/d1.err"
node "$MODE" "$D_T3" >"$WORK/d2.out" 2>"$WORK/d2.err"
{ cmp -s "$WORK/d1.out" "$WORK/d2.out" && cmp -s "$WORK/d1.err" "$WORK/d2.err"; } \
  && ok "two runs over the same descriptor are byte-identical on both streams (pure function)" \
  || no "mode-select is not deterministic"

echo "== 4. route-task: a well-formed routing receipt, one file per decision =="
RDIR="$WORK/receipts"
D_LIGHT="$(mkdesc 2 true 1 true false medium)"
ROUT="$(bash "$ROUTE" --task-id T-LIGHT-01 --description "a bounded one-session feature" --descriptor "$D_LIGHT" --out "$RDIR" 2>&1)"; RC=$?
[ "$RC" = "0" ] && ok "route-task issues a light receipt at exit 0" || { no "route-task exit $RC"; printf '%s\n' "$ROUT" | sed 's/^/      | /'; }
REC="$(find "$RDIR" -name 'routing-T-LIGHT-01-*.md' 2>/dev/null | sed -n '1p')"
[ -n "$REC" ] && [ -f "$REC" ] && ok "exactly one receipt file written under --out" || no "no receipt file found under $RDIR"
NREC="$(find "$RDIR" -type f | grep -c . || true)"
[ "${NREC:-0}" = "1" ] && ok "one routing decision produced ONE file" || no "route-task wrote $NREC files for one decision"
for f in task_id description_sha256 descriptor selected_mode issued_at \
         budget_max_subagents budget_max_total_tokens budget_max_uncached_tokens \
         budget_max_model_calls budget_max_wall_clock_s budget_max_cost_usd \
         executed_mode escalation escalation_evidence \
         consumed_subagents consumed_total_tokens consumed_uncached_tokens \
         consumed_model_calls consumed_wall_clock_s consumed_cost_usd degradation_note; do
  grep -qE "^$f: " "$REC" && ok "receipt carries $f" || no "receipt is missing $f"
done
grep -qE '^selected_mode: gravito_light$' "$REC" \
  && ok "the receipt records the selector's own verdict (gravito_light)" \
  || no "selected_mode does not match the selector's verdict"
for f in executed_mode escalation escalation_evidence consumed_subagents consumed_total_tokens \
         consumed_uncached_tokens consumed_model_calls consumed_wall_clock_s consumed_cost_usd degradation_note; do
  grep -qE "^$f: -$" "$REC" && ok "$f is '-' at issue (empty-at-issue, an unknown is not a zero)" || no "$f is not '-' at issue"
done
EXPECT_SHA="$(printf '%s' "a bounded one-session feature" | sha256sum | awk '{print $1}')"
grep -qE "^description_sha256: $EXPECT_SHA$" "$REC" \
  && ok "description_sha256 is the sha256 of the description text (derived, checkable)" \
  || no "description_sha256 does not re-derive"
grep -q "DERIVED DEFAULTS" "$REC" \
  && ok "the receipt labels its budgets as DERIVED DEFAULTS, operator-tunable — not laws" \
  || no "the receipt does not label its budgets as derived defaults"
# A Full receipt carries the EXP-0002-derived Full budgets.
D_FULL="$(mkdesc 6 true 2 true true high high_blast_radius)"
bash "$ROUTE" --task-id T-FULL-01 --description "a genuinely full-mode packet" --descriptor "$D_FULL" --out "$RDIR" >/dev/null 2>&1; RC=$?
FREC="$(find "$RDIR" -name 'routing-T-FULL-01-*.md' | sed -n '1p')"
{ [ "$RC" = "0" ] && [ -n "$FREC" ]; } && ok "route-task issues a full receipt" || no "full receipt not issued (exit $RC)"
grep -qE '^selected_mode: gravito_full$' "$FREC" && ok "full descriptor + value factor -> selected_mode gravito_full" || no "full receipt selected_mode wrong"
grep -qE '^budget_max_subagents: 3$' "$FREC" \
  && ok "Full budget: max_subagents 3 (below the 4-5 the blowouts dispatched)" \
  || no "Full max_subagents is not the derived default 3"
grep -qE '^budget_max_total_tokens: 2000000$' "$FREC" \
  && ok "Full budget: max_total_tokens 2000000 (blowouts measured 4.9M/7.4M)" \
  || no "Full max_total_tokens is not the derived default 2000000"
grep -qE '^budget_max_cost_usd: 1.50$' "$FREC" \
  && ok "Full budget: max_cost_usd 1.50 (blowouts measured 3.63/4.80)" \
  || no "Full max_cost_usd is not the derived default 1.50"
# Refusals: malformed input never issues a receipt.
bash "$ROUTE" --task-id "" --description "x" --descriptor "$D_LIGHT" --out "$RDIR" >/dev/null 2>&1; RC=$?
[ "$RC" = "2" ] && ok "empty task id is refused (exit 2)" || no "empty task id got exit $RC"
bash "$ROUTE" --task-id "bad/../id" --description "x" --descriptor "$D_LIGHT" --out "$RDIR" >/dev/null 2>&1; RC=$?
[ "$RC" = "2" ] && ok "a path-shaped task id is refused (exit 2)" || no "path-shaped task id got exit $RC"
bash "$ROUTE" --task-id T-BAD-01 --description "x" --descriptor "$PARTIAL" --out "$RDIR" >/dev/null 2>&1; RC=$?
[ "$RC" = "2" ] && ok "a partial descriptor propagates the selector's refusal (exit 2)" || no "partial descriptor got exit $RC"
NREC2="$(find "$RDIR" -type f | grep -c . || true)"
[ "${NREC2:-0}" = "2" ] && ok "refused invocations wrote NO receipt (still 2 files)" || no "a refusal wrote a receipt ($NREC2 files)"

echo "== 5. routing-check: refusal is for CONTRADICTION, not absence =="
# Fixture builder: a receipt built by the REAL issuer, then damaged one field at
# a time, so a fixture the live tool would refuse cannot be smuggled in by hand.
mkfix(){ # <name> <sed-program...>  — copies the light receipt and applies edits
  local out="$WORK/fix-$1.md"; shift
  cp "$REC" "$out"
  local prog
  for prog in "$@"; do sed -i "$prog" "$out"; done
  printf '%s' "$out"
}
# RED 1 — T5, replayed as a receipt: selected light, executed full, NO
# escalation record. This is the exact defect: silent escalation.
F1="$(mkfix silent-escalation 's/^executed_mode: -$/executed_mode: gravito_full/')"
bash "$RCHECK" check --receipt "$F1" >"$WORK/f1.out" 2>&1; RC=$?
[ "$RC" = "2" ] && ok "RED: a silent-escalation receipt (executed full over selected light, escalation '-') is REFUSED (exit 2)" \
               || { no "RED FAILED: silent escalation passed (exit $RC)"; sed 's/^/      | /' "$WORK/f1.out"; }
grep -qi "escalation" "$WORK/f1.out" && ok "the refusal names the escalation rule" || no "the refusal does not say why"
# RED 2 — an escalation record with no evidence of what changed.
F2="$(mkfix evidence-free 's/^executed_mode: -$/executed_mode: gravito_full/' 's/^escalation: -$/escalation: escalated to gravito_full mid-task/')"
bash "$RCHECK" check --receipt "$F2" >"$WORK/f2.out" 2>&1; RC=$?
[ "$RC" = "2" ] && ok "RED: an escalation with NO evidence field naming what changed is REFUSED (exit 2)" \
               || no "RED FAILED: evidence-free escalation passed (exit $RC)"
# RED 3 — a filled consumption field over its budget with no degradation note.
F3="$(mkfix budget-breach 's/^executed_mode: -$/executed_mode: gravito_light/' 's/^consumed_total_tokens: -$/consumed_total_tokens: 7400000/')"
bash "$RCHECK" check --receipt "$F3" >"$WORK/f3.out" 2>&1; RC=$?
[ "$RC" = "2" ] && ok "RED: consumption over budget with NO degradation note is REFUSED (exit 2)" \
               || no "RED FAILED: undeclared budget breach passed (exit $RC)"
grep -qi "budget" "$WORK/f3.out" && ok "the refusal names the breached budget" || no "the breach refusal is unlabelled"
# RED 4 — a receipt claiming Full with no budgets at all.
F4="$(mkfix full-no-budgets 's/^selected_mode: gravito_light$/selected_mode: gravito_full/' 's/^budget_max_total_tokens: .*$/budget_max_total_tokens: -/')"
bash "$RCHECK" check --receipt "$F4" >"$WORK/f4.out" 2>&1; RC=$?
[ "$RC" = "2" ] && ok "RED: a Full receipt with no budgets is REFUSED (exit 2)" \
               || no "RED FAILED: budget-less Full receipt passed (exit $RC)"
# RED 5 — a receipt missing a required field is malformed, not silently partial.
F5="$(mkfix malformed '/^escalation: -$/d')"
bash "$RCHECK" check --receipt "$F5" >/dev/null 2>&1; RC=$?
[ "$RC" = "2" ] && ok "RED: a receipt missing a required field is REFUSED as malformed (exit 2)" \
               || no "RED FAILED: malformed receipt passed (exit $RC)"

echo "== 5b. routing-check: the passes — honest records are never punished =="
# PASS 1 — a clean, still-open light receipt: everything '-', nothing contradicts.
bash "$RCHECK" check --receipt "$REC" >"$WORK/p1.out" 2>&1; RC=$?
[ "$RC" = "0" ] && ok "a clean light receipt with '-' consumption PASSES (an unknown is not a zero)" \
               || { no "clean light receipt refused (exit $RC)"; sed 's/^/      | /' "$WORK/p1.out"; }
grep -qi "admission" "$WORK/p1.out" \
  && ok "'-' fields are reported as admissions, not treated as zeros" \
  || no "the pass does not distinguish admissions from measurements"
# PASS 2 — executed at or below selected: de-escalation is free.
P2="$(mkfix deescalated 's/^executed_mode: -$/executed_mode: direct/')"
bash "$RCHECK" check --receipt "$P2" >/dev/null 2>&1; RC=$?
[ "$RC" = "0" ] && ok "executed_mode BELOW selected_mode passes (de-escalation needs no record)" \
               || no "de-escalation was refused (exit $RC)"
# PASS 3 — an escalation WITH evidence recorded passes the gate.
P3="$(mkfix escalated-with-evidence \
  's/^executed_mode: -$/executed_mode: gravito_full/' \
  's/^escalation: -$/escalation: escalated gravito_light -> gravito_full/' \
  's|^escalation_evidence: -$|escalation_evidence: a hidden cross-module dependency surfaced at file 3 of 2 expected; new decision recorded before escalated work began|')"
bash "$RCHECK" check --receipt "$P3" >/dev/null 2>&1; RC=$?
[ "$RC" = "0" ] && ok "an evidence-bearing escalation passes (escalation is legal, silence is not)" \
               || no "evidence-bearing escalation refused (exit $RC)"
# PASS 4 — a breach that DECLARES its degradation passes: the gate polices
# honesty of the record, not the misfortune itself.
P4="$(mkfix declared-breach \
  's/^executed_mode: -$/executed_mode: gravito_light/' \
  's/^consumed_total_tokens: -$/consumed_total_tokens: 600000/' \
  's/^degradation_note: -$/degradation_note: budget approached at stage 2; stopped spawning, collapsed remaining work into the parent loop, finished Light/')"
bash "$RCHECK" check --receipt "$P4" >/dev/null 2>&1; RC=$?
[ "$RC" = "0" ] && ok "an over-budget receipt WITH a degradation note passes (refusal is for concealment)" \
               || no "a declared degradation was refused (exit $RC)"
# PASS 5 — consumption within budget, fully filled in.
P5="$(mkfix within-budget \
  's/^executed_mode: -$/executed_mode: gravito_light/' \
  's/^consumed_subagents: -$/consumed_subagents: 0/' \
  's/^consumed_total_tokens: -$/consumed_total_tokens: 310000/' \
  's/^consumed_cost_usd: -$/consumed_cost_usd: 0.31/')"
bash "$RCHECK" check --receipt "$P5" >/dev/null 2>&1; RC=$?
[ "$RC" = "0" ] && ok "filled-in consumption within budget passes" || no "within-budget consumption refused (exit $RC)"

echo "== 6. The sweep: the live receipt store is gated on every suite run =="
NLIVE="$(find "$LIVE_DIR" -maxdepth 1 -name '*.md' 2>/dev/null | grep -c . || true)"
[ "${NLIVE:-0}" -ge 1 ] \
  && ok "the live store $LIVE_DIR carries $NLIVE receipt(s) (the sweep below is not vacuous)" \
  || no "the live routing store is empty — the sweep would certify nothing"
bash "$RCHECK" check --dir "$LIVE_DIR" >"$WORK/live.out" 2>&1; RC=$?
[ "$RC" = "0" ] \
  && ok "routing-check sweeps the LIVE receipt store clean (exit 0)" \
  || { no "the live receipt store is REFUSED (exit $RC)"; sed 's/^/      | /' "$WORK/live.out"; }
# A sweep over an empty directory refuses rather than certifying nothing.
mkdir -p "$WORK/empty"
bash "$RCHECK" check --dir "$WORK/empty" >/dev/null 2>&1; RC=$?
[ "$RC" = "2" ] && ok "a sweep that finds zero receipts REFUSES (a blinded sweep certifies nothing)" \
               || no "an empty sweep exited $RC, not 2"

echo "== 7. The contract: protocol text honestly labeled as protocol =="
CBYTES="$(wc -c < "$CONTRACT" | tr -d ' ')"
[ "${CBYTES:-99999}" -le 4000 ] \
  && ok "routing_contract.md stays within its 4000-byte ceiling ($CBYTES B)" \
  || no "routing_contract.md is $CBYTES B, over the 4000-byte ceiling"
grep -q "MECHANICAL" "$CONTRACT" && ok "the contract labels the mechanical half by name" || no "no MECHANICAL label"
grep -q "PROTOCOL" "$CONTRACT"   && ok "the contract labels the protocol half by name"   || no "no PROTOCOL label"
grep -qi "binding" "$CONTRACT"   && ok "the recorded verdict is stated as binding"        || no "the contract does not state the verdict is binding"
grep -qi "silent escalation" "$CONTRACT" \
  && ok "silent escalation is prohibited in so many words" \
  || no "the contract does not prohibit silent escalation"
grep -qi "before the escalated work begins" "$CONTRACT" \
  && ok "escalation requires a recorded decision BEFORE the escalated work begins" \
  || no "the contract does not order the escalation record before the work"
for step in "stop spawning" "collapse" "preserve state" "continue Light" "report the degradation"; do
  grep -qi "$step" "$CONTRACT" && ok "circuit breaker names the step: $step" || no "circuit breaker missing step: $step"
done
grep -qi "never bare termination" "$CONTRACT" \
  && ok "bare termination is prohibited while a safe productive path remains" \
  || no "the contract does not prohibit bare termination"
grep -qi "not machine-visible" "$CONTRACT" \
  && ok "the contract admits live counters are not machine-visible to bash (no fake checkbox)" \
  || no "the contract does not admit the live-counter limitation"
grep -qi "verified at close" "$CONTRACT" \
  && ok "mid-flight breaker behaviour is verified at close via the receipt comparison" \
  || no "the contract does not say where the protocol half IS verified"

echo "== 8. The hook: CLAUDE.md requires a routing receipt for substantive packets =="
grep -q "routing_contract.md" "$SRC/CLAUDE.md" \
  && ok "CLAUDE.md points at routing_contract.md" \
  || no "CLAUDE.md does not reference the routing contract"
grep -q "route-task.sh" "$SRC/CLAUDE.md" \
  && ok "CLAUDE.md names the receipt issuer" \
  || no "CLAUDE.md does not name route-task.sh"
grep -qi "routing receipt" "$SRC/CLAUDE.md" \
  && ok "CLAUDE.md requires a routing receipt in so many words" \
  || no "CLAUDE.md does not require a routing receipt"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
