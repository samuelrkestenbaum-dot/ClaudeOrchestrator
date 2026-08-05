#!/usr/bin/env bash
# Build OS — control registry tests.
#
# WHAT THIS PINS. build-os/registry/control_registry.txt declares, for every
# consequential control that already runs in this repository, its evidentiary
# CLASS, its IMPLEMENTATION STATUS, its EMPIRICAL STATUS, the RUNTIME AUTHORITY
# it actually exercises, and its role in the system. The three claims the
# registry exists to make checkable are:
#
#   1. A METRIC IS NOT LOAD-BEARING MERELY BECAUSE IT IS IMPLEMENTED. An entry
#      claiming `load_bearing` must name the live policy that consumes it.
#   2. A RESEARCH FUNCTIONAL OR A LEARNED MODEL MAY NOT OUTRANK AN INVARIANT.
#      Class R and Class D may not sit above `observe`.
#   3. A CONTROL EXERCISING MORE AUTHORITY THAN ITS CLASS LICENSES MUST SAY SO.
#      The licence table is fixed (A->gate, B->rank, C->advise, D->observe,
#      R->observe). Exceeding it is not forbidden here — several controls in this
#      repository do exceed it, and re-authorising them is an operator decision,
#      not a builder's — but it must be DECLARED on the entry and listed in
#      build-os/registry/MISMATCHES.md. The one thing that cannot happen quietly
#      is a heuristic being relabelled an invariant so the registry looks clean.
#
# AND THE ANTI-SHELFWARE GUARD, which is the lesson the metrics adoption guard
# paid for: a registry nobody updates is a registry that describes a system that
# no longer exists. So the entry set is reconciled against an INDEPENDENT SCAN of
# the tree — every file that can terminate a run non-zero must be owned by at
# least one `gate` entry, and every `gate` entry must own a file the scan found.
# A gating control added in a new file, with no registration, FAILS here.
#
# No network. Deterministic. Every fixture lives in its own mktemp dir; nothing
# outside $WORK is written. Exits non-zero if any assertion fails.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REG="$SRC/build-os/registry/control_registry.txt"
SCAN="$SRC/build-os/registry/scan-controls.sh"
MISM="$SRC/build-os/registry/MISMATCHES.md"
RREADME="$SRC/build-os/registry/README.md"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# The declared enums. Duplicated here ON PURPOSE: a test that reads its expected
# values out of the artefact it is checking cannot detect the artefact widening
# its own enum. These are pinned against the README's table in section 2.
CLASSES="R A B C D"
IMPL_STATUSES="specified implemented runtime_observed decision_contributing load_bearing"
EMP_STATUSES="untested unvalidated red_driven field_observed calibrated refuted"
AUTHORITIES="none observe advise rank gate execute"
ROLES="sensor reflex immune memory conscience motor"
MISMATCH_VALUES="none declared"
FIELDS="control class implementation_status empirical_status runtime_authority nervous_system_role inputs output owning_module consuming_policies evidence_refs failure_behavior rollback_behavior promotion_requirement demotion_requirement authority_mismatch notes"
# The licence table, as authority ranks
# (none=0 observe=1 advise=2 rank=3 gate=4 execute=5). No class licenses
# `execute`, so lic_of() tops out at 4 while rank_of() below runs to 5.
lic_of(){ case "$1" in A) echo 4 ;; B) echo 3 ;; C) echo 2 ;; D) echo 1 ;; R) echo 1 ;; *) echo -1 ;; esac; }
rank_of(){ case "$1" in none) echo 0 ;; observe) echo 1 ;; advise) echo 2 ;; rank) echo 3 ;; gate) echo 4 ;; execute) echo 5 ;; *) echo -1 ;; esac; }
in_list(){ local v="$1" l; for l in $2; do [ "$v" = "$l" ] && return 0; done; return 1; }

# Field value for a control id, or empty.
fval(){ # <registry> <control-id> <field>
  awk -v id="$2" -v f="$3" '
    $0 ~ "^control: " { cur = substr($0, 10) }
    cur == id && index($0, f ": ") == 1 { print substr($0, length(f) + 3); exit }
  ' "$1"
}
ids_of(){ sed -n 's/^control: //p' "$1"; }
dump(){ sed 's/^/      | /' "$WORK/out.txt" | head -25; }

echo "== 1. The registry, the scanner and the mismatch report exist =="
for pair in "control_registry.txt:$REG" "scan-controls.sh:$SCAN" "MISMATCHES.md:$MISM" "README.md:$RREADME"; do
  n="${pair%%:*}"; p="${pair#*:}"
  [ -s "$p" ] && ok "build-os/registry/$n exists and is non-empty" || no "build-os/registry/$n is missing or empty"
done

echo "== 2. VACUITY, HALF ONE — the registry declares controls at all =="
NENT="$(ids_of "$REG" 2>/dev/null | grep -c . || true)"; NENT="${NENT:-0}"
[ "$NENT" -ge 20 ] \
  && ok "the registry declares $NENT controls (>= 20, not a stub)" \
  || no "the registry declares only $NENT control(s) — a registry this small is not a census of this repository"
NDUP="$(ids_of "$REG" 2>/dev/null | sort | uniq -d | wc -l | tr -d ' ')"
[ "${NDUP:-0}" -eq 0 ] && ok "every control id is unique" || no "$NDUP control id(s) are declared twice"

echo "== 3. Every entry carries every required field, with values from the declared enums =="
BADF=0; BADE=0; MISSINGF=""
while IFS= read -r id; do
  [ -n "$id" ] || continue
  for f in $FIELDS; do
    v="$(fval "$REG" "$id" "$f")"
    if [ -z "$v" ]; then BADF=$((BADF+1)); MISSINGF="$MISSINGF $id/$f"; fi
  done
  in_list "$(fval "$REG" "$id" class)" "$CLASSES" || { BADE=$((BADE+1)); echo "      | $id: class not in enum"; }
  in_list "$(fval "$REG" "$id" implementation_status)" "$IMPL_STATUSES" || { BADE=$((BADE+1)); echo "      | $id: implementation_status not in enum"; }
  in_list "$(fval "$REG" "$id" runtime_authority)" "$AUTHORITIES" || { BADE=$((BADE+1)); echo "      | $id: runtime_authority not in enum"; }
  in_list "$(fval "$REG" "$id" nervous_system_role)" "$ROLES" || { BADE=$((BADE+1)); echo "      | $id: nervous_system_role not in enum"; }
  in_list "$(fval "$REG" "$id" authority_mismatch)" "$MISMATCH_VALUES" || { BADE=$((BADE+1)); echo "      | $id: authority_mismatch not in enum"; }
  for tok in $(fval "$REG" "$id" empirical_status | tr ',' ' '); do
    in_list "$tok" "$EMP_STATUSES" || { BADE=$((BADE+1)); echo "      | $id: empirical_status token \"$tok\" not in enum"; }
  done
done < <(ids_of "$REG")
[ "$BADF" -eq 0 ] && ok "all $NENT entries carry all 17 required fields" \
                  || no "$BADF required field(s) missing or empty:${MISSINGF:0:300}"
[ "$BADE" -eq 0 ] && ok "every enumerated field holds a value from its declared enum" \
                  || no "$BADE enumerated field(s) hold a value outside the declared enum"

echo "== 4. Nothing claims load_bearing without naming a consuming policy =="
LB=0; LBBAD=0
while IFS= read -r id; do
  [ -n "$id" ] || continue
  [ "$(fval "$REG" "$id" implementation_status)" = "load_bearing" ] || continue
  LB=$((LB+1))
  cp="$(fval "$REG" "$id" consuming_policies)"
  if [ -z "$cp" ] || [ "$cp" = "NONE" ]; then
    LBBAD=$((LBBAD+1)); echo "      | $id claims load_bearing and names no consuming policy"
  fi
done < <(ids_of "$REG")
[ "$LB" -gt 0 ] && ok "$LB entries claim load_bearing (the check below is not vacuous)" \
                || no "no entry claims load_bearing — either the census is wrong or this check has nothing to bite on"
[ "$LBBAD" -eq 0 ] && ok "every load_bearing entry names a live consuming policy" \
                   || no "$LBBAD load_bearing entr(ies) name no consuming policy"

echo "== 5. No Class R and no Class D sits above observe =="
RDBAD=0; RD=0
while IFS= read -r id; do
  [ -n "$id" ] || continue
  c="$(fval "$REG" "$id" class)"
  case "$c" in R|D) RD=$((RD+1)) ;; *) continue ;; esac
  a="$(fval "$REG" "$id" runtime_authority)"
  [ "$(rank_of "$a")" -le 1 ] || { RDBAD=$((RDBAD+1)); echo "      | $id is class $c at authority $a"; }
done < <(ids_of "$REG")
[ "$RDBAD" -eq 0 ] && ok "no Class R or Class D control exercises more than observe ($RD such entries)" \
                   || no "$RDBAD research/learned control(s) exercise authority above observe"

echo "== 6. Authority beyond the class licence is DECLARED, never laundered =="
MM=0; MMBAD=0; MMUNLISTED=0
while IFS= read -r id; do
  [ -n "$id" ] || continue
  c="$(fval "$REG" "$id" class)"; a="$(fval "$REG" "$id" runtime_authority)"
  d="$(fval "$REG" "$id" authority_mismatch)"
  lic="$(lic_of "$c")"; act="$(rank_of "$a")"
  if [ "$act" -gt "$lic" ]; then
    MM=$((MM+1))
    [ "$d" = "declared" ] || { MMBAD=$((MMBAD+1)); echo "      | $id exercises $a on a class-$c licence but declares authority_mismatch: $d"; }
    grep -qF "$id" "$MISM" 2>/dev/null || { MMUNLISTED=$((MMUNLISTED+1)); echo "      | $id is over-authorised but is absent from MISMATCHES.md"; }
  else
    [ "$d" = "none" ] || { MMBAD=$((MMBAD+1)); echo "      | $id is within its licence but declares authority_mismatch: $d"; }
  fi
done < <(ids_of "$REG")
[ "$MM" -gt 0 ] && ok "$MM control(s) exercise authority beyond their class licence — declared, not hidden" \
               || no "the registry reports ZERO over-authorised controls; this repository gates on median-derived thresholds, so a clean sheet here means the classification was bent to produce it"
[ "$MMBAD" -eq 0 ] && ok "every entry's authority_mismatch flag agrees with the licence table" \
                   || no "$MMBAD entr(ies) carry an authority_mismatch flag that contradicts the licence table"
[ "$MMUNLISTED" -eq 0 ] && ok "every over-authorised control is named in MISMATCHES.md" \
                        || no "$MMUNLISTED over-authorised control(s) are missing from MISMATCHES.md"

echo "== 7. Every evidence reference resolves — and resolvability is NOT identity (section 28) =="
EVN=0; EVBAD=0
while IFS= read -r id; do
  [ -n "$id" ] || continue
  om="$(fval "$REG" "$id" owning_module)"
  [ -f "$SRC/$om" ] || { EVBAD=$((EVBAD+1)); echo "      | $id: owning_module $om does not exist"; }
  for ref in $(fval "$REG" "$id" evidence_refs | tr ';' ' '); do
    [ -n "$ref" ] || continue
    EVN=$((EVN+1))
    f="${ref%:*}"; l="${ref##*:}"
    if [ ! -f "$SRC/$f" ]; then EVBAD=$((EVBAD+1)); echo "      | $id: evidence file $f does not exist"; continue; fi
    tot="$(wc -l < "$SRC/$f" | tr -d ' ')"
    case "$l" in ''|*[!0-9]*) EVBAD=$((EVBAD+1)); echo "      | $id: evidence ref \"$ref\" has no line number"; continue ;; esac
    [ "$l" -ge 1 ] && [ "$l" -le "$tot" ] || { EVBAD=$((EVBAD+1)); echo "      | $id: evidence ref $ref points past the end of the file ($tot lines)"; }
  done
done < <(ids_of "$REG")
[ "$EVN" -ge "$NENT" ] && ok "$EVN evidence reference(s) checked across $NENT entries (at least one each)" \
                       || no "only $EVN evidence reference(s) for $NENT entries — some entry cites no line at all"
[ "$EVBAD" -eq 0 ] && ok "every evidence reference resolves to an existing line of an existing file" \
                   || no "$EVBAD evidence reference(s) do not resolve"

echo "== 8. The independent scan agrees with the registry (anti-shelfware) =="
bash "$SCAN" check --repo "$SRC" --registry "$REG" --mismatches "$MISM" > "$WORK/out.txt" 2>&1
LRC=$?
[ "$LRC" = "0" ] && ok "scan-controls.sh check is GREEN against the live tree (exit 0)" \
                 || { no "the registry does not reconcile with the live tree (exit $LRC) — a registry that is red on the day it ships gets deleted by the end of the week"; dump; }
NSURF="$(bash "$SCAN" surfaces --repo "$SRC" 2>/dev/null | grep -c . || true)"
[ "${NSURF:-0}" -ge 20 ] \
  && ok "the independent scan discovers $NSURF refusal-capable control surfaces (>= 20, not vacuous)" \
  || no "the independent scan discovered only ${NSURF:-0} control surface(s) — it has gone blind"
# Deliberately NOT a single awk pass: `runtime_authority` precedes
# `owning_module` inside a record, so a one-pass scan that prints `om` when it
# sees the authority prints the PREVIOUS record's module. That bug produced an
# off-by-one that looked exactly like a real reconciliation failure.
GATEMODS=""
while IFS= read -r id; do
  [ -n "$id" ] || continue
  [ "$(fval "$REG" "$id" runtime_authority)" = "gate" ] || continue
  GATEMODS="$GATEMODS$(fval "$REG" "$id" owning_module)"$'\n'
done < <(ids_of "$REG")
NGATE="$(printf '%s' "$GATEMODS" | grep -v '^$' | sort -u | grep -c . || true)"
[ "${NGATE:-0}" = "${NSURF:-0}" ] \
  && ok "every one of the $NSURF discovered surfaces is owned by a gate entry, and no gate entry owns a file the scan did not find" \
  || no "$NGATE gate-owned module(s) vs $NSURF discovered surface(s) — the registry and the tree disagree"

