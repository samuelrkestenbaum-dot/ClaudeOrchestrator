# EXP-0002 — run ONE task of one arm's sustained-workload sequence and capture
# MACHINE-DERIVED telemetry. Invoke via bash; this file is deliberately NOT
# executable.
#
# Usage:
#   bash run-exp2-task.sh --arm raw|buildos --task T1|T2|T3|T4|T5 \
#                         --workdir DIR --outdir DIR [--model NAME] \
#                         [--poll SECONDS] [--timeout SECONDS]
#
#   --workdir DIR   the arm's PERSISTENT directory. Holds DIR/repo (the ONE
#                   evolving work tree — never reseeded between tasks) and
#                   DIR/pristine (the arm baseline, captured once before T1).
#                   Use a DIFFERENT workdir per arm and the SAME workdir for
#                   all five of that arm's tasks.
#   --outdir DIR    per-task artifact directory (stream.jsonl, result.json,
#                   run_record.txt, poll.log, ...). Use a fresh one per task.
#   --poll          acceptance poll interval, seconds (default 10)
#   --timeout       hard cap on the invocation, seconds (default 3600;
#                   a timeout is a failed run and is retained)
#
# THE SEQUENCE THIS SCRIPT BELONGS TO (per arm, in order):
#   seed -> T1 -> T2 -> T3 -> inject-t4 -> T4 -> T5
# T1 performs the seed + arm setup itself (so the baseline is captured exactly
# once, before any session runs); T4 performs the injection itself when
# test/regression-t4.js is absent, and records that it did. Every task is a
# FRESH headless session; continuity exists only in the repository.
#
# ARMS. Identical task text, identical permissions; the ONLY difference is the
# installed surface:
#   raw      the seeded repo untouched (control)
#   buildos  seed + install-project.sh --no-session-hook, run BEFORE the
#            baseline copy is taken (so installer-edited files are baseline,
#            not task output)
#
# THE RULE THAT GOVERNS EVERY FIELD BELOW (bench discipline): an unknown is
# not a zero. Anything this script cannot derive by executing something is
# written "-", never 0 and never a model's own claim about itself.
#
# TREE IDENTITY. The work tree is NOT a git repository — `git -C workdir`
# has nothing to point at and no commit SHA exists. The pinned-state identity
# is a content digest (sha256 over sorted relpath+sha256 lines, the seeder's
# routine), recorded as starting_tree_digest / ending_tree_digest per task.
#
# time_to_first_correct_change RESOLUTION IS THE POLL INTERVAL: the oracle is
# executed against a COPY of the tree every --poll seconds, so the value is an
# upper bound with known granularity, derived by execution, never self-reported.
#
# Exit: 0 the run completed (accepted or not), 2 harness/precondition failure.
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SELF_DIR/../../../.." && pwd)"
SEEDER="$SELF_DIR/seed-workload-repo.sh"
ORACLE="$SELF_DIR/oracle-exp2.js"
TASKS_MD="$SELF_DIR/tasks.md"
INJECTOR="$SELF_DIR/inject-t4.sh"
MODESEL="$SELF_DIR/mode-selector.mjs"
INSTALLER="$REPO_ROOT/install-project.sh"

HARNESS_VERSION="1.0.0"
SEED_SUITE_EXPECT='TOTAL: 19 passed, 0 failed'

TASK=""; ARM=""; WORKDIR=""; OUTDIR=""; MODEL=""; POLL=10; TIMEOUT=3600

die(){ printf 'run-exp2-task: %s\n' "$*" >&2; exit 2; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --arm)     ARM="$2"; shift 2 ;;
    --task)    TASK="$2"; shift 2 ;;
    --workdir) WORKDIR="$2"; shift 2 ;;
    --outdir)  OUTDIR="$2"; shift 2 ;;
    --model)   MODEL="$2"; shift 2 ;;
    --poll)    POLL="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    -h|--help) sed -n '2,50p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

