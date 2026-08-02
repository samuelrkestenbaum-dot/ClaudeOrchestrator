#!/usr/bin/env bash
# Build OS — cross-surface memory kernel tests.
#
# WHAT THIS PINS, AND WHY IT IS ONE SUITE AND NOT EIGHTEEN. The kernel exists to
# prove ONE property: Claude closes work into governed memory, and a second AI
# surface consumes that state WITHOUT anybody copying the transcript. Every
# section below is a way that property can be false. The end-to-end fixture in
# section 0 is the property itself, executed from EMPTY STORES on every run, so
# the proof is re-earned rather than remembered.
#
# EVERY SECTION IS RED-DRIVEN. A guard that has only ever been observed passing
# is a guard nobody has tested, so each section plants the defect it exists
# against and asserts the REFUSAL TOKEN — not the prose, which changes, but the
# token, which is the interface.
#
# THE ONE INVARIANT WORTH THE SUITE (section 11): a context package that PARSES
# but refers to the WRONG VERSIONS is REFUSED. `resolvability is not identity`,
# applied to memory.
#
# NO NETWORK. Deterministic. Every fixture lives under $WORK and nothing outside
# it is written — the LIVE stores are READ, never modified, and section 18 is
# what proves that claim rather than asserting it.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MK="$SRC/build-os/tools/memory-kernel.sh"
LIVE="$SRC/build-os/kernel"
REG="$SRC/build-os/registry/control_registry.txt"

PASS=0; FAIL=0
TAB=$'\t'
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# --- the two primitives every section uses ----------------------------------
# `k` runs the kernel against a fixture store set and captures BOTH streams and
# the exit code. Output goes to a FILE and is grepped from there: a gate piped
# through `tail` is a gate whose verdict can be lost, and this repository has
# already paid for that once.
KOUT="$WORK/k.out"
k(){ bash "$MK" "$@" --kernel "$KD" --repo "$SRC" > "$KOUT" 2>&1; KRC=$?; return 0; }
# A refusal is REFUSED when it exits 2 AND names its token. Either alone is
# insufficient: exit 2 with the wrong reason is a guard firing for a reason
# nobody checked, and the right prose at exit 0 is not a refusal at all.
refused_with(){ # <token> <what>
  if [ "$KRC" = "2" ] && grep -qF "$1" "$KOUT"; then ok "$2"
  else no "$2 (exit $KRC, token $1 absent)"; sed 's/^/      | /' "$KOUT" | head -3; fi
}
accepted(){ # <what>
  if [ "$KRC" = "0" ]; then ok "$1"; else no "$1 (exit $KRC)"; sed 's/^/      | /' "$KOUT" | head -4; fi
}
# The SAME digest the kernel computes, computed independently here. The laundering
# attack in section 10 has to RE-SIGN a row it edited, because an attack that
# only edits the row is caught by a hash check nobody had to think hard about.
sha_of(){ if command -v sha256sum >/dev/null 2>&1; then printf '%s' "$1" | sha256sum | cut -d' ' -f1
          else printf '%s' "$1" | shasum -a 256 | cut -d' ' -f1; fi; }

# An empty kernel: the headers only, no rows. Everything below builds from here,
# so nothing in this suite depends on a store somebody seeded by hand.
new_kernel(){ # <dir>
  mkdir -p "$1/exports"
  local f
  for f in namespaces actors memory_objects memory_events memory_relationships memory_artifacts memory_handoffs memory_context_packages; do
    grep '^#' "$LIVE/$f.tsv" > "$1/$f.tsv"
  done
}

B="claude.cowork.session.ramhds"   # the builder's execution surface
G="chatgpt.web.session.strategy-01" # the receiving surface

