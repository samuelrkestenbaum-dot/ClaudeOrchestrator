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

# `any` ANSWERS "did the upstream stage emit at least one line?" AND IT IS NOT A
# `grep -q .` WITH A LONGER NAME. THE DRAINING IS THE WHOLE POINT: `any` reads to
# EOF and only then decides, so the producer always reaches EOF and `pipefail`
# has no 141 to promote. IT IS ALSO WIDER THAN `grep -q .`: on input that is
# only blank lines `any` returns 0 where `grep -q .` returns 1. Unreachable at
# all three §10 call sites — the producers print whole non-empty rows and
# `datarows` strips blanks — but stated here rather than left to be found.
#
# DEFECT-0013. `grep -q` exits the instant it matches; its producer is still
# writing, gets SIGPIPE, dies 141, and `set -o pipefail` (line 32) promotes that
# 141 to the whole pipeline's status. Measured at §10: the shipped `grep -q`
# form failed 628/4000 (15.70%), `PIPESTATUS=[0 141 0]`; `any` failed 0/4000.
#
# ONE-DIRECTIONALITY IS A PROPERTY OF THE `&& ok || no` POLARITY, NOT OF THE
# CLASS: at that polarity the race can only manufacture a false FAIL, but
# INVERTED — `producer | grep -q . && no || ok` — the same 141 routes to `ok`
# and the identical race yields a FALSE PASS that masks a real failure. Measured
# counterexample, LATENT AND NOT LIVE: tests/build_os_maintenance_tests.sh:414
# is written at that inverted polarity and returned non-zero 2000/2000 at
# 270890 B, 0/2000 draining. It needs >64 KiB — ~1100+ leftover paths in a
# directory the test expects EMPTY — and §28 cannot see it: its producer is
# `find`. Recorded, not fixed; that file is outside this packet's ownership.
any(){ awk 'BEGIN{r=1} {r=0} END{exit r}'; }

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
#
# ALL THREE USE `any` AND NOT `grep -q`, AND ONLY THE FIRST WAS EVER OBSERVED TO
# FLAP. That asymmetry is measured, not assumed: the first assertion's `awk`
# emits 72147 bytes — past the 64 KiB pipe buffer, so it MUST issue more than one
# write and can be caught mid-stream — and it failed 628/4000. The second and
# third emit 462 and 519 bytes, one write each, and failed 0/4000 and 0/4000.
#
# THE OTHER TWO ARE CONVERTED ANYWAY, AND NOT FOR TIDINESS. Their safety is a
# property of TODAY'S FILE SIZE, not of their structure — the third is the worst
# structurally, its `awk` stopping after 519 bytes while `datarows` still has
# 72 KB to push — and it survives only because mawk's `exit` happens not to kill
# its producer on this toolchain. MEASURED OVER N=200 TRIALS EACH, producer
# killed: mawk `exit` 0/200 (0.0%); `grep -q .` 16/200 (8.0%); `grep -m1 .`
# 19/200 (9.5%); `head -1` 105/200 (52.5%); `sed -n '1p;1q'` 200/200 (100%);
# bare `read` 5/5 (n=5 cannot tell 8% from 100% — that is why N=200).
datarows "$STORE" | awk -F'\t' '$15=="git"||$15=="mixed"' | any \
  && ok "the corpus contains at least one git-backed row" || no "no seeded row is git-backed"
datarows "$STORE" | awk -F'\t' '$15=="transcript"||$15=="estimate"' | any \
  && ok "the corpus contains at least one openly non-git row (nothing is dressed up as measured)" \
  || no "no seeded row is marked transcript/estimate — every unmeasured figure would be posing as measured"
datarows "$STORE" | awk -F'\t' '{for(i=4;i<=13;i++) if($i=="-"){print}}' | any \
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

# ===========================================================================
# RULINGS 2, 3 and 6 (operator-ruled 2026-08-05, PACKET-0045 fix round).
# Sections 18-20 drive bench/run-corpus.sh through a STUB claude CLI so every
# path executes for real — no network, no live model, deterministic streams.
# ===========================================================================
BENCH="$SRC/bench/run-corpus.sh"
BSEED="$SRC/bench/seed-bench-repo.sh"

echo "== 18. RULING 2 — degraded runs are unmistakably degraded, driven both directions =="
[ -f "$BENCH" ] && [ -x "$BENCH" ] && ok "bench/run-corpus.sh exists and is executable" \
  || no "bench/run-corpus.sh is missing or not executable — every drive below is meaningless"
