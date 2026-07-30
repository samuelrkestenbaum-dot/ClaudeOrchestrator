#!/usr/bin/env bash
# Build OS — speed benchmark instrument tests (packet gravito_speed_benchmark_a).
#
# WHAT THIS PINS. The repo has argued "20x-100x faster" with zero instrumentation.
# This suite pins the instrument that replaces the argument with a measurement:
#
#   build-os/metrics/record-packet.sh    the recorder (append one validated row)
#   build-os/metrics/report-speed.sh     the report generator (render + total)
#   build-os/metrics/packet_metrics.tsv  the append-only store, seeded from real history
#   build-os/metrics/task_corpus.md      the fixed, versioned task corpus
#   build-os/metrics/COMPARISON_PROTOCOL.md  how a real A/B would be run
#   build-os/metrics/README.md           what the instrument can and cannot prove
#
# THE FAILURE MODES IT EXISTS TO CATCH, in the order a skeptic would probe them:
#   1. A report that silently DROPS ROWS — totals that do not equal the sum of the
#      rendered rows, or a body shorter than the store. A dropped row is how a
#      flattering number gets published without anyone lying on purpose.
#   2. A row with NO ATTRIBUTION — a number nobody can trace to a commit or a
#      transcript is not evidence, it is decoration.
#   3. A row that CONTRADICTS GIT — the one class of claim this repo can falsify
#      cheaply, so it must be falsified automatically.
#   4. A VACUOUS GREEN — a report generated from zero rows must fail loudly, not
#      print an empty table with a clean exit. An empty green table is worse than
#      a red one, because it looks like proof.
#   5. An UNHEDGED SPEED CLAIM — no artifact here may state 20x/100x as measured
#      fact, because no A/B was run here and none can be run from this harness.
#
# No network. Deterministic. Temp dirs only (the live store is READ, never
# written). Exits non-zero if any assertion fails, and prints the final
# "==== RESULT: N passed, M failed ====" line the orchestrator parses when it
# chains this suite into tests/build_os_tests.sh.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
METRICS="$SRC/build-os/metrics"
REC="$METRICS/record-packet.sh"
REP="$METRICS/report-speed.sh"
STORE="$METRICS/packet_metrics.tsv"
CORPUS="$METRICS/task_corpus.md"
PROTO="$METRICS/COMPARISON_PROTOCOL.md"
DOC="$METRICS/README.md"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }
have(){ grep -qF "$2" "$1"; }
havei(){ grep -qiF "$2" "$1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# The schema, restated here on purpose. If the recorder's header drifts, this
# suite must go red rather than silently follow it.
HEADER_COLS='packet_id	date	lane	rounds	wall_min	serial_min	agents	files	insertions	deletions	tests_added	defects_gated	defects_escaped	commits	evidence	note'
NCOLS=16

# ------------------------------------------------------------------ helpers --
# Data rows of a store: everything after the header, blanks and #-comments out.
datarows(){ tail -n +2 "$1" 2>/dev/null | grep -v '^[[:space:]]*$' | grep -v '^#'; }
nrows(){ datarows "$1" | wc -l | tr -d ' '; }

# Body rows of a rendered report's per-packet table, TOTAL row excluded.
rep_body(){ awk '/REPORT:PACKETS:START/{f=1;next} /REPORT:PACKETS:END/{f=0} f' "$1" \
            | grep '^| ' | grep -v '^| packet ' | grep -v '^|---' | grep -v 'TOTAL'; }
rep_total(){ awk '/REPORT:PACKETS:START/{f=1;next} /REPORT:PACKETS:END/{f=0} f' "$1" \
            | grep 'TOTAL'; }
# Cell k (1-based) of a markdown table row that starts with "| ".
cell(){ printf '%s\n' "$1" | awk -F'|' -v i="$2" '{v=$(i+1); gsub(/^[ \t]+|[ \t]+$/,"",v); gsub(/\*/,"",v); print v}'; }
# Sum of column k over a set of markdown rows, skipping "-" cells.
sumcol(){ local k="$2" t=0 v; while IFS= read -r line; do
    [ -n "$line" ] || continue
    v="$(cell "$line" "$k")"
    case "$v" in ''|-|*[!0-9.]*) continue ;; esac
    t="$(awk -v a="$t" -v b="$v" 'BEGIN{printf "%g", a+b}')"
  done < "$1"; printf '%s' "$t"; }

# Append one row to a store through the recorder. Returns the recorder's exit.
add(){ bash "$REC" --store "$1" "${@:2}" > "$WORK/add.out" 2>&1; }

echo "== 1. The instrument exists and is runnable =="
for f in "$REC" "$REP" "$STORE" "$CORPUS" "$PROTO" "$DOC"; do
  b="build-os/metrics/$(basename "$f")"
  [ -f "$f" ] && ok "$b exists" || no "$b is missing — the instrument is not installed"
done
for f in "$REC" "$REP"; do
  b="$(basename "$f")"
  [ -x "$f" ] && ok "$b is executable" || no "$b is not executable"
done
# Dependency-free is the point: a recorder nobody can run is a recorder nobody uses.
for f in "$REC" "$REP"; do
  head -n1 "$f" | grep -q '^#!/usr/bin/env bash' \
    && ok "$(basename "$f") is a bash script (no runtime to install)" \
    || no "$(basename "$f") does not start with a bash shebang"
done

echo "== 2. The store's schema is the declared 16-column TSV =="
HDR="$(head -n1 "$STORE" 2>/dev/null)"
[ "$HDR" = "$HEADER_COLS" ] && ok "store header is the canonical 16-column TSV header" \
  || { no "store header drifted from the canonical schema"; printf '      | got: %s\n' "$HDR"; }
HN="$(printf '%s' "$HDR" | awk -F'\t' '{print NF}')"
[ "${HN:-0}" = "$NCOLS" ] && ok "store header has exactly $NCOLS tab-separated columns" \
  || no "store header has ${HN:-0} columns, expected $NCOLS"
