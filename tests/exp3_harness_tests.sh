#!/usr/bin/env bash
# Build OS — EXP-0003 harness: the deterministic scripted T1/T2 setup, the
# routing-frontier runner's refusal paths, and the mechanical close-time
# receipt loop (PACKET-0051-exp0003-routing-frontier).
#
# WHAT THIS SUITE PROVES, by execution:
#   1. setup-t1t2.sh is byte-reproducible (two seeds, two setups, identical
#      tree digests, equal to the preregistered pin), leaves the suite at the
#      exact pinned total, and DRIVES the frozen EXP-0002 oracle on T1 and T2
#      rather than asserting them.
#   2. run-exp3-task.sh refuses bad conditions, unmeasured tasks (T1/T2 are
#      scripted by design), missing preconditions, and a close over condition
#      A (which has NO receipt, disclosed) — red drives, not conventions.
#   3. The close-time loop is MECHANICAL: consumption summed from sealed
#      records into a receipt the REAL issuer wrote, gated by the REAL
#      routing-check.sh; an under-budget fill passes; a fabricated
#      over-budget, dispatching fill is REFUSED (SILENT-ESCALATION +
#      BUDGET-BREACH) and RETAINED as data; a second fill is refused.
#   4. The frozen prompt pins in the preregistration equal what the runner's
#      own extraction derives from EXP-0002's frozen tasks.md.
#
# No network. Deterministic. Fixtures live in mktemp dirs; nothing under
# build-os/experiments/ is written. No claude invocation occurs anywhere in
# this suite — every green path exercised here is a scripted or close-mode
# path, so the suite spends zero model tokens.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
H="$SRC/build-os/experiments/EXP-0003-routing-frontier/harness"
SETUP="$H/setup-t1t2.sh"
RUNNER="$H/run-exp3-task.sh"
PREREG="$SRC/build-os/experiments/EXP-0003-routing-frontier/PREREGISTRATION.md"
HREADME="$H/README.md"
EXP2_H="$SRC/build-os/experiments/EXP-0002-sustained-workload/harness"
SEEDER="$EXP2_H/seed-workload-repo.sh"
TASKS_MD="$EXP2_H/tasks.md"
ROUTE="$SRC/build-os/tools/route-task.sh"

PIN_SETUP_DIGEST="6c77b5a4bda46ba4730ccf1b2a08725a76523e87ac7402096744659d0c47b6aa"
PIN_SHA_T3="aa51dd7f4329ecfabd20348cefe0e78cc324cefe9c6e9b56455bc7b8e163fcbc"
PIN_SHA_T4="39638bc19253701d624915b5e9c651335e9f1193cf7da9b1a7f49c552fad29f1"
PIN_SHA_T5="f2dd4ce545ffd523a564ed9139d9f3b86725a0b1b48c98eabd3fd7ef53031d5c"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "== 1. Layout: the harness exists and is NON-executable (census must not move) =="
for f in "$SETUP" "$RUNNER" "$PREREG" "$HREADME"; do
  [ -f "$f" ] && ok "$(basename "$f") exists" || no "$(basename "$f") missing"
done
[ ! -x "$SETUP" ]  && ok "setup-t1t2.sh is NOT executable (invoked via bash, by design)" || no "setup-t1t2.sh is executable"
[ ! -x "$RUNNER" ] && ok "run-exp3-task.sh is NOT executable (invoked via bash, by design)" || no "run-exp3-task.sh is executable"
# THE CENSUS, WITH ONE NARROW HISTORICAL EXCEPTION.
#
# build-os/experiments/EXP-0005-system-efficiency/harness/restore-seed.sh is
# tracked at mode 755 and is a FROZEN EXP-0005 artifact. The standing
# instruction forbids altering, rewriting, deleting or regenerating one, and a
# chmod is an alteration. The operator ruled that its immutability outranks a
# tidier census assumption, so it is exempted here rather than modified there.
#
# The exemption is deliberately unable to grow: ONE exact relative path and ONE
# exact expected mode, compared literally. No glob, no directory prefix, no
# "*.sh under EXP-*" -- a pattern would silently exempt every future experiment
# file, which is how a narrow exception becomes a blanket one.
FROZEN_EXEC_REL="EXP-0005-system-efficiency/harness/restore-seed.sh"
FROZEN_EXEC_MODE="755"