# ---------------------------------------------------------------------------
# The red drives. Every check above is a claim that something FAILS on a defect;
# a check nobody has watched fail is a check nobody has tested.
# ---------------------------------------------------------------------------
mkfix(){ # <dir> — a minimal repo the scanner can walk, with a matching registry
  local d="$1"
  rm -rf "$d"; mkdir -p "$d/build-os/metrics" "$d/tests"
  printf '#!/usr/bin/env bash\nrefuse(){ echo "$*" >&2; exit 2; }\n[ -f x ] || refuse "no x"\n' > "$d/build-os/metrics/guard.sh"
  printf '#!/usr/bin/env bash\nPASS=0; FAIL=0\necho "==== RESULT: $PASS passed, $FAIL failed ===="\n[ "$FAIL" -eq 0 ]\n' > "$d/tests/x_tests.sh"
  cat > "$d/registry.txt" <<'EOF'
control: fixture.guard
class: A
implementation_status: load_bearing
empirical_status: red_driven
runtime_authority: gate
nervous_system_role: reflex
inputs: the presence of x
output: a refusal message
owning_module: build-os/metrics/guard.sh
consuming_policies: the guard's own exit code
evidence_refs: build-os/metrics/guard.sh:3
failure_behavior: prints the reason on stderr and exits 2
rollback_behavior: writes nothing; nothing to roll back
promotion_requirement: n/a — already load_bearing
demotion_requirement: remove the caller that acts on its exit code
authority_mismatch: none
notes: fixture

control: fixture.suite
class: A
implementation_status: load_bearing
empirical_status: red_driven
runtime_authority: gate
nervous_system_role: reflex
inputs: the fixture tree
output: a RESULT line
owning_module: tests/x_tests.sh
consuming_policies: the suite's own exit status
evidence_refs: tests/x_tests.sh:4
failure_behavior: exits non-zero when FAIL is non-zero
rollback_behavior: read-only; nothing to roll back
promotion_requirement: n/a — already load_bearing
demotion_requirement: unwire it from the chain
authority_mismatch: none
notes: fixture
EOF
  mkmism "$d"
}
mkmism(){ # <dir> [id...] — a mismatch report with the anchored summary table
  local d="$1" id; shift
  {
    printf '# fixture mismatch report\n\n'
    printf '<!-- MISMATCH-TABLE:START -->\n\n'
    printf '| control | class | exercises | licensed | the line that gates |\n'
    printf '|---|---|---|---|---|\n'
    for id in "$@"; do
      printf '| `%s` | C | gate | advise | `build-os/metrics/guard.sh:3` |\n' "$id"
    done
    printf '\n<!-- MISMATCH-TABLE:END -->\n'
  } > "$d/MISM.md"
}
runfix(){ # <dir> -> exit code, output in $WORK/out.txt
  bash "$SCAN" check --repo "$1" --registry "$1/registry.txt" --mismatches "$1/MISM.md" > "$WORK/out.txt" 2>&1
}
saw(){ grep -qi -- "$1" "$WORK/out.txt"; }

echo "== 9. Control: the clean fixture passes =="
FIX="$WORK/fix"; mkfix "$FIX"
runfix "$FIX"; RC=$?
[ "$RC" = "0" ] && ok "the clean fixture reconciles (exit 0) — the red drives below fail for their own reason" \
                || { no "the clean fixture already fails (exit $RC); every red drive after this would pass for the wrong reason"; dump; }

echo "== 10. RED DRIVE — load_bearing with no consuming policy is REFUSED (a metric is not load-bearing because it is implemented) =="
mkfix "$FIX"; sed -i 's|^consuming_policies: the guard.s own exit code$|consuming_policies: NONE|' "$FIX/registry.txt"
runfix "$FIX"; RC=$?
{ [ "$RC" = "2" ] && saw "load_bearing"; } \
  && ok "an entry claiming load_bearing with no consuming policy is REFUSED (exit $RC)" \
  || { no "load_bearing with no consuming policy was accepted (exit $RC)"; dump; }

echo "== 11. RED DRIVE — a Class D control at gate is REFUSED (a learned model does not outrank an invariant) =="
mkfix "$FIX"; sed -i '0,/^class: A$/s//class: D/' "$FIX/registry.txt"
runfix "$FIX"; RC=$?
{ [ "$RC" = "2" ] && saw "observe"; } \
  && ok "a Class D control declared at gate is REFUSED (exit $RC)" \
  || { no "a learned model was allowed to gate (exit $RC)"; dump; }

echo "== 11b. RED DRIVE — a Class R control above observe is REFUSED =="
mkfix "$FIX"; sed -i '0,/^class: A$/s//class: R/' "$FIX/registry.txt"
runfix "$FIX"; RC=$?
[ "$RC" = "2" ] && ok "a Class R research functional declared at gate is REFUSED (exit $RC)" \
               || { no "a research functional was allowed to gate (exit $RC)"; dump; }

echo "== 12. RED DRIVE — an unregistered gating control added to the tree FAILS =="
mkfix "$FIX"
printf '#!/usr/bin/env bash\n[ -f y ] || { echo no y >&2; exit 2; }\n' > "$FIX/build-os/metrics/sneaky.sh"
runfix "$FIX"; RC=$?
{ [ "$RC" = "2" ] && saw "sneaky.sh"; } \
  && ok "a gating control added with no registry entry FAILS, by name (exit $RC)" \
  || { no "an unregistered gating control was accepted (exit $RC) — this is the shelfware state"; dump; }

echo "== 13. RED DRIVE — a registered gate whose module the scan cannot find FAILS =="
mkfix "$FIX"; rm -f "$FIX/build-os/metrics/guard.sh"
runfix "$FIX"; RC=$?
[ "$RC" = "2" ] && ok "a gate entry owning a module the scan does not find FAILS (exit $RC)" \
               || { no "a gate entry pointing at nothing was accepted (exit $RC)"; dump; }

echo "== 14. RED DRIVE — VACUITY: zero registry entries, and a blinded scan =="
mkfix "$FIX"; : > "$FIX/registry.txt"
runfix "$FIX"; RC=$?
{ [ "$RC" = "2" ] && saw "0 "; } \
  && ok "a registry with zero entries is REFUSED (exit $RC) — an empty census is not a clean one" \
  || { no "an empty registry passed (exit $RC)"; dump; }
mkfix "$FIX"; rm -rf "$FIX/build-os" "$FIX/tests"
runfix "$FIX"; RC=$?
[ "$RC" = "2" ] && ok "a scan that discovers ZERO control surfaces is REFUSED (exit $RC) — a blinded scanner must not report success" \
               || { no "a blinded scan reported success (exit $RC)"; dump; }

echo "== 15. RED DRIVE — laundering: over-authorised without declaring it, and declared but unlisted =="
mkfix "$FIX"; sed -i '0,/^class: A$/s//class: C/' "$FIX/registry.txt"
runfix "$FIX"; RC=$?
{ [ "$RC" = "2" ] && saw "licence"; } \
  && ok "a Class C heuristic exercising gate WITHOUT declaring the mismatch is REFUSED (exit $RC)" \
  || { no "a heuristic became a gate silently (exit $RC) — this is the failure the registry exists against"; dump; }
mkfix "$FIX"
sed -i '0,/^class: A$/s//class: C/' "$FIX/registry.txt"
sed -i '0,/^authority_mismatch: none$/s//authority_mismatch: declared/' "$FIX/registry.txt"
runfix "$FIX"; RC=$?
{ [ "$RC" = "2" ] && saw "UNREPORTED"; } \
  && ok "a declared mismatch that is absent from the mismatch report is REFUSED (exit $RC)" \
  || { no "a declared mismatch never reached the report (exit $RC)"; dump; }
mkfix "$FIX"
sed -i '0,/^class: A$/s//class: C/' "$FIX/registry.txt"
sed -i '0,/^authority_mismatch: none$/s//authority_mismatch: declared/' "$FIX/registry.txt"
mkmism "$FIX" fixture.guard
runfix "$FIX"; RC=$?
[ "$RC" = "0" ] && ok "a heuristic at gate that is BOTH declared and reported passes — the registry records the mismatch, it does not silence it" \
               || { no "a properly declared and reported mismatch was still refused (exit $RC)"; dump; }

# The forward check matches the id against the report. Control ids NEST —
# `metrics.record.verify_git` is a prefix of `metrics.record.verify_git_vacuity`,
# `suite.build_os` of `suite.build_os_maintenance` — so an unanchored substring
# match would let a shorter id certify itself reported off a longer id's row.
# Latent today (neither shorter id is declared) and cheap to close, which is the
# only combination in which a guard reliably never gets closed.
mkfix "$FIX"
sed -i '0,/^class: A$/s//class: C/' "$FIX/registry.txt"
sed -i '0,/^authority_mismatch: none$/s//authority_mismatch: declared/' "$FIX/registry.txt"
mkmism "$FIX" fixture.guard_extra
runfix "$FIX"; RC=$?
{ [ "$RC" = "2" ] && saw "UNREPORTED"; } \
  && ok "a declared id that appears in the report only as a PREFIX of a longer id is still UNREPORTED (exit $RC)" \
  || { no "fixture.guard rode on fixture.guard_extra's mention and certified itself reported (exit $RC)"; dump; }

echo "== 15b. RED DRIVE — the reverse reconciliation: a mismatch cleared by RELABELLING the class =="
# The licence test (scanner section 5) only has an opinion while the control is
# still CLASSIFIED as exceeding its licence. Relabel the heuristic `class: A`,
# set authority_mismatch back to none, and the forward direction goes quiet —
# while the report goes on naming the control. Measured before this check
# existed, against the real registry: `tools.supervise_timeout` relabelled C->A
# with authority_mismatch: none, `scan-controls.sh check` exited 0, silently.
# "Do not clear a mismatch by changing the class" was a sentence in a header.
mkfix "$FIX"
sed -i '0,/^class: A$/s//class: C/' "$FIX/registry.txt"
sed -i '0,/^authority_mismatch: none$/s//authority_mismatch: declared/' "$FIX/registry.txt"
mkmism "$FIX" fixture.guard
runfix "$FIX"; RC=$?
[ "$RC" = "0" ] || { no "the declared-and-reported control was not green before the relabel; the drive below would fail for the wrong reason (exit $RC)"; dump; }
sed -i '0,/^class: C$/s//class: A/' "$FIX/registry.txt"
sed -i '0,/^authority_mismatch: declared$/s//authority_mismatch: none/' "$FIX/registry.txt"
runfix "$FIX"; RC=$?
{ [ "$RC" = "2" ] && saw "RELABELLED"; } \
  && ok "a control still named in the report, relabelled class A with authority_mismatch: none, is REFUSED (exit $RC)" \
  || { no "a mismatch was cleared by relabelling the class (exit $RC) — the single failure this registry exists to prevent"; dump; }

echo "== 15c. RED DRIVE — the report accuses a control the census does not classify =="
mkfix "$FIX"; mkmism "$FIX" fixture.phantom_control
runfix "$FIX"; RC=$?
{ [ "$RC" = "2" ] && saw "GHOST-REPORT"; } \
  && ok "an id named in the report's summary table with no registry entry is REFUSED (exit $RC)" \
  || { no "the report accused a control the registry does not classify, and the scan agreed (exit $RC)"; dump; }

echo "== 15d. RED DRIVE — VACUITY: a summary table the reverse check cannot parse =="
# A reverse check that parses zero rows clears every relabelled mismatch at once,
# and does it silently. Same failure as a blinded surface scan, one layer along.
mkfix "$FIX"
sed -i '0,/^class: A$/s//class: C/' "$FIX/registry.txt"
sed -i '0,/^authority_mismatch: none$/s//authority_mismatch: declared/' "$FIX/registry.txt"
printf '# fixture mismatch report\n\n- `fixture.guard` gates at `build-os/metrics/guard.sh:3`.\n' > "$FIX/MISM.md"
runfix "$FIX"; RC=$?
{ [ "$RC" = "2" ] && saw "0 control ids"; } \
  && ok "a report that mentions the control only in prose, with no parseable table, is REFUSED (exit $RC)" \
  || { no "the reverse check went blind and reported success (exit $RC)"; dump; }

echo "== 16. RED DRIVE — an unresolvable evidence reference FAILS =="
mkfix "$FIX"; sed -i 's|^evidence_refs: build-os/metrics/guard.sh:3$|evidence_refs: build-os/metrics/guard.sh:9999|' "$FIX/registry.txt"
runfix "$FIX"; RC=$?
[ "$RC" = "2" ] && ok "an evidence reference pointing past the end of its file FAILS (exit $RC)" \
               || { no "an unresolvable evidence reference was accepted (exit $RC)"; dump; }
mkfix "$FIX"; sed -i 's|^class: A$|class: Q|' "$FIX/registry.txt"
runfix "$FIX"; RC=$?
[ "$RC" = "2" ] && ok "a class outside the five-class ontology FAILS (exit $RC)" \
               || { no "an undeclared class was accepted (exit $RC)"; dump; }
mkfix "$FIX"; sed -i '0,/^nervous_system_role: reflex$/s//nervous_system_role: /' "$FIX/registry.txt"
runfix "$FIX"; RC=$?
[ "$RC" = "2" ] && ok "a missing required field FAILS (exit $RC)" \
               || { no "an entry missing a required field was accepted (exit $RC)"; dump; }

echo "== 17. The registry classifies THIS repository, not a template =="
for m in build-os/metrics/check-adoption.sh build-os/metrics/record-packet.sh \
         build-os/metrics/report-speed.sh build-os/tools/swarm-merge.sh \
         build-os/maintenance/run-tests.sh build-os/maintenance/real-memory-tripwire.mjs \
         tests/build_os_tests.sh build-os/registry/scan-controls.sh \
         tests/control_registry_tests.sh; do
  grep -qF "owning_module: $m" "$REG" \
    && ok "the registry classifies at least one control in $m" \
    || no "$m owns no registry entry"
done
# The registry must classify its own guard, or it is exempting itself.
grep -qF "owning_module: build-os/registry/scan-controls.sh" "$REG" \
  && grep -qF "owning_module: tests/control_registry_tests.sh" "$REG" \
  && ok "the registry registers its OWN scanner and its OWN suite (no self-exemption)" \
  || no "the registry exempts its own machinery from the census"

echo "== 18. The README declares the ontology the entries are written against =="
for term in "ControlClass" "ImplementationStatus" "EmpiricalStatus" "RuntimeAuthority" \
            "nervous_system_role" "none < observe < advise < rank < gate < execute"; do
  grep -qF "$term" "$RREADME" && ok "README declares: $term" || no "README never declares: $term"
done
grep -qE 'not load-bearing merely because|not load.bearing merely because' "$RREADME" \
  && ok "README states that implementation alone does not make a control load-bearing" \
  || no "README omits the load-bearing rule"
grep -qiE 'does not become a gate by being useful|heuristic .* not .* gate' "$RREADME" \
  && ok "README states that a heuristic does not become a gate by being useful" \
  || no "README omits the heuristic-authority rule"

echo "== 19. The mismatch report names a file and a line for every mismatch it lists =="
MMIDS="$(awk -v FS='\n' '/^control: /{id=substr($0,10)} /^authority_mismatch: declared$/{print id}' "$REG")"
NMM="$(printf '%s\n' "$MMIDS" | grep -c . || true)"
[ "${NMM:-0}" -ge 5 ] \
  && ok "$NMM control(s) are declared over-authorised — the report below is not vacuous" \
  || no "only ${NMM:-0} declared mismatch(es); this repository derives gating thresholds from a 4-row sample, so a near-clean sheet is a classification failure"
MMNOLINE=0
while IFS= read -r id; do
  [ -n "$id" ] || continue
  # the report must quote a path:line for this control, not merely name it
  awk -v id="$id" 'index($0, id) { print }' "$MISM" | grep -qE '[A-Za-z0-9_./-]+\.(sh|mjs):[0-9]+' \
    || { MMNOLINE=$((MMNOLINE+1)); echo "      | $id is listed with no file:line"; }
done < <(printf '%s\n' "$MMIDS")
[ "$MMNOLINE" -eq 0 ] && ok "every listed mismatch quotes the specific line that gates" \
                      || no "$MMNOLINE listed mismatch(es) quote no gating line"

