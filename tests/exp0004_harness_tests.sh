#!/usr/bin/env bash
# Build OS — EXP-0004 matched-arm harness: the arm-invariance assertions, the
# deterministic ordering rule, the clean-reset refusal, the prior-pilot
# exclusion gate, Amendment 2 confound exclusion, tier-labeled measurement,
# and the MECHANICAL verdict with its binding acceptance veto.
#
# WHAT THIS SUITE PROVES, by execution:
#   1. Every identical-across-arms field is an ASSERTION: each of the eight is
#      mismatched in turn, and each refusal NAMES the field that differs.
#   2. Arm ordering is derived from a registered rule (no RNG, no wall-clock),
#      is byte-reproducible across two registrations, and is RECORDED.
#   3. An arm never starts on a moving tree: a dirty work tree or a HEAD that
#      is not the pinned seed is refused, and the between-arms reset restores
#      the seed.
#   4. All TEN prior-pilot frozen tasks (PILOT-0001 T1-T5, PILOT-0002 T1-T5)
#      are refused AT REGISTRATION, by name — not silently skipped later.
#   5. An Amendment-2-confounded arm B is recorded result_confounded and drops
#      out of the aggregate's n; the ledger makes that exclusion permanent.
#   6. Measurement records carry tier labels from the adapter contract's
#      vocabulary and admit unknowns as '-'. An unknown is never a zero.
#   7. All seven verdict labels are reachable from constructed aggregates, the
#      acceptance-quality veto blocks a token-win aggregate whose acceptance
#      dropped (the load-bearing test), and threshold overrides are REFUSED.
#
# No network. No model invocation. Deterministic. Every fixture lives in a
# mktemp dir; nothing under build-os/ is written by this suite.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
H="$SRC/build-os/experiments/EXP-0004-context-compiler/harness"
RUNNER="$H/run-exp0004.mjs"
MEASURE="$H/measure.mjs"
VERDICT="$H/verdict.mjs"
PREREG="$SRC/build-os/compiler/AB_PREREGISTRATION.md"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# ---------------------------------------------------------------- fixtures --
mkrepo(){ # $1 dir -> a one-commit git repo; prints nothing
  mkdir -p "$1"
  git -C "$1" init -q
  git -C "$1" config user.email "harness@example.invalid"
  git -C "$1" config user.name  "exp0004 harness"
  printf 'seed\n' > "$1/seed.txt"
  git -C "$1" add -A >/dev/null 2>&1
  git -C "$1" commit -qm seed >/dev/null 2>&1
}

mkelig(){ # $1 out  $2 no_parser_share_pct (default 12.0)
  printf '{ "no_parser_share_pct": %s, "files_admitted_as_candidates": 415, "measured_by": "build-index.mjs stats", "recorded_before_arm_a": true }\n' \
    "${2:-12.0}" > "$1"
}

mktasks(){ # $1 out  $2 seed  $3 id  $4 title  $5 description
  cat > "$1" <<EOF
{
  "pinned_seed_commit": "$2",
  "model_id": "claude-fable-5",
  "max_retries": 1,
  "authority_mode_policy": "gravito_light; no push; no merge",
  "baseline_measurement": "check:app error count at the pinned seed",
  "measurement_boundaries": "session open to acceptance verdict",
  "tasks": [
    { "id": "$3", "title": "$4", "description": "$5", "acceptance_criteria": ["named acceptance clause"], "shape": "simple isolated" }
  ]
}
EOF
}

mkpair(){ # $1 out  $2 task_id  $3 seed  $4 task_definition_sha
  cat > "$1" <<EOF
{
  "task_id": "$2",
  "arm_a": {
    "repository_seed_commit": "$3",
    "task_definition": "$4",
    "model_id": "claude-fable-5",
    "acceptance_criteria": ["named acceptance clause"],
    "max_retries": 1,
    "authority_mode_policy": "gravito_light; no push; no merge",
    "baseline_measurement": "check:app error count at the pinned seed",
    "measurement_boundaries": "session open to acceptance verdict"
  },
  "arm_b": {
    "repository_seed_commit": "$3",
    "task_definition": "$4",
    "model_id": "claude-fable-5",
    "acceptance_criteria": ["named acceptance clause"],
    "max_retries": 1,
    "authority_mode_policy": "gravito_light; no push; no merge",
    "baseline_measurement": "check:app error count at the pinned seed",
    "measurement_boundaries": "session open to acceptance verdict"
  }
}
EOF
}

mkrecA(){ # $1 out  $2 task  $3 uncached  $4 elapsed  $5 acceptance
  cat > "$1" <<EOF
{
  "experiment": "EXP-0004",
  "task_id": "$2",
  "arm": "A",
  "fields": {
    "starting_context_bytes": { "value": 240000, "tier": "EXACT" },
    "expansion_bytes": { "value": 0, "tier": "EXACT" },
    "total_tokens": { "value": $3, "tier": "CLOSE-TIME" },
    "uncached_tokens": { "value": $3, "tier": "CLOSE-TIME" },
    "time_to_first_meaningful_edit_s": { "value": 41, "tier": "EXACT" },
    "total_elapsed_s": { "value": $4, "tier": "EXACT" },
    "files_read": { "value": 12, "tier": "EXACT" },
    "search_operations": { "value": 6, "tier": "EXACT" },
    "context_expansions": { "value": 0, "tier": "EXACT" },
    "failed_hypotheses": { "value": 1, "tier": "EXACT" },
    "rework_rounds": { "value": 0, "tier": "EXACT" },
    "verifier_dispatches": { "value": 1, "tier": "EXACT" },
    "tests_run": { "value": 10, "tier": "EXACT" },
    "tests_passed": { "value": 10, "tier": "EXACT" },
    "acceptance_result": { "value": "$5", "tier": "EXACT" },
    "regressions": { "value": 0, "tier": "EXACT" },
    "human_interventions": { "value": 0, "tier": "EXACT" }
  }
}
EOF
}

