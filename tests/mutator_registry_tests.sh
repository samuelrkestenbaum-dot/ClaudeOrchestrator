#!/usr/bin/env bash
# Build OS — mutator census, stable identity, defect-class recurrence,
# decision telemetry and decision-time signal snapshots.
#
# WHAT THIS PINS, AND WHY EACH PIECE EXISTS.
#
#   1. THE MUTATOR CENSUS. build-os/registry/control_registry.txt classifies
#      controls by the authority their VERDICT exercises. Every entry whose
#      owning_module is one of this repository's mutating modules classified the
#      CHECK and not the WRITE: swarm.disjointness classifies a refusal,
#      metrics.record.schema_invariant classifies a refusal, tools.handoff_lock
#      classifies a fail-closed acquisition. The write actions themselves —
#      rotate-memory.mjs's rename onto the live memory file, swarm-merge.sh's
#      commit, record-packet.sh's append, the identity hook's stamp,
#      specialist-handoff.sh's lock — were registered at NO authority at all.
#      build-os/registry/mutator_registry.txt is the census of those actions.
#
#   2. STABLE IDENTITY. Every object this layer creates carries an immutable,
#      machine-parseable id. LINE NUMBERS MAY REMAIN NAVIGATION HINTS; THEY MAY
#      NOT BE IDENTITY. Seven consecutive packets have shipped a stale `:NNN`,
#      so an id that moves when a file is edited is not an id.
#
#   3. DEFECT-CLASS RECURRENCE. Recurrence was trapped in the prose of
#      build-os/memory/residue.md, where nothing can count it. A class with two
#      occurrences and a class with one look identical to a reader and identical
#      to a grep. The store answers query(defect_class_id) mechanically.
#
#   4. TELEMETRY THAT KEEPS UNKNOWNS UNKNOWN. The failure this exists against is
#      the one that makes a measurement store worse than no store: an unmeasured
#      quantity written as 0, which then averages, sums and ranks as though it
#      were measured. Every quantitative field is `<value>@<provenance>` or the
#      literal `unknown`, and OMISSION YIELDS `unknown` — never 0.
#
#   5. SNAPSHOTS FROZEN AT DECISION TIME. A signal used in a decision is frozen
#      when the decision is taken. A later evaluation that recomputes a historical
#      signal against the current tree is not evaluating the decision that was
#      made; it is evaluating a decision nobody took.
#
# A NOTE ON THIS FILE'S OWN CONSTANTS. It deliberately uses NO `-ge N` / `-gt N`
# floor with N > 1. tests/control_registry_tests.sh section 21 sweeps the tree for
# exactly that shape and requires every match to be registered to
# tests.nonvacuity_minimums; a floor added here without registration turns that
# check red. Where this suite needs a count it asserts an EXACT one, which is
# stronger for a store this layer owns, and uses `-gt 0` / `-ge 1` for vacuity
# guards, both of which section 21 excludes by rule.
#
# No network. Deterministic. Every fixture lives in its own mktemp dir; nothing
# outside $WORK is written. Exits non-zero if any assertion fails.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MUTREG="$SRC/build-os/registry/mutator_registry.txt"
DEFREG="$SRC/build-os/registry/defect_classes.txt"
FINDREG="$SRC/build-os/registry/findings.txt"
BASELINE="$SRC/build-os/registry/governance_baseline.txt"
SCAN="$SRC/build-os/registry/scan-mutators.sh"
REG="$SRC/build-os/registry/control_registry.txt"
CROSS="$SRC/build-os/registry/neurocosmology_crosswalk.txt"
TEL="$SRC/build-os/metrics/decision_telemetry.tsv"
SNAP="$SRC/build-os/metrics/signal_snapshots.tsv"
RECDEC="$SRC/build-os/metrics/record-decision.sh"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# The enums, duplicated here ON PURPOSE. A test that reads its expected values
# out of the artefact it is checking cannot detect the artefact widening its own
# enum — the lesson tests/control_registry_tests.sh paid for.
MUT_FIELDS="control_id actor_or_tool trigger read_scope write_scope mutation_type rollback_behavior required_authority runtime_authority deployment_mode implementation_status empirical_status evidence_refs receipt_behavior"
MUTATION_TYPES="create replace append delete commit lock"
DEPLOY_MODES="shadow human_confirmed bounded_autonomous autonomous"
AUTHORITIES="none observe advise rank gate execute"
PROVENANCE="measured derived reported"
ID_CLASSES="MUT CTRL DEFECT FINDING PACKET DECISION EVIDENCE OUTCOME SIGNAL-SNAPSHOT RANKING OCCURRENCE"
ID_RE='^(MUT|CTRL|DEFECT|FINDING|PACKET|DECISION|EVIDENCE|OUTCOME|SIGNAL-SNAPSHOT|RANKING|OCCURRENCE)-[0-9]{4}(-[a-z0-9][a-z0-9-]*)?$'

# The five mutators the packet brief names. Held here as a literal list so that
# deleting one from the census is caught by this suite rather than by nobody.
BRIEF_FIVE="build-os/maintenance/rotate-memory.mjs build-os/tools/swarm-merge.sh build-os/metrics/record-packet.sh .claude/hooks/build-os-identity.sh build-os/tools/specialist-handoff.sh"

# Stanza helpers, independent of scan-mutators.sh's own parser.
recs(){ awk -v k="$1" -F': ' '$0 ~ "^"k": " {print $2}' "$2"; }
fld(){ # <record-key> <id> <field> <file>
  awk -v k="$1" -v i="$2" -v f="$3" '
    $0 == k": "i {inr=1; next}
    /^$/ {inr=0}
    inr && $0 ~ "^"f": " {sub("^"f": ",""); print; exit}' "$4"
}

echo "== 0. Every artefact this layer is made of exists and is non-empty =="
MISSING=""
for f in "$MUTREG" "$DEFREG" "$FINDREG" "$BASELINE" "$SCAN" "$TEL" "$SNAP" "$RECDEC"; do
  [ -s "$f" ] || MISSING="$MISSING ${f#"$SRC/"}"
done
[ -z "$MISSING" ] && ok "all 8 artefacts present and non-empty" \
                  || no "absent or empty:$MISSING"
[ -x "$SCAN" ] && ok "scan-mutators.sh is executable" || no "scan-mutators.sh is not executable"
[ -x "$RECDEC" ] && ok "record-decision.sh is executable" || no "record-decision.sh is not executable"

echo "== 1. All five known mutators are registered (4.7.1) =="
# The census is reconciled against the BRIEF'S LIST, by actor_or_tool. A census
# that only agrees with itself proves nothing.
NMUT="$(recs mutator "$MUTREG" | grep -c . || true)"
[ "${NMUT:-0}" -gt 0 ] && ok "$NMUT mutator record(s) parsed (not vacuous)" \
                       || no "no mutator records parsed — every check below would pass vacuously"
UNCENSUSED=""
for m in $BRIEF_FIVE; do
  grep -qxF "actor_or_tool: $m" "$MUTREG" || UNCENSUSED="$UNCENSUSED $m"
done
[ -z "$UNCENSUSED" ] \
  && ok "all five mutators named in the brief own a census record" \
  || no "mutator(s) named in the brief but NOT in the census:$UNCENSUSED"

# ...and the census must not be narrower than an independent scan of the tree.
# THE SCAN IS THE ANTI-SHELFWARE HALF: a census that is only ever added to by
# hand describes the system somebody remembered, not the system that runs.
#
# WHAT THE SCAN CANNOT DECIDE, AND HOW THAT IS HANDLED. The pattern is syntactic,
# so it cannot tell a write to a durable store from a write to an `mktemp` path
# that the script's own `trap` removes on exit. One module in this tree is
# exactly that case. It is EXCLUDED BY AN AUDITABLE LIST WITH A STATED REASON —
# the same device tests/control_registry_tests.sh section 21 uses — and the
# reason must be written down in the census where a reviewer reads it, or the
# exclusion itself fails below. An exclusion nobody can audit is how a census
# shrinks quietly.
MUT_EXCL="$WORK/mut_excluded.txt"
cat > "$MUT_EXCL" <<'EOF'
build-os/tools/authority-envelope.sh
build-os/tools/claim-evidence.sh
build-os/tools/mismatch-disposition.sh
EOF
( cd "$SRC" && grep -rlnE 'renameSync|writeFileSync\(|copyFileSync|appendFileSync|git -C "\$[A-Za-z_]+" commit|>>[[:space:]]*"\$[A-Za-z_]+"|mkdir[[:space:]]+"\$[A-Za-z_]+"' \
    build-os/maintenance build-os/tools build-os/metrics .claude/hooks 2>/dev/null \
  | grep -vE '\.test\.mjs$' | sort -u ) > "$WORK/durable_all.txt"
