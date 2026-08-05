#!/usr/bin/env bash
# Build OS — run ONE corpus task, ONE arm, and capture MACHINE-DERIVED metrics.
#
# WHAT THIS IS NOT. It is not the pre-registered A/B in
# build-os/metrics/COMPARISON_PROTOCOL.md. That design is 16 runs across two
# arms with a HUMAN OPERATOR holding the clock, explicitly not an agent. This
# script runs one task, one arm, once. See build-os/bench/BASELINE_LIMITS.md.
#
# THE RULE THAT GOVERNS EVERY FIELD BELOW: an unknown is not a zero. Anything
# this script cannot derive by executing something is written "-", never 0 and
# never a model's own claim about itself. record-packet.sh enforces the same
# distinction and says why: "0 is a measurement and '-' is an admission."
#
# WHAT IS MACHINE-DERIVED (trustworthy):
#   wall_clock_s              this script's own clock around the invocation
#   duration_api_ms           from the CLI result JSON
#   num_turns                 from the CLI result JSON  (= "model calls")
#   total_cost_usd            from the CLI result JSON
#   input/output/cache tokens from the CLI result JSON usage block
#   context_window            from the CLI result JSON modelUsage block
#   time_to_first_correct_change_s
#                             POLLED: a hidden oracle is run against a COPY of
#                             the tree every --poll seconds, and the first poll
#                             that accepts stamps the time. Derived by executing
#                             the acceptance check, never self-reported.
#   accepted                  the final hidden-oracle verdict
#
# WHAT IS DELIBERATELY NOT DERIVED (recorded "-"):
#   human_interventions       nobody was watching; this is an operator
#                             observation and there was no operator. Not 0.
#   rework                    would require classifying which edits existed only
#                             to repair a previous edit. Not decidable from the
#                             tree alone, and a model's own account of its
#                             rework is exactly the self-report this excludes.
#   defects_escaped           counted only for as long as someone keeps looking,
#                             and nobody kept looking after the run.
#
# time_to_first_correct_change RESOLUTION IS THE POLL INTERVAL. A value of 30
# means "accepted at or before 30s and after 25s" at --poll 5. It is an upper
# bound with a known granularity, and it is reported as such rather than
# pretending to sub-second precision it does not have.
#
# Usage:
#   run-corpus.sh --task T1|T2|T3|T4 --arm buildos|raw --run N [options]
# Options:
#   --poll SECONDS     acceptance poll interval (default 10)
#   --timeout SECONDS  hard cap on the invocation (default 3600)
#   --outdir DIR       where to write artifacts (default: a mktemp dir)
#   --model NAME       passed through to the CLI; recorded in the result
#   --keep             do not delete the working tree on exit
# Exit: 0 the run completed (accepted or not), 2 harness/precondition failure.
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SELF_DIR/../.." && pwd)"
SEEDER="$SELF_DIR/seed-bench-repo.sh"
ORACLE="$SELF_DIR/oracles/oracle.js"
INSTALLER="$REPO_ROOT/install-project.sh"

CORPUS_VERSION="1.0.0"
INSTANCE_VERSION="1.0.0"

TASK=""; ARM=""; RUNNO=""; POLL=10; TIMEOUT=3600; OUTDIR=""; MODEL=""; KEEP=0

die(){ printf 'run-corpus: %s\n' "$*" >&2; exit 2; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --task)    TASK="$2"; shift 2 ;;
    --arm)     ARM="$2"; shift 2 ;;
    --run)     RUNNO="$2"; shift 2 ;;
    --poll)    POLL="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    --outdir)  OUTDIR="$2"; shift 2 ;;
    --model)   MODEL="$2"; shift 2 ;;
    --keep)    KEEP=1; shift ;;
    -h|--help) sed -n '2,60p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