mkrecB(){ # $1 out  $2 task  $3 uncached  $4 elapsed  $5 acceptance
          # $6 starting_context_bytes  $7 capsule_bytes  $8 prefix_bytes  $9 broad_context_included
  cat > "$1" <<EOF
{
  "experiment": "EXP-0004",
  "task_id": "$2",
  "arm": "B",
  "fields": {
    "starting_context_bytes": { "value": ${6:-8622}, "tier": "EXACT" },
    "expansion_bytes": { "value": 1200, "tier": "EXACT" },
    "total_tokens": { "value": $3, "tier": "CLOSE-TIME" },
    "uncached_tokens": { "value": $3, "tier": "CLOSE-TIME" },
    "time_to_first_meaningful_edit_s": { "value": 18, "tier": "EXACT" },
    "total_elapsed_s": { "value": $4, "tier": "EXACT" },
    "files_read": { "value": 4, "tier": "EXACT" },
    "search_operations": { "value": 2, "tier": "EXACT" },
    "context_expansions": { "value": 2, "tier": "EXACT" },
    "failed_hypotheses": { "value": 0, "tier": "EXACT" },
    "rework_rounds": { "value": 0, "tier": "EXACT" },
    "verifier_dispatches": { "value": 1, "tier": "EXACT" },
    "tests_run": { "value": 10, "tier": "EXACT" },
    "tests_passed": { "value": 10, "tier": "EXACT" },
    "acceptance_result": { "value": "$5", "tier": "EXACT" },
    "regressions": { "value": 0, "tier": "EXACT" },
    "human_interventions": { "value": 0, "tier": "EXACT" }
  },
  "arm_b_starting_context": {
    "capsule_bytes": { "value": ${7:-6622}, "tier": "EXACT" },
    "prefix_bytes": { "value": ${8:-2000}, "tier": "EXACT" },
    "broad_context_included": ${9:-false}
  }
}
EOF
}

mkagg(){ # $1 out $2 uA $3 uB $4 tA $5 tB $6 accA-csv $7 accB-csv [$8 no_parser] [$9 confound-json]
  local out="$1" uA="$2" uB="$3" tA="$4" tB="$5" np="${8:-12.0}" conf="${9:-}"
  local -a AA BB
  IFS=',' read -r -a AA <<< "$6"
  IFS=',' read -r -a BB <<< "$7"
  local body="" i
  for i in 0 1 2; do
    [ -n "$body" ] && body="$body,"
    body="$body{\"task_id\":\"E4-T$((i+1))\",\"a\":{\"uncached_tokens\":$uA,\"total_tokens\":$uA,\"total_elapsed_s\":$tA,\"human_interventions\":0,\"acceptance_result\":\"${AA[$i]}\"},\"b\":{\"uncached_tokens\":$uB,\"total_tokens\":$uB,\"total_elapsed_s\":$tB,\"human_interventions\":0,\"acceptance_result\":\"${BB[$i]}\"}}"
  done
  cat > "$out" <<EOF
{
  "experiment": "EXP-0004",
  "arm_order_rule": { "id": "task-index-parity-v1" },
  "eligibility": { "no_parser_share_pct": $np, "recorded_before_arm_a": true },
  "harness_confounds": [$conf],
  "n_registered": 3,
  "n_admitted": 3,
  "n_excluded_confounded": 0,
  "excluded": [],
  "tasks": [$body]
}
EOF
}

mkrepo "$WORK/repo"
SEED="$(git -C "$WORK/repo" rev-parse HEAD)"
mkelig "$WORK/elig.json"

echo "== 1. Layout: three tools exist and are NON-executable (the census must not move) =="
for f in "$RUNNER" "$MEASURE" "$VERDICT"; do
  [ -f "$f" ] && ok "$(basename "$f") exists" || no "$(basename "$f") missing"
  [ ! -x "$f" ] && ok "$(basename "$f") is NOT executable (invoked via node, by design)" || no "$(basename "$f") is executable"