NSCAN_ALL="$(grep -c . "$WORK/durable_all.txt" || true)"
grep -vxF -f "$MUT_EXCL" "$WORK/durable_all.txt" > "$WORK/durable_scan.txt"
NSCAN="$(grep -c . "$WORK/durable_scan.txt" || true)"
[ "${NSCAN:-0}" -gt 0 ] && ok "the independent durable-write scan found $NSCAN module(s) of $NSCAN_ALL matched (not blind)" \
                        || no "the durable-write scan found nothing — it has gone blind"
UNSEEN=""
while IFS= read -r s; do
  [ -n "$s" ] || continue
  grep -qxF "actor_or_tool: $s" "$MUTREG" || UNSEEN="$UNSEEN $s"
done < "$WORK/durable_scan.txt"
[ -z "$UNSEEN" ] \
  && ok "every module the independent scan finds performing a durable write owns a census record" \
  || no "module(s) perform durable writes and are NOT censused:$UNSEEN"
# The exclusion must match something real AND carry its reason in the census.
MEXBAD=0
while IFS= read -r ex; do
  [ -n "$ex" ] || continue
  grep -qxF "$ex" "$WORK/durable_all.txt" || { MEXBAD=$((MEXBAD+1)); echo "      | exclusion matches nothing: $ex"; }
  grep -qF "$ex" "$MUTREG" || { MEXBAD=$((MEXBAD+1)); echo "      | exclusion is not justified in the census: $ex"; }
done < "$MUT_EXCL"
[ "$MEXBAD" -eq 0 ] \
  && ok "every scan exclusion matches a real module AND states its reason in the census" \
  || no "$MEXBAD exclusion problem(s)"

echo "== 2. Every registered mutator has a stable id, and every id is well-formed (4.7.2) =="
BADID=0; NOCTRL=0
while IFS= read -r id; do
  [ -n "$id" ] || continue
  printf '%s\n' "$id" | grep -qE "$ID_RE" || { BADID=$((BADID+1)); echo "      | malformed id: $id"; }
  case "$id" in MUT-*) ;; *) BADID=$((BADID+1)); echo "      | mutator id is not in the MUT namespace: $id" ;; esac
  c="$(fld mutator "$id" control_id "$MUTREG")"
  [ -n "$c" ] || { NOCTRL=$((NOCTRL+1)); echo "      | $id names no control_id"; }
done < <(recs mutator "$MUTREG")
[ "$BADID" -eq 0 ] && ok "every mutator id is a well-formed MUT-* stable id" \
                   || no "$BADID mutator id problem(s)"
[ "$NOCTRL" -eq 0 ] && ok "every mutator record names the control it is classified by" \
                    || no "$NOCTRL mutator record(s) name no control_id"

# Every field of the required record shape is present on every record.
INCOMPLETE=0
while IFS= read -r id; do
  [ -n "$id" ] || continue
  for f in $MUT_FIELDS; do
    v="$(fld mutator "$id" "$f" "$MUTREG")"
    [ -n "$v" ] || { INCOMPLETE=$((INCOMPLETE+1)); echo "      | $id has no \"$f\""; }
  done
done < <(recs mutator "$MUTREG")
[ "$INCOMPLETE" -eq 0 ] && ok "every mutator record carries all 14 fields of the declared shape" \
                        || no "$INCOMPLETE missing field(s)"

# Enums, and the control_id must resolve into the live control registry.
BADENUM=0; DANGLING=0
while IFS= read -r id; do
  [ -n "$id" ] || continue
  mt="$(fld mutator "$id" mutation_type "$MUTREG")"
  dm="$(fld mutator "$id" deployment_mode "$MUTREG")"
  ra="$(fld mutator "$id" required_authority "$MUTREG")"
  rt="$(fld mutator "$id" runtime_authority "$MUTREG")"
  cid="$(fld mutator "$id" control_id "$MUTREG")"
  case " $MUTATION_TYPES " in *" $mt "*) ;; *) BADENUM=$((BADENUM+1)); echo "      | $id mutation_type \"$mt\"" ;; esac
  case " $DEPLOY_MODES "   in *" $dm "*) ;; *) BADENUM=$((BADENUM+1)); echo "      | $id deployment_mode \"$dm\"" ;; esac
  case " $AUTHORITIES "    in *" $ra "*) ;; *) BADENUM=$((BADENUM+1)); echo "      | $id required_authority \"$ra\"" ;; esac
  case " $AUTHORITIES "    in *" $rt "*) ;; *) BADENUM=$((BADENUM+1)); echo "      | $id runtime_authority \"$rt\"" ;; esac
  grep -qxF "control: $cid" "$REG" || { DANGLING=$((DANGLING+1)); echo "      | $id names control_id $cid, which owns no registry entry"; }
  # The copied runtime_authority must equal the live one. The crosswalk keeps the
  # same redundancy for the same reason: where they disagree the registry is
  # right and this file is stale, and a stale copy is how a census drifts.
  live="$(fld control "$cid" runtime_authority "$REG")"
  [ "$rt" = "$live" ] || { BADENUM=$((BADENUM+1)); echo "      | $id copies runtime_authority \"$rt\" but the registry says \"$live\" for $cid"; }
done < <(recs mutator "$MUTREG")
[ "$BADENUM" -eq 0 ] && ok "every mutator's enums are legal and its runtime_authority matches the live registry" \
                     || no "$BADENUM enum/copy problem(s)"
[ "$DANGLING" -eq 0 ] && ok "every mutator's control_id resolves into the control registry" \
                      || no "$DANGLING dangling control_id(s)"

echo "== 3. Each mutator's stated mutation surface is supported by static derivation (4.7.3) =="
# THE CLAIM BEING CHECKED, EXACTLY. A record says `mutation_type: append`. This
# derives from the TREE that at least one line the record cites actually performs
# an append. It does NOT prove the write scope is complete — that is stated as a
# bound rather than implied away — but it makes a record that claims a mutation
# the module cannot perform fail.
#
# `commit`'s family is WIDER THAN `git .*commit`, and the reason is recorded so it
# does not read as a regex fitted to the data. build-os/tools/swarm-merge.sh:587,
# the literal invocation, is ALREADY CLAIMED by swarm.post_merge_verification, and
# control_registry_tests.sh section 22 forbids one line carrying two
# classifications. So the mutator is cited at the flag that enables the commit and
# the branch that decides it happens, and the family accepts those. Freeing :587
# by narrowing the other entry's refs is the technique scan-controls.sh's own
# header names as hole 5, and was not done.
mt_family(){ case "$1" in
  create)  echo 'mkdir|writeFileSync|> *"' ;;
  replace) echo 'renameSync|writeFileSync|copyFileSync|cp |> *"' ;;
  append)  echo '>>|appendFileSync' ;;
  delete)  echo 'rm -|rmSync|unlinkSync|rmdir' ;;
  commit)  echo 'git[[:space:]][^|]*commit|DO_COMMIT|--commit' ;;
  lock)    echo 'mkdir|rmdir' ;;
  esac; }
UNSUPPORTED=0; NREFCHECKED=0
while IFS= read -r id; do
  [ -n "$id" ] || continue
  mt="$(fld mutator "$id" mutation_type "$MUTREG")"
  refs="$(fld mutator "$id" evidence_refs "$MUTREG")"
  fam="$(mt_family "$mt")"
  hit=0
  for ref in $(printf '%s' "$refs" | tr ';' ' '); do
    [ -n "$ref" ] || continue
    rf="${ref%:*}"; rl="${ref##*:}"
    case "$rl" in ''|*[!0-9]*)
      UNSUPPORTED=$((UNSUPPORTED+1)); echo "      | $id cites \"$ref\" with no line number"; continue ;;
    esac
    [ -f "$SRC/$rf" ] || { UNSUPPORTED=$((UNSUPPORTED+1)); echo "      | $id cites $ref, but $rf is not a file"; continue; }
    tot="$(wc -l < "$SRC/$rf" | tr -d ' ')"
    if [ "$rl" -lt 1 ] || [ "$rl" -gt "${tot:-0}" ]; then
      UNSUPPORTED=$((UNSUPPORTED+1)); echo "      | $id cites $ref, past the end of a ${tot:-0}-line file"; continue
    fi
    NREFCHECKED=$((NREFCHECKED+1))
    line="$(sed -n "${rl}p" "$SRC/$rf")"
    printf '%s\n' "$line" | grep -qE "$fam" && hit=1
  done
  [ "$hit" -eq 1 ] || { UNSUPPORTED=$((UNSUPPORTED+1)); echo "      | $id claims mutation_type \"$mt\" but no cited line matches /$fam/"; }
