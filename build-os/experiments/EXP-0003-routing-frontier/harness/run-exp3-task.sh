# EXP-0003 — run ONE measured task of one condition's three-task sequence and
# capture MODELUSAGE-NATIVE telemetry; or close a condition's routing receipt
# from its three sealed records. Invoke via bash; this file is deliberately
# NOT executable.
#
# Usage (run mode — one condition, one task):
#   bash run-exp3-task.sh --condition A|B|C --task T3|T4|T5 \
#                         --workdir DIR --outdir DIR [--model NAME] \
#                         [--timeout SECONDS]
#
# Usage (close mode — after a condition's THREE tasks, B and C only):
#   bash run-exp3-task.sh --close --condition B|C --workdir DIR \
#                         --runsdir DIR --outdir DIR
#
#   --workdir DIR   the condition's PERSISTENT directory: DIR/repo (the one
#                   evolving work tree, never reseeded between tasks) and
#                   DIR/pristine (the condition baseline, captured once before
#                   T3's session). One workdir per condition.
#   --outdir DIR    per-task artifact directory (stream.jsonl, result.json,
#                   run_record.txt, ...); in close mode, where gate_result.txt
#                   and the filled receipt copy are written.
#   --runsdir DIR   close mode only: the directory holding T3/ T4/ T5
#                   subdirectories with the three run_record.txt files.
#
# THE SEQUENCE (per condition, in order):
#   seed -> setup-t1t2 (scripted T1+T2 reference, oracle-proven)
#        -> [B/C only: install-project.sh --no-session-hook + routing receipt
#            placed at build-os/packets/routing/ + the pointer block appended
#            to build-os/memory/tool_router.md]
#        -> pristine baseline -> T3 -> inject-t4 -> T4 -> T5 -> close (B/C)
# The first measured task (T3) performs seed + setup + condition surface +
# baseline itself, so the baseline is captured exactly once, before any
# session runs. T4 performs the injection itself when test/regression-t4.js is
# absent, and records that it did. Every task is a FRESH headless session.
#
# CONDITIONS. Identical task text (EXP-0002's FROZEN prompts, extracted
# mechanically and sha256-pinned), identical permissions; the differences are
# EXACTLY: A no installed surface; B installed surface + a gravito_light
# routing receipt; C installed surface + a gravito_full routing receipt with
# the derived budgets. B and C receive a BYTE-IDENTICAL router pointer block;
# their receipts are issued by the REAL issuer (build-os/tools/route-task.sh)
# from descriptors differing in exactly one boolean (high_rework_history).
#
# TELEMETRY IS MODELUSAGE-NATIVE — the recorded EXP-0002 defect (the parent
# result event's usage.* block undercounts dispatch-heavy sessions), fixed in
# THIS new runner rather than by editing frozen machinery: token and cost
# primaries are summed across the result event's modelUsage entries, the sum
# of per-model costUSD is reconciled against total_cost_usd, and the record is
# REFUSED (written as run_record.REFUSED.txt, exit 2, retained as data) if the
# two disagree by more than 1e-6. The parent usage.* block is recorded BESIDE
# the primaries with an explicit usage_block_disagrees flag, never merged.
#
# THE CLOSE-TIME LOOP (close mode). The harness fills the condition receipt's
# consumption fields from the three records' summed measured telemetry, sets
# executed_mode by the DISCLOSED mechanical proxy (>=1 structural subagent
# dispatch across the sequence = gravito_full ceremony was executed; 0 = the
# selected mode; unknown = '-'), then runs build-os/tools/routing-check.sh on
# the filled receipt and writes its verdict VERBATIM plus its exit code to
# gate_result.txt. A refused receipt is DATA: it is retained, labeled, and
# never edited to pass. Condition A has no receipt (disclosed); close mode
# refuses it by name.
#
# THE RULE THAT GOVERNS EVERY FIELD (bench discipline): an unknown is not a
# zero. Anything not derived by executing something is '-'.
#
# Exit: 0 the run/close completed (accepted or not; gate verdict recorded
# either way); 2 harness/precondition failure or a REFUSED record.
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SELF_DIR/../../../.." && pwd)"
EXP2_H="$(cd "$SELF_DIR/../../EXP-0002-sustained-workload/harness" && pwd)"
SEEDER="$EXP2_H/seed-workload-repo.sh"
ORACLE="$EXP2_H/oracle-exp2.js"
TASKS_MD="$EXP2_H/tasks.md"
INJECTOR="$EXP2_H/inject-t4.sh"
SETUP="$SELF_DIR/setup-t1t2.sh"
INSTALLER="$REPO_ROOT/install-project.sh"
ROUTE="$REPO_ROOT/build-os/tools/route-task.sh"
RCHECK="$REPO_ROOT/build-os/tools/routing-check.sh"