# Every data row must have the same shape. A ragged TSV is an unparseable store.
RAGGED="$(datarows "$STORE" | awk -F'\t' -v n="$NCOLS" 'NF!=n{print NR": "NF" fields"}')"
[ -z "$RAGGED" ] && ok "every data row in the live store has $NCOLS fields" \
  || { no "live store has ragged row(s)"; printf '      | %s\n' "$RAGGED"; }

echo "== 3. The recorder round-trips a record =="
RT="$WORK/roundtrip.tsv"
add "$RT" --packet demo_alpha --date 2026-07-30 --lane tiny --rounds 2 --wall-min 4.5 \
    --agents 1 --files 1 --insertions 12 --deletions 3 --tests-added 1 \
    --defects-gated 0 --defects-escaped 0 --commits abc1234 --evidence git \
    --note "fixture row; diff figures are fictional and never git-checked here"
RC=$?
[ "$RC" = "0" ] && ok "recorder accepts a well-formed record (exit 0)" \
  || { no "recorder rejected a well-formed record (exit $RC)"; sed 's/^/      | /' "$WORK/add.out"; }
[ -f "$RT" ] && ok "recorder created the store on first append" || no "recorder did not create the store"
[ "$(head -n1 "$RT" 2>/dev/null)" = "$HEADER_COLS" ] \
  && ok "a freshly created store is written with the canonical header" \
  || no "a freshly created store does not carry the canonical header"
[ "$(nrows "$RT")" = "1" ] && ok "one append produces exactly one data row" \
  || no "one append produced $(nrows "$RT") data rows"

# Round-trip means the values come back BYTE-IDENTICAL, field by field. A
# recorder that quietly reformats a number is a recorder that can change a claim.
R1="$(datarows "$RT" | head -n1)"
i=0
for expect in demo_alpha 2026-07-30 tiny 2 4.5 - 1 1 12 3 1 0 0 abc1234 git; do
  i=$((i+1))
  got="$(printf '%s' "$R1" | cut -f"$i")"
  [ "$got" = "$expect" ] && ok "field $i round-trips as \"$expect\"" \
    || no "field $i round-tripped as \"$got\", expected \"$expect\""
done
NOTE_BACK="$(printf '%s' "$R1" | cut -f16)"
[ "$NOTE_BACK" = "fixture row; diff figures are fictional and never git-checked here" ] \
  && ok "the note field round-trips intact (attribution survives storage)" \
  || no "the note field did not round-trip: \"$NOTE_BACK\""

echo "== 4. The store is append-only and hand-writable =="
add "$RT" --packet demo_beta --date 2026-07-30 --lane substantive --rounds 3 \
    --insertions 40 --evidence estimate --note "second fixture row, appended after the first"
[ "$(nrows "$RT")" = "2" ] && ok "a second append yields two rows" || no "second append did not yield two rows"
[ "$(datarows "$RT" | head -n1)" = "$R1" ] \
  && ok "the first row is byte-unchanged after the second append (append-only)" \
  || no "the first row changed when a second row was appended — the store is not append-only"
# Unspecified numeric fields default to "-", never to 0. A guessed zero is a lie
# with the same shape as a measurement.
R2="$(datarows "$RT" | tail -n1)"
[ "$(printf '%s' "$R2" | cut -f5)" = "-" ] \
  && ok "an unsupplied field defaults to \"-\" (unrecorded), not to 0" \
  || no "an unsupplied field did not default to \"-\" — an unmeasured cell must never read as a measurement"
# Hand-writable: a row typed straight into the file with printf must validate.
printf 'demo_manual\t2026-07-30\tdiagnosis\t1\t-\t-\t1\t-\t-\t-\t-\t-\t-\t-\ttranscript\thand-written row, typed directly into the TSV\n' >> "$RT"
bash "$REC" --store "$RT" --validate > "$WORK/val.out" 2>&1
[ $? = "0" ] && ok "a hand-typed row validates (recording is cheap enough to actually happen)" \
  || { no "a hand-typed row failed validation"; sed 's/^/      | /' "$WORK/val.out"; }

echo "== 5. The recorder refuses a malformed record, and appends nothing =="
BEFORE="$(nrows "$RT")"
reject(){ # reject <label> <args...>
  local label="$1"; shift
  bash "$REC" --store "$RT" "$@" > "$WORK/rej.out" 2>&1
  local rc=$?
  local after; after="$(nrows "$RT")"
  if [ "$rc" != "0" ] && [ "$after" = "$BEFORE" ]; then
    ok "rejected: $label (exit $rc, nothing appended)"
  elif [ "$rc" = "0" ]; then
    no "ACCEPTED a malformed record: $label"
  else
    no "rejected $label but the store grew from $BEFORE to $after rows"
  fi
}
reject "an unknown lane"            --packet x --lane turbo --evidence estimate --note "a lane that does not exist"
reject "a non-numeric round count"  --packet x --lane tiny --rounds many --evidence estimate --note "rounds must be a number"
reject "a negative-looking value"   --packet x --lane tiny --rounds -3 --evidence estimate --note "rounds cannot be negative"
reject "an empty packet id"         --packet "" --lane tiny --evidence estimate --note "a row with no packet id"
reject "an unknown evidence class"  --packet x --lane tiny --evidence vibes --note "evidence must name a real source"
reject "a missing note"             --packet x --lane tiny --evidence estimate
reject "an empty note"              --packet x --lane tiny --evidence estimate --note ""
reject "a one-word note"            --packet x --lane tiny --evidence estimate --note "fast"
reject "a tab inside a field"       --packet x --lane tiny --evidence estimate --note "$(printf 'a\tb note that breaks the TSV')"
reject "evidence=git with no commit" --packet x --lane tiny --evidence git --note "claims git evidence but names no commit"
reject "a malformed commit id"      --packet x --lane tiny --evidence git --commits zzz --note "not a hex object name"
reject "a malformed date"           --packet x --lane tiny --date 30-07-2026 --evidence estimate --note "dates are ISO 8601 or -"
# One row per packet. A second row for a packet already in the store would be
# double-counted by every total in the report, and the totals would still look
# internally consistent — the hardest kind of wrong number to notice.
reject "a duplicate packet_id"      --packet demo_alpha --lane tiny --evidence estimate --note "demo_alpha is already recorded in this store"
DUPMSG="$(bash "$REC" --store "$RT" --packet demo_alpha --lane tiny --evidence estimate --note "duplicate again, to read the message" 2>&1)"
printf '%s' "$DUPMSG" | grep -qi 'already' \
  && ok "the duplicate refusal names the collision" || no "the duplicate refusal does not explain itself: $DUPMSG"
