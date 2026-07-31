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
EMP_STATUSES="unvalidated red_driven field_observed calibrated refuted"
AUTHORITIES="none observe advise rank gate"
ROLES="sensor reflex immune memory conscience motor"
MISMATCH_VALUES="none declared"
FIELDS="control class implementation_status empirical_status runtime_authority nervous_system_role inputs output owning_module consuming_policies evidence_refs failure_behavior rollback_behavior promotion_requirement demotion_requirement authority_mismatch notes"
# The licence table, as authority ranks (none=0 observe=1 advise=2 rank=3 gate=4).
lic_of(){ case "$1" in A) echo 4 ;; B) echo 3 ;; C) echo 2 ;; D) echo 1 ;; R) echo 1 ;; *) echo -1 ;; esac; }
rank_of(){ case "$1" in none) echo 0 ;; observe) echo 1 ;; advise) echo 2 ;; rank) echo 3 ;; gate) echo 4 ;; *) echo -1 ;; esac; }
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

echo "== 7. Every evidence reference resolves to a real line of a real file =="
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
            "nervous_system_role" "none < observe < advise < rank < gate"; do
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
tests/build_os_maintenance_tests.sh:193
tests/pilot_kit_tests.sh:340
tests/speed_benchmark_tests.sh:405
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

echo "== 20. This suite is chained, and is not vacuous about itself =="
grep -qF 'chain_suite "tests/control_registry_tests.sh"' "$SRC/tests/build_os_tests.sh" \
  && ok "this suite is chained from tests/build_os_tests.sh (not discoverable-only)" \
  || no "this suite is present but never chained from tests/build_os_tests.sh"
[ "$PASS" -ge 40 ] && ok "this suite ran $PASS assertions (>= 40, not vacuous)" \
                   || no "this suite ran only $PASS assertions"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
