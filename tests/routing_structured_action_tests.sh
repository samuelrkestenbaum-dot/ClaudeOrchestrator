#!/usr/bin/env bash
# Build OS — the STRUCTURED ROUTING ACTION (PACKET-0055-structured-routing-action):
# the deadlock-guard exception narrowed from a substring match over the ENTIRE raw
# hook JSON to an exactly-recognized routing invocation.
#
# WHY THIS SUITE EXISTS. PACKET-0054's deadlock guard matched the four routing-tool
# names as substrings of the whole PreToolUse event, checked BEFORE git
# classification. The reviewer proved three ungated shapes: a compound command
# (`route-task.sh …; git push --force`), a comment merely mentioning a routing
# tool, and a routing-tool path in a non-command JSON field. The contract stated
# that breadth honestly; the OPERATOR then ruled it "a real enforcement bypass,
# not merely a wording issue" and ordered this hardening BEFORE the
# real-repository pilot. The correction: extract the ACTUAL tool_input.command
# field, require the ENTIRE trimmed command to match one strict single-invocation
# shape (optional bash/sh — or node for mode-select.mjs — interpreter prefix,
# optional path prefix, exactly one routing tool, arguments free of every
# chaining/substitution metacharacter), fingerprint the pass, and let EVERYTHING
# else — including extraction failure — fall through to normal classification,
# toward GATING, never toward an ungated pass.
#
# Deterministic, local, model-free; fixtures in mktemp; the live receipt store is
# read and never written. The hook is driven directly with fabricated stdin JSON
# (hooks load at session start; the session shipping this change is not governed
# by it).
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GATE="$SRC/.claude/hooks/routing-gate.sh"
ROUTE="$SRC/build-os/tools/route-task.sh"
CONTRACT_LIVE="$SRC/build-os/memory/routing_contract_live.md"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# The descriptor builder (routing_enforcement_tests.sh's, verbatim) — fixture
# receipts come from the REAL issuer.
mkdesc(){
  local files="$1" tests="$2" sessions="$3" prior="$4" handoff="$5" cons="$6" vals="${7:-}"
  local f v
  printf '{'
  printf '"expected_files_changed":%s,"requires_tests":%s,"expected_session_count":%s,' "$files" "$tests" "$sessions"
  printf '"prior_context_required":%s,"handoff_required":%s,"consequence_level":"%s"' "$prior" "$handoff" "$cons"
  for f in irreversible_or_external_mutation high_blast_radius unclear_acceptance_criteria \
           security_or_compliance_consequence parallel_workstreams_benefit high_rework_history \
           nondeterministic_verification; do
    v=false
    case ",$vals," in *",$f,"*) v=true ;; esac
    printf ',"%s":%s' "$f" "$v"
  done
  printf '}'
}
D_DIRECT="$(mkdesc 1 false 1 false false low)"