# And the guard must not block a genuinely new packet id.
add "$RT" --packet demo_alpha_2 --lane tiny --evidence estimate --note "a different packet id, must still be accepted"
[ $? = "0" ] && ok "the duplicate guard does not block a new packet id" || no "the duplicate guard rejected a new packet id"
BEFORE="$(nrows "$RT")"

echo "== 6. --validate catches a corrupted store, and refuses an empty one =="
BAD="$WORK/bad.tsv"; cp "$RT" "$BAD"
printf 'broken_row\ttoo\tfew\tfields\n' >> "$BAD"
bash "$REC" --store "$BAD" --validate > "$WORK/val2.out" 2>&1
[ $? != "0" ] && ok "--validate rejects a store with a ragged row" || no "--validate passed a store with a ragged row"
grep -q 'broken_row' "$WORK/val2.out" \
  && ok "--validate names the offending row" || no "--validate does not name the offending row"

EMPTY="$WORK/empty.tsv"; printf '%s\n' "$HEADER_COLS" > "$EMPTY"
bash "$REC" --store "$EMPTY" --validate > "$WORK/val3.out" 2>&1
[ $? != "0" ] && ok "--validate refuses a header-only store (0 rows is not a pass)" \
  || no "--validate returned success on a store with zero rows — a vacuous green"

bash "$REC" --store "$WORK/nope.tsv" --validate > /dev/null 2>&1
[ $? != "0" ] && ok "--validate fails on a missing store" || no "--validate succeeded on a missing store"

echo "== 7. The report's totals equal the sum of its rendered rows =="
FIX="$WORK/fixture.tsv"
add "$FIX" --packet fix_one --date 2026-07-01 --lane tiny --rounds 2 --wall-min 10.0 \
    --agents 1 --files 2 --insertions 100 --deletions 5 --tests-added 4 \
    --defects-gated 1 --defects-escaped 0 --evidence estimate --note "fixture one, deterministic figures"
add "$FIX" --packet fix_two --date 2026-07-02 --lane substantive --rounds 3 --wall-min 20.0 \
    --agents 4 --files 6 --insertions 300 --deletions 10 --tests-added 26 \
    --defects-gated 2 --defects-escaped 1 --evidence estimate --note "fixture two, deterministic figures"
add "$FIX" --packet fix_fan --date 2026-07-03 --lane agent-swarm --rounds 3 --wall-min 10.0 \
    --serial-min 30.0 --agents 3 --files 12 --insertions 600 --deletions 20 --tests-added 70 \
    --evidence estimate --note "fixture fan-out, serial equivalent is 3.00x the parallel wall"

RPT="$WORK/report.md"
bash "$REP" --store "$FIX" > "$RPT" 2>"$WORK/report.err"
RRC=$?
[ "$RRC" = "0" ] && ok "report generator exits 0 on a valid store" \
  || { no "report generator exited $RRC on a valid store"; sed 's/^/      | /' "$WORK/report.err"; }

rep_body "$RPT" > "$WORK/body.txt"
rep_total "$RPT" > "$WORK/total.txt"
BODYN="$(grep -c . "$WORK/body.txt")"
[ "$BODYN" = "3" ] && ok "the per-packet table renders all 3 store rows" \
  || no "the per-packet table rendered $BODYN rows for a 3-row store — rows are being dropped"
[ "$BODYN" = "$(nrows "$FIX")" ] && ok "rendered row count equals the store's row count" \
  || no "rendered row count ($BODYN) != store row count ($(nrows "$FIX"))"
[ -s "$WORK/total.txt" ] && ok "the per-packet table carries a TOTAL row" || no "the per-packet table has no TOTAL row"

# Column order of the rendered table (1-based): packet date lane rounds wall_min
# agents files insertions tests_added defects_gated defects_escaped evidence.
# Sum every numeric column of the BODY and demand the TOTAL row agrees. This is
# the assertion that catches a report which drops a row from the body but keeps
# it in the total, or vice versa.
TOTROW="$(cat "$WORK/total.txt")"
for spec in "4:rounds:8" "5:wall-clock:40" "6:agents:8" "7:files:20" "8:insertions:1000" "9:tests added:100" "10:defects gated:3" "11:defects escaped:1"; do
  k="${spec%%:*}"; rest="${spec#*:}"; label="${rest%%:*}"; expect="${rest##*:}"
  s="$(sumcol "$WORK/body.txt" "$k")"
  t="$(cell "$TOTROW" "$k")"
  [ "$(awk -v a="$s" -v b="$t" 'BEGIN{print (a==b)?"y":"n"}')" = "y" ] \
    && ok "TOTAL $label ($t) equals the sum of the rendered rows ($s)" \
    || no "TOTAL $label ($t) != sum of rendered rows ($s) — the report is dropping or double-counting"
  [ "$(awk -v a="$s" -v b="$expect" 'BEGIN{print (a==b)?"y":"n"}')" = "y" ] \
    && ok "rendered $label sums to the fixture's known value ($expect)" \
    || no "rendered $label sums to $s, but the fixture's known value is $expect"
done

