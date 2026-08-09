#!/usr/bin/env bash
# THE GATE ON THE SECOND ANCHOR MIGRATION.
#
# The first attempt failed for one reason: it assumed the positional
# `path:line` evidence format had ONE consumer, updated it, and shipped. There
# were seventeen. The registry converted, scan-controls.sh understood the new
# form, and control_registry_tests.sh — carrying its own independent parser —
# reported 712 unresolvable references.
#
# So this suite does not check that the inventory is right. It checks that the
# inventory CAN FAIL: a consumer planted in the tree must be found, and a
# detector that has gone blind must be visible as red rather than as a shrinking
# count. That distinction is the entire lesson of the first attempt.
set -uo pipefail
cd "$(dirname "$0")/.."
SRC="$PWD"
P=0; F=0
ok(){ P=$((P+1)); echo "  ok   $1"; }
no(){ F=$((F+1)); echo "  FAIL $1"; }
t(){ [ "$2" = "$3" ] && ok "$1" || no "$1 (got '$2' want '$3')"; }

INV="build-os/registry/consumer-inventory.sh"
count(){ bash "$INV" --tsv 2>/dev/null | tail -n +2 | grep -c . || true; }
has(){ bash "$INV" --tsv 2>/dev/null | cut -f1 | grep -qx "$1"; }

echo "== the inventory finds the consumers the first attempt missed =="
N="$(count)"
[ "${N:-0}" -ge 15 ] && ok "inventory reports $N consumers (>= 15; the first attempt assumed 1)" \
                     || no "inventory reports only ${N:-0} consumers"
for f in tests/control_registry_tests.sh tests/mutator_registry_tests.sh \
         build-os/registry/scan-controls.sh build-os/registry/scan-mutators.sh \
         build-os/tools/evidence-policy.sh; do
  has "$f" && ok "found: $f" || no "MISSED: $f"
done
# The one that actually broke the first migration, named explicitly.
has tests/control_registry_tests.sh \
  && ok "  control_registry_tests.sh is present — the consumer whose omission reverted attempt 1" \
  || no "the consumer that reverted attempt 1 is STILL missing from the inventory"

echo "== THE COVERAGE GATE: a PLANTED consumer must be detected =="
# Written into the tree, because a detector proven only against a fixture has
# not been proven against the thing it actually scans.
PLANT="build-os/registry/.planted-consumer-probe.sh"
cleanup(){ rm -f "$SRC/$PLANT"; }
trap cleanup EXIT
cat > "$SRC/$PLANT" <<'EOF'
#!/usr/bin/env bash
# A synthetic consumer: decodes a citation positionally and touches the domain.
for ref in $(cat evidence_refs.txt); do
  file="${ref%:*}"; line="${ref##*:}"
  echo "control_registry says $file at $line"
done
EOF
AFTER="$(count)"
t "planting a consumer raises the inventory count" "$AFTER" "$((N+1))"
has "$PLANT" && ok "  and the planted consumer is named, not merely counted" || no "the planted consumer was not identified"
cleanup
t "removing it returns the count to baseline" "$(count)" "$N"

echo "== a blind detector must be RED, not quietly empty =="
# Zero consumers means the patterns rotted. Reporting that as "nothing to
# migrate" is how the first attempt's blind spot would have survived a rerun.
BLIND="$(mktemp -d)"; mkdir -p "$BLIND/build-os/registry" "$BLIND/tests"
cp "$INV" "$BLIND/build-os/registry/"
# CAPTURE FIRST, THEN GREP. Under `set -o pipefail` the pipeline inherits the
# PRODUCER's status, so `inventory | grep -q` reports failure precisely because
# the inventory correctly exited 3 — a passing assertion rendered as FAIL. That
# is DEFECT-0013's family, already on record here, and it bit this suite on its
# first run.
BLIND_OUT="$(bash "$BLIND/build-os/registry/consumer-inventory.sh" --repo "$BLIND" 2>&1)"; BLIND_RC=$?
t "an empty tree exits non-zero rather than reporting a clean bill" "$BLIND_RC" "3"
case "$BLIND_OUT" in
  *REFUSED*) ok "  and says the detector is broken rather than the tree clean" ;;
  *)         no "no refusal message" ;;
esac
rm -rf "$BLIND"

