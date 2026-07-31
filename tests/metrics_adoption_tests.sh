#!/usr/bin/env bash
# Build OS — metrics ADOPTION tests (packet gravito_metrics_adoption_guard_a).
#
# WHAT THIS PINS, AND WHY IT IS A SEPARATE SUITE FROM speed_benchmark_tests.sh.
# That suite pins the instrument: the recorder refuses a bad row, the report
# refuses an empty store. Neither of them notices the failure that actually
# kills a measurement instrument — a packet that CLOSES WITHOUT RECORDING AT
# ALL. Nothing went red when nobody recorded, so the predicted end state was a
# store frozen at its seed rows while every artifact around it claimed the
# system was measured. This suite pins the guard that makes that state red:
#
#   build-os/metrics/check-adoption.sh        receipts -> rows reconciliation
#   build-os/metrics/adoption_boundaries.tsv  the ONE dated grandfather boundary
#                                             per obligation, and nothing else
#   .claude/agents/archivist.md               recording is part of closing
#   .claude/commands/close-packet.md          the same, at the command surface
#
# THE FAILURE MODES IT EXISTS TO CATCH, in the order a skeptic would probe them:
#   1. A CLOSED PACKET WITH NO ROW — the shelfware mechanism itself.
#   2. A JUNK ROW — a row of dashes appended to shut the guard up. That must be
#      visibly worse than no row, not a pass.
#   3. A WAIVER VIOLATED — read-only / diagnosis / tiny close with no packet and
#      no receipt. A guard that invents an obligation those lanes waive is a tax
#      on small work and gets switched off.
#   4. A PERMANENTLY RED GUARD — receipts P-001..P-022 predate the store. The
#      exemption must be one dated, checkable boundary, never a growing list.
#   5. A DISARMED GUARD — pushing the boundary forward until nothing is in scope
#      must REFUSE, not pass. A guard that cannot fail must not report success.
#   6. A VACUOUS GREEN — zero receipts or zero rows found means the scanner was
#      blinded, not that adoption was proved.
#
# No network. Deterministic. Temp dirs only: the live store and the live
# receipts are READ, never written. Exits non-zero if any assertion fails, and
# prints the final "==== RESULT: N passed, M failed ====" line the orchestrator
# parses when it chains this suite into tests/build_os_tests.sh.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
METRICS="$SRC/build-os/metrics"
GUARD="$METRICS/check-adoption.sh"
BOUNDS="$METRICS/adoption_boundaries.tsv"
REC="$METRICS/record-packet.sh"
STORE="$METRICS/packet_metrics.tsv"
DOC="$METRICS/README.md"
RECEIPTS="$SRC/build-os/receipts"
ARCHIVIST="$SRC/.claude/agents/archivist.md"
CLOSECMD="$SRC/.claude/commands/close-packet.md"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }
havei(){ grep -qiF "$2" "$1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

TAB=$'\t'
TODAY="$(date +%Y-%m-%d)"
# The boundaries are pinned LITERALLY here on purpose. The only way to exempt a
# packet from the guard is to move one of these two dates, so moving one must
# cost a deliberate, reviewable edit to this suite. That is what makes the
# grandfather boundary "explicit and checkable" instead of a quiet ratchet.
PIN_ROW_BOUNDARY="2026-07-29"
PIN_COMMIT_BOUNDARY="2026-07-30"
# A commit that certainly exists in this repository, used for fixture rows so
# the guard's git check is genuinely exercised. Diff columns are left "-" so no
# fixture ever has to restate a real numstat.
REAL_SHA="$(git -C "$SRC" rev-parse --short HEAD 2>/dev/null)"; REAL_SHA="${REAL_SHA:-HEAD}"
FAKE_SHA="dedbeef"
GOODNOTE="fixture row; rounds and agents are from the fixture transcript, diff columns deliberately left unmeasured"

# ------------------------------------------------------------------ helpers --
# Run the guard against a fixture, capturing stdout+stderr and the exit code.
run_guard(){ # run_guard <receipts-dir> <store> [extra args...]
  local r="$1" s="$2"; shift 2
  bash "$GUARD" --receipts "$r" --store "$s" --boundaries "${BFILE:-$BOUNDS}" --repo "$SRC" "$@" \
    > "$WORK/out.txt" 2>&1
  GRC=$?
  return 0
}
gout(){ cat "$WORK/out.txt"; }
dump(){ sed 's/^/      | /' "$WORK/out.txt"; }
saw(){ grep -qF "$1" "$WORK/out.txt"; }

# A fresh fixture: its own receipts dir, its own store, and one honestly
# recorded baseline packet so the fixture is never vacuous by accident.
newfix(){ # newfix <name> -> sets FR (receipts dir) and FS (store)
  FR="$WORK/$1/receipts"; FS="$WORK/$1/store.tsv"
  mkdir -p "$FR"
  mkreceipt "$1" baseline "$TODAY" ""
  addrow "$1" baseline substantive --rounds 2 --agents 3 --tests-added 4 \
         --commits "$REAL_SHA" --evidence mixed --note "$GOODNOTE"
}
mkreceipt(){ # mkreceipt <fixname> <id> <date|-> <lane|""> [extra body]
  local d="$WORK/$1/receipts" id="$2" dt="$3" lane="$4" extra="${5:-}"
  mkdir -p "$d"
  { printf '# Receipt — %s: fixture\n\n' "$id"
    [ "$dt" != "-" ] && printf -- '- **Date:** %s\n' "$dt"
    [ -n "$lane" ] && printf -- '- **Lane:** %s\n' "$lane"
    printf '\n## Scope\n\n- **In:** fixture receipt written by tests/metrics_adoption_tests.sh\n'
    [ -n "$extra" ] && printf '\n%s\n' "$extra"
  } > "$d/$id.md"
}
addrow(){ # addrow <fixname> <packet id> <lane> [recorder flags...]
  local s="$WORK/$1/store.tsv" id="$2" lane="$3"; shift 3
  bash "$REC" --store "$s" --packet "$id" --lane "$lane" --date "$TODAY" "$@" \
    > "$WORK/rec.out" 2>&1
}

echo "== 1. The guard is installed and runnable =="
[ -f "$GUARD" ] && ok "build-os/metrics/check-adoption.sh exists" \
  || no "build-os/metrics/check-adoption.sh is missing — the obligation to record is unenforced"
[ -x "$GUARD" ] && ok "check-adoption.sh is executable" || no "check-adoption.sh is not executable"
head -n1 "$GUARD" 2>/dev/null | grep -q '^#!/usr/bin/env bash' \
  && ok "check-adoption.sh is a bash script (no runtime to install)" \
  || no "check-adoption.sh does not start with a bash shebang"
[ -f "$BOUNDS" ] && ok "adoption_boundaries.tsv exists (the grandfather boundary is a file, not a hardcoded list)" \
  || no "adoption_boundaries.tsv is missing"
# The guard must not be able to mutate what it audits.
grep -nE '^[^#]*(>>|[^>]>[^&])[[:space:]]*"?\$(STORE|BOUNDS|RECEIPTS)' "$GUARD" > /dev/null 2>&1 \
  && no "check-adoption.sh appears to write to the store/receipts it audits" \
  || ok "check-adoption.sh never redirects output into the store, boundaries or receipts"

echo "== 2. The exemption mechanism is one dated boundary per obligation, and nothing else =="
[ "$(head -n1 "$BOUNDS")" = "obligation${TAB}required_after${TAB}reason" ] \
  && ok "boundary manifest carries the 3-column obligation/required_after/reason header" \
  || no "boundary manifest header drifted"
BROWS="$(tail -n +2 "$BOUNDS" | grep -cv '^[[:space:]]*$')"
[ "$BROWS" = "2" ] && ok "boundary manifest declares exactly 2 obligations (no room for a per-packet list)" \
  || no "boundary manifest has $BROWS declarations, expected 2"
BR="$(awk -F'\t' '$1=="row_required_after"{print $2}' "$BOUNDS")"
BC="$(awk -F'\t' '$1=="single_commit_required_after"{print $2}' "$BOUNDS")"
[ "$BR" = "$PIN_ROW_BOUNDARY" ] \
  && ok "row_required_after is pinned at $PIN_ROW_BOUNDARY (the day before the store existed)" \
  || no "row_required_after is $BR, not the pinned $PIN_ROW_BOUNDARY — moving the boundary must be a reviewed edit, not a quiet one"
[ "$BC" = "$PIN_COMMIT_BOUNDARY" ] \
  && ok "single_commit_required_after is pinned at $PIN_COMMIT_BOUNDARY" \
  || no "single_commit_required_after is $BC, not the pinned $PIN_COMMIT_BOUNDARY"
[ "$BR" \> "$TODAY" ] && no "row_required_after is in the future — unhappened work cannot be grandfathered" \
  || ok "row_required_after is not in the future"
# Every exemption states a reason, and no exemption names a packet.
BADREASON="$(awk -F'\t' 'NR>1 && length($3)<24 {print $1}' "$BOUNDS")"
[ -z "$BADREASON" ] && ok "every boundary states a reason (>=24 chars)" \
  || no "boundary(s) with no stated reason: $BADREASON"
PERPKT="$(awk -F'\t' 'NR>1 && $1 !~ /^(row_required_after|single_commit_required_after)$/ {print $1}' "$BOUNDS")"
[ -z "$PERPKT" ] && ok "the manifest contains no per-packet exemption entries" \
  || no "the manifest names individual packets as exemptions ($PERPKT) — that is the ever-growing exception list this design refuses"

echo "== 3. Live repo: the guard passes AND actually checked something =="
bash "$GUARD" > "$WORK/out.txt" 2>&1; LIVE=$?
[ "$LIVE" = "0" ] && ok "the guard is green against the live receipts and the live store" \
  || { no "the guard is red against the live repo (exit $LIVE)"; dump; }
INSCOPE="$(grep -oE '[0-9]+ in scope' "$WORK/out.txt" | grep -oE '^[0-9]+')"
[ "${INSCOPE:-0}" -ge 1 ] \
  && ok "the live scan had ${INSCOPE} receipt(s) actually in scope (a green over an empty scope would prove nothing)" \
  || { no "the live scan had 0 receipts in scope — this green is vacuous"; dump; }
saw "0 missing" && ok "the live scan reports 0 closed-but-unrecorded packets" || { no "the live scan reports missing rows"; dump; }
saw "0 hollow"  && ok "the live scan reports 0 hollow rows" || { no "the live scan reports hollow rows"; dump; }
# The guard is an auditor; it must not touch the evidence.
SUMB="$(cksum "$STORE" | awk '{print $1,$2}')"
bash "$GUARD" > /dev/null 2>&1
SUMA="$(cksum "$STORE" | awk '{print $1,$2}')"
[ "$SUMB" = "$SUMA" ] && ok "running the guard leaves the live store byte-identical" \
  || no "the guard modified the live store"

echo "== 4. A substantive packet that closed without recording FAILS =="
newfix miss
mkreceipt miss unrecorded_packet_a "$TODAY" ""
run_guard "$FR" "$FS"
[ "$GRC" = "2" ] && ok "a receipt with no store row makes the guard exit 2" \
  || { no "a receipt with no store row did not fail the guard (exit $GRC)"; dump; }
saw "MISSING" && saw "unrecorded_packet_a" \
  && ok "the guard names the unrecorded packet as MISSING" || { no "the guard did not name the missing packet"; dump; }

echo "== 5. The same packet, once recorded, PASSES =="
addrow miss unrecorded_packet_a substantive --rounds 3 --agents 2 --tests-added 9 \
  --commits "$REAL_SHA" --evidence mixed --note "$GOODNOTE"
run_guard "$FR" "$FS"
[ "$GRC" = "0" ] && ok "recording a meaningful row clears the guard (exit 0)" \
  || { no "a recorded packet still failed the guard (exit $GRC)"; dump; }
saw "RECORDED" && ok "the guard reports the packet as RECORDED" || { no "the guard did not report RECORDED"; dump; }

echo "== 6. The lane waivers hold — small work owes nothing =="
# (a) The strong form: those lanes leave no receipt at all, so they never enter
#     the scan. Nothing to assert but the pass itself.
newfix waive
run_guard "$FR" "$FS"
[ "$GRC" = "0" ] && ok "a tree where the only closures are receipt-less (tiny/read-only/diagnosis) is green" \
  || { no "receipt-less closures tripped the guard (exit $GRC)"; dump; }
# (b) The declared form: a receipt that names a waived lane is skipped by name.
for lane in tiny read-only diagnosis; do
  mkreceipt waive "waived_${lane//-/_}_a" "$TODAY" "$lane"
done
run_guard "$FR" "$FS" --verbose
[ "$GRC" = "0" ] && ok "receipts declaring tiny / read-only / diagnosis need no row (exit 0)" \
  || { no "a waived-lane receipt tripped the guard (exit $GRC)"; dump; }
saw "WAIVED" && ok "the guard reports the waived-lane receipts explicitly" || { no "the guard did not report the waiver"; dump; }
# And the waiver must not be a loophole for substantive work: an undeclared lane
# means substantive, because substantive is the only lane that writes a receipt.
newfix nolane
mkreceipt nolane undeclared_lane_a "$TODAY" ""
run_guard "$FR" "$FS"
[ "$GRC" = "2" ] && ok "a receipt with NO lane declaration is treated as substantive and still owes a row" \
  || { no "an undeclared-lane receipt escaped the obligation (exit $GRC)"; dump; }

echo "== 7. A junk row does NOT satisfy the guard =="
# (a) All dashes: the row a bored agent appends to make a check stop complaining.
newfix junk
mkreceipt junk all_dashes_a "$TODAY" ""
addrow junk all_dashes_a substantive --evidence estimate \
  --note "closed this packet and appended a row so the adoption check stops complaining about it"
[ -n "$(awk -F'\t' '$1=="all_dashes_a"' "$FS")" ] \
  && ok "the recorder itself accepts the all-dash row (so the guard is the only thing standing between it and a green)" \
  || no "fixture setup failed: the all-dash row was never written"
run_guard "$FR" "$FS"
[ "$GRC" = "2" ] && ok "a row of all dashes does NOT satisfy the guard (exit 2)" \
  || { no "an all-dash row satisfied the guard (exit $GRC)"; dump; }
saw "HOLLOW" && ok "the guard calls the all-dash row HOLLOW rather than RECORDED" || { no "no HOLLOW verdict for the all-dash row"; dump; }
saw "0 of 11" && ok "the guard states how few cells were measured (0 of 11)" || { no "the guard did not report the measured-cell count"; dump; }
saw "names no commit" && ok "the guard states that a commit-less row cannot be checked against git" \
  || { no "the guard did not flag the missing commit"; dump; }
# (b) A row just under the meaningfulness bar: a commit, but nothing measured.
newfix thin
mkreceipt thin thin_row_a "$TODAY" ""
addrow thin thin_row_a substantive --commits "$REAL_SHA" --evidence mixed --note "$GOODNOTE"
run_guard "$FR" "$FS"
[ "$GRC" = "2" ] && ok "a row naming a commit but measuring nothing else is still HOLLOW" \
  || { no "a near-empty row passed (exit $GRC)"; dump; }
# (c) rounds "-" is only acceptable as an ADMISSION: the note must say why.
newfix rounds
mkreceipt rounds silent_rounds_a "$TODAY" ""
addrow rounds silent_rounds_a substantive --agents 2 --tests-added 3 --defects-gated 1 \
  --commits "$REAL_SHA" --evidence mixed \
  --note "figures taken from the session log; nothing here was reconstructed after the fact"
run_guard "$FR" "$FS"
[ "$GRC" = "2" ] && ok "rounds='-' with no explanation in the note is HOLLOW" \
  || { no "an unexplained blank round count passed (exit $GRC)"; dump; }
newfix rounds2
mkreceipt rounds2 explained_rounds_a "$TODAY" ""
addrow rounds2 explained_rounds_a substantive --agents 2 --tests-added 3 --defects-gated 1 \
  --commits "$REAL_SHA" --evidence mixed \
  --note "rounds were never counted in this session and are left blank rather than reconstructed from commit timestamps"
run_guard "$FR" "$FS"
[ "$GRC" = "0" ] && ok "rounds='-' WITH a stated reason in the note is accepted (an admission is a measurement's honest sibling)" \
  || { no "an explained blank round count was rejected (exit $GRC)"; dump; }
# (d) A note too short to attribute anything.
newfix shortnote
mkreceipt shortnote terse_note_a "$TODAY" ""
addrow shortnote terse_note_a substantive --rounds 2 --agents 1 --tests-added 1 \
  --commits "$REAL_SHA" --evidence mixed --note "closed it ok"
run_guard "$FR" "$FS"
[ "$GRC" = "2" ] && ok "a row whose note is too short to attribute its numbers is HOLLOW" \
  || { no "an unattributable row passed (exit $GRC)"; dump; }
# (e) A fabricated commit.
newfix fakesha
mkreceipt fakesha invented_commit_a "$TODAY" ""
addrow fakesha invented_commit_a substantive --rounds 2 --agents 1 --tests-added 1 \
  --commits "$FAKE_SHA" --evidence mixed --note "$GOODNOTE"
run_guard "$FR" "$FS"
[ "$GRC" = "2" ] && ok "a row naming a commit this repository does not contain is refused" \
  || { no "a fabricated commit passed the guard (exit $GRC)"; dump; }
saw "$FAKE_SHA" && ok "the guard names the commit it could not find" || { no "the guard did not name the bad sha"; dump; }

echo "== 8. Pre-metrics receipts are grandfathered — by a date, not by a list =="
newfix grand
mkreceipt grand P-999 "2026-07-24" ""
run_guard "$FR" "$FS" --verbose
[ "$GRC" = "0" ] && ok "a receipt dated before row_required_after needs no row (exit 0)" \
  || { no "a pre-metrics receipt tripped the guard (exit $GRC)"; dump; }
saw "GRANDFATHERED" && ok "the guard says WHY it skipped the historical receipt" || { no "no GRANDFATHERED verdict"; dump; }
# The boundary is a boundary: on it is out, one day past it is in.
newfix edge
mkreceipt edge on_boundary_a "$PIN_ROW_BOUNDARY" ""
run_guard "$FR" "$FS"
[ "$GRC" = "0" ] && ok "a receipt dated exactly on the boundary is grandfathered" \
  || { no "the boundary is off by one on its own date (exit $GRC)"; dump; }
newfix edge2
mkreceipt edge2 past_boundary_a "2026-07-30" ""
run_guard "$FR" "$FS"
[ "$GRC" = "2" ] && ok "a receipt dated one day past the boundary is in scope and owes a row" \
  || { no "a post-boundary receipt was not held to the obligation (exit $GRC)"; dump; }
# An undated brand-new receipt must fail CLOSED, or omitting the date is the dodge.
newfix undated
mkreceipt undated undated_new_a "-" ""
run_guard "$FR" "$FS"
[ "$GRC" = "2" ] && ok "a receipt with no date at all is treated as new and still owes a row" \
  || { no "omitting the date let a receipt escape the guard (exit $GRC)"; dump; }

echo "== 9. The boundary cannot be used to disarm the guard =="
mkbounds(){ printf 'obligation\trequired_after\treason\n%s\n' "$1" > "$WORK/b.tsv"; BFILE="$WORK/b.tsv"; }
newfix disarm
mkreceipt disarm unrecorded_b "$TODAY" ""
# Baseline: with the real boundaries this fixture is red.
BFILE="$BOUNDS"; run_guard "$FR" "$FS"
[ "$GRC" = "2" ] && ok "baseline: the disarm fixture is red under the real boundaries" \
  || { no "disarm fixture is not red to begin with (exit $GRC)"; dump; }
# Push the boundary forward past every receipt to silence it -> vacuous scope.
mkbounds "row_required_after${TAB}${TODAY}${TAB}pushed forward to make the failure go away, which is the abuse this refuses
single_commit_required_after${TAB}${PIN_COMMIT_BOUNDARY}${TAB}unchanged fixture boundary with a sufficiently long stated reason"
run_guard "$FR" "$FS"
[ "$GRC" = "2" ] && saw "0 receipts were in scope" \
  && ok "moving the boundary past every receipt REFUSES (a guard that cannot fail must not pass)" \
  || { no "the boundary could be moved forward to buy a green (exit $GRC)"; dump; }
# A future boundary is refused outright.
mkbounds "row_required_after${TAB}2099-01-01${TAB}an absurd boundary that would grandfather all future work forever
single_commit_required_after${TAB}${PIN_COMMIT_BOUNDARY}${TAB}unchanged fixture boundary with a sufficiently long stated reason"
run_guard "$FR" "$FS"
[ "$GRC" = "2" ] && saw "future" && ok "a boundary dated in the future is refused" \
  || { no "a future boundary was accepted (exit $GRC)"; dump; }
# A per-packet exemption is not a syntax this guard has.
mkbounds "row_required_after${TAB}${PIN_ROW_BOUNDARY}${TAB}the real boundary, restated in a fixture with a long enough reason
single_commit_required_after${TAB}${PIN_COMMIT_BOUNDARY}${TAB}unchanged fixture boundary with a sufficiently long stated reason
exempt_packet${TAB}${TODAY}${TAB}please ignore unrecorded_b just this once, we were in a hurry that day"
run_guard "$FR" "$FS"
[ "$GRC" = "2" ] && saw "unknown obligation" \
  && ok "a per-packet exemption entry is refused — the exception list cannot grow" \
  || { no "the manifest accepted a per-packet exemption (exit $GRC)"; dump; }
# A duplicated or unreasoned boundary is refused.
mkbounds "row_required_after${TAB}${PIN_ROW_BOUNDARY}${TAB}the real boundary, restated in a fixture with a long enough reason
row_required_after${TAB}${TODAY}${TAB}a second value for the same boundary, which is not a boundary at all
single_commit_required_after${TAB}${PIN_COMMIT_BOUNDARY}${TAB}unchanged fixture boundary with a sufficiently long stated reason"
run_guard "$FR" "$FS"
[ "$GRC" = "2" ] && saw "more than once" && ok "two values for one boundary are refused" \
  || { no "a duplicated boundary was accepted (exit $GRC)"; dump; }
mkbounds "row_required_after${TAB}${PIN_ROW_BOUNDARY}${TAB}short
single_commit_required_after${TAB}${PIN_COMMIT_BOUNDARY}${TAB}unchanged fixture boundary with a sufficiently long stated reason"
run_guard "$FR" "$FS"
[ "$GRC" = "2" ] && ok "a boundary with no stated reason is refused" \
  || { no "an unreasoned exemption was accepted (exit $GRC)"; dump; }
# A missing manifest is not "no boundaries, therefore everything passes".
BFILE="$WORK/nope.tsv"; run_guard "$FR" "$FS"
[ "$GRC" = "2" ] && ok "a missing boundary manifest refuses rather than defaulting to permissive" \
  || { no "a missing manifest was treated as permissive (exit $GRC)"; dump; }
BFILE="$BOUNDS"

echo "== 10. Vacuity guard: a scan with nothing to compare FAILS LOUDLY =="
newfix vac
# (a) Blinded scanner: pointed at an empty directory.
mkdir -p "$WORK/empty-receipts"
run_guard "$WORK/empty-receipts" "$FS"
[ "$GRC" = "2" ] && saw "0 receipts" && ok "0 receipts found REFUSES (a blinded scanner must not report success)" \
  || { no "an empty receipts directory produced a green (exit $GRC)"; dump; }
# (b) Pointed at a directory that does not exist at all.
run_guard "$WORK/no-such-dir" "$FS"
[ "$GRC" = "2" ] && ok "a nonexistent receipts directory REFUSES" \
  || { no "a missing receipts directory produced a green (exit $GRC)"; dump; }
# (c) A store with a header and no rows.
head -n1 "$STORE" > "$WORK/emptystore.tsv"
run_guard "$FR" "$WORK/emptystore.tsv"
[ "$GRC" = "2" ] && saw "0 data rows" && ok "a store with 0 data rows REFUSES" \
  || { no "an empty store produced a green (exit $GRC)"; dump; }
# (d) No store at all.
run_guard "$FR" "$WORK/no-such-store.tsv"
[ "$GRC" = "2" ] && ok "a missing store REFUSES" || { no "a missing store produced a green (exit $GRC)"; dump; }

echo "== 11. One commit per packet, with the stated fallback =="
newfix onecommit
SHA2="$(git -C "$SRC" rev-parse --short HEAD~1 2>/dev/null)"; SHA2="${SHA2:-$REAL_SHA}"
mkreceipt onecommit multi_commit_a "$TODAY" ""
addrow onecommit multi_commit_a substantive --rounds 2 --agents 1 --tests-added 5 \
  --commits "$REAL_SHA,$SHA2" --evidence mixed --note "$GOODNOTE"
run_guard "$FR" "$FS"
[ "$GRC" = "2" ] && saw "UNATTRIBUTED" \
  && ok "a packet spread over 2 commits with no file-ownership manifest in its receipt FAILS" \
  || { no "the one-commit-per-packet obligation is unenforced (exit $GRC)"; dump; }
# The fallback is what makes the rule followable when the merge forces >1 commit.
mkreceipt onecommit multi_commit_a "$TODAY" "" \
"## File-ownership manifest

The merge forced two commits, so attribution is recorded by path here:
- \`$REAL_SHA\` — build-os/metrics/**
- \`$SHA2\` — tests/**"
run_guard "$FR" "$FS"
[ "$GRC" = "0" ] \
  && ok "the same packet passes once the receipt records the disjoint file-ownership manifest" \
  || { no "the documented fallback does not actually satisfy the rule (exit $GRC)"; dump; }
# And the rule has its own dated boundary, so pre-rule packets are not retro-judged.
newfix oldmulti
mkreceipt oldmulti old_multi_a "$PIN_COMMIT_BOUNDARY" ""
addrow oldmulti old_multi_a substantive --rounds 2 --agents 1 --tests-added 5 \
  --commits "$REAL_SHA,$SHA2" --evidence mixed --note "$GOODNOTE"
run_guard "$FR" "$FS"
[ "$GRC" = "0" ] \
  && ok "a multi-commit packet closed on or before single_commit_required_after is not retro-judged" \
  || { no "the one-commit rule is applied retroactively (exit $GRC)"; dump; }

echo "== 12. Recording is part of CLOSING, not a convention someone remembers =="
for spec in "record-packet.sh:the recorder it must run" \
            "packet_metrics.tsv:the store it writes to" \
            "check-adoption.sh:the guard that will catch a skipped row" \
            "adoption_boundaries.tsv:the dated grandfather boundary"; do
  needle="${spec%%:*}"; label="${spec#*:}"
  havei "$ARCHIVIST" "$needle" && ok "archivist.md names $label" || no "archivist.md never names $label"
done
grep -qiE 'one commit per packet|a single commit per packet' "$ARCHIVIST" \
  && ok "archivist.md states the one-commit-per-packet obligation" \
  || no "archivist.md does not state the one-commit-per-packet obligation"
grep -qiE 'file[ -]ownership manifest' "$ARCHIVIST" \
  && ok "archivist.md states the fallback that makes the one-commit rule followable" \
  || no "archivist.md states an absolute commit rule with no fallback — a rule that collides with merge mechanics gets quietly broken"
grep -qiE '"-"|dash' "$ARCHIVIST" && ok "archivist.md carries the '-' (unmeasured) convention into the close step" \
  || no "archivist.md does not tell the archivist how to record an unmeasured cell"
grep -qiE '\*\*lane:?\*\*' "$ARCHIVIST" && ok "archivist.md requires the receipt to declare its lane (the guard reads it)" \
  || no "archivist.md does not require a lane line in the receipt"
grep -qiE 'read-only|tiny' "$ARCHIVIST" && ok "archivist.md keeps the small-lane waiver visible next to the new obligation" \
  || no "archivist.md does not restate the lane waiver"
for needle in "record-packet.sh" "check-adoption.sh"; do
  havei "$CLOSECMD" "$needle" && ok "close-packet.md names $needle" || no "close-packet.md never names $needle"
done
havei "$DOC" "check-adoption.sh" && ok "the metrics README documents the adoption guard" \
  || no "the metrics README does not document the adoption guard"

echo "== 13. This suite is not vacuous about itself =="
# Every fixture is built from the live recorder against the live repo. If the
# helpers silently produced nothing, most assertions above would pass by
# accident, so the fixtures are counted.
NFIX="$(find "$WORK" -name 'store.tsv' | wc -l | tr -d ' ')"
[ "${NFIX:-0}" -ge 10 ] && ok "$NFIX independent fixture stores were built and scanned" \
  || no "only ${NFIX:-0} fixture stores were built — the fixture helpers are not doing what these assertions assume"
NRCPT="$(find "$WORK" -path '*/receipts/*.md' | wc -l | tr -d ' ')"
[ "${NRCPT:-0}" -ge 15 ] && ok "$NRCPT fixture receipts were written and scanned" \
  || no "only ${NRCPT:-0} fixture receipts were written"
[ -n "$REAL_SHA" ] && [ "$REAL_SHA" != "HEAD" ] \
  && ok "fixture rows referenced a real commit ($REAL_SHA), so the guard's git check was exercised" \
  || no "no real commit was available — the git check was never exercised"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