# A total that is right by accident is not right. Independently sum the STORE and
# demand the rendered TOTAL matches it — ground truth from outside the renderer.
for spec in "9:8:insertions" "11:9:tests added" "4:4:rounds"; do
  sc="${spec%%:*}"; rest="${spec#*:}"; rc2="${rest%%:*}"; label="${rest##*:}"
  s="$(datarows "$FIX" | awk -F'\t' -v k="$sc" '$k!="-"{t+=$k} END{printf "%g", t+0}')"
  t="$(cell "$TOTROW" "$rc2")"
  [ "$(awk -v a="$s" -v b="$t" 'BEGIN{print (a==b)?"y":"n"}')" = "y" ] \
    && ok "rendered TOTAL $label ($t) equals the store's own sum ($s)" \
    || no "rendered TOTAL $label ($t) contradicts the store's sum ($s)"
done

echo "== 7b. A column nobody measured totals to \"-\", never to 0 =="
# Summing an empty set to 0 is how "defects escaped: 0" gets published for a
# column that was never audited. It has the same shape as a real zero-defect
# record and none of the evidence. Caught in the live seeded report, where every
# defects_escaped cell is "-" and the TOTAL row read 0.
ZERO="$WORK/allempty.tsv"
add "$ZERO" --packet z_one --lane tiny --rounds 1 --insertions 10 --evidence estimate \
    --note "no defect columns recorded at all for this row"
add "$ZERO" --packet z_two --lane tiny --rounds 1 --insertions 20 --evidence estimate \
    --note "no defect columns recorded for this row either"
bash "$REP" --store "$ZERO" > "$WORK/zrep.md" 2>&1
ZT="$(rep_total "$WORK/zrep.md")"
[ "$(cell "$ZT" 10)" = "-" ] \
  && ok "an entirely unmeasured defects-gated column totals to \"-\"" \
  || no "an entirely unmeasured defects-gated column totalled to \"$(cell "$ZT" 10)\" — an unaudited column must never read as a measured zero"
[ "$(cell "$ZT" 11)" = "-" ] \
  && ok "an entirely unmeasured defects-escaped column totals to \"-\"" \
  || no "an entirely unmeasured defects-escaped column totalled to \"$(cell "$ZT" 11)\" — that is a fabricated clean record"
[ "$(cell "$ZT" 8)" = "30" ] \
  && ok "a column that WAS measured still totals normally (10 + 20 = 30)" \
  || no "a measured column totalled to \"$(cell "$ZT" 8)\", expected 30 — the empty-set guard has gone too far"
# And the live report must show it, since no packet in the corpus has been audited.
bash "$REP" --store "$STORE" > "$WORK/liverep.md" 2>&1
LT="$(rep_total "$WORK/liverep.md")"
[ "$(cell "$LT" 11)" = "-" ] \
  && ok "the live seeded report totals defects-escaped as \"-\" (no post-close audit has ever run)" \
  || no "the live seeded report claims a defects-escaped total of \"$(cell "$LT" 11)\" — no packet in the corpus was ever audited for escapes"

echo "== 8. The report renders the sections a buyer would read =="
for spec in "Rounds per lane:rounds-per-lane table" \
            "Round-budget compliance:round-budget compliance" \
            "Throughput:throughput per wall-clock minute" \
            "Fan-out speedup:fan-out speedup" \
            "cannot fill:the explicit list of empty cells"; do
  needle="${spec%%:*}"; label="${spec#*:}"
  grep -qiF "$needle" "$RPT" && ok "report renders $label" || no "report omits $label"
done
# Speedup must be COMPUTED from the row, not asserted. 30.0 serial / 10.0 parallel.
grep -q '3\.00' "$RPT" && ok "fan-out speedup is computed as 3.00x from serial 30.0 / parallel 10.0" \
  || { no "fan-out speedup is not computed correctly from the fixture (expected 3.00)"; grep -i 'speedup' -A4 "$RPT" | sed 's/^/      | /'; }
# Throughput: 100 insertions over 10.0 min = 10 insertions/min.
grep -qE '\| *fix_one *\|.* 10\.0' "$RPT" && ok "throughput renders fix_one's 100 insertions / 10.0 min" \
  || no "throughput row for fix_one does not render its computed rate"
# The compliance denominator must be stated. A rate with a hidden denominator of
# 1 reads like a rate measured over a hundred packets.
grep -qiE 'denominator|of [0-9]+ budgeted' "$RPT" \
  && ok "compliance states its denominator (a rate over n=1 must not read as a rate)" \
  || no "compliance rate is printed without stating its denominator"

echo "== 8b. The finding is stated BEFORE the first table, not buried in §6 =="
# ORDERING IS THE ASSERTION, not presence. A reader skims top-down: totals, then
# insertions/min, then a speedup with an "x" on it, and stops. If the one thing
# this report does not show — that Build OS is faster than anything — appears only
# in §6, the skimmer has already formed the opposite belief from two impressive
# numbers. §8 above only proves the disclosure exists SOMEWHERE. This proves it
# arrives first, so the ordering cannot silently regress.
FIND_LN="$(grep -n 'does not show that Build OS is faster than anything' "$RPT" | head -n1 | cut -d: -f1)"
S1_LN="$(grep -n '^## 1\. Per-packet record' "$RPT" | head -n1 | cut -d: -f1)"
FIRSTTBL_LN="$(grep -n '^| ' "$RPT" | head -n1 | cut -d: -f1)"
if [ -n "$FIND_LN" ]; then
  ok "the report states plainly that it does not show Build OS is faster than anything"
else
  no "the report never states plainly that it does not show Build OS is faster than anything"
fi
if [ -n "$FIND_LN" ] && [ -n "$S1_LN" ] && [ "$FIND_LN" -lt "$S1_LN" ]; then
  ok "that finding (line $FIND_LN) precedes the §1 marker (line $S1_LN)"
else
  no "the finding does not precede §1 (finding=${FIND_LN:-absent} §1=${S1_LN:-absent}) — a skimmer reads the totals and the speedup before ever meeting the caveat"
fi
if [ -n "$FIND_LN" ] && [ -n "$FIRSTTBL_LN" ] && [ "$FIND_LN" -lt "$FIRSTTBL_LN" ]; then
  ok "the finding precedes the report's very first table row (line $FIRSTTBL_LN)"
