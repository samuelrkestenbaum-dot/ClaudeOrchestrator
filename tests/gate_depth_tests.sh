#!/usr/bin/env bash
# Build OS — gate DEPTH tests (Gravito speed lane, S3).
#
# Fan-out width is not the binding constraint on a single packet; serial DEPTH
# is. A substantive packet that runs builder -> qa -> reviewer -> fix ->
# re-review spends 5 sequential agent stages — roughly an hour of wall-clock —
# and spends that hour identically whether one packet runs or twenty. Width is
# free; depth is not.
#
# These tests pin the three structural depth reductions:
#
#   1. qa and reviewer run CONCURRENTLY by default. Both are read-only and make
#      no edits (checkable from their `tools:` frontmatter), so neither can
#      disturb what the other measures. The one real constraint — neither may
#      run while a builder is mutating the tree — must be stated, along with how
#      the orchestrator knows the tree is quiet.
#   2. A shared, DECLARED evidence contract, so the second gate does not
#      re-derive what the first measured. It lives in the agent definitions, not
#      in each hand-written brief.
#   3. A `fix-then-pass` enumerates EVERY fix at once, and its re-review is
#      TARGETED by default — with named exceptions that force a full re-gate.
#
# Plus a numeric DEPTH BUDGET per lane, stated identically wherever it is
# stated. Prose that disagrees between the entry point and the agent that must
# obey it is exactly how a rule stops being a rule, so DRIFT FAILS HERE — the
# same standard the lane table already meets in lane_enforcement_tests.sh.
#
# Nothing here weakens a gate's CONTENT: qa still reports exact counts, the
# Commit-1-isolation result and a safety grep; the reviewer still renders one
# verdict and still judges overclaiming. The target is fewer SERIAL STAGES, not
# less checking — so these tests also re-assert that content survived.
#
# No network. Deterministic. Temp dirs only. Exits non-zero if any assertion
# fails, and prints a final "==== RESULT: N passed, M failed ====" line.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ORCH="$SRC/.claude/agents/build-orchestrator.md"
BUILDER="$SRC/.claude/agents/builder.md"
QA="$SRC/.claude/agents/qa.md"
REVIEWER="$SRC/.claude/agents/reviewer.md"
REVCMD="$SRC/.claude/commands/review-packet.md"
PROJ_CLAUDE="$SRC/CLAUDE.md"
GUIDANCE="$SRC/build-os/global-claude-md.md"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }
have(){ grep -qF "$2" "$1"; }
haveE(){ grep -qE "$2" "$1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Text strictly BETWEEN a start and end sentinel (sentinels excluded).
block(){ awk -v s="$2" -v e="$3" 'index($0,s){f=1;next} index($0,e){f=0} f' "$1"; }

DEPTH_START="BUILD-OS:DEPTH:START"; DEPTH_END="BUILD-OS:DEPTH:END"
EVID_START="BUILD-OS:EVIDENCE:START"; EVID_END="BUILD-OS:EVIDENCE:END"

# Every file that is REQUIRED to state the substantive depth budget. Drift
# between any two of these is a failure, not a nit.
DEPTH_FILES=("$PROJ_CLAUDE" "$GUIDANCE" "$ORCH" "$QA" "$REVIEWER" "$BUILDER" "$REVCMD")
# The agent definitions the concurrency argument rests on.
AGENT_DEFS=("$ORCH" "$BUILDER" "$QA" "$REVIEWER")

echo "== 0. VACUITY GUARD — the scan must actually see the agent definitions =="
# Every assertion below is a grep over a set of files. If that set is empty or
# the files have moved, every one of those greps would report a cheerful PASS
# over nothing. Fail loudly first instead.
SEEN=0
for f in "${AGENT_DEFS[@]}"; do [ -s "$f" ] && SEEN=$((SEEN+1)); done
if [ "$SEEN" -ge 4 ]; then
  ok "agent-definition scan sees $SEEN non-empty definitions (>= 4, not vacuous)"
else
  no "agent-definition scan matched $SEEN of ${#AGENT_DEFS[@]} definitions (expected >= 4) — the scan has gone blind, so every assertion below is meaningless"
  for f in "${AGENT_DEFS[@]}"; do [ -s "$f" ] || echo "      | missing or empty: $f"; done
fi
DSEEN=0
for f in "${DEPTH_FILES[@]}"; do [ -s "$f" ] && DSEEN=$((DSEEN+1)); done
if [ "$DSEEN" -eq "${#DEPTH_FILES[@]}" ]; then
  ok "depth-budget scan sees all ${#DEPTH_FILES[@]} files it must compare"
else
  no "depth-budget scan sees only $DSEEN of ${#DEPTH_FILES[@]} files — a drift check over a missing file proves nothing"
fi

echo "== 1. qa and reviewer are STRUCTURALLY read-only (the property that makes concurrency safe) =="
# Two agents may only be run at the same time against one tree if neither can
# write to it. That is checkable from the frontmatter, not just the prose.
for f in "$QA" "$REVIEWER"; do
  b="$(basename "$f")"
  tline="$(grep -m1 '^tools:' "$f" || true)"
  if [ -z "$tline" ]; then
    no "$b declares no tools: line — cannot prove it is read-only"
  elif grep -qE '\b(Edit|Write|MultiEdit|NotebookEdit)\b' <<<"$tline"; then
    no "$b grants a mutating tool, so it cannot be run concurrently: $tline"
  else
    ok "$b grants no mutating tool ($tline)"
  fi
  grep -qiE "makes? no edits|no edits|never edit|you do not edit" "$f" \
    && ok "$b states in prose that it makes no edits" \
    || no "$b does not state that it makes no edits"
done

echo "== 2. Concurrency is the DOCUMENTED DEFAULT, not an incidental optimisation =="
for f in "$QA" "$REVIEWER" "$REVCMD"; do
  b="$(basename "$f")"
  if grep -qiE "concurrent|in parallel|at the same time" "$f"; then
    ok "$b mentions concurrent execution"
  else
    no "$b never mentions running qa and reviewer concurrently"
  fi
  if grep -qiE "(run|runs) (qa and reviewer |them )?concurrently by default|concurrently by default|by default.{0,40}concurrent|default.{0,60}(in parallel|concurrent)" "$f"; then
    ok "$b makes concurrency the DEFAULT (not merely permitted)"
  else
    no "$b mentions concurrency but does not make it the default"
  fi
  grep -qiE "not (two|in sequence|sequential)|rather than in sequence|instead of in sequence|one serial stage, not two" "$f" \
    && ok "$b says concurrency replaces the sequence (one stage, not two)" \
    || no "$b does not say the concurrent gates replace a sequence"
done
# The orchestrator is what actually dispatches them, so it must not still
# describe the gate pair as a sequence to be walked.
if grep -qiE "qa and (the )?reviewer .{0,40}concurrent|concurrent.{0,40}qa and (the )?reviewer|dispatch .{0,30}(qa|both) .{0,30}(concurrent|parallel)" "$ORCH"; then
  ok "build-orchestrator.md routes qa and reviewer as ONE concurrent stage"
else
  no "build-orchestrator.md does not route qa and reviewer as one concurrent stage"
fi

echo "== 3. The tree-quiet constraint — a read-only gate measuring a moving tree produces junk =="
for f in "$QA" "$REVIEWER" "$REVCMD" "$ORCH"; do
  b="$(basename "$f")"
  if grep -qiE "tree.quiet|quiet tree|moving tree|while a builder is (still )?mutating|builder is (still )?(running|mutating|in flight)" "$f"; then
    ok "$b states the tree-quiet constraint"
  else
    no "$b never states that a gate may not run against a tree a builder is mutating"
  fi
done
# It is not enough to assert the constraint; the orchestrator has to be able to
# DECIDE it. Require the concrete signals.
DEPTHTXT="$WORK/depth.orch"
block "$ORCH" "$DEPTH_START" "$DEPTH_END" > "$DEPTHTXT"
if [ -s "$DEPTHTXT" ]; then
  ok "orchestrator carries a canonical depth block"
else
  no "orchestrator has no canonical depth block ($DEPTH_START/$DEPTH_END)"
fi
grep -qiE "handed back|hand-?back|no builder .{0,20}in flight" "$DEPTHTXT" \
  && ok "tree-quiet signal 1: the builder has handed back" \
  || no "tree-quiet does not require that the builder has handed back"
grep -qF 'git status --porcelain' "$DEPTHTXT" \
  && ok "tree-quiet signal 2: git status --porcelain is checked" \
  || no "tree-quiet names no concrete working-tree check (git status --porcelain)"
grep -qiE "HEAD is stable|stable.{0,20}HEAD|rev-parse HEAD" "$DEPTHTXT" \
  && ok "tree-quiet signal 3: HEAD is pinned/stable for the gates" \
  || no "tree-quiet does not pin HEAD for the concurrent gates"
grep -qiE "gates? wait|wait|never run against a moving tree" "$DEPTHTXT" \
  && ok "tree-quiet states the consequence: the gates wait" \
  || no "tree-quiet states no consequence when the tree is not quiet"

echo "== 4. The shared evidence contract lives in the DEFINITIONS, not in each brief =="
block "$QA"       "$EVID_START" "$EVID_END" > "$WORK/evid.qa"
block "$REVIEWER" "$EVID_START" "$EVID_END" > "$WORK/evid.rev"
[ -s "$WORK/evid.qa" ]  && ok "qa.md carries the shared evidence contract"       || no "qa.md has no shared evidence contract block ($EVID_START/$EVID_END)"
[ -s "$WORK/evid.rev" ] && ok "reviewer.md carries the shared evidence contract" || no "reviewer.md has no shared evidence contract block ($EVID_START/$EVID_END)"
if [ ! -s "$WORK/evid.qa" ] || [ ! -s "$WORK/evid.rev" ]; then
  # Two empty extractions are byte-identical. That is blindness, not agreement.
  no "evidence-contract drift check is VACUOUS — one or both extractions are empty, so 'identical' would prove nothing"
elif diff -u "$WORK/evid.qa" "$WORK/evid.rev" > "$WORK/evid.diff" 2>&1; then
  ok "evidence contract is IDENTICAL in qa and reviewer (no drift)"
else
  no "evidence contract DRIFTED between qa.md and reviewer.md"
  sed -n '1,20p' "$WORK/evid.diff" | sed 's/^/      | /'
fi
grep -qiE "do not re-derive|not re-derived|never re-derive" "$WORK/evid.qa" \
  && ok "the contract forbids re-deriving the other gate's evidence" \
  || no "the contract does not forbid re-deriving the other gate's evidence"
grep -qiE "pending" "$WORK/evid.qa" \
  && ok "what you do not own is cited as PENDING, never as measured" \
  || no "the contract does not say how to cite evidence you did not produce"
# The split must actually name who owns what, or 'do not re-derive' is unusable.
for owned in "counts" "isolation" "safety grep" "verdict" "trajectory"; do
  grep -qi "$owned" "$WORK/evid.qa" && ok "evidence split names: $owned" || no "evidence split does not name: $owned"
done
grep -qiE "reconcil" "$WORK/evid.qa" \
  && ok "the orchestrator reconciles the two concurrent outputs" \
  || no "nothing says who reconciles two gates that ran without seeing each other"

echo "== 5. A fix-then-pass enumerates EVERY fix at once (installments are what cost 6 stages) =="
grep -qiE "enumerate (every|all) .{0,30}fix|every required fix at once|all .{0,20}fixes at once" "$REVIEWER" \
  && ok "reviewer.md requires every fix enumerated at once" \
  || no "reviewer.md does not require the fix list to be complete in one round"
grep -qiE "never split (a|the) fix list|do not split (a|the) fix list" "$REVIEWER" \
  && ok "reviewer.md forbids splitting a fix list across rounds" \
  || no "reviewer.md does not forbid splitting a fix list across rounds"
grep -qiE "file:line" "$REVIEWER" \
  && ok "each enumerated fix carries a file:line" \
  || no "enumerated fixes carry no file:line, so 'targeted' is unbounded"
# The builder is the other half of the installment problem: it must apply the
# whole list in ONE pass, or a complete list still costs extra stages.
grep -qiE "all .{0,30}enumerated .{0,30}(in|as) one pass|one pass|every enumerated (item|fix)" "$BUILDER" \
  && ok "builder.md applies the whole enumerated fix list in one pass" \
  || no "builder.md does not require applying the whole fix list in one pass"

echo "== 6. The fix round is CONDITIONAL and BOUNDED — targeted by default, with named exceptions =="
grep -qiE "targeted" "$REVIEWER" \
  && ok "reviewer.md makes re-review targeted" \
  || no "reviewer.md does not bound the re-review to the enumerated items"
grep -qiE "re-review only th|targeted by default|Re-review: targeted" "$REVIEWER" \
  && ok "targeted re-review is the DEFAULT, stated as such" \
  || no "targeted re-review is not stated as the default"
# The exceptions are the whole safety argument. Each must be named.
declare -a EXC_LABEL=("logic change" "count change" "outside the enumerated items" "qa RED")
declare -a EXC_RE=(
  "logic change"
  "count change|test count.{0,20}(change|move)|suite total"
  "outside the enumerated items|outside the enumerated"
  "qa (came back |is |returned )?\*{0,2}RED"
)
for i in 0 1 2 3; do
  if grep -qiE "${EXC_RE[$i]}" "$REVIEWER"; then
    ok "targeted re-review names its exception: ${EXC_LABEL[$i]}"
  else
    no "targeted re-review does not name its exception: ${EXC_LABEL[$i]}"
  fi
done
grep -qiE "comment ?/ ?doc|doc(umentation)?[ /-]only|prose text|comment/doc" "$REVIEWER" \
  && ok "the cheap case (comment/doc-only fixes) is named explicitly" \
  || no "reviewer.md never names the comment/doc-only case that the bound exists for"

echo "== 7. The DEPTH BUDGET is numeric, canonical, and identical everywhere it is stated =="
block "$PROJ_CLAUDE" "$DEPTH_START" "$DEPTH_END" > "$WORK/depth.claude"
block "$GUIDANCE"    "$DEPTH_START" "$DEPTH_END" > "$WORK/depth.guidance"
for pair in "CLAUDE.md:$WORK/depth.claude" "global-claude-md.md:$WORK/depth.guidance"; do
  b="${pair%%:*}"; p="${pair#*:}"
  [ -s "$p" ] && ok "$b carries the canonical depth block" || no "$b has no canonical depth block ($DEPTH_START/$DEPTH_END)"
done
for pair in "CLAUDE.md:$WORK/depth.claude" "global-claude-md.md:$WORK/depth.guidance"; do
  b="${pair%%:*}"; p="${pair#*:}"
  if [ ! -s "$DEPTHTXT" ] || [ ! -s "$p" ]; then
    no "depth-block drift check vs $b is VACUOUS — one or both extractions are empty"
  elif diff -u "$DEPTHTXT" "$p" > "$WORK/depth.diff" 2>&1; then
    ok "depth block is IDENTICAL in build-orchestrator.md and $b (no drift)"
  else
    no "depth block DRIFTED between build-orchestrator.md and $b"
    sed -n '1,20p' "$WORK/depth.diff" | sed 's/^/      | /'
  fi
done

# The number itself. A budget you cannot count is not a budget.
DEPTH_RE='[0-9]+ serial stages median'
MATCHED=0; NUMS=""
for f in "${DEPTH_FILES[@]}"; do
  b="$(basename "$f")"
  n="$(grep -oE "$DEPTH_RE" "$f" | head -1 | grep -oE '^[0-9]+' || true)"
  if [ -n "$n" ]; then
    MATCHED=$((MATCHED+1)); NUMS="$NUMS $b=$n"
    ok "$b states the substantive depth budget numerically ($n serial stages median)"
  else
    no "$b states no numeric substantive depth budget (expected /$DEPTH_RE/)"
  fi
done
# VACUITY GUARD for the drift comparison itself: comparing zero numbers is not
# agreement, it is blindness.
if [ "$MATCHED" -ge "${#DEPTH_FILES[@]}" ]; then
  ok "depth-number scanner matched all ${#DEPTH_FILES[@]} files (not vacuous)"
else
  no "depth-number scanner matched only $MATCHED of ${#DEPTH_FILES[@]} files — a drift check over $MATCHED numbers is meaningless"
fi
UNIQ="$(tr ' ' '\n' <<<"$NUMS" | sed '/^$/d' | cut -d= -f2 | sort -u | tr '\n' ',' | sed 's/,$//')"
if [ "$MATCHED" -gt 0 ] && [ "$UNIQ" = "2" ]; then
  ok "every file states the SAME substantive depth budget: 2 serial stages median"
else
  no "substantive depth budget DRIFTED across files — distinct values seen: [${UNIQ:-none}]; per file:$NUMS"
fi

# The stages must be named, or '2' is a number with no referent.
grep -qiE "builder" "$DEPTHTXT" && grep -qiE "qa and reviewer" "$DEPTHTXT" \
  && ok "the 2 stages are named: (1) builder, (2) qa + reviewer concurrently" \
  || no "the depth block does not name what the 2 stages are"
# Third stage is the justified exception; fourth is a defect.
grep -qiE "third (serial )?stage.{0,80}(exception|justif)|exception.{0,60}third" "$DEPTHTXT" \
  && ok "a third serial stage is the EXCEPTION and must be justified" \
  || no "the depth block does not make the third stage an exception owing a reason"
grep -qiE "fourth (serial )?stage is a defect|fourth.{0,30}defect" "$DEPTHTXT" \
  && ok "a fourth serial stage is named a DEFECT (hard cap)" \
  || no "the depth block sets no hard cap on serial stages"
grep -qiE "Depth: *3 *(—|-|:)" "$DEPTHTXT" \
  && ok "the third-stage announcement has a concrete format" \
  || no "no concrete announcement format for spending a third stage"

# THE FOURTH STAGE IS NOT UNCONDITIONALLY A DEFECT, AND THE ONE EXCEPTION IS
# NAMED RATHER THAN IMPLIED. The withdrawn version of this rule said a fourth
# stage meant only installments or a mis-cut packet. That left no legal depth at
# all for a fix list that arrived COMPLETE, in ONE installment, against a
# CORRECTLY SCOPED packet, whose contents the contract's own re-review rules
# FORBID confirming narrowly — so a packet that had done everything right was
# pushed into recording a defect it had not committed. The exception must be
# (a) named, (b) announceable, (c) CONJUNCTIVE — every condition, not any one —
# and (d) explicitly not recorded as a defect; and the defect reading must
# survive intact for every cause that really is one.
#
# These greps run over a FLATTENED copy: the block is hard-wrapped prose, and a
# line-based grep for a phrase that spans a wrap would report a cheerful miss.
DEPTHFLAT="$WORK/depth.flat"
tr '\n' ' ' < "$DEPTHTXT" | tr -s ' ' > "$DEPTHFLAT"
[ -s "$DEPTHFLAT" ] \
  && ok "the depth block flattens to a non-empty line (the phrase checks below are not vacuous)" \
  || no "the flattened depth block is empty — every phrase check below would pass over nothing"
grep -qF 'mandatory_full_regate' "$DEPTHFLAT" \
  && ok "the fourth stage's one legitimate cause is NAMED: mandatory_full_regate" \
  || no "the depth block names no legitimate cause for a fourth serial stage — a complete fix list the re-review rules forbid closing narrowly would have no legal depth"
grep -qE 'Depth: *4 *(—|-|:) *reason: *`?mandatory_full_regate' "$DEPTHFLAT" \
  && ok "the fourth-stage announcement has a concrete format naming the cause" \
  || no "no concrete announcement format for spending a fourth stage"
grep -qiE 'not\*{0,2} a defect and is not recorded as one' "$DEPTHFLAT" \
  && ok "under mandatory_full_regate depth 4 is NOT a defect and is NOT recorded as one" \
  || no "the exception never says depth 4 stops being a defect, so it exempts nothing"
grep -qiE 'when \*\*all\*\* of these hold|all of these hold|all five' "$DEPTHFLAT" \
  && ok "the exception is CONJUNCTIVE — every condition must hold, not any one" \
  || no "the exception does not require ALL its conditions, so it is a licence rather than an exception"
declare -a REG_LABEL=("complete, one-installment fix list" "correctly scoped packet" "load-bearing change" "targeted confirmation forbidden" "full concurrent re-gate required")
declare -a REG_RE=(
  "complete, in one installment|complete.{0,20}one installment"
  "correctly scoped|correctly-scoped"
  "logic, derivation, authority, counts|load-bearing behaviour"
  "forbid targeted|forbids targeted"
  "concurrent re-gate"
)
for i in 0 1 2 3 4; do
  grep -qiE "${REG_RE[$i]}" "$DEPTHFLAT" \
    && ok "mandatory_full_regate names its condition: ${REG_LABEL[$i]}" \
    || no "mandatory_full_regate does not name its condition: ${REG_LABEL[$i]}"
done
# The exception must not swallow the rule: every cause that IS a defect is still
# named as one, or "depth 4 is fine if you say the word" is what this becomes.
DEFCAUSE=0
for cause in "incomplete enumeration" "installments" "scope growth" "split before execution"; do
  grep -qiF "$cause" "$DEPTHFLAT" || { DEFCAUSE=$((DEFCAUSE+1)); echo "      | illegitimate cause of a fourth stage not named: $cause"; }
done
[ "$DEFCAUSE" -eq 0 ] \
  && ok "depth 4 REMAINS a defect for every illegitimate cause, each named" \
  || no "$DEFCAUSE illegitimate cause(s) of a fourth stage are unnamed, so the exception swallows the rule"

# Every lane gets a depth budget, as the lane table does for rounds.
for lane in read-only diagnosis tiny substantive architecture; do
  grep -qE "^\| \`$lane\` *\|" "$DEPTHTXT" \
    && ok "depth budget declared for lane: $lane" \
    || no "no depth budget declared for lane: $lane"
done

echo "== 8. Depth was cut by REMOVING SERIALISATION, not by weakening a gate =="
# The whole point is fewer serial stages, not less checking. If these regress,
# the speed win was bought with proof.
grep -qiE "exact counts|N passed, M failed" "$QA" && ok "qa still reports exact test counts"          || no "qa no longer reports exact counts"
grep -qiE "Commit-1" "$QA"                        && ok "qa still checks Commit-1 green in isolation" || no "qa no longer checks Commit-1 isolation"
grep -qiE "safety grep" "$QA"                     && ok "qa still runs the safety grep"               || no "qa no longer runs the safety grep"
grep -qiE "mutation" "$QA"                        && ok "qa still runs the mutation check"            || no "qa no longer runs the mutation check"
grep -qiE "exactly one verdict|choose exactly one" "$REVIEWER" && ok "reviewer still renders exactly one verdict" || no "reviewer no longer renders exactly one verdict"
if grep -qiE "overclaim|claims more than" "$REVIEWER"; then
  ok "reviewer still judges overclaiming"
else
  no "reviewer no longer judges overclaiming"
fi
for v in pass fix-then-pass fail; do
  grep -qF "$v" "$REVIEWER" && ok "verdict still available: $v" || no "verdict lost: $v"
done
# The command must still refuse to close on a RED qa, concurrency or not.
grep -qiE "RED" "$REVCMD" && ok "/review-packet still blocks the close on a RED qa" || no "/review-packet no longer blocks on RED"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