HARNESS_VERSION="1.0.0"
SEED_SUITE_EXPECT='TOTAL: 19 passed, 0 failed'
# Pinned identities — refusals, not notes. The seed digest is EXP-0002's
# preregistered value; the post-setup digest is EXP-0003's preregistered
# value; the prompt sha256s are EXP-0002's sealed per-task values.
PIN_SEED_DIGEST="128485c6082bdf7305168001212b1e2aa7005815be9c00735185eecfdb8cc06f"
PIN_SETUP_DIGEST="6c77b5a4bda46ba4730ccf1b2a08725a76523e87ac7402096744659d0c47b6aa"
PIN_SHA_T3="aa51dd7f4329ecfabd20348cefe0e78cc324cefe9c6e9b56455bc7b8e163fcbc"
PIN_SHA_T4="39638bc19253701d624915b5e9c651335e9f1193cf7da9b1a7f49c552fad29f1"
PIN_SHA_T5="f2dd4ce545ffd523a564ed9139d9f3b86725a0b1b48c98eabd3fd7ef53031d5c"

RECEIPT_NAME="routing-EXP-0003-sequence.md"
RECEIPT_REL="build-os/packets/routing/$RECEIPT_NAME"
# One description, BYTE-IDENTICAL across B and C (so description_sha256 is
# identical); the descriptors differ in exactly one boolean.
COND_DESC_TEXT="EXP-0003 measured three-task sequence (T3 discount-code feature, T4 injected regression, T5 summary follow-up) on the prepared parcel-billing tree"
DESC_COMMON='"expected_files_changed":4,"requires_tests":true,"expected_session_count":3,"prior_context_required":true,"handoff_required":false,"consequence_level":"medium","irreversible_or_external_mutation":false,"high_blast_radius":false,"unclear_acceptance_criteria":false,"security_or_compliance_consequence":false,"parallel_workstreams_benefit":false,"nondeterministic_verification":false'
DESC_B="{$DESC_COMMON,\"high_rework_history\":false}"
DESC_C="{$DESC_COMMON,\"high_rework_history\":true}"

die(){ printf 'run-exp3-task: %s\n' "$*" >&2; exit 2; }

MODE="run"; TASK=""; COND=""; WORKDIR=""; OUTDIR=""; RUNSDIR=""; MODEL=""; TIMEOUT=3600
while [ "$#" -gt 0 ]; do
  case "$1" in
    --close)     MODE="close"; shift ;;
    --condition) [ $# -ge 2 ] || die "--condition needs a value"; COND="$2"; shift 2 ;;
    --task)      [ $# -ge 2 ] || die "--task needs a value";      TASK="$2"; shift 2 ;;
    --workdir)   [ $# -ge 2 ] || die "--workdir needs a value";   WORKDIR="$2"; shift 2 ;;
    --outdir)    [ $# -ge 2 ] || die "--outdir needs a value";    OUTDIR="$2"; shift 2 ;;
    --runsdir)   [ $# -ge 2 ] || die "--runsdir needs a value";   RUNSDIR="$2"; shift 2 ;;
    --model)     [ $# -ge 2 ] || die "--model needs a value";     MODEL="$2"; shift 2 ;;
    --timeout)   [ $# -ge 2 ] || die "--timeout needs a value";   TIMEOUT="$2"; shift 2 ;;
    -h|--help)   sed -n '2,72p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

# Argument validation FIRST — a refusal must not depend on the environment.
case "$COND" in A|B|C) ;; *) die "--condition must be A|B|C (got \"${COND:-}\") — A direct/raw, B gravito_light receipt, C gravito_full receipt with budgets" ;; esac
[ -n "$WORKDIR" ] || die "--workdir is required (the condition's persistent directory)"
[ -n "$OUTDIR" ]  || die "--outdir is required"

# A field's first value, house format "field: value".
fval(){ awk -v k="$2" 'index($0, k": ")==1 { print substr($0, length(k)+3); exit }' "$1"; }
is_num(){ printf '%s' "$1" | grep -qE '^-?[0-9]+(\.[0-9]+)?$'; }