unexpected_execs(){ # <experiments-root> — every executable EXCEPT the one exemption
  find "$1" -type f -perm -u+x 2>/dev/null | while IFS= read -r p; do
    [ "${p#$1/}" = "$FROZEN_EXEC_REL" ] || printf '%s\n' "$p"
  done
}

NEXEC="$(unexpected_execs "$SRC/build-os/experiments" | grep -c . || true)"
[ "${NEXEC:-1}" = "0" ] \
  && ok "0 unexpected executables under build-os/experiments/ (the census holds, one frozen exception aside)" \
  || no "$NEXEC unexpected executable file(s) under build-os/experiments/: $(unexpected_execs "$SRC/build-os/experiments" | tr '\n' ' ')"

# The exemption is pinned to a MODE as well as a path: if the frozen file's own
# mode ever changes, that is itself a change to a frozen artifact and must fail.
FROZEN_ABS="$SRC/build-os/experiments/$FROZEN_EXEC_REL"
[ -f "$FROZEN_ABS" ] \
  && ok "the exempted frozen artifact is present where the exemption says it is" \
  || no "the exemption names a path that does not exist: $FROZEN_EXEC_REL"
[ "$(stat -c '%a' "$FROZEN_ABS" 2>/dev/null)" = "$FROZEN_EXEC_MODE" ] \
  && ok "...at exactly mode $FROZEN_EXEC_MODE — a change to the frozen file's own mode would fail here" \
  || no "the frozen artifact's mode is $(stat -c '%a' "$FROZEN_ABS" 2>/dev/null), not the pinned $FROZEN_EXEC_MODE"

# THE REGRESSION. An exemption nobody can see failing is an exemption that has
# quietly become a blanket. Proven against a FIXTURE tree so the real
# repository is never written to.
CENSUS_FIX="$(mktemp -d)"
mkdir -p "$CENSUS_FIX/EXP-0005-system-efficiency/harness" "$CENSUS_FIX/EXP-0009-decoy/harness"
: > "$CENSUS_FIX/$FROZEN_EXEC_REL"; chmod 755 "$CENSUS_FIX/$FROZEN_EXEC_REL"
: > "$CENSUS_FIX/EXP-0009-decoy/harness/new-tool.sh"; chmod 755 "$CENSUS_FIX/EXP-0009-decoy/harness/new-tool.sh"
FOUND="$(unexpected_execs "$CENSUS_FIX" | grep -c . || true)"
[ "$FOUND" = "1" ] \
  && ok "REGRESSION: a NEW executable under build-os/experiments/ is still caught (the exemption did not become a blanket)" \
  || no "a new executable under build-os/experiments/ was not caught (found $FOUND)"
unexpected_execs "$CENSUS_FIX" | grep -q "EXP-0009-decoy" \
  && ok "...and the one reported is the decoy, not the exempted frozen artifact" \
  || no "the census reported the wrong file"
rm -rf "$CENSUS_FIX"