case "$TASK" in T1|T2|T3|T4) ;; *) die "--task must be T1|T2|T3|T4" ;; esac
case "$ARM"  in buildos|raw) ;; *) die "--arm must be buildos|raw" ;; esac
[ -n "$RUNNO" ] || die "--run is required (the run number goes in the recorded note)"
command -v claude >/dev/null 2>&1 || die "the claude CLI is not on PATH"
command -v node   >/dev/null 2>&1 || die "node is not on PATH"
[ -x "$SEEDER" ] || [ -f "$SEEDER" ] || die "missing seeder: $SEEDER"
[ -f "$ORACLE" ] || die "missing oracle: $ORACLE"

[ -n "$OUTDIR" ] || OUTDIR="$(mktemp -d)"
mkdir -p "$OUTDIR" || die "cannot create $OUTDIR"
OUTDIR="$(cd "$OUTDIR" && pwd)"

WORK="$OUTDIR/work"
REPO="$WORK/repo"
PRISTINE="$WORK/pristine"
rm -rf "$WORK"; mkdir -p "$WORK"

# ----------------------------------------------------------------- the task --
# THE TASK TEXT IS FROZEN HERE AND IS IDENTICAL ACROSS ARMS. Constant #1 of the
# protocol requires the task text to be verbatim and pinned. The wording below
# restates the corpus shape against the frozen instance, and it is deliberately
# NOT tuned: no hints, no "think step by step", no mention of the oracle, no
# mention of which files to touch beyond what the frozen instance documents
# already say. Tuning the prompt would be optimising for the benchmark, which is
# the one thing this baseline exists not to do.
case "$TASK" in
  T1) PROMPT='This project has exactly one code comment that contains a factual error. Find it and correct it. Do not change any behaviour, and do not change the tests.' ;;
  T2) PROMPT='There is a bug in this project'"'"'s statistics code. Write a test that fails because of it first, confirm it fails for the right reason, then fix the bug and confirm the test passes. The full test suite must be green when you are done.' ;;
  T3) PROMPT='Implement the feature request in SPEC-T3.md. Follow the specification exactly, including its worked examples and error cases. The full test suite must be green when you are done.' ;;
  T4) PROMPT='TASKS-T4.md describes three independent work items with a disjoint file-ownership manifest. Complete all three, respecting the manifest, then run the full test suite once as a single post-merge verification. It must be green.' ;;
esac

# --------------------------------------------------------------------- seed --
bash "$SEEDER" "$REPO" > "$OUTDIR/seed.txt" 2>&1 || { cat "$OUTDIR/seed.txt" >&2; die "seeding failed"; }
TREE_DIGEST="$(grep '^tree_digest_sha256: ' "$OUTDIR/seed.txt" | awk '{print $2}')"

# The seeded suite must be green BEFORE the run, or nothing measured after it
# means anything. T2's defect is latent (deliberately untested), so the seeded
# state is fully green and this check is exact, not approximate.
SEED_SUITE="$(cd "$REPO" && node test/run.js 2>&1 | tail -1)"
case "$SEED_SUITE" in
  'TOTAL: 14 passed, 0 failed') ;;
  *) die "seeded suite is not at its expected state (got: $SEED_SUITE)" ;;
esac

# ---------------------------------------------------------------- arm setup --
# arm B (buildos) = the product actually installed, via its own shipped
#                   installer. Not a hand-rolled approximation of it.
# arm A (raw)     = the seeded repo untouched: no CLAUDE.md, no .claude/,
#                   no lanes, no router, no packets. This is the protocol's
#                   own definition of the control arm.
ARM_NOTE=""
if [ "$ARM" = "buildos" ]; then
  [ -f "$INSTALLER" ] || die "arm buildos needs $INSTALLER"
  bash "$INSTALLER" --no-session-hook "$REPO" > "$OUTDIR/arm-install.log" 2>&1 \
    || { cat "$OUTDIR/arm-install.log" >&2; die "arm install failed"; }
  ARM_NOTE="Build OS installed via install-project.sh --no-session-hook"
else
  ARM_NOTE="no Build OS surface present (control)"
fi