done < <(recs mutator "$MUTREG")
[ "$NREFCHECKED" -gt 0 ] && ok "$NREFCHECKED mutator evidence reference(s) resolved against the tree (not vacuous)" \
                         || no "no mutator evidence refs resolved — the derivation below is meaningless"
[ "$UNSUPPORTED" -eq 0 ] \
  && ok "every mutator's declared mutation_type is derivable from a line it cites" \
  || no "$UNSUPPORTED mutation surface(s) are not supported by any cited line"

echo "== 4. Stable ids survive line movement (4.7.4) =="
# THE DEFECT THIS EXISTS AGAINST is the one seven consecutive packets have hit: a
# reference that is a POSITION. Shifting every line of every store must not
# change one identifier. The shift is applied by PREPENDING comment lines, which
# moves every record without altering any record.
mkdir -p "$WORK/shift/build-os/registry" "$WORK/shift/build-os/metrics"
for f in mutator_registry.txt defect_classes.txt findings.txt governance_baseline.txt control_registry.txt; do
  cp "$SRC/build-os/registry/$f" "$WORK/shift/build-os/registry/$f"
done
IDS_BEFORE="$WORK/ids_before.txt"; IDS_AFTER="$WORK/ids_after.txt"
"$SCAN" ids --repo "$SRC" > "$IDS_BEFORE" 2>"$WORK/ids_before.err"
NIDS="$(grep -c . "$IDS_BEFORE" || true)"
[ "${NIDS:-0}" -gt 0 ] && ok "scan-mutators.sh ids emits $NIDS stable id(s) (not vacuous)" \
                       || { no "scan-mutators.sh ids emitted nothing"; sed 's/^/      | /' "$WORK/ids_before.err"; }
for f in mutator_registry.txt defect_classes.txt findings.txt governance_baseline.txt; do
  { printf '# line-movement fixture: this comment shifts every record below it\n'
    printf '# by two lines, and must change no identifier.\n'
    cat "$WORK/shift/build-os/registry/$f"; } > "$WORK/shift/build-os/registry/$f.new"
  mv "$WORK/shift/build-os/registry/$f.new" "$WORK/shift/build-os/registry/$f"
done
"$SCAN" ids --repo "$WORK/shift" > "$IDS_AFTER" 2>/dev/null
if diff -q "$IDS_BEFORE" "$IDS_AFTER" >/dev/null 2>&1; then
  ok "every stable id is byte-identical after every record moved by two lines"
else
  no "line movement changed the id set — an identifier that moves with the file is a position, not an identity"
  diff "$IDS_BEFORE" "$IDS_AFTER" | head -10 | sed 's/^/      | /'
fi

echo "== 5. Duplicate ids are REFUSED (4.7.5) =="
mkdir -p "$WORK/dup/build-os/registry"
for f in mutator_registry.txt defect_classes.txt findings.txt governance_baseline.txt control_registry.txt; do
  cp "$SRC/build-os/registry/$f" "$WORK/dup/build-os/registry/$f"
done
FIRSTMUT="$(recs mutator "$MUTREG" | head -1)"
# Duplicate one whole record, verbatim. An id that can be claimed twice is not an
# id, and this is the exact shape a copy-paste produces.
awk -v k="mutator: $FIRSTMUT" '
  $0 == k {inr=1}
  inr {buf = buf $0 "\n"}
  inr && /^$/ {inr=0}
  {print}
  END {printf "%s", buf}' "$MUTREG" > "$WORK/dup/build-os/registry/mutator_registry.txt"
if "$SCAN" check --repo "$WORK/dup" >"$WORK/dup.out" 2>&1; then
  no "RED FAILED: a duplicated stable id passed scan-mutators.sh check"
else
  grep -qi "duplicate" "$WORK/dup.out" \
    && ok "RED: a duplicated stable id is refused, and the refusal says 'duplicate'" \
    || { no "the duplicate was refused, but not for being a duplicate"; head -4 "$WORK/dup.out" | sed 's/^/      | /'; }
fi

echo "== 6. Defect-class recurrence is queryable MECHANICALLY (4.7.6) =="
# THE MINIMUM PROOF the brief demands: query(defect_class_id) returns MORE THAN
# ONE historical occurrence for at least one recurrent class. A registry in which
# every class has exactly one occurrence proves the schema and nothing about
# recurrence, which is the only thing the schema exists to measure.
NCLASS="$(recs defect_class "$DEFREG" | grep -c . || true)"
NOCC="$(recs occurrence "$DEFREG" | grep -c . || true)"
[ "${NCLASS:-0}" -gt 0 ] && ok "$NCLASS defect class(es) registered (not vacuous)" || no "no defect classes registered"
[ "${NOCC:-0}" -gt 0 ]   && ok "$NOCC occurrence(s) registered (not vacuous)"     || no "no occurrences registered"

# The twelve classes demonstrated in this session must all be seeded.
SEEDED_MISSING=""
for slug in stale-line-reference stale-remembered-count duplicate-semantic-truth \
            guard-reconciles-labels-not-arguments check-matches-wrong-output \
            unchained-live-verification incomplete-enumeration incomplete-application \
            silently-truncated-help-range same-model-review-correlation \
            undeclared-active-packet transient-evidence-destroyed-on-failure; do
  recs defect_class "$DEFREG" | grep -q -- "-$slug\$" || SEEDED_MISSING="$SEEDED_MISSING $slug"
done
[ -z "$SEEDED_MISSING" ] \
  && ok "all twelve defect classes demonstrated in this session are seeded" \
  || no "defect class(es) named by the brief but not seeded:$SEEDED_MISSING"

# Every occurrence must reference a class that exists, and carry the full shape.
OCC_FIELDS="defect_class_id packet_id detected_stage escaped_stage affected_objects root_cause_class symptom prevented_by could_have_been_prevented_by evidence_refs"
OCCBAD=0
while IFS= read -r oid; do
  [ -n "$oid" ] || continue
  for f in $OCC_FIELDS; do
    v="$(fld occurrence "$oid" "$f" "$DEFREG")"
    [ -n "$v" ] || { OCCBAD=$((OCCBAD+1)); echo "      | $oid has no \"$f\""; }
  done
  dc="$(fld occurrence "$oid" defect_class_id "$DEFREG")"
  grep -qxF "defect_class: $dc" "$DEFREG" || { OCCBAD=$((OCCBAD+1)); echo "      | $oid references unknown class $dc"; }
done < <(recs occurrence "$DEFREG")
[ "$OCCBAD" -eq 0 ] && ok "every occurrence carries all 10 fields and names a registered class" \
                    || no "$OCCBAD occurrence problem(s)"

# THE QUERY ITSELF. Not "the data would support a query" — the query, executed.
RECURRENT=""
while IFS= read -r cid; do
  [ -n "$cid" ] || continue
  n="$("$SCAN" query "$cid" --repo "$SRC" 2>/dev/null | grep -c . || true)"
  # WRITTEN `!= 0 && != 1` RATHER THAN AS A GREATER-THAN-ONE COMPARISON, AND THE
  # REASON IS RECORDED SO IT IS JUDGED IN THE OPEN RATHER THAN DISCOVERED.
  # control_registry_tests.sh section 21 sweeps tests/*.sh for the greater-than
  # and at-least forms with a bound above one, and requires every match to be
  # registered to tests.nonvacuity_minimums — a family of FITTED CONSTANTS,
  # thresholds snapshotted from the tree on the day they were written. This
  # constant is not one: "more than one occurrence" is the DEFINITION of
  # recurrence, not a floor anybody fitted, and registering it would file a
  # definition among the heuristics that can stop a build. The alternative was to
  # add a fourth entry to section 21's exclusion list, which would be exempting a
  # guard to go green. Neither was acceptable, so the comparison is spelled a way
  # that is exactly equivalent and is not the shape that rule is hunting.
  { [ "${n:-0}" != "0" ] && [ "${n:-0}" != "1" ]; } && RECURRENT="$RECURRENT $cid:$n"
done < <(recs defect_class "$DEFREG")
if [ -n "$RECURRENT" ]; then
  ok "query(defect_class_id) returns MORE THAN ONE occurrence for:$RECURRENT"
else
  no "no defect class has more than one queryable occurrence — the store proves a schema, not recurrence"
fi
# A query for a class that does not exist must refuse, not return an empty set
# that reads like "this never happened".
if "$SCAN" query DEFECT-9999-not-a-real-class --repo "$SRC" >/dev/null 2>&1; then
  no "querying an unregistered defect class succeeded — an empty result is indistinguishable from 'never happened'"
else
  ok "querying an unregistered defect class REFUSES rather than returning an empty set"
fi