# THE END-TO-END PATH, from empty stores, in the order the property requires.
# Called by section 0 and re-used by later sections that need a populated store.
seed(){ # <kernel-dir>
  KD="$1"; new_kernel "$KD"
  k record-namespace --id NS-0001 --type organization --owner ACT-0001 --label gravito
  k record-namespace --id NS-0002 --type project --parent NS-0001 --owner ACT-0001 --label orchestrator
  k record-namespace --id NS-0003 --type packet --parent NS-0002 --owner ACT-0001 --label PACKET-0035
  k record-namespace --id NS-0009 --type project --parent NS-0001 --owner ACT-0001 --label sibling-project
  k record-actor --id ACT-0001 --actor-type human --role gravito.operator --surface-family human.operator --surface-instance operator.local --namespace NS-0001
  k record-actor --id ACT-0002 --actor-type ai_agent --role gravito.builder --surface-family claude.cowork.session --surface-instance "$B" --provider anthropic --model claude-opus-5 --session s-1 --namespace NS-0002
  k record-actor --id ACT-0003 --actor-type ai_agent --role gravito.chatgpt.strategy --surface-family chatgpt.web.session --surface-instance "$G" --provider openai --model unspecified --session s-2 --namespace NS-0002
  k record-actor --id ACT-0004 --actor-type ai_agent --role gravito.sibling --surface-family claude.cowork.session --surface-instance claude.cowork.session.sibling --namespace NS-0009
  k record-artifact --id ART-0001 --namespace NS-0003 --kind repo_file --path build-os/registry/control_registry.txt --anchor ANC-0001 --actor ACT-0002
  k record-artifact --id ART-0002 --namespace NS-0003 --kind repo_file --path build-os/metrics/decision_telemetry.tsv --anchor ANC-0002 --actor ACT-0002
  k record-artifact --id ART-0003 --namespace NS-0003 --kind repo_file --path build-os/metrics/signal_snapshots.tsv --anchor ANC-0008 --actor ACT-0002
  k record-artifact --id ART-0004 --namespace NS-0003 --kind repo_file --path build-os/metrics/packet_metrics.tsv --anchor ANC-0009 --actor ACT-0002
  k record-artifact --id ART-0005 --namespace NS-0003 --kind repo_file --path build-os/registry/findings.txt --anchor ANC-0004 --actor ACT-0002
  k record-artifact --id ART-0006 --namespace NS-0003 --kind repo_file --path build-os/receipts/gravito_p5_outcome_counterfactual_telemetry_a.md --anchor ANC-0007 --actor ACT-0002
  k record-artifact --id ART-0007 --namespace NS-0003 --kind repo_file --path build-os/registry/evidence_assertions.txt --anchor ANC-0005 --actor ACT-0002
  k record-object --object-id OBJ-0001 --type goal --namespace NS-0003 --actor ACT-0002 --surface "$B" --expected-version 0 --status active --truth-state decided --authority operator --payload "goal: cross-surface memory"
  k record-object --object-id OBJ-0002 --type control --namespace NS-0003 --actor ACT-0002 --surface "$B" --expected-version 0 --status active --truth-state observed --authority operator --evidence ART-0001 --payload "control: registry.evidence_resolution"
  k record-object --object-id OBJ-0003 --type decision --namespace NS-0003 --actor ACT-0002 --surface "$B" --expected-version 0 --status sealed --truth-state decided --authority operator --evidence ART-0002 --payload "decision: DECISION-0011"
  k record-object --object-id OBJ-0004 --type ranking --namespace NS-0003 --actor ACT-0002 --surface "$B" --expected-version 0 --status active --truth-state observed --authority operator --evidence ART-0003 --payload "ranking: SIGNAL-SNAPSHOT-0094"
  k record-object --object-id OBJ-0005 --type outcome --namespace NS-0003 --actor ACT-0002 --surface "$B" --expected-version 0 --status active --truth-state observed --authority operator --evidence ART-0004 --payload "outcome: p5"
  k record-object --object-id OBJ-0006 --type receipt --namespace NS-0003 --actor ACT-0002 --surface "$B" --expected-version 0 --status closed --truth-state observed --authority operator --evidence ART-0006 --payload "receipt: p5"
  k record-object --object-id OBJ-0007 --type finding --namespace NS-0003 --actor ACT-0002 --surface "$B" --expected-version 0 --status open --truth-state reported --authority operator --evidence ART-0005 --payload "finding: FINDING-0003 open"
  k record-object --object-id OBJ-0008 --type evidence --namespace NS-0003 --actor ACT-0002 --surface "$B" --expected-version 0 --status active --truth-state observed --authority operator --evidence ART-0007 --payload "evidence: EV-0001"
  k record-object --object-id OBJ-0009 --type task --namespace NS-0003 --actor ACT-0002 --surface "$B" --expected-version 0 --status open --truth-state reported --authority operator --payload "packet state: in flight"
  k record-object --object-id OBJ-0010 --type decision --namespace NS-0003 --actor ACT-0002 --surface "$B" --expected-version 0 --status open --truth-state unknown --authority operator --payload "open question: write authority"
  k record-object --object-id OBJ-0011 --type finding --namespace NS-0003 --actor ACT-0002 --surface "$B" --expected-version 0 --status open --truth-state inferred --authority operator --payload "inferred: the next packet is projection migration"
  k record-object --object-id OBJ-0013 --type plan --namespace NS-0003 --actor ACT-0002 --surface "$B" --expected-version 0 --status active --truth-state reported --authority operator --payload "plan: migrate projections"
  k record-object --object-id OBJ-0014 --type task --namespace NS-0003 --actor ACT-0002 --surface "$B" --expected-version 0 --status active --truth-state reported --authority operator --payload "task: widen the anchor table"
  k record-object --object-id OBJ-0015 --type task --namespace NS-0003 --actor ACT-0002 --surface "$B" --expected-version 0 --status active --truth-state reported --authority operator --payload "task: census the kernel writer"
  k record-object --object-id OBJ-0016 --type task --namespace NS-0003 --actor ACT-0002 --surface "$B" --expected-version 0 --status active --truth-state reported --authority operator --payload "task: record the pipefail defect"
  k record-object --object-id OBJ-0012 --type task --namespace NS-0009 --actor ACT-0004 --surface claude.cowork.session.sibling --expected-version 0 --status open --truth-state reported --authority operator --payload "the sibling project's work"
  k record-object --object-id OBJ-0009 --type task --namespace NS-0003 --actor ACT-0002 --surface "$B" --expected-version 1 --status closed --truth-state observed --authority operator --evidence ART-0001 --payload "packet state: built"
  k record-relationship --id REL-0001 --source OBJ-0003 --type selected_from --target OBJ-0004 --namespace NS-0003 --actor ACT-0002 --evidence ART-0003
  k record-relationship --id REL-0002 --source OBJ-0003 --type resulted_in --target OBJ-0005 --namespace NS-0003 --actor ACT-0002 --evidence ART-0004
  k record-relationship --id REL-0003 --source OBJ-0007 --type blocks --target OBJ-0010 --namespace NS-0003 --actor ACT-0002 --evidence ART-0005
  k record-relationship --id REL-0004 --source OBJ-0011 --type contradicts --target OBJ-0009 --namespace NS-0003 --actor ACT-0002
  k record-event --type PacketStarted --actor ACT-0002 --surface "$B" --namespace NS-0003 --object OBJ-0009 --object-version 1 --authority operator
  k record-event --type DecisionSealed --actor ACT-0002 --surface "$B" --namespace NS-0003 --object OBJ-0003 --object-version 1 --authority operator --evidence ART-0002
  k record-event --type PacketClosed --actor ACT-0002 --surface "$B" --namespace NS-0003 --object OBJ-0009 --object-version 2 --authority operator --evidence ART-0001
  k create-handoff --id HOF-0001 --from-actor ACT-0002 --from-surface "$B" --to-role gravito.chatgpt.strategy --namespace NS-0003 \
     --objective "take over strategy using only governed state" --completed "OBJ-0009;OBJ-0002;OBJ-0006" \
     --current-state "OBJ-0001;OBJ-0003;OBJ-0004;OBJ-0005;OBJ-0008" --open-questions "OBJ-0007;OBJ-0010;OBJ-0011" \
     --evidence "ART-0001;ART-0002;ART-0003;ART-0004;ART-0005;ART-0006;ART-0007" --authority-refs operator \
     --next-action "decide OBJ-0010, which OBJ-0007 blocks" --acceptance "a decision object at version 1 with an authority_ref and resolvable evidence"
  k compile-context --id CTX-0001 --namespace NS-0003 --actor ACT-0003 --surface "$G" --objective "strategy takeover" --budget 20
}

echo "== 0. THE END-TO-END PROPERTY, executed from empty stores =="
# THIS SECTION IS THE PACKET. Claude records typed state, creates a handoff, the
# ledger records it, the compiler builds a package for the ChatGPT role, the
# export is generated, and a consumer that has never seen the Claude session can
# answer six questions from it. Everything else in this file protects this.
KD="$WORK/e2e"; seed "$KD"
k validate;   accepted "the end-to-end store set validates from a standing start"
E2E="$WORK/e2e.md"
k export-handoff --handoff HOF-0001 --package CTX-0001 --out "$E2E"; accepted "the ChatGPT export renders from the handoff and the package"
k acknowledge-handoff --handoff HOF-0001 --actor ACT-0003 --surface "$G"; accepted "the receiving surface acknowledges the handoff through a governed command"