echo "== 21. The non-vacuity family is reconciled against the TREE, not against itself =="
# WHY THIS EXISTS. tests.nonvacuity_minimums is one registry entry standing for a
# family of identical judgements — "the scan found at least N things, so what
# follows is not vacuous" — spread across a dozen suites. Its first version cited
# five lines and its notes claimed six constants. The real membership was
# thirty-four, and the grep that shows it fits on one line. An entry that groups
# is only as good as the rule that decides membership, so the rule is executed
# here rather than trusted: the tree is scanned, three lines are excluded by an
# auditable list with stated reasons, and what remains must be EXACTLY the
# entry's evidence_refs. Adding a fitted floor to any suite without registering
# it turns this red; so does leaving a stale ref behind after one is deleted.
#
# THE RULE. A member is `-ge N` or `-gt N` in tests/*.sh with N > 1, flooring how
# much a scanner or driver COVERED. N <= 1 is excluded on purpose: "found at
# least one thing" IS the invariant and is Class A. Every constant above 1 is a
# snapshot of the tree on the day it was written.
FAM_EXCL="$WORK/fam_excluded.txt"
cat > "$FAM_EXCL" <<'EOF'
tests/build_os_maintenance_tests.sh:200
tests/pilot_kit_tests.sh:340
tests/speed_benchmark_tests.sh:429
EOF
( cd "$SRC" && grep -rnE -- '-ge[[:space:]]+[0-9]+|-gt[[:space:]]+[0-9]+' tests/*.sh 2>/dev/null ) \
  | grep -vE -- '-ge[[:space:]]+[01][^0-9]|-gt[[:space:]]+0[^0-9]' \
  | cut -d: -f1,2 | sort -u > "$WORK/fam_all.txt"
NFAM_ALL="$(grep -c . "$WORK/fam_all.txt" || true)"
grep -vxF -f "$FAM_EXCL" "$WORK/fam_all.txt" | sort -u > "$WORK/fam_scan.txt"
awk '/^control: /{c=$2} c=="tests.nonvacuity_minimums" && /^evidence_refs: /{sub(/^evidence_refs: /,""); print; exit}' "$REG" \
  | tr ';' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | grep -v '^$' | sort -u > "$WORK/fam_reg.txt"
NFAM_SCAN="$(grep -c . "$WORK/fam_scan.txt" || true)"
NFAM_REG="$(grep -c . "$WORK/fam_reg.txt" || true)"
# VACUITY GUARD on this very reconciliation: a scan that matched nothing would
# certify an empty registry entry. (Written with `-gt 0`, deliberately: a fitted
# floor here would make this check a member of the family it polices.)
[ "${NFAM_ALL:-0}" -gt 0 ] && ok "the family scan matched $NFAM_ALL floor(s) in tests/ (not vacuous)" \
                           || no "the family scan matched nothing — it has gone blind, so the comparison below is meaningless"
FAM_MISSING="$(comm -23 "$WORK/fam_scan.txt" "$WORK/fam_reg.txt")"
FAM_STALE="$(comm -13 "$WORK/fam_scan.txt" "$WORK/fam_reg.txt")"
[ -z "$FAM_MISSING" ] \
  && ok "every fitted non-vacuity floor in the tree ($NFAM_SCAN of $NFAM_ALL scanned, 3 excluded with reasons) is registered to tests.nonvacuity_minimums" \
  || { no "$(printf '%s\n' "$FAM_MISSING" | grep -c .) fitted floor(s) gate but are NOT registered — the census undercounts itself again"; printf '%s\n' "$FAM_MISSING" | sed 's/^/      | unregistered: /'; }
[ -z "$FAM_STALE" ] \
  && ok "tests.nonvacuity_minimums cites no floor that the scan cannot find ($NFAM_REG refs)" \
  || { no "$(printf '%s\n' "$FAM_STALE" | grep -c .) registered ref(s) match no floor in the tree"; printf '%s\n' "$FAM_STALE" | sed 's/^/      | stale: /'; }
# The exclusions are auditable or they are a hiding place.
EXBAD=0
while IFS= read -r ex; do
  [ -n "$ex" ] || continue
  grep -qxF "$ex" "$WORK/fam_all.txt" || { EXBAD=$((EXBAD+1)); echo "      | exclusion matches nothing: $ex"; }
  grep -qF "$ex" "$MISM" || { EXBAD=$((EXBAD+1)); echo "      | exclusion is not justified in MISMATCHES.md: $ex"; }
done < "$FAM_EXCL"
[ "$EXBAD" -eq 0 ] \
  && ok "every exclusion matches a real line AND is named with its reason in MISMATCHES.md" \
  || no "$EXBAD exclusion problem(s) — an exclusion list nobody can audit is how a census shrinks quietly"

echo "== 22. No path:line is classified twice =="
# One line, two entries, two contradictory classes is the defect this found:
# tests/pilot_kit_tests.sh:97 was cited by tests.nonvacuity_minimums (C,
# declared) AND by suite.pilot_kit (A, none) — in the artefact whose whole
# purpose is unambiguous classification. Two entries may share an owning FILE;
# they may not share the LINE that exercises them.
awk '/^control: /{c=$2}
     /^evidence_refs: /{sub(/^evidence_refs: /,""); n=split($0,a,";");
       for(i=1;i<=n;i++){gsub(/^[ \t]+|[ \t]+$/,"",a[i]); if(a[i]!="") print a[i] "\t" c}}' "$REG" \
  | sort > "$WORK/allrefs.txt"
NREFS="$(grep -c . "$WORK/allrefs.txt" || true)"
[ "${NREFS:-0}" -gt 0 ] && ok "$NREFS evidence reference(s) parsed across the registry (not vacuous)" \
                        || no "no evidence references parsed — the duplicate check below is meaningless"
DUPREF="$(cut -f1 "$WORK/allrefs.txt" | uniq -d)"
if [ -z "$DUPREF" ]; then
  ok "no path:line is claimed by two entries — every classified line has exactly one class"
else
  no "$(printf '%s\n' "$DUPREF" | grep -c .) path:line(s) are classified twice"
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    printf '      | %s claimed by: %s\n' "$r" "$(awk -F'\t' -v r="$r" '$1==r{printf "%s ", $2}' "$WORK/allrefs.txt")"
  done < <(printf '%s\n' "$DUPREF")
fi

echo "== 23. A cited line must DO something — the sweep, converted into a check =="
# WHY THIS EXISTS, AND WHAT IT COST TO NOT HAVE IT. Until now `evidence_refs`
# were checked only for pointing INSIDE the file. Nothing checked that the line
# they landed on exercised anything, so a citation could satisfy the guard
# VACUOUSLY: `tools.supervise_timeout` cited a header comment, an `echo` and a
# `fi` for a full packet; two entries cited `#!/usr/bin/env bash`, which is the
# `nref >= 1` guard passing on a line that is not even code. Each verification
# round found more of them by hand and cast a wider net than the last, which is
# what a hand sweep over 200-odd citations does. This is that sweep made
# mechanical, so the class of defect cannot be reintroduced silently.
#
# EXACTLY WHAT IT CATCHES: a ref resolving to a blank line, a comment-only line,
# a shebang, or a lone closer (`fi`, `done`, `esac`, `else`, `}`, `)`, `{`, `]`,
# `;;`). EXACTLY WHAT IT DOES NOT: anything that is a statement but not a
# decision. An `echo`, an assignment, a function call and a `return` all pass.
# Measured against the real defect: of the three bad `supervise_timeout` refs it
# would have caught two — the comment and the `fi` — and NOT the `echo`. The
# check "is this line a comparison or an exit" is the one worth having and it is
# genuinely hard; this is the cheap half, and the cheap half is stated as such
# rather than sold as the whole thing.
VACREFS="$(bash "$SCAN" check --repo "$SRC" --registry "$REG" --mismatches "$MISM" 2>&1 | grep -c 'VACUOUS-REF' || true)"
[ "${VACREFS:-0}" -eq 0 ] \
  && ok "no evidence_ref in the live registry resolves to a blank line, a comment, a shebang or a lone closer" \
  || no "${VACREFS} evidence_ref(s) resolve to a line that exercises nothing"
bash "$SCAN" patterns | grep -q '^vacuous-ref: ' \
  && ok "scan-controls.sh patterns prints the vacuity rule in full, so what it does NOT catch is readable" \
  || no "the vacuity rule is not printed by scan-controls.sh patterns"
bash "$SCAN" patterns | grep -q '^vacuity-allow-count: ' \
  && ok "the vacuity ALLOWANCE is printed too — an exemption list nobody can grep is a silent one" \
  || no "scan-controls.sh patterns does not print the vacuity allowance"

# A fixture whose guard.sh carries, in order: :4 a comment, :5 a declaration,
# :6 a lone closer, :7 a blank line.
mkvac(){ mkfix "$1"; printf '# a header comment, which decides nothing\nTHRESHOLD=900\n}\n\n' >> "$1/build-os/metrics/guard.sh"; }
setref(){ sed -i "s|^evidence_refs: build-os/metrics/guard.sh:3$|evidence_refs: build-os/metrics/guard.sh:$2|" "$1/registry.txt"; }

echo "== 23a. RED DRIVE — a ref repointed at a COMMENT is REFUSED =="
mkvac "$FIX"; setref "$FIX" 4
runfix "$FIX"; RC=$?
{ [ "$RC" = "2" ] && saw "VACUOUS-REF"; } \
  && ok "an evidence_ref resolving to a comment-only line is REFUSED (exit $RC)" \
  || { no "a ref citing a comment was accepted (exit $RC) — this is the sweep that kept having to be redone"; dump; }

echo "== 23b. RED DRIVE — a legitimate DECLARATION ref still PASSES (the check is not a blanket) =="
# The other direction, and it is the one that decides whether this check is
# usable at all. A control is often best cited at the line that DEFINES its
# chosen constant — `TIMEOUT="900"` is the whole subject of a threshold entry —
# and a filter that rejected declarations would push authors to cite a less
# honest line. Declarations pass by construction: they are not blank, not a
# comment, not a shebang and not a closer. `tools.supervise_timeout:21` is the
# live instance.
mkvac "$FIX"; setref "$FIX" 5
runfix "$FIX"; RC=$?
[ "$RC" = "0" ] \
  && ok "an evidence_ref resolving to a constant's DEFINITION passes (exit $RC) — the check rejects vacuity, not declarations" \
  || { no "a legitimate declaration ref was refused (exit $RC) — the check is too blunt to live with"; dump; }
grep -qE '^evidence_refs: .*build-os/tools/supervise\.sh:21' "$REG" \
  && ok "the live registry carries a real declaration ref (supervise.sh:21, the chosen TIMEOUT) — 23b is not a fixture-only claim" \
  || no "no live declaration ref remains, so 23b proves nothing about this registry"

echo "== 23c. RED DRIVE — a shebang, a lone closer and a blank line are each REFUSED =="
VACOK=0
for pair in "1:shebang" "6:closer" "7:blank"; do
  ln="${pair%%:*}"; what="${pair#*:}"
  mkvac "$FIX"; setref "$FIX" "$ln"
  runfix "$FIX"; RC=$?
  { [ "$RC" = "2" ] && saw "VACUOUS-REF"; } || { echo "      | a $what ref was accepted (exit $RC)"; VACOK=$((VACOK+1)); }
done
[ "$VACOK" -eq 0 ] \
  && ok "a shebang, a lone closer and a blank line are each REFUSED as evidence — \`nref >= 1\` satisfied by a shebang is the guard failing, not passing" \
  || no "$VACOK of 3 vacuous line shapes were accepted as evidence"

echo "== 24. RED DRIVE — a DUPLICATED anchor row cannot inflate the reconciled count =="
# The anchor counted ROWS, not distinct ids, so pasting a control's row twice
# passed at exit 0 and reported one more reconciled row than there were
# controls. A count that can be raised by copy-paste is not a reconciliation.
mkfix "$FIX"
sed -i '0,/^class: A$/s//class: C/' "$FIX/registry.txt"
sed -i '0,/^authority_mismatch: none$/s//authority_mismatch: declared/' "$FIX/registry.txt"
mkmism "$FIX" fixture.guard fixture.guard
runfix "$FIX"; RC=$?
{ [ "$RC" = "2" ] && saw "DUPLICATE-ROW"; } \
  && ok "the same control listed in two rows of the summary table is REFUSED (exit $RC)" \
  || { no "a duplicated anchor row was accepted (exit $RC) and inflated the reconciled count"; dump; }
mkfix "$FIX"
sed -i '0,/^class: A$/s//class: C/' "$FIX/registry.txt"
sed -i '0,/^authority_mismatch: none$/s//authority_mismatch: declared/' "$FIX/registry.txt"
mkmism "$FIX" fixture.guard
runfix "$FIX"; RC=$?
{ [ "$RC" = "0" ] && grep -q '1 report row(s) reconciled' "$WORK/out.txt"; } \
  && ok "the reconciled count is a count of DISTINCT control ids (1 row for 1 control)" \
  || { no "the reconciled row count is not distinct-id based (exit $RC)"; dump; }

echo "== 25. Any stated ref TOTAL is derived from the live count, not remembered =="
# THE DEFECT THIS CLOSES. The same total was written down in three artefacts and
# all three were wrong, in three different ways — 218, 184 and 184, against a
# live 224 — because each was a hand count frozen at a different moment. A
# number that has to be remembered in three places is a number that will be
# wrong in at least two. MISMATCHES.md and control_registry.txt now state no
# total at all; the README states one, and it is checked here against the count
# the registry actually produces.
LIVEREFS="$(awk '/^evidence_refs: /{sub(/^evidence_refs: /,""); n=split($0,a,";"); for(i=1;i<=n;i++){gsub(/^[ \t]+|[ \t]+$/,"",a[i]); if(a[i]!="") c++}} END{print c+0}' "$REG")"
[ "${LIVEREFS:-0}" -gt 0 ] \
  && ok "the live registry carries $LIVEREFS evidence_refs (the comparison below is not vacuous)" \
  || no "no evidence_refs parsed from the registry"
# A TOTAL, and only a total. The extractor is anchored on the words that make a
# number a total — `all N refs`, `carries N evidence_refs`, `a total of N refs` —
# so a legitimate LOCAL count ("corrected from 5 refs", which is a claim about
# one entry) is not swept up and does not have to be rewritten to appease a
# regex. All three of the wrong totals were written in exactly this shape.
statedrefs(){ grep -ohE '(all|carries|a total of)[[:space:]]+\**[0-9]+\**[[:space:]]+(`?evidence_refs`?|evidence references|refs)\b' "$@" 2>/dev/null \
                | grep -oE '[0-9]+' ; }
STATEDBAD=0; NSTATED=0
while IFS= read -r n; do
  [ -n "$n" ] || continue
  NSTATED=$((NSTATED+1))
  [ "$n" = "$LIVEREFS" ] || { STATEDBAD=$((STATEDBAD+1)); echo "      | an artefact states $n evidence_refs; the registry carries $LIVEREFS"; }
done < <(statedrefs "$RREADME" "$MISM" "$REG")
[ "$NSTATED" -ge 1 ] \
  && ok "$NSTATED stated ref total(s) found to check (this check has something to bite on)" \
  || no "no artefact states a ref total, so this check is vacuous — state it in the README where it is checked"
[ "$STATEDBAD" -eq 0 ] \
  && ok "every stated evidence_ref total equals the live count ($LIVEREFS)" \
  || no "$STATEDBAD stated ref total(s) disagree with the live count of $LIVEREFS"
# RED DRIVE on this check itself, since the live artefacts are (now) correct and
# a check that has only ever been observed passing is a check nobody has tested.
printf 'the registry carries **99999** `evidence_refs` today.\n' > "$WORK/stale_claim.md"
SD="$(statedrefs "$WORK/stale_claim.md")"
{ [ -n "$SD" ] && [ "$SD" != "$LIVEREFS" ]; } \
  && ok "a stale hand-written total (99999) is detected by the same extractor — the check fails on drift rather than sleeping through it" \
  || no "the stated-total extractor does not detect a stale total, so section 25 would pass whatever the artefacts claim"

echo "== 26. The egress scan is a control in its own right, cited INSIDE its own block =="
# WHAT THIS CLOSES. README section 4's known hole number one is "a new control
# added inside an already-registered file". The egress scan was the live
# instance: a real security invariant with a planted-defect fixture and a
# negative control, living inside tests/entitlement_tests.sh, visible to the
# census only through that suite's RESULT line and through its own vacuity floor
# (registered to tests.nonvacuity_minimums). So the registry could see "this
# scanner is not blind" and could never see "nothing performs egress".
#
# WHAT IS PINNED HERE, AND WHY EACH PART. Registration alone is cheap; an entry
# whose citations wander outside the block it claims to classify would put the
# census back where it started. So the block is located by its own markers and
# every citation must land inside it — and at least one must land inside the
# CONTROL-FIXTURE block, because a planted-defect fixture is what `red_driven`
# MEANS and an entry claiming it without citing one is claiming a fixture nobody
# has to have written.
ENT="$SRC/tests/entitlement_tests.sh"
EG_START="$(grep -n '7. no network egress' "$ENT" | head -1 | cut -d: -f1)"
EG_END="$(grep -n '^# CONTROL-FIXTURE:END' "$ENT" | head -1 | cut -d: -f1)"
FIX_START="$(grep -n '^# CONTROL-FIXTURE:START' "$ENT" | head -1 | cut -d: -f1)"
{ [ -n "$EG_START" ] && [ -n "$EG_END" ] && [ "$EG_END" -gt "$EG_START" ]; } \
  && ok "the egress block is locatable by its own markers (lines $EG_START-$EG_END) — this section is not vacuous" \
  || no "the egress block could not be located in tests/entitlement_tests.sh, so everything below is meaningless"
grep -qxF 'control: entitlement.egress_scan' "$REG" \
  && ok "the egress scan owns a registry entry of its own (entitlement.egress_scan)" \
  || no "the egress scan is still invisible to the census as a control"
[ "$(fval "$REG" entitlement.egress_scan owning_module)" = "tests/entitlement_tests.sh" ] \
  && ok "it is owned by the file it actually lives in" \
  || no "entitlement.egress_scan names the wrong owning_module"
EG_OUT=0; EG_IN_FIX=0; EG_N=0
for ref in $(fval "$REG" entitlement.egress_scan evidence_refs | tr ';' ' '); do
  [ -n "$ref" ] || continue
  EG_N=$((EG_N+1))
  rl="${ref##*:}"
  case "$ref" in tests/entitlement_tests.sh:*) ;; *) EG_OUT=$((EG_OUT+1)); echo "      | cites another file: $ref"; continue ;; esac
  { [ "$rl" -ge "$EG_START" ] && [ "$rl" -le "$EG_END" ]; } \
    || { EG_OUT=$((EG_OUT+1)); echo "      | cites a line outside the egress block: $ref"; }
  { [ "$rl" -ge "$FIX_START" ] && [ "$rl" -le "$EG_END" ]; } && EG_IN_FIX=$((EG_IN_FIX+1))
done
[ "$EG_N" -gt 0 ] && ok "$EG_N citation(s) parsed from the entry (not vacuous)" \
                  || no "the entry cites nothing, so the containment check below is meaningless"
[ "$EG_OUT" -eq 0 ] \
  && ok "every citation lands inside the egress block — the entry classifies the control it claims to" \
  || no "$EG_OUT citation(s) fall outside the block this entry classifies"
if [ "$(fval "$REG" entitlement.egress_scan empirical_status)" = "red_driven" ]; then
  [ "$EG_IN_FIX" -gt 0 ] \
    && ok "it claims red_driven AND cites the planted-defect fixture that earns the claim" \
    || no "it claims red_driven but cites no line of the control-fixture block"
else
  no "entitlement.egress_scan does not claim red_driven, though the block carries both a positive and a negative control"
fi
# The scan's non-vacuity floor stays with the FAMILY, not with this entry. One
# path:line, one class — section 22 already enforces it; this states the intent
# where a reader meets it, because the floor is Class C and the scan is Class A.
printf '%s\n' "$(fval "$REG" entitlement.egress_scan evidence_refs)" | grep -qF ":$(grep -n 'SCANNED" -ge' "$ENT" | head -1 | cut -d: -f1)" \
  && no "the egress entry has absorbed its own fitted vacuity floor, which belongs to tests.nonvacuity_minimums (Class C, declared)" \
  || ok "the entry does NOT cite its own fitted vacuity floor — that line stays with the Class C family that owns it"

echo "== 26a. THE RULING: this control does NOT enforce the external boundary =="
# The rule "never push, merge, deploy, publish or touch secrets" is enforced by
# the operator's permission system — a process boundary outside this repository.
# Anything that could bypass that permission system bypasses a repo-side check
# trivially, so a repo-side gate would convert a real external boundary into a
# checkbox that looks enforced and is not. The census is allowed to record a
# scanner over a fileset. It is not allowed to let that scanner be read as the
# boundary, so the disclaimer is asserted rather than trusted to good intentions.
EG_STANZA="$WORK/eg_stanza.txt"
awk '/^control: entitlement.egress_scan$/{f=1} f{print} f&&/^notes: /{exit}' "$REG" > "$EG_STANZA"
[ -s "$EG_STANZA" ] && ok "the entitlement.egress_scan stanza is readable (not vacuous)" \
                    || no "the stanza could not be extracted, so the assertions below are meaningless"
grep -qi 'permission system' "$EG_STANZA" \
  && ok "the entry names the operator's permission system as where the real boundary lives" \
  || no "the entry never names the external permission system"
grep -qiE 'does not enforce the external boundary|IT DOES NOT ENFORCE THE EXTERNAL BOUNDARY' "$EG_STANZA" \
  && ok "the entry states outright that it does NOT enforce the external boundary" \
  || no "the entry does not disclaim enforcement of the external boundary — the one claim this control may not make"
grep -qiE 'outside this repository|outside the census' "$EG_STANZA" \
  && ok "the entry places that boundary OUTSIDE this repository, where it actually is" \
  || no "the entry does not locate the external boundary outside this repository"
grep -qiE 'checkbox that looks enforced' "$EG_STANZA" \
  && ok "the entry records WHY a repo-side gate would be worse than none: a checkbox that looks enforced and is not" \
  || no "the entry omits the reason a repo-side gate is refused"
# ...and the crosswalk must not undo it from the other side.
XWF="$SRC/build-os/registry/neurocosmology_crosswalk.txt"
awk '/^primitive: ethical_admissibility$/{f=1} f{print} f&&/^known_limitations: /{exit}' "$XWF" \
  | grep -qiE 'permission system' \
  && ok "the crosswalk's ethical_admissibility record still states that its strongest enforcement is the external permission system" \
  || no "the crosswalk no longer records that this primitive's strongest enforcement lives outside the census"

echo "== 26b. RED DRIVE — a citation dragged OUTSIDE the egress block is caught =="
# The check above is only worth having if it fails on the edit it exists to
# catch: an entry that keeps its id and quietly widens its scope. The fixture is
# the live entry with one ref repointed at line 1 of the same file.
FAKE_REFS="tests/entitlement_tests.sh:1; tests/entitlement_tests.sh:350"
RD_OUT=0
for ref in $(printf '%s' "$FAKE_REFS" | tr ';' ' '); do
  [ -n "$ref" ] || continue
  rl="${ref##*:}"
  { [ "$rl" -ge "$EG_START" ] && [ "$rl" -le "$EG_END" ]; } || RD_OUT=$((RD_OUT+1))
done
[ "$RD_OUT" -gt 0 ] \
  && ok "RED: a ref repointed outside the egress block is reported ($RD_OUT of 2) by the same containment test" \
  || no "RED FAILED: a citation outside the block passed the containment test, so the entry's scope is unpoliced"

echo "== 27. A CITATION CARRYING TWO NUMBERS CARRIES TWO POSITIONS =="
# WHY THIS EXISTS, AND WHAT IT COST TO NOT HAVE IT. §23 and the resolvability
# guard in scan-controls.sh both read a citation as ONE position: a `path:line`
# with a single number. Two notations in this tree carry TWO numbers, and the
# repoint sweeps moved only the FIRST of them. Four citations were corrupted that
# way in one packet, and the corruption is invisible to every check that existed:
# each half still resolved, each landed on real code, and nothing compared them.
#
# THE TWO NOTATIONS ARE NOT THE SAME KIND OF THING, and the rule differs because
# of it. This is the distinction the sweep did not draw:
#
#   RANGE       `path:N-M`  — N and M are two positions in the CURRENT tree,
#                             bounding one span of one file. It is a LIVE
#                             pointer. When the file moves it must be repointed
#                             AT BOTH ENDS, together, or it silently renames the
#                             span it cites. `tests/mutator_registry_tests.sh`
#                             gained a line and the sweep produced `:573-574`
#                             from `:572-574` — a three-line guard cited as two.
#
#   ARROW-PAIR  `path:N -> :M` — N and M are the SAME content at TWO DIFFERENT
#                             COMMITS. It is not a pointer at all; it is a
#                             HISTORICAL RECORD that a reference moved from N to
#                             M. Repointing either number rewrites the record of
#                             a past event. The sweep shifted the first number of
#                             `:642 -> :643` and produced `:643 -> :643` — a
#                             repoint asserted to have moved nothing, which
#                             destroys the evidence that the defect ever existed.
#
# THE RULING THIS PACKET TAKES: ranges are repointed at both ends; arrow-pairs
# are EXCLUDED from mechanical repointing entirely, because both of their numbers
# are statements about commits that are not this one. The three checks below are
# that ruling made mechanical.
# TREE-WIDE, and deliberately so. qa's "0 stale refs" and the reviewer's four
# corrupted citations were BOTH true because they measured different things over
# different surfaces: resolvability over build-os/registry/, identity over
# build-os/memory/ and the receipts. This sweep reads both properties over BOTH,
# so neither result can be quoted about a surface it never visited.
CIT_ALL="$SRC/build-os $SRC/tests"
RANGE_RE='[A-Za-z0-9_./-]+\.(sh|md|txt|mjs|json|js):[0-9]+-[0-9]+'
# Resolve a cited path — several artefacts cite by basename — to a real file.
citfile(){
  local p="$1"
  [ -f "$SRC/$p" ] && { printf '%s\n' "$SRC/$p"; return 0; }
  find "$SRC/build-os" "$SRC/tests" -name "$(basename "$p")" -type f 2>/dev/null | head -1
}

echo "== 27a. Both ends of a RANGE resolve, and they are the right way round =="
CR_BAD=0; CR_SEEN=0
while IFS= read -r cit; do
  [ -n "$cit" ] || continue
  CR_SEEN=$((CR_SEEN+1))
  cp="${cit%:*}"; span="${cit##*:}"; cn="${span%%-*}"; cm="${span##*-}"
  cf="$(citfile "$cp")"
  if [ -z "$cf" ]; then CR_BAD=$((CR_BAD+1)); echo "      | $cit names no file in the tree"; continue; fi
  ctot="$(grep -c '' "$cf")"
  if [ "$cn" -ge "$cm" ]; then CR_BAD=$((CR_BAD+1)); echo "      | $cit ends at or before it starts"; continue; fi
  if [ "$cm" -gt "$ctot" ]; then CR_BAD=$((CR_BAD+1)); echo "      | $cit ends past the end of a $ctot-line file"; fi
done < <(grep -rhoE "$RANGE_RE" $CIT_ALL 2>/dev/null | sort -u)
[ "$CR_SEEN" -ge 10 ] \
  && ok "$CR_SEEN distinct range citation(s) found to check — this sweep has something to bite on" \
  || no "only $CR_SEEN range citation(s) found; the sweep is vacuous"
[ "$CR_BAD" -eq 0 ] \
  && ok "every range citation resolves at BOTH ends: the file exists, N < M, and M is inside it" \
  || no "$CR_BAD range citation(s) do not resolve at both ends"

echo "== 27b. RED DRIVE — a range whose SECOND end was left behind is caught =="
# The exact corruption, driven against the same predicate. `:573-574` is what the
# sweep produced; `:573-575` is the guard. Both resolve, both land on code, and
# only a check that reads the second number can tell them apart.
# THE PROBES ARE BUILT AT RUN TIME AND NEVER WRITTEN AS LITERALS. This file
# lives under the corpus 27a sweeps, so a literal malformed range here would be
# swept as a real citation and 27a would fail on its own fixture — the same trap
# the GHOST_MEAS token in tests/mismatch_disposition_tests.sh avoids.
CR_F="tests/mutator_registry_tests.sh"
CR_RED=0
for probe in "$CR_F:$((9990))-$((9999))" "$CR_F:$((575))-$((573))"; do
  pp="${probe%:*}"; ps="${probe##*:}"; pn="${ps%%-*}"; pm="${ps##*-}"
  pf="$(citfile "$pp")"; ptot="$(grep -c '' "$pf")"
  { [ "$pn" -ge "$pm" ] || [ "$pm" -gt "$ptot" ]; } && CR_RED=$((CR_RED+1))
done
[ "$CR_RED" -eq 2 ] \
  && ok "RED: a range past the end of the file and a range that runs backwards are BOTH caught by 27a's predicate" \
  || no "RED FAILED: 27a's predicate accepted $((2-CR_RED)) of 2 malformed ranges, so it does not read the second number"

echo "== 27c. An ARROW-PAIR records a MOVE — its two numbers must DIFFER =="
# `:N -> :N` is a repoint that moved nothing. Nobody writes that down. It is what
# a first-number-only sweep produces from a real repoint record, and it is the
# signature of the record having been corrupted rather than of a repoint having
# been redundant. Newlines are folded first: these citations wrap in prose, and
# the p2 receipt's pair was split across two lines.
AP_BAD=0; AP_SEEN=0
while IFS= read -r ap; do
  [ -n "$ap" ] || continue
  AP_SEEN=$((AP_SEEN+1))
  an="$(printf '%s' "$ap" | sed -E 's/^.*:([0-9]+) *(->|→|to).*$/\1/')"
  am="$(printf '%s' "$ap" | sed -E 's/^.*(->|→|to) *:?([0-9]+).*$/\2/')"
  [ "$an" = "$am" ] && { AP_BAD=$((AP_BAD+1)); echo "      | $ap records a repoint that moved nothing"; }
done < <(for f in $(grep -rlE ':[0-9]+ *(->|→|to) *:?[0-9]+' $CIT_ALL 2>/dev/null); do
           tr '\n' ' ' < "$f" | grep -oE '[A-Za-z0-9_./-]+\.(sh|md|txt|mjs):[0-9]+ *(->|→|to) *:?[0-9]+'
         done | sort -u)
[ "$AP_SEEN" -ge 1 ] \
  && ok "$AP_SEEN arrow-pair repoint record(s) found tree-wide — memory, receipts and metrics included" \
  || no "no arrow-pair citation found, so this check is vacuous"
[ "$AP_BAD" -eq 0 ] \
  && ok "every arrow-pair names TWO DIFFERENT lines — no repoint record has been flattened into \`:N -> :N\`" \
  || no "$AP_BAD arrow-pair(s) assert a repoint that moved nothing, which is the record of a defect destroyed by a first-number-only sweep"
# RED DRIVE on the extractor itself, since the live records are (now) correct.
# Assembled at run time for the same reason 27b's probes are: a literal
# `:N -> :N` in this file would be swept by the loop above as a real record.
AP_PROBE="$CR_F:$((643)) -> :$((643))"
PN="$(printf '%s' "$AP_PROBE" | sed -E 's/^.*:([0-9]+) *(->|→|to).*$/\1/')"
PM="$(printf '%s' "$AP_PROBE" | sed -E 's/^.*(->|→|to) *:?([0-9]+).*$/\2/')"
[ "$PN" = "$PM" ] \
  && ok "RED: the extractor reads BOTH numbers out of \`$AP_PROBE\` and reports them equal — 27c fails on the corruption rather than sleeping through it" \
  || no "RED FAILED: the arrow-pair extractor does not parse both endpoints ($PN vs $PM)"

echo "== 27d. Two ranges over ONE file must not CONTRADICT each other =="
# DEFECT-0003-duplicate-semantic-truth, in the notation that invites it. When two
# artefacts cite overlapping spans of the same file with DIFFERENT bounds, one of
# them is stale and a reader cannot tell which — and the reader has no way to
# find out which without opening the file, which is the work the citation existed
# to save. This is what made the four corrupted citations legible as a defect
# rather than as a preference: `:573-574` and `:572-573` named the same
# three-line guard as two different things.
CC_BAD=0; CC_PAIRS=0
grep -rhoE "$RANGE_RE" $CIT_ALL 2>/dev/null | sort -u > "$WORK/liveranges.txt"
while IFS= read -r r1; do
  [ -n "$r1" ] || continue
  f1="$(citfile "${r1%:*}")"; s1="${r1##*:}"; a1="${s1%%-*}"; b1="${s1##*-}"
  while IFS= read -r r2; do
    [ -n "$r2" ] || continue
    [ "$r1" = "$r2" ] && continue
    f2="$(citfile "${r2%:*}")"; [ "$f1" = "$f2" ] || continue
    s2="${r2##*:}"; a2="${s2%%-*}"; b2="${s2##*-}"
    # overlap, and not the identical span
    if [ "$a1" -le "$b2" ] && [ "$a2" -le "$b1" ]; then
      CC_PAIRS=$((CC_PAIRS+1))
      [ "$a1" = "$a2" ] && [ "$b1" = "$b2" ] || { CC_BAD=$((CC_BAD+1)); echo "      | $r1 and $r2 overlap but name different spans of ${f1#"$SRC"/}"; }
    fi
  done < "$WORK/liveranges.txt"
done < "$WORK/liveranges.txt"
[ "$CC_BAD" -eq 0 ] \
  && ok "no two range citations overlap while naming different spans — the same guard is not cited as two different things anywhere in the tree" \
  || no "$((CC_BAD/2)) contradicting range citation pair(s): one of each pair is stale and a reader cannot tell which"

echo "== 28. STABLE SEMANTIC ANCHORS — identity is CONTENT, position is a HINT =="
# WHY THIS EXISTS, AND WHAT MEASURED THE HOLE. Residue (mm) quantified it and
# named the remedy in one sentence: the citation guard checks RESOLVABILITY,
# NOT IDENTITY, and "the durable fix is an ANCHOR TOKEN or a CONTENT HASH
# instead of a line number". Sections 7, 23 and 27 above are every one of them
# POSITIONAL. Section 7 asks whether a number lands inside a file. Section 23
# asks whether the line it lands on does something. Section 27 asks whether a
# citation carrying two numbers carries two positions. NOT ONE OF THEM ASKS
# WHETHER THE LINE IS THE SAME OBJECT THE CITATION WAS WRITTEN ABOUT, which is
# why 20 of 27 drifted references passed all of them while silently wrong.
#
# WHAT AN ANCHOR IS HERE. Ten fields, pipe-delimited, declared in
# build-os/registry/scan-controls.sh between the ANCHOR-TABLE markers:
#
#   anchor_id | object_id | object_type | namespace_id | semantic_role |
#   artifact_ref | content_or_symbol_ref | version | created_at | supersedes
#
# RESOLUTION IS BY CONTENT. The anchor names a literal that must occur EXACTLY
# ONCE in its artifact; the line number is COMPUTED and never stored. A position
# may still be written down as `path:line#ANCHOR-ID` — the `#` half is the
# IDENTITY and the `:` half is a NAVIGATION HINT — and the eight subsections
# below drive the eight rules that distinction has to satisfy, each with the
# defect it fails on rather than only the case it passes.
ANC_TYPES="control_id decision_id packet_id finding_id evidence_id defect_class_id receipt_id ranking_id outcome_id section_anchor symbol_anchor test_assertion_anchor"
bash "$SCAN" anchors > "$WORK/anc_live.txt" 2>&1; ARC=$?
[ "$ARC" = "0" ] \
  && ok "the LIVE anchor table validates against the LIVE tree (scan-controls.sh anchors, exit 0)" \
  || { no "the live anchor table does not validate (exit $ARC) — every claim below would be about a broken table"; sed 's/^/      | /' "$WORK/anc_live.txt" | head -25; }
NANC="$(grep -c '^anchor: ' "$WORK/anc_live.txt" || true)"
[ "${NANC:-0}" -gt 0 ] \
  && ok "$NANC anchor record(s) are declared and listed (this section is not vacuous)" \
  || no "no anchor records were listed, so everything below is meaningless"
# Every one of the twelve declared object types must be CLAIMED by a live
# anchor. A type enum nothing instantiates is a schema, not a scheme.
ANC_TMISS=0; ANC_TSEEN=0
for t in $ANC_TYPES; do
  ANC_TSEEN=$((ANC_TSEEN+1))
  grep -q "^anchor: .* type=$t " "$WORK/anc_live.txt" || { ANC_TMISS=$((ANC_TMISS+1)); echo "      | no live anchor claims type $t"; }
done
[ "$ANC_TSEEN" -eq 12 ] \
  && ok "twelve anchor types are declared, and all twelve are checked here" \
  || no "$ANC_TSEEN anchor type(s) checked — the declared set is not twelve"
[ "$ANC_TMISS" -eq 0 ] \
  && ok "all twelve object types are instantiated by at least one live anchor — the enum is a scheme, not a schema" \
  || no "$ANC_TMISS declared anchor type(s) have no live instance"

# The fixture: a tiny artifact and an anchor table over it. Built at run time so
# no literal anchor record in this file can be mistaken for a live one.
mkanc(){ # <dir>
  local d="$1"
  rm -rf "$d"; mkdir -p "$d/art"
  printf 'alpha line\nBETA_MARK is the beta object\ngamma line\nDELTA_MARK is the delta object\nomega line\n' > "$d/art/objects.txt"
  {
    printf 'ANC-F001|obj.beta|control_id|fixture|the-beta-object|art/objects.txt|BETA_MARK|1|2026-08-02|-\n'
    printf 'ANC-F002|obj.delta|decision_id|fixture|the-delta-object|art/objects.txt|DELTA_MARK|1|2026-08-02|-\n'
  } > "$d/anchors.txt"
}
runanc(){ # <dir> [extra args...] -> exit code, output in $WORK/out.txt
  local d="$1"; shift
  bash "$SCAN" anchors --repo "$d" --anchors "$d/anchors.txt" "$@" > "$WORK/out.txt" 2>&1
}
ANCF="$WORK/anc"
mkanc "$ANCF"; runanc "$ANCF"; RC=$?
[ "$RC" = "0" ] \
  && ok "the clean anchor fixture validates (exit 0) — the red drives below fail for their own reason" \
  || { no "the clean anchor fixture already fails (exit $RC); every red drive after this would pass for the wrong reason"; dump; }

echo "== 28a. RULE 1 — an anchor SURVIVES the insertion of lines above it =="
# The whole defect class in four lines: the object does not move, the number
# does. An anchor resolved by content reports a DIFFERENT line and the SAME
# object; the number written beside it reports the same line and a different
# object. Both are executed here rather than argued.
mkanc "$ANCF"
runanc "$ANCF" --ref ANC-F001
A1_BEFORE="$(awk '/^resolved_line: /{print $2; exit}' "$WORK/out.txt")"
A1_OBJ_BEFORE="$(awk '/^object_id: /{print $2; exit}' "$WORK/out.txt")"
{ printf 'inserted 1\ninserted 2\ninserted 3\n'; cat "$ANCF/art/objects.txt"; } > "$ANCF/art/objects.new"
mv "$ANCF/art/objects.new" "$ANCF/art/objects.txt"
runanc "$ANCF" --ref ANC-F001; RC=$?
A1_AFTER="$(awk '/^resolved_line: /{print $2; exit}' "$WORK/out.txt")"
A1_OBJ_AFTER="$(awk '/^object_id: /{print $2; exit}' "$WORK/out.txt")"
{ [ "$RC" = "0" ] && [ -n "$A1_BEFORE" ] && [ "$A1_AFTER" -eq "$((A1_BEFORE + 3))" ]; } \
  && ok "three lines inserted above it move the anchor's RESOLVED POSITION from :$A1_BEFORE to :$A1_AFTER — the position is computed, not remembered" \
  || { no "the anchor did not track the insertion (before=$A1_BEFORE after=$A1_AFTER exit $RC)"; dump; }
{ [ -n "$A1_OBJ_BEFORE" ] && [ "$A1_OBJ_BEFORE" = "$A1_OBJ_AFTER" ]; } \
  && ok "and it names the SAME object across the move ($A1_OBJ_AFTER) — identity survived a change of position" \
  || no "the anchor's object changed under a pure line insertion ($A1_OBJ_BEFORE -> $A1_OBJ_AFTER)"
# RED: the positional form, driven over the same edit.
A1_STALE="$(sed -n "${A1_BEFORE}p" "$ANCF/art/objects.txt")"
A1_LIVE="$(sed -n "${A1_AFTER}p" "$ANCF/art/objects.txt")"
{ [ "$A1_STALE" != "$A1_LIVE" ] && printf '%s' "$A1_LIVE" | grep -qF 'BETA_MARK'; } \
  && ok "RED: the line number that was correct before the insertion now names DIFFERENT content, and it still resolves — the exact shape residue (mm) measured" \
  || no "RED FAILED: the stale position was not observed to drift, so this comparison proves nothing"

echo "== 28b. RULE 2 — two different objects CANNOT claim the same stable anchor =="
mkanc "$ANCF"; sed -i 's/^ANC-F002|/ANC-F001|/' "$ANCF/anchors.txt"
runanc "$ANCF"; RC=$?
{ [ "$RC" = "2" ] && saw "ANCHOR-COLLISION"; } \
  && ok "RED: one anchor_id claimed by two different objects is REFUSED (exit $RC)" \
  || { no "RED FAILED: two objects shared one anchor_id and it was accepted (exit $RC)"; dump; }
# And the other direction: two ids over ONE site. Distinct names for one object
# is how a stable anchor stops being stable.
mkanc "$ANCF"; sed -i 's/|art\/objects.txt|DELTA_MARK|/|art\/objects.txt|BETA_MARK|/' "$ANCF/anchors.txt"
runanc "$ANCF"; RC=$?
{ [ "$RC" = "2" ] && saw "ANCHOR-SITE-COLLISION"; } \
  && ok "RED: two different objects anchored at ONE content site is REFUSED (exit $RC)" \
  || { no "RED FAILED: two objects sharing a content site was accepted (exit $RC)"; dump; }

echo "== 28c. RULE 3 — a CURRENTLY RESOLVABLE line pointing at the WRONG OBJECT is REJECTED =="
# The heart of it. Line 4 of the fixture exists, is inside the file, is not
# blank, is not a comment and is not a closer — it passes every predicate
# sections 7 and 23 own. It is also the site of a DIFFERENT anchored object.
mkanc "$ANCF"
runanc "$ANCF" --ref 'art/objects.txt:4#ANC-F001'; RC=$?
{ [ "$RC" = "2" ] && saw "WRONG-OBJECT"; } \
  && ok "RED: a reference whose line resolves, and resolves to ANOTHER anchored object, is REJECTED (exit $RC)" \
  || { no "RED FAILED: a resolvable line naming the wrong object was accepted (exit $RC)"; dump; }
grep -q '^syntactic: OK' "$WORK/out.txt" \
  && ok "and the refusal states that the reference is SYNTACTICALLY FINE — the rejection is on identity, and says so" \
  || { no "the refusal does not separate the syntactic verdict from the identity verdict"; dump; }
runanc "$ANCF" --ref 'art/objects.txt:2#ANC-F001'; RC=$?
[ "$RC" = "0" ] \
  && ok "NEGATIVE CONTROL: the same reference at the RIGHT line is accepted (exit 0) — the check is not a blanket refusal" \
  || { no "a correct anchored reference was refused (exit $RC)"; dump; }

echo "== 28d. RULE 4 — GENERATED PROJECTIONS preserve stable identity =="
# A projection is the positional form regenerated FROM the anchor. It carries
# the token, so it round-trips; a projection that has been reduced to a bare
# `path:line` has thrown the identity away and is refused as such.
mkanc "$ANCF"
runanc "$ANCF" --project; RC=$?
cp "$WORK/out.txt" "$WORK/anc_proj.txt"
NPROJ="$(grep -c '#ANC-F' "$WORK/anc_proj.txt" || true)"
{ [ "$RC" = "0" ] && [ "${NPROJ:-0}" -gt 0 ]; } \
  && ok "$NPROJ projection(s) generated, every one carrying its anchor token (exit $RC)" \
  || { no "no projections carrying an anchor token were generated (exit $RC)"; dump; }
PROJBAD=0
while IFS= read -r p; do
  [ -n "$p" ] || continue
  runanc "$ANCF" --ref "$p" || PROJBAD=$((PROJBAD+1))
done < <(grep -oE '[A-Za-z0-9_./-]+:[0-9]+#ANC-F[0-9]+' "$WORK/anc_proj.txt")
{ [ "$PROJBAD" -eq 0 ] && [ "${NPROJ:-0}" -gt 0 ]; } \
  && ok "every generated projection validates back to its own anchor — the generator preserves identity rather than restating a position" \
  || no "$PROJBAD generated projection(s) do not validate against the table that generated them"
# RED: the same projection with the identity stripped.
PROJ1="$(grep -oE '[A-Za-z0-9_./-]+:[0-9]+#ANC-F[0-9]+' "$WORK/anc_proj.txt" | head -1)"
runanc "$ANCF" --ref "${PROJ1%%#*}"; RC=$?
{ [ "$RC" = "2" ] && saw "NO-ANCHOR"; } \
  && ok "RED: the same projection with its \`#anchor\` removed is REFUSED (exit $RC) — a bare position carries no identity to preserve" \
  || { no "RED FAILED: a projection stripped of its anchor token was accepted (exit $RC)"; dump; }

echo "== 28e. RULE 5 — a RENAMED heading SUPERSEDES an earlier one without rewriting history =="
# The rename case. The v1 record keeps its own content ref and its own
# created_at, stops resolving, and is NOT a violation because a later record
# declares that it superseded it. History is added to, never edited.
mkanc "$ANCF"
sed -i 's/^BETA_MARK is the beta object$/BETA_RENAMED is the beta object/' "$ANCF/art/objects.txt"
printf 'ANC-F003|obj.beta|control_id|fixture|the-beta-object|art/objects.txt|BETA_RENAMED|2|2026-08-02|ANC-F001\n' >> "$ANCF/anchors.txt"
runanc "$ANCF"; RC=$?
[ "$RC" = "0" ] \
  && ok "a renamed heading is carried by a v2 anchor that SUPERSEDES the v1 record, and the table validates (exit 0)" \
  || { no "a legitimate supersession was refused (exit $RC)"; dump; }
grep -q '^anchor: ANC-F001 .*status=SUPERSEDED' "$WORK/out.txt" \
  && ok "the v1 record is still LISTED, marked SUPERSEDED — it was retired, not deleted" \
  || { no "the superseded record is not reported as superseded"; dump; }
# RED: the same rename with no supersession declared is an unresolvable anchor.
mkanc "$ANCF"
sed -i 's/^BETA_MARK is the beta object$/BETA_RENAMED is the beta object/' "$ANCF/art/objects.txt"
runanc "$ANCF"; RC=$?
{ [ "$RC" = "2" ] && saw "ANCHOR-UNRESOLVED"; } \
  && ok "RED: the same rename with NO supersession declared is REFUSED (exit $RC) — silence is not history" \
  || { no "RED FAILED: an anchor whose content no longer exists was accepted (exit $RC)"; dump; }
# RED: a supersedes pointing at nothing.
mkanc "$ANCF"
printf 'ANC-F009|obj.beta|control_id|fixture|the-beta-object|art/objects.txt|BETA_MARK|2|2026-08-02|ANC-F404\n' >> "$ANCF/anchors.txt"
runanc "$ANCF"; RC=$?
{ [ "$RC" = "2" ] && saw "ANCHOR-SUPERSEDE"; } \
  && ok "RED: a supersedes naming an anchor the table does not declare is REFUSED (exit $RC)" \
  || { no "RED FAILED: a dangling supersedes link was accepted (exit $RC)"; dump; }

echo "== 28f. RULE 6 — a reference may resolve SYNTACTICALLY and still FAIL identity validation =="
# The generalization of 28c, and the sentence this tree has now named in six
# substrates. The two properties are computed SEPARATELY here so that the pass
# is not a restatement of the fail: the syntactic predicate is evaluated by this
# test, and the identity verdict comes from the tool.
mkanc "$ANCF"
SYN_OK=0
SYN_LINE=1
[ -f "$ANCF/art/objects.txt" ] && SYN_OK=$((SYN_OK+1))
[ "$SYN_LINE" -le "$(grep -c '' "$ANCF/art/objects.txt")" ] && SYN_OK=$((SYN_OK+1))
[ -n "$(sed -n "${SYN_LINE}p" "$ANCF/art/objects.txt" | tr -d '[:space:]')" ] && SYN_OK=$((SYN_OK+1))
[ "$SYN_OK" -eq 3 ] \
  && ok "the probe reference satisfies all three positional predicates this suite already owns: the file exists, the line is in bounds, and the line is not blank" \
  || no "the probe reference does not satisfy the positional predicates, so the identity failure below would be over-determined"
runanc "$ANCF" --ref 'art/objects.txt:1#ANC-F404'; RC=$?
{ [ "$RC" = "2" ] && saw "UNKNOWN-ANCHOR"; } \
  && ok "RED: and it FAILS identity validation anyway (exit $RC) — the anchor it names is not declared. Resolvability is not identity." \
  || { no "RED FAILED: a syntactically perfect reference to an undeclared anchor was accepted (exit $RC)"; dump; }
# ...and a STALE HINT is reported without being refused, because a line number
# is allowed to be a navigation hint. It is not allowed to be the identity.
mkanc "$ANCF"
runanc "$ANCF" --ref 'art/objects.txt:1#ANC-F001'; RC=$?
{ [ "$RC" = "0" ] && saw "HINT-STALE"; } \
  && ok "a reference whose ANCHOR is right and whose LINE is merely stale is REPORTED, not refused — the position is demoted to a hint, exactly as declared" \
  || { no "a stale navigation hint was treated as an identity failure (exit $RC)"; dump; }
grep -q '^projection: ' "$WORK/out.txt" \
  && ok "and the corrected projection is printed beside it, so repointing is mechanical rather than manual" \
  || { no "no corrected projection was offered for the stale hint"; dump; }

echo "== 28g. RULE 7 — historical references continue to resolve their ORIGINAL objects =="
# A receipt written a month ago cites the object as it was. Resolving its anchor
# must return THAT object at THAT version — not the object that superseded it.
# Silently redirecting an old citation to a new object is how a history stops
# being a history.
mkanc "$ANCF"
sed -i 's/^BETA_MARK is the beta object$/BETA_RENAMED is the beta object/' "$ANCF/art/objects.txt"
printf 'ANC-F003|obj.beta|control_id|fixture|the-beta-object|art/objects.txt|BETA_RENAMED|2|2026-08-02|ANC-F001\n' >> "$ANCF/anchors.txt"
runanc "$ANCF" --ref ANC-F001; RC=$?
H_VER="$(awk '/^version: /{print $2; exit}' "$WORK/out.txt")"
H_CREF="$(sed -n 's/^content_or_symbol_ref: //p' "$WORK/out.txt" | head -1)"
H_BY="$(awk '/^superseded_by: /{print $2; exit}' "$WORK/out.txt")"
{ [ "$RC" = "0" ] && [ "$H_VER" = "1" ] && [ "$H_CREF" = "BETA_MARK" ]; } \
  && ok "the historical anchor still returns its ORIGINAL version ($H_VER) and its ORIGINAL content ref ($H_CREF) — the v2 rename did not rewrite it" \
  || { no "the historical anchor was rewritten by its successor (version=$H_VER cref=$H_CREF exit $RC)"; dump; }
[ "$H_BY" = "ANC-F003" ] \
  && ok "and it names its successor ($H_BY), so a reader following an old citation is told what happened rather than sent somewhere else" \
  || { no "the historical anchor does not name the successor that superseded it (got \"$H_BY\")"; dump; }
# The same property on the LIVE table: this packet renamed section 7's heading
# above, and the v1 section anchor must still carry the ORIGINAL title.
bash "$SCAN" anchors --ref ANC-0010-a > "$WORK/out.txt" 2>&1; RC=$?
L_CREF="$(sed -n 's/^content_or_symbol_ref: //p' "$WORK/out.txt" | head -1)"
{ [ "$RC" = "0" ] && printf '%s' "$L_CREF" | grep -qF 'resolves to a real line of a real file'; } \
  && ok "LIVE: the v1 anchor for this suite's own renamed section 7 still carries the heading as it was written" \
  || { no "LIVE: the pre-rename section anchor no longer carries its original heading (exit $RC)"; dump; }

echo "== 28h. RULE 8 — the SEALED decision and its selection still resolve after this packet moved lines =="
# THE SELF-REFERENTIAL CASE. This packet inserted this very section into this
# very file and rewrote lines of scan-controls.sh, so it moved positions that
# its own sealed evidence is cited by. If the anchors are worth anything they
# survive that, and if they are not, the packet has invalidated the experiment
# measuring it. Both halves are executed.
A8_BAD=0
for a in ANC-0002 ANC-0003 ANC-0008; do
  bash "$SCAN" anchors --ref "$a" > "$WORK/out.txt" 2>&1 || { A8_BAD=$((A8_BAD+1)); echo "      | $a does not resolve"; continue; }
  grep -q '^status: RESOLVED' "$WORK/out.txt" || { A8_BAD=$((A8_BAD+1)); echo "      | $a resolved with a non-RESOLVED status"; }
done
[ "$A8_BAD" -eq 0 ] \
  && ok "the sealed decision, the selected candidate and the sealed ranking snapshot ALL still resolve by anchor after this packet's line movement" \
  || no "$A8_BAD of the three sealed anchors no longer resolve"
bash "$SCAN" anchors --ref ANC-0002 > "$WORK/out.txt" 2>&1
A8_DLINE="$(awk '/^resolved_line: /{print $2; exit}' "$WORK/out.txt")"
{ [ -n "$A8_DLINE" ] && sed -n "${A8_DLINE}p" "$SRC/build-os/metrics/decision_telemetry.tsv" | grep -qF 'PACKET-0029-citation-anchor-tokens'; } \
  && ok "and the line the decision anchor resolves to still records PACKET-0029 as the selection — the resolved position is DERIVED and lands on the right row" \
  || no "the decision anchor resolves to a line that does not carry the recorded selection"
# The number that would be destroyed if any of this were wrong.
bash "$SRC/build-os/metrics/rank-candidates.sh" rank --decision-id DECISION-0011-p5b-next-after-p3b > "$WORK/s1.txt" 2>&1; RC=$?
{ [ "$RC" = "0" ] && grep -qx 'rank_of_selected: 1' "$WORK/s1.txt"; } \
  && ok "and the sealed ordering still derives rank_of_selected: 1 for the executed candidate (exit $RC) — one observation, and NOT evidence of ranker skill" \
  || { no "the sealed ordering no longer derives rank_of_selected: 1 (exit $RC)"; sed 's/^/      | /' "$WORK/s1.txt" | tail -12; }
# RED: the positional form, over a line this packet ACTUALLY moved. 924 was the
# suite verdict's line before this section existed; it is built at run time so
# no literal here is swept as a citation.
A8_OLD=$((924))
bash "$SCAN" anchors --ref ANC-0012 > "$WORK/out.txt" 2>&1
A8_NEW="$(awk '/^resolved_line: /{print $2; exit}' "$WORK/out.txt")"
A8_CREF="$(sed -n 's/^content_or_symbol_ref: //p' "$WORK/out.txt" | head -1)"
{ [ -n "$A8_NEW" ] && [ "$A8_NEW" != "$A8_OLD" ] && ! sed -n "${A8_OLD}p" "$SRC/tests/control_registry_tests.sh" | grep -qF "$A8_CREF"; } \
  && ok "RED: the position that named this suite's own assertion before this packet ($A8_OLD) no longer does, while its anchor resolves at :$A8_NEW — the drift is real and the anchor absorbed it" \
  || no "RED FAILED: the pre-packet position was not observed to drift ($A8_OLD vs $A8_NEW), so rule 8 was not exercised on a real move"

echo "== 29. DERIVED COUNTS — a stated count is CHECKED AGAINST ITS SOURCE, not remembered =="
# WHAT MEASURED THE HOLE, IN THIS REPOSITORY'S OWN RECORD. The doctrine "DERIVE
# every count; never restate one" is written in four artefacts and enforced by
# discipline alone, and discipline kept failing:
#
#   1. build-os/memory/tool_router.md said the second-eyes provider had been
#      absent "at each of the last **nine** packets" while the true streak was
#      NINETEEN. The file that tracks review discipline understated the gap by
#      more than half, and the whole 2190-assertion suite was green over it.
#   2. A signal-snapshot total was taken with `wc -l` where
#      `grep -c '^SIGNAL-SNAPSHOT-'` was meant, overstating a store by ~2x for
#      two closes: 176 file lines reported for 97 records.
#   3. `grep -c 'authority_mismatch: declared'` gives 27 and the anchored
#      `grep -c '^authority_mismatch: declared'` gives 22, because five prose
#      lines mention the field mid-sentence. Every brief has to warn about it.
#
# Section 25 above is the closest prior art and it is BESPOKE: it hard-codes ONE
# count (evidence_refs) and one extractor regex. The mechanism driven here is
# section 25 generalised — a DECLARATIVE table, checked the same way.
#
# THE RECORD. Eight fields, pipe-delimited, declared in
# build-os/registry/scan-controls.sh between the COUNT-TABLE markers:
#
#   count_id | stated_artifact | stated_content | derivation_kind |
#   derivation_source | derivation_pattern | created_at | note
#
# AND THE DESIGN CLAIM THE SUBSECTIONS BELOW EXIST TO DRIVE: **THE RECORD STORES
# NO NUMBER.** It stores WHERE a count is stated and HOW it is derived. The
# stated value is read out of the live prose at resolution and the derived value
# is computed from the live source at resolution, so the table itself can never
# become the third stale copy of the truth it is policing. Resolution is BY
# CONTENT — the stated literal must occur EXACTLY ONCE, and the line number is a
# computed navigation hint, never an identity.
CNTF="$WORK/cnt"
mkcnt(){ # <dir> — the tree the fixture tables are declarations about
  local d="$1" i
  rm -rf "$d"; mkdir -p "$d/doc" "$d/store" "$d/recs"
  # A router-shaped document carrying the SAME stale sentence the live one did.
  {
    printf 'preamble line\n'
    printf '| Second-eyes | NONE. Absent from every surface, checked at each of the last **nine** packets. Until a provider is live... |\n'
    printf 'tail line\n'
  } > "$d/doc/router.md"
  # Nineteen closed packets, one receipt file each — the derivation source.
  for i in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19; do
    printf '# receipt %s\n' "$i" > "$d/recs/gravito_p$i.md"
  done
  # A record store whose LINE count (7) is not its RECORD count (3) — instance 2.
  printf '# header\nSNAP-0001\tone\n  wrapped 0001\nSNAP-0002\ttwo\n  wrapped 0002\nSNAP-0003\tthree\n  wrapped 0003\n' > "$d/store/snapshots.tsv"
  # A registry-shaped file where anchored (3) and unanchored (5) differ — instance 3.
  printf 'authority_mismatch: declared\nnotes: the flag authority_mismatch: declared marks both kinds\nauthority_mismatch: declared\nnotes: see authority_mismatch: declared above\nauthority_mismatch: declared\n' > "$d/store/registry.txt"
  # The prose that restates those counts.
  printf 'report\nthe anchored grep yields **3** declarations\nthe store holds **7** records\nthe roster names **several** items\n' > "$d/doc/report.md"
}
cnttab(){ printf '%s\n' "$@" > "$CNTF/counts.txt"; }
runcnt(){ bash "$SCAN" counts --repo "$CNTF" --counts "$CNTF/counts.txt" > "$WORK/out.txt" 2>&1; }
CR_STREAK='DC-F001|doc/router.md|checked at each of the last **{N}** packets|files|recs|gravito_*.md|2026-08-03|the second-eyes streak'
CR_ANCH='DC-F002|doc/report.md|the anchored grep yields **{N}** declarations|lines|store/registry.txt|^authority_mismatch: declared|2026-08-03|anchored, and the anchoring is the point'
CR_RECS='DC-F003|doc/report.md|the store holds **{N}** records|lines|store/snapshots.tsv|^SNAP-|2026-08-03|records, not lines'

# --- the LIVE table, against the LIVE tree -----------------------------------
bash "$SCAN" counts > "$WORK/cnt_live.txt" 2>&1; CRC=$?
[ "$CRC" = "0" ] \
  && ok "the LIVE derived-count table agrees with the live tree (scan-controls.sh counts, exit 0)" \
  || { no "the live derived-count table does not agree (exit $CRC) — every claim below would be about a broken table"; sed 's/^/      | /' "$WORK/cnt_live.txt" | head -25; }
NCNT="$(grep -c '^count: ' "$WORK/cnt_live.txt" || true)"
[ "${NCNT:-0}" -gt 0 ] \
  && ok "$NCNT derived-count record(s) are declared and listed (this section is not vacuous)" \
  || no "no derived-count records were listed, so everything below is meaningless"
[ "$(grep -c 'status=STALE' "$WORK/cnt_live.txt" || true)" = "0" ] \
  && ok "no live record is STALE" \
  || no "a live derived-count record is STALE"
# THE LIVE BINDING, RECOMPUTED HERE INDEPENDENTLY. The suite must not learn the
# expected value from the instrument it is checking, so the streak is counted
# from the receipt store directly and compared to what the scanner derived.
LIVESTREAK="$(find "$SRC/build-os/receipts" -maxdepth 1 -name 'gravito_*.md' | grep -c . || true)"
SCANSTREAK="$(sed -n 's/^count: DC-0001 .*derived=\([0-9]*\).*/\1/p' "$WORK/cnt_live.txt" | head -1)"
{ [ "${LIVESTREAK:-0}" -gt 0 ] && [ "$LIVESTREAK" = "$SCANSTREAK" ]; } \
  && ok "DC-0001 derives the second-eyes streak as $SCANSTREAK, which is independently $LIVESTREAK closed-packet receipts" \
  || no "DC-0001 derived '$SCANSTREAK'; counting the receipt store here gives '$LIVESTREAK'"
STATEDSTREAK="$(sed -n 's/^count: DC-0001 stated=\([0-9]*\) .*/\1/p' "$WORK/cnt_live.txt" | head -1)"
{ [ -n "$STATEDSTREAK" ] && [ "$STATEDSTREAK" = "$LIVESTREAK" ]; } \
  && ok "and the router STATES $STATEDSTREAK — the number that was wrong is now bound to the store that produces it" \
  || no "the router states '$STATEDSTREAK' where the receipt store gives '$LIVESTREAK'"
# The counts block GATES the `check` path too — a table checked only when
# somebody asks is the shelfware this module's header is about.
bash "$SCAN" check > "$WORK/cnt_check.txt" 2>&1
grep -q 'derived count(s)' "$WORK/cnt_check.txt" \
  && ok 'the "check" path runs the derived-count reconciliation as well (not an ask-only subcommand)' \
  || { no "scan-controls.sh check does not run the derived-count reconciliation"; sed 's/^/      | /' "$WORK/cnt_check.txt" | tail -10; }

# --- the clean fixture -------------------------------------------------------
mkcnt "$CNTF"
sed -i 's/\*\*nine\*\*/**19**/' "$CNTF/doc/router.md"
sed -i 's/\*\*7\*\* records/**3** records/' "$CNTF/doc/report.md"
cnttab "$CR_STREAK" "$CR_ANCH" "$CR_RECS"
runcnt; RC=$?
[ "$RC" = "0" ] \
  && ok "the clean count fixture validates (exit 0) — the red drives below fail for their own reason" \
  || { no "the clean count fixture already fails (exit $RC); every red drive after it would pass for the wrong reason"; dump; }

echo "== 29a. RED DRIVE — the router's stale streak, the fixture that justified this tool =="
# The live defect, reproduced: a document saying "nine" over a store of nineteen.
mkcnt "$CNTF"; cnttab "$CR_STREAK"
runcnt; RC=$?
[ "$RC" = "2" ] \
  && ok "RED: a document stating 'nine' over a store of nineteen is REFUSED (exit 2)" \
  || { no "RED FAILED: the stale streak was not refused (exit $RC)"; dump; }
grep -q 'COUNT-STALE' "$WORK/out.txt" \
  && ok "RED: the finding is classified COUNT-STALE" \
  || { no "RED FAILED: no COUNT-STALE finding"; dump; }
{ grep -q 'stated=9' "$WORK/out.txt" && grep -q 'derived=19' "$WORK/out.txt"; } \
  && ok "RED: it prints BOTH numbers — stated=9, derived=19 — so the reader is not asked to take the verdict on trust" \
  || { no "RED FAILED: the stated and derived values are not both reported"; dump; }
grep -q 'nine' "$WORK/out.txt" \
  && ok "RED: and it quotes the offending token ('nine') as written, so the site is findable by content" \
  || { no "RED FAILED: the stated token is not quoted"; dump; }
# THE COUNTERFACTUAL, EXECUTED RATHER THAN ASSERTED. Section 25's extractor is
# the nearest thing this repository already had to a derived-count check. Run it
# over the same stale document: it finds nothing, because it is bound to one
# hard-coded subject. That is why the stale "nine" survived 2190 green assertions.
S25HITS="$(statedrefs "$CNTF/doc/router.md" | grep -c . || true)"
[ "${S25HITS:-0}" = "0" ] \
  && ok "COUNTERFACTUAL: section 25's bespoke extractor finds 0 totals in the same stale document — the old way misses this defect, executed rather than argued" \
  || no "section 25's extractor unexpectedly found $S25HITS total(s) in the fixture router"
# And the fix is a one-word prose edit, with NO edit to the table.
CNTTAB_BEFORE="$(cat "$CNTF/counts.txt")"
sed -i 's/\*\*nine\*\*/**nineteen**/' "$CNTF/doc/router.md"
runcnt; RC=$?
{ [ "$RC" = "0" ] && [ "$CNTTAB_BEFORE" = "$(cat "$CNTF/counts.txt")" ]; } \
  && ok "GREEN: correcting the prose to 'nineteen' clears it at exit 0 with the count table BYTE-IDENTICAL — the record stores no number, so the fix is not a second place to be wrong" \
  || { no "the corrected document did not clear (exit $RC), or the table had to change"; dump; }
grep -q 'stated=19' "$WORK/out.txt" \
  && ok "and the English cardinal 'nineteen' reads as 19 — prose stays prose and is still machine-comparable" \
  || { no "the cardinal 'nineteen' was not read as 19"; dump; }

echo "== 29b. RED DRIVE — instance 3: an UNANCHORED line pattern is refused, not silently widened =="
# `grep -c 'authority_mismatch: declared'` gives 27; `grep -c '^authority_...'`
# gives 22. The five extras are prose. The kind `lines` therefore REQUIRES `^`:
# the sloppy form is not a mistake that can be made quietly here, it is a form
# the schema refuses to accept.
mkcnt "$CNTF"
cnttab 'DC-F002|doc/report.md|the anchored grep yields **{N}** declarations|lines|store/registry.txt|authority_mismatch: declared|2026-08-03|UNANCHORED ON PURPOSE'
runcnt; RC=$?
{ [ "$RC" = "2" ] && grep -q 'COUNT-UNANCHORED' "$WORK/out.txt"; } \
  && ok "RED: an unanchored 'lines' pattern is REFUSED as COUNT-UNANCHORED (exit 2) — the 27-vs-22 form cannot be declared" \
  || { no "RED FAILED: the unanchored pattern was accepted (exit $RC)"; dump; }
cnttab "$CR_ANCH"
runcnt; RC=$?
{ [ "$RC" = "0" ] && grep -q 'derived=3' "$WORK/out.txt"; } \
  && ok "GREEN: the anchored pattern derives 3 — the two prose mentions that the unanchored form would have swept up are excluded" \
  || { no "the anchored pattern did not derive 3 (exit $RC)"; dump; }
# The counterfactual, executed: what the unanchored form WOULD have counted.
LOOSE="$(grep -c 'authority_mismatch: declared' "$CNTF/store/registry.txt" || true)"
ANCH="$(grep -c '^authority_mismatch: declared' "$CNTF/store/registry.txt" || true)"
{ [ "$LOOSE" = "5" ] && [ "$ANCH" = "3" ]; } \
  && ok "COUNTERFACTUAL: on the same file the unanchored grep gives $LOOSE and the anchored gives $ANCH — the gap is real and is the gap the schema closes" \
  || no "the fixture does not reproduce the anchored/unanchored gap (loose=$LOOSE anchored=$ANCH)"

echo "== 29c. RED DRIVE — instance 2: a RECORD count is not a LINE count =="
# 176 file lines reported where 97 records were meant. There is no line-count
# derivation kind at all: a count of records must be spelled as an anchored
# pattern match, so the `wc -l` answer is not merely discouraged, it is refused.
mkcnt "$CNTF"; cnttab "$CR_RECS"
FIXLINES="$(grep -c '' "$CNTF/store/snapshots.tsv" || true)"
runcnt; RC=$?
{ [ "$RC" = "2" ] && grep -q 'COUNT-STALE' "$WORK/out.txt" && grep -q 'derived=3' "$WORK/out.txt"; } \
  && ok "RED: a store stated at its LINE count ($FIXLINES) is refused against its RECORD count (3) — the ~2x overstatement is caught" \
  || { no "RED FAILED: the line-count restatement was not caught (exit $RC)"; dump; }
grep -q "stated=$FIXLINES" "$WORK/out.txt" \
  && ok "RED: and the report names the wrong figure ($FIXLINES) beside the right one, which is what makes it fixable" \
  || { no "RED FAILED: the stated line count was not reported"; dump; }

echo "== 29d. RULE — identity is CONTENT; the line number is a computed hint =="
mkcnt "$CNTF"
sed -i 's/\*\*nine\*\*/**19**/' "$CNTF/doc/router.md"
cnttab "$CR_STREAK"
runcnt
C_BEFORE="$(sed -n 's/^count: DC-F001 .* at=doc\/router.md:\([0-9]*\) .*/\1/p' "$WORK/out.txt" | head -1)"
{ printf 'inserted 1\ninserted 2\ninserted 3\ninserted 4\n'; cat "$CNTF/doc/router.md"; } > "$CNTF/doc/router.new"
mv "$CNTF/doc/router.new" "$CNTF/doc/router.md"
runcnt; RC=$?
C_AFTER="$(sed -n 's/^count: DC-F001 .* at=doc\/router.md:\([0-9]*\) .*/\1/p' "$WORK/out.txt" | head -1)"
{ [ "$RC" = "0" ] && [ -n "$C_BEFORE" ] && [ "$C_AFTER" -eq "$((C_BEFORE + 4))" ]; } \
  && ok "four lines inserted above it move the reported position from :$C_BEFORE to :$C_AFTER and change nothing else — the position is computed at every resolution, not stored" \
  || { no "the count record did not track the insertion (before=$C_BEFORE after=$C_AFTER exit $RC)"; dump; }
# ...and the record has no line number in it to go stale in the first place.
grep -qE '\|[0-9]+\|' "$CNTF/counts.txt" \
  && no "a fixture count record carries a bare integer field — the scheme's whole claim is that it stores no number" \
  || ok "no FIXTURE count record carries a bare integer field: not the stated value, and not a line number"

# THE SAME CLAIM, ASSERTED WHERE IT IS MADE — OVER THE **LIVE** TABLE.
# The check above ran the predicate `\|[0-9]+\|` against the FIXTURE table, and
# that regex could not have matched the defect it was named for even if it had
# been pointed at the live one: `DC-0003` shipped with the stated_content
# `**14 of {N} entries carrying`, whose `14` sits mid-field and never between
# two pipes. The claim was universal and the assertion was not, so INSTANCE SIX
# of this packet's own defect was found by review rather than by the guard.
# What follows reads the LIVE COUNT_TABLE out of the scanner and drives the
# predicate in BOTH DIRECTIONS: it must be clean now, and it must have BITTEN on
# the table as it shipped. Neither direction is asserted; both are executed.
sed -n '/^# COUNT-TABLE:START$/,/^# COUNT-TABLE:END$/p' "$SCAN" \
  | sed -n "s/^'\\(DC-[^|]*|.*\\)'$/\\1/p" > "$WORK/live_counts.txt"
NLIVEREC="$(grep -c . "$WORK/live_counts.txt" || true)"
[ "${NLIVEREC:-0}" -ge 1 ] \
  && ok "$NLIVEREC live count record(s) were read out of the scanner's own table (this check has something to bite on)" \
  || no "no live count records could be parsed out of $SCAN — the assertions below would be vacuous"
# field 3 with the {N} placeholder removed: a digit surviving that is a number
# the record PERSISTED, which is the one thing this table promises never to do.
# AN IDENTIFIER IS NOT A COUNT, and this distinction is not cosmetic: the first
# version of this predicate flagged DC-0003's note for the digits inside the
# token `DC-0002`, which is a NAME. Stable-id tokens (`DC-0002`, `ANC-0010`,
# `PACKET-0041`) and ISO dates are stripped before the test; what survives and
# still carries a digit is a QUANTITY the record persisted.
barecounts(){ # <file of records> -> offending "id<TAB>field<TAB>value" lines
  awk -F'|' '{
    sc = $3; nt = $8
    gsub(/\{N\}/, "", sc);                      gsub(/\{N\}/, "", nt)
    gsub(/[0-9]{4}-[0-9]{2}-[0-9]{2}/, "", sc); gsub(/[0-9]{4}-[0-9]{2}-[0-9]{2}/, "", nt)
    gsub(/[A-Za-z]+-[0-9]+[A-Za-z]*/, "", sc);  gsub(/[A-Za-z]+-[0-9]+[A-Za-z]*/, "", nt)
    if (sc ~ /[0-9]/) print $1 "\tstated_content\t" $3
    if (nt ~ /[0-9]/) print $1 "\tnote\t" $8
  }' "$1"
}
barecounts "$WORK/live_counts.txt" > "$WORK/bare_live.txt"
NBARE="$(grep -c . "$WORK/bare_live.txt" || true)"
[ "${NBARE:-0}" = "0" ] \
  && ok "NO live count record persists a digit in its stated_content or its note — the header's claim that the record stores no number is now MECHANICAL, asserted over the table it is a claim about" \
  || { no "$NBARE live count field(s) persist a number the record was supposed to derive"; sed 's/^/      | /' "$WORK/bare_live.txt" | head -10; }