else
  no "the finding appears after the first table row (finding=${FIND_LN:-absent} first table=${FIRSTTBL_LN:-absent})"
fi
# The finding must say WHY, or it reads as ritual modesty rather than a fact.
PREAMBLE="$(sed -n "1,${S1_LN:-1}p" "$RPT")"
printf '%s' "$PREAMBLE" | grep -qi 'baseline arm' \
  && ok "the preamble names the absent baseline arm as the reason" \
  || no "the preamble does not name the missing baseline arm — the finding has no stated cause"
printf '%s' "$PREAMBLE" | grep -qiE 'cannot be produced|none can be' \
  && ok "the preamble states the baseline cannot be produced from this harness" \
  || no "the preamble does not state that no baseline can be produced here"

echo "== 8c. §5's speedup carries its qualifiers inline =="
# §5 is the section that gets pasted into a deck on its own. Every qualifier that
# makes 2.77x honest must travel WITH the number, in the same section — a caveat
# two sections away does not survive a copy-paste.
awk '/^## 5\./{f=1} /^## 6\./{f=0} f' "$RPT" > "$WORK/s5.txt"
[ -s "$WORK/s5.txt" ] && ok "§5 is extractable as a standalone block (as a reader would paste it)" \
  || no "§5 could not be extracted from the report"
s5have(){ grep -qiE "$1" "$WORK/s5.txt"; }
s5have 'no control arm|not a comparison against anything' \
  && ok "§5 says inline that there is no control arm" \
  || no "§5 does not say inline that no control arm exists — pasted alone it reads as a Build-OS-vs-nothing result"
s5have 'within Build OS|parallel-vs-serial' \
  && ok "§5 says inline that the comparison is parallel-vs-serial WITHIN Build OS" \
  || no "§5 does not scope the comparison to within Build OS"
s5have 'transcript-sourced|not reproducible from this repos' \
  && ok "§5 says inline that the serial figure is transcript-sourced, not reproducible from the repo" \
  || no "§5 does not state inline that the serial equivalent is not reproducible from this repository"
s5have 'agent execution only|agent-execution only' \
  && ok "§5 says inline that the figure covers agent execution only" \
  || no "§5 does not state inline that the figure excludes everything but agent execution"
s5have 'merge' && s5have 'orchestration' \
  && ok "§5 names the merge and orchestration costs that parallelism adds as excluded" \
  || no "§5 does not name the excluded merge/orchestration cost"
s5have 'upper bound' \
  && ok "§5 calls the speedup a structural upper bound rather than a realized saving" \
  || no "§5 does not label the speedup an upper bound — it reads as a saving somebody actually experienced"

echo "== 9. Vacuity guard — a report from zero rows fails loudly =="
bash "$REP" --store "$EMPTY" > "$WORK/vac.out" 2>"$WORK/vac.err"
VRC=$?
[ "$VRC" != "0" ] && ok "report on a header-only store exits non-zero ($VRC)" \
  || no "report on a header-only store exited 0 — an empty green table is worse than a red one"
grep -qi 'refus\|0 rows\|no rows\|empty' "$WORK/vac.err" "$WORK/vac.out" \
  && ok "report says out loud why it refused an empty store" || no "report refused an empty store silently"
grep -q 'TOTAL' "$WORK/vac.out" \
  && no "report printed a TOTAL row for a store with zero rows" \
  || ok "report printed no TOTAL row for a store with zero rows"
bash "$REP" --store "$WORK/nope.tsv" > /dev/null 2>&1
[ $? != "0" ] && ok "report fails on a missing store" || no "report succeeded on a missing store"

echo "== 10. Every seeded row carries an attribution =="
bash "$REC" --store "$STORE" --validate > "$WORK/lval.out" 2>&1
[ $? = "0" ] && ok "the live seeded store validates" \
  || { no "the live seeded store does not validate"; sed 's/^/      | /' "$WORK/lval.out"; }
LN="$(nrows "$STORE")"
[ "${LN:-0}" -ge 4 ] && ok "the live store carries $LN seeded rows (>= 4, not vacuous)" \
  || no "the live store carries only ${LN:-0} rows — the corpus below is too thin to mean anything"

# Attribution = a declared evidence class AND a note that says something. A row
# whose provenance is a shrug is exactly the row a buyer will throw out.
BADEV=""; BADNOTE=""; BADCOMMIT=""
while IFS=$'\t' read -r pid dt lane rnd wm sm ag fl ins del ta dg de cm ev nt; do
  case "$ev" in git|transcript|estimate|mixed) ;; *) BADEV="$BADEV $pid($ev)" ;; esac
  [ "${#nt}" -ge 12 ] || BADNOTE="$BADNOTE $pid"
  case "$ev" in
    git|mixed) [ "$cm" = "-" ] && BADCOMMIT="$BADCOMMIT $pid" ;;
  esac
done < <(datarows "$STORE")
[ -z "$BADEV" ]     && ok "every seeded row declares a known evidence class" || no "seeded row(s) with an unknown evidence class:$BADEV"
[ -z "$BADNOTE" ]   && ok "every seeded row carries a substantive attribution note" || no "seeded row(s) with a missing/trivial note:$BADNOTE"
[ -z "$BADCOMMIT" ] && ok "every git-attributed seeded row names its commit(s)" || no "git-attributed row(s) naming no commit:$BADCOMMIT"

# At least one row must be honest about being unmeasured, and at least one must
# be git-backed. A corpus that is all estimate proves nothing; a corpus that is
# all git is hiding the parts it could not measure.
datarows "$STORE" | awk -F'\t' '$15=="git"||$15=="mixed"' | grep -q . \
  && ok "the corpus contains at least one git-backed row" || no "no seeded row is git-backed"
datarows "$STORE" | awk -F'\t' '$15=="transcript"||$15=="estimate"' | grep -q . \
  && ok "the corpus contains at least one openly non-git row (nothing is dressed up as measured)" \
  || no "no seeded row is marked transcript/estimate — every unmeasured figure would be posing as measured"