echo "== 7. Telemetry accepts unknowns WITHOUT converting them to zero (4.7.7) =="
MEASURED_FIELDS="wall_minutes serial_minutes agent_minutes human_attention_minutes model_calls estimated_tokens estimated_cost estimated_energy fix_rounds review_rounds rework_count rollback_count"
cp "$TEL" "$WORK/tel.tsv"
# Record a decision naming NOTHING quantitative. Omission is the common case and
# it is the one that must not silently become 0.
"$RECDEC" record --store "$WORK/tel.tsv" \
  --decision-id DECISION-9001-unknown-probe \
  --decision-time 2026-08-01T00:00:00Z \
  --candidate-ids PACKET-9001-a \
  --selected-candidate-id PACKET-9001-a \
  --selector operator \
  --selection-reason "a probe row for the unknown-preservation check" \
  --expected-outcome "the quantitative fields read back as unknown" \
  --result unknown \
  --durability-status unknown \
  >"$WORK/rec.out" 2>&1 \
  && ok "a decision row with no quantitative values is accepted" \
  || { no "recording a row with omitted quantitative values failed"; head -5 "$WORK/rec.out" | sed 's/^/      | /'; }
ZEROED=""
for f in $MEASURED_FIELDS; do
  v="$("$RECDEC" get DECISION-9001-unknown-probe "$f" --store "$WORK/tel.tsv" 2>/dev/null)"
  [ "$v" = "unknown" ] || ZEROED="$ZEROED $f=$v"
done
[ -z "$ZEROED" ] \
  && ok "all 12 omitted quantitative fields read back as \`unknown\`, none as 0" \
  || no "omitted field(s) did not read back as unknown:$ZEROED"

# A measured ZERO is a real measurement and must remain distinguishable from an
# unknown. This is the other half, and without it the check above is satisfiable
# by a store that simply cannot represent 0.
"$RECDEC" record --store "$WORK/tel.tsv" \
  --decision-id DECISION-9002-measured-zero \
  --decision-time 2026-08-01T00:00:00Z \
  --candidate-ids PACKET-9002-a \
  --selected-candidate-id PACKET-9002-a \
  --selector operator \
  --selection-reason "a probe row proving measured zero survives" \
  --expected-outcome "fix_rounds reads back as a MEASURED zero" \
  --fix-rounds 0@measured \
  --result unknown --durability-status unknown >/dev/null 2>&1
Z="$("$RECDEC" get DECISION-9002-measured-zero fix_rounds --store "$WORK/tel.tsv" 2>/dev/null)"
[ "$Z" = "0@measured" ] \
  && ok "a MEASURED zero reads back as \`0@measured\` — distinguishable from unknown" \
  || no "a measured zero read back as \"$Z\""

# A bare number with no provenance is refused: it is exactly the value whose
# origin nobody can later reconstruct.
if "$RECDEC" record --store "$WORK/tel.tsv" \
     --decision-id DECISION-9003-bare --decision-time 2026-08-01T00:00:00Z \
     --candidate-ids PACKET-9003-a --selected-candidate-id PACKET-9003-a \
     --selector operator --selection-reason "a probe row that must be refused" \
     --expected-outcome "refusal" --wall-minutes 42 \
     --result unknown --durability-status unknown >"$WORK/bare.out" 2>&1; then
  no "RED FAILED: a quantitative value with no provenance was accepted"
else
  ok "RED: a quantitative value with no \`@measured|derived|reported\` provenance is refused"
fi
# ...and the aggregate must not sum unknowns as zero.
"$RECDEC" report --store "$WORK/tel.tsv" > "$WORK/report.out" 2>&1
grep -qE "unknown" "$WORK/report.out" \
  && ok "the telemetry report names its unknowns rather than aggregating them away" \
  || { no "the report does not distinguish unknown values"; head -6 "$WORK/report.out" | sed 's/^/      | /'; }

# The live store must itself validate, and every provenance token must be legal.
"$RECDEC" validate --store "$TEL" --snapshots "$SNAP" >"$WORK/val.out" 2>&1 \
  && ok "the live decision-telemetry store validates" \
  || { no "the live decision-telemetry store does not validate"; head -8 "$WORK/val.out" | sed 's/^/      | /'; }
BADPROV=0
while IFS= read -r tok; do
  [ -n "$tok" ] || continue
  case " $PROVENANCE " in *" $tok "*) ;; *) BADPROV=$((BADPROV+1)); echo "      | illegal provenance: $tok" ;; esac
done < <(grep -o '@[a-z]*' "$TEL" | sed 's/^@//' | sort -u)
[ "$BADPROV" -eq 0 ] && ok "every provenance token in the live store is one of measured/derived/reported" \
                     || no "$BADPROV illegal provenance token(s)"

echo "== 8. Signal snapshots are immutable (4.7.8) =="
NSNAP="$(grep -vc '^#' "$SNAP" 2>/dev/null || true)"
[ "${NSNAP:-0}" -gt 0 ] && ok "$NSNAP snapshot line(s) present (not vacuous)" || no "the snapshot store is empty"
"$RECDEC" snapshot-verify --snapshots "$SNAP" >"$WORK/sv.out" 2>&1 \
  && ok "the live snapshot chain verifies" \
  || { no "the live snapshot chain does not verify"; head -8 "$WORK/sv.out" | sed 's/^/      | /'; }
# Tamper with a recorded signal VALUE and leave everything else alone. This is the
# edit somebody makes when a historical number turns out to be inconvenient.
sed '0,/^SIGNAL-SNAPSHOT-/{s/^\(SIGNAL-SNAPSHOT-[^\t]*\t[^\t]*\t[^\t]*\t[^\t]*\t[^\t]*\t[^\t]*\t\)[^\t]*/\1999999/}' \
  "$SNAP" > "$WORK/snap_tampered.tsv"
if diff -q "$SNAP" "$WORK/snap_tampered.tsv" >/dev/null 2>&1; then
  no "the tamper fixture changed nothing — the check below would pass vacuously"
else
  ok "the tamper fixture altered a recorded signal_value (the check below is live)"
fi
if "$RECDEC" snapshot-verify --snapshots "$WORK/snap_tampered.tsv" >"$WORK/svt.out" 2>&1; then
  no "RED FAILED: a retroactively edited signal_value still verified"
else
  ok "RED: a retroactively edited signal_value breaks the digest chain and is refused"
fi
# Appending is legal; rewriting history is not. A store that refused appends
# would be immutable by being useless.
cp "$SNAP" "$WORK/snap_append.tsv"
"$RECDEC" snapshot --snapshots "$WORK/snap_append.tsv" \
  --snapshot-id SIGNAL-SNAPSHOT-9001-probe --decision-id DECISION-9001-unknown-probe \
  --captured-at 2026-08-01T00:00:00Z --repository-commit 0000000 \
  --candidate-id PACKET-9001-a --signal-name dependency_unlock_count --signal-value 3 \
  --derivation-version v1 --source-object-versions "MUT-0001@probe" \
  --evidence-refs "build-os/registry/mutator_registry.txt" >/dev/null 2>&1
"$RECDEC" snapshot-verify --snapshots "$WORK/snap_append.tsv" >/dev/null 2>&1 \
  && ok "an APPENDED snapshot still verifies — immutability is not refusal to grow" \
  || no "appending a snapshot broke the chain"

echo "== 9. Changing the live registry after a snapshot does not change the snapshot (4.7.9) =="
# THE FAILURE THIS EXISTS AGAINST: an evaluation that recomputes a historical
# signal against the CURRENT tree, and therefore scores a decision nobody took.
SNAPID="$(awk -F'\t' '!/^#/ && NF>1 {print $1; exit}' "$SNAP")"
SIGBEFORE="$("$RECDEC" get-snapshot "$SNAPID" signal_value --snapshots "$SNAP" 2>/dev/null)"
[ -n "$SIGBEFORE" ] && ok "a historical snapshot's frozen signal_value is readable ($SNAPID = $SIGBEFORE)" \
                    || no "could not read a historical snapshot value — the check below is meaningless"
mkdir -p "$WORK/moved/build-os/registry" "$WORK/moved/build-os/metrics"
for f in mutator_registry.txt defect_classes.txt findings.txt governance_baseline.txt control_registry.txt; do
  cp "$SRC/build-os/registry/$f" "$WORK/moved/build-os/registry/$f"