# RED DRIVE on the predicate itself, reconstructing the table AS IT SHIPPED. A
# check that has only ever been observed passing is a check nobody has tested.
sed 's/|of {N} entries carrying|/|**14 of {N} entries carrying|/' "$WORK/live_counts.txt" > "$WORK/preFix_counts.txt"
cmp -s "$WORK/live_counts.txt" "$WORK/preFix_counts.txt" \
  && no "the pre-fix reconstruction is identical to the live table, so the red drive below proves nothing" \
  || ok "the pre-fix table is reconstructed and DIFFERS from the live one — the red drive below is about a real prior state"
barecounts "$WORK/preFix_counts.txt" > "$WORK/bare_pre.txt"
NBAREPRE="$(grep -c . "$WORK/bare_pre.txt" || true)"
{ [ "${NBAREPRE:-0}" -ge 1 ] && grep -q 'stated_content' "$WORK/bare_pre.txt"; } \
  && ok "RED: the same predicate flags $NBAREPRE field(s) on the table AS IT SHIPPED — it would have caught instance six before review did" \
  || { no "RED FAILED: the predicate does not bite on the pre-fix table, so it is not the assertion that would have caught the defect"; sed 's/^/      | /' "$WORK/bare_pre.txt" | head -5; }
# And the fix must not have cost uniqueness: the shortened literal still names
# exactly one line of the artifact it is a claim about.
[ "$(grep -cF ' entries carrying' "$MISM" || true)" = "1" ] \
  && ok "the shortened DC-0003 literal ' entries carrying' occurs exactly ONCE in MISMATCHES.md — dropping the 14 cost no uniqueness" \
  || no "' entries carrying' does not occur exactly once in MISMATCHES.md, so DC-0003 no longer identifies one site"