case "$TASK" in T1|T2|T3|T4|T5) ;; *) die "--task must be T1|T2|T3|T4|T5" ;; esac
case "$ARM"  in raw|buildos) ;; *) die "--arm must be raw|buildos" ;; esac
[ -n "$WORKDIR" ] || die "--workdir is required (the arm's persistent directory)"
[ -n "$OUTDIR" ]  || die "--outdir is required (per-task artifact directory)"
command -v claude >/dev/null 2>&1 || die "the claude CLI is not on PATH"
command -v node   >/dev/null 2>&1 || die "node is not on PATH"
[ -f "$SEEDER" ]   || die "missing seeder: $SEEDER"
[ -f "$ORACLE" ]   || die "missing oracle: $ORACLE"
[ -f "$TASKS_MD" ] || die "missing frozen prompts: $TASKS_MD"
[ -f "$INJECTOR" ] || die "missing injector: $INJECTOR"

mkdir -p "$OUTDIR" || die "cannot create $OUTDIR"
OUTDIR="$(cd "$OUTDIR" && pwd)"
mkdir -p "$WORKDIR" || die "cannot create $WORKDIR"
WORKDIR="$(cd "$WORKDIR" && pwd)"
REPO="$WORKDIR/repo"
PRISTINE="$WORKDIR/pristine"