# THE SIX QUESTIONS A FRESH CONSUMER MUST BE ABLE TO ANSWER, each checked against
# the export ALONE. The transcript is not on disk anywhere in this fixture, so
# anything the export cannot answer is unanswerable here.
q(){ grep -qF "$1" "$E2E" && ok "the export answers: $2" || no "the export does not answer: $2"; }
q "## 2. What was completed"                  "what was completed"
q "## 4. What remains open"                   "what remains open"
q "## 5. Evidence"                            "what evidence supports it"
q "## 6. Authority in force"                  "what authority applies"
q "## 7. The next decision required"          "what next decision is required"
q "## 9. The binding"                         "which exact source versions it is bound to"
# ...and the answers are SUBSTANTIVE, not empty headings.
grep -qF 'OBJ-0009' "$E2E" && grep -qF 'OBJ-0010' "$E2E" && grep -qF 'ANC-0002' "$E2E" \
  && ok "the export names concrete objects, an open decision and a resolvable anchor — the headings are not empty" \
  || no "the export's sections are present but carry no concrete state"

echo "== 1. Stable ids survive line movement — identity in, position out =="
# The kernel cites artifacts by ANCHOR, never by line. The proof is executed
# against a fixture repository so a line can actually be moved: the SAME anchor
# id resolves to a DIFFERENT line after an insertion, and nothing recorded in the
# kernel changes.
FR="$WORK/fixrepo"; mkdir -p "$FR/build-os/registry"
printf 'alpha\ncontrol: fixture.subject\nomega\n' > "$FR/build-os/registry/f.txt"
cat > "$WORK/anchors.txt" <<'EOF'
ANC-F001|fixture.subject|control_id|buildos.control|the-fixture-subject|build-os/registry/f.txt|control: fixture.subject|1|2026-08-02|-
EOF
L1="$(bash "$SRC/build-os/registry/scan-controls.sh" anchors --anchors "$WORK/anchors.txt" --repo "$FR" --ref ANC-F001 2>&1 | sed -n 's/^resolved_line: //p')"
printf 'inserted\ninserted\n%s' "$(cat "$FR/build-os/registry/f.txt")" > "$WORK/tmpf" && mv "$WORK/tmpf" "$FR/build-os/registry/f.txt"
L2="$(bash "$SRC/build-os/registry/scan-controls.sh" anchors --anchors "$WORK/anchors.txt" --repo "$FR" --ref ANC-F001 2>&1 | sed -n 's/^resolved_line: //p')"
{ [ "$L1" = "2" ] && [ "$L2" = "4" ]; } \
  && ok "one unchanged anchor id resolved to line $L1 and then to line $L2 after an insertion — the position is a return value, not the identity" \
  || no "the anchor did not track its content across an insertion (before=$L1 after=$L2)"
# RED DRIVE: delete the content and the anchor does not silently resolve to
# whatever slid into place — it refuses.
printf 'alpha\nomega\n' > "$FR/build-os/registry/f.txt"
bash "$SRC/build-os/registry/scan-controls.sh" anchors --anchors "$WORK/anchors.txt" --repo "$FR" --ref ANC-F001 > "$WORK/anc.out" 2>&1
grep -qF 'UNRESOLVED' "$WORK/anc.out" \
  && ok "RED: with the anchored content deleted the reference REFUSES rather than resolving to the line that took its place" \
  || no "a deleted anchor target did not produce UNRESOLVED"
# ...and the kernel's own store carries no positional citation at all.
# `-c` over several files prints one count PER FILE, so the total is taken by
# matching and then counting the matches — a row count, not a per-file report.
NPOS="$(grep -hoE '\.(sh|md|txt|tsv|mjs):[0-9]+' "$LIVE"/*.tsv | grep -c . || true)"
[ "${NPOS:-0}" = "0" ] \
  && ok "no canonical kernel store contains a path:line token — there is nothing in them to decay" \
  || no "$NPOS positional citation(s) have been written into the canonical stores"

echo "== 2. Typed objects version correctly =="
KD="$WORK/e2e"
NV="$(grep -c "^OBJ-0009${TAB:-	}" "$KD/memory_objects.tsv" || true)"
[ "$NV" = "2" ] && ok "OBJ-0009 carries exactly 2 version rows after one correction" || no "OBJ-0009 carries $NV version row(s), not 2"
V1="$(awk -F'\t' '$1=="OBJ-0009" && $5==1 {print $6}' "$KD/memory_objects.tsv")"
V2="$(awk -F'\t' '$1=="OBJ-0009" && $5==2 {print $6}' "$KD/memory_objects.tsv")"
{ [ "$V1" = "open" ] && [ "$V2" = "closed" ]; } \
  && ok "version 1 still reads \`open\` and version 2 reads \`closed\` — the history was added to, not overwritten" \
  || no "the version rows do not preserve the earlier state (v1=$V1 v2=$V2)"
# RED DRIVE: a version that skips a number is a correction nobody recorded.
cp -r "$KD" "$WORK/gap"; KD="$WORK/gap"
awk -F'\t' 'BEGIN{OFS="\t"} $1=="OBJ-0009" && $5==2 {$5=4} {print}' "$WORK/gap/memory_objects.tsv" > "$WORK/g.tsv" && mv "$WORK/g.tsv" "$WORK/gap/memory_objects.tsv"
k validate; refused_with "VERSION-NONMONOTONIC" "RED: a version sequence with a gap is refused"

echo "== 3. Events are append-only =="
KD="$WORK/e2e"
k validate; accepted "the untouched ledger validates — its digest chain closes"
cp -r "$WORK/e2e" "$WORK/ed"; KD="$WORK/ed"
# RED DRIVE 1: an event EDITED IN PLACE. Everything still parses; the chain does not.
sed -i 's/^\(EVT-0003\t\)[A-Za-z]*\t/\1PacketClosed\t/' "$WORK/ed/memory_events.tsv"
k validate; refused_with "EVENT-APPEND-ONLY" "RED: an event rewritten in place breaks the digest chain and is refused"
# RED DRIVE 2: an event REMOVED. A ledger with a hole is not a causal chain.
cp -r "$WORK/e2e" "$WORK/ex"; KD="$WORK/ex"
grep -v '^EVT-0005	' "$WORK/e2e/memory_events.tsv" > "$WORK/ex/memory_events.tsv"
k validate; refused_with "EVENT-APPEND-ONLY" "RED: an event deleted from the middle of the ledger is refused"

