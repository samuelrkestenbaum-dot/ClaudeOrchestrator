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

echo "== 9. The COMMIT BUDGET is the same RULE on every surface that governs it =="
# WHY THIS SECTION EXISTS. The depth budget has the three-way mirror above; the
# COMMIT budget had NOTHING. `<=2 commits per packet` was withdrawn as
# unsatisfiable in CLAUDE.md and its global mirror, and README.md — under a
# heading reading "Safety gates (non-negotiable)" — went on asserting it. A
# green suite of well over two thousand assertions said nothing, because not one
# of them looked. Doctrine enforced by writing rather than by machinery is the
# exact failure the withdrawal was written to fix, so the guard lives in the
# file that already owns cross-file doctrine consistency rather than in a new
# suite nobody chains.
#
# WHY NOT BYTE-IDENTITY, THE MECHANISM SECTION 7 USES. The depth block is ONE
# canonical text carried verbatim between sentinels, so `diff` is exactly right
# there. The commit budget is not that shape and cannot be made into it without
# damage: CLAUDE.md states it in a paragraph plus a five-item sub-list because
# the fix commit is defined by what it may NOT do; global-claude-md.md
# compresses the same rule to one paragraph for a reader who has no packet in
# flight; README.md gives an operator a single line under the safety gates;
# bandwidth-check.sh states it as a shell constant that must also disclaim what
# the number does not mean; control_registry.txt states it inside a census note
# arguing its own class. Byte-identity across those five is not achievable, and
# forcing it would mean making four audiences read the contract's wording — the
# very thing derived restatements exist to avoid. So this compares the RULE, not
# the PROSE: each surface must yield the same normalised tuple
# (build ceiling, fix ceiling) = (2, 1), extracted from whatever words it uses,
# and no surface may still ASSERT the withdrawn untyped total cap. Two surfaces
# can disagree about every word here and still pass; they cannot disagree about
# the rule.
README_MD="$SRC/README.md"
BWCHECK="$SRC/build-os/tools/bandwidth-check.sh"
REGISTRY="$SRC/build-os/registry/control_registry.txt"
# The GOVERNING surfaces: files that state the commit budget as a rule this
# system is bound by, rather than summarising it for one audience.
BUDGET_FILES=("$PROJ_CLAUDE" "$GUIDANCE" "$README_MD" "$BWCHECK" "$REGISTRY")
# The DERIVED restatements, declared BY NAME so the hole is visible instead of
# silent. They summarise the contract for a single audience and are handled by
# the follow-up packet named in build-os/packets/active_packet.md; this list
# exists so that debt is enumerated and so a rename cannot quietly lose it.
BUDGET_DERIVED=(
  "$SRC/.claude/agents/builder.md"
  "$SRC/.claude/agents/build-orchestrator.md"
  "$SRC/build-os/memory/tool_router.md"
  "$SRC/docs/ONBOARDING.md"
  "$SRC/build-os/metrics/task_corpus.md"
  "$SRC/build-os/registry/CROSSWALK.md"
  "$SRC/build-os/registry/neurocosmology_crosswalk.txt"
  "$SRC/templates/build-os/memory/tool_router.md"
  "$SRC/templates/build-os/packets/active_packet.md"
)

# VACUITY GUARD, and it is the same lesson section 7 already learned: two empty
# files are byte-identical, and an extraction that matches nothing agrees with
# every other extraction that matches nothing. The manifest must be the set this
# section CLAIMS to scan, and every member of it must resolve, before a single
# comparison below is worth reading.
#
# This is an IDENTITY check against a named set, deliberately not a `-ge N`
# floor on the array's length. A length floor would be a fitted constant — a
# snapshot of the manifest on the day it was written, the family
# tests.nonvacuity_minimums exists to register — and it would still pass if a
# surface were SUBSTITUTED rather than removed. Naming the set costs the same
# line and catches both.
BUD_EXPECT="CLAUDE.md README.md bandwidth-check.sh control_registry.txt global-claude-md.md"
BUD_ACTUAL="$(for f in "${BUDGET_FILES[@]}"; do basename "$f"; done | sort | tr '\n' ' ' | sed 's/ $//')"
BUD_MISSING=0
for f in "${BUDGET_FILES[@]}"; do
  [ -s "$f" ] || { BUD_MISSING=$((BUD_MISSING+1)); echo "      | commit-budget surface does not resolve: $f"; }