datarows "$STORE" | awk -F'\t' '{for(i=4;i<=13;i++) if($i=="-"){print; exit}}' | grep -q . \
  && ok "at least one seeded cell is left empty rather than guessed" \
  || no "no seeded cell is empty — every unknown appears to have been filled in with a guess"

echo "== 11. A row that contradicts git fails =="
# PRECONDITION, named out loud before the checks that depend on it. Everything in
# §11 and §12 falsifies a seeded claim against THIS repository's history. A tree
# with that history stripped — a shallow clone, or a `git archive` export re-inited
# as a fresh repo — cannot run these checks at all, and the failures it produces
# read like defects in the verifier when they are nothing of the kind. This
# assertion exists so the log says which it is, once, before seven confusing lines.
MISSING_HIST=""
for c in 641527f c30f77d 5b956c0 68cae7a; do
  git -C "$SRC" cat-file -e "${c}^{commit}" 2>/dev/null || MISSING_HIST="$MISSING_HIST $c"
done
if [ -z "$MISSING_HIST" ]; then
  ok "the pinned commits §11/§12 verify against are present in this checkout"
else
  no "PRECONDITION UNMET — commit(s) absent from this checkout:$MISSING_HIST. §11/§12 falsify seeded claims against git history; without it their failures mean the HISTORY is missing, not that the verifier is broken"
fi

# The one class of claim this repo can falsify cheaply. 641527f is 1 file,
# 115 insertions, 1 deletion — verified from git in this session.
GOOD="$WORK/git_good.tsv"
add "$GOOD" --packet git_true --date 2026-07-30 --lane tiny --files 1 --insertions 115 \
    --deletions 1 --commits 641527f --evidence git --note "figures taken straight from git show --numstat"
bash "$REC" --store "$GOOD" --verify-git --repo "$SRC" > "$WORK/vg1.out" 2>&1
VG1=$?
[ "$VG1" = "0" ] && ok "--verify-git passes a row whose figures match git (exit 0)" \
  || { no "--verify-git failed a row that matches git (exit $VG1)"; sed 's/^/      | /' "$WORK/vg1.out"; }
grep -q 'VERIFIED' "$WORK/vg1.out" && ok "--verify-git reports VERIFIED for the matching row" \
  || no "--verify-git printed no VERIFIED line for a matching row"

for wrong in "--insertions 999:insertion count" "--files 7:file count" "--deletions 42:deletion count"; do
  flagval="${wrong%%:*}"; label="${wrong##*:}"
  LIE="$WORK/git_lie.tsv"; rm -f "$LIE"
  # shellcheck disable=SC2086
  add "$LIE" --packet git_lie --date 2026-07-30 --lane tiny --files 1 --insertions 115 \
      --deletions 1 $flagval --commits 641527f --evidence git \
      --note "deliberately contradicts git for the falsification test"
  bash "$REC" --store "$LIE" --verify-git --repo "$SRC" > "$WORK/vg2.out" 2>&1
  VG2=$?
  if [ "$VG2" != "0" ] && grep -q 'MISMATCH' "$WORK/vg2.out"; then
    ok "--verify-git fails a row whose $label contradicts git (exit $VG2, MISMATCH)"
  else
    no "--verify-git did NOT fail a row whose $label contradicts git (exit $VG2)"
    sed 's/^/      | /' "$WORK/vg2.out"
  fi
done

# Vacuity guard on the verifier itself. A verifier that verified nothing must not
# report success — that is how a blinded check goes green forever.
NOCOMMIT="$WORK/git_none.tsv"
add "$NOCOMMIT" --packet no_commits --lane substantive --rounds 2 --evidence estimate \
    --note "no commits named, so there is nothing here for git to verify"
bash "$REC" --store "$NOCOMMIT" --verify-git --repo "$SRC" > "$WORK/vg3.out" 2>&1
[ $? != "0" ] && ok "--verify-git refuses to report success when it verified 0 rows (not vacuous)" \
  || no "--verify-git returned success having verified nothing — it has gone blind"

# An unknown commit is UNVERIFIABLE, not a pass and not a mismatch. A copy of
# this repo without history must not turn into a silent green.
UNK="$WORK/git_unknown.tsv"
add "$UNK" --packet unknown_commit --lane tiny --files 1 --insertions 5 --commits 0000000 \
    --evidence git --note "names a commit that does not exist in this repository"
bash "$REC" --store "$UNK" --verify-git --repo "$SRC" > "$WORK/vg4.out" 2>&1
grep -q 'UNVERIFIABLE' "$WORK/vg4.out" \
  && ok "--verify-git reports UNVERIFIABLE for a commit absent from the repo" \
  || { no "--verify-git does not distinguish an absent commit from a verified one"; sed 's/^/      | /' "$WORK/vg4.out"; }

echo "== 11b. A fabricated commit makes --verify-git EXIT non-zero, not just print =="
# THE HOLE THIS CLOSES. --verify-git printed "UNVERIFIABLE <packet> <sha>" and then
# exited 0, as long as at least one OTHER row verified. A skeptic who checks only
# "$?" — which is the entire point of a falsifiable artifact — would read that 0 as
# "the store agrees with git" while a fabricated commit sat in it. For a tool whose
# whole pitch is "check me against your own history", the exit code must carry the
# finding, not just the transcript.
FAB="$WORK/git_fabricated.tsv"
add "$FAB" --packet fab_real --date 2026-07-30 --lane tiny --files 1 --insertions 115 \
    --deletions 1 --commits 641527f --evidence git \
    --note "a genuinely git-backed row, so the run is not vacuous and 1 row verifies"
add "$FAB" --packet fab_invented --date 2026-07-30 --lane tiny --files 3 --insertions 900 \
    --deletions 4 --commits deadbee --evidence git \
    --note "names a fabricated commit that does not exist in this repository"
bash "$REC" --store "$FAB" --verify-git --repo "$SRC" > "$WORK/vg5.out" 2>&1
VG5=$?
grep -q 'VERIFIED' "$WORK/vg5.out" \
  && ok "the fabricated-SHA fixture still verifies its one real row (the check is not vacuous)" \
  || { no "the fabricated-SHA fixture verified no row at all — this fixture proves nothing"; sed 's/^/      | /' "$WORK/vg5.out"; }
