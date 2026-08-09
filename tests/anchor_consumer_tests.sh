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