# THE DIFF BASELINE IS TAKEN AFTER ARM INSTALL, NOT BEFORE, AND THIS MATTERS.
# install-project.sh does not only add .claude/ and build-os/ — it also EDITS
# package.json (adding a test:build-os-memory script) and writes .gitignore.
# Diffing the finished tree against the pre-install seed therefore charges the
# task with 2 files it never touched, which would inflate T3's file count and
# make every arm-B T4 run look like it breached its ownership manifest. The
# baseline is the tree as the model FIRST SEES IT.
#
# This copy also still carries the unfixed stats.js, so it remains the correct
# reference for T2's pre-fix differential.
cp -r "$REPO" "$PRISTINE"

# ------------------------------------------------------- acceptance poller ---
# Derives time_to_first_correct_change by EXECUTING the acceptance check against
# a COPY of the tree, on an interval. Copying first means the poller can never
# perturb what the model is doing, and a copy caught mid-write simply fails that
# poll and is retried on the next one.
POLL_RESULT="$OUTDIR/first_accept.txt"
POLL_LOG="$OUTDIR/poll.log"
: > "$POLL_LOG"

poller(){
  local start="$1" snap verdict now
  while :; do
    sleep "$POLL"
    snap="$WORK/snap"
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

# ------------------------------------------------- runnability precondition --
# THE HARNESS REFUSES TO PRODUCE A NUMBER IT CANNOT STAND BEHIND.
#
# T2, T3 and T4 all require the agent to execute the project's test command:
#   T2 "confirm it fails for the right reason ... confirm it passes"
#   T3 "the full test suite must be green when you are done"
#   T4 "one post-merge verification"
# With the Bash tool denied (see the permission note above) none of those clauses
# can be satisfied by the agent. Running them anyway would yield a wall-clock and
# a token count that LOOK like corpus results and are not, because the task
# performed was not the task the corpus specifies.
#
# This gate is in the script rather than in a runbook because a rule that has to
# be REMEMBERED is a rule that gets skipped on the day someone wants a number.
# --i-accept-a-degraded-run exists only so that a future environment that does
# grant Bash can proceed; it prints what it is doing.
BASH_TOOL_AVAILABLE="${BENCH_BASH_TOOL:-no}"
NEEDS_SUITE=0
case "$TASK" in T2|T3|T4) NEEDS_SUITE=1 ;; esac

if [ "$NEEDS_SUITE" -eq 1 ] && [ "$BASH_TOOL_AVAILABLE" != "yes" ] && [ "${FORCE_DEGRADED:-0}" != "1" ]; then
  {
    echo "# Build OS bench — single run record"
    echo "corpus_version: $CORPUS_VERSION"
    echo "instance_version: $INSTANCE_VERSION"
    echo "tree_digest_sha256: $TREE_DIGEST"
    echo "task: $TASK"
    echo "arm: $ARM  ($ARM_NOTE)"
    echo "run: $RUNNO"
    echo "cli_version: $(claude --version 2>/dev/null | head -1)"
    echo "status: IMPOSSIBLE — NOT RUN, NO NUMBERS PRODUCED"
    echo "reason: $TASK requires the agent to execute the project's test command."
    echo "        The CLI denies the Bash tool under --permission-mode acceptEdits,"
    echo "        and --permission-mode bypassPermissions is refused outright when the"
    echo "        CLI runs as root. The agent therefore cannot run the suite, so the"
    echo "        corpus's own 'Do'/'Done when' clauses for this task cannot be met."
    echo "wall_clock_s: -"
    echo "num_turns: -"
    echo "total_cost_usd: -"
    echo "input_tokens: -"
    echo "output_tokens: -"
    echo "cache_creation_input_tokens: -"
    echo "cache_read_input_tokens: -"
    echo "time_to_first_correct_change_s: -"
    echo "accepted: -"
    echo "note: a degraded run would produce numbers that look comparable to a real"
    echo "      corpus run and are not. No row is recorded for this task."
  } | tee "$OUTDIR/run_record.txt"
  [ "$KEEP" -eq 0 ] && rm -rf "$WORK"
  echo
  echo "artifacts: $OUTDIR"
  exit 0
fi