mkroot(){ mkdir -p "$WORK/$1/build-os/packets/routing"; printf '%s' "$WORK/$1"; }
issue(){ # <root> <task-id> <descriptor>
  bash "$ROUTE" --task-id "$2" --description "structured-action fixture $2" --descriptor "$3" \
    --out "$1/build-os/packets/routing" >/dev/null 2>&1 || return 1
  find "$1/build-os/packets/routing" -maxdepth 1 -name "routing-$2-*.md" | sed -n '1p'
}
edit_json(){ printf '{"session_id":"s1","transcript_path":"/tmp/t","cwd":".","hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"/x/f.txt","old_string":"a","new_string":"b"}}'; }
# RAW command injection: $1 is embedded VERBATIM as the JSON string content, so a
# test can plant \n, ; or pre-escaped \" sequences exactly as a hook event
# would carry them.
bash_json(){ printf '{"session_id":"s1","transcript_path":"/tmp/t","cwd":".","hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"%s"}}' "$1"; }
# JSON-escape a real shell command for embedding (backslashes then quotes).
jesc(){ printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
rungate(){ # <root> <subcmd> <stdin> <outfile-stem> — exit code on stdout
  printf '%s' "$3" | ROUTING_GATE_ROOT="$1" bash "$GATE" "$2" >"$4.out" 2>"$4.err"; echo $?
}
statefile(){ printf '%s/build-os/packets/routing/live_state/%s.tsv' "$1" "$(basename "$2" .md)"; }
logfile(){ printf '%s/build-os/packets/routing/live_gate_log.tsv' "$1"; }

echo "== 1. The contract states the STRUCTURED action, its fingerprint, and the NEW honest bounds =="
grep -qi "structured routing action" "$CONTRACT_LIVE" \
  && ok "the contract names the structured routing action" || no "no structured-routing-action statement"
grep -q "tool_input.command" "$CONTRACT_LIVE" \
  && ok "the contract states the match runs on the extracted tool_input.command field, not the raw event" \
  || no "the contract does not name the command-field extraction"
grep -qi "toward gating" "$CONTRACT_LIVE" \
  && ok "extraction failure's named direction is TOWARD GATING, never an ungated pass" \
  || no "the extraction-failure direction is unstated"
grep -qi "sha256" "$CONTRACT_LIVE" \
  && ok "the contract states the ROUTING-TOOL-PASS fingerprint (sha256)" || no "the fingerprint is unstated"
grep -qi "wrapper script" "$CONTRACT_LIVE" && grep -qi "no longer passes ungated" "$CONTRACT_LIVE" \
  && ok "the contract states a wrapper that merely CALLS route-task.sh now gates as ordinary mutation — intended" \
  || no "the wrapper-now-gates consequence is unstated"
grep -q "Universal mutation-entry governance is complete for hooked Claude sessions; cross-provider and all-activity governance remain incomplete." "$CONTRACT_LIVE" \
  && ok "the operator's status framing sentence is present verbatim" \
  || no "the operator's status framing sentence is missing"
grep -qi "sh -c" "$CONTRACT_LIVE" && grep -qi "not a sandbox" "$CONTRACT_LIVE" \
  && ok "the unchanged bound survives: sh -c evasion of the MUTATION gate remains; not a sandbox" \
  || no "the pre-existing sh -c / not-a-sandbox bound was lost in the rewrite"
grep -qi "heuristic over JSON" "$CONTRACT_LIVE" \
  && ok "the extraction is itself named a heuristic over JSON-in-shell" \
  || no "the extraction's own heuristic nature is unstated"

echo "== 2. RED — ATTACK SHAPES: anything that merely MENTIONS a routing tool gates as mutation =="
RA="$(mkroot ra)"
i=0
while IFS= read -r atk; do
  [ -n "$atk" ] || continue
  i=$((i+1))
  RC="$(rungate "$RA" mutgate "$(bash_json "$atk")" "$WORK/atk$i")"
  [ "$RC" = "2" ] && ok "ATTACK BLOCKED (no receipt, exit 2): ${atk:0:70}" \
                  || no "ATTACK PASSED UNGATED (exit $RC): ${atk:0:70}"
done <<'ATTACKS'
build-os/tools/route-task.sh --task-id x --description y --descriptor z; git push --force
build-os/tools/route-task.sh --task-id x && git push origin main
build-os/tools/route-task.sh --task-id x & git push origin main
build-os/tools/routing-check.sh check | tee /tmp/x
git push origin main # route-task.sh
echo done # see build-os/tools/routing-check.sh
sh -c 'build-os/tools/route-task.sh --task-id x; git push'
bash -c \"build-os/tools/route-task.sh --task-id x; git push --force\"
sh -c build-os/tools/route-task.sh
eval build-os/tools/route-task.sh --task-id x
git push $(build-os/tools/route-task.sh)
git push `build-os/tools/route-task.sh`
build-os/tools/route-task.sh --task-id x\ngit push origin main
build-os/tools/route-task.sh --task-id x ; git push origin main
build-os/tools/route-task.sh --task-id x > /tmp/steal
build-os/tools/route-task.sh --task-id x < /tmp/feed
evil-route-task.sh --task-id x
ROUTED=1 build-os/tools/route-task.sh --task-id x
ATTACKS
# A routing tool named ONLY in a non-command JSON field, with a mutating command.
DESC_AFTER='{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"git push origin main","description":"run build-os/tools/route-task.sh first"}}'
RC="$(rungate "$RA" mutgate "$DESC_AFTER" "$WORK/atk-desc1")"
[ "$RC" = "2" ] && ok "ATTACK BLOCKED: routing tool mentioned only in the description field (after command)" \
                || no "description-field mention passed ungated (exit $RC)"
DESC_BEFORE='{"session_id":"s1","tool_name":"Bash","tool_input":{"description":"run build-os/tools/route-task.sh first","command":"git push origin main"}}'
RC="$(rungate "$RA" mutgate "$DESC_BEFORE" "$WORK/atk-desc2")"
[ "$RC" = "2" ] && ok "ATTACK BLOCKED: description-field mention placed BEFORE the command field" \
                || no "description-before-command mention passed ungated (exit $RC)"
DESC_DECOY='{"session_id":"s1","tool_name":"Bash","tool_input":{"description":"see \"command\":\"build-os/tools/route-task.sh\" here","command":"git push origin main"}}'
RC="$(rungate "$RA" mutgate "$DESC_DECOY" "$WORK/atk-desc3")"
[ "$RC" = "2" ] && ok "ATTACK BLOCKED: an escaped-quote decoy planting \"command\":\"route-task.sh\" inside a string value" \
                || no "the escaped-quote decoy defeated command-field extraction (exit $RC)"
grep -q "ROUTING-TOOL-PASS" "$(logfile "$RA")" 2>/dev/null \
  && no "an attack shape reached ROUTING-TOOL-PASS — the ledger mislabels hostile events" \
  || ok "ZERO attack shapes reached ROUTING-TOOL-PASS — only exact invocations carry that label now"

echo "== 3. GREEN — the LEGITIMATE invocation set passes ungated, logged =="
RB="$(mkroot rb)"
NLEGIT=0
while IFS= read -r legit; do
  [ -n "$legit" ] || continue
  NLEGIT=$((NLEGIT+1))
  RC="$(rungate "$RB" mutgate "$(bash_json "$(jesc "$legit")")" "$WORK/legit$NLEGIT")"
  [ "$RC" = "0" ] && ok "LEGIT PASSES (exit 0): ${legit:0:70}" \
                  || no "LEGIT BLOCKED — the guard re-created the deadlock (exit $RC): ${legit:0:70}"
done <<LEGIT
build-os/tools/route-task.sh --task-id x --description y --descriptor z
route-task.sh --task-id bare-name
bash build-os/tools/route-task.sh --task-id x --description y --descriptor z
sh build-os/tools/routing-check.sh check
bash $SRC/build-os/tools/routing-check.sh check
./build-os/tools/record-degradation.sh --receipt r.md --reason because
build-os/tools/record-degradation.sh --receipt r.md --reason "stated reason, quoted"
node build-os/tools/mode-select.mjs '{}'
build-os/tools/mode-select.mjs '{}'
build-os/tools/route-task.sh --task-id q1 --description "small routed task" --descriptor '$D_DIRECT'
LEGIT
NPASS="$(grep -c "ROUTING-TOOL-PASS" "$(logfile "$RB")" 2>/dev/null || true)"
[ "${NPASS:-0}" = "$NLEGIT" ] \
  && ok "all $NLEGIT legitimate invocations are logged ROUTING-TOOL-PASS (ungated is not untraced)" \
  || no "ROUTING-TOOL-PASS rows: ${NPASS:-0}, expected $NLEGIT"

echo "== 4. THE FINGERPRINT — the ledger alone distinguishes 'ran route-task.sh' from anything else =="
RC1="$(mkroot rc1)"
CMD1='build-os/tools/route-task.sh --task-id fp1 --description y --descriptor z'
CMD2='build-os/tools/routing-check.sh check'
rungate "$RC1" mutgate "$(bash_json "$(jesc "$CMD1")")" "$WORK/fp1" >/dev/null
rungate "$RC1" mutgate "$(bash_json "$(jesc "$CMD2")")" "$WORK/fp2" >/dev/null
LOG1="$(grep "ROUTING-TOOL-PASS" "$(logfile "$RC1")" | sed -n '1p')"
LOG2="$(grep "ROUTING-TOOL-PASS" "$(logfile "$RC1")" | sed -n '2p')"
printf '%s' "$LOG1" | grep -q "routing_tool=route-task.sh" \
  && ok "the pass row names WHICH tool matched (routing_tool=route-task.sh)" \
  || no "no routing_tool= field in the pass row: $LOG1"
printf '%s' "$LOG2" | grep -q "routing_tool=routing-check.sh" \
  && ok "...and a different tool is named as itself (routing_tool=routing-check.sh)" \
  || no "second pass row misnames its tool: $LOG2"
WANT1="$(printf '%s' "$CMD1" | sha256sum | cut -c1-12)"
printf '%s' "$LOG1" | grep -q "sha256=$WANT1" \
  && ok "the pass row carries sha256=$WANT1 — the first 12 hex chars of the EXACT command's digest, independently recomputed" \
  || no "the recorded sha256 does not match the recomputed digest $WANT1: $LOG1"
SHA1="$(printf '%s' "$LOG1" | grep -oE 'sha256=[0-9a-f]{12}' | head -n1)"
SHA2="$(printf '%s' "$LOG2" | grep -oE 'sha256=[0-9a-f]{12}' | head -n1)"
[ -n "$SHA1" ] && [ -n "$SHA2" ] && [ "$SHA1" != "$SHA2" ] \
  && ok "two different commands produce two different fingerprints — the ledger can tell them apart" \
  || no "fingerprints missing or identical across different commands ($SHA1 vs $SHA2)"
printf '%s' "$LOG1" | grep -q "cmd=build-os/tools/route-task.sh --task-id fp1" \
  && ok "the pass row carries a readable command excerpt (cmd=...)" || no "no cmd= excerpt: $LOG1"
awk -F'\t' 'NF!=5{bad=1} END{exit bad}' "$(logfile "$RC1")" \
  && ok "every log row still carries exactly 5 tab-separated fields — the fingerprint stayed TSV-safe" \
  || no "a log row broke the 5-field TSV shape"
LONG="build-os/tools/route-task.sh --task-id long --description $(head -c 200 /dev/zero | tr '\0' 'a')"
rungate "$RC1" mutgate "$(bash_json "$(jesc "$LONG")")" "$WORK/fp3" >/dev/null
EXC="$(grep "ROUTING-TOOL-PASS" "$(logfile "$RC1")" | sed -n '3p' | grep -oE 'cmd=[^\t]*' | sed 's/^cmd=//')"
EXCLEN="${#EXC}"
[ -n "$EXC" ] && [ "$EXCLEN" -le 80 ] \
  && ok "the excerpt is truncated to <= 80 chars ($EXCLEN) — a fingerprint, not a transcript" \
  || no "the excerpt is missing or overlong ($EXCLEN chars)"
# With a receipt OPEN, the state-file row carries the same fingerprint.
RC2="$(mkroot rc2)"
RECC="$(issue "$RC2" T-FPRINT "$D_DIRECT")"
rungate "$RC2" mutgate "$(bash_json "$(jesc "$CMD2")")" "$WORK/fp4" >/dev/null
SFC="$(statefile "$RC2" "$RECC")"
awk -F'\t' '$2=="routing_tool_pass"' "$SFC" 2>/dev/null | grep -q "routing_tool=routing-check.sh" \
  && ok "the state-file routing_tool_pass row carries the tool identity too" \
  || no "the state row lost the tool identity"
awk -F'\t' '$2=="routing_tool_pass"' "$SFC" 2>/dev/null | grep -qE "sha256=[0-9a-f]{12}" \
  && ok "...and the sha256 fingerprint (both ledgers agree on what ran)" \
  || no "the state row lost the fingerprint"
awk -F'\t' 'NF!=3 && $1!="label" && !/^#/{bad=1} END{exit bad}' "$SFC" \
  && ok "the state file's 3-field TSV shape survived the fingerprint" \
  || no "a state row broke the 3-field TSV shape"

echo "== 5. RECOVERY END-TO-END — the refusal's own command classifies routing_tool, executes, and unblocks =="
RD="$(mkroot rd)"
RC="$(rungate "$RD" mutgate "$(edit_json)" "$WORK/rec1")"
[ "$RC" = "2" ] && ok "a no-receipt Edit is blocked (the boundary is live)" || no "unrouted Edit passed (exit $RC)"
RCMD="$(sed -n 's/^ *\(build-os\/tools\/route-task\.sh --task-id quick-task-1 .*\)$/\1/p' "$WORK/rec1.err" | head -n1)"
[ -n "$RCMD" ] && ok "the refusal carries an extractable recovery command" || no "no extractable recovery command in the refusal"
RC="$(rungate "$RD" mutgate "$(bash_json "$(jesc "$RCMD")")" "$WORK/rec2")"
[ "$RC" = "0" ] && ok "the refusal's OWN recovery command classifies routing_tool (exit 0) — quotes, braces, colons and commas in the 13-field descriptor all pass" \
               || no "the refusal's own recovery command is blocked (exit $RC) — the guard bricked its recovery path"
grep -q "ROUTING-TOOL-PASS" "$(logfile "$RD")" 2>/dev/null \
  && ok "...and is logged ROUTING-TOOL-PASS" || no "the recovery pass left no log row"
WANTR="$(printf '%s' "$RCMD" | sha256sum | cut -c1-12)"
grep "ROUTING-TOOL-PASS" "$(logfile "$RD")" | grep -q "sha256=$WANTR" \
  && ok "the fingerprint hashes the DECODED command exactly (recomputed over the refusal's own text: $WANTR)" \
  || no "the recovery command's fingerprint does not match its own text"
# EXECUTE it. The example writes to the live store by default, so ONE clean
# argument (--out, itself re-classified below) redirects the receipt into the
# scratch root; the command is otherwise the refusal's own text, verbatim.
RCMD_OUT="$RCMD --out $RD/build-os/packets/routing"
RC="$(rungate "$RD" mutgate "$(bash_json "$(jesc "$RCMD_OUT")")" "$WORK/rec3")"
[ "$RC" = "0" ] && ok "the recovery command with the test's --out redirection still classifies routing_tool" \
               || no "--out redirection broke the classification (exit $RC)"
( cd "$SRC" && eval "$RCMD_OUT" ) >"$WORK/rec-exec.out" 2>&1
find "$RD/build-os/packets/routing" -maxdepth 1 -name 'routing-quick-task-1-*.md' | grep -q . \
  && ok "EXECUTED: the recovery command issues a real receipt into the scratch store" \
  || no "no receipt appeared after executing the recovery command ($(head -n1 "$WORK/rec-exec.out" 2>/dev/null))"
RC="$(rungate "$RD" mutgate "$(edit_json)" "$WORK/rec4")"
[ "$RC" = "0" ] && ok "the NEXT mutation-capable call passes — recovery is one command, and it cannot carry unrelated mutations" \
               || no "mutation still blocked after recovery (exit $RC)"

echo "== 6. A compound command under an OPEN receipt lands MUTATION-capable, never routing_tool =="
RE="$(mkroot re)"
RECE="$(issue "$RE" T-COMPOUND "$D_DIRECT")"
RC="$(rungate "$RE" mutgate "$(bash_json 'build-os/tools/route-task.sh --task-id x; git push --force')" "$WORK/comp1")"
[ "$RC" = "0" ] && ok "under an open receipt the compound is ADMITTED (routed work) rather than refused" \
               || no "compound under open receipt blocked (exit $RC)"
SFE="$(statefile "$RE" "$RECE")"
awk -F'\t' '$2=="mutation_event"' "$SFE" 2>/dev/null | grep -q . \
  && ok "...and is counted as a mutation_event — the ledger shows mutation, not a routing pass" \
  || no "the admitted compound left no mutation_event row"
awk -F'\t' '$2=="routing_tool_pass"' "$SFE" 2>/dev/null | grep -q . \
  && no "the compound was ALSO recorded as routing_tool_pass — the mislabel survives" \
  || ok "no routing_tool_pass row for the compound — ROUTING-TOOL-PASS now means exactly what it says"
grep -q "ALLOW-MUTATION" "$(logfile "$RE")" 2>/dev/null \
  && ok "the log row is ALLOW-MUTATION (mutation-capable classification held)" \
  || no "no ALLOW-MUTATION row for the admitted compound"

echo "== 7. STORE-UNAVAILABLE IS NOT A BRICK — fail-open with the trace on the 0053 mechanics =="
# (a) The existing doctrine holds: garbage stdin fails open.
RF="$(mkroot rf)"
RC="$(rungate "$RF" mutgate "utter garbage, not json" "$WORK/su-a")"
[ "$RC" = "0" ] && ok "(a) unparseable stdin FAILS OPEN (exit 0) — unchanged doctrine" \
               || no "(a) the gate failed CLOSED on garbage stdin (exit $RC)"
# (b) The store path exists but is NOT a directory: open_receipt cannot read it
# and route-task.sh could never write a receipt — a block here would be a dead
# end whose own recovery command cannot succeed. The gate must FAIL OPEN, with
# the row surviving on stderr (the store is unwritable, so the log file cannot
# carry it — the 0053 UNLOGGED fallback).
RG_DIR="$WORK/su-b"; mkdir -p "$RG_DIR/build-os/packets"; printf 'not a dir' > "$RG_DIR/build-os/packets/routing"
RC="$(rungate "$RG_DIR" mutgate "$(edit_json)" "$WORK/su-b1")"
[ "$RC" = "0" ] && ok "(b) mutation with an UNREADABLE store FAILS OPEN (exit 0) — no dead end" \
               || no "(b) BRICK: the gate hard-blocked (exit $RC) while the recovery command could never succeed"
grep -q "FAIL-OPEN-STORE-UNAVAILABLE" "$WORK/su-b1.err" \
  && ok "(b) the fail-open is TRACED: FAIL-OPEN-STORE-UNAVAILABLE row emitted" \
  || no "(b) the store-unavailable fail-open left no trace"
grep -q "UNLOGGED(store unwritable)" "$WORK/su-b1.err" \
  && ok "(b) ...and the trace rode the stderr fallback (UNLOGGED(store unwritable)) exactly as layer 4 states" \
  || no "(b) the trace did not use the documented stderr fallback"
RC="$(rungate "$RG_DIR" mutgate "$(bash_json 'build-os/tools/route-task.sh --task-id x --description y --descriptor z')" "$WORK/su-b2")"
[ "$RC" = "0" ] && ok "(b) the recovery command itself still passes under an unavailable store (classification precedes the store)" \
               || no "(b) the recovery command is blocked under an unavailable store (exit $RC)"
# (c) The store is merely MISSING with a creatable parent: recovery is viable,
# so the gate still BLOCKS — and the block is escapable by the one command.
RH_DIR="$WORK/su-c"; mkdir -p "$RH_DIR"
RC="$(rungate "$RH_DIR" mutgate "$(edit_json)" "$WORK/su-c1")"
[ "$RC" = "2" ] && ok "(c) a merely-MISSING store still blocks (recovery is viable, so the boundary holds)" \
               || no "(c) a missing-but-creatable store failed open (exit $RC) — the boundary leaks"
issue "$RH_DIR" T-SU-RECOVER "$D_DIRECT" >/dev/null \
  && ok "(c) the recovery command succeeds against that root (the receipt store is creatable)" \
  || no "(c) recovery could not issue a receipt — (c) is a brick after all"
RC="$(rungate "$RH_DIR" mutgate "$(edit_json)" "$WORK/su-c2")"
[ "$RC" = "0" ] && ok "(c) ...and the next mutation passes: block -> one command -> unblocked, never a dead end" \
               || no "(c) mutation still blocked after recovery (exit $RC)"

echo "== 8. The neighbouring classes are undisturbed =="
RI="$(mkroot ri)"
RC="$(rungate "$RI" mutgate "$(bash_json 'git status')" "$WORK/nb1")"
[ "$RC" = "0" ] && ok "read-only git still passes ungated (GIT-READONLY-PASS class intact)" \
               || no "git status was blocked (exit $RC)"
RC="$(rungate "$RI" mutgate "$(bash_json 'git push origin main')" "$WORK/nb2")"
[ "$RC" = "2" ] && ok "mutating git is still blocked without a receipt" || no "git push passed unrouted (exit $RC)"
RC="$(rungate "$RI" mutgate "$(edit_json)" "$WORK/nb3")"
[ "$RC" = "2" ] && ok "Edit stays unconditional mutation — non-Bash tools never reach the routing-action check" \
               || no "Edit passed unrouted (exit $RC)"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