done
cp "$SNAP" "$WORK/moved/build-os/metrics/signal_snapshots.tsv"
cp "$TEL" "$WORK/moved/build-os/metrics/decision_telemetry.tsv"
# Materially change the live registry the signal was derived from: add a whole
# new mutator record. If any snapshot value tracked the live tree, this moves it.
{ cat "$SRC/build-os/registry/mutator_registry.txt"
  printf '\nmutator: MUT-9099-probe-record\n'
  printf 'control_id: probe.only\nactor_or_tool: probe\ntrigger: probe\n'
  printf 'read_scope: probe\nwrite_scope: probe\nmutation_type: append\n'
  printf 'rollback_behavior: probe\nrequired_authority: execute\nruntime_authority: execute\n'
  printf 'deployment_mode: autonomous\nimplementation_status: specified\nempirical_status: unvalidated\n'
  printf 'evidence_refs: probe:1\nreceipt_behavior: probe\n'
} > "$WORK/moved/build-os/registry/mutator_registry.txt"
SIGAFTER="$("$RECDEC" get-snapshot "$SNAPID" signal_value --snapshots "$WORK/moved/build-os/metrics/signal_snapshots.tsv" 2>/dev/null)"
[ "$SIGBEFORE" = "$SIGAFTER" ] \
  && ok "the historical signal_value is unchanged after the live registry gained a record ($SIGBEFORE)" \
  || no "the historical signal_value moved with the live tree: $SIGBEFORE -> $SIGAFTER"
"$RECDEC" snapshot-verify --snapshots "$WORK/moved/build-os/metrics/signal_snapshots.tsv" >/dev/null 2>&1 \
  && ok "...and the historical chain still verifies against the changed tree" \
  || no "the historical chain stopped verifying merely because the live tree changed"
# Every snapshot must name the commit it was captured at, or "frozen" is a claim
# with no referent.
NOCOMMIT="$(awk -F'\t' '!/^#/ && NF>1 && ($4=="" || $4=="-") {print $1}' "$SNAP" | grep -c . || true)"
[ "${NOCOMMIT:-0}" -eq 0 ] && ok "every snapshot names the repository_commit it was frozen at" \
                           || no "$NOCOMMIT snapshot(s) name no repository_commit"

echo "== 10. Generated projections cannot silently substitute line numbers for identity (4.7.10) =="
# A PROJECTION IS WHERE IDENTITY GETS LOST. The census is read as a table far more
# often than as a stanza file, and a table that keys its rows on `file:line` looks
# right, reads right, and is a position again.
"$SCAN" project --repo "$SRC" > "$WORK/proj.txt" 2>"$WORK/proj.err"
NPROJ="$(grep -c . "$WORK/proj.txt" || true)"
[ "${NPROJ:-0}" -gt 0 ] && ok "the generated projection emits $NPROJ line(s) (not vacuous)" \
                        || { no "the projection emitted nothing"; sed 's/^/      | /' "$WORK/proj.err"; }
# Every censused mutator must appear in the projection BY ITS STABLE ID.
PROJ_MISSING=""
while IFS= read -r id; do
  [ -n "$id" ] || continue
  grep -qF "$id" "$WORK/proj.txt" || PROJ_MISSING="$PROJ_MISSING $id"
done < <(recs mutator "$MUTREG")
[ -z "$PROJ_MISSING" ] \
  && ok "every mutator appears in the projection under its stable id" \
  || no "mutator(s) projected without their stable id:$PROJ_MISSING"
# ...and the projection's IDENTITY COLUMN must never hold a path:line.
BADCOL="$(awk -F'|' 'NF>2 {gsub(/^[ \t]+|[ \t]+$/,"",$2); if ($2 ~ /:[0-9]+/) print $2}' "$WORK/proj.txt" | grep -c . || true)"
[ "${BADCOL:-0}" -eq 0 ] \
  && ok "no projected identity column holds a path:line — line numbers stay navigation hints" \
  || no "$BADCOL projected row(s) use a path:line as identity"
# The tool must REFUSE to project a store whose identity is a line number, rather
# than projecting it prettily.
mkdir -p "$WORK/badproj/build-os/registry"
for f in mutator_registry.txt defect_classes.txt findings.txt governance_baseline.txt control_registry.txt; do
  cp "$SRC/build-os/registry/$f" "$WORK/badproj/build-os/registry/$f"
done
sed "s/^mutator: MUT-0001/mutator: build-os\/maintenance\/rotate-memory.mjs:1006/" \
  "$MUTREG" > "$WORK/badproj/build-os/registry/mutator_registry.txt"
if "$SCAN" project --repo "$WORK/badproj" >/dev/null 2>&1; then
  no "RED FAILED: a store keyed on a path:line projected without complaint"
else
  ok "RED: a store whose identity is a path:line is REFUSED, not projected"
fi

echo "== 11. Existing controls and findings are NOT silently re-authorised (4.7.11) =="
# THE RULE THIS ENFORCES. Registering a NEW control is authorised work. Moving an
# EXISTING control's class or authority is a governance act belonging to the
# operator. The baseline makes the difference mechanical: a new control is simply
# absent from it, while changing an old one costs an edit to an artefact a
# reviewer reads in the diff.
NBASE="$(grep -vc '^#' "$BASELINE" 2>/dev/null | tr -d ' ' || true)"
NBASE="$(awk '!/^#/ && NF>0' "$BASELINE" | grep -c . || true)"
[ "${NBASE:-0}" -gt 0 ] && ok "the governance baseline pins $NBASE control(s) (not vacuous)" \
                        || no "the governance baseline is empty — it would certify every re-authorisation at once"
MOVED=0; GONE=0
while IFS=$'\t' read -r bid bcls baut bmm; do
  [ -n "$bid" ] || continue
  case "$bid" in '#'*) continue ;; esac
  if ! grep -qxF "control: $bid" "$REG"; then
    GONE=$((GONE+1)); echo "      | $bid is pinned by the baseline but no longer exists in the registry"; continue
  fi
  lcls="$(fld control "$bid" class "$REG")"
  laut="$(fld control "$bid" runtime_authority "$REG")"
  lmm="$(fld control "$bid" authority_mismatch "$REG")"
  [ "$lcls" = "$bcls" ] || { MOVED=$((MOVED+1)); echo "      | $bid class $bcls -> $lcls"; }
  [ "$laut" = "$baut" ] || { MOVED=$((MOVED+1)); echo "      | $bid runtime_authority $baut -> $laut"; }
  [ "$lmm"  = "$bmm"  ] || { MOVED=$((MOVED+1)); echo "      | $bid authority_mismatch $bmm -> $lmm"; }
done < <(awk '!/^#/ && NF>0' "$BASELINE")
[ "$GONE" -eq 0 ]  && ok "every baselined control still exists" || no "$GONE baselined control(s) vanished"
[ "$MOVED" -eq 0 ] && ok "no baselined control changed class, runtime_authority or authority_mismatch" \
                   || no "$MOVED governance field(s) moved on pre-existing control(s) — that is a re-authorisation"

# THE OPEN FINDINGS ARE NOT SILENTLY DISCHARGED EITHER. A finding that records
# "this control sits at X while its behaviour requires Y" is falsified the moment
# somebody moves it to Y and leaves the finding standing — or "fixes" the finding
# by deleting it. Both are caught: the subject's observed state must still match
# what the finding says it observed.
NFIND="$(recs finding "$FINDREG" | grep -c . || true)"
[ "${NFIND:-0}" -gt 0 ] && ok "$NFIND finding(s) registered (not vacuous)" || no "no findings registered"
FINDBAD=0; FINDFIELDS="subject subject_kind observed_authority required_authority remedy remedy_applied authority_to_apply evidence_refs"
while IFS= read -r fid; do
  [ -n "$fid" ] || continue
  printf '%s\n' "$fid" | grep -qE "$ID_RE" || { FINDBAD=$((FINDBAD+1)); echo "      | malformed finding id: $fid"; }
  for f in $FINDFIELDS; do
    v="$(fld finding "$fid" "$f" "$FINDREG")"
    [ -n "$v" ] || { FINDBAD=$((FINDBAD+1)); echo "      | $fid has no \"$f\""; }
  done
  applied="$(fld finding "$fid" remedy_applied "$FINDREG")"
  subj="$(fld finding "$fid" subject "$FINDREG")"
  obs="$(fld finding "$fid" observed_authority "$FINDREG")"
  auth="$(fld finding "$fid" authority_to_apply "$FINDREG")"
  [ "$auth" = "operator" ] || { FINDBAD=$((FINDBAD+1)); echo "      | $fid claims authority_to_apply \"$auth\"; a re-authorisation is the operator's"; }
  if [ "$applied" = "no" ]; then
    # The subject may be a control or a censused mutator; each is read from the
    # store that owns it. A finding naming neither is itself a defect — an
    # accusation with no subject cannot be discharged OR sustained.
    case "$(fld finding "$fid" subject_kind "$FINDREG")" in
      control) live="$(fld control "$subj" runtime_authority "$REG")" ;;
      mutator) live="$(fld mutator "$subj" runtime_authority "$MUTREG")" ;;
      *)       live=""; FINDBAD=$((FINDBAD+1)); echo "      | $fid declares no legal subject_kind" ;;
    esac
    [ "$live" = "$obs" ] || { FINDBAD=$((FINDBAD+1)); echo "      | $fid observed $subj at \"$obs\" and remedy_applied: no, but the live store now says \"$live\""; }
  fi
