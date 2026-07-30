#!/usr/bin/env bash
# Build OS — packet speed report generator.
#
# Renders the metrics store as the table a buyer would read, and nothing else.
# Every figure printed is copied or arithmetically derived from a row in the
# store. There is no model of how fast the system "should" be anywhere in this
# file, and no default that fills an unmeasured cell with a plausible number.
#
# THE FAILURE MODE THIS FILE IS DESIGNED AGAINST is a report that silently drops
# a row: totals that no longer equal the sum of the rows above them. That is how
# a flattering number gets published without anyone intending to lie. So the
# report prints "rows in store" and "rows rendered" side by side, refuses to
# finish if they differ, and its totals are pinned by tests/speed_benchmark_tests.sh
# against an independent sum of the store.
#
# THE SECOND FAILURE MODE is a vacuous green: a report generated from zero rows
# that prints an empty table and exits 0. An empty table looks like proof. This
# refuses, loudly, on stderr, with a non-zero exit.
#
# Local only. Reads one file. No network, no telemetry, nothing transmitted.
#
# Usage: report-speed.sh [--store PATH]
# Exit:  0 rendered, 2 refused (missing store, zero rows, or a render/count
#        disagreement).
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STORE="$SELF_DIR/packet_metrics.tsv"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --store) [ "$#" -ge 2 ] || { echo "report-speed: --store requires a value" >&2; exit 2; }
             STORE="$2"; shift 2 ;;
    -h|--help) sed -n '2,25p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "report-speed: unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [ ! -f "$STORE" ]; then
  printf 'report-speed: REFUSED — no metrics store at %s. There is nothing to report.\n' "$STORE" >&2
  exit 2
fi

ROWS="$(tail -n +2 "$STORE" 2>/dev/null | grep -v '^[[:space:]]*$' | grep -cv '^#')"
ROWS="${ROWS:-0}"
if [ "$ROWS" -eq 0 ]; then
  printf 'report-speed: REFUSED — %s has 0 rows.\n' "$STORE" >&2
  printf 'A report over an empty store is not a green report; it is an unmeasured system\nwearing a table. Record at least one packet before asking for a number.\n' >&2
  exit 2
fi

GEN_DATE="$(date +%Y-%m-%d 2>/dev/null)"; GEN_DATE="${GEN_DATE:--}"

OUT="$(awk -F'\t' -v store="$STORE" -v gen="$GEN_DATE" '
function isnum(x){ return (x != "-" && x != "" && x ~ /^[0-9]+(\.[0-9]+)?$/) }
function fmt(x){ if (x == int(x)) return sprintf("%d", x); return sprintf("%.1f", x) }
function cel(x){ return (isnum(x) ? x : "-") }

BEGIN { budget["read-only"]=1; budget["diagnosis"]=1; budget["tiny"]=2 }

NR==1 { next }
/^[[:space:]]*$/ { next }
/^#/ { next }
NF!=16 { skipped++; next }
{
  n++
  pid[n]=$1; dt[n]=$2; ln[n]=$3; rd[n]=$4; wm[n]=$5; sm[n]=$6; ag[n]=$7
  fl[n]=$8; ins[n]=$9; del[n]=$10; ta[n]=$11; dg[n]=$12; de[n]=$13
  cm[n]=$14; ev[n]=$15; nt[n]=$16
}