echo "== 4. Corrections create new versions AND new events =="
KD="$WORK/e2e"
NC="$(awk -F'\t' '$2=="ObjectCreated" && $8=="OBJ-0009" && $9==1' "$KD/memory_events.tsv" | grep -c . || true)"
NU="$(awk -F'\t' '$2=="ObjectVersioned" && $8=="OBJ-0009" && $9==2' "$KD/memory_events.tsv" | grep -c . || true)"
{ [ "$NC" = "1" ] && [ "$NU" = "1" ]; } \
  && ok "the correction produced exactly one ObjectCreated@1 and one ObjectVersioned@2 — the ledger records the change, not just the result" \
  || no "the correction's events are wrong (created=$NC versioned=$NU)"
# RED DRIVE: an event naming a version the object store does not carry.
cp -r "$WORK/e2e" "$WORK/ev"; KD="$WORK/ev"
awk -F'\t' 'BEGIN{OFS="\t"} $1=="EVT-0001"{$9=9} {print}' "$WORK/e2e/memory_events.tsv" > "$WORK/ev/memory_events.tsv"
k validate; refused_with "EVENT-APPEND-ONLY" "RED: an event pointed at a nonexistent version is refused (the chain covers the version field)"

echo "== 5. Namespace boundaries refuse cross-project access =="
KD="$WORK/e2e"
k record-object --object-id OBJ-0020 --type task --namespace NS-0009 --actor ACT-0002 --surface "$B" --expected-version 0 --truth-state reported --authority operator --payload x
refused_with "NAMESPACE-REFUSED" "RED: the builder writing into a SIBLING project's namespace is refused"
k create-handoff --id HOF-0009 --from-actor ACT-0002 --from-surface "$B" --to-role gravito.chatgpt.strategy --namespace NS-0003 \
  --objective x --completed OBJ-0012 --next-action y --acceptance z
refused_with "NAMESPACE-REFUSED" "RED: a handoff that hands across an object from another project is refused"
k record-relationship --id REL-0090 --source OBJ-0009 --type depends_on --target OBJ-0012 --namespace NS-0003 --actor ACT-0002
refused_with "NAMESPACE-REFUSED" "RED: a relationship edge across the boundary is refused — an edge is a read by another name"
# ...and the sibling's object is not merely absent from the package, it is COUNTED
# as refused, so an empty result and a filtered one are distinguishable.
grep -qF 'out_of_closure_refused=1' "$KD/memory_context_packages.tsv" \
  && ok "the package records that exactly 1 object was refused for being outside the closure, without naming it" \
  || no "the package does not account for objects outside the closure"
grep -qF 'OBJ-0012' "$KD/memory_context_packages.tsv" \
  && no "the sibling project's object id LEAKED into a package compiled for another namespace" \
  || ok "the sibling project's object id does not appear anywhere in the package — the count leaks nothing"
# ...and the boundary holds on the READ paths too, not only on the writes and the
# compiler. `project` renders an object's full envelope INCLUDING ITS PAYLOAD; a
# read subcommand that took no actor would be a cross-namespace retrieval wearing
# a projection's clothes, which is the one thing v0 refuses by default.
k project --object OBJ-0012 --actor ACT-0002 --surface "$B"
refused_with "NAMESPACE-REFUSED" "RED: projecting a SIBLING namespace's object is refused — a read across the boundary is refused whichever subcommand asks"
k project --object OBJ-0012
refused_with "actor is required for \`project\`" "RED: \`project\` with no actor is refused rather than answered — every read identifies actor, surface and namespace or it does not happen"
k project --object OBJ-0001 --actor ACT-0002 --surface "$B"
accepted "the same subcommand, scoped and inside the closure, still projects"

echo "== 6. A stale expected_version refuses, loudly, and never last-write-wins =="
KD="$WORK/e2e"
k record-object --object-id OBJ-0009 --type task --namespace NS-0003 --actor ACT-0002 --surface "$B" --expected-version 1 --truth-state reported --authority operator --payload "stale write"
refused_with "VERSION-STALE" "RED: a write carrying a version the store has moved past is refused"
grep -qF 'stale write' "$KD/memory_objects.tsv" \
  && no "the refused write left a row behind — the refusal is not atomic" \
  || ok "the refused write stored NOTHING: no row, no event, no partial state"
# The conflict may be RECORDED instead of refused — but it becomes a typed object
# and an event, never a silent overwrite.
cp -r "$WORK/e2e" "$WORK/cf"; KD="$WORK/cf"
k record-object --object-id OBJ-0009 --type task --namespace NS-0003 --actor ACT-0002 --surface "$B" --expected-version 1 --truth-state reported --authority operator --on-conflict record --payload "conflicting view"
accepted "--on-conflict record is accepted"
grep -qF 'conflict:expected_version=1,current_version=2' "$WORK/cf/memory_objects.tsv" \
  && ok "the conflict became a typed \`finding\` object naming both versions rather than disappearing" \
  || no "the recorded conflict did not become an object"
[ "$(awk -F'\t' '$1=="OBJ-0009" && $5==2 {print $21}' "$WORK/cf/memory_objects.tsv")" = "packet state: built" ] \
  && ok "the object it conflicted with is BYTE-IDENTICAL afterwards — nothing was overwritten" \
  || no "recording the conflict modified the object it conflicted with"

echo "== 7. A handoff resolves every object it references =="
KD="$WORK/e2e"
UNRES=0
for i in $(awk -F'\t' '$1=="HOF-0001"{print $7";"$8";"$9}' "$KD/memory_handoffs.tsv" | tr ';' ' '); do
  [ "$i" = "-" ] && continue
  grep -q "^$i	" "$KD/memory_objects.tsv" || { UNRES=$((UNRES+1)); echo "      | unresolved: $i"; }
done
[ "$UNRES" = "0" ] && ok "every object id the live handoff names resolves in the object store" || no "$UNRES handoff reference(s) resolve to nothing"
k create-handoff --id HOF-0008 --from-actor ACT-0002 --from-surface "$B" --to-role gravito.chatgpt.strategy --namespace NS-0003 \
  --objective x --completed "OBJ-9999" --next-action y --acceptance z
refused_with "HANDOFF-UNRESOLVED" "RED: a handoff naming an object that does not exist is refused — a list of names the receiver cannot resolve is a transcript with extra steps"
k create-handoff --id HOF-0007 --from-actor ACT-0002 --from-surface "$G" --to-role gravito.chatgpt.strategy --namespace NS-0003 \
  --objective x --next-action y --acceptance z
refused_with "SURFACE-IDENTITY" "RED: a logical role claiming an execution surface it does not own is refused"

echo "== 8. The compiler includes mandatory controls and the authority in force =="
KD="$WORK/e2e"
INC="$(awk -F'\t' '$1=="CTX-0001"{print $7}' "$KD/memory_context_packages.tsv")"
case ";$INC;" in *';OBJ-0002;'*) ok "the live control object is present in the compiled package (mandatory inclusion)" ;;
  *) no "the compiled package omits a live control" ;; esac