# ------------------------------------------------- frozen prompt extraction --
# The prompt is EXTRACTED from tasks.md, never retyped here: the committed
# document and the sent text cannot drift apart.
PROMPT="$(awk -v task="$TASK" '
  /^## / { insec = ($2 == task); fence = 0; next }
  insec && /^```/ { fence++; if (fence == 2) exit; next }
  insec && fence == 1 { print }
' "$TASKS_MD")"
[ -n "$PROMPT" ] || die "could not extract the $TASK prompt from $TASKS_MD"

# ------------------------------------------------------- arm setup (T1 only) --
SETUP_NOTE="pre-existing work tree (task $TASK of the arm sequence)"
SEEDED_SUITE="-"
if [ ! -d "$REPO" ]; then
  [ "$TASK" = "T1" ] || die "work tree $REPO does not exist — the arm sequence starts at T1, which performs the seed"
  bash "$SEEDER" "$REPO" > "$OUTDIR/seed.txt" 2>&1 || { cat "$OUTDIR/seed.txt" >&2; die "seeding failed"; }
  SEEDED_SUITE="$(cd "$REPO" && node test/run.js 2>&1 | tail -1)"
  [ "$SEEDED_SUITE" = "$SEED_SUITE_EXPECT" ] || die "seeded suite is not at its expected state (got: $SEEDED_SUITE)"
  if [ "$ARM" = "buildos" ]; then
    [ -f "$INSTALLER" ] || die "arm buildos needs $INSTALLER"
    bash "$INSTALLER" --no-session-hook "$REPO" > "$OUTDIR/arm-install.log" 2>&1 \
      || { cat "$OUTDIR/arm-install.log" >&2; die "arm install failed"; }
  fi
  # THE BASELINE IS TAKEN AFTER ARM INSTALL, NOT BEFORE: install-project.sh
  # edits package.json and writes .gitignore, and charging those to the tasks
  # would corrupt every arm-B diff. The baseline is the tree as the FIRST
  # session first sees it. It also still carries the unfixed lib/pricing.js,
  # so it remains the correct reference for T2's pre-fix differential.
  cp -r "$REPO" "$PRISTINE"
  SETUP_NOTE="seeded now; arm surface installed; pristine baseline captured"
else
  [ -d "$PRISTINE" ] || die "$REPO exists but $PRISTINE does not — the baseline was never captured; re-start the arm from T1 in a fresh workdir"
fi

ARM_NOTE="no Build OS surface present (control)"
[ "$ARM" = "buildos" ] && ARM_NOTE="Build OS installed via install-project.sh --no-session-hook"

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

# -------------------------------------------- mode-selector (descriptive) ----
# Frozen per-task descriptors. The selector's verdict is RECORDED and then
# ignored — it routes nothing; both arms run every task identically.
case "$TASK" in
  T1) MODE_JSON='{"expected_files_changed":1,"requires_tests":false,"expected_session_count":1,"prior_context_required":false,"handoff_required":false,"consequence_level":"low"}' ;;
  T2) MODE_JSON='{"expected_files_changed":2,"requires_tests":true,"expected_session_count":1,"prior_context_required":true,"handoff_required":false,"consequence_level":"medium"}' ;;
  T3) MODE_JSON='{"expected_files_changed":5,"requires_tests":true,"expected_session_count":1,"prior_context_required":false,"handoff_required":false,"consequence_level":"medium"}' ;;
  T4) MODE_JSON='{"expected_files_changed":2,"requires_tests":true,"expected_session_count":1,"prior_context_required":true,"handoff_required":false,"consequence_level":"medium"}' ;;
  T5) MODE_JSON='{"expected_files_changed":2,"requires_tests":true,"expected_session_count":1,"prior_context_required":true,"handoff_required":false,"consequence_level":"medium"}' ;;
esac
MODE_SAYS="$(node "$MODESEL" "$MODE_JSON" 2>/dev/null)" || MODE_SAYS="-"
[ -n "$MODE_SAYS" ] || MODE_SAYS="-"

# ------------------------------------------------------------ tree identity --
STARTING_DIGEST="$(bash "$SEEDER" --digest "$REPO")" || die "could not digest the starting tree"

# ------------------------------------------------------- acceptance poller ---
# Executes the acceptance check against a COPY of the tree on an interval, so
# polling can never perturb the run; a copy caught mid-write simply fails that
# poll and is retried.
POLL_RESULT="$OUTDIR/first_accept.txt"
POLL_LOG="$OUTDIR/poll.log"
: > "$POLL_LOG"

poller(){
  local start="$1" snap verdict now
  while :; do
    sleep "$POLL"
    snap="$OUTDIR/.snap"
    rm -rf "$snap" 2>/dev/null
    cp -r "$REPO" "$snap" 2>/dev/null || continue
    verdict="$(node "$ORACLE" "$TASK" "$snap" "$PRISTINE" 2>&1)"
    if [ $? -eq 0 ]; then
      now="$(date +%s.%N)"
      awk -v a="$now" -v b="$start" 'BEGIN{printf "%.2f\n", a-b}' > "$POLL_RESULT"
      printf 'ACCEPTED at %s\n' "$(cat "$POLL_RESULT")" >> "$POLL_LOG"
      rm -rf "$snap" 2>/dev/null
      return 0
    fi
    printf '%s | %s\n' "$(date +%s)" "$verdict" >> "$POLL_LOG"
    rm -rf "$snap" 2>/dev/null
  done
}

# ------------------------------------------------------------------- invoke --
RESULT_JSON="$OUTDIR/result.json"
STREAM_LOG="$OUTDIR/stream.jsonl"
RUN_ERR="$OUTDIR/run.stderr"

# PERMISSIONS — IDENTICAL ACROSS ARMS, AND DISCLOSED HONESTLY. The scoped
# allowlist form Bash(node:*) grants real Bash execution headlessly under
# acceptEdits (the EXP-0001 invalidator, resolved). Observed and disclosed in
# every record: the scoped pattern is NON-BINDING in CLI 2.1.222 — git executed
# under Bash(node:*) without denial — so isolation comes from the detached
# scratch working tree, not the allowlist.
CLAUDE_ARGS=(-p "$PROMPT" --output-format stream-json --verbose \
             --permission-mode acceptEdits --allowedTools "Bash(node:*)")
[ -n "$MODEL" ] && CLAUDE_ARGS+=(--model "$MODEL")

START="$(date +%s.%N)"
poller "$START" &
POLLER_PID=$!

( cd "$REPO" && timeout "$TIMEOUT" claude "${CLAUDE_ARGS[@]}" ) > "$STREAM_LOG" 2> "$RUN_ERR"
CLI_EXIT=$?
END="$(date +%s.%N)"

kill "$POLLER_PID" 2>/dev/null; wait "$POLLER_PID" 2>/dev/null
rm -rf "$OUTDIR/.snap" 2>/dev/null

WALL_S="$(awk -v a="$END" -v b="$START" 'BEGIN{printf "%.2f", a-b}')"
WALL_MIN="$(awk -v s="$WALL_S" 'BEGIN{printf "%.2f", s/60}')"

ENDING_DIGEST="$(bash "$SEEDER" --digest "$REPO")" || ENDING_DIGEST="-"

# The final stream event of a stream-json run is the same result object that
# --output-format json emits on its own; pulling it from the stream buys a
# full tool-use trace in the same artifact.
grep '"type":"result"' "$STREAM_LOG" | tail -1 > "$RESULT_JSON" 2>/dev/null
[ -s "$RESULT_JSON" ] || printf '{}' > "$RESULT_JSON"

# ------------------------------------------------------------ final verdict --
FINAL_VERDICT="$(node "$ORACLE" "$TASK" "$REPO" "$PRISTINE" 2>&1)"
ACCEPTED=$?
if [ "$ACCEPTED" -eq 0 ]; then ACCEPTED_STR="yes"; else ACCEPTED_STR="no"; fi

TTFCC="-"
[ -s "$POLL_RESULT" ] && TTFCC="$(cat "$POLL_RESULT")"
# Accepted at the end but never caught accepting by a poll = finished inside
# one poll interval. Report the bound, do not invent a number.
if [ "$TTFCC" = "-" ] && [ "$ACCEPTED_STR" = "yes" ]; then
  TTFCC="<=$WALL_S"
fi

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
IN_TOK="$(jq_get usage.input_tokens)"
OUT_TOK="$(jq_get usage.output_tokens)"
CC_TOK="$(jq_get usage.cache_creation_input_tokens)"
CR_TOK="$(jq_get usage.cache_read_input_tokens)"
IS_ERROR="$(jq_get is_error)"
STOP_REASON="$(jq_get stop_reason)"

# Context size and the model actually used come from modelUsage, keyed by
# model name — read structurally, never guessed.
MODEL_USED="$(node -e '
  const fs=require("fs");let j={};try{j=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));}catch(e){}
  const mu=j.modelUsage||{};const keys=Object.keys(mu);
  process.stdout.write(keys.length?keys.join("+"):"-");
' "$RESULT_JSON")"
CONTEXT_WINDOW="$(node -e '
  const fs=require("fs");let j={};try{j=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));}catch(e){}
  const mu=j.modelUsage||{};let m=0;
  for(const k of Object.keys(mu)) m=Math.max(m, mu[k].contextWindow||0);
  process.stdout.write(m?String(m):"-");
' "$RESULT_JSON")"

PERM_DENIALS="$(node -e '
  const fs=require("fs");let j={};try{j=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));}catch(e){}
  const d=j.permission_denials||[];
  process.stdout.write(d.length?d.length+" ("+[...new Set(d.map(x=>x.tool_name))].join(",")+")":"0");
' "$RESULT_JSON")"

# TOOL COUNTING — TWO GENUINELY INDEPENDENT WITNESSES (the bench/run-corpus.sh
# discipline, RULING 3):
#   WITNESS 1  tool_use_events    structural JSON parse (never a grep):
#                                 distinct tool_use block ids in ASSISTANT
#                                 events — tool REQUESTS the model made.
#   WITNESS 2  tool_result_events independently derived from the OTHER side of
#                                 the protocol: distinct tool_use_ids answered
#                                 by a tool_result block in USER events (emitted
#                                 by the CLI's executor, not the model) —
#                                 COMPLETED executions reported back.
# The two measure DIFFERENT CONCEPTS and are not required to be equal; a
# disagreement is PRINTED, never reconciled. Invalid lines are reported, never
# silently skipped. A stream with no user events has no tool_result channel:
# unavailable, NEVER zero.
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
  TOOL_USE_RAW="unavailable"; TOOL_USE_EVENTS="unavailable"
  TOOL_RESULT_RAW="unavailable"; TOOL_RESULT_EVENTS="unavailable"
  TOOL_FAILURES="unavailable"; USER_EVENTS=0
else
  STREAM_LINES="$(printf '%s' "$TOOL_TSV" | cut -f1)"
  STREAM_INVALID="$(printf '%s' "$TOOL_TSV" | cut -f2)"
  TOOL_USE_RAW="$(printf '%s' "$TOOL_TSV" | cut -f3)"
  TOOL_USE_EVENTS="$(printf '%s' "$TOOL_TSV" | cut -f4)"
  TOOL_RESULT_RAW="$(printf '%s' "$TOOL_TSV" | cut -f5)"
  TOOL_RESULT_EVENTS="$(printf '%s' "$TOOL_TSV" | cut -f6)"
  TOOL_FAILURES="$(printf '%s' "$TOOL_TSV" | cut -f7)"
  USER_EVENTS="$(printf '%s' "$TOOL_TSV" | cut -f8)"
  # A stream in which EVERY line failed to parse establishes nothing: refuse
  # the counts rather than report a confident zero derived from garbage.
  if [ "$STREAM_LINES" != "0" ] && [ "$STREAM_INVALID" = "$STREAM_LINES" ]; then
    TOOL_USE_RAW="unavailable"; TOOL_USE_EVENTS="unavailable"
    TOOL_RESULT_RAW="unavailable"; TOOL_RESULT_EVENTS="unavailable"
    TOOL_FAILURES="unavailable"
  elif [ "$USER_EVENTS" = "0" ]; then
    TOOL_RESULT_RAW="unavailable"; TOOL_RESULT_EVENTS="unavailable"
    TOOL_FAILURES="unavailable"
  fi
fi
if [ "$TOOL_USE_EVENTS" = "$TOOL_RESULT_EVENTS" ]; then
  TOOL_CALLS="$TOOL_USE_EVENTS"
else
  TOOL_CALLS="DISAGREE tool_use_events=$TOOL_USE_EVENTS tool_result_events=$TOOL_RESULT_EVENTS — requests and completed executions differ; the gap is denied/failed/unreported calls and is REPORTED, not reconciled"
fi

# Subagent dispatch: the tool is named `Agent` in CLI 2.1.222 (was `Task`);
# both names matched, plus a name-agnostic subagent_type witness.
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

SUBAGENT_TYPES="$(grep -oE '"subagent_type":[[:space:]]*"[A-Za-z0-9_-]*"' "$STREAM_LOG" 2>/dev/null | sort -u | tr '\n' ',' | sed 's/,$//')"
[ -n "$SUBAGENT_TYPES" ] || SUBAGENT_TYPES="-"

# Cumulative divergence from the ARM BASELINE (not from the previous task —
# per-task deltas are recoverable from consecutive tree digests). Arm-surface
# paths are excluded for the reason the oracle names.
DIFFSTAT="$(diff -ru --exclude=.git --exclude=node_modules --exclude=.claude \
                --exclude=build-os --exclude=CLAUDE.md --exclude=.gitignore \
                "$PRISTINE" "$REPO" 2>/dev/null \
  | awk '/^\+[^+]/{i++} /^-[^-]/{d++} END{printf "%d %d", i+0, d+0}')"
INSERTIONS="$(printf '%s' "$DIFFSTAT" | awk '{print $1}')"
DELETIONS="$(printf '%s' "$DIFFSTAT" | awk '{print $2}')"

FILES_CHANGED="$(node -e '
  const fs=require("fs"),path=require("path");
  const SKIP=/^(\.claude(\/|$)|build-os(\/|$)|CLAUDE\.md$|\.mcp\.json$|\.gitignore$)/;
  const list=(root)=>{const acc=[];const walk=(d,rel)=>{
    for(const e of fs.readdirSync(path.join(root,d),{withFileTypes:true})){
      const r=rel?rel+"/"+e.name:e.name;
      if(e.name===".git"||e.name==="node_modules"||SKIP.test(r))continue;
      if(e.isDirectory())walk(path.join(d,e.name),r);else acc.push(r);} };
    walk(".","");return acc;};
  const [a,b]=[process.argv[1],process.argv[2]];
  const sb=new Set(list(b));let n=0;
  for(const f of list(a)){ if(!sb.has(f)){n++;continue;}
    if(!fs.readFileSync(path.join(a,f)).equals(fs.readFileSync(path.join(b,f))))n++; }
  process.stdout.write(String(n));
' "$REPO" "$PRISTINE")"

# ------------------------------------------------------------------ report --
REPORT="$OUTDIR/run_record.txt"
{
  echo "# EXP-0002 sustained-workload — single task record"
  echo "experiment: EXP-0002"
  echo "harness_version: $HARNESS_VERSION"
  echo "task: $TASK"
  echo "arm: $ARM  ($ARM_NOTE)"
  echo "tree_state: persistent evolving work tree at $REPO — seeded once before T1, NEVER reseeded between tasks; this record is task $TASK of the arm's T1->T5 sequence; setup: $SETUP_NOTE"
  echo "tree_identity: content digests (the work tree is not a git repo; no commit SHA exists)"
  echo "starting_tree_digest: $STARTING_DIGEST"
  echo "ending_tree_digest: $ENDING_DIGEST"
  echo "pristine_baseline: $PRISTINE (captured once, after arm setup, before T1's session)"
  echo "regression_t4_injection: $INJECTED_NOW"
  echo "mode_selector_says: $MODE_SAYS   (DESCRIPTIVE ONLY — recorded, routed nothing; both arms ran this task identically)"
  echo "task_prompt_sha256: $(printf '%s' "$PROMPT" | sha256sum | cut -d' ' -f1)   (extracted from tasks.md; identical across arms by construction)"
  echo "model_requested: ${MODEL:--(CLI default)}"
  echo "model_used: $MODEL_USED"
  echo "context_window: $CONTEXT_WINDOW"
  echo "cli_version: $(claude --version 2>/dev/null | head -1)"
  echo "weekly_usage_meter: unobservable_from_this_environment"
  echo "bash_allowlist_note: scoped allowlist observed non-binding in CLI 2.1.222 (git executed under Bash(node:*)); permissions identical across arms"
  echo "cli_exit: $CLI_EXIT"
  echo "is_error: $IS_ERROR"
  echo "stop_reason: $STOP_REASON"
  echo "--- machine-derived ---"
  echo "wall_clock_s: $WALL_S"
  echo "wall_clock_min: $WALL_MIN"
  echo "duration_api_ms: $DURATION_API_MS"
  echo "num_turns (model calls): $NUM_TURNS"
  echo "total_cost_usd: $COST_USD"
  echo "input_tokens: $IN_TOK"
  echo "output_tokens: $OUT_TOK"
  echo "cache_creation_input_tokens: $CC_TOK"
  echo "cache_read_input_tokens: $CR_TOK"
  echo "permission_denials: $PERM_DENIALS   (A FLOOR, NOT A COUNT — the array can undercount denied tool_use blocks)"
  echo "tool_calls: $TOOL_CALLS"
  echo "tool_use_events: $TOOL_USE_EVENTS   (WITNESS 1 — structural JSON parse: distinct tool_use block ids in ASSISTANT events; measures tool REQUESTS the model made; raw blocks=$TOOL_USE_RAW, duplicates counted once by id)"
  echo "tool_result_events: $TOOL_RESULT_EVENTS   (WITNESS 2 — independently derived from USER events emitted by the tool executor: distinct tool_use_ids answered by a tool_result; measures COMPLETED executions reported back; raw blocks=$TOOL_RESULT_RAW)"
  echo "tool_failures: $TOOL_FAILURES   (tool_result blocks with is_error=true, by id; 'unavailable' when the stream carries no tool_result channel)"
  echo "stream_invalid_lines: $STREAM_INVALID of $STREAM_LINES   (lines that failed JSON parse — REPORTED, never silently skipped; if all lines are invalid the counts above are refused as unavailable)"
  echo "subagent_dispatches (Agent|Task): $TASK_DISPATCHES   (naive=$TASK_DISPATCHES_NAIVE structural=$TASK_DISPATCHES_STRUCT)"
  echo "subagent_types_seen: $SUBAGENT_TYPES"
  echo "files_changed_vs_arm_baseline (task files only, cumulative across the sequence so far): $FILES_CHANGED"
  echo "insertions_vs_arm_baseline: $INSERTIONS"
  echo "deletions_vs_arm_baseline: $DELETIONS"
  echo "time_to_first_correct_change_s: $TTFCC   (poll resolution ${POLL}s)"
  echo "accepted: $ACCEPTED_STR"
  echo "oracle_verdict: $FINAL_VERDICT"
  echo "seeded_suite: $SEEDED_SUITE   ('-' after T1: seeding happens once, before T1 only)"
  echo "final_suite: $FINAL_SUITE"
  echo "--- NOT machine-derivable, recorded as '-' (an unknown is not a zero) ---"
  echo "human_interventions: -   (unattended by construction; no operator was present to observe any)"
  echo "rework: -                (not decidable from the final tree; a model's own account of its rework is a self-report)"
  echo "defects_escaped: -       (counted only while someone keeps looking; nobody did after this run)"
} > "$REPORT"

cat "$REPORT"
echo
echo "artifacts: $OUTDIR"
echo "work tree (persistent, do not delete until the arm's T5 closes): $REPO"
exit 0