# =========================================================== CLOSE MODE =====
if [ "$MODE" = "close" ]; then
  [ "$COND" = "A" ] && die "condition A has NO routing receipt — that absence is a disclosed property of the condition (no installed surface, nothing to reconcile), not an omission. There is nothing to fill and nothing to gate."
  [ -n "$RUNSDIR" ] || die "--runsdir is required in close mode (the directory holding T3/ T4/ T5 run records)"
  [ -d "$WORKDIR" ] || die "workdir $WORKDIR does not exist"
  WORKDIR="$(cd "$WORKDIR" && pwd)"
  REC="$WORKDIR/repo/$RECEIPT_REL"
  [ -f "$REC" ] || die "no routing receipt at $REC — condition $COND's work tree was never given its receipt, so this is not a condition that can be closed"
  [ -f "$RCHECK" ] || die "missing close-time gate: $RCHECK"
  [ -d "$RUNSDIR" ] || die "runsdir $RUNSDIR does not exist"
  RUNSDIR="$(cd "$RUNSDIR" && pwd)"
  for t in T3 T4 T5; do
    [ -f "$RUNSDIR/$t/run_record.txt" ] || die "missing $RUNSDIR/$t/run_record.txt — the condition's three records must all exist before the receipt is filled (a REFUSED record cannot be summed; a missing one cannot be admitted as zero)"
  done
  mkdir -p "$OUTDIR" || die "cannot create $OUTDIR"
  OUTDIR="$(cd "$OUTDIR" && pwd)"
  # A receipt is filled exactly once.
  for f in executed_mode consumed_subagents consumed_total_tokens consumed_uncached_tokens \
           consumed_model_calls consumed_wall_clock_s consumed_cost_usd; do
    [ "$(fval "$REC" "$f")" = "-" ] || die "receipt field $f is already filled in $REC — a receipt is filled once, from the sealed records, and never refilled"
  done
  SEL="$(fval "$REC" selected_mode)"
  [ -n "$SEL" ] || die "receipt at $REC carries no selected_mode"

  # Sum a numeric run-record field across the three tasks; '-' unless all
  # three values are machine-derived numbers (an unknown is not a zero).
  sum_field(){ # <field> <printf-format>
    local k="$1" fmt="$2" v t vals=""
    for t in T3 T4 T5; do
      v="$(fval "$RUNSDIR/$t/run_record.txt" "$k")"
      v="${v%% *}"
      is_num "$v" || { printf '%s' "-"; return 0; }
      vals="$vals $v"
    done
    # shellcheck disable=SC2086
    awk -v fmt="$fmt" 'BEGIN{s=0; for(i=1;i<ARGC;i++) s+=ARGV[i]; printf fmt, s; exit}' $vals
  }
  C_SUB="$(sum_field subagent_dispatches_structural "%d")"
  C_TOT="$(sum_field mu_total_tokens "%d")"
  C_UNC="$(sum_field mu_uncached_tokens "%d")"
  C_CALLS="$(sum_field num_turns "%d")"
  C_WALL="$(sum_field wall_clock_s "%.2f")"
  C_COST="$(sum_field mu_cost_usd "%.6f")"

  # The DISCLOSED executed-mode proxy: >=1 structural subagent dispatch across
  # the sequence is the machine-visible signature of Full ceremony; 0 means
  # the sequence stayed at (or below) its selected mode; unknown stays '-'.
  # NAMED BOUND: a Full ceremony that dispatches no subagent is invisible to
  # this proxy, and no field here claims otherwise.
  if [ "$C_SUB" = "-" ]; then EXE="-"
  elif [ "$C_SUB" -ge 1 ]; then EXE="gravito_full"
  else EXE="$SEL"; fi

  fill(){ # <field> <value> — replace the exact '-' line, verify it took
    local f="$1" v="$2"
    sed -i "s|^$f: -$|$f: $v|" "$REC" || die "could not fill $f"
    [ "$(fval "$REC" "$f")" = "$v" ] || die "fill of $f did not take"
  }
  fill executed_mode "$EXE"
  fill consumed_subagents "$C_SUB"
  fill consumed_total_tokens "$C_TOT"
  fill consumed_uncached_tokens "$C_UNC"
  fill consumed_model_calls "$C_CALLS"
  fill consumed_wall_clock_s "$C_WALL"
  fill consumed_cost_usd "$C_COST"

  # The mechanical gate, verdict recorded VERBATIM. A refusal here is DATA —
  # the receipt and the verdict are both retained exactly as produced.
  GATE_OUT="$OUTDIR/gate_result.txt"
  {
    echo "# EXP-0003 close-time routing gate — condition $COND"
    echo "receipt: $REC"
    echo "filled_from: $RUNSDIR/{T3,T4,T5}/run_record.txt (summed measured telemetry; '-' = not all three machine-derived)"
    echo "executed_mode_proxy: >=1 structural subagent dispatch across the sequence -> gravito_full; 0 -> selected_mode; unknown -> '-' (a dispatch-free Full ceremony is invisible to this proxy — named bound)"
    echo "--- routing-check.sh check --receipt (verbatim) ---"
  } > "$GATE_OUT"
  bash "$RCHECK" check --receipt "$REC" >> "$GATE_OUT" 2>&1
  GATE_EXIT=$?
  {
    echo "--- end verbatim ---"
    echo "gate_exit: $GATE_EXIT"
    echo "disposition: $([ "$GATE_EXIT" -eq 0 ] && echo "PASSED" || echo "REFUSED — retained as data, labeled, not edited to pass")"
  } >> "$GATE_OUT"
  cp "$REC" "$OUTDIR/receipt-final.md" || die "could not copy the filled receipt beside its gate result"
  cat "$GATE_OUT"
  printf 'run-exp3-task: close complete for condition %s (gate_exit=%s; a refusal is data, not a harness failure)\n' "$COND" "$GATE_EXIT"
  exit 0
fi

# ============================================================= RUN MODE =====
case "$TASK" in
  T3|T4|T5) ;;
  T1|T2) die "--task $TASK is not a measured EXP-0003 task — T1/T2 arrive by the deterministic scripted setup (setup-t1t2.sh), identically in all conditions, precisely so no unmeasured model run exists" ;;
  *) die "--task must be T3|T4|T5 (got \"${TASK:-}\")" ;;
esac
command -v claude >/dev/null 2>&1 || die "the claude CLI is not on PATH"
command -v node   >/dev/null 2>&1 || die "node is not on PATH"
for f in "$SEEDER" "$ORACLE" "$TASKS_MD" "$INJECTOR" "$SETUP"; do
  [ -f "$f" ] || die "missing harness piece: $f"
done

mkdir -p "$OUTDIR" || die "cannot create $OUTDIR"
OUTDIR="$(cd "$OUTDIR" && pwd)"
mkdir -p "$WORKDIR" || die "cannot create $WORKDIR"
WORKDIR="$(cd "$WORKDIR" && pwd)"
REPO="$WORKDIR/repo"
PRISTINE="$WORKDIR/pristine"