[ -f "$BSEED" ] && ok "bench/seed-bench-repo.sh exists (the harness can seed)" \
  || no "bench/seed-bench-repo.sh is missing"

# The stub CLI: answers --version, and for a run emits the stream named by
# BENCH_FAKE_STREAM. It exercises the REAL harness end to end — seeding, the
# gate, the poller, the oracle, the witnesses — with only the model call faked.
BIN="$WORK/stubbin"; mkdir -p "$BIN"
cat > "$BIN/claude" <<'STUB'
#!/usr/bin/env bash
if [ "${1:-}" = "--version" ]; then echo "stub-claude 0.0.0 (bench test fixture)"; exit 0; fi
[ -n "${BENCH_FAKE_STREAM:-}" ] && [ -f "$BENCH_FAKE_STREAM" ] && cat "$BENCH_FAKE_STREAM"
exit 0
STUB
chmod +x "$BIN/claude"

# DRIVE 1 — the canonical T2 refusal still fires when prerequisites are absent.
D1="$WORK/bench_d1"
PATH="$BIN:$PATH" bash "$BENCH" --task T2 --arm raw --run 1 --outdir "$D1" > "$WORK/d1.out" 2>&1
RC=$?
R1F="$D1/run_record.txt"
{ [ "$RC" = "0" ] && grep -qF 'status: IMPOSSIBLE' "$R1F" 2>/dev/null; } \
  && ok "DRIVE 1: T2 without Bash and without the flag refuses to run — status IMPOSSIBLE, no numbers" \
  || { no "DRIVE 1 FAILED: the canonical T2 refusal did not fire (exit $RC)"; tail -5 "$WORK/d1.out" | sed 's/^/      | /'; }
[ ! -f "$D1/stream.jsonl" ] \
  && ok "DRIVE 1: no model invocation happened behind the refusal (no stream artifact)" \
  || no "DRIVE 1: the refusal path still invoked the CLI"
grep -qF 'canonical_comparison_eligible: false' "$R1F" 2>/dev/null \
  && ok "DRIVE 1: the refusal record is explicitly ineligible for canonical comparison" \
  || no "DRIVE 1: the refusal record does not state canonical_comparison_eligible: false"
grep -qE '^benchmark_mode:' "$R1F" 2>/dev/null \
  && no "DRIVE 1: a NON-RUN carries a benchmark_mode — a refusal is neither canonical nor degraded" \
  || ok "DRIVE 1: the non-run record carries no benchmark_mode, and absence is INVALID for any comparison by rule"

# The degraded stream fixture — it deliberately carries every hostile shape at
# once: a valid tool_use (id A), a byte-identical DUPLICATE of it (same id), an
# assistant block whose raw bytes contain "type":"tool_use" without being a
# tool_use block, one line that is not JSON, one tool_result answering A, a
# second tool_use (id B) that nothing answers, and the final result object.
FAKE2="$WORK/stream_degraded.jsonl"
cat > "$FAKE2" <<'JSONL'
{"type":"assistant","message":{"content":[{"type":"tool_use","id":"toolu_A","name":"Read","input":{}}]}}
{"type":"assistant","message":{"content":[{"type":"tool_use","id":"toolu_A","name":"Read","input":{}}]}}
{"type":"assistant","message":{"content":[{"type":"text","text":"prose block","meta":{"type":"tool_use"}}]}}
this line is deliberately not JSON
{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"toolu_A","content":"ok"}]}}
{"type":"assistant","message":{"content":[{"type":"tool_use","id":"toolu_B","name":"Bash","input":{}}]}}
{"type":"result","duration_api_ms":1234,"num_turns":3,"total_cost_usd":0.01,"is_error":false,"stop_reason":"end_turn","usage":{"input_tokens":10,"output_tokens":20,"cache_creation_input_tokens":0,"cache_read_input_tokens":0},"modelUsage":{"stub-model":{"contextWindow":200000}},"permission_denials":[]}
JSONL

# DRIVE 2 — the supported flag permits execution.
D2="$WORK/bench_d2"
PATH="$BIN:$PATH" BENCH_FAKE_STREAM="$FAKE2" bash "$BENCH" --task T2 --arm raw --run 1 \
  --outdir "$D2" --i-accept-a-degraded-run --degraded-reason "test drive: headless agent denied Bash" \
  > "$WORK/d2.out" 2> "$WORK/d2.err"