END {
  # ---- aggregate -----------------------------------------------------------
  # Column names, used only to report which cells were left empty and why.
  cname[4]="rounds"; cname[5]="wall_min"; cname[6]="serial_min"; cname[7]="agents"
  cname[8]="files"; cname[9]="insertions"; cname[10]="deletions"; cname[11]="tests_added"
  cname[12]="defects_gated"; cname[13]="defects_escaped"
  for (i=1; i<=n; i++) {
    v[4]=rd[i]; v[5]=wm[i]; v[6]=sm[i]; v[7]=ag[i]; v[8]=fl[i]
    v[9]=ins[i]; v[10]=del[i]; v[11]=ta[i]; v[12]=dg[i]; v[13]=de[i]
    for (c=4; c<=13; c++) { if (isnum(v[c])) tot[c]+=v[c]; else empty[c]++ }

    L=ln[i]
    if (!(L in lseen)) { lseen[L]=1; lorder[++nl]=L }
    lpk[L]++
    if (isnum(rd[i])) { lrd[L]+=rd[i]; lrdn[L]++ }
    if (L in budget && isnum(rd[i])) {
      bdenom++
      if (rd[i]+0 <= budget[L]) bwithin++; else { bover++; lover[L]++ }
    }
  }

  # ---- header --------------------------------------------------------------
  print "# Build OS — packet speed report"
  print ""
  printf "- **Store:** `%s` — append-only TSV, local, operator-owned, no telemetry.\n", store
  printf "- **Rows in store:** %d\n", n
  printf "- **Rows rendered:** %d\n", n
  printf "- **Generated:** %s by `build-os/metrics/report-speed.sh`\n", gen
  print ""
  print "Every number below is copied from a row in the store, or is arithmetic over"
  print "those rows. Nothing is modelled, extrapolated, or benchmarked against a system"
  print "that was not actually run. A cell that reads `-` was never measured; §6 lists"
  print "which ones and states why."
  print ""

  # ---- 1. per-packet -------------------------------------------------------
  print "## 1. Per-packet record"
  print ""
  print "<!-- REPORT:PACKETS:START -->"
  print "| packet | date | lane | rounds | wall min | agents | files | insertions | tests added | defects gated | defects escaped | evidence |"
  print "|---|---|---|---|---|---|---|---|---|---|---|---|"
  for (i=1; i<=n; i++) {
    printf "| %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |\n",
      pid[i], dt[i], ln[i], cel(rd[i]), cel(wm[i]), cel(ag[i]), cel(fl[i]),
      cel(ins[i]), cel(ta[i]), cel(dg[i]), cel(de[i]), ev[i]
    rendered++
  }
  printf "| **TOTAL (%d rows)** | - | - | %s | %s | %s | %s | %s | %s | %s | %s | - |\n",
    n, fmt(tot[4]+0), fmt(tot[5]+0), fmt(tot[7]+0), fmt(tot[8]+0),
    fmt(tot[9]+0), fmt(tot[11]+0), fmt(tot[12]+0), fmt(tot[13]+0)
  print "<!-- REPORT:PACKETS:END -->"
  print ""
  printf "Totals skip `-` cells; they are sums of what was recorded, not of what happened.\n"
  print ""

  # ---- 2. rounds per lane --------------------------------------------------
  print "## 2. Rounds per lane"
  print ""
  print "| lane | packets | rounds recorded | mean rounds/packet | round budget | over budget |"
  print "|---|---|---|---|---|---|"
  for (i=1; i<=nl; i++) {
    L=lorder[i]
    mean = (lrdn[L] > 0) ? sprintf("%.1f", lrd[L]/lrdn[L]) : "-"
    b = (L in budget) ? budget[L] : "as needed"
    ov = (L in budget) ? (lover[L]+0) : "n/a"
    printf "| `%s` | %d | %s | %s | %s | %s |\n", L, lpk[L],
      (lrdn[L] > 0 ? fmt(lrd[L]) : "-"), mean, b, ov
  }
  print ""
  print "`substantive`, `architecture` and `agent-swarm` carry no numeric round budget"
  print "in the router — the row reads \"as needed\" — so they cannot be over or under it."
  print ""

  # ---- 3. budget compliance ------------------------------------------------
  print "## 3. Round-budget compliance"
  print ""
  if (bdenom+0 == 0) {
    print "**Not computable.** No packet in the store sits in a budgeted lane"
    print "(`read-only`, `diagnosis`, `tiny`) *and* carries a recorded round count."
    print "The denominator is 0, so no compliance rate is printed. A rate over an empty"
    print "denominator is not 100%; it is nothing."
  } else {
    printf "- Denominator — packets in a budgeted lane with a recorded round count: **%d**\n", bdenom
    printf "- Within budget: **%d**\n", bwithin+0
    printf "- Over budget: **%d**\n", bover+0
    printf "- Compliance: **%.0f%%** over a denominator of %d.\n", (bwithin*100.0)/bdenom, bdenom
    print ""
    if (bdenom < 5) {
      printf "**Read that denominator before quoting the percentage.** It is %d. A rate over\n", bdenom
      print "a denominator this small is an anecdote with a percent sign attached, and it will"
      print "move by tens of points on the next packet recorded."
    }
  }
  print ""

  # ---- 4. throughput -------------------------------------------------------
  print "## 4. Throughput per wall-clock minute"
  print ""
  print "| packet | wall min | insertions/min | tests/min |"
  print "|---|---|---|---|"
  tn=0
  for (i=1; i<=n; i++) {
    if (!isnum(wm[i]) || wm[i]+0 <= 0) continue
    tn++
    ipm = isnum(ins[i]) ? sprintf("%.1f", ins[i]/wm[i]) : "-"
    tpm = isnum(ta[i])  ? sprintf("%.1f", ta[i]/wm[i])  : "-"
    printf "| %s | %s | %s | %s |\n", pid[i], wm[i], ipm, tpm
  }
  if (tn == 0) print "| _none_ | - | - | - |"
  print ""
  printf "%d of %d packets carry a wall-clock. Throughput cannot be computed for the rest,\n", tn, n
  print "and no substitute figure is invented for them."
  print ""

  # ---- 5. fan-out speedup --------------------------------------------------
  print "## 5. Fan-out speedup"
  print ""
  print "| packet | agents | parallel wall (min) | serial equivalent (min) | speedup |"
  print "|---|---|---|---|---|"
  fn=0
  for (i=1; i<=n; i++) {
    if (!isnum(sm[i]) || !isnum(wm[i]) || wm[i]+0 <= 0) continue
    fn++
    printf "| %s | %s | %s | %s | %.2fx |\n", pid[i], cel(ag[i]), wm[i], sm[i], sm[i]/wm[i]
  }
  if (fn == 0) print "| _none_ | - | - | - | - |"
  print ""
  print "Speedup is `serial equivalent / parallel wall`, computed from the row — it is"
  print "never a figure typed into the store. The serial equivalent is only as good as"
  print "its own attribution in §7: where it came from a transcript rather than a"
  print "re-run, the speedup inherits that weakness exactly."
  print ""

  # ---- 6. what this cannot fill -------------------------------------------
  print "## 6. Cells this instrument cannot fill here"
  print ""
  print "Empty cells, counted rather than described:"
  print ""
  print "| column | empty cells | of rows |"
  print "|---|---|---|"
  for (c=4; c<=13; c++) if (empty[c]+0 > 0) printf "| `%s` | %d | %d |\n", cname[c], empty[c], n
  print ""
  print "The standing reasons, so an empty cell is never mistaken for a zero:"
  print ""
  print "- **A raw-Claude-Code baseline column does not exist, and cannot.** A real"
  print "  A/B needs a Claude Code session driven with Build OS off, and a session"
  print "  cannot be launched from this bash harness — there is no scriptable"
  print "  invocation and no API access here. The 20x-100x claim this project has"
  print "  argued is therefore **unmeasured** by this instrument. The empty column is the"
  print "  honest answer; `COMPARISON_PROTOCOL.md` specifies how to fill it later."
  print "- **`wall_min` is missing wherever nobody was holding a clock.** It was never"
  print "  recorded for packets that closed before this instrument existed, and it is"
  print "  not reconstructible from commit timestamps: the gap between two commits"
  print "  contains review, merge, and idle time as well as work."
  print "- **`defects_escaped` is near-universally empty because no post-close defect"
  print "  audit has ever been run.** Empty means unaudited. It does **not** mean zero"
  print "  escaped, and it must never be reported as a zero-defect record."
  print "- **Rows whose evidence class is `transcript` or `estimate` are not"
  print "  reproducible from this repository.** They are real observations from the"
  print "  session record, but a reader with only the repo cannot re-derive them, and"
  print "  `--verify-git` deliberately leaves them alone rather than pretending to."
  print ""

  # ---- 7. attribution ------------------------------------------------------
  print "## 7. Attribution — where each row came from"
  print ""
  print "| packet | evidence | commits | attribution |"
  print "|---|---|---|---|"
  for (i=1; i<=n; i++) printf "| %s | `%s` | `%s` | %s |\n", pid[i], ev[i], cm[i], nt[i]
  print ""
  printf "RENDERCHECK %d %d %d\n", n, rendered, skipped+0
}
' "$STORE")"