grep -q 'UNVERIFIABLE  fab_invented' "$WORK/vg5.out" \
  && ok "--verify-git names the fabricated row as UNVERIFIABLE" \
  || { no "--verify-git did not report the fabricated row"; sed 's/^/      | /' "$WORK/vg5.out"; }
[ "$VG5" != "0" ] \
  && ok "--verify-git exits non-zero ($VG5) when a row names a commit absent from the repo" \
  || { no "--verify-git exited 0 with a fabricated commit in the store — a skeptic checking only \$? would be told the store agrees with git"; sed 's/^/      | /' "$WORK/vg5.out"; }
grep -qi 'refus\|unverifiable' "$WORK/vg5.out" \
  && ok "--verify-git says on stderr why it refused" || no "--verify-git refused silently"
# The existing guarantee must survive the new one: a store where EVERY row verifies
# still exits 0. A verifier that fails on everything is as useless as one that
# passes on everything.
bash "$REC" --store "$GOOD" --verify-git --repo "$SRC" > "$WORK/vg6.out" 2>&1
[ $? = "0" ] && ok "--verify-git still exits 0 when every named commit exists and matches" \
  || { no "--verify-git now fails a store that fully verifies — the new guard is too broad"; sed 's/^/      | /' "$WORK/vg6.out"; }

echo "== 12. The live seeded store verifies against git =="
bash "$REC" --store "$STORE" --verify-git --repo "$SRC" > "$WORK/lvg.out" 2>&1
LVG=$?
[ "$LVG" = "0" ] && ok "every git-attributed seeded row matches git (exit 0)" \
  || { no "a seeded row contradicts git (exit $LVG)"; grep -E 'MISMATCH|ERROR' "$WORK/lvg.out" | sed 's/^/      | /'; }
NVER="$(grep -c 'VERIFIED' "$WORK/lvg.out")"; NVER="${NVER:-0}"
[ "$NVER" -ge 3 ] && ok "$NVER seeded rows were actually checked against git (>= 3, not vacuous)" \
  || no "only $NVER seeded rows were checked against git — the seed is mostly unverifiable"

echo "== 13. The task corpus is fixed, versioned and lane-assigned =="
grep -qiE 'corpus version' "$CORPUS" && ok "the corpus declares a version" || no "the corpus declares no version"
# The four task classes the packet requires, each with an expected lane and budget.
for spec in "T1:one-line comment fix" "T2:single-file bugfix" "T3:multi-file feature" "T4:three-way independent fan-out"; do
  id="${spec%%:*}"; label="${spec#*:}"
  have "$CORPUS" "$id" && ok "corpus defines task $id ($label)" || no "corpus is missing task $id ($label)"
done
CROWS="$(grep -cE '^\| *`?T[0-9]+`? *\|' "$CORPUS")"; CROWS="${CROWS:-0}"
[ "$CROWS" -ge 4 ] && ok "corpus task scanner sees $CROWS task rows (>= 4, not vacuous)" \
  || no "corpus task scanner matched $CROWS rows (expected >= 4) — it has gone blind"
# Every lane named in the corpus must be a lane the router actually defines.
BADLANE=""
for l in $(grep -oE '`(read-only|diagnosis|tiny|substantive|architecture|agent-swarm|[a-z-]+)`' "$CORPUS" \
           | tr -d '`' | sort -u); do
  case "$l" in
    read-only|diagnosis|tiny|substantive|architecture|agent-swarm) ;;
    *) continue ;;
  esac
  grep -qF "$l" "$SRC/build-os/memory/tool_router.md" || BADLANE="$BADLANE $l"
done
[ -z "$BADLANE" ] && ok "every lane the corpus assigns exists in the router" || no "corpus assigns lane(s) the router does not define:$BADLANE"
grep -qiE 'round budget|budget' "$CORPUS" && ok "corpus states a round budget per task" || no "corpus states no round budget"

echo "== 13b. The corpus states its own coverage gaps rather than implying none =="
# A corpus that says it "spans the lane ladder" while omitting two of the five
# lanes is describing itself inaccurately in its own opening sentence. The
# selection biases matter more than the tasks: they are what a buyer would find.
havei "$CORPUS" "read-only" && havei "$CORPUS" "diagnosis" \
  && ok "the corpus names the lanes it does NOT cover (read-only, diagnosis)" \
  || no "the corpus does not name the lanes it leaves untested — it implies full ladder coverage"
grep -qiE 'over-?sampl|over-?weight|25% of the corpus|best case' "$CORPUS" \
  && ok "the corpus states the T4 over-weighting caveat (fan-out is 25% of the corpus)" \
  || no "the corpus does not admit that three-way fan-out is over-represented relative to real work"
# The three missing task SHAPES. These are the corpus's blind spot, not a backlog:
# it measures building, and the product sells judgment.
for spec in "unfamiliar:debugging an unfamiliar codebase" \
            "input size:read-a-lot / write-a-little" \
            "don't build it:a task whose right answer is not to build"; do
  needle="${spec%%:*}"; label="${spec#*:}"
  havei "$CORPUS" "$needle" && ok "corpus names the missing shape: $label" \
    || no "corpus does not name the missing task shape: $label"
done
grep -qiE 'blind spot' "$CORPUS" \
  && ok "the corpus calls those omissions a blind spot in plain words" \
  || no "the corpus lists gaps without calling them a blind spot"

echo "== 14. The comparison protocol is specified, and honestly NOT run =="
for spec in "held constant:what is held constant" \
            "runs:the number of runs" \
            "corpus:the task corpus it runs on" \
            "not been run:the plain statement that it has not been run here"; do
  needle="${spec%%:*}"; label="${spec#*:}"
  havei "$PROTO" "$needle" && ok "protocol specifies $label" || no "protocol omits $label"