RC=$?
R2F="$D2/run_record.txt"
{ [ "$RC" = "0" ] && [ -f "$D2/stream.jsonl" ] && grep -qF 'wall_clock_s:' "$R2F" 2>/dev/null; } \
  && ok "DRIVE 2: --i-accept-a-degraded-run permits the T2 run to execute (exit 0, full record produced)" \
  || { no "DRIVE 2 FAILED: the supported degraded flag did not permit execution (exit $RC)"; tail -5 "$WORK/d2.err" | sed 's/^/      | /'; }
grep -qiF 'WARNING' "$WORK/d2.err" \
  && ok "DRIVE 2: the degraded run displays a clear warning" \
  || no "DRIVE 2: no warning was displayed for a degraded run"

# DRIVE 3 — a degraded result carries ALL required provenance fields.
for fld in 'benchmark_mode: degraded' 'degraded_reason: test drive: headless agent denied Bash' 'degraded_authorization: --i-accept-a-degraded-run' 'canonical_comparison_eligible: false'; do
  grep -qF "$fld" "$R2F" 2>/dev/null \
    && ok "DRIVE 3: degraded record carries \"$fld\"" \
    || no "DRIVE 3 FAILED: degraded record lacks \"$fld\""
done
[ -f "$D2/DEGRADED" ] \
  && ok "DRIVE 3: the artifact directory itself carries a DEGRADED marker file" \
  || no "DRIVE 3: no DEGRADED marker — the artifacts are not unmistakably degraded"
head -n1 "$R2F" 2>/dev/null | grep -qF 'DEGRADED, NOT A CORPUS RESULT' \
  && ok "DRIVE 3: the record's TITLE LINE is byte-visibly degraded" \
  || no "DRIVE 3: the degraded record's title is indistinguishable from a canonical one"

# DRIVES 4 and 5 — the kill-switches, asserted as absences that would go red the
# moment the emission is removed or flipped.
grep -cE '^benchmark_mode: degraded$' "$R2F" 2>/dev/null | grep -qx '1' \
  && ok "DRIVE 4: benchmark_mode: degraded is present exactly once — removing it kills this test" \
  || no "DRIVE 4 FAILED: benchmark_mode: degraded is absent or duplicated in the degraded record"
grep -qF 'canonical_comparison_eligible: true' "$R2F" 2>/dev/null \
  && no "DRIVE 5 FAILED: a degraded result claims canonical_comparison_eligible: true" \
  || ok "DRIVE 5: the degraded result nowhere claims canonical eligibility — setting it true kills this test"

# DRIVE 6 — a degraded row cannot enter canonical comparison or aggregate.
# THE REFUSAL LIVES IN record-packet.sh, THE RECORDING PATH, AND HERE IS WHY IT
# IS THE REAL CONSUMER: no canonical A/B comparator exists in this tree (the
# protocol has never run), so the only aggregation surface is
# packet_metrics.tsv, whose totals report-speed.sh renders into benchmark
# claims — and that store's single governed entry is record-packet.sh. Refusing
# at the door keeps the poisoned row out of EVERY downstream consumer, present
# and future, where a render-time filter would protect only one.
DSTORE="$WORK/degraded_store.tsv"
bash "$REC" --store "$DSTORE" --packet deg_try --lane tiny --evidence transcript \
  --note "T2 degraded bench run; benchmark_mode=degraded; canonical_comparison_eligible=false" \
  > "$WORK/d6.out" 2>&1
{ [ $? != "0" ] && [ ! -f "$DSTORE" ]; } \
  && ok "DRIVE 6: the recording path REFUSES a benchmark_mode=degraded row (nothing appended)" \
  || { no "DRIVE 6 FAILED: a degraded row entered the aggregation store"; sed 's/^/      | /' "$WORK/d6.out" | head -3; }
bash "$REC" --store "$DSTORE" --packet deg_spoof --lane tiny --evidence transcript \
  --note "bench run; benchmark_mode: degraded; canonical_comparison_eligible=true — spoofed eligibility" \
  > "$WORK/d6b.out" 2>&1
{ [ $? != "0" ] && [ ! -f "$DSTORE" ]; } \
  && ok "DRIVE 6/5: spoofing canonical_comparison_eligible=true on a degraded row is STILL refused — the mode wins" \
  || no "DRIVE 6/5 FAILED: a degraded row claiming eligibility entered the store"
