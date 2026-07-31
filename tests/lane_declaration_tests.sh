#!/usr/bin/env bash
# Build OS — LANE DECLARATION tests (packet gravito_lane_declaration_check_a).
#
# THE HOLE THIS SUITE PINS, in the adoption guard's own words:
#
#   "A mis-declared lane. **Lane:** tiny on a receipt is self-asserted and skips
#    the row obligation. Nothing cross-checks a declared lane against the
#    packet's actual size. This is the largest remaining hole."
#
# Declaring `tiny` waives qa, the reviewer, the archivist, the receipt AND the
# metrics row. Every one of those gates hangs off a single unverified word
# written by the same agent the gates exist to check. An agent that learns to
# type `tiny` gets a Build OS with no gates at all, and nothing anywhere goes
# red. This suite pins the cross-check that makes that state red:
#
#   build-os/metrics/check-adoption.sh   the lane <-> git-diff cross-check
#   build-os/memory/tool_router.md       the thresholds, and their derivation
#
# WHAT IT ASSERTS, in the order a skeptic would probe it:
#   1. A `tiny` whose commits are egregiously large FAILS.
#   2. A genuinely small `tiny` PASSES — false positives are the failure mode
#      that gets a check like this deleted, so specificity is asserted harder
#      than sensitivity.
#   3. A `substantive` of ANY size passes. There is no upper bound on the lane
#      that already pays for the full chain.
#   4. A declaration with no commit PASSES. Read-only answers and diagnoses
#      leave no diff, and an absent diff is not evidence of a large one.
#   5. The override is RECORDED and GREPPABLE, never silent, and a malformed
#      override FAILS rather than degrading to a pass.
#   6. The thresholds in the script and in the router are the same numbers.
#      Drift between the enforced value and the documented value is a defect.
#   7. Vacuity — zero receipts, or zero rows to calibrate against, must fail
#      loudly. A check that cannot fire must not report success.
#
# No network. Deterministic. Temp dirs only: the live store and live receipts
# are READ, never written. Exits non-zero if any assertion fails, and prints the
# "==== RESULT: N passed, M failed ====" line the orchestrator parses when it
# chains this suite.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
METRICS="$SRC/build-os/metrics"
GUARD="$METRICS/check-adoption.sh"
REC="$METRICS/record-packet.sh"
BOUNDS="$METRICS/adoption_boundaries.tsv"
STORE="$METRICS/packet_metrics.tsv"
ROUTER="$SRC/build-os/memory/tool_router.md"
DOC="$METRICS/README.md"
ORCH="$SRC/.claude/agents/build-orchestrator.md"
BUILDER="$SRC/.claude/agents/builder.md"
ARCHIVIST="$SRC/.claude/agents/archivist.md"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }
havei(){ grep -qiF "$2" "$1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

TAB=$'\t'
TODAY="$(date +%Y-%m-%d)"

# --- the pinned thresholds ---------------------------------------------------
# These are LITERAL here on purpose. They are the median of this repository's
# own non-waived-lane packet sizes (see section 2), and the only way to move
# them is a deliberate, reviewable edit to this file, the script AND the router
# at once. A threshold that can be tuned quietly is a threshold that gets tuned
# away the first time it is inconvenient.
PIN_MAX_FILES=13
PIN_MAX_CHURN=2213
OVR="LANE-OVERRIDE"

# ------------------------------------------------------------------ helpers --
# A synthetic git repository. The live history has no commit that trips exactly
# ONE of the two thresholds, so OR-semantics cannot be proved against it. These
# three commits are built to isolate each signal.
SYNTH="$WORK/synthrepo"
mkgit(){
  mkdir -p "$SYNTH"
  git -c init.defaultBranch=main -C "$SYNTH" init -q >/dev/null 2>&1
  git -C "$SYNTH" config user.email "lane-tests@example.invalid"
  git -C "$SYNTH" config user.name  "lane declaration tests"
  echo base > "$SYNTH/base.txt"
  git -C "$SYNTH" add -A >/dev/null 2>&1; git -C "$SYNTH" commit -qm base >/dev/null 2>&1
  # WIDE: 20 files x 1 line. Trips files, not churn.
  local i; for i in $(seq 1 20); do echo "x" > "$SYNTH/w$i.txt"; done
  git -C "$SYNTH" add -A >/dev/null 2>&1; git -C "$SYNTH" commit -qm wide >/dev/null 2>&1
  SHA_WIDE="$(git -C "$SYNTH" rev-parse --short HEAD)"
  # DEEP: 1 file x 3000 lines. Trips churn, not files.
  seq 1 3000 > "$SYNTH/deep.txt"
  git -C "$SYNTH" add -A >/dev/null 2>&1; git -C "$SYNTH" commit -qm deep >/dev/null 2>&1
  SHA_DEEP="$(git -C "$SYNTH" rev-parse --short HEAD)"
  # SMALL: 2 files x 5 lines. Trips neither.
  seq 1 5 > "$SYNTH/s1.txt"; seq 1 5 > "$SYNTH/s2.txt"
  git -C "$SYNTH" add -A >/dev/null 2>&1; git -C "$SYNTH" commit -qm small >/dev/null 2>&1
  SHA_SMALL="$(git -C "$SYNTH" rev-parse --short HEAD)"
  # MID: 8 files / 2005 changed lines — the exact size of gravito_pilot_kit_a,
  # the second-smallest substantive packet this repository has produced. It is
  # UNDER both thresholds, and that is the stated recall sacrifice made visible.
  local j; for j in $(seq 1 7); do seq 1 250 > "$SYNTH/m$j.txt"; done
  seq 1 255 > "$SYNTH/m8.txt"
  git -C "$SYNTH" add -A >/dev/null 2>&1; git -C "$SYNTH" commit -qm mid >/dev/null 2>&1
  SHA_MID="$(git -C "$SYNTH" rev-parse --short HEAD)"
}
mkgit

GOODNOTE="fixture row written by tests/lane_declaration_tests.sh; rounds deliberately unmeasured, diff cells taken from git"

# Run the guard against a fixture. REPO defaults to the synthetic repo so the
# fixture commits are the only ones in scope.
run_guard(){ # run_guard <receipts-dir> <store> [extra args...]
  local r="$1" s="$2"; shift 2
  bash "$GUARD" --receipts "$r" --store "$s" --boundaries "$BOUNDS" \
       --repo "${FREPO:-$SYNTH}" "$@" > "$WORK/out.txt" 2>&1
  GRC=$?
  return 0
}
dump(){ sed 's/^/      | /' "$WORK/out.txt"; }
saw(){ grep -qF "$1" "$WORK/out.txt"; }

mkreceipt(){ # mkreceipt <fix> <id> <lane|""> [commits-section-shas] [extra body]
  local d="$WORK/$1/receipts" id="$2" lane="$3" shas="${4:-}" extra="${5:-}"
  mkdir -p "$d"
  { printf '# %s — fixture receipt\n\n' "$id"
    printf -- '- **Date:** %s\n' "$TODAY"
    [ -n "$lane" ] && printf -- '- **Lane:** %s\n' "$lane"
    printf '\n## Scope\n\n- **In:** fixture written by tests/lane_declaration_tests.sh\n'
    if [ -n "$shas" ]; then
      printf '\n## Commits\n\n'
      local s; for s in $shas; do printf -- '- `%s` fixture commit\n' "$s"; done
    fi
    [ -n "$extra" ] && printf '\n%s\n' "$extra"
    printf '\n## Review\n\n- **Verdict: pass.**\n'
  } > "$d/$id.md"
}
addrow(){ # addrow <fix> <id> <lane> [recorder flags...]
  local s="$WORK/$1/store.tsv" id="$2" lane="$3"; shift 3
  bash "$REC" --store "$s" --packet "$id" --lane "$lane" --date "$TODAY" "$@" \
    > "$WORK/rec.out" 2>&1
}
# Every fixture carries one honestly recorded substantive packet. It does two
# jobs: it keeps the adoption scan's in-scope set non-empty, and it IS the
# calibration basis the lane cross-check needs (a non-waived row with a
# git-verified size). Without it a fixture would be vacuous by accident.
newfix(){ # newfix <name> -> FR (receipts dir), FS (store)
  FR="$WORK/$1/receipts"; FS="$WORK/$1/store.tsv"
  mkdir -p "$FR"
  mkreceipt "$1" baseline substantive "$SHA_WIDE"
  addrow "$1" baseline substantive --files 20 --insertions 20 --deletions 0 \
         --commits "$SHA_WIDE" --evidence git --note "$GOODNOTE (rounds not taken)"
}

echo "== 1. The cross-check exists and is wired where closes are reconciled =="
[ -f "$GUARD" ] && ok "build-os/metrics/check-adoption.sh exists" \
  || no "check-adoption.sh is missing"
grep -q 'LANE_TINY_MAX_FILES' "$GUARD" \
  && ok "check-adoption.sh defines LANE_TINY_MAX_FILES (the cross-check lives where receipts are already reconciled, not in a script nobody runs)" \
  || no "check-adoption.sh has no lane-size threshold — a declared lane is still unchecked"
grep -q 'LANE_TINY_MAX_CHURN' "$GUARD" \
  && ok "check-adoption.sh defines LANE_TINY_MAX_CHURN" \
  || no "check-adoption.sh has no churn threshold"
grep -q 'LANE-CONTRADICTED' "$GUARD" \
  && ok "check-adoption.sh can report LANE-CONTRADICTED" \
  || no "check-adoption.sh never reports a lane contradiction"
grep -qF "$OVR" "$GUARD" \
  && ok "check-adoption.sh knows the $OVR token (the escape hatch is implemented, not just described)" \
  || no "check-adoption.sh does not implement an override — a rule with no stated fallback gets quietly broken"
# The signal must come from git, not from prose.
grep -q 'numstat' "$GUARD" \
  && ok "the cross-check measures with git numstat (observable evidence, not the agent's own prose)" \
  || no "check-adoption.sh never calls git numstat — it cannot be measuring anything observable"

echo "== 2. The thresholds are documented, derived, and identical in script and router =="
sfiles="$(grep -m1 -E '^LANE_TINY_MAX_FILES=' "$GUARD" | cut -d= -f2 | tr -d ' \t')"
schurn="$(grep -m1 -E '^LANE_TINY_MAX_CHURN=' "$GUARD" | cut -d= -f2 | tr -d ' \t')"
[ "$sfiles" = "$PIN_MAX_FILES" ] \
  && ok "check-adoption.sh enforces LANE_TINY_MAX_FILES=$PIN_MAX_FILES" \
  || no "check-adoption.sh enforces LANE_TINY_MAX_FILES=${sfiles:-<unset>}, not the pinned $PIN_MAX_FILES"
[ "$schurn" = "$PIN_MAX_CHURN" ] \
  && ok "check-adoption.sh enforces LANE_TINY_MAX_CHURN=$PIN_MAX_CHURN" \
  || no "check-adoption.sh enforces LANE_TINY_MAX_CHURN=${schurn:-<unset>}, not the pinned $PIN_MAX_CHURN"
grep -q 'BUILD-OS:LANE-SIZE:START' "$ROUTER" \
  && ok "tool_router.md carries a delimited LANE-SIZE block (the numbers are documented where the lanes are declared)" \
  || no "tool_router.md documents no lane-size thresholds — the check enforces a number nobody can look up"
rfiles="$(awk -F'|' '/LANE_TINY_MAX_FILES/{gsub(/[` ]/,"",$3); print $3; exit}' "$ROUTER")"
rchurn="$(awk -F'|' '/LANE_TINY_MAX_CHURN/{gsub(/[` ]/,"",$3); print $3; exit}' "$ROUTER")"
[ -n "$rfiles" ] && [ "$rfiles" = "$sfiles" ] \
  && ok "the router's LANE_TINY_MAX_FILES ($rfiles) is the value the script enforces (no drift)" \
  || no "DRIFT: router says LANE_TINY_MAX_FILES=${rfiles:-<absent>}, script enforces ${sfiles:-<unset>}"
[ -n "$rchurn" ] && [ "$rchurn" = "$schurn" ] \
  && ok "the router's LANE_TINY_MAX_CHURN ($rchurn) is the value the script enforces (no drift)" \
  || no "DRIFT: router says LANE_TINY_MAX_CHURN=${rchurn:-<absent>}, script enforces ${schurn:-<unset>}"
# A threshold nobody can justify gets tuned away. The derivation must be written
# down next to the number, and it must name the data it came from.
havei "$ROUTER" "median" \
  && ok "the router states the derivation (median of the observed non-waived-lane packet sizes), not a bare number" \
  || no "the router gives the thresholds with no derivation — an unjustified threshold is the first thing tuned away"
havei "$ROUTER" "packet_metrics.tsv" \
  && ok "the router names the dataset the thresholds were derived from" \
  || no "the router does not name the dataset behind the thresholds"
grep -q 'median' "$GUARD" \
  && ok "check-adoption.sh carries the derivation next to the constants it enforces" \
  || no "check-adoption.sh states no derivation for its thresholds"

echo "== 3. Live repo: the cross-check runs, is calibrated, and does NOT fire on real history =="
bash "$GUARD" > "$WORK/out.txt" 2>&1; LIVE=$?
[ "$LIVE" = "0" ] \
  && ok "the guard is green against the live receipts and the live store (the cross-check ships without a red day-one)" \
  || { no "the guard is RED against the live repo (exit $LIVE) — a check that is red on the day it ships gets disabled inside a week"; dump; }
saw "lane cross-check" \
  && ok "the live scan reports a lane cross-check line" \
  || { no "the live scan never mentions the lane cross-check — it did not run"; dump; }
LBASIS="$(grep -oE 'calibrated from [0-9]+' "$WORK/out.txt" | grep -oE '[0-9]+' | head -n1)"
[ "${LBASIS:-0}" -ge 1 ] \
  && ok "the live cross-check was calibrated from ${LBASIS} non-waived-lane row(s) (its thresholds are moored to real data)" \
  || { no "the live cross-check reports 0 calibration rows — its thresholds are unmoored"; dump; }
LSUBJ="$(grep -oE '[0-9]+ waived-lane declaration' "$WORK/out.txt" | grep -oE '^[0-9]+' | head -n1)"
[ "${LSUBJ:-0}" -ge 1 ] \
  && ok "the live cross-check actually examined ${LSUBJ} waived-lane declaration(s) — this green is not vacuous" \
  || { no "the live cross-check examined 0 declarations; this repo records lane=tiny for gravito_test_harness_stdin_hang_a, so 0 means it is not looking"; dump; }
! saw "LANE-CONTRADICTED" \
  && ok "no real packet in this repository's 6 rows / 24 receipts is contradicted by its own diff (zero false positives on real history)" \
  || { no "the cross-check fires on this repo's real history — that is a false positive, the failure mode that kills this check"; dump; }
# The one recorded tiny in the store is 1 file / 116 changed lines. It must be
# reported as matching, not merely skipped.
bash "$GUARD" --verbose > "$WORK/out.txt" 2>&1
grep -qE 'store.s current median' "$WORK/out.txt" \
  && ok "the live scan prints the store's currently-recomputed medians beside the pinned thresholds, so drift is visible without being self-tuning" \
  || { no "the scan never shows the store's current medians — threshold drift would be invisible"; dump; }
grep -qE 'LANE-OK +gravito_test_harness_stdin_hang_a' "$WORK/out.txt" \
  && ok "gravito_test_harness_stdin_hang_a is LANE-OK: 1 file / 116 changed lines is genuinely tiny-sized, so its 6-rounds-against-a-2-round-budget failure was a BUDGET breach, not a mis-declaration (a different defect, needing a different guard)" \
  || { no "the repo's only lane=tiny row is not reported LANE-OK"; dump; }

echo "== 4. A tiny declared over an egregiously large commit FAILS =="
newfix bigtiny
mkreceipt bigtiny oversized tiny "$SHA_WIDE"
run_guard "$FR" "$FS"
[ "$GRC" != "0" ] \
  && ok "a receipt declaring lane=tiny over a ${PIN_MAX_FILES}+-file commit is REFUSED (exit $GRC)" \
  || { no "a tiny declared over 20 files passed — the hole is still open"; dump; }
saw "LANE-CONTRADICTED" \
  && ok "the failure is named LANE-CONTRADICTED, not buried in a generic message" \
  || { no "no LANE-CONTRADICTED line for a 20-file tiny"; dump; }
grep -q 'LANE-CONTRADICTED.*oversized' "$WORK/out.txt" \
  && ok "the LANE-CONTRADICTED line itself names the offending packet id" \
  || { no "the contradiction does not name the packet on its own line"; dump; }
grep -qE 'LANE-CONTRADICTED.*(20 file|files.*20)' "$WORK/out.txt" \
  && ok "the failure quotes the measured size, so the operator can judge it without re-running git" \
  || { no "the failure never states what git actually measured"; dump; }
# Each signal must fire on its own; OR, not AND.
newfix deeptiny
mkreceipt deeptiny oversized tiny "$SHA_DEEP"
run_guard "$FR" "$FS"
[ "$GRC" != "0" ] && saw "LANE-CONTRADICTED" \
  && ok "a tiny over 1 file / 3000 changed lines also fails — the churn signal fires on its own (OR, not AND)" \
  || { no "a 3000-line single-file tiny passed — the churn threshold is inert"; dump; }
# The same declaration made in the STORE rather than the receipt is the other
# half of the surface: tiny work legitimately closes with a row and no receipt.
newfix rowtiny
addrow rowtiny sneaky tiny --commits "$SHA_WIDE" --rounds 1 --agents 1 --tests-added 0 \
       --evidence git --note "$GOODNOTE"
run_guard "$FR" "$FS"
[ "$GRC" != "0" ] && saw "sneaky" \
  && ok "a lane=tiny declared in the metrics row with no receipt at all is still cross-checked (the row is a declaration surface too)" \
  || { no "a lane=tiny store row with no receipt escaped the cross-check"; dump; }

echo "== 5. A genuinely small tiny PASSES (specificity is asserted harder than sensitivity) =="
newfix smalltiny
mkreceipt smalltiny quick tiny "$SHA_SMALL"
run_guard "$FR" "$FS"
[ "$GRC" = "0" ] \
  && ok "a tiny over 2 files / 10 changed lines passes clean" \
  || { no "a genuinely small tiny was flagged — this is the false positive that gets the check deleted"; dump; }
! saw "LANE-CONTRADICTED" && ok "no contradiction reported for genuinely small work" \
  || { no "a 2-file tiny is reported as contradicted"; dump; }
# THE DELIBERATE RECALL SACRIFICE, asserted so it is a recorded decision rather
# than a bug someone discovers later. SHA_MID is 8 files / 2005 changed lines —
# the exact size of gravito_pilot_kit_a, a real substantive packet. Relabelled
# tiny it PASSES, because the thresholds are the MEDIAN of the substantive
# distribution, not its minimum. That is the price of specificity and it is paid
# knowingly.
newfix midtiny
mkreceipt midtiny mid tiny "$SHA_MID"
run_guard "$FR" "$FS"
[ "$GRC" = "0" ] \
  && ok "a tiny over 8 files / 2005 changed lines (the size of the real gravito_pilot_kit_a) PASSES — the stated recall sacrifice: thresholds sit at the median of the substantive distribution, so mis-declaration below the median is knowingly missed" \
  || { no "the check fires below its documented thresholds"; dump; }
newfix undertiny
mkreceipt undertiny near tiny ""
run_guard "$FR" "$FS"
[ "$GRC" = "0" ] && ok "a tiny with an empty commits section passes (nothing measurable is not evidence of something large)" \
  || { no "an unmeasurable tiny was flagged"; dump; }

echo "== 6. A substantive of ANY size PASSES — no upper bound on the lane that pays for the chain =="
newfix bigsub
mkreceipt bigsub huge substantive "$SHA_WIDE $SHA_DEEP" \
  "The disjoint file-ownership manifest for this fan-out: w*.txt to agent A, deep.txt to agent B."
addrow bigsub huge substantive --commits "$SHA_WIDE,$SHA_DEEP" --rounds 2 --agents 3 \
       --tests-added 9 --evidence git --note "$GOODNOTE" \
       --files 21 --insertions 3020 --deletions 0
run_guard "$FR" "$FS"
[ "$GRC" = "0" ] \
  && ok "a substantive over 21 files / 3020 changed lines passes — size is only evidence AGAINST a lane that waives gates" \
  || { no "a large substantive was flagged; this check must have no upper bound on substantive"; dump; }
! saw "LANE-CONTRADICTED" && ok "no contradiction reported for a large substantive" \
  || { no "a large substantive is reported as contradicted"; dump; }
# agent-swarm is likewise not a waived lane.
newfix bigswarm
mkreceipt bigswarm fan agent-swarm "$SHA_WIDE $SHA_DEEP"
run_guard "$FR" "$FS" --verbose
! saw "LANE-CONTRADICTED" \
  && ok "a large agent-swarm packet is not contradicted (only lanes that WAIVE gates are cross-checked)" \
  || { no "agent-swarm is being size-checked; it does not waive the chain"; dump; }

echo "== 7. A declaration with no commit PASSES — read-only and diagnosis leave no diff =="
for L in read-only diagnosis tiny; do
  newfix "nocommit-$L"
  mkreceipt "nocommit-$L" answer "$L" ""
  run_guard "$FR" "$FS"
  [ "$GRC" = "0" ] \
    && ok "a lane=$L declaration with no commit passes (an absent diff is not evidence of a large one)" \
    || { no "a commitless $L declaration was flagged — read-only/diagnosis work would go red for existing"; dump; }
done
# A commit that this repository does not contain must not be measured either.
newfix ghost
mkreceipt ghost phantom tiny "dedbeef1234567"
run_guard "$FR" "$FS"
[ "$GRC" = "0" ] \
  && ok "a tiny naming a commit this repository does not contain is unmeasurable, not guilty" \
  || { no "an unresolvable sha produced a lane failure"; dump; }

echo "== 8. The override is recorded, greppable, and costs something visible =="
JUST="mechanical rename across 20 files, no behaviour change; every hunk is the identifier swap and the suite is untouched"
newfix ovr
mkreceipt ovr renamed tiny "$SHA_WIDE" "$OVR: $JUST"
run_guard "$FR" "$FS"
[ "$GRC" = "0" ] \
  && ok "a tiny over 20 files with a recorded $OVR passes — the escape hatch exists, so the rule does not get broken quietly instead" \
  || { no "a properly recorded override did not buy a pass; a rule with no working fallback gets bypassed"; dump; }
saw "LANE-OVERRIDDEN" \
  && ok "the honoured override prints LANE-OVERRIDDEN on stdout — it is never a silent pass" \
  || { no "the override passed silently, which is the same as no rule"; dump; }
grep -rqF "$OVR" "$FR" \
  && ok "the override is greppable in the receipt store (grep -rn $OVR build-os/ enumerates every one that exists)" \
  || no "the override left no greppable trace"
# The cost: it must name this packet's measured file count, so a boilerplate
# override copied from another packet cannot be reused.
newfix ovrboiler
mkreceipt ovrboiler renamed tiny "$SHA_WIDE" "$OVR: a purely mechanical change, judged tiny by the reviewer, no behavioural difference at all"
run_guard "$FR" "$FS"
[ "$GRC" != "0" ] && saw "LANE-OVERRIDE-BAD" \
  && ok "an override that never names the measured file count FAILS — it cannot have been written against this packet's real size" \
  || { no "a boilerplate override bought a pass; the escape hatch costs nothing"; dump; }
newfix ovrshort
mkreceipt ovrshort renamed tiny "$SHA_WIDE" "$OVR: 20 files, fine"
run_guard "$FR" "$FS"
[ "$GRC" != "0" ] && saw "LANE-OVERRIDE-BAD" \
  && ok "a one-clause override FAILS — an override with no justification is a silent pass wearing a label" \
  || { no "a 15-char override bought a pass"; dump; }
# The override is honoured from the metrics note as well as the receipt.
newfix ovrnote
addrow ovrnote noted tiny --commits "$SHA_WIDE" --rounds 1 --agents 1 --evidence git \
       --note "fixture row; $OVR: mechanical rename across 20 files, judged tiny, no behavioural change and the suite is untouched"
run_guard "$FR" "$FS"
[ "$GRC" = "0" ] && saw "LANE-OVERRIDDEN" \
  && ok "an override recorded in the metrics note is honoured too (receipt OR note, as documented)" \
  || { no "an override in the metrics note was not honoured"; dump; }

echo "== 9. False-positive defences =="
# A receipt preamble routinely quotes a base and a merge-base. Measuring those
# would attribute another packet's diff to this one and manufacture a violation.
newfix preamble
mkreceipt preamble based tiny "$SHA_SMALL" ""
sed -i "s|^- \*\*Date:\*\*|- **Base:** \`$SHA_WIDE\` (merge-base \`$SHA_DEEP\`)\n- **Date:**|" "$FR/based.md"
run_guard "$FR" "$FS"
[ "$GRC" = "0" ] \
  && ok "a tiny whose PREAMBLE quotes a huge base/merge-base is judged on its Commits section only (base shas are not this packet's diff)" \
  || { no "the check measured a base/merge-base sha from the preamble — a manufactured false positive"; dump; }
# When a store row names the packet's commits, that curated attribution wins.
newfix curated
mkreceipt curated cur tiny "$SHA_WIDE $SHA_DEEP"
addrow curated cur tiny --commits "$SHA_SMALL" --rounds 1 --agents 1 --evidence git --note "$GOODNOTE"
run_guard "$FR" "$FS"
[ "$GRC" = "0" ] \
  && ok "the store row's commits column wins over receipt prose (record-packet.sh --verify-git has already reconciled it against git)" \
  || { no "receipt prose overrode the curated, git-verified attribution"; dump; }

echo "== 10. Vacuity — a check that cannot fire must not report success =="
newfix vac0
rm -f "$FR"/*.md
run_guard "$FR" "$FS"
[ "$GRC" != "0" ] && ok "zero receipts is REFUSED (a scan with nothing to scan is a blinded scanner, not a pass)" \
  || { no "zero receipts reported success"; dump; }
# Zero comparable rows: the thresholds are the median of a real distribution. If
# that distribution is empty the numbers are unmoored and a green means nothing.
# Every row in this fixture declares a WAIVED lane, so the calibration basis is
# empty — while a threshold is still being applied to a real, measurable diff.
# Nothing else here can refuse (the lone receipt is waived, so it owes no row,
# and 2 files / 10 lines is nowhere near a contradiction), which is what makes
# the refusal attributable to the empty basis alone.
mkdir -p "$WORK/vacbasis/receipts"
FR="$WORK/vacbasis/receipts"; FS="$WORK/vacbasis/store.tsv"
mkreceipt vacbasis lonely tiny "$SHA_SMALL"
addrow vacbasis lonely tiny --commits "$SHA_SMALL" --rounds 1 --agents 1 \
       --tests-added 0 --evidence git --note "$GOODNOTE"
run_guard "$FR" "$FS"
! grep -qE 'MISSING|HOLLOW|UNATTRIBUTED|LANE-CONTRADICTED' "$WORK/out.txt" \
  && ok "the empty-basis fixture has no other violation, so the refusal below is attributable to the empty calibration basis alone" \
  || { no "the empty-basis fixture refuses for some other reason — this assertion would pass for the wrong reason"; dump; }
[ "$GRC" != "0" ] \
  && ok "applying a threshold to a real diff with zero comparable rows is REFUSED — the thresholds have nothing here to be calibrated against" \
  || { no "the cross-check reported success with zero calibration rows; its thresholds are unmoored and it says so to nobody"; dump; }
grep -qE 'REFUSED.*calibrat' "$WORK/out.txt" \
  && ok "the refusal itself explains that the calibration basis is empty" \
  || { no "the vacuity refusal does not explain itself"; dump; }
# THE OTHER HALF OF THE VACUITY QUESTION, and the one that decides whether this
# guard is a guard or a tax. The basis must be measured FROM GIT, never read out
# of the row's `files` column. The column is optional — the archivist is told to
# write "-" for anything it did not measure — so an honest store that recorded
# rounds but not diffs is normal. A basis derived from that column would refuse
# every such store, which is a red guard on day one for most installs. This
# fixture's only row leaves files/insertions/deletions unmeasured and still
# calibrates, because its commit is real.
mkdir -p "$WORK/dashbasis/receipts"
FR="$WORK/dashbasis/receipts"; FS="$WORK/dashbasis/store.tsv"
mkreceipt dashbasis solo substantive "$SHA_MID"
mkreceipt dashbasis quick tiny "$SHA_SMALL"
addrow dashbasis solo substantive --commits "$SHA_MID" --rounds 1 --agents 1 \
       --tests-added 0 --evidence transcript --note "$GOODNOTE; diff cells deliberately left unmeasured"
run_guard "$FR" "$FS"
[ "$GRC" = "0" ] \
  && ok "a store whose diff cells are all '-' still calibrates and passes — the basis is measured from git, not read from the optional files column, so an honest dash-filled store is not red on day one" \
  || { no "a store that recorded rounds but not diffs makes the guard red; that is a tax on honest recording, not a guard"; dump; }
grep -qE 'calibrated from 1 non-waived-lane row' "$WORK/out.txt" \
  && ok "the dash-filled row still counted toward the calibration basis (git answered for it)" \
  || { no "a row with no recorded diff figures was dropped from the basis"; dump; }
# The refusal is nonetheless gated on a threshold actually being APPLIED, not on
# the basis alone. That gate cannot be killed independently here: any store that
# survives record-packet.sh --verify-git must contain a resolvable, non-empty
# commit, and such a row is necessarily EITHER a basis row (non-waived) OR a
# measurable subject (waived) — so "empty basis with nothing measured" is
# unreachable from a store the earlier gates admit. It is asserted as present
# rather than as independently falsifiable, and the narrower claim is the honest
# one (see the standing lesson on unkillable mutations in tool_router.md).
grep -q 'LANE_MEASURED' "$GUARD" \
  && ok "the vacuity refusal is gated on a threshold having been applied (defence in depth; not independently falsifiable given the verify-git precondition, and the script says so)" \
  || no "the vacuity refusal is not gated on threshold application"

echo "== 11. The guard is still an auditor — it writes nothing =="
SUMB="$(cksum "$STORE" | awk '{print $1,$2}')"
RSUMB="$(cksum "$SRC/build-os/receipts/gravito_test_harness_stdin_hang_a.md" | awk '{print $1,$2}')"
bash "$GUARD" --verbose > /dev/null 2>&1
SUMA="$(cksum "$STORE" | awk '{print $1,$2}')"
RSUMA="$(cksum "$SRC/build-os/receipts/gravito_test_harness_stdin_hang_a.md" | awk '{print $1,$2}')"
[ "$SUMB" = "$SUMA" ] && ok "the live store is byte-identical after a scan" || no "the guard mutated the store it audits"
[ "$RSUMB" = "$RSUMA" ] && ok "the live receipt is byte-identical after a scan" || no "the guard mutated a receipt"

echo "== 12. Lane declaration is documented as CHECKABLE, not merely stated =="
havei "$ROUTER" "checkable" \
  && ok "tool_router.md says a declared lane is checkable" \
  || no "the router still presents the lane as pure self-report"
havei "$ROUTER" "check-adoption.sh" \
  && ok "the router names the script that does the checking" \
  || no "the router never names check-adoption.sh"
havei "$ORCH" "check-adoption.sh" \
  && ok "build-orchestrator.md knows the lane it declares is cross-checked against git" \
  || no "the orchestrator declares lanes with no knowledge that they are verified"
havei "$ORCH" "$OVR" \
  && ok "build-orchestrator.md documents the override token" \
  || no "the orchestrator does not know the escape hatch exists, so it will break the rule instead of using it"
havei "$BUILDER" "$OVR" \
  && ok "builder.md documents the override token" \
  || no "builder.md does not name the override"
havei "$BUILDER" "lane" \
  && ok "builder.md addresses the lane it is building under" \
  || no "builder.md never mentions the lane"
havei "$ARCHIVIST" "$OVR" \
  && ok "archivist.md tells the closer how to record an override" \
  || no "archivist.md does not say how to record an override, so it will be written in a form nothing greps"
havei "$ARCHIVIST" "cross-check" \
  && ok "archivist.md states that the lane it writes is cross-checked" \
  || no "archivist.md presents the receipt's Lane line as unverified prose"
havei "$DOC" "LANE_TINY_MAX_FILES" \
  && ok "the metrics README documents the thresholds" \
  || no "the metrics README does not document the lane thresholds"
havei "$DOC" "$OVR" \
  && ok "the metrics README documents the override" \
  || no "the metrics README does not document the override"

echo "== 13. This suite is not vacuous about itself =="
NFIX="$(find "$WORK" -name 'store.tsv' 2>/dev/null | wc -l | tr -d ' ')"
[ "${NFIX:-0}" -ge 12 ] && ok "$NFIX independent fixture stores were built and scanned" \
  || no "only ${NFIX:-0} fixture stores were built — the helpers are not doing what these assertions assume"
NRCPT="$(find "$WORK" -path '*/receipts/*.md' 2>/dev/null | wc -l | tr -d ' ')"
[ "${NRCPT:-0}" -ge 15 ] && ok "$NRCPT fixture receipts were written and scanned" \
  || no "only ${NRCPT:-0} fixture receipts were written"
# The synthetic repo must really isolate each signal, or sections 4-6 prove
# nothing about OR-semantics.
WF="$(git -C "$SYNTH" show --numstat --format='' "$SHA_WIDE" | awk -F'\t' 'NF>=3{n++; c+=$1+$2} END{print n" "c}')"
DF="$(git -C "$SYNTH" show --numstat --format='' "$SHA_DEEP" | awk -F'\t' 'NF>=3{n++; c+=$1+$2} END{print n" "c}')"
[ "$WF" = "20 20" ] \
  && ok "the WIDE fixture commit is 20 files / 20 changed lines — over the file threshold ($PIN_MAX_FILES), under the churn one ($PIN_MAX_CHURN)" \
  || no "the WIDE fixture measured '$WF', not '20 20' — section 4's files-only assertion is not isolating the files signal"
[ "$DF" = "1 3000" ] \
  && ok "the DEEP fixture commit is 1 file / 3000 changed lines — under the file threshold, over the churn one" \
  || no "the DEEP fixture measured '$DF', not '1 3000' — the churn-only assertion is not isolating the churn signal"
MF="$(git -C "$SYNTH" show --numstat --format='' "$SHA_MID" | awk -F'\t' 'NF>=3{n++; c+=$1+$2} END{print n" "c}')"
[ "$MF" = "8 2005" ] \
  && ok "the MID fixture commit is 8 files / 2005 changed lines — the exact size of the real gravito_pilot_kit_a, and under BOTH thresholds, which is what makes the recall-sacrifice assertion in section 5 mean something" \
  || no "the MID fixture measured '$MF', not '8 2005' — the recall-sacrifice assertion is not calibrated to a real packet size"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