done
havei "$PROTO" "cannot" && ok "protocol states what cannot be measured from this harness" \
  || no "protocol does not state the harness limit"
# The hard constraint from the packet: no simulated A/B, ever.
if grep -qiE '\bsleep [0-9]|simulat(e|ed) (a |the )?(run|session|a/b)' "$PROTO" "$REC" "$REP" 2>/dev/null; then
  no "the instrument or protocol simulates a run — a faked A/B is worse than no A/B"
else
  ok "nothing in the instrument or protocol simulates a run"
fi

echo "== 14b. The protocol is actually RUNNABLE on both arms, and pre-registered =="
# A stopping rule denominated in ROUNDS cannot fire on arm A, because arm A is raw
# Claude Code and consumes zero delegated agent passes by definition. A DNF rule
# only one arm can trigger is not a stopping rule; it is a rule that silently
# exempts the control from ever failing to converge.
grep -qiE 'wall.?clock (minutes|min)[^.]*(stop|DNF|exceed)|(stop|DNF)[^.]*wall.?clock' "$PROTO" \
  && ok "the stopping rule is denominated in wall-clock, a unit BOTH arms have" \
  || no "the stopping rule is not denominated in a cross-arm unit — a rounds-only DNF can never fire on arm A"
grep -qiE 'arm B only|B-only|only arm B' "$PROTO" \
  && ok "the protocol marks rounds as an arm-B-only diagnostic rather than a both-arms measure" \
  || no "the protocol still presents rounds as measured on both arms while arm A has none"
# Two held constants that void the result if they move and nothing else catches them.
grep -qiE 'reasoning effort|thinking budget' "$PROTO" \
  && ok "reasoning effort / thinking budget is held constant (a separate knob from the model)" \
  || no "reasoning effort / thinking budget is not held constant — arm B could run hotter and nothing would catch it"
grep -qiE 'fresh session|cold context' "$PROTO" \
  && ok "fresh session / cold context is held constant (session state, not just filesystem state)" \
  || no "the protocol holds filesystem state constant but not session state — the larger confound"
# One pre-registered primary endpoint, declared before run 1.
grep -qiE 'pre-?register' "$PROTO" \
  && ok "the protocol pre-registers its analysis" \
  || no "the protocol pre-registers nothing — five outcome families over four tasks is a garden of forking paths"
grep -qiE 'primary endpoint' "$PROTO" \
  && ok "the protocol declares ONE primary endpoint" \
  || no "the protocol names no primary endpoint, so any of five outcomes can be reported as the finding"
# The design that will actually be executed, not just the one that sounds rigorous.
grep -qiE '16 runs' "$PROTO" \
  && ok "the protocol names a reduced-N plan (16 runs) as the recommended execution" \
  || no "the protocol offers only the 40-run design — 20-30 operator-hours, which means it will not be run at all"
grep -qiE 'ranges overlap' "$PROTO" \
  && ok "the reduced-N plan carries its pre-registered overlap rule" \
  || no "the reduced-N plan states no decision rule, so a null result can be narrated as a win"
# The operator cannot be blinded, and is the author.
grep -qiE 'blind' "$PROTO" \
  && ok "the protocol states the operator cannot be blinded to which arm he is in" \
  || no "the protocol does not admit the blinding failure — the same objection it raises against an agent measuring itself"
grep -qiE "author" "$PROTO" \
  && ok "the protocol names the operator's authorship of the product as a limit" \
  || no "the protocol does not name the operator as the product's author"

echo "== 15. Local only — no telemetry, no phone-home =="
NET="$(grep -nEi 'curl|wget|nc -|netcat|https?://[a-z]|ftp://|telemetry|phone.?home|analytics|api\.|POST ' "$REC" "$REP" 2>/dev/null \
        | grep -viE 'keepachangelog|semver\.org|no telemetry|never transmit|no network|#' )"
[ -z "$NET" ] && ok "the recorder and report generator contain no network egress" \
  || { no "network/telemetry construct found in the instrument"; printf '      | %s\n' "$NET"; }
havei "$DOC" "no telemetry" && ok "README states the store is local with no telemetry" \
  || no "README does not state the no-telemetry boundary"
havei "$DOC" "operator" && ok "README states the store is operator-owned" || no "README does not state operator ownership"

echo "== 16. No artifact states 20x/100x as a measured fact =="
# Every multiplier mention in build-os/metrics must sit on a line that hedges it.
UNHEDGED=""
while IFS= read -r line; do
  printf '%s' "$line" | grep -qiE 'unmeasured|not measured|never measured|unverified|claim|hypothes|argued|assert|would|no instrument|cannot' \
    || UNHEDGED="$UNHEDGED
      | $line"
done < <(grep -rniE '\b(20x|100x|20-100x|20x-100x)\b' "$METRICS" 2>/dev/null)
[ -z "$UNHEDGED" ] && ok "every 20x/100x mention in build-os/metrics is explicitly hedged as unmeasured" \
  || { no "an unhedged 20x/100x claim is present in build-os/metrics"; printf '%s\n' "$UNHEDGED"; }
# And the hedge scanner must have something to scan, or it proves nothing.
MULT="$(grep -rocE '\b(20x|100x|20-100x|20x-100x)\b' "$METRICS" 2>/dev/null | awk -F: '{t+=$2} END{print t+0}')"
[ "${MULT:-0}" -ge 1 ] && ok "the multiplier scanner sees $MULT mention(s) to check (not vacuous)" \
  || no "the multiplier scanner found nothing to check — the artifact never confronts the claim it exists to test"

echo "== 17. The instrument's own limits are written down =="
for spec in "cannot:what the instrument cannot prove" \
            "A/B:the A/B that was not run" \
            "sample:the sample size" ; do
  needle="${spec%%:*}"; label="${spec#*:}"
  havei "$DOC" "$needle" && ok "README states $label" || no "README omits $label"
done
grep -qiE 'wall.?clock' "$DOC" && ok "README explains the wall-clock column's provenance" \
  || no "README does not explain wall-clock provenance"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