# The self-check: rows read must equal rows rendered, and no row may have been
# skipped for being ragged. A report that quietly rendered fewer rows than it
# read is the exact defect this file is built against, so it is a refusal, not a
# footnote.
CHECK="$(printf '%s\n' "$OUT" | grep '^RENDERCHECK ')"
READ_N="$(printf '%s' "$CHECK" | awk '{print $2}')"
RENDER_N="$(printf '%s' "$CHECK" | awk '{print $3}')"
SKIP_N="$(printf '%s' "$CHECK" | awk '{print $4}')"

if [ -z "$CHECK" ] || [ "$READ_N" != "$RENDER_N" ] || [ "${SKIP_N:-0}" != "0" ]; then
  printf 'report-speed: REFUSED — render self-check failed (read=%s rendered=%s skipped=%s).\n' \
    "${READ_N:-?}" "${RENDER_N:-?}" "${SKIP_N:-?}" >&2
  printf 'A report that drops rows is worse than no report, because its totals still look right.\n' >&2
  exit 2
fi
if [ "$READ_N" != "$ROWS" ]; then
  printf 'report-speed: REFUSED — the store has %s rows but the renderer read %s.\n' "$ROWS" "$READ_N" >&2
  exit 2
fi

printf '%s\n' "$OUT" | grep -v '^RENDERCHECK '