bash "$REC" --store "$DSTORE" --packet canon_ok --lane tiny --evidence transcript \
  --note "T1 canonical bench run; benchmark_mode=canonical; canonical_comparison_eligible=true" \
  > "$WORK/d6c.out" 2>&1
[ $? = "0" ] \
  && ok "DRIVE 6 (other direction): a canonical-marked row is still accepted — the refusal is not a blanket ban" \
  || { no "DRIVE 6 FAILED: the canonical control row was refused"; sed 's/^/      | /' "$WORK/d6c.out" | head -3; }
# ...and --validate applies the SAME refusal, so a hand-typed degraded row
# cannot enter around the recorder.
cp "$DSTORE" "$WORK/degraded_hand.tsv"
printf 'deg_hand\t2026-08-05\ttiny\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\ttranscript\thand-typed degraded row; benchmark_mode=degraded; kept out of aggregation\n' >> "$WORK/degraded_hand.tsv"
bash "$REC" --store "$WORK/degraded_hand.tsv" --validate > "$WORK/d6d.out" 2>&1
[ $? != "0" ] \
  && ok "DRIVE 6: --validate refuses a store carrying a hand-typed degraded row (no path around the door)" \
  || no "DRIVE 6 FAILED: --validate passed a store containing a degraded row"

# DRIVE 7 — the old FORCE_DEGRADED=1 silent path is GONE.
D7="$WORK/bench_d7"
PATH="$BIN:$PATH" FORCE_DEGRADED=1 bash "$BENCH" --task T2 --arm raw --run 1 --outdir "$D7" > "$WORK/d7.out" 2>&1
RC=$?
{ [ "$RC" = "0" ] && grep -qF 'status: IMPOSSIBLE' "$D7/run_record.txt" 2>/dev/null && [ ! -f "$D7/stream.jsonl" ]; } \
  && ok "DRIVE 7: FORCE_DEGRADED=1 no longer runs anything — the refusal fires as if it were unset" \
  || no "DRIVE 7 FAILED: FORCE_DEGRADED=1 still changes behaviour (exit $RC)"
grep -qiF 'BYPASSED_via_FORCE_DEGRADED' "$D7/run_record.txt" 2>/dev/null \
  && no "DRIVE 7: the record still names the removed FORCE_DEGRADED disposition" \
  || ok "DRIVE 7: no record names the removed FORCE_DEGRADED disposition"

# DRIVE 8 — an unknown degraded mechanism refuses.
PATH="$BIN:$PATH" bash "$BENCH" --task T2 --arm raw --run 1 --force-degraded > "$WORK/d8.out" 2>&1
{ [ $? = "2" ] && grep -qiF 'unknown argument' "$WORK/d8.out"; } \
  && ok "DRIVE 8: an invented --force-degraded flag is refused as an unknown argument (exit 2)" \
  || no "DRIVE 8 FAILED: an unknown degraded mechanism was not refused"
D8="$WORK/bench_d8"
PATH="$BIN:$PATH" bash "$BENCH" --task T2 --arm raw --run 1 --outdir "$D8" --i-accept-a-degraded-run > "$WORK/d8b.out" 2>&1
{ [ $? = "2" ] && grep -qiF 'REQUIRES --degraded-reason' "$WORK/d8b.out"; } \
  && ok "DRIVE 8/flag: --i-accept-a-degraded-run WITHOUT an explicit reason is refused (exit 2)" \
  || no "DRIVE 8/flag FAILED: the flag ran without a recorded reason"

echo "== 19. RULING 3 — TOOL_CALLS has two genuinely independent witnesses =="
# The canonical control run: ONE valid tool_use, answered by ONE tool_result.
FAKE1="$WORK/stream_canonical.jsonl"
cat > "$FAKE1" <<'JSONL'
{"type":"assistant","message":{"content":[{"type":"tool_use","id":"toolu_X","name":"Edit","input":{}}]}}
{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"toolu_X","content":"ok"}]}}
{"type":"result","duration_api_ms":900,"num_turns":2,"total_cost_usd":0.005,"is_error":false,"stop_reason":"end_turn","usage":{"input_tokens":5,"output_tokens":9,"cache_creation_input_tokens":0,"cache_read_input_tokens":0},"modelUsage":{"stub-model":{"contextWindow":200000}},"permission_denials":[]}
JSONL
D9="$WORK/bench_canonical"
PATH="$BIN:$PATH" BENCH_FAKE_STREAM="$FAKE1" bash "$BENCH" --task T1 --arm raw --run 1 --outdir "$D9" \
  > "$WORK/d9.out" 2>&1