case ";$INC;" in *';OBJ-0003;'*) ok "the sealed decision is present in the compiled package (mandatory inclusion)" ;;
  *) no "the compiled package omits a sealed decision" ;; esac
AST="$(awk -F'\t' '$1=="CTX-0001"{print $13}' "$KD/memory_context_packages.tsv")"
case "$AST" in *effective=operator*) ok "the package carries the effective authority derived from its own included objects" ;;
  *) no "the package does not carry an authority state ($AST)" ;; esac
CON="$(awk -F'\t' '$1=="CTX-0001"{print $14}' "$KD/memory_context_packages.tsv")"
case "$CON" in *contradicts*) ok "the package surfaces the unresolved contradiction between its own included objects" ;;
  *) no "the package reports no contradiction where one is recorded ($CON)" ;; esac
# RED DRIVE: mandatory means mandatory. A budget too small to hold the controls
# and sealed decisions REFUSES rather than trimming one out of sight.
k compile-context --id CTX-0090 --namespace NS-0003 --actor ACT-0003 --surface "$G" --objective x --budget 1
refused_with "BUDGET-BELOW-MANDATORY" "RED: a budget below the mandatory set is refused rather than silently trimmed"

echo "== 9. Every omitted object carries a reason =="
cp -r "$WORK/e2e" "$WORK/om"; KD="$WORK/om"
k compile-context --id CTX-0002 --namespace NS-0003 --actor ACT-0003 --surface "$G" --objective "budgeted" --budget 12
accepted "a budgeted compilation is accepted"
OM="$(awk -F'\t' '$1=="CTX-0002"{print $11}' "$WORK/om/memory_context_packages.tsv")"
RS="$(awk -F'\t' '$1=="CTX-0002"{print $12}' "$WORK/om/memory_context_packages.tsv")"
NO="$(printf '%s' "$OM" | tr ';' '\n' | grep -c . || true)"
NR2="$(printf '%s' "$RS" | tr ';' '\n' | grep -c . || true)"
{ [ "$NO" = "$NR2" ] && [ "$NO" != "0" ]; } \
  && ok "$NO object(s) were omitted and $NR2 reason(s) recorded — one for one, and not vacuously zero" \
  || no "omissions and reasons do not pair up (omitted=$NO reasons=$NR2)"
case "$RS" in *budget-exceeded*) ok "the omission reason names the budget and the rank at which the object fell out" ;;
  *) no "the omission reason does not say WHY ($RS)" ;; esac
# RED DRIVE: strip the reasons and the store refuses — an omission with no reason
# is indistinguishable from an object the compiler never saw.
awk -F'\t' 'BEGIN{OFS="\t"} $1=="CTX-0002"{$12="-"} {print}' "$WORK/om/memory_context_packages.tsv" > "$WORK/o.tsv" && mv "$WORK/o.tsv" "$WORK/om/memory_context_packages.tsv"
k validate; refused_with "PACKAGE-IDENTITY" "RED: stripping the omission reasons is caught — the package's hash covers them"

echo "== 10. A context package binds to EXACT source versions =="
KD="$WORK/e2e"
IDS="$(awk -F'\t' '$1=="CTX-0001"{print $7}' "$KD/memory_context_packages.tsv")"
VER="$(awk -F'\t' '$1=="CTX-0001"{print $8}' "$KD/memory_context_packages.tsv")"
NI="$(printf '%s' "$IDS" | tr ';' '\n' | grep -c . || true)"
NVV="$(printf '%s' "$VER" | tr ';' '\n' | grep -c . || true)"
{ [ "$NI" = "$NVV" ] && [ "$NI" != "0" ]; } \
  && ok "the package pairs $NI object id(s) with $NVV version(s), positionally — an id without a version names an object at no version" \
  || no "the package's id/version binding is unpaired (ids=$NI versions=$NVV)"
n=1; BAD=0
for i in $(printf '%s' "$IDS" | tr ';' ' '); do
  want="$(printf '%s' "$VER" | cut -d';' -f$n)"; n=$((n+1))
  have="$(awk -F'\t' -v o="$i" '$1==o{print $5}' "$KD/memory_objects.tsv" | sort -n | tail -1)"
  [ "$want" = "$have" ] || { BAD=$((BAD+1)); echo "      | $i bound at $want, store holds $have"; }
done
[ "$BAD" = "0" ] && ok "every bound version equals the version that was current when the package was compiled" || no "$BAD binding(s) never matched the store"
grep -qF 'OBJ-0009;2' <<<"$(printf '%s;%s' "$IDS" "$VER")" >/dev/null 2>&1 || true
case "$IDS" in *OBJ-0009*) ok "the package binds the CORRECTED object (OBJ-0009), so the staleness test below has something to move" ;;
  *) no "the package does not include the object the correction applies to" ;; esac
# RED DRIVE: a package whose hash no longer describes its own binding.
cp -r "$WORK/e2e" "$WORK/pk"; KD="$WORK/pk"
awk -F'\t' 'BEGIN{OFS="\t"} $1=="CTX-0001"{$8="1;1;1;1;1;1;1;1;1;1;1;1"} {print}' "$WORK/e2e/memory_context_packages.tsv" > "$WORK/pk/memory_context_packages.tsv"
k validate; refused_with "PACKAGE-IDENTITY" "RED: rewriting the bound versions is caught by the package's own content hash"
# THE SELF-HASH IS UNKEYED, so it detects a CARELESS edit and not a WRITER. The
# tamper evidence is the CHAINED LEDGER: the ContextCompiled event carries the
# package's content_hash, and re-signing the package row does not move the event.
KD="$WORK/e2e"
grep -qE "ContextCompiled.*CTX-0001@[0-9a-f]{64}" "$KD/memory_events.tsv" \
  && ok "the ContextCompiled event carries the package's content_hash, so the package row is anchored to the tamper-evident ledger and not only to itself" \
  || no "the ContextCompiled event does not carry the package hash — nothing anchors the package row to the chained ledger"