# ------------------------------------------------- frozen prompt extraction --
# Extracted mechanically from EXP-0002's FROZEN tasks.md (read-only reuse by
# invocation), then VERIFIED against the pinned sha256 — committed text, sent
# text and preregistered identity cannot drift apart.
PROMPT="$(awk -v task="$TASK" '
  /^## / { insec = ($2 == task); fence = 0; next }
  insec && /^```/ { fence++; if (fence == 2) exit; next }
  insec && fence == 1 { print }
' "$TASKS_MD")"
[ -n "$PROMPT" ] || die "could not extract the $TASK prompt from $TASKS_MD"
PROMPT_SHA="$(printf '%s' "$PROMPT" | sha256sum | cut -d' ' -f1)"
case "$TASK" in
  T3) PIN="$PIN_SHA_T3" ;;
  T4) PIN="$PIN_SHA_T4" ;;
  T5) PIN="$PIN_SHA_T5" ;;
esac
[ "$PROMPT_SHA" = "$PIN" ] || die "frozen prompt drift: $TASK extracted sha256 $PROMPT_SHA does not equal the pinned $PIN — the frozen EXP-0002 prompt is not what this runner would send, so it sends nothing"

# ------------------------------------- condition setup (first task = T3) ----
SETUP_NOTE="pre-existing work tree (task $TASK of the condition sequence)"
SEEDED_SUITE="-"; SETUP_SUITE="-"
if [ ! -d "$REPO" ]; then
  [ "$TASK" = "T3" ] || die "work tree $REPO does not exist — the condition sequence starts at T3, which performs seed + scripted T1/T2 setup + condition surface + baseline"
  bash "$SEEDER" "$REPO" > "$OUTDIR/seed.txt" 2>&1 || { cat "$OUTDIR/seed.txt" >&2; die "seeding failed"; }
  SEED_DIGEST="$(bash "$SEEDER" --digest "$REPO")" || die "could not digest the seeded tree"
  [ "$SEED_DIGEST" = "$PIN_SEED_DIGEST" ] || die "seed digest $SEED_DIGEST does not equal the pinned $PIN_SEED_DIGEST — the frozen workload is not what was preregistered"
  SEEDED_SUITE="$(cd "$REPO" && node test/run.js 2>&1 | tail -1)"
  [ "$SEEDED_SUITE" = "$SEED_SUITE_EXPECT" ] || die "seeded suite is not at its expected state (got: $SEEDED_SUITE)"
  # Deterministic scripted T1/T2 — identical across conditions, oracle-proven.
  bash "$SETUP" "$REPO" > "$OUTDIR/setup-t1t2.log" 2>&1 || { cat "$OUTDIR/setup-t1t2.log" >&2; die "scripted T1/T2 setup failed"; }
  SETUP_DIGEST="$(bash "$SEEDER" --digest "$REPO")" || die "could not digest the post-setup tree"
  [ "$SETUP_DIGEST" = "$PIN_SETUP_DIGEST" ] || die "post-setup digest $SETUP_DIGEST does not equal the pinned $PIN_SETUP_DIGEST — the scripted T1/T2 state is not what was preregistered"
  SETUP_SUITE="$(cd "$REPO" && node test/run.js 2>&1 | tail -1)"
  if [ "$COND" != "A" ]; then
    [ -f "$INSTALLER" ] || die "conditions B/C need $INSTALLER"
    [ -f "$ROUTE" ]     || die "conditions B/C need the receipt issuer $ROUTE"
    bash "$INSTALLER" --no-session-hook "$REPO" > "$OUTDIR/arm-install.log" 2>&1 \
      || { cat "$OUTDIR/arm-install.log" >&2; die "condition install failed"; }
    # The condition receipt — issued by the REAL issuer, never hand-written.
    case "$COND" in
      B) DESC="$DESC_B"; WANT_MODE="gravito_light" ;;
      C) DESC="$DESC_C"; WANT_MODE="gravito_full" ;;
    esac
    RTMP="$(mktemp -d)"
    bash "$ROUTE" --task-id EXP-0003-sequence --description "$COND_DESC_TEXT" \
      --descriptor "$DESC" --out "$RTMP" > "$OUTDIR/route-task.log" 2>&1 \
      || { cat "$OUTDIR/route-task.log" >&2; rm -rf "$RTMP"; die "receipt issuance failed"; }
    ISSUED="$(find "$RTMP" -maxdepth 1 -name 'routing-EXP-0003-sequence-*.md' | head -1)"
    [ -n "$ISSUED" ] || { rm -rf "$RTMP"; die "the issuer wrote no receipt"; }
    GOT_MODE="$(fval "$ISSUED" selected_mode)"
    [ "$GOT_MODE" = "$WANT_MODE" ] || { rm -rf "$RTMP"; die "condition $COND expected selected_mode $WANT_MODE, the issuer selected \"$GOT_MODE\" — the condition cannot be instantiated from this descriptor"; }
    mkdir -p "$REPO/build-os/packets/routing"
    # Placed at a FIXED name so the two conditions' surfaces differ only in
    # receipt CONTENT, never in path.
    cp "$ISSUED" "$REPO/$RECEIPT_REL" || { rm -rf "$RTMP"; die "could not place the receipt in the work tree"; }
    rm -rf "$RTMP"
    # The pointer block — BYTE-IDENTICAL across B and C — appended to the ONE
    # installed file the installed per-task protocol (step 2) directs every
    # session to read. The installed CLAUDE.md block carries NO routing step;
    # this is the disclosed placement mechanism, identical in both conditions.
    [ -f "$REPO/build-os/memory/tool_router.md" ] || die "install did not produce build-os/memory/tool_router.md — nowhere the installed surface directs the agent to read"
    cat >> "$REPO/build-os/memory/tool_router.md" <<'EOF'

## Routing receipt for the current work (BINDING)

A routing receipt for the work in this repository is at
`build-os/packets/routing/routing-EXP-0003-sequence.md`. Read it before
starting. The recorded `selected_mode` is **binding**, not advisory:

- `direct` — no workflow machinery.
- `gravito_light` — use repository context and bounded checks; **no Full
  ceremony** (no subagent dispatches, no multi-agent workflow).
- `gravito_full` — full workflow is authorized **only within the receipt's
  budgets**. When any budget is approached, degrade gracefully, in order:
  stop spawning subagents; collapse remaining work into the parent loop;
  preserve state; continue light where safe; report the degradation. Never
  bare termination while a safe productive path remains.

Silent escalation is prohibited: running above the recorded mode requires a
new evidence-bearing escalation decision recorded in the receipt BEFORE the
escalated work begins. De-escalation is free. The receipt's consumption
fields are reconciled against its budgets at close.
EOF
    SETUP_NOTE="seeded; scripted T1/T2 applied (oracle-proven); surface installed; $WANT_MODE receipt placed; router pointer appended; pristine baseline captured"
  else
    SETUP_NOTE="seeded; scripted T1/T2 applied (oracle-proven); NO surface (condition A); pristine baseline captured"
  fi
  # THE BASELINE IS TAKEN AFTER the condition surface, so installer-edited
  # files, the receipt and the pointer block are baseline, never task output.
  cp -r "$REPO" "$PRISTINE"
else
  [ -d "$PRISTINE" ] || die "$REPO exists but $PRISTINE does not — the baseline was never captured; re-start the condition from T3 in a fresh workdir"
  if [ "$COND" != "A" ] && [ ! -f "$REPO/$RECEIPT_REL" ]; then
    die "condition $COND work tree carries no receipt at $RECEIPT_REL — the condition surface was never placed; re-start the condition from T3 in a fresh workdir"
  fi
fi

case "$COND" in
  A) COND_NOTE="direct/raw — no installed surface, no receipt (disclosed)" ;;
  B) COND_NOTE="installed surface + gravito_light receipt (binding, pointed to from tool_router.md)" ;;
  C) COND_NOTE="installed surface + gravito_full receipt with derived budgets (binding, pointed to from tool_router.md)" ;;
esac

# ------------------------------------------------------ T4 injection gate ----
INJECTED_NOW="not_applicable"
if [ "$TASK" = "T4" ]; then
  if [ -f "$REPO/test/regression-t4.js" ]; then
    INJECTED_NOW="already_present"
  else
    bash "$INJECTOR" "$REPO" > "$OUTDIR/inject-t4.log" 2>&1 \
      || { cat "$OUTDIR/inject-t4.log" >&2; die "inject-t4 failed"; }
    INJECTED_NOW="injected_by_this_run (see inject-t4.log)"
  fi
fi

STARTING_DIGEST="$(bash "$SEEDER" --digest "$REPO")" || die "could not digest the starting tree"

# ------------------------------------------------------------------- invoke --
RESULT_JSON="$OUTDIR/result.json"
STREAM_LOG="$OUTDIR/stream.jsonl"
RUN_ERR="$OUTDIR/run.stderr"

# PERMISSIONS — IDENTICAL ACROSS CONDITIONS, disclosed as in EXP-0002: the
# scoped allowlist observed NON-BINDING in CLI 2.1.222; isolation comes from
# the detached scratch work tree, not the allowlist.
CLAUDE_ARGS=(-p "$PROMPT" --output-format stream-json --verbose \
             --permission-mode acceptEdits --allowedTools "Bash(node:*)")
[ -n "$MODEL" ] && CLAUDE_ARGS+=(--model "$MODEL")

START="$(date +%s.%N)"
( cd "$REPO" && timeout "$TIMEOUT" claude "${CLAUDE_ARGS[@]}" ) > "$STREAM_LOG" 2> "$RUN_ERR"
CLI_EXIT=$?
END="$(date +%s.%N)"
WALL_S="$(awk -v a="$END" -v b="$START" 'BEGIN{printf "%.2f", a-b}')"
WALL_MIN="$(awk -v s="$WALL_S" 'BEGIN{printf "%.2f", s/60}')"

ENDING_DIGEST="$(bash "$SEEDER" --digest "$REPO")" || ENDING_DIGEST="-"

grep '"type":"result"' "$STREAM_LOG" | tail -1 > "$RESULT_JSON" 2>/dev/null
[ -s "$RESULT_JSON" ] || printf '{}' > "$RESULT_JSON"

# ------------------------------------------------------------ final verdict --
FINAL_VERDICT="$(node "$ORACLE" "$TASK" "$REPO" "$PRISTINE" 2>&1)"
ACCEPTED=$?
if [ "$ACCEPTED" -eq 0 ]; then ACCEPTED_STR="yes"; else ACCEPTED_STR="no"; fi
FINAL_SUITE="$(cd "$REPO" && node test/run.js 2>&1 | tail -1)"

# --------------------------------------------------------- extract from CLI --
jq_get(){ node -e '
  const fs=require("fs");
  let j={};try{j=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));}catch(e){}
  const p=process.argv[2].split(".");let v=j;
  for(const k of p){ if(v==null||typeof v!=="object"){v=undefined;break;} v=v[k]; }
  process.stdout.write(v===undefined||v===null?"-":String(v));
' "$RESULT_JSON" "$1"; }

DURATION_API_MS="$(jq_get duration_api_ms)"
NUM_TURNS="$(jq_get num_turns)"
COST_USD="$(jq_get total_cost_usd)"
IS_ERROR="$(jq_get is_error)"
STOP_REASON="$(jq_get stop_reason)"
# The parent usage.* block — recorded BESIDE the primaries, never merged.
U_IN="$(jq_get usage.input_tokens)"
U_OUT="$(jq_get usage.output_tokens)"
U_CC="$(jq_get usage.cache_creation_input_tokens)"
U_CR="$(jq_get usage.cache_read_input_tokens)"

# THE PRIMARIES — MODELUSAGE-NATIVE. Summed structurally across every model
# entry; TSV: models nmodels in out cr cc total uncached cost.
MU_TSV="$(node -e '
  const fs=require("fs");let j={};try{j=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));}catch(e){}
  const mu=j.modelUsage||{};const ks=Object.keys(mu);
  if(!ks.length){process.stdout.write("NOMU");process.exit(0);}
  let i=0,o=0,cr=0,cc=0,cost=0;
  for(const k of ks){const m=mu[k]||{};
    i+=m.inputTokens||0;o+=m.outputTokens||0;
    cr+=m.cacheReadInputTokens||0;cc+=m.cacheCreationInputTokens||0;
    cost+=m.costUSD||0;}
  const tot=i+o+cr+cc;
  process.stdout.write([ks.join("+"),ks.length,i,o,cr,cc,tot,tot-cr,cost.toFixed(6)].join("\t"));
' "$RESULT_JSON" 2>/dev/null)"
if [ -z "$MU_TSV" ] || [ "$MU_TSV" = "NOMU" ]; then
  MODEL_USED="-"; MU_N="-"; MU_IN="-"; MU_OUT="-"; MU_CR="-"; MU_CC="-"
  MU_TOTAL="-"; MU_UNCACHED="-"; MU_COST="-"
else
  MODEL_USED="$(printf '%s' "$MU_TSV" | cut -f1)"
  MU_N="$(printf '%s' "$MU_TSV" | cut -f2)"
  MU_IN="$(printf '%s' "$MU_TSV" | cut -f3)"
  MU_OUT="$(printf '%s' "$MU_TSV" | cut -f4)"
  MU_CR="$(printf '%s' "$MU_TSV" | cut -f5)"
  MU_CC="$(printf '%s' "$MU_TSV" | cut -f6)"
  MU_TOTAL="$(printf '%s' "$MU_TSV" | cut -f7)"
  MU_UNCACHED="$(printf '%s' "$MU_TSV" | cut -f8)"
  MU_COST="$(printf '%s' "$MU_TSV" | cut -f9)"
fi

# COST RECONCILIATION — refusal, not a footnote. When both the modelUsage cost
# sum and total_cost_usd are numeric, they must agree to 1e-6 or the record is
# REFUSED (retained as run_record.REFUSED.txt — a refused record is data).
COST_DELTA="-"; COST_AGREES="-"
if is_num "$MU_COST" && is_num "$COST_USD"; then
  COST_DELTA="$(awk -v a="$MU_COST" -v b="$COST_USD" 'BEGIN{d=a-b; if(d<0)d=-d; printf "%.9f", d}')"
  if awk -v d="$COST_DELTA" 'BEGIN{exit !(d+0 > 0.000001)}'; then
    COST_AGREES="no"
  else
    COST_AGREES="yes"
  fi
fi

# usage_block_disagrees — the preregistered criterion: yes iff any of the four
# parent usage.* token fields differs from its modelUsage-summed counterpart
# (both sides numeric); '-' when either side is unavailable.
USAGE_DISAGREES="-"
if is_num "$MU_IN" && is_num "$U_IN" && is_num "$U_OUT" && is_num "$U_CC" && is_num "$U_CR"; then
  if [ "$U_IN" = "$MU_IN" ] && [ "$U_OUT" = "$MU_OUT" ] && [ "$U_CC" = "$MU_CC" ] && [ "$U_CR" = "$MU_CR" ]; then
    USAGE_DISAGREES="no"
  else
    USAGE_DISAGREES="yes"
  fi
fi

# TOOL COUNTING — TWO GENUINELY INDEPENDENT WITNESSES (the EXP-0002/bench
# structural discipline, copied): tool_use ids in ASSISTANT events vs
# tool_result ids in USER events; disagreement is PRINTED, never reconciled.
TOOL_TSV="$(node -e '
  const fs=require("fs");
  let raw=null; try{raw=fs.readFileSync(process.argv[1],"utf8");}catch(e){}
  if(raw===null){ process.stdout.write("NOSTREAM"); process.exit(0); }
  const lines=raw.split("\n").filter(l=>l.trim()!=="");
  let invalid=0, useRaw=0, resRaw=0, userEvents=0;
  const useIds=new Set(); const resIds=new Map();
  for(const l of lines){
    let j; try{ j=JSON.parse(l) }catch(e){ invalid++; continue }
    if(j&&j.type==="user") userEvents++;
    const c=j&&j.message&&j.message.content;
    if(!Array.isArray(c)) continue;
    for(const b of c){
      if(!b) continue;
      if(j.type==="assistant"&&b.type==="tool_use"){
        useRaw++; useIds.add(b.id?String(b.id):("noid#"+useRaw));
      }
      if(j.type==="user"&&b.type==="tool_result"){
        resRaw++;
        const id=b.tool_use_id?String(b.tool_use_id):("noid#"+resRaw);
        const err=(b.is_error===true);
        resIds.set(id,(resIds.get(id)===true)||err);
      }
    }
  }
  let fails=0; for(const v of resIds.values()) if(v) fails++;
  process.stdout.write([lines.length,invalid,useRaw,useIds.size,resRaw,resIds.size,fails,userEvents].join("\t"));
' "$STREAM_LOG" 2>/dev/null)"
if [ -z "$TOOL_TSV" ] || [ "$TOOL_TSV" = "NOSTREAM" ]; then
  STREAM_LINES="unavailable"; STREAM_INVALID="unavailable"
  TOOL_USE_EVENTS="unavailable"; TOOL_RESULT_EVENTS="unavailable"
  TOOL_FAILURES="unavailable"; USER_EVENTS=0
else
  STREAM_LINES="$(printf '%s' "$TOOL_TSV" | cut -f1)"
  STREAM_INVALID="$(printf '%s' "$TOOL_TSV" | cut -f2)"
  TOOL_USE_EVENTS="$(printf '%s' "$TOOL_TSV" | cut -f4)"
  TOOL_RESULT_EVENTS="$(printf '%s' "$TOOL_TSV" | cut -f6)"
  TOOL_FAILURES="$(printf '%s' "$TOOL_TSV" | cut -f7)"
  USER_EVENTS="$(printf '%s' "$TOOL_TSV" | cut -f8)"
  if [ "$STREAM_LINES" != "0" ] && [ "$STREAM_INVALID" = "$STREAM_LINES" ]; then
    TOOL_USE_EVENTS="unavailable"; TOOL_RESULT_EVENTS="unavailable"; TOOL_FAILURES="unavailable"
  elif [ "$USER_EVENTS" = "0" ]; then
    TOOL_RESULT_EVENTS="unavailable"; TOOL_FAILURES="unavailable"
  fi
fi
if [ "$TOOL_USE_EVENTS" = "$TOOL_RESULT_EVENTS" ]; then
  TOOL_CALLS="$TOOL_USE_EVENTS"
else
  TOOL_CALLS="DISAGREE tool_use_events=$TOOL_USE_EVENTS tool_result_events=$TOOL_RESULT_EVENTS — requests and completed executions differ; REPORTED, not reconciled"
fi

# Subagent dispatch — two witnesses; the STRUCTURAL count is what close mode
# sums into consumed_subagents.
TASK_DISPATCHES_NAIVE="$(grep -oE '"name":[[:space:]]*"(Agent|Task)"' "$STREAM_LOG" 2>/dev/null | wc -l | tr -d ' ')"
TASK_DISPATCHES_STRUCT="$(node -e '
  const fs=require("fs");let n=0;
  let lines=[];try{lines=fs.readFileSync(process.argv[1],"utf8").trim().split("\n");}catch(e){}
  for(const l of lines){let j;try{j=JSON.parse(l)}catch(e){continue}
    const c=j.message&&j.message.content;
    if(Array.isArray(c)) for(const b of c)
      if(b&&b.type==="tool_use"&&(b.name==="Agent"||b.name==="Task")) n++;}
  process.stdout.write(String(n));
' "$STREAM_LOG" 2>/dev/null)"
[ -n "$TASK_DISPATCHES_STRUCT" ] || TASK_DISPATCHES_STRUCT="-"
if [ "$TASK_DISPATCHES_NAIVE" = "$TASK_DISPATCHES_STRUCT" ]; then
  TASK_DISPATCHES="$TASK_DISPATCHES_NAIVE"
else
  TASK_DISPATCHES="DISAGREE naive=$TASK_DISPATCHES_NAIVE structural=$TASK_DISPATCHES_STRUCT"
fi

# ------------------------------------------------------------------ report --
REPORT="$OUTDIR/run_record.txt"
{
  echo "# EXP-0003 routing-frontier — single task record"
  echo "experiment: EXP-0003"
  echo "harness_version: $HARNESS_VERSION"
  echo "task: $TASK"
  echo "condition: $COND  ($COND_NOTE)"
  echo "receipt: $([ "$COND" = "A" ] && echo "none — condition A has no receipt, disclosed" || echo "$RECEIPT_REL (in the work tree; filled + gated at condition close)")"
  echo "tree_state: persistent evolving work tree at $REPO — seeded once before T3, NEVER reseeded; this record is task $TASK of the condition's T3->T5 sequence; setup: $SETUP_NOTE"
  echo "starting_tree_digest: $STARTING_DIGEST"
  echo "ending_tree_digest: $ENDING_DIGEST"
  echo "pinned_seed_digest: $PIN_SEED_DIGEST (verified at seed)"
  echo "pinned_post_setup_digest: $PIN_SETUP_DIGEST (verified after scripted T1/T2)"
  echo "regression_t4_injection: $INJECTED_NOW"
  echo "task_prompt_sha256: $PROMPT_SHA   (extracted from EXP-0002's frozen tasks.md; VERIFIED equal to the preregistered pin — the runner refuses on drift)"
  echo "model_requested: ${MODEL:--(CLI default)}"
  echo "model_used: $MODEL_USED"
  echo "models_in_usage: $MU_N"
  echo "cli_version: $(claude --version 2>/dev/null | head -1)"
  echo "weekly_usage_meter: unobservable_from_this_environment"
  echo "bash_allowlist_note: scoped allowlist observed non-binding in CLI 2.1.222; permissions identical across conditions"
  echo "cli_exit: $CLI_EXIT"
  echo "is_error: $IS_ERROR"
  echo "stop_reason: $STOP_REASON"
  echo "--- machine-derived, MODELUSAGE-NATIVE primaries (the EXP-0002 usage-block defect, fixed in this runner) ---"
  echo "wall_clock_s: $WALL_S"
  echo "wall_clock_min: $WALL_MIN"
  echo "duration_api_ms: $DURATION_API_MS"
  echo "num_turns: $NUM_TURNS"
  echo "mu_input_tokens: $MU_IN"
  echo "mu_output_tokens: $MU_OUT"
  echo "mu_cache_read_tokens: $MU_CR"
  echo "mu_cache_creation_tokens: $MU_CC"
  echo "mu_total_tokens: $MU_TOTAL   (PRIMARY: input+output+cache_read+cache_creation, summed across modelUsage entries)"
  echo "mu_uncached_tokens: $MU_UNCACHED   (PRIMARY variant: total minus cache_read)"
  echo "mu_cost_usd: $MU_COST   (sum of per-model costUSD)"
  echo "total_cost_usd: $COST_USD   (provider top-level, recorded for reconciliation)"
  echo "cost_reconciliation_delta: $COST_DELTA   (|mu_cost_usd - total_cost_usd|; >1e-6 REFUSES the record)"
  echo "cost_reconciliation_agrees: $COST_AGREES"
  echo "--- the parent-loop usage.* block, recorded BESIDE the primaries, never merged ---"
  echo "usage_input_tokens: $U_IN"
  echo "usage_output_tokens: $U_OUT"
  echo "usage_cache_creation_tokens: $U_CC"
  echo "usage_cache_read_tokens: $U_CR"
  echo "usage_block_disagrees: $USAGE_DISAGREES   (yes iff any of the four differs from its modelUsage-summed counterpart; the EXP-0002 undercount signature)"
  echo "--- two-witness counts (structural JSON parse, never a grep alone) ---"
  echo "tool_calls: $TOOL_CALLS"
  echo "tool_use_events: $TOOL_USE_EVENTS   (WITNESS 1 — distinct tool_use ids in ASSISTANT events)"
  echo "tool_result_events: $TOOL_RESULT_EVENTS   (WITNESS 2 — distinct tool_use_ids answered in USER events)"
  echo "tool_failures: $TOOL_FAILURES"
  echo "stream_invalid_lines: $STREAM_INVALID of $STREAM_LINES"
  echo "subagent_dispatches: $TASK_DISPATCHES   (naive=$TASK_DISPATCHES_NAIVE structural=$TASK_DISPATCHES_STRUCT)"
  echo "subagent_dispatches_structural: $TASK_DISPATCHES_STRUCT   (what close mode sums into consumed_subagents)"
  echo "--- outcome ---"
  echo "accepted: $ACCEPTED_STR"
  echo "oracle_verdict: $FINAL_VERDICT"
  echo "seeded_suite: $SEEDED_SUITE   ('-' after T3: seeding happens once)"
  echo "post_setup_suite: $SETUP_SUITE   ('-' after T3: scripted setup happens once)"
  echo "final_suite: $FINAL_SUITE"
  echo "--- NOT machine-derivable, recorded as '-' (an unknown is not a zero) ---"
  echo "human_interventions: -"
  echo "rework: -"
  echo "defects_escaped: -"
} > "$REPORT"

# The refusal, applied AFTER the full record is assembled so the refused
# record carries every measured field: a cost contradiction is a record this
# harness will not stand behind, and it is RETAINED, labeled, as data.
if [ "$COST_AGREES" = "no" ]; then
  mv "$REPORT" "$OUTDIR/run_record.REFUSED.txt"
  {
    echo ""
    echo "REFUSED: mu_cost_usd ($MU_COST) and total_cost_usd ($COST_USD) disagree by $COST_DELTA (> 1e-6)."
    echo "A record whose two cost witnesses contradict is not sealed as evidence; it is retained here, labeled, as data."
  } >> "$OUTDIR/run_record.REFUSED.txt"
  cat "$OUTDIR/run_record.REFUSED.txt"
  die "record refused on cost reconciliation (retained at $OUTDIR/run_record.REFUSED.txt)"
fi

cat "$REPORT"
echo
echo "artifacts: $OUTDIR"
echo "work tree (persistent, do not delete until the condition's close): $REPO"
exit 0