echo "== 29e. RED DRIVE — an UNRESOLVED or AMBIGUOUS stated site fails CLOSED =="
# The blinded-scanner failure, in its two forms. A site that resolves to nothing
# and a site that resolves to two places must both REFUSE: a check that shrugs
# when it cannot find its subject is a check that passes whatever the tree says.
mkcnt "$CNTF"; cnttab "$CR_STREAK"
sed -i 's/checked at each of the last/checked at each of the previous/' "$CNTF/doc/router.md"
runcnt; RC=$?
{ [ "$RC" = "2" ] && grep -q 'COUNT-UNRESOLVED' "$WORK/out.txt"; } \
  && ok "RED: a stated site whose content no longer exists is COUNT-UNRESOLVED and REFUSED, not skipped" \
  || { no "RED FAILED: a vanished stated site did not refuse (exit $RC)"; dump; }
mkcnt "$CNTF"; cnttab "$CR_STREAK"
sed -n '2p' "$CNTF/doc/router.md" >> "$CNTF/doc/router.md"
runcnt; RC=$?
{ [ "$RC" = "2" ] && grep -q 'COUNT-UNRESOLVED' "$WORK/out.txt"; } \
  && ok "RED: a stated site that occurs TWICE is REFUSED — content that names two lines identifies neither, so there is no 'the' stated value" \
  || { no "RED FAILED: an ambiguous stated site did not refuse (exit $RC)"; dump; }