echo "== every consumer is CLASSIFIED, so an update order can be built =="
UNK="$(bash "$INV" --tsv | tail -n +2 | awk -F'\t' '$2=="parser"' | grep -c . || true)"
t "no consumer is left unclassified" "${UNK:-1}" "0"
KINDS="$(bash "$INV" --tsv | tail -n +2 | awk -F'\t' '{print $2}' | sort -u | tr '\n' ',' )"
case "$KINDS" in *registry_scanner*) ok "the scanners are identified separately — they must be updated FIRST" ;;
                 *) no "no registry_scanner kind in the inventory" ;; esac
case "$KINDS" in *suite_assertion*) ok "the suite assertions are identified — attempt 1 died on exactly these" ;;
                 *) no "no suite_assertion kind in the inventory" ;; esac

echo "== CONFIRMED and CANDIDATE are not added together =="
# The first inventory reported "18 consumers" as fact. Four were config-pair
# splitters that never read a citation: `evid` in DOMAIN_RE also matches
# `evidence_axis`. The loose net is KEPT — a false negative reverted attempt 1,
# a false positive costs a review — but the two counts are now separate.
CONF="$(bash "$INV" --tsv | tail -n +2 | awk -F'\t' '$3=="CONFIRMED"' | grep -c . || true)"
CAND="$(bash "$INV" --tsv | tail -n +2 | awk -F'\t' '$3=="CANDIDATE"' | grep -c . || true)"
[ "${CONF:-0}" -ge 6 ] && ok "$CONF CONFIRMED consumers actually handle a citation field" || no "only ${CONF:-0} confirmed"
[ "${CAND:-0}" -ge 1 ] && ok "  and $CAND CANDIDATES are carried for review, not counted as consumers" || no "no candidates carried"
for f in build-os/tools/evidence-policy.sh build-os/metrics/rank-candidates.sh; do
  bash "$INV" --tsv | awk -F'\t' -v f="$f" '$1==f && $3=="CANDIDATE"' | grep -q . \
    && ok "  $f is a CANDIDATE — it splits config pairs, not citations" \
    || no "$f is still counted as a confirmed consumer"
done
# The confirmed set must still contain the one that reverted attempt 1.
bash "$INV" --tsv | awk -F'\t' '$1=="tests/control_registry_tests.sh" && $3=="CONFIRMED"' | grep -q . \
  && ok "  and control_registry_tests.sh is CONFIRMED, not downgraded by the tightening" \
  || no "the consumer that reverted attempt 1 was downgraded to a candidate"

echo "== the DATA side is enumerated too — the registry is four files, not one =="
# Attempt 1 converted control_registry.txt and nothing else, because "the
# registry" was assumed singular.
# CAPTURED ONCE, then matched in-shell. `inventory | grep -q` SIGPIPEs the
# producer the moment grep finds a match, and under `set -o pipefail` that 141
# turns a PASSING assertion into a FAIL. This is DEFECT-0013, already on record
# here, and it bit this same suite twice: only the LAST store matched, because
# grep read to EOF and never closed the pipe early.
INV_OUT="$(bash "$INV" 2>/dev/null)"
STORES="$(printf '%s\n' "$INV_OUT" | grep -c 'positional citations' || true)"
[ "${STORES:-0}" -ge 4 ] && ok "$STORES citation-bearing stores enumerated (attempt 1 migrated 1)" || no "only ${STORES:-0} stores enumerated"
for st in control_registry mutator_registry defect_classes findings; do
  case "$INV_OUT" in
    *"$st.txt"*"positional citations"*) ok "  $st.txt is on the phase-4 list" ;;
    *) no "$st.txt is MISSING from the store list" ;;
  esac
done

echo "== the inventory does not exempt itself by pattern =="
# Self-exclusion is by EXACT PATH. A pattern-based exemption could silently
# hide other consumers, which is the failure mode this whole suite guards.
grep -q 'SELF_PATH="build-os/registry/consumer-inventory.sh"' "$INV" \
  && ok "self-exclusion is one literal path" || no "self-exclusion is not a literal path"
grep -qE 'grep -v.*consumer|exclude.*\*' "$INV" \
  && no "the inventory carries a WILDCARD exclusion — it could hide a real consumer" \
  || ok "  and there is no wildcard exclusion that could hide a real consumer"

echo "==== RESULT: $P passed, $F failed ===="
[ "$F" -eq 0 ]