# RED DRIVE — THE LAUNDERING ATTACK. Rewrite the recorded contradiction away and
# RE-SIGN the row correctly, which anyone who can write the store can do. The
# self-hash check passes. The ledger anchor does not.
cp -r "$WORK/e2e" "$WORK/ldr"; KD="$WORK/ldr"
CPF="$WORK/ldr/memory_context_packages.tsv"
awk -F'\t' 'BEGIN{OFS="\t"} $1=="CTX-0001"{$14="none-detected"} {print}' "$CPF" > "$WORK/l.tsv" && mv "$WORK/l.tsv" "$CPF"
LROW="$(grep "^CTX-0001${TAB}" "$CPF")"
LIN=""; for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do LIN="$LIN|$(printf '%s' "$LROW" | cut -f$i)"; done
LH="$(sha_of "$LIN")"
awk -F'\t' -v h="$LH" 'BEGIN{OFS="\t"} $1=="CTX-0001"{$16=h} {print}' "$CPF" > "$WORK/l.tsv" && mv "$WORK/l.tsv" "$CPF"
LROW2="$(grep "^CTX-0001${TAB}" "$CPF")"
LIN2=""; for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do LIN2="$LIN2|$(printf '%s' "$LROW2" | cut -f$i)"; done
[ "$(sha_of "$LIN2")" = "$(printf '%s' "$LROW2" | cut -f16)" ] \
  && ok "the laundered package re-signs cleanly against its OWN hash — the self-hash alone is not tamper evidence, and the attack is real" \
  || no "the laundering fixture did not actually re-sign (the attack below would pass for the wrong reason)"
k validate
refused_with "PACKAGE-UNANCHORED" "RED: a package field laundered and correctly RE-SIGNED is still refused — the ledger holds the hash the package was compiled with"
k read-context-package --package CTX-0001 --as-current
refused_with "PACKAGE-UNANCHORED" "RED: ...and the READ path refuses it too, so a laundered package cannot be consumed as current either"

echo "== 11. Changing a source object makes an old package STALE, not silently current =="
# THE INVARIANT THE WHOLE PACKET EXISTS FOR. The package still PARSES. Every id
# in it still RESOLVES. And it describes a state the project has left.
cp -r "$WORK/e2e" "$WORK/st"; KD="$WORK/st"
k read-context-package --package CTX-0001 --as-current; accepted "before any change, the package reads as CURRENT"
grep -qF 'state: CURRENT' "$KOUT" && ok "...and says so in one word a caller can branch on" || no "the package does not report its own state"
k record-object --object-id OBJ-0009 --type task --namespace NS-0003 --actor ACT-0002 --surface "$B" --expected-version 2 --status closed --truth-state observed --authority operator --evidence ART-0001 --payload "packet state: reopened and corrected"
accepted "a source object advances to version 3 through the governed path"
k read-context-package --package CTX-0001
{ [ "$KRC" = "0" ] && grep -qF 'state: STALE' "$KOUT"; } \
  && ok "the package is now readable ONLY as history, and reports state: STALE" \
  || no "the package did not become stale when its source moved (exit $KRC)"
grep -qF 'OBJ-0009@2->now@3' "$KOUT" \
  && ok "...and names the exact drift: OBJ-0009 bound at 2, the store now holds 3" \
  || no "the stale report does not name which binding drifted"
k read-context-package --package CTX-0001 --as-current
refused_with "PACKAGE-STALE" "RED: THE HEADLINE REFUSAL — a stale package REPRESENTED AS CURRENT is refused, exit 2, nothing returned"
grep -qF 'resolvability is not identity' "$KOUT" \
  && ok "...and the refusal names the defect class it belongs to, so the reader learns the rule and not just the failure" \
  || no "the refusal does not name the class"
# The export inherits the determination rather than re-deriving it differently.
k export-handoff --handoff HOF-0001 --package CTX-0001 --out "$WORK/stale.md"; accepted "the export still renders for a stale package (history is readable)"
grep -qF 'state: STALE' "$WORK/stale.md" \
  && ok "...and the export says STALE on its face, where a consumer reads it first" \
  || no "the export presents a stale package without saying so"
# THE BODY IS BOUND, NOT ONLY THE BINDING TABLE. A document whose section 3 shows
# an object at the CURRENT version while its section 9 names the BOUND one is
# `resolvability is not identity` reproduced inside the artifact built to refuse
# it — every id resolves, and the two halves describe different states.
BODYV="$(sed -n 's/^| `OBJ-0009` | \([0-9][0-9]*\) | task | .*/\1/p' "$WORK/stale.md" | head -1)"
TBLV="$(sed -n 's/^| `OBJ-0009` | \([0-9][0-9]*\) | `[a-z]*` | .*/\1/p' "$WORK/stale.md" | head -1)"
{ [ -n "$BODYV" ] && [ "$BODYV" = "$TBLV" ] && [ "$BODYV" = "2" ]; } \
  && ok "the stale export's BODY and its section 9 binding table name the SAME version (OBJ-0009@$BODYV), and it is the version the package BOUND — not the one the store has moved to" \
  || no "the export's body and its binding table disagree (body=$BODYV table=$TBLV, package bound 2, store holds 3)"
grep -qF '`OBJ-0009@2`' "$WORK/stale.md" && ! grep -qF '`OBJ-0009@3`' "$WORK/stale.md" \
  && ok "...and the per-object payload lines are bound too, so no part of the document silently reads the present" \
  || no "the export's payload lines render a version the package does not bind"

echo "== 12. Claude creates the handoff through GOVERNED commands only =="
KD="$WORK/e2e"
grep -qF 'HandoffCreated' "$KD/memory_events.tsv" && ok "the handoff produced a HandoffCreated event" || no "no HandoffCreated event"
grep -qF 'HandoffAccepted' "$KD/memory_events.tsv" && ok "the acknowledgement produced a HandoffAccepted event" || no "no HandoffAccepted event"
grep -qF 'ContextCompiled' "$KD/memory_events.tsv" && ok "the compilation produced a ContextCompiled event" || no "no ContextCompiled event"
[ "$(awk -F'\t' '$1=="HOF-0001"{print $15}' "$KD/memory_handoffs.tsv")" = "created" ] \
  && ok "the handoff ROW still reads \`created\` after acceptance — acceptance is a later EVENT, never an in-place edit" \
  || no "acknowledgement rewrote the handoff row"
# ...and BECAUSE the row is frozen at `created` forever, the export may not read
# it back. The ledger is what carries the state change, so the export derives the
# status from the ledger — otherwise a second consumer is told a claimed handoff
# is unclaimed, by the same module whose own ledger says otherwise.
k export-handoff --handoff HOF-0001 --package CTX-0001 --out "$WORK/acked.md"; accepted "the export renders after acknowledgement"
grep -qF '**status:** `created`' "$WORK/acked.md" \
  && no "an ACKNOWLEDGED handoff exports as \`created\` — the export is repeating a frozen field while the ledger records HandoffAccepted" \
  || ok "an acknowledged handoff does NOT export as \`created\`"
grep -qF '**status:** `accepted`' "$WORK/acked.md" \
  && ok "...it exports as \`accepted\`, derived from the last HandoffAccepted event naming this handoff" \
  || no "the export does not derive the handoff status from the ledger"