# ------------------------------------------------------------------- invoke --
RESULT_JSON="$OUTDIR/result.json"
STREAM_LOG="$OUTDIR/stream.jsonl"
RUN_ERR="$OUTDIR/run.stderr"

# PERMISSION MODE, AND THE CAPABILITY THIS HARNESS CANNOT GRANT.
#
# `bypassPermissions` / `--dangerously-skip-permissions` are REFUSED outright
# when the CLI runs as root: "cannot be used with root/sudo privileges for
# security reasons". Verified, exit 1 in 0.91s.
#
# `acceptEdits` works: Read/Write/Edit/Glob/Grep all function, and file edits
# are auto-accepted. But the **Bash tool is DENIED** under it — verified
# directly, with the denial recorded in the result JSON's `permission_denials`
# array. Attempting to widen this with `--allowedTools Bash` is itself blocked
# by the environment's auto-mode classifier at the caller.
#
# CONSEQUENCE, STATED PLAINLY BECAUSE IT INVALIDATES THREE OF THE FOUR TASKS:
# the agent under test CANNOT RUN THE PROJECT'S TEST COMMAND. Any corpus task
# whose "Do" or "Done when" clause requires executing the suite cannot be
# performed as the corpus defines it. Those tasks are recorded IMPOSSIBLE rather
# than run in a degraded form — see BASELINE_LIMITS.md. A degraded run is worse
# than no run, because it produces a number that looks comparable and is not.
CLAUDE_ARGS=(-p "$PROMPT" --output-format stream-json --verbose --permission-mode acceptEdits)
[ -n "$MODEL" ] && CLAUDE_ARGS+=(--model "$MODEL")

START="$(date +%s.%N)"
poller "$START" &
POLLER_PID=$!

( cd "$REPO" && timeout "$TIMEOUT" claude "${CLAUDE_ARGS[@]}" ) > "$STREAM_LOG" 2> "$RUN_ERR"
CLI_EXIT=$?
END="$(date +%s.%N)"

kill "$POLLER_PID" 2>/dev/null; wait "$POLLER_PID" 2>/dev/null

WALL_S="$(awk -v a="$END" -v b="$START" 'BEGIN{printf "%.2f", a-b}')"
WALL_MIN="$(awk -v s="$WALL_S" 'BEGIN{printf "%.2f", s/60}')"

# The final stream event of a --output-format stream-json run is the same result
# object that --output-format json emits on its own. Pulling it from the stream
# costs nothing and buys a full tool-use trace in the same artifact.
grep '"type":"result"' "$STREAM_LOG" | tail -1 > "$RESULT_JSON" 2>/dev/null
[ -s "$RESULT_JSON" ] || printf '{}' > "$RESULT_JSON"

# ------------------------------------------------------------ final verdict --
FINAL_VERDICT="$(node "$ORACLE" "$TASK" "$REPO" "$PRISTINE" 2>&1)"
ACCEPTED=$?
if [ "$ACCEPTED" -eq 0 ]; then ACCEPTED_STR="yes"; else ACCEPTED_STR="no"; fi

TTFCC="-"
[ -s "$POLL_RESULT" ] && TTFCC="$(cat "$POLL_RESULT")"
# A run that is accepted at the end but was never caught accepting by a poll
# finished inside one poll interval. Report the bound, do not invent a number.
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

# Context size and the model string actually used come from modelUsage, which is
# keyed by model name, so it is read structurally rather than guessed.
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

# Tool-use trace: how many tool calls, and whether subagent dispatch ever fired.
# The second is the direct test of COMPARISON_PROTOCOL.md's second stated
# blocker, "agent invocations are not addressable from a harness".
#
# THE DISPATCH TOOL IS NAMED `Agent`, NOT `Task`, IN CLI 2.1.222. An earlier
# version of the line below grepped only for "Task" and would have reported 0
# dispatches for a run that had in fact dispatched a subagent successfully —
# i.e. it would have "confirmed" the protocol's blocker by measuring the wrong
# string. Both names are matched so the count survives a rename, and
# `subagent_type` is captured independently as a second, name-agnostic witness.
PERM_DENIALS="$(node -e '
  const fs=require("fs");let j={};try{j=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));}catch(e){}
  const d=j.permission_denials||[];
  process.stdout.write(d.length?d.length+" ("+[...new Set(d.map(x=>x.tool_name))].join(",")+")":"0");