echo "== 2. Frozen prompts: the runner's own extraction re-derives the preregistered pins =="
for t in T3 T4 T5; do
  P="$(awk -v task="$t" '
    /^## / { insec = ($2 == task); fence = 0; next }
    insec && /^```/ { fence++; if (fence == 2) exit; next }
    insec && fence == 1 { print }
  ' "$TASKS_MD")"
  GOT="$(printf '%s' "$P" | sha256sum | cut -d' ' -f1)"
  case "$t" in T3) WANT="$PIN_SHA_T3" ;; T4) WANT="$PIN_SHA_T4" ;; T5) WANT="$PIN_SHA_T5" ;; esac
  [ "$GOT" = "$WANT" ] \
    && ok "$t extraction sha256 equals the pinned EXP-0002 value ($GOT)" \
    || no "$t extraction sha256 $GOT != pinned $WANT — the frozen prompt has drifted"
  grep -q "$WANT" "$PREREG" && ok "the $t pin is stated in PREREGISTRATION.md" || no "PREREGISTRATION.md does not carry the $t pin"
  grep -q "$WANT" "$RUNNER" && ok "the $t pin is enforced in run-exp3-task.sh (refusal on drift)" || no "run-exp3-task.sh does not carry the $t pin"
done

echo "== 3. setup-t1t2: byte-reproducible, oracle-proven, pinned total =="
bash "$SEEDER" "$WORK/tree-a" > "$WORK/seed-a.log" 2>&1 \
  && ok "seed A produced" || no "seed A failed: $(tail -1 "$WORK/seed-a.log")"
bash "$SEEDER" "$WORK/tree-b" > "$WORK/seed-b.log" 2>&1 \
  && ok "seed B produced" || no "seed B failed: $(tail -1 "$WORK/seed-b.log")"
bash "$SETUP" "$WORK/tree-a" > "$WORK/setup-a.log" 2>&1; RC=$?
[ "$RC" = "0" ] && ok "setup on seed A exits 0" || { no "setup on seed A exited $RC"; sed 's/^/      | /' "$WORK/setup-a.log"; }
grep -q 'ACCEPT T1' "$WORK/setup-a.log" \
  && ok "the frozen T1 oracle ACCEPTED the reference diagnosis (driven, not asserted)" \
  || no "no 'ACCEPT T1' in setup output"
grep -q 'ACCEPT T2' "$WORK/setup-a.log" \
  && ok "the frozen T2 oracle ACCEPTED the reference fix (differential executed)" \
  || no "no 'ACCEPT T2' in setup output"
grep -q 'transplanted tests fail pre-fix' "$WORK/setup-a.log" \
  && ok "the T2 differential proves the boundary test FAILS on the unfixed source" \
  || no "the T2 verdict does not show the pre-fix differential"
grep -q 'post_setup_suite: TOTAL: 23 passed, 0 failed' "$WORK/setup-a.log" \
  && ok "post-setup suite is green at EXACTLY the pinned total (23 passed, 0 failed)" \
  || no "post-setup suite is not at the pinned total"
bash "$SETUP" "$WORK/tree-b" > "$WORK/setup-b.log" 2>&1; RC=$?
[ "$RC" = "0" ] && ok "setup on seed B exits 0" || no "setup on seed B exited $RC"
DA="$(bash "$SEEDER" --digest "$WORK/tree-a")"
DB="$(bash "$SEEDER" --digest "$WORK/tree-b")"
[ "$DA" = "$DB" ] \
  && ok "two independent seed+setup runs produce IDENTICAL tree digests (byte-reproducible)" \
  || no "digests differ: $DA vs $DB"
[ "$DA" = "$PIN_SETUP_DIGEST" ] \
  && ok "the post-setup digest equals the preregistered pin ($PIN_SETUP_DIGEST)" \
  || no "post-setup digest $DA != preregistered $PIN_SETUP_DIGEST"
grep -q "$PIN_SETUP_DIGEST" "$PREREG" && ok "the post-setup digest pin is stated in PREREGISTRATION.md" || no "PREREGISTRATION.md does not carry the post-setup digest pin"
grep -q "$PIN_SETUP_DIGEST" "$RUNNER" && ok "the post-setup digest pin is enforced in run-exp3-task.sh" || no "run-exp3-task.sh does not carry the post-setup digest pin"

echo "== 4. setup-t1t2 refusals (red) =="
mkdir -p "$WORK/notatree"
bash "$SETUP" "$WORK/notatree" >/dev/null 2>&1; RC=$?
[ "$RC" = "2" ] && ok "a non-seeded directory is REFUSED (exit 2)" || no "non-seeded dir got exit $RC"
bash "$SETUP" "$WORK/tree-a" >/dev/null 2>&1; RC=$?
[ "$RC" = "2" ] && ok "re-running setup on an already-set-up tree is REFUSED (exit 2 — setup runs exactly once)" || no "re-run got exit $RC"
bash "$SETUP" >/dev/null 2>&1; RC=$?
[ "$RC" = "0" ] && ok "bare invocation prints usage (exit 0, help path)" || no "bare invocation got exit $RC"

echo "== 5. run-exp3-task refusals (red) — a refusal must not depend on the environment =="
bash "$RUNNER" --condition D --task T3 --workdir "$WORK/w" --outdir "$WORK/o" >/dev/null 2>&1; RC=$?
[ "$RC" = "2" ] && ok "an unknown condition is REFUSED (exit 2)" || no "unknown condition got exit $RC"
bash "$RUNNER" --condition A --task T1 --workdir "$WORK/w" --outdir "$WORK/o" > "$WORK/t1.err" 2>&1; RC=$?
[ "$RC" = "2" ] && ok "--task T1 is REFUSED (scripted setup, never a measured run)" || no "T1 got exit $RC"
grep -q 'scripted' "$WORK/t1.err" && ok "the T1 refusal names the scripted-setup reason" || no "the T1 refusal states no reason"
bash "$RUNNER" --condition A --task T2 --workdir "$WORK/w" --outdir "$WORK/o" >/dev/null 2>&1; RC=$?
[ "$RC" = "2" ] && ok "--task T2 is REFUSED for the same reason" || no "T2 got exit $RC"
bash "$RUNNER" --condition A --task T6 --workdir "$WORK/w" --outdir "$WORK/o" >/dev/null 2>&1; RC=$?
[ "$RC" = "2" ] && ok "an unknown task is REFUSED" || no "unknown task got exit $RC"
bash "$RUNNER" --condition A --task T3 --outdir "$WORK/o" >/dev/null 2>&1; RC=$?
[ "$RC" = "2" ] && ok "a missing --workdir is REFUSED" || no "missing workdir got exit $RC"
bash "$RUNNER" --condition B --task T4 --workdir "$WORK/fresh-b" --outdir "$WORK/o" > "$WORK/t4.err" 2>&1; RC=$?
[ "$RC" = "2" ] && ok "a non-T3 task on a missing work tree is REFUSED (the sequence starts at T3)" || no "T4-without-tree got exit $RC"
grep -q 'starts at T3' "$WORK/t4.err" && ok "the precondition refusal names the sequence rule" || no "the precondition refusal states no rule"
bash "$RUNNER" --close --condition A --workdir "$WORK/w" --runsdir "$WORK/r" --outdir "$WORK/o" > "$WORK/ca.err" 2>&1; RC=$?
[ "$RC" = "2" ] && ok "close over condition A is REFUSED by name (A has no receipt)" || no "close-A got exit $RC"
grep -q 'disclosed' "$WORK/ca.err" && ok "the close-A refusal states the absence is a DISCLOSED property, not an omission" || no "the close-A refusal does not disclose"
mkdir -p "$WORK/wd-norec/repo"
bash "$RUNNER" --close --condition B --workdir "$WORK/wd-norec" --runsdir "$WORK/r" --outdir "$WORK/o" >/dev/null 2>&1; RC=$?
[ "$RC" = "2" ] && ok "close over a work tree with NO receipt is REFUSED" || no "close-no-receipt got exit $RC"

echo "== 6. The mechanical close loop — receipts from the REAL issuer, gated by the REAL gate =="
DESC_COMMON='"expected_files_changed":4,"requires_tests":true,"expected_session_count":3,"prior_context_required":true,"handoff_required":false,"consequence_level":"medium","irreversible_or_external_mutation":false,"high_blast_radius":false,"unclear_acceptance_criteria":false,"security_or_compliance_consequence":false,"parallel_workstreams_benefit":false,"nondeterministic_verification":false'
OUTB="$(node "$SRC/build-os/tools/mode-select.mjs" "{$DESC_COMMON,\"high_rework_history\":false}" 2>/dev/null)"
[ "$OUTB" = "gravito_light" ] \
  && ok "condition B's preregistered descriptor still selects gravito_light (the condition is instantiable)" \
  || no "condition B descriptor now selects \"$OUTB\" — the preregistered condition cannot be instantiated"
OUTC="$(node "$SRC/build-os/tools/mode-select.mjs" "{$DESC_COMMON,\"high_rework_history\":true}" 2>/dev/null)"
[ "$OUTC" = "gravito_full" ] \
  && ok "condition C's preregistered descriptor still selects gravito_full (one boolean apart)" \
  || no "condition C descriptor now selects \"$OUTC\""
mkrecs(){ # <dir> <total> <uncached> <cost> <turns> <wall> <dispatches>
  local d="$1" t
  for t in T3 T4 T5; do
    mkdir -p "$d/$t"
    { echo "mu_total_tokens: $2"; echo "mu_uncached_tokens: $3"; echo "mu_cost_usd: $4"
      echo "num_turns: $5"; echo "wall_clock_s: $6"; echo "subagent_dispatches_structural: $7"
    } > "$d/$t/run_record.txt"
  done
}
mkwd(){ # <wd> — place a REAL light receipt at the runner's fixed path
  mkdir -p "$1/repo/build-os/packets/routing"
  local rt="$WORK/rt-$RANDOM"
  bash "$ROUTE" --task-id EXP-0003-sequence --description "suite fixture" \
    --descriptor "{$DESC_COMMON,\"high_rework_history\":false}" --out "$rt" >/dev/null 2>&1 || return 1
  cp "$rt"/routing-EXP-0003-sequence-*.md "$1/repo/build-os/packets/routing/routing-EXP-0003-sequence.md"
}
# --- 6a. under-budget: an honest light sequence PASSES the gate -------------
mkwd "$WORK/wd1" && ok "a real gravito_light receipt was issued and placed at the fixed path" || no "receipt issuance failed"
mkrecs "$WORK/runs1" 100000 15000 0.100000 6 120.50 0
bash "$RUNNER" --close --condition B --workdir "$WORK/wd1" --runsdir "$WORK/runs1" --outdir "$WORK/close1" > "$WORK/close1.log" 2>&1; RC=$?
[ "$RC" = "0" ] && ok "close mode completes (exit 0) on three sealed records" || { no "close exited $RC"; sed 's/^/      | /' "$WORK/close1.log"; }
REC1="$WORK/wd1/repo/build-os/packets/routing/routing-EXP-0003-sequence.md"
grep -q '^consumed_total_tokens: 300000$' "$REC1" \
  && ok "consumed_total_tokens = 300000 (summed from the three records, machine-derived)" \
  || no "consumed_total_tokens not summed correctly"
grep -q '^consumed_wall_clock_s: 361.50$' "$REC1" \
  && ok "consumed_wall_clock_s = 361.50 (decimal sum)" || no "wall clock sum wrong"
grep -q '^executed_mode: gravito_light$' "$REC1" \
  && ok "executed_mode = selected mode when 0 subagents were dispatched (disclosed proxy)" \
  || no "executed_mode proxy wrong for 0 dispatches"
[ -f "$WORK/close1/gate_result.txt" ] && ok "gate_result.txt written" || no "no gate_result.txt"
grep -q '^gate_exit: 0$' "$WORK/close1/gate_result.txt" \
  && ok "the REAL routing-check.sh PASSED the under-budget receipt (gate_exit: 0)" \
  || no "under-budget receipt did not pass the gate"
[ -f "$WORK/close1/receipt-final.md" ] && ok "the filled receipt is copied beside its gate result" || no "no receipt-final.md"
bash "$RUNNER" --close --condition B --workdir "$WORK/wd1" --runsdir "$WORK/runs1" --outdir "$WORK/close1b" >/dev/null 2>&1; RC=$?
[ "$RC" = "2" ] && ok "a SECOND fill of the same receipt is REFUSED (a receipt is filled once)" || no "re-fill got exit $RC"
# --- 6b. fabricated over-budget + dispatches: the gate REFUSES, data retained
mkwd "$WORK/wd2" || no "second fixture receipt issuance failed"
mkrecs "$WORK/runs2" 2500000 90000 1.800000 40 900.00 2
bash "$RUNNER" --close --condition B --workdir "$WORK/wd2" --runsdir "$WORK/runs2" --outdir "$WORK/close2" > "$WORK/close2.log" 2>&1; RC=$?
[ "$RC" = "0" ] && ok "close mode still completes — the gate's refusal is DATA, not a harness failure" || no "over-budget close exited $RC"
G2="$WORK/close2/gate_result.txt"
grep -q '^gate_exit: 2$' "$G2" \
  && ok "RED: the fabricated over-budget consumption is REFUSED by routing-check.sh (gate_exit: 2)" \
  || no "RED FAILED: the over-budget receipt passed the gate"
grep -q 'SILENT-ESCALATION' "$G2" \
  && ok "RED: >=1 dispatch under a light receipt fills executed_mode gravito_full and the gate names SILENT-ESCALATION" \
  || no "SILENT-ESCALATION not named"
grep -q 'BUDGET-BREACH' "$G2" \
  && ok "RED: the breach without a degradation note is named BUDGET-BREACH, verbatim" \
  || no "BUDGET-BREACH not named"
grep -q 'REFUSED — retained as data' "$G2" \
  && ok "the disposition labels the refusal as retained data, not edited to pass" \
  || no "no retained-as-data disposition"
grep -q '^consumed_total_tokens: 7500000$' "$WORK/close2/receipt-final.md" \
  && ok "the refused receipt RETAINS its over-budget number (nothing was edited to pass)" \
  || no "the refused receipt's consumption was altered"
# --- 6c. an unknown is not a zero: a non-numeric field stays '-' ------------
mkwd "$WORK/wd3" || no "third fixture receipt issuance failed"
mkrecs "$WORK/runs3" 100000 15000 0.100000 6 120.50 0
sed -i 's/^subagent_dispatches_structural: 0$/subagent_dispatches_structural: -/' "$WORK/runs3/T4/run_record.txt"
bash "$RUNNER" --close --condition B --workdir "$WORK/wd3" --runsdir "$WORK/runs3" --outdir "$WORK/close3" >/dev/null 2>&1; RC=$?
[ "$RC" = "0" ] && ok "close mode completes with one unmeasured dispatch count" || no "close3 exited $RC"
REC3="$WORK/wd3/repo/build-os/packets/routing/routing-EXP-0003-sequence.md"
grep -q '^consumed_subagents: -$' "$REC3" \
  && ok "consumed_subagents stays '-' when any record's count is unmeasured (an unknown is not a zero)" \
  || no "an unmeasured dispatch count was summed as if zero"
grep -q '^executed_mode: -$' "$REC3" \
  && ok "executed_mode stays '-' when the dispatch proxy has no measurement" \
  || no "executed_mode was guessed without a measurement"
grep -q '^gate_exit: 0$' "$WORK/close3/gate_result.txt" \
  && ok "the gate treats '-' as an admission and passes it (refusal is for contradiction, not absence)" \
  || no "an honest admission was refused"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