echo "== 29f. RED DRIVE — an unreadable stated value, and a VACUOUS derivation =="
mkcnt "$CNTF"
cnttab 'DC-F004|doc/report.md|the roster names **{N}** items|files|recs|gravito_*.md|2026-08-03|the stated value is a word this scheme cannot read'
runcnt; RC=$?
{ [ "$RC" = "2" ] && grep -q 'COUNT-UNREADABLE' "$WORK/out.txt"; } \
  && ok "RED: a stated value of 'several' is COUNT-UNREADABLE and REFUSED — an unparseable number is never treated as agreement" \
  || { no "RED FAILED: an unreadable stated value did not refuse (exit $RC)"; dump; }
mkcnt "$CNTF"
printf 'report\nthe empty roster names **0** items\n' > "$CNTF/doc/report.md"
cnttab 'DC-F005|doc/report.md|the empty roster names **{N}** items|files|recs|nothing_matches_*.md|2026-08-03|a glob that matches nothing'
runcnt; RC=$?
{ [ "$RC" = "2" ] && grep -q 'COUNT-VACUOUS' "$WORK/out.txt"; } \
  && ok "RED: a derivation that produces ZERO is REFUSED as COUNT-VACUOUS even though the stated 0 'agrees' — a broken derivation and a genuinely empty one are indistinguishable, so this fails closed" \
  || { no "RED FAILED: a zero derivation certified itself by agreeing with a stated zero (exit $RC)"; dump; }