' "$RESULT_JSON")"

TOOL_CALLS="$(grep -o '"type":"tool_use"' "$STREAM_LOG" 2>/dev/null | wc -l | tr -d ' ')"
TASK_DISPATCHES="$(grep -oE '"name":"(Agent|Task)"' "$STREAM_LOG" 2>/dev/null | wc -l | tr -d ' ')"
SUBAGENT_TYPES="$(grep -o '"subagent_type":"[a-z-]*"' "$STREAM_LOG" 2>/dev/null | sort -u | tr '\n' ',' | sed 's/,$//')"
[ -n "$SUBAGENT_TYPES" ] || SUBAGENT_TYPES="-"

# Line-level diffstat against the arm baseline. Captured BEFORE the working tree
# is cleaned up: run 1 of T1 lost these figures to cleanup and they had to be
# reconstructed afterwards from the preserved stream log, which worked only
# because that run happened to make a single Edit. Derive them here instead.
DIFFSTAT="$(diff -ru --exclude=.git --exclude=node_modules --exclude=.claude \
                --exclude=build-os --exclude=CLAUDE.md --exclude=.gitignore \
                "$PRISTINE" "$REPO" 2>/dev/null \
  | awk '/^\+[^+]/{i++} /^-[^-]/{d++} END{printf "%d %d", i+0, d+0}')"
INSERTIONS="$(printf '%s' "$DIFFSTAT" | awk '{print $1}')"
DELETIONS="$(printf '%s' "$DIFFSTAT" | awk '{print $2}')"

FILES_CHANGED="$(node -e '
  const fs=require("fs"),path=require("path");
  const SKIP=/^(\.claude(\/|$)|build-os(\/|$)|CLAUDE\.md$|\.mcp\.json$)/;
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
  echo "# Build OS bench — single run record"
  echo "corpus_version: $CORPUS_VERSION"
  echo "instance_version: $INSTANCE_VERSION"
  echo "tree_digest_sha256: $TREE_DIGEST"
  echo "task: $TASK"
  echo "arm: $ARM  ($ARM_NOTE)"
  echo "run: $RUNNO"
  echo "cli_version: $(claude --version 2>/dev/null | head -1)"
  echo "model_requested: ${MODEL:--(CLI default)}"
  echo "model_used: $MODEL_USED"
  echo "context_window: $CONTEXT_WINDOW"
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
  echo "permission_denials: $PERM_DENIALS"
  echo "tool_calls: $TOOL_CALLS"
  echo "subagent_dispatches (Agent|Task): $TASK_DISPATCHES"
  echo "subagent_types_seen: $SUBAGENT_TYPES"
  echo "files_changed (task files only): $FILES_CHANGED"
  echo "insertions: $INSERTIONS"
  echo "deletions: $DELETIONS"
  echo "time_to_first_correct_change_s: $TTFCC   (poll resolution ${POLL}s)"
  echo "accepted: $ACCEPTED_STR"
  echo "oracle_verdict: $FINAL_VERDICT"
  echo "seeded_suite: $SEED_SUITE"
  echo "final_suite: $FINAL_SUITE"
  echo "--- NOT machine-derivable, recorded as '-' (an unknown is not a zero) ---"
  echo "human_interventions: -   (no operator was present to observe any)"
  echo "rework: -                (not decidable from the final tree; a model's own account of its rework is a self-report)"
  echo "defects_escaped: -       (counted only while someone keeps looking; nobody did after this run)"
} > "$REPORT"

cat "$REPORT"

if [ "$KEEP" -eq 0 ]; then rm -rf "$WORK"; else echo; echo "tree kept at: $REPO"; fi
echo
echo "artifacts: $OUTDIR"
exit 0