done
{ [ "$BUD_ACTUAL" = "$BUD_EXPECT" ] && [ "$BUD_MISSING" -eq 0 ]; } \
  && ok "the commit-budget manifest is exactly the governing surfaces it names, and all ${#BUDGET_FILES[@]} resolve non-empty (the scan below is not vacuous)" \
  || no "the commit-budget manifest is not what this section claims to scan — expected [$BUD_EXPECT], got [$BUD_ACTUAL], with $BUD_MISSING unresolvable; every check below would pass over nothing"

# Extract the RULE from each surface, in whatever words that surface uses.
#
# EVERY statement in the file, never just the first. A surface may state the
# budget more than once — README.md states it twice, once in the agent table and
# once under the safety gates — and a `head -1` extraction would take the first
# and be structurally blind to the second disagreeing with it. That is not a
# hypothetical: it is a zero-kill this guard was caught by under mutation, with
# README's second statement moved to 3 while the first still read 2. So each
# file collapses to the SET of values it states, and a file that disagrees with
# ITSELF fails here before any cross-file comparison is attempted.
BUILD_MATCHED=0; BUILD_NUMS=""
FIX_MATCHED=0;   FIX_NUMS=""
for f in "${BUDGET_FILES[@]}"; do
  b="$(basename "$f")"
  nset="$(grep -oiE '(≤|<=) ?[0-9]+ build commits' "$f" | grep -oE '[0-9]+' | sort -u | tr '\n' ',' | sed 's/,$//')"
  if [ -z "$nset" ]; then
    no "$b states no BUILD-commit ceiling, so it is not carrying the typed budget at all"
  elif [ "${nset#*,}" != "$nset" ]; then
    no "$b states MORE THAN ONE build-commit ceiling — [$nset] — the surface disagrees with ITSELF"
  else
    BUILD_MATCHED=$((BUILD_MATCHED+1)); BUILD_NUMS="$BUILD_NUMS $b=$nset"
    ok "$b states the BUILD-commit ceiling numerically ($nset), the same value everywhere it states it"
  fi
  mset="$(grep -oiE 'at most (one|[0-9]+) fix commit' "$f" | tr 'A-Z' 'a-z' | awk '{print $3}' | sed 's/^one$/1/' | sort -u | tr '\n' ',' | sed 's/,$//')"
  if [ -z "$mset" ]; then
    no "$b states no FIX-commit allowance — the half of the rule that made the old cap satisfiable is missing"
  elif [ "${mset#*,}" != "$mset" ]; then
    no "$b states MORE THAN ONE fix-commit allowance — [$mset] — the surface disagrees with ITSELF"
  else
    FIX_MATCHED=$((FIX_MATCHED+1)); FIX_NUMS="$FIX_NUMS $b=$mset"
    ok "$b states the FIX-commit allowance numerically ($mset), the same value everywhere it states it"
  fi
done
[ "$BUILD_MATCHED" -eq "${#BUDGET_FILES[@]}" ] \
  && ok "build-ceiling scanner matched all ${#BUDGET_FILES[@]} surfaces (not vacuous)" \
  || no "build-ceiling scanner matched only $BUILD_MATCHED of ${#BUDGET_FILES[@]} — an agreement check over $BUILD_MATCHED numbers is meaningless"
[ "$FIX_MATCHED" -eq "${#BUDGET_FILES[@]}" ] \
  && ok "fix-allowance scanner matched all ${#BUDGET_FILES[@]} surfaces (not vacuous)" \
  || no "fix-allowance scanner matched only $FIX_MATCHED of ${#BUDGET_FILES[@]} — an agreement check over $FIX_MATCHED numbers is meaningless"