# A MALFORMED ERE, which `grep -c` answers with exit >= 2 AND NO NUMBER. Under
# `|| true` that emptiness reached the comparison and produced a finding reading
# "gives " with nothing after it: fail-closed and unreadable at once. The pattern
# must be NAMED. The counterfactual is executed first, so the premise is measured
# rather than assumed.
mkcnt "$CNTF"
printf 'report\nthe store holds **2** records\n' > "$CNTF/doc/report.md"
grep -cE -- '^[unclosed' "$CNTF/store/snapshots.tsv" >/dev/null 2>&1; GREPRC=$?
# Written as a `case` and NOT as a numeric floor, ON PURPOSE: `grep -c` returns
# 0 for matches and 1 for none, so anything else is an ERROR — this is an exact
# membership test, not a coverage floor. Spelling it as a floor would enrol the
# line in the `tests.nonvacuity_minimums` family it does not belong to. Section
# 21 scans this file TEXTUALLY, so even naming the rejected form in this comment
# enrols it — which it duly did on the first attempt, and is why the form is
# described here in words instead of quoted.
case "${GREPRC:-0}" in
  0|1) no "grep -cE did not error on a malformed ERE (exit $GREPRC), so this red drive is about nothing" ;;
  *)   ok "COUNTERFACTUAL: grep -cE on a malformed ERE exits $GREPRC and prints no number — the premise of this guard, measured not assumed" ;;