done < <(recs finding "$FINDREG")
[ "$FINDBAD" -eq 0 ] \
  && ok "every open finding still describes its subject's actual state, and names the operator as the authority" \
  || no "$FINDBAD finding problem(s)"
# The specific one the brief asked about, named rather than left to the loop.
MSR="$(fld control maint.managed_set_replacement runtime_authority "$REG")"
[ "$MSR" = "advise" ] \
  && ok "maint.managed_set_replacement is STILL at \`advise\` — examined, recorded as a finding, and not re-authorised here" \
  || no "maint.managed_set_replacement moved to \"$MSR\"; this packet was licensed to register, not to re-authorise"

echo "== 12. The live stores reconcile, and this suite is chained (4.7.12) =="
"$SCAN" check --repo "$SRC" >"$WORK/check.out" 2>&1 \
  && ok "scan-mutators.sh check reconciles the live stores (exit 0)" \
  || { no "scan-mutators.sh check REFUSED against the live tree"; head -12 "$WORK/check.out" | sed 's/^/      | /'; }
# Every new control this packet registered must own a crosswalk binding — the
# anti-omission guard is in another suite, but a census that fails it fails late.
UNBOUND=""
while IFS= read -r id; do
  [ -n "$id" ] || continue
  cid="$(fld mutator "$id" control_id "$MUTREG")"
  grep -qxF "control: $cid" "$CROSS" || UNBOUND="$UNBOUND $cid"
done < <(recs mutator "$MUTREG")
[ -z "$UNBOUND" ] && ok "every censused mutator's control owns a crosswalk binding" \
                  || no "control(s) censused but unbound in the crosswalk:$UNBOUND"
grep -qF 'chain_suite "tests/mutator_registry_tests.sh"' "$SRC/tests/build_os_tests.sh" \
  && ok "this suite is chained into tests/build_os_tests.sh (not discoverable-only)" \
  || no "this suite is not chained — it would run only for whoever knew it existed"

echo "== 13. S1 — an ordering comes out, it refuses to rank itself, and it dispatches nothing (4.7.13) =="
# THE FIRST EXECUTIVE COMPONENT IN THE CENSUS. Everything above this section
# prevents a bad action. This one forms an explicit, inspectable PREFERENCE among
# several permissible good actions, and every assertion here exists because a
# preference that cannot be inspected, cannot be reproduced, or can be pointed at
# its own promotion is worse than no preference at all.
#
# WHAT IS ASSERTED AGAINST THE LIVE STORES, NOT A FIXTURE: the ordering over the
# real recorded decision, the visibility of every candidate including the ones it
# ranked last and the ones it refused, and `rank_of_selected` — the one number
# that makes S1 falsifiable, because without it S1 can emit orderings forever and
# never be wrong about anything.
#
# WHAT IS DRIVEN RED ON FIXTURES: the self-amendment guard in BOTH directions (a
# candidate that would edit S1 is refused; its neighbour, which would not, is
# ranked), the identity binding between a snapshot and the decision it claims,
# and the refusal to rank against a broken chain. A guard observed only passing
# is a guard nobody has tested, and a guard tested only against its author's own
# positive case is fitted to it.
S1="$SRC/build-os/metrics/rank-candidates.sh"
S1DEC="DECISION-0010-p4-s1-shadow-ranker"
[ -s "$S1" ] && ok "build-os/metrics/rank-candidates.sh exists and is non-empty" \
             || no "S1 is absent — there is no ranker"
[ -x "$S1" ] && ok "S1 is executable" || no "S1 is not executable"

# --- it is a REGISTERED control, at the authority the composition produces ----
S1CTRL="ranker.s1_shadow_ordering"
grep -qxF "control: $S1CTRL" "$REG" \
  && ok "S1 owns a census entry ($S1CTRL) — it is not an unregistered control surface" \
  || no "S1 is not registered in control_registry.txt"
S1DECL=""
for pair in class:C empirical_status:untested runtime_authority:observe nervous_system_role:conscience; do
  f="${pair%%:*}"; want="${pair##*:}"
  got="$(fld control "$S1CTRL" "$f" "$REG")"
  [ "$got" = "$want" ] || S1DECL="$S1DECL $f=$got(want $want)"
done
[ -z "$S1DECL" ] \
  && ok "S1 is declared class C / untested / observe — MIN(advise, observe, execute) = observe, and it is registered at exactly that" \
  || no "S1's declaration does not compose to observe:$S1DECL"
grep -qxF "control: $S1CTRL" "$CROSS" \
  && ok "S1's control owns a crosswalk binding — the first control bound to goal_ecology" \
  || no "S1 is registered but unbound in the crosswalk"

# --- IT PRODUCES AN ORDERING OVER THE REAL, LIVE, FROZEN CANDIDATE SET --------
"$S1" rank --decision-id "$S1DEC" > "$WORK/s1.out" 2>&1
S1EXIT=$?
[ "$S1EXIT" -eq 0 ] \
  && ok "S1 ranks the live decision $S1DEC at exit 0" \
  || { no "S1 refused the live decision (exit $S1EXIT)"; head -12 "$WORK/s1.out" | sed 's/^/      | /'; }

# EVERY CANDIDATE IS STILL VISIBLE — derived from the store, never from a literal
# list in this file, so a candidate deleted from the decision row cannot make
# this assertion pass by shrinking what it checks.
S1CANDS="$("$RECDEC" get "$S1DEC" candidate_ids --store "$TEL" 2>/dev/null | tr ';' '\n' | grep -c . || true)"
[ "${S1CANDS:-0}" -gt 0 ] \
  && ok "$S1CANDS candidate(s) are recorded for $S1DEC — the visibility check below is not vacuous" \
  || no "the decision names no candidates; every check below would pass vacuously"
INVIS=""
while IFS= read -r c; do
  [ -n "$c" ] || continue
  grep -qF "$c" "$WORK/s1.out" || INVIS="$INVIS $c"
done < <("$RECDEC" get "$S1DEC" candidate_ids --store "$TEL" 2>/dev/null | tr ';' '\n')
[ -z "$INVIS" ] \
  && ok "every one of the $S1CANDS candidates appears in the output — including the last-ranked and the refused; nothing is filtered out of the record" \
  || no "candidate(s) vanished from S1's output:$INVIS"

# `rank_of_selected` — the falsifiability hook. Its VALUE is not asserted here
# (that would fit the suite to today's answer); its PRESENCE and its AGREEMENT
# with the ordering are.
grep -q '^rank_of_selected: ' "$WORK/s1.out" \
  && ok "S1 reports rank_of_selected — where the human's actual pick landed in its ordering" \
  || no "S1 reports no rank_of_selected, so no ordering it ever emits can be wrong about anything"
S1SEL="$("$RECDEC" get "$S1DEC" selected_candidate_id --store "$TEL" 2>/dev/null)"
ROS="$(awk '/^rank_of_selected: /{print $2; exit}' "$WORK/s1.out")"
SELRANK="$(awk -v c="$S1SEL" '$1=="rank" && $3==c {print $2; exit}' "$WORK/s1.out")"
{ [ -n "$ROS" ] && [ "$ROS" = "$SELRANK" ]; } \
  && ok "rank_of_selected ($ROS) is the position the ordering actually gives $S1SEL — the number is read off the ordering, not asserted beside it" \
  || no "rank_of_selected is \"$ROS\" but the ordering places $S1SEL at \"$SELRANK\""

# --- GUARD 1, ON THE LIVE SET, IN BOTH DIRECTIONS ----------------------------
NEXCL="$(grep -c '^excluded ' "$WORK/s1.out" || true)"; NEXCL="${NEXCL:-0}"
[ "$NEXCL" -gt 0 ] \
  && ok "$NEXCL live candidate(s) are REFUSED by the self-amendment guard — the refusal is visible in the output, not a silent skip" \
  || no "no live candidate is excluded, so the self-amendment guard has nothing to bite on here"
NRANKED="$(grep -c '^rank ' "$WORK/s1.out" || true)"; NRANKED="${NRANKED:-0}"
[ "$NRANKED" -gt 0 ] \
  && ok "$NRANKED candidate(s) are ranked alongside them — the guard discriminates rather than refusing the whole set" \
  || no "the guard excluded everything; a predicate that refuses every subject discriminates nothing"
EXCLNOREASON=0
while IFS= read -r l; do
  case "$l" in *' reason='*) ;; *) EXCLNOREASON=$((EXCLNOREASON+1)) ;; esac
done < <(grep '^excluded ' "$WORK/s1.out")
[ "$EXCLNOREASON" -eq 0 ] \
  && ok "every exclusion carries its reason — an exclusion nobody can audit is a silent one" \
  || no "$EXCLNOREASON exclusion(s) name no reason"