RC=$?
R9F="$D9/run_record.txt"
[ "$RC" = "0" ] && [ -f "$R9F" ] \
  && ok "the canonical T1 control run executes against the stub stream (exit 0)" \
  || { no "the canonical control run failed (exit $RC) — the witness checks below are meaningless"; tail -5 "$WORK/d9.out" | sed 's/^/      | /'; }
grep -qF 'benchmark_mode: canonical' "$R9F" 2>/dev/null \
  && ok "RULING 2 (other direction): a canonical run says benchmark_mode: canonical explicitly" \
  || no "the canonical record does not carry benchmark_mode: canonical"
grep -qF 'canonical_comparison_eligible: true' "$R9F" 2>/dev/null \
  && ok "a canonical run states canonical_comparison_eligible: true explicitly, never by absence" \
  || no "the canonical record does not state its eligibility explicitly"
head -n1 "$R9F" 2>/dev/null | grep -qF 'DEGRADED' \
  && no "the canonical record's title claims degradation" \
  || ok "canonical vs degraded records differ from the TITLE LINE down (byte-wise unmistakable)"
[ ! -f "$D9/DEGRADED" ] \
  && ok "no DEGRADED marker appears beside a canonical run's artifacts" \
  || no "a canonical run's artifact directory carries a DEGRADED marker"
# One valid event -> one parsed event, in agreement across both witnesses.
grep -qE '^tool_use_events: 1 ' "$R9F" 2>/dev/null \
  && ok "one valid tool_use event parses as exactly one tool_use_events (witness 1)" \
  || no "witness 1 did not count exactly 1 for a single valid event"
grep -qE '^tool_result_events: 1 ' "$R9F" 2>/dev/null \
  && ok "its answering tool_result parses as exactly one tool_result_events (witness 2)" \
  || no "witness 2 did not count exactly 1 for a single answered call"
grep -qE '^tool_calls: 1$' "$R9F" 2>/dev/null \
  && ok "agreeing witnesses render tool_calls: 1 with no DISAGREE marker" \
  || no "agreeing witnesses did not render a clean tool_calls value"

# The hostile degraded stream from section 18, re-read for the witness claims.
grep -qE '^tool_use_events: 2 ' "$R2F" 2>/dev/null \
  && ok "prose whose raw bytes contain \"type\":\"tool_use\" does NOT increment — 2 events counted, not 3 (nothing greps)" \
  || { no "witness 1 miscounted the hostile stream (wanted 2 distinct tool_use ids)"; grep '^tool_use_events' "$R2F" 2>/dev/null | sed 's/^/      | /'; }
grep -qF 'raw blocks=3' "$R2F" 2>/dev/null \
  && ok "the duplicated tool_use id is handled deterministically — counted once, raw block count reported beside it" \
  || no "duplicate handling is not visible (no raw block count in the record)"
grep -qE '^stream_invalid_lines: 1 of 7' "$R2F" 2>/dev/null \
  && ok "the malformed line is REPORTED as invalid (1 of 7), never silently skipped" \
  || { no "the malformed stream line was not reported"; grep '^stream_invalid_lines' "$R2F" 2>/dev/null | sed 's/^/      | /'; }
grep -qE '^tool_result_events: 1 ' "$R2F" 2>/dev/null \
  && ok "witness 2 counts 1 completed execution — independently derived from executor-emitted user events" \
  || no "witness 2 miscounted the hostile stream"
grep -qF 'DISAGREE tool_use_events=2 tool_result_events=1' "$R2F" 2>/dev/null \
  && ok "the 2-vs-1 disagreement is VISIBLE in the DISAGREE shape, not silently reconciled" \
  || { no "the witness disagreement was hidden"; grep '^tool_calls' "$R2F" 2>/dev/null | sed 's/^/      | /'; }
grep -qF 'WITNESS 1' "$R2F" 2>/dev/null && grep -qF 'WITNESS 2' "$R2F" 2>/dev/null \
  && ok "the record NAMES exactly what each witness measures, beside its number" \
  || no "the record does not name what its witnesses measure"
grep -qF 'tool_failures:' "$R2F" 2>/dev/null \
  && ok "requests, executions and failures are not collapsed — tool_failures is its own field" \
  || no "tool_failures is not emitted as a separate field"