UNIQ_BUILD="$(tr ' ' '\n' <<<"$BUILD_NUMS" | sed '/^$/d' | cut -d= -f2 | sort -u | tr '\n' ',' | sed 's/,$//')"
UNIQ_FIX="$(tr ' ' '\n' <<<"$FIX_NUMS" | sed '/^$/d' | cut -d= -f2 | sort -u | tr '\n' ',' | sed 's/,$//')"
{ [ "$BUILD_MATCHED" -gt 0 ] && [ "$UNIQ_BUILD" = "2" ]; } \
  && ok "every governing surface states the SAME build-commit ceiling: 2" \
  || no "build-commit ceiling DRIFTED across surfaces — distinct values seen: [${UNIQ_BUILD:-none}]; per file:$BUILD_NUMS"
{ [ "$FIX_MATCHED" -gt 0 ] && [ "$UNIQ_FIX" = "1" ]; } \
  && ok "every governing surface states the SAME fix-commit allowance: 1" \
  || no "fix-commit allowance DRIFTED across surfaces — distinct values seen: [${UNIQ_FIX:-none}]; per file:$FIX_NUMS"

# THE REGRESSION ITSELF. An untyped total cap — `<=2 commits` with no BUILD in
# it — is the WITHDRAWN rule. It may still be QUOTED, because a withdrawal that
# cannot name what it withdrew is unreadable; it may not still be ASSERTED. The
# discriminator is on the same line: a quotation carries its withdrawal marker,
# a live rule does not.
UNTYPED_RE='(≤|<=) ?2 +commits'
WITHDRAWN_RE='withdrawn|former|no longer|superseded|unsatisfiable|replaced by'
for f in "${BUDGET_FILES[@]}"; do
  b="$(basename "$f")"
  BAD="$(grep -nE "$UNTYPED_RE" "$f" | grep -viE "$WITHDRAWN_RE" || true)"
  if [ -z "$BAD" ]; then
    ok "$b asserts no untyped '<=2 commits per packet' cap (the withdrawn rule is quoted, never restated as live)"
  else
    no "$b still ASSERTS the WITHDRAWN untyped commit cap on $(grep -c . <<<"$BAD") line(s) — the rule CLAUDE.md withdrew as unsatisfiable is alive on another surface"
    cut -c1-160 <<<"$BAD" | sed 's/^/      | /'
  fi
done

# And the withdrawal must be RECORDED on the contract surfaces, not silently
# dropped. Deleting the old sentence would satisfy the check above while leaving
# every reader of a derived restatement unable to tell the rule ever changed.
for pair in "CLAUDE.md:$PROJ_CLAUDE" "global-claude-md.md:$GUIDANCE"; do
  b="${pair%%:*}"; p="${pair#*:}"
  if grep -E "$UNTYPED_RE" "$p" | grep -qiE "$WITHDRAWN_RE"; then
    ok "$b RECORDS the withdrawal of the untyped cap rather than dropping it silently"
  else
    no "$b does not record that '<=2 commits per packet' was withdrawn — a reader cannot tell the rule changed"
  fi
done

# The declared debt must stay resolvable, or the register is decoration.
BUD_DMISS=0
for f in "${BUDGET_DERIVED[@]}"; do
  [ -e "$f" ] || { BUD_DMISS=$((BUD_DMISS+1)); echo "      | declared derived restatement no longer resolves: $f"; }
done
{ [ "${#BUDGET_DERIVED[@]}" -gt 0 ] && [ "$BUD_DMISS" -eq 0 ]; } \
  && ok "the ${#BUDGET_DERIVED[@]} DERIVED restatements outside this manifest are declared by name and all resolve (a named debt, not a silent hole)" \
  || no "$BUD_DMISS of ${#BUDGET_DERIVED[@]} declared derived restatements no longer resolve — the register is stale and the debt is untracked"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