# --- GUARD 2 — THE DECOMPOSITION, NOT JUST THE TOTAL -------------------------
# A total score is not transparency. For every ranked candidate the output must
# say what each signal contributed to its position, or a reader cannot see why A
# outranked B.
NODECOMP=""
while IFS= read -r c; do
  [ -n "$c" ] || continue
  awk -v c="$c" '$1=="contribution" && $2==c {f=1} END{exit !f}' "$WORK/s1.out" \
    || NODECOMP="$NODECOMP $c"
done < <(awk '$1=="rank"{print $3}' "$WORK/s1.out")
[ -z "$NODECOMP" ] \
  && ok "every ranked candidate publishes a per-signal contribution — the decomposition, not just the value" \
  || no "candidate(s) carry a total with no decomposition:$NODECOMP"

# --- MISSING SIGNALS STAY EXPLICITLY MISSING ---------------------------------
grep -q '^signal .* MISSING' "$WORK/s1.out" \
  && ok "at least one declared signal is reported MISSING for this decision rather than defaulted or dropped" \
  || no "no signal is named as missing; a defaulted signal is the untested-missing-from-EVIDENCE_AXIS defect again"
grep -q '^signal .* NEVER-COLLECTED' "$WORK/s1.out" \
  && ok "the signals this repository has never collected at all are named as absent, not imputed" \
  || no "S1 does not name the signals it lacks"
grep -q '^signal .* UNINTERPRETED' "$WORK/s1.out" \
  && ok "a frozen signal whose DIRECTION has never been established is named uninterpreted rather than guessed into an ordering" \
  || no "S1 silently interprets every signal it finds"
MISSCORED=0
while IFS= read -r s; do
  [ -n "$s" ] || continue
  awk -v s="$s" '$1=="contribution" && $3==s {f=1} END{exit !f}' "$WORK/s1.out" && MISSCORED=$((MISSCORED+1))
done < <(awk '$1=="signal" && ($3=="MISSING" || $3=="NEVER-COLLECTED" || $3=="UNINTERPRETED"){print $2}' "$WORK/s1.out")
[ "$MISSCORED" -eq 0 ] \
  && ok "no missing, never-collected or uninterpreted signal contributes to any candidate's position" \
  || no "$MISSCORED signal(s) are declared absent and scored anyway"

# --- ZERO DISPATCH AUTHORITY, MEASURED RATHER THAN ASSERTED ------------------
hash_of(){ if command -v sha256sum >/dev/null 2>&1; then sha256sum; else shasum -a 256; fi; }
BEFORE="$(cat "$TEL" "$SNAP" | hash_of)"
"$S1" rank --decision-id "$S1DEC" >/dev/null 2>&1
AFTER="$(cat "$TEL" "$SNAP" | hash_of)"
[ "$BEFORE" = "$AFTER" ] \
  && ok "ranking leaves both live stores byte-identical — S1 emits an ordering and acts on nothing" \
  || no "a rank run MUTATED a store; S1 has dispatch authority it must not have"

# --- REPRODUCIBILITY: THE ORDERING IS IMMUTABLE BECAUSE ITS INPUTS ARE --------
"$S1" rank --decision-id "$S1DEC" > "$WORK/s1b.out" 2>&1
cmp -s "$WORK/s1.out" "$WORK/s1b.out" \
  && ok "two runs over the same frozen inputs produce byte-identical output — the ordering is a function of the chain, not of the tree" \
  || no "S1's output is not reproducible"
grep -q '^ranking_digest: ' "$WORK/s1.out" \
  && ok "the ordering carries a digest over the rule, the inputs and the result, so a reader can bind a quoted ordering to the inputs it came from" \
  || no "the ordering carries no digest"

# --- RED DRIVES --------------------------------------------------------------
# The fixtures are built with the REAL recorder, so a fixture that the live tool
# would refuse cannot be smuggled in by hand-writing a row.
mks1(){ # <dir> <surface-arm-1> [omit-surface] [surface-arm-2] — a two-candidate decision
  local d="$1"; mkdir -p "$d"
  "$RECDEC" record --store "$d/tel.tsv" \
    --decision-id DECISION-9101-s1-fixture --decision-time 2026-08-01T00:00:00Z \
    --candidate-ids "PACKET-9101-touches-s1;PACKET-9101-touches-nothing" \
    --selected-candidate-id PACKET-9101-touches-nothing --selector operator \
    --selection-reason "a fixture for the self-amendment guard" \
    --expected-outcome "one arm is refused and the other is ranked" \
    --result unknown --durability-status unknown >/dev/null 2>&1
  local i=1 c v
  for c in PACKET-9101-touches-s1 PACKET-9101-touches-nothing; do
    case "$c" in
      *touches-s1) v="$2" ;;
      *)           v="${4:-build-os/memory/residue.md}" ;;
    esac
    # `omit-surface` builds the fixture WITHOUT the screening signal rather than
    # deleting the row afterwards — a deletion would break the digest chain and
    # the run would refuse for that reason instead, proving nothing about the
    # guard.
    if [ "${3:-}" != "omit-surface" ]; then
      "$RECDEC" snapshot --snapshots "$d/snap.tsv" \
        --snapshot-id "SIGNAL-SNAPSHOT-910$i-surface" --decision-id DECISION-9101-s1-fixture \
        --captured-at 2026-08-01T00:00:00Z --repository-commit fixture \
        --candidate-id "$c" --signal-name candidate_write_surface --signal-value "$v" \
        --derivation-version fixture --source-object-versions fixture --evidence-refs fixture >/dev/null 2>&1
    fi
    i=$((i+1))
    "$RECDEC" snapshot --snapshots "$d/snap.tsv" \
      --snapshot-id "SIGNAL-SNAPSHOT-910$i-items" --decision-id DECISION-9101-s1-fixture \
      --captured-at 2026-08-01T00:00:00Z --repository-commit fixture \
      --candidate-id "$c" --signal-name residue_items_closed --signal-value 1 \
      --derivation-version fixture --source-object-versions fixture --evidence-refs fixture >/dev/null 2>&1
    i=$((i+1))
  done
}
# R1: the candidate that would edit S1's own code is REFUSED.
mks1 "$WORK/r1s1" "build-os/metrics/rank-candidates.sh"
"$S1" rank --decision-id DECISION-9101-s1-fixture --store "$WORK/r1s1/tel.tsv" --snapshots "$WORK/r1s1/snap.tsv" \
  > "$WORK/r1s1.out" 2>&1
grep -qE '^excluded PACKET-9101-touches-s1 .*self_amendment' "$WORK/r1s1.out" \
  && ok "RED: a candidate whose write surface names S1's own code is REFUSED, by name, with the reason self_amendment" \
  || { no "RED FAILED: a candidate that would rewrite S1 was not excluded"; head -8 "$WORK/r1s1.out" | sed 's/^/      | /'; }
awk '$1=="rank" && $3=="PACKET-9101-touches-nothing"{f=1} END{exit !f}' "$WORK/r1s1.out" \
  && ok "...and its neighbour, which touches no protected object, is RANKED in the same run — the predicate discriminates" \
  || no "the guard refused the whole fixture; it is not a predicate, it is a wall"
grep -qF 'PACKET-9101-touches-s1' "$WORK/r1s1.out" \
  && ok "the refused candidate is still PRESENT in the output — refused is recorded, never omitted" \
  || no "the refused candidate was dropped from the record"
# R2: the same shape pointed at the promotion machinery rather than at S1's code.
mks1 "$WORK/r2s1" "build-os/tools/evidence-policy.sh"
"$S1" rank --decision-id DECISION-9101-s1-fixture --store "$WORK/r2s1/tel.tsv" --snapshots "$WORK/r2s1/snap.tsv" \
  > "$WORK/r2s1.out" 2>&1
grep -qE '^excluded PACKET-9101-touches-s1 .*self_amendment' "$WORK/r2s1.out" \
  && ok "RED: a candidate that would edit the MECHANISM GOVERNING S1'S PROMOTION is refused too — the guard is the general form, not a filename check" \
  || no "RED FAILED: a candidate rewriting the licence composition was ranked"
# R3: a candidate with NO frozen write surface cannot be screened, and an
# unscreenable candidate is refused rather than assumed innocent.
mks1 "$WORK/r3s1" "build-os/memory/residue.md" omit-surface
"$S1" rank --decision-id DECISION-9101-s1-fixture --store "$WORK/r3s1/tel.tsv" --snapshots "$WORK/r3s1/snap.tsv" \
  > "$WORK/r3s1.out" 2>&1