grep -qE '^tool_failures: 0 ' "$R2F" 2>/dev/null \
  && ok "zero observed failures over a parsed tool_result channel is a measured 0, not a guess" \
  || no "tool_failures did not read 0 over a stream whose one result carried no error"
# unavailable-not-zero: a stream with NO user events cannot establish the
# executor-side fields, and the harness must say so rather than print 0.
FAKE3="$WORK/stream_nouser.jsonl"
cat > "$FAKE3" <<'JSONL'
{"type":"assistant","message":{"content":[{"type":"tool_use","id":"toolu_Y","name":"Read","input":{}}]}}
{"type":"result","duration_api_ms":1,"num_turns":1,"total_cost_usd":0.001,"is_error":false,"stop_reason":"end_turn","usage":{"input_tokens":1,"output_tokens":1,"cache_creation_input_tokens":0,"cache_read_input_tokens":0},"modelUsage":{"stub-model":{"contextWindow":200000}},"permission_denials":[]}
JSONL
D10="$WORK/bench_nouser"
PATH="$BIN:$PATH" BENCH_FAKE_STREAM="$FAKE3" bash "$BENCH" --task T1 --arm raw --run 2 --outdir "$D10" \
  > "$WORK/d10.out" 2>&1
R10F="$D10/run_record.txt"
grep -qE '^tool_result_events: unavailable ' "$R10F" 2>/dev/null \
  && ok "a stream with no tool_result channel yields tool_result_events: unavailable — NEVER zero" \
  || { no "an unestablishable field was not reported unavailable"; grep '^tool_result_events' "$R10F" 2>/dev/null | sed 's/^/      | /'; }
grep -qE '^tool_failures: unavailable ' "$R10F" 2>/dev/null \
  && ok "tool_failures is likewise unavailable when the provider output cannot establish it" \
  || no "tool_failures printed a number the stream cannot support"

echo "== 20. RULING 6 — the baseline row is preserved; the later record derives, never edits =="
NORIG="$(datarows "$STORE" | awk -F'\t' '$1=="t1_run1_buildos_preintegration"' | wc -l | tr -d ' ')"
[ "$NORIG" = "1" ] \
  && ok "the original t1_run1_buildos_preintegration row exists exactly once — never replaced" \
  || no "the original baseline row is missing or duplicated ($NORIG occurrences)"
ORIG="$(datarows "$STORE" | awk -F'\t' '$1=="t1_run1_buildos_preintegration"')"
printf '%s' "$ORIG" | grep -qF 'PRE-INTEGRATION SNAPSHOT' \
  && ok "the original row still carries its own frozen wording (not rewritten)" \
  || no "the original row's wording changed — a landed row was edited"
printf '%s' "$ORIG" | grep -qF 'benchmark_mode' \
  && no "the original row was retrofitted with new-schema fields — that is an edit, not a later record" \
  || ok "the original row carries NO new-schema field — the schema verdict lives in the later record only"
LATER="$(datarows "$STORE" | awk -F'\t' '$1=="t1_run1_buildos_preintegration_later_record"')"
[ -n "$LATER" ] \
  && ok "a LATER RECORD row exists for the baseline (append, not edit)" \
  || no "no later record row found for the baseline"
for fld in 'status=historical_preintegration_capture' 'canonical_comparison_eligible=false' 'harness_version=945a140' 'known_limitations='; do
  printf '%s' "$LATER" | grep -qF "$fld" \
    && ok "the later record carries $fld" \
    || no "the later record lacks $fld"
done
printf '%s' "$LATER" | grep -qF 'absence is INVALID' \
  && ok "the eligibility verdict is DERIVED in the record's own words: the original carries no benchmark_mode, and absence is INVALID, not canonical" \
  || no "the later record asserts eligibility without deriving it"
OPOS="$(datarows "$STORE" | awk -F'\t' '$1=="t1_run1_buildos_preintegration"{print NR}')"
LPOS="$(datarows "$STORE" | awk -F'\t' '$1=="t1_run1_buildos_preintegration_later_record"{print NR}')"
{ [ -n "$OPOS" ] && [ -n "$LPOS" ] && [ "$LPOS" -gt "$OPOS" ]; } \
  && ok "the later record is appended AFTER the row it annotates (row $OPOS -> row $LPOS)" \
  || no "the later record does not follow the original row (orig=$OPOS later=$LPOS)"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