done
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
if grep -nE 'Math\.random|Date\.now|new Date\(|process\.hrtime' "$H"/*.mjs >/dev/null 2>&1; then
  no "a harness tool reaches for RNG or a wall-clock — ordering must be derived, not sampled"
else
  ok "no RNG and no wall-clock anywhere in the harness tools (ordering is derived)"
fi
for d in EXP-0001-token-efficiency EXP-0002-sustained-workload EXP-0003-routing-frontier; do
  [ -d "$SRC/build-os/experiments/$d" ] && ok "$d is present and untouched (frozen prior experiment)" || no "$d is missing"
done

echo "== 2. Registration: the frozen fields, the eligibility precondition (AMENDMENT 1) =="
mktasks "$WORK/tasks-ok.json" "$SEED" "E4-T1" "capsule renderer byte drift" "a bounded numeric drift in the capsule byte renderer, isolated to one module"
node "$RUNNER" register --tasks "$WORK/tasks-ok.json" --eligibility "$WORK/elig.json" --out "$WORK/reg.json" >"$WORK/reg.log" 2>&1; RC=$?
[ "$RC" = "0" ] && ok "a clean task set registers (exit 0)" || { no "registration exited $RC"; sed 's/^/      | /' "$WORK/reg.log"; }
[ -f "$WORK/reg.json" ] && ok "registry.json is written" || no "no registry.json"
grep -q '"no_parser_share_pct": 12' "$WORK/reg.json" \
  && ok "the eligibility measurement is RECORDED in the registry before any arm runs (AMENDMENT 1)" \
  || no "the registry does not record the eligibility measurement"
mkelig "$WORK/elig-bad.json" 94.0
node "$RUNNER" register --tasks "$WORK/tasks-ok.json" --eligibility "$WORK/elig-bad.json" --out "$WORK/reg-bad.json" >"$WORK/regbad.log" 2>&1; RC=$?
[ "$RC" = "2" ] && ok "a repository over the preregistered no_parser ceiling is REFUSED (exit 2)" || no "bad eligibility exited $RC"
grep -qi 'no_parser' "$WORK/regbad.log" && ok "the eligibility refusal NAMES no_parser and its 50% ceiling" || no "the eligibility refusal does not name no_parser"
grep -qi 'AMENDMENT 1' "$WORK/regbad.log" && ok "the eligibility refusal cites AMENDMENT 1" || no "the eligibility refusal does not cite AMENDMENT 1"
node "$RUNNER" register --tasks "$WORK/tasks-ok.json" --out "$WORK/reg-noelig.json" >"$WORK/regnoelig.log" 2>&1; RC=$?
[ "$RC" = "2" ] && ok "registration WITHOUT eligibility evidence is refused (the precondition is not optional)" || no "missing eligibility exited $RC"
sed 's/"model_id": "claude-fable-5",//' "$WORK/tasks-ok.json" > "$WORK/tasks-nomodel.json"
node "$RUNNER" register --tasks "$WORK/tasks-nomodel.json" --eligibility "$WORK/elig.json" --out "$WORK/x.json" >"$WORK/nomodel.log" 2>&1; RC=$?
[ "$RC" = "2" ] && ok "a task set missing a frozen field is refused" || no "missing model_id exited $RC"
grep -q 'model_id' "$WORK/nomodel.log" && ok "the missing frozen field is NAMED (model_id)" || no "the refusal does not name model_id"

echo "== 3. Prior-pilot exclusion: all TEN frozen tasks refused AT REGISTRATION, by name =="
excl(){ # $1 expected pilot id  $2 candidate id  $3 title  $4 description
  mktasks "$WORK/tasks-x.json" "$SEED" "$2" "$3" "$4"
  node "$RUNNER" register --tasks "$WORK/tasks-x.json" --eligibility "$WORK/elig.json" --out "$WORK/reg-x.json" >"$WORK/excl.log" 2>&1
  local rc=$?
  if [ "$rc" != "2" ]; then no "$1 was NOT refused at registration (exit $rc) — a frozen pilot task leaked in"; return; fi
  grep -q "$1" "$WORK/excl.log" \
    && ok "$1 is refused at registration and NAMED in the refusal" \
    || { no "$1 refused but not named: $(head -1 "$WORK/excl.log")"; }
  [ -f "$WORK/reg-x.json" ] && no "$1 refusal still wrote a registry" || ok "$1 refusal wrote NO registry (refused, not skipped)"
}
excl PILOT-0001-T1 E4-X1 "Diagnose the red baseline" "classify every check:app type error by subsystem and root cause, no implementation"
excl PILOT-0001-T2 E4-X2 "notification test determinism" "remove the vacuous shadow test and make the autonomy rate in notification content test deterministic"
excl PILOT-0001-T3 E4-X3 "operator-event kind" "implement the dedicated four_eyes_state_change operator-event kind end to end"
excl PILOT-0001-T4 E4-X4 "failing dry-run test" "fix the failing executeFixLayer dry-run test without weakening the assertion"
excl PILOT-0001-T5 E4-X5 "checkout drift" "fix the stripe error cluster: the checkout API-version pin and the webhook subscription property drift"
excl PILOT-0002-T1 E4-X6 "client namespace drift" "fix the six Property bridge does not exist errors in the trpc client namespace"
excl PILOT-0002-T2 E4-X7 "report type drift" "fix the six Property coverage does not exist on type CoverageReportData errors"
excl PILOT-0002-T3 E4-X8 "structure test defect" "make the three agents structure tests hermetic by mocking the LLM boundary"
excl PILOT-0002-T4 E4-X9 "interface conflict" "IAutoRetrainingPipeline incorrectly extends AutoRetrainingPipeline: private config and Promise-shape mismatch"
excl PILOT-0002-T5 E4-X10 "gateway narrowing" "fix the voice-stream-gateway LogDomain error and the webhooks router unknown-narrowing pair"
node "$RUNNER" exclusions >"$WORK/exclist.log" 2>&1; RC=$?
[ "$RC" = "0" ] && ok "the exclusion list is printable (auditable, not buried)" || no "exclusions subcommand exited $RC"
NEX="$(grep -c 'PILOT-000' "$WORK/exclist.log" || true)"
[ "$NEX" = "10" ] && ok "the exclusion list carries EXACTLY the 10 prior-pilot frozen tasks" || no "the exclusion list names $NEX prior-pilot tasks, expected 10"

echo "== 4. Deterministic arm ordering: derived from a registered rule, reproducible, RECORDED =="
grep -q 'task-index-parity-v1' "$WORK/reg.json" \
  && ok "the arm-ordering rule id is RECORDED in the run record (auditable)" \
  || no "the registry does not record the ordering rule id"
node "$RUNNER" register --tasks "$WORK/tasks-ok.json" --eligibility "$WORK/elig.json" --out "$WORK/reg2.json" >/dev/null 2>&1
S1="$(sha256sum "$WORK/reg.json" | cut -d' ' -f1)"
S2="$(sha256sum "$WORK/reg2.json" | cut -d' ' -f1)"
[ "$S1" = "$S2" ] && ok "two independent registrations are BYTE-IDENTICAL (no RNG, no clock)" || no "registrations differ: $S1 vs $S2"
cat > "$WORK/tasks3.json" <<EOF
{
  "pinned_seed_commit": "$SEED",
  "model_id": "claude-fable-5",
  "max_retries": 1,
  "authority_mode_policy": "gravito_light; no push; no merge",
  "baseline_measurement": "check:app error count at the pinned seed",
  "measurement_boundaries": "session open to acceptance verdict",
  "tasks": [
    { "id": "E4-T1", "title": "capsule renderer byte drift", "description": "a bounded numeric drift in one module", "acceptance_criteria": ["named acceptance clause"], "shape": "simple isolated" },
    { "id": "E4-T2", "title": "expansion ledger wiring", "description": "an ordinary multi-file change across the expansion ledger and its caller", "acceptance_criteria": ["named acceptance clause"], "shape": "ordinary multi-file" },
    { "id": "E4-T3", "title": "unfamiliar subsystem repair", "description": "a complex unfamiliar repair in a subsystem with no covering test", "acceptance_criteria": ["named acceptance clause"], "shape": "complex unfamiliar" }
  ]
}
EOF
node "$RUNNER" register --tasks "$WORK/tasks3.json" --eligibility "$WORK/elig.json" --out "$WORK/reg3.json" >/dev/null 2>&1
node "$RUNNER" plan --registry "$WORK/reg3.json" > "$WORK/plan.txt" 2>&1; RC=$?
[ "$RC" = "0" ] && ok "plan prints the counterbalanced order" || no "plan exited $RC"
grep -q 'E4-T1: A,B' "$WORK/plan.txt" && ok "task index 0 (even) runs A then B — the parity rule" || no "index-0 order is not A,B"
grep -q 'E4-T2: B,A' "$WORK/plan.txt" && ok "task index 1 (odd) runs B then A — counterbalanced, not sampled" || no "index-1 order is not B,A"
grep -q 'E4-T3: A,B' "$WORK/plan.txt" && ok "task index 2 (even) runs A then B" || no "index-2 order is not A,B"
grep -q 'arm_order_rule: task-index-parity-v1' "$WORK/plan.txt" && ok "the plan states the rule that produced the order" || no "the plan does not state the ordering rule"

echo "== 5. Identical-across-arms: EIGHT assertions, each refusal NAMES the field =="
TDSHA="$(grep -o '"task_definition_sha256": "[a-f0-9]*"' "$WORK/reg.json" | head -1 | cut -d'"' -f4)"
[ -n "$TDSHA" ] && ok "the registry pins a task_definition sha256" || no "no task_definition_sha256 in the registry"
mkpair "$WORK/pair-ok.json" "E4-T1" "$SEED" "$TDSHA"
node "$RUNNER" assert-matched --registry "$WORK/reg.json" --pair "$WORK/pair-ok.json" >"$WORK/am.log" 2>&1; RC=$?
[ "$RC" = "0" ] && ok "a genuinely matched pair passes the invariance assertion" || { no "matched pair exited $RC"; sed 's/^/      | /' "$WORK/am.log"; }
mismatch(){ # $1 field  $2 the JSON value arm_b gets instead
  mkpair "$WORK/pair-m.json" "E4-T1" "$SEED" "$TDSHA"
  node -e '
    const fs=require("fs");const [f,field,val]=process.argv.slice(1);
    const j=JSON.parse(fs.readFileSync(f,"utf8"));
    j.arm_b[field]=JSON.parse(val);
    fs.writeFileSync(f,JSON.stringify(j,null,2));
  ' "$WORK/pair-m.json" "$1" "$2"
  node "$RUNNER" assert-matched --registry "$WORK/reg.json" --pair "$WORK/pair-m.json" >"$WORK/mm.log" 2>&1
  local rc=$?
  if [ "$rc" != "2" ]; then no "a differing $1 was NOT refused (exit $rc) — the invariant is a convention, not an assertion"; return; fi
  grep -q "$1" "$WORK/mm.log" \
    && ok "a differing $1 is REFUSED (exit 2) and the field is NAMED" \
    || no "$1 mismatch refused but the field is not named: $(head -1 "$WORK/mm.log")"
}
mismatch repository_seed_commit '"0000000000000000000000000000000000000000"'
mismatch task_definition        '"deadbeef"'
mismatch model_id               '"some-other-model"'
mismatch acceptance_criteria    '["a different clause"]'
mismatch max_retries            '3'
mismatch authority_mode_policy  '"gravito_full; push allowed"'
mismatch baseline_measurement   '"a different baseline"'
mismatch measurement_boundaries '"session open to session close"'
node -e '
  const fs=require("fs");const f=process.argv[1];
  const j=JSON.parse(fs.readFileSync(f,"utf8")); delete j.arm_b.model_id;
  fs.writeFileSync(f,JSON.stringify(j,null,2));
' "$WORK/pair-ok.json"
node "$RUNNER" assert-matched --registry "$WORK/reg.json" --pair "$WORK/pair-ok.json" >"$WORK/absent.log" 2>&1; RC=$?
[ "$RC" = "2" ] && ok "an ABSENT invariant field is refused (asserted, never assumed)" || no "absent model_id exited $RC"
grep -q 'model_id' "$WORK/absent.log" && ok "the absent-field refusal names the field" || no "the absent-field refusal does not name it"
mkpair "$WORK/pair-unreg.json" "E4-NOT-REGISTERED" "$SEED" "$TDSHA"
node "$RUNNER" assert-matched --registry "$WORK/reg.json" --pair "$WORK/pair-unreg.json" >"$WORK/unreg.log" 2>&1; RC=$?
[ "$RC" = "2" ] && ok "a pair for an UNREGISTERED task is refused (registration cannot be bypassed)" || no "unregistered pair exited $RC"

echo "== 6. Clean reset between arms: no arm starts on a moving tree =="
mkpair "$WORK/pair-run.json" "E4-T1" "$SEED" "$TDSHA"
node "$RUNNER" run-pair --registry "$WORK/reg.json" --pair "$WORK/pair-run.json" --repo "$WORK/repo" --out "$WORK/pair1" >"$WORK/rp1.log" 2>&1; RC=$?
[ "$RC" = "0" ] && ok "a clean tree at the pinned seed runs the pair (exit 0)" || { no "clean run-pair exited $RC"; sed 's/^/      | /' "$WORK/rp1.log"; }
grep -q 'arm_order: A,B' "$WORK/pair1/pair_record.txt" && ok "the pair record RECORDS the executed arm order" || no "no arm_order in the pair record"
grep -q 'arm_order_rule: task-index-parity-v1' "$WORK/pair1/pair_record.txt" && ok "the pair record RECORDS the rule that fixed the order (auditable)" || no "no arm_order_rule in the pair record"
grep -q 'invariance_assertion: PASS' "$WORK/pair1/pair_record.txt" && ok "the pair record records the invariance assertion result" || no "no invariance_assertion in the pair record"
printf 'uncommitted\n' > "$WORK/repo/dirty.txt"
node "$RUNNER" arm-start --repo "$WORK/repo" --seed "$SEED" --arm A --task E4-T1 >"$WORK/dirty.log" 2>&1; RC=$?
[ "$RC" = "2" ] && ok "a DIRTY work tree is refused at arm start (exit 2)" || no "dirty tree exited $RC"
grep -qi 'dirty' "$WORK/dirty.log" && ok "the dirty-tree refusal says so, and lists the offending path" || no "the dirty refusal does not name the condition"
grep -q 'dirty.txt' "$WORK/dirty.log" && ok "the refusal names the actual untracked path" || no "the refusal does not name the path"
node "$RUNNER" run-pair --registry "$WORK/reg.json" --pair "$WORK/pair-run.json" --repo "$WORK/repo" --out "$WORK/pair2" >"$WORK/rp2.log" 2>&1; RC=$?
[ "$RC" = "2" ] && ok "run-pair refuses to open a pair on a dirty tree" || no "dirty run-pair exited $RC"
rm -f "$WORK/repo/dirty.txt"
node "$RUNNER" arm-start --repo "$WORK/repo" --seed 0000000000000000000000000000000000000000 --arm A --task E4-T1 >"$WORK/head.log" 2>&1; RC=$?
[ "$RC" = "2" ] && ok "a HEAD that is not the pinned seed is refused" || no "wrong-HEAD exited $RC"
grep -qi 'seed' "$WORK/head.log" && ok "the wrong-HEAD refusal names the pinned seed it expected" || no "the wrong-HEAD refusal does not name the seed"
node "$RUNNER" arm-start --repo "$WORK/repo" --seed "$SEED" --arm A --task E4-T1 >"$WORK/clean.log" 2>&1; RC=$?
[ "$RC" = "0" ] && ok "a clean tree at the pinned seed passes arm start" || no "clean arm-start exited $RC"
node "$RUNNER" run-pair --registry "$WORK/reg.json" --pair "$WORK/pair-run.json" --repo "$WORK/repo" --out "$WORK/pair3" \
  --exec-cmd 'printf worker > "$EXP0004_REPO/worker-$EXP0004_ARM.txt"' >"$WORK/rp3.log" 2>&1; RC=$?
[ "$RC" = "2" ] && ok "arm B refuses to start on the tree arm A dirtied (no reset requested)" || no "unreset second arm exited $RC"
grep -qi 'dirty' "$WORK/rp3.log" && ok "the between-arms refusal is the dirty-tree refusal, at arm B's start" || no "the between-arms refusal is not the dirty-tree one"
git -C "$WORK/repo" reset -q --hard "$SEED"; git -C "$WORK/repo" clean -qfdx
node "$RUNNER" run-pair --registry "$WORK/reg.json" --pair "$WORK/pair-run.json" --repo "$WORK/repo" --out "$WORK/pair4" \
  --reset-between-arms --exec-cmd 'printf worker > "$EXP0004_REPO/worker-$EXP0004_ARM.txt"' >"$WORK/rp4.log" 2>&1; RC=$?
[ "$RC" = "0" ] && ok "with the reset requested, both arms run from the pinned seed" || { no "reset run-pair exited $RC"; sed 's/^/      | /' "$WORK/rp4.log"; }
grep -q 'reset_between_arms: performed' "$WORK/pair4/pair_record.txt" && ok "the reset is RECORDED, not assumed" || no "the reset is not recorded"
grep -q 'arm_a_exec_exit: 0' "$WORK/pair4/pair_record.txt" && ok "arm A's worker exit is recorded" || no "arm A exec exit not recorded"
grep -q 'arm_b_exec_exit: 0' "$WORK/pair4/pair_record.txt" && ok "arm B's worker exit is recorded" || no "arm B exec exit not recorded"
[ -z "$(git -C "$WORK/repo" status --porcelain)" ] && [ "$(git -C "$WORK/repo" rev-parse HEAD)" = "$SEED" ] \
  && ok "after the pair the tree is back at the pinned seed, clean" || no "the tree did not return to the pinned seed"

echo "== 7. Measurement records: the tier vocabulary, and an unknown is NEVER a zero =="
node "$MEASURE" template --task E4-T1 --arm A --out "$WORK/tmplA.json" >/dev/null 2>&1; RC=$?
[ "$RC" = "0" ] && ok "measure.mjs emits a template record" || no "template exited $RC"
node "$MEASURE" validate --record "$WORK/tmplA.json" >"$WORK/v0.log" 2>&1; RC=$?
[ "$RC" = "0" ] && ok "the all-unknown template VALIDATES (admissions are legal; guesses are not)" || { no "template failed validation"; sed 's/^/      | /' "$WORK/v0.log"; }
NDASH="$(grep -c '"value": "-", "tier": "UNAVAILABLE"' "$WORK/tmplA.json" || true)"
[ "$NDASH" -ge 17 ] && ok "every one of the $NDASH template fields is a '-' admission at tier UNAVAILABLE" || no "only $NDASH template fields are '-' admissions"
grep -q '"value": 0' "$WORK/tmplA.json" && no "the template contains a zero — unknowns were rendered as zeros" || ok "the template contains NO zeros (an unknown is not a zero)"
for f in starting_context_bytes expansion_bytes total_tokens uncached_tokens time_to_first_meaningful_edit_s \
         total_elapsed_s files_read search_operations context_expansions failed_hypotheses rework_rounds \
         verifier_dispatches tests_run tests_passed acceptance_result regressions human_interventions; do
  grep -q "\"$f\"" "$WORK/tmplA.json" && ok "the record carries $f" || no "the record is missing $f"
done
mkrecA "$WORK/good-A.json" E4-T1 100000 300 accepted
node "$MEASURE" validate --record "$WORK/good-A.json" >/dev/null 2>&1; RC=$?
[ "$RC" = "0" ] && ok "a fully measured arm-A record validates" || no "good arm-A record exited $RC"
mkrecB "$WORK/good-B.json" E4-T1 60000 180 accepted 8622 6622 2000 false
node "$MEASURE" validate --record "$WORK/good-B.json" >/dev/null 2>&1; RC=$?
[ "$RC" = "0" ] && ok "a fully measured arm-B record validates (capsule + prefix = starting bytes)" || no "good arm-B record exited $RC"
sed 's|"starting_context_bytes": { "value": 240000, "tier": "EXACT" }|"starting_context_bytes": { "value": 0, "tier": "UNAVAILABLE" }|' \
  "$WORK/good-A.json" > "$WORK/zero.json"
node "$MEASURE" validate --record "$WORK/zero.json" >"$WORK/zero.log" 2>&1; RC=$?
[ "$RC" = "2" ] && ok "an UNAVAILABLE field carrying 0 is REFUSED (the zero-for-unknown lie)" || no "zero-for-unknown exited $RC"
grep -q 'starting_context_bytes' "$WORK/zero.log" && ok "the zero-for-unknown refusal names the field" || no "the refusal does not name the field"
sed 's|"tier": "CLOSE-TIME"|"tier": "PROBABLY"|' "$WORK/good-A.json" > "$WORK/tier.json"
node "$MEASURE" validate --record "$WORK/tier.json" >"$WORK/tier.log" 2>&1; RC=$?
[ "$RC" = "2" ] && ok "a tier outside the adapter contract's vocabulary is REFUSED" || no "bad tier exited $RC"
grep -q 'PROBABLY' "$WORK/tier.log" && ok "the bad-tier refusal quotes the invented tier" || no "the bad-tier refusal does not quote it"
sed 's|"value": "-", "tier": "UNAVAILABLE"|"value": "-", "tier": "EXACT"|' "$WORK/tmplA.json" > "$WORK/dashexact.json"
node "$MEASURE" validate --record "$WORK/dashexact.json" >/dev/null 2>&1; RC=$?
[ "$RC" = "2" ] && ok "a '-' value claiming tier EXACT is REFUSED (no tier above what was measured)" || no "dash-at-EXACT exited $RC"
sed '/"regressions"/d' "$WORK/good-A.json" > "$WORK/missing.json"
node "$MEASURE" validate --record "$WORK/missing.json" >"$WORK/missing.log" 2>&1; RC=$?
[ "$RC" = "2" ] && ok "a record missing a required field is REFUSED" || no "missing field exited $RC"
grep -q 'regressions' "$WORK/missing.log" && ok "the missing-field refusal names regressions" || no "the missing-field refusal does not name it"
node "$MEASURE" template --task E4-T1 --arm B --out "$WORK/tmplB.json" >/dev/null 2>&1
grep -q 'arm_b_starting_context' "$WORK/tmplB.json" && ok "an arm-B template carries the AMENDMENT 2 starting-context block" || no "arm-B template lacks the Amendment 2 block"
grep -q 'arm_b_starting_context' "$WORK/tmplA.json" && no "an arm-A template carries an arm-B-only block" || ok "an arm-A template carries NO arm-B block"
node "$MEASURE" render --record "$WORK/good-B.json" >"$WORK/render.txt" 2>&1; RC=$?
[ "$RC" = "0" ] && ok "render prints the record" || no "render exited $RC"
grep -q 'uncached_tokens .*CLOSE-TIME' "$WORK/render.txt" && ok "the rendered record shows the tier beside every value" || no "the rendered record hides tiers"

echo "== 8. AMENDMENT 2: a confounded arm B leaves the aggregate, and never comes back =="
RD="$WORK/records"; mkdir -p "$RD"
for t in E4-T1 E4-T2 E4-T3; do
  mkrecA "$RD/$t.A.json" "$t" 100000 300 accepted
  mkrecB "$RD/$t.B.json" "$t" 60000 180 accepted 8622 6622 2000 false
done
node "$RUNNER" aggregate --registry "$WORK/reg3.json" --records "$RD" --out "$WORK/agg-clean.json" >"$WORK/ag1.log" 2>&1; RC=$?
[ "$RC" = "0" ] && ok "three clean pairs aggregate (exit 0)" || { no "clean aggregate exited $RC"; sed 's/^/      | /' "$WORK/ag1.log"; }
grep -q '"n_admitted": 3' "$WORK/agg-clean.json" && ok "the clean aggregate admits n=3" || no "the clean aggregate is not n=3"
RD2="$WORK/records2"; mkdir -p "$RD2"
for t in E4-T1 E4-T2 E4-T3; do
  mkrecA "$RD2/$t.A.json" "$t" 100000 300 accepted
  mkrecB "$RD2/$t.B.json" "$t" 60000 180 accepted 8622 6622 2000 false
done
# T2's arm B received the broad context AND the capsule — the exact Amendment 2 confound.
mkrecB "$RD2/E4-T2.B.json" E4-T2 60000 180 accepted 248622 6622 2000 true
node "$RUNNER" aggregate --registry "$WORK/reg3.json" --records "$RD2" --out "$WORK/agg-conf.json" >"$WORK/ag2.log" 2>&1; RC=$?
[ "$RC" = "0" ] && ok "the aggregate completes with one confounded task (recorded, not fatal)" || no "confounded aggregate exited $RC"
grep -q '"n_admitted": 2' "$WORK/agg-conf.json" \
  && ok "the aggregate's n DROPS to 2 — the confounded task is excluded from the math" \
  || no "the confounded task was counted anyway"
grep -q '"n_excluded_confounded": 1' "$WORK/agg-conf.json" && ok "the exclusion is counted, not hidden" || no "the exclusion count is missing"
grep -q 'result_confounded' "$WORK/agg-conf.json" && ok "the excluded task is labeled result_confounded (the preregistered word)" || no "the exclusion is not labeled result_confounded"
node -e '
  const a=require(process.argv[1]);
  process.exit(a.tasks.some(t=>t.task_id==="E4-T2")?1:0);
' "$WORK/agg-conf.json" && ok "the confounded task is ABSENT from the aggregate's task list" || no "the confounded task is still in the task list"
# Amendment 2's "never repaired, never re-run": repair the record and re-aggregate.
mkrecB "$RD2/E4-T2.B.json" E4-T2 60000 180 accepted 8622 6622 2000 false
node "$RUNNER" aggregate --registry "$WORK/reg3.json" --records "$RD2" --out "$WORK/agg-conf2.json" >"$WORK/ag3.log" 2>&1
grep -q '"n_admitted": 2' "$WORK/agg-conf2.json" \
  && ok "a REPAIRED confounded task stays excluded — the ledger is permanent (AMENDMENT 2)" \
  || no "a confounded task was repaired back into the aggregate"
grep -q 'confounded_ledger' "$WORK/agg-conf2.json" && ok "the permanent exclusion cites the ledger as its reason" || no "the permanent exclusion has no ledger reason"
# An unverifiable Amendment 2 check is a confound too, not a pass.
RD3="$WORK/records3"; mkdir -p "$RD3"
for t in E4-T1 E4-T2 E4-T3; do
  mkrecA "$RD3/$t.A.json" "$t" 100000 300 accepted
  mkrecB "$RD3/$t.B.json" "$t" 60000 180 accepted 8622 6622 2000 false
done
mkrecB "$RD3/E4-T3.B.json" E4-T3 60000 180 accepted 8622 6622 2000 null
node "$RUNNER" aggregate --registry "$WORK/reg3.json" --records "$RD3" --out "$WORK/agg-unver.json" >/dev/null 2>&1
grep -q '"n_admitted": 2' "$WORK/agg-unver.json" \
  && ok "an UNVERIFIABLE Amendment 2 check confounds the task (it is not admitted on trust)" \
  || no "an unverifiable Amendment 2 check was admitted"
RD4="$WORK/records4"; mkdir -p "$RD4"
mkrecA "$RD4/E4-T1.A.json" E4-T1 100000 300 accepted
node "$RUNNER" aggregate --registry "$WORK/reg3.json" --records "$RD4" --out "$WORK/agg-half.json" >"$WORK/ag4.log" 2>&1; RC=$?
[ "$RC" = "2" ] && ok "a task with only ONE arm's record is refused (matched-arm means both)" || no "half a pair exited $RC"
grep -q 'E4-T1' "$WORK/ag4.log" && ok "the half-pair refusal names the task" || no "the half-pair refusal does not name the task"

echo "== 9. Verdict: the seven labels, mechanically, from the preregistration's own thresholds =="
node "$VERDICT" --help >/dev/null 2>&1 && ok "verdict.mjs answers --help" || no "verdict.mjs has no help path"
verd(){ # $1 expected operator_verdict  $2 aggregate file  $3 label
  node "$VERDICT" --aggregate "$2" >"$WORK/vd.log" 2>&1
  local rc=$?
  if [ "$rc" != "0" ]; then no "$3: verdict exited $rc"; sed 's/^/      | /' "$WORK/vd.log"; return; fi
  grep -q "^operator_verdict: $1$" "$WORK/vd.log" \
    && ok "$3 -> '$1'" \
    || no "$3 expected '$1', got: $(grep '^operator_verdict:' "$WORK/vd.log" || echo none)"
}
mkagg "$WORK/a-sup.json"  1000 600 100 60  accepted,accepted,accepted accepted,accepted,accepted
verd "supported" "$WORK/a-sup.json" "40% fewer uncached tokens, 40% faster, acceptance held"
mkagg "$WORK/a-comp.json" 1000 600 100 95  accepted,accepted,accepted accepted,accepted,accepted
verd "compression only" "$WORK/a-comp.json" "40% fewer tokens, only 5% faster"
mkagg "$WORK/a-acc.json"  1000 900 100 50  accepted,accepted,accepted accepted,accepted,accepted
verd "acceleration only" "$WORK/a-acc.json" "50% faster, only 10% fewer tokens"
mkagg "$WORK/a-inc.json"  1000 970 100 98  accepted,accepted,accepted accepted,accepted,accepted
verd "inconclusive" "$WORK/a-inc.json" "3% tokens, 2% time — nothing separates"
mkagg "$WORK/a-harm.json" 1000 1200 100 90 accepted,accepted,accepted accepted,accepted,accepted
verd "context compilation harmful" "$WORK/a-harm.json" "20% MORE uncached tokens"
mkagg "$WORK/a-unin.json" 1000 600 100 60  accepted,accepted,accepted accepted,accepted,accepted 94.0
verd "small-because-uninformed" "$WORK/a-unin.json" "a token win on a repository with 94% no_parser"
mkagg "$WORK/a-conf.json" 1000 600 100 60  accepted,accepted,accepted accepted,accepted,accepted 12.0 '"arm isolation defect: the capsule leaked into arm A"'
verd "result confounded" "$WORK/a-conf.json" "a recorded arm-isolation defect"

echo "== 9b. THE ACCEPTANCE VETO — a token win that costs acceptance is a LOSS, not a trade =="
mkagg "$WORK/a-veto.json" 1000 500 100 50 accepted,accepted,accepted accepted,accepted,rejected
node "$VERDICT" --aggregate "$WORK/a-veto.json" >"$WORK/veto.log" 2>&1; RC=$?
[ "$RC" = "0" ] && ok "the veto aggregate evaluates" || no "veto aggregate exited $RC"
grep -q '^operator_verdict: context compilation harmful$' "$WORK/veto.log" \
  && ok "a 50% token win AND a 50% time win with acceptance 3/3 -> 2/3 returns 'context compilation harmful'" \
  || no "the acceptance veto did not fire: $(grep '^operator_verdict:' "$WORK/veto.log" || echo none)"
grep -q '^acceptance_veto_applied: true$' "$WORK/veto.log" \
  && ok "the veto is reported explicitly, as its own gate" \
  || no "the veto gate is not reported"
for forbidden in "^operator_verdict: supported$" "^operator_verdict: compression only$" "^operator_verdict: acceleration only$"; do
  grep -q "$forbidden" "$WORK/veto.log" && no "a vetoed aggregate returned $forbidden" || ok "a vetoed aggregate CANNOT return ${forbidden//^operator_verdict: /}"
done
grep -q 'Compression that costs acceptance is a loss' "$WORK/veto.log" \
  && ok "the veto cites the preregistration's own sentence" || no "the veto does not cite the preregistration"
# The veto must survive an aggregate that would otherwise be the strongest possible win.
mkagg "$WORK/a-veto2.json" 100000 1000 1000 10 accepted,accepted,accepted accepted,rejected,rejected
node "$VERDICT" --aggregate "$WORK/a-veto2.json" >"$WORK/veto2.log" 2>&1
grep -q '^operator_verdict: context compilation harmful$' "$WORK/veto2.log" \
  && ok "a 99% token win with acceptance 3/3 -> 1/3 is still 'context compilation harmful'" \
  || no "the veto failed on the extreme win"

echo "== 9c. The thresholds come from the preregistration, and nowhere else =="
node "$VERDICT" --aggregate "$WORK/a-sup.json" >"$WORK/th.log" 2>&1
grep -q 'uncached_supported_pct: 25' "$WORK/th.log" && ok "the 25% support threshold is reported with its source" || no "the 25% threshold is not reported"
grep -q 'detectable_pct: 10' "$WORK/th.log" && ok "the 10% detectability threshold is reported" || no "the 10% threshold is not reported"
grep -q 'no_parser_max_pct: 50' "$WORK/th.log" && ok "AMENDMENT 1's 50% ceiling is reported" || no "the 50% ceiling is not reported"
grep -q 'AB_PREREGISTRATION.md' "$WORK/th.log" && ok "every threshold cites AB_PREREGISTRATION.md as its source" || no "the thresholds cite no source file"
for flag in --threshold-uncached-pct --min-n --override-threshold; do
  node "$VERDICT" --aggregate "$WORK/a-sup.json" "$flag" 5 >"$WORK/ov.log" 2>&1; RC=$?
  [ "$RC" = "2" ] && ok "$flag is REFUSED (thresholds are preregistered, not chosen from the data)" || no "$flag exited $RC"
  grep -q 'preregist' "$WORK/ov.log" && ok "$flag refusal explains that the threshold is preregistered" || no "$flag refusal gives no reason"
done
cp "$PREREG" "$WORK/prereg-drifted.md"
sed -i 's/reduction >= 25%/reduction >= 5%/' "$WORK/prereg-drifted.md"
node "$VERDICT" --aggregate "$WORK/a-sup.json" --prereg "$WORK/prereg-drifted.md" >"$WORK/drift.log" 2>&1; RC=$?
[ "$RC" = "2" ] && ok "a preregistration whose parsed threshold disagrees with the cited constant is REFUSED (drift is not silently adopted)" || no "prereg drift exited $RC"
node "$VERDICT" --aggregate "$WORK/a-sup.json" --prereg "$WORK/does-not-exist.md" >/dev/null 2>&1; RC=$?
[ "$RC" = "2" ] && ok "a missing preregistration file is refused (no thresholds, no verdict)" || no "missing prereg exited $RC"

echo "== 9d. The verdict is honest about the preregistration it is applying =="
node "$VERDICT" --aggregate "$WORK/a-acc.json" >"$WORK/map.log" 2>&1
grep -q '^preregistered_verdict: ' "$WORK/map.log" \
  && ok "every operator label is mapped back to one of the FIVE preregistered outcomes" \
  || no "no preregistered_verdict is emitted"
grep -q 'AMBIGUITY' "$WORK/map.log" \
  && ok "the tool names the preregistration ambiguities it had to navigate (not silently resolved)" \
  || no "the tool resolves prereg ambiguities silently"
grep -q 'no wall-clock threshold' "$WORK/map.log" \
  && ok "the borrowed wall-clock threshold is disclosed as borrowed (the prereg registers none)" \
  || no "the borrowed time threshold is undisclosed"
node "$VERDICT" --aggregate "$WORK/a-unin.json" >"$WORK/unin.log" 2>&1
grep -q 'preregistered_verdict: result confounded' "$WORK/unin.log" \
  && ok "small-because-uninformed maps to 'result confounded' per AMENDMENT 1's binding clause" \
  || no "small-because-uninformed maps somewhere the amendment does not say"
node -e '
  const fs=require("fs");const f=process.argv[1];
  const j=JSON.parse(fs.readFileSync(f,"utf8"));
  j.tasks[1].b.uncached_tokens="-";
  fs.writeFileSync(f,JSON.stringify(j,null,2));
' "$WORK/a-sup.json"
node "$VERDICT" --aggregate "$WORK/a-sup.json" >"$WORK/dash.log" 2>&1; RC=$?
[ "$RC" = "2" ] && ok "an admitted task with an unmeasured uncached count is REFUSED (a '-' is never averaged as 0)" || no "unmeasured admission exited $RC"
grep -q 'E4-T2' "$WORK/dash.log" && ok "the unmeasured-admission refusal names the task" || no "the refusal does not name the task"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