cp -r "$WORK/e2e" "$WORK/hr"; KD="$WORK/hr"
k acknowledge-handoff --handoff HOF-0001 --actor ACT-0002 --surface "$B"
refused_with "HANDOFF-ROLE" "RED: an actor whose role the handoff does not name cannot accept it"
# RED DRIVE: there is no ungoverned door. A bare invocation decides nothing.
bash "$MK" > "$KOUT" 2>&1; KRC=$?
{ [ "$KRC" = "2" ] && grep -qF 'no subcommand' "$KOUT"; } \
  && ok "RED: a bare invocation exits 2 rather than defaulting to some action" \
  || no "a bare invocation did not refuse (exit $KRC)"
k record-object --object-id OBJ-0030 --type task --namespace NS-0003 --actor ACT-0002 --surface "$B" --expected-version 0 --truth-state reported --authority operator --payload "token sk-ABCDEFGHIJKLMNOPQRSTUV"
refused_with "SECRET-INLINE" "RED: a raw credential in a payload is refused — secrets are held by reference or not at all"

echo "== 13. The ChatGPT export is consumable WITHOUT the transcript =="
# The fixture kernel contains no transcript, no chat log and no prose from the
# session that produced it. What the export can answer, it answers from the
# stores. What it cannot, nothing here can.
KD="$WORK/e2e"
grep -qiE 'transcript|chat log|conversation history' "$KD"/*.tsv \
  && no "the canonical stores carry transcript text — the property is satisfied by copying after all" \
  || ok "no canonical store contains transcript text, a chat log or conversation history"
MISSV=""
for t in observed reported inferred decided verified refuted unknown; do
  grep -qF "\`$t\`" "$E2E" || MISSV="$MISSV $t"
done
[ -z "$MISSV" ] && ok "all seven truth states appear in the export by name" || no "the export omits truth state(s):$MISSV"
grep -qF 'Truth-state vocabulary' "$E2E" \
  && ok "the export declares the full truth-state vocabulary, so a reader can tell an observation from an inference" \
  || no "the export does not declare its truth-state vocabulary"
# The inferred object must be LABELLED inferred and must NOT be presented as fact.
grep -qE '`OBJ-0011` \| 1 \| finding \| open \| `inferred`' "$E2E" \
  && ok "the model-generated conclusion is rendered with truth_state \`inferred\` and is not dressed as an observation" \
  || no "an inferred object is not visibly labelled in the export"
grep -qF 'consumable without the originating transcript' "$E2E" \
  && ok "the export states its own claim on its face" || no "the export makes no claim about transcript independence"
# ...and the claims it states are the ones the mechanism supports. `pkg_state`
# iterates the BOUND ids only, so an object recorded into the namespace AFTER the
# compile is invisible to it: "nothing was omitted" is false the moment the
# project moves, and the honest claim is time-scoped to the compile.
grep -qxF 'Nothing was omitted from the package.' "$E2E" \
  && no "the export claims nothing was omitted, full stop — a claim the freshness check cannot support once the project moves" \
  || ok "the export does not make an unbounded no-omission claim"
grep -qF 'AT COMPILE TIME' "$E2E" \
  && ok "the omission claim is scoped to the compile, which is exactly what the compiler measured and all it measured" \
  || no "the export's omission section does not scope its claim to the compile"

echo "== 14. Projections reconcile against canonical objects =="
KD="$WORK/e2e"
RT=0
for o in OBJ-0001 OBJ-0002 OBJ-0003 OBJ-0004 OBJ-0005 OBJ-0006 OBJ-0007 OBJ-0008 OBJ-0009; do
  bash "$MK" project --object "$o" --actor ACT-0002 --surface "$B" --kernel "$KD" --repo "$SRC" --out "$WORK/p.md" >/dev/null 2>&1
  bash "$MK" parse-projection --file "$WORK/p.md" --kernel "$KD" --repo "$SRC" > "$WORK/pp.out" 2>&1 || { RT=$((RT+1)); echo "      | round trip failed: $o"; continue; }
  grep -qF 'round_trip: MATCH' "$WORK/pp.out" || { RT=$((RT+1)); echo "      | no MATCH: $o"; }
done
[ "$RT" = "0" ] \
  && ok "canonical object -> generated projection -> parsed back -> same id, version, namespace and hash, for goal, control, decision, ranking, outcome, receipt, finding, evidence and packet state" \
  || no "$RT projection round trip(s) failed"
# RED DRIVE: edit the readable copy. It does not become a second opinion.
bash "$MK" project --object OBJ-0003 --actor ACT-0002 --surface "$B" --kernel "$KD" --repo "$SRC" --out "$WORK/p.md" >/dev/null 2>&1
sed -i 's/version=1/version=7/' "$WORK/p.md"
k parse-projection --file "$WORK/p.md"; refused_with "PROJECTION-DIVERGED" "RED: a projection edited to claim a version the store does not carry is refused"
bash "$MK" project --object OBJ-0003 --actor ACT-0002 --surface "$B" --kernel "$KD" --repo "$SRC" --out "$WORK/p.md" >/dev/null 2>&1
sed -i 's/^- \*\*truth state:\*\*.*/- **truth state:** `verified`/' "$WORK/p.md"
k parse-projection --file "$WORK/p.md"
{ [ "$KRC" = "0" ] && grep -qF 'round_trip: MATCH' "$KOUT"; } \
  && ok "a projection whose PROSE is edited still parses to the canonical identity — the footer is the binding, and \`reconcile\` is what catches the prose" \
  || no "the footer-based parse behaved unexpectedly (exit $KRC)"
cp "$WORK/p.md" "$KD/exports/"; k reconcile
refused_with "PROJECTION-DIVERGED" "RED: reconcile regenerates every projection and refuses the hand-edited copy byte for byte"

echo "== 15. Duplicate writable truth is rejected =="
KD="$WORK/e2e"
k record-object --object-id OBJ-0031 --type finding --namespace NS-0003 --actor ACT-0002 --surface "$B" --expected-version 0 --truth-state reported --authority operator --payload "build-os/kernel/exports/HANDOFF-0001-chatgpt-strategy.md"
refused_with "DUPLICATE-WRITABLE-TRUTH" "RED: a canonical object whose payload points INTO the generated projection tree is refused"
cp -r "$WORK/e2e" "$WORK/dp"; KD="$WORK/dp"
awk -F'\t' 'BEGIN{OFS="\t"} $1=="OBJ-0008" && $5==1 {$21="packet state: built"} {print}' "$WORK/e2e/memory_objects.tsv" > "$WORK/dp/memory_objects.tsv"
k validate
{ grep -qF 'DUPLICATE-WRITABLE-TRUTH' "$KOUT" || grep -qF 'OBJECT-HASH' "$KOUT"; } && [ "$KRC" = "2" ] \
  && ok "RED: two objects claiming one payload is refused (and the tampered row's hash is refused with it)" \
  || no "two objects were allowed to own one payload (exit $KRC)"