esac
cnttab 'DC-FERR|doc/report.md|the store holds **{N}** records|lines|store/snapshots.tsv|^[unclosed|2026-08-03|a malformed ERE'
runcnt; RC=$?
{ [ "$RC" = "2" ] && grep -q 'COUNT-SOURCE' "$WORK/out.txt" && grep -qF 'not a usable ERE' "$WORK/out.txt"; } \
  && ok "RED: an unusable ERE is REFUSED as COUNT-SOURCE and the offending pattern is NAMED — not swallowed into an empty derived value" \
  || { no "RED FAILED: a malformed ERE was not refused-and-named (exit $RC)"; dump; }
grep -qE 'gives *$|derived= ' "$WORK/out.txt" \
  && { no "the report still contains an empty derived value — the unreadable form survived"; dump; } \
  || ok "and no finding reports an EMPTY derived value anywhere in the output"

echo "== 29g. RED DRIVE — the schema refuses a malformed, colliding or unknown-kind record =="
mkcnt "$CNTF"
cnttab 'DC-F001|doc/router.md|checked at each of the last **{N}** packets|files|recs|gravito_*.md|2026-08-03'
runcnt; RC=$?
{ [ "$RC" = "2" ] && grep -q 'COUNT-SCHEMA' "$WORK/out.txt"; } \
  && ok "RED: a 7-field record is COUNT-SCHEMA — a partially declared count is an undeclared one" \
  || { no "RED FAILED: a short record was accepted (exit $RC)"; dump; }
mkcnt "$CNTF"; sed -i 's/\*\*nine\*\*/**19**/' "$CNTF/doc/router.md"
cnttab "$CR_STREAK" "$CR_STREAK"
runcnt; RC=$?
{ [ "$RC" = "2" ] && grep -q 'COUNT-COLLISION' "$WORK/out.txt"; } \
  && ok "RED: a duplicated count_id is COUNT-COLLISION — the id IS the identity" \
  || { no "RED FAILED: a duplicated id was accepted (exit $RC)"; dump; }
mkcnt "$CNTF"
cnttab 'DC-F006|doc/router.md|checked at each of the last **{N}** packets|bytes|recs|gravito_*.md|2026-08-03|no such kind'
runcnt; RC=$?
{ [ "$RC" = "2" ] && grep -q 'COUNT-KIND' "$WORK/out.txt"; } \
  && ok "RED: an unrecognised derivation kind is COUNT-KIND and REFUSED — an unknown kind must never fall through to permissive" \
  || { no "RED FAILED: an unknown derivation kind was accepted (exit $RC)"; dump; }
mkcnt "$CNTF"
cnttab 'DC-F007|doc/router.md|checked at each of the last packets|files|recs|gravito_*.md|2026-08-03|no {N} placeholder'
runcnt; RC=$?
{ [ "$RC" = "2" ] && grep -q 'COUNT-SCHEMA' "$WORK/out.txt"; } \
  && ok "RED: a stated_content with no {N} placeholder is COUNT-SCHEMA — a site with no number in it states no count" \
  || { no "RED FAILED: a record with no {N} was accepted (exit $RC)"; dump; }
mkcnt "$CNTF"
: > "$CNTF/counts.txt"
runcnt; RC=$?
[ "$RC" = "2" ] \
  && ok "RED: an EMPTY count table is REFUSED — a table that declares nothing validates everything at once, which is the blinded-scanner failure this module already refuses three times" \
  || { no "RED FAILED: an empty count table was accepted (exit $RC)"; dump; }

echo "== 19b. RULING 4 — coverage follows IDENTITY, not geography (executable roots + top-level tools) =="
# The operator's ruling, verbatim in spirit: executable tools capable of
# refusing, mutating, measuring, or producing evidence must be registered
# regardless of directory — otherwise the easiest way around enforcement is
# moving the file. The mechanism: a NAMED ALLOWLIST of executable roots
# (including bench/), plus discovery of EXECUTABLE .sh/.mjs files at the repo
# top level. Scanning was NOT broadened to every file indiscriminately: inside
# roots the rule is unchanged, and at the top level only the executable bit
# makes a file a tool.
mkbench(){ # <dir> <relpath> — mkfix plus one registered, EXECUTABLE benchmark tool at <relpath>
  local d="$1" rel="$2"
  mkfix "$d"
  mkdir -p "$d/$(dirname "$rel")" 2>/dev/null
  printf '#!/usr/bin/env bash\n[ -f ok ] || { echo "bench refusal" >&2; exit 2; }\n' > "$d/$rel"
  chmod +x "$d/$rel"
  cat >> "$d/registry.txt" <<EOF2

control: fixture.bench_tool
class: A
implementation_status: load_bearing
empirical_status: red_driven
runtime_authority: gate
nervous_system_role: reflex
inputs: the fixture tree
output: a refusal
owning_module: $rel
consuming_policies: the tool's own exit code
evidence_refs: $rel:2
failure_behavior: exits 2
rollback_behavior: read-only
promotion_requirement: n/a
demotion_requirement: n/a
authority_mismatch: none
notes: fixture benchmark tool for the RULING 4 proofs
EOF2
}

# PROOF 1 — moving a registered tool between approved roots preserves coverage.
FIX="$WORK/fix"
mkbench "$FIX" "bench/bench-tool.sh"
runfix "$FIX"; RCA=$?
bash "$SCAN" surfaces --repo "$FIX" > "$WORK/surf_a.txt" 2>&1
mkbench "$FIX" "tests/bench-tool.sh"
runfix "$FIX"; RCB=$?
bash "$SCAN" surfaces --repo "$FIX" > "$WORK/surf_b.txt" 2>&1
{ [ "$RCA" = "0" ] && grep -qxF 'bench/bench-tool.sh' "$WORK/surf_a.txt"; } \
  && ok "PROOF 1a: a registered tool under the bench/ root is discovered and reconciles (exit 0)" \
  || { no "PROOF 1a FAILED: the bench-root tool did not reconcile (exit $RCA)"; dump; }
{ [ "$RCB" = "0" ] && grep -qxF 'tests/bench-tool.sh' "$WORK/surf_b.txt"; } \
  && ok "PROOF 1b: the SAME tool moved to another approved root is still discovered and reconciles — coverage travels with the identity, not the directory" \
  || { no "PROOF 1b FAILED: the moved tool lost coverage (exit $RCB)"; dump; }

# PROOF 2 — an UNREGISTERED executable benchmark tool at the repo top level REFUSES.
mkfix "$FIX"
printf '#!/usr/bin/env bash\n[ -f ok ] || { echo "rogue refusal" >&2; exit 2; }\n' > "$FIX/rogue-bench.sh"
chmod +x "$FIX/rogue-bench.sh"
runfix "$FIX"; RC=$?
{ [ "$RC" = "2" ] && saw 'UNREGISTERED rogue-bench.sh'; } \
  && ok "PROOF 2: an unregistered EXECUTABLE benchmark tool shelved at the repo root is REFUSED (exit 2, named) — the 014afb1 root-shelf precedent is closed" \
  || { no "PROOF 2 FAILED: a root-shelved executable tool escaped the census (exit $RC)"; dump; }
# ...and the same file, REGISTERED at the top level, reconciles: registration
# regardless of directory is the remedy, not relocation.
mkbench "$FIX" "rogue-bench.sh"
runfix "$FIX"; RC=$?
[ "$RC" = "0" ] \
  && ok "PROOF 2 (other direction): the same top-level tool, registered, reconciles at exit 0 — the demand is registration, not geography" \
  || { no "PROOF 2 other-direction FAILED: a registered top-level tool still refuses (exit $RC)"; dump; }

# PROOF 3 — substituting an unapproved root refuses.
bash "$SCAN" surfaces --repo "$FIX" --exec-roots "bench evil" > "$WORK/out.txt" 2>&1
RC=$?
{ [ "$RC" = "2" ] && saw 'not an approved executable root'; } \
  && ok "PROOF 3: an undeclared root substituted via --exec-roots is REFUSED, not scanned (exit 2)" \
  || { no "PROOF 3 FAILED: an unapproved root was accepted (exit $RC)"; dump; }
bash "$SCAN" surfaces --repo "$FIX" --exec-roots "tests" > "$WORK/out.txt" 2>&1
[ $? = "0" ] \
  && ok "PROOF 3 (other direction): selecting AMONG the approved roots still works — the override is for fixtures, not for widening" \
  || { no "PROOF 3 other-direction FAILED: a legal subset of approved roots was refused"; dump; }

# PROOF 4 — deleting bench/ from the declared root set kills this test.
bash "$SCAN" patterns > "$WORK/pat.txt" 2>&1
grep -E '^approved exec roots: ' "$WORK/pat.txt" | grep -qE '(^| )bench( |$)' \
  && ok "PROOF 4a: bench is a member of the machine-readable approved-root list (patterns output)" \
  || no "PROOF 4a FAILED: bench is not in the declared executable roots — removing it reopened the geography hole"
bash "$SCAN" surfaces > "$WORK/livesurf.txt" 2>&1
grep -qxF 'bench/run-corpus.sh' "$WORK/livesurf.txt" && grep -qxF 'bench/seed-bench-repo.sh' "$WORK/livesurf.txt" \
  && ok "PROOF 4b: both live bench scripts are DISCOVERED as surfaces — deleting bench from the root set turns this red" \
  || no "PROOF 4b FAILED: the live bench scripts are not discovered"
for bc in bench.run_corpus_gate bench.seed_determinism; do
  [ -n "$(fval "$REG" "$bc" runtime_authority)" ] && [ "$(fval "$REG" "$bc" runtime_authority)" = "gate" ] \
    && ok "PROOF 4c: $bc is registered at authority gate (the two operator-authorized bench registrations)" \
    || no "PROOF 4c FAILED: $bc is not registered at gate"
done

# PROOF 5 — a NON-executable fixture is not accidentally treated as a tool.
mkfix "$FIX"
printf '#!/usr/bin/env bash\n[ -f ok ] || { echo "fixture text" >&2; exit 2; }\n' > "$FIX/sample-fixture.sh"
chmod -x "$FIX/sample-fixture.sh"
runfix "$FIX"; RC=$?
[ "$RC" = "0" ] \
  && ok "PROOF 5: the same refusal-capable bytes WITHOUT the executable bit are a fixture, not a tool — no refusal (exit 0)" \
  || { no "PROOF 5 FAILED: a non-executable top-level fixture was treated as a tool (exit $RC)"; dump; }
bash "$SCAN" surfaces --repo "$FIX" > "$WORK/surf_c.txt" 2>&1
grep -qxF 'sample-fixture.sh' "$WORK/surf_c.txt" \
  && no "PROOF 5: the non-executable fixture appears in the surface list" \
  || ok "PROOF 5: the non-executable fixture is absent from the surface list (the executable bit is the discriminator)"

echo "== 20. This suite is chained, and is not vacuous about itself =="
grep -qF 'chain_suite "tests/control_registry_tests.sh"' "$SRC/tests/build_os_tests.sh" \
  && ok "this suite is chained from tests/build_os_tests.sh (not discoverable-only)" \
  || no "this suite is present but never chained from tests/build_os_tests.sh"
[ "$PASS" -ge 40 ] && ok "this suite ran $PASS assertions (>= 40, not vacuous)" \
                   || no "this suite ran only $PASS assertions"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