grep -q 'guard1_unscreenable' "$WORK/r3s1.out" \
  && ok "RED: a candidate carrying no frozen write surface is refused as UNSCREENABLE — the guard fails closed rather than assuming innocence" \
  || { no "RED FAILED: an unscreenable candidate was ranked"; head -8 "$WORK/r3s1.out" | sed 's/^/      | /'; }
# R4: RESOLVABILITY IS NOT IDENTITY. A snapshot that parses perfectly, and is
# chained perfectly, but claims a candidate the decision never named.
mks1 "$WORK/r4s1" "build-os/memory/residue.md"
"$RECDEC" snapshot --snapshots "$WORK/r4s1/snap.tsv" \
  --snapshot-id SIGNAL-SNAPSHOT-9109-orphan --decision-id DECISION-9101-s1-fixture \
  --captured-at 2026-08-01T00:00:00Z --repository-commit fixture \
  --candidate-id PACKET-9199-never-a-candidate --signal-name residue_items_closed --signal-value 99 \
  --derivation-version fixture --source-object-versions fixture --evidence-refs fixture >/dev/null 2>&1
if "$S1" rank --decision-id DECISION-9101-s1-fixture --store "$WORK/r4s1/tel.tsv" --snapshots "$WORK/r4s1/snap.tsv" \
     > "$WORK/r4s1.out" 2>&1; then
  no "RED FAILED: a snapshot claiming a candidate the decision never named was ranked — the snapshot parsed, so the instrument reported confidence"
else
  grep -q 'PACKET-9199-never-a-candidate' "$WORK/r4s1.out" \
    && ok "RED: a well-formed, correctly-chained snapshot bound to a candidate the decision does not name is REFUSED and the orphan is named — parsing is not belonging" \
    || no "RED FAILED: the orphan snapshot was refused without naming what was wrong"
fi
# R5: a tampered chain is not a ranking substrate.
mks1 "$WORK/r5s1" "build-os/memory/residue.md"
sed 's/\tresidue_items_closed\t1\t/\tresidue_items_closed\t9\t/' "$WORK/r5s1/snap.tsv" > "$WORK/r5s1/snap2.tsv"
if "$S1" rank --decision-id DECISION-9101-s1-fixture --store "$WORK/r5s1/tel.tsv" --snapshots "$WORK/r5s1/snap2.tsv" \
     > "$WORK/r5s1.out" 2>&1; then
  no "RED FAILED: S1 ranked against a snapshot store whose chain does not verify"
else
  ok "RED: an edited historical signal breaks the chain and S1 REFUSES to rank on it — a value recomputed or rewritten after the fact is not evidence about the decision that was made"
fi
# R6: an unknown decision is refused rather than ranked over an empty set.
if "$S1" rank --decision-id DECISION-9999-does-not-exist >"$WORK/r6s1.out" 2>&1; then
  no "RED FAILED: S1 ranked a decision that does not exist"
else
  ok "RED: an unknown decision id is refused — a ranking over an empty candidate set is satisfiable by anything"
fi
# R7: THE SAME PRINCIPLE, ONE STEP LATER — AND THE TOOL USED TO VIOLATE IT.
# R6 refuses an empty candidate set at the door. Guard 1 can produce one AFTER
# the door, by excluding every candidate, and S1 then printed an EMPTY ordering
# section and exited 0 — its own header claiming "0 an ordering was produced".
# Reproducible on live data at the time this was found:
#   rank --decision-id DECISION-0009-p3-accept-and-constrain
# An empty section is not an ordering, and an exit code that says otherwise is a
# falsified contract. The refusal must still PRINT the exclusions, because guard
# 1's whole promise is that a refused candidate stays visible with its reason.
mks1 "$WORK/r7s1" "build-os/metrics/rank-candidates.sh" "" "build-os/tools/authority-envelope.sh"
if "$S1" rank --decision-id DECISION-9101-s1-fixture --store "$WORK/r7s1/tel.tsv" --snapshots "$WORK/r7s1/snap.tsv" \
     > "$WORK/r7s1.out" 2>"$WORK/r7s1.err"; then
  no "RED FAILED: guard 1 refused EVERY candidate and S1 still exited 0, reporting an empty ordering section as an ordering produced"
else
  ok "RED: when guard 1 refuses every candidate S1 exits 2 — exit 0 asserts an ordering was produced, and there is none"
fi
grep -qF 'ordering: NONE' "$WORK/r7s1.out" \
  && ok "...and the ordering section says NONE in words, so an empty section cannot be misread as an ordering nobody printed" \
  || { no "RED FAILED: the ordering section is silently empty rather than stating that no ordering exists"; head -4 "$WORK/r7s1.out" | sed 's/^/      | /'; }
R7RANKS="$(grep -c '^rank ' "$WORK/r7s1.out" || true)"
[ "${R7RANKS:-1}" -eq 0 ] \
  && ok "...and it emits no rank line at all — nothing was ordered, and nothing pretends to have been" \
  || no "RED FAILED: $R7RANKS rank line(s) survive a run in which every candidate was excluded"
R7EXCL="$(grep -c '^excluded ' "$WORK/r7s1.out" || true)"
[ "${R7EXCL:-0}" -eq 2 ] \
  && ok "...and BOTH refusals are still printed with their reasons — a refusal nobody can read is not a refusal, so exit 2 does not suppress the record" \
  || no "the whole-set refusal printed ${R7EXCL:-0} of 2 exclusions; the record does not survive the refusal"
# R8: GUARD 1 FAILED CLOSED ON ABSENCE AND *OPEN* ON SPELLING.
# `touches()` compared raw strings, so four aliases of the one file guard 1 exists
# to protect all reached rank 1 while the plain spelling was excluded. A guard a
# rename of the same path defeats is not a guard. The fourth is not a spelling at
# all — it is a WILDCARD, which names a set whose members depend on the working
# tree, and expanding it would screen frozen evidence against the current tree.
S1SELF="build-os/metrics/rank-candidates.sh"
R8I=0
for r8alias in "./$S1SELF" "build-os/metrics/../metrics/rank-candidates.sh" \
               "build-os//metrics/rank-candidates.sh" "build-os/metrics/*"; do
  R8I=$((R8I+1))
  mks1 "$WORK/r8s1$R8I" "$r8alias"
  "$S1" rank --decision-id DECISION-9101-s1-fixture --store "$WORK/r8s1$R8I/tel.tsv" \
        --snapshots "$WORK/r8s1$R8I/snap.tsv" > "$WORK/r8s1$R8I.out" 2>&1
  if grep -q '^excluded PACKET-9101-touches-s1 ' "$WORK/r8s1$R8I.out"; then
    ok "RED: the alias \"$r8alias\" of S1's own file is EXCLUDED — guard 1 no longer fails open on spelling"
  else
    no "RED FAILED: \"$r8alias\" names S1's own code and was RANKED; guard 1 compares raw strings and any alias walks past it"
  fi
done
grep -q '^excluded PACKET-9101-touches-s1 reason=guard1_uninterpretable_surface' "$WORK/r8s1$R8I.out" \
  && ok "RED: the WILDCARD surface is refused as uninterpretable rather than expanded — S1 will not decide what a candidate writes by looking at the working tree, because that would make frozen evidence mean different things from different directories" \
  || { no "RED FAILED: a wildcard write surface is not refused as uninterpretable"; grep '^excluded' "$WORK/r8s1$R8I.out" | head -2 | sed 's/^/      | /'; }
R8WALL=0
for R8J in 1 2 3 4; do
  awk '$1=="rank" && $3=="PACKET-9101-touches-nothing"{f=1} END{exit !f}' "$WORK/r8s1$R8J.out" || R8WALL=$((R8WALL+1))
done
[ "$R8WALL" -eq 0 ] \
  && ok "...and in all four runs the innocent neighbour is STILL RANKED — normalising the comparison tightened the guard without turning it into a wall" \
  || no "$R8WALL of 4 alias runs refused the whole fixture; the guard became a wall rather than a predicate"
# The other direction, which is the one a conservative normalisation gets wrong:
# an alias of a path that is NOT protected must still rank.
mks1 "$WORK/r8neg" "./build-os/memory/residue.md"
"$S1" rank --decision-id DECISION-9101-s1-fixture --store "$WORK/r8neg/tel.tsv" \
      --snapshots "$WORK/r8neg/snap.tsv" > "$WORK/r8neg.out" 2>&1
awk '$1=="rank" && $3=="PACKET-9101-touches-s1"{f=1} END{exit !f}' "$WORK/r8neg.out" \
  && ok "RED (other direction): a NON-protected path written in the same aliased form is still RANKED — the normaliser resolves spellings, it does not excuse itself by excluding everything" \
  || no "RED FAILED: normalisation excluded a candidate that touches nothing protected; over-broad in the unsafe direction is still broken"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