grep -qF 'the place a fact is edited' "$LIVE/README.md" \
  && ok "the store's own README states the one-way rule the code enforces" || no "the README does not state the projection rule"

echo "== 16. Evidence and truth states remain distinct =="
KD="$WORK/e2e"
k record-object --object-id OBJ-0032 --type finding --namespace NS-0003 --actor ACT-0002 --surface "$B" --expected-version 0 --truth-state observed --authority operator --payload "the suite is green"
refused_with "TRUTH-STATE-UNBACKED" "RED: \`observed\` with no evidence is refused — a model-generated inference may enter memory, and not as an observation"
k record-object --object-id OBJ-0033 --type decision --namespace NS-0003 --actor ACT-0002 --surface "$B" --expected-version 0 --truth-state decided --payload "we will do X"
refused_with "AUTHORITY-MISSING" "RED: \`decided\` with no authority_ref is refused — a decision nobody authorised is an opinion"
cp -r "$WORK/e2e" "$WORK/tr"; KD="$WORK/tr"
k record-object --object-id OBJ-0034 --type finding --namespace NS-0003 --actor ACT-0002 --surface "$B" --expected-version 0 --truth-state inferred --authority operator --payload "the next packet is probably projection migration"
accepted "the SAME claim recorded as \`inferred\` is accepted — the rule is about the label, not about silencing the model"
k record-object --object-id OBJ-0035 --type finding --namespace NS-0003 --actor ACT-0002 --surface "$B" --expected-version 0 --truth-state observed --authority operator --evidence ART-9999 --payload "cited to nothing"
refused_with "EVIDENCE-UNRESOLVED" "RED: an evidence id that resolves to nothing is refused — citing an artifact that does not exist is worse than citing none"

echo "== 17. No learned policy gains any authority =="
# The scan reads CODE, not commentary: this module's own header names the
# constructs it excludes, and a scan that counted the exclusion notice as an
# instance would be measuring prose.
grep -vE '^[[:space:]]*#' "$MK" > "$WORK/mk.code"
LEARN="$(grep -cE 'embedding|cosine|softmax|weights\[|classifier|similarity_score|model\.predict' "$WORK/mk.code" || true)"
[ "${LEARN:-0}" = "0" ] \
  && ok "the kernel module contains no embedding, similarity, weight, training or classifier construct" \
  || no "$LEARN learned-ranking construct(s) appear in the kernel module"
# Determinism is the operational form of the same claim: the same store compiled
# twice produces the same inclusion order, so no fitted or stochastic step is
# hiding inside the retrieval path.
cp -r "$WORK/e2e" "$WORK/d1"; KD="$WORK/d1"
k compile-context --id CTX-0050 --namespace NS-0003 --actor ACT-0003 --surface "$G" --objective same --budget 20
k compile-context --id CTX-0051 --namespace NS-0003 --actor ACT-0003 --surface "$G" --objective same --budget 20
A="$(awk -F'\t' '$1=="CTX-0050"{print $7"|"$8"|"$11"|"$12}' "$WORK/d1/memory_context_packages.tsv")"
Bx="$(awk -F'\t' '$1=="CTX-0051"{print $7"|"$8"|"$11"|"$12}' "$WORK/d1/memory_context_packages.tsv")"
{ [ -n "$A" ] && [ "$A" = "$Bx" ]; } \
  && ok "two compilations of the same store return an identical inclusion order, binding and omission set" \
  || no "the compiler is not deterministic"
# ...and the registry entries this packet added are invariants, not models. A
# Class D or R entry holding `gate` is exactly the promotion this refuses.
BADC=0
for c in memory.kernel_schema memory.context_package_identity memory.kernel_store_append suite.memory_kernel; do
  cl="$(awk -F': ' -v n="$c" '/^control: /{cur=$2} cur==n && /^class: /{print $2; exit}' "$REG")"
  case "$cl" in A) ;; "") BADC=$((BADC+1)); echo "      | not registered: $c" ;; *) BADC=$((BADC+1)); echo "      | $c is class $cl" ;; esac
done
[ "$BADC" = "0" ] \
  && ok "every control this kernel added is Class A — a hard invariant — and none is a learned or research functional" \
  || no "$BADC kernel control(s) are unregistered or are not Class A"

echo "== 18. The live stores are intact, reconciled, and this suite is wired in =="
# The LIVE kernel — the committed end-to-end fixture — is validated as data, and
# every projection under exports/ is regenerated and compared. This is also what
# proves the suite wrote nothing outside $WORK: the live stores still reconcile.
bash "$MK" validate > "$WORK/live.out" 2>&1; LRC=$?
{ [ "$LRC" = "0" ] && grep -qF '0 violations' "$WORK/live.out"; } \
  && ok "the LIVE committed kernel stores validate: $(sed -n 's/^memory-kernel: \([0-9].*\)$/\1/p' "$WORK/live.out" | head -1)" \
  || { no "the live kernel stores do not validate (exit $LRC)"; sed 's/^/      | /' "$WORK/live.out" | head -5; }
bash "$MK" reconcile > "$WORK/liver.out" 2>&1; RRC=$?
{ [ "$RRC" = "0" ] && grep -qF '0 divergent' "$WORK/liver.out"; } \
  && ok "every committed projection regenerates byte for byte from the canonical stores" \
  || { no "a committed projection has diverged (exit $RRC)"; sed 's/^/      | /' "$WORK/liver.out" | head -5; }
grep -qF 'chain_suite "tests/memory_kernel_tests.sh"' "$SRC/tests/build_os_tests.sh" \
  && ok "this suite is chained from the repository suite — it cannot be forgotten" \
  || no "this suite is not chained from tests/build_os_tests.sh"
# The kernel's write surface is censused. A durable write nobody registered is
# the census gap this repository built the mutator registry to close.
grep -qxF 'actor_or_tool: build-os/tools/memory-kernel.sh' "$SRC/build-os/registry/mutator_registry.txt" \
  && ok "the kernel's write surface owns a mutator census record" || no "the kernel writes durable state and is not censused as a mutator"
[ "$PASS" -ge 1 ] && ok "this suite ran $PASS assertion(s) before its own floor — it is not vacuous" \
                  || no "this suite asserted nothing"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
