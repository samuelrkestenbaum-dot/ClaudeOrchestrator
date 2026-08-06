#!/usr/bin/env bash
# Context Compiler — CONTEXT-MODE SEAM tests (the task-entry seam, EXP-0004).
#
# WHAT THIS PINS. build-os/compiler/entry/ is the seam where a task acquires its
# STARTING context, and it exists to make AB_PREREGISTRATION AMENDMENT 2
# mechanical: in arm B the compiled capsule REPLACES the broad-context delivery.
# It does not supplement it. A compression thesis cannot be tested by adding
# bytes, so a task whose arm B starts with the capsule AND the ordinary broad
# context is not a measurement — it is a confound, and it is excluded rather
# than repaired.
#
# The adversarial set is the point. Every one of these must be REFUSED or
# MARKED-AND-EXCLUDED, never silently accepted and never silently fixed:
#
#   broad context + capsule            an undeclared initial artifact
#   transcript + capsule               duplicated capsule content
#   repository summary + capsule       a mutated / mutable prefix
#   capsule digest mismatch            starting bytes != prefix + capsule
#
# It also pins the three properties that keep the experiment honest in the other
# direction:
#
#   * EXPANSION IS STILL PERMITTED AND MEASURED, and cannot rewrite history —
#     the starting-context record's digest is unchanged after expansion events
#     are appended to a SEAM 3 ledger elsewhere.
#   * AN INCOMPLETE CAPSULE FAILS HONESTLY — nothing in this seam tops it up,
#     rescues it, or quietly widens its starting context. It is allowed to lose
#     through expansion cost, rework and acceptance loss, which is what
#     AB_PREREGISTRATION's outcome 4 exists to record.
#   * SMALLER IS NOT A WIN BY ITSELF — grep-negative over every emitted record
#     and over the sources: no field derives a score, a verdict or a saving from
#     byte count anywhere in these tools.
#
# INERTNESS is the operator's required proof and is section 8: the live runtime
# (.claude/hooks, .claude/settings.json, build-os/tools, build-os/runtime, and
# every compiler directory except entry/) must contain ZERO references to these
# entry points and zero occurrences of the mode name. A positive control proves
# the grep can find the string when it is there.
#
# NOT PINNED, AND SAID RATHER THAN FAKED: provider-added hidden context (system
# prompts, injected reminders, tool preambles) is NOT OBSERVABLE from anything
# this seam can measure. There is therefore no test for it here. The record
# carries that limitation in words instead, and section 7 asserts the words are
# present — an admitted blind spot, not a green check over an unmeasured thing.
#
# VACUITY GUARDS. Every grep-negative is paired with a positive: the scanned
# corpus is asserted non-empty first, and section 8 greps for a string that IS
# present to prove the scan works at all.
#
# FIXTURES are fabricated in mktemp. The only files read from the repository are
# the three tools under test and the compiler's own immutable-prefix constant
# (READ-ONLY). Nothing outside mktemp is written. No network. Deterministic:
# every invocation pins --now and --repo-commit.
#
# Exits non-zero if any assertion fails, and prints a final
# "==== RESULT: N passed, M failed ====" line.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENTRY="$SRC/build-os/compiler/entry"
CM="$ENTRY/context-mode.mjs"
AD="$ENTRY/admit.mjs"
AC="$ENTRY/activation.mjs"
PREFIX_MOD="$SRC/build-os/compiler/compile/capsule-prefix.mjs"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }
eq(){ if [ "$2" = "$3" ]; then ok "$1"; else no "$1 — got [$2] want [$3]"; fi; }
ne(){ if [ "$2" != "$3" ]; then ok "$1"; else no "$1 — got [$2] and must differ"; fi; }
has(){ if grep -qF -- "$3" <<<"$2"; then ok "$1"; else no "$1 — [$3] absent from output"; fi; }
hasnt(){ if grep -qF -- "$3" <<<"$2"; then no "$1 — [$3] present and must not be"; else ok "$1"; fi; }
ge(){ if [ "$2" -ge "$3" ] 2>/dev/null; then ok "$1"; else no "$1 — got [$2] want >= [$3]"; fi; }
nonempty(){ if [ -n "$2" ]; then ok "$1"; else no "$1 — was empty"; fi; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
RECORDS="$WORK/records"
mkdir -p "$RECORDS"
NREC=0

sha(){ node -e 'const c=require("crypto"),f=require("fs");process.stdout.write(c.createHash("sha256").update(f.readFileSync(process.argv[1])).digest("hex"))' "$1"; }
nbytes(){ wc -c <"$1" | tr -d ' '; }
q(){ node -e '
const o=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));
let v=o; for(const k of process.argv[2].split(".")){ v=(v===null||v===undefined)?undefined:v[k]; }
process.stdout.write(v===undefined?"<missing>":(v===null?"null":(typeof v==="object"?JSON.stringify(v):String(v))));' "$1" "$2"; }

# Run context-mode.mjs, keeping every emitted record in a corpus for the
# grep-negative section (which is worthless against an empty corpus).
runcm(){ OUT="$(node "$CM" "$@" 2>"$WORK/err")"; RC=$?; ERRTXT="$(cat "$WORK/err")"; }
keep(){ if [ -f "$1" ]; then NREC=$((NREC+1)); cp "$1" "$RECORDS/rec_$NREC.json"; fi; }

echo "== 0. fixtures =="
node --input-type=module -e "
import fs from 'node:fs';
import { IMMUTABLE_PREFIX, PREFIX_SHA256 } from '$PREFIX_MOD';
fs.writeFileSync('$WORK/prefix.txt', IMMUTABLE_PREFIX);
fs.writeFileSync('$WORK/prefix.sha', PREFIX_SHA256);
" 2>"$WORK/fixerr" || true
if [ -s "$WORK/prefix.txt" ]; then ok "immutable prefix fixture extracted from the compiler constant"; else no "immutable prefix fixture — $(cat "$WORK/fixerr")"; fi
PSHA="$(cat "$WORK/prefix.sha" 2>/dev/null || echo MISSING)"
PBYTES="$(nbytes "$WORK/prefix.txt" 2>/dev/null || echo 0)"
SEED="1111111111111111111111111111111111111111"
NOW="2026-01-01T00:00:00.000Z"

# A SEAM 2 capsule declaring the canonical prefix digest in provenance.
node -e '
const fs=require("fs");
const c={capsule_version:1,task_id:"T-1",compiled_at:"2026-01-01T00:00:00Z",index_version:1,
  repo_head:process.argv[3],objective:"do the thing",acceptance:["tests pass"],
  relevant_files:[{path:"src/a.mjs",why:"named as a seed file",symbols:["a"]}],
  dependency_neighborhood:[],constraints:[],failed_approaches:[],
  allowed_mutation_surface:["src/**"],authority:{mode:"light",receipt:"none"},
  verification:{commands:["node t"],expected:"ok"},artifact_refs:[],
  provenance:{included_because:{"src/a.mjs":"named as a seed file"},excluded_notable:[],prefix_sha256:process.argv[2]}};
fs.writeFileSync(process.argv[1], JSON.stringify(c,null,2)+"\n");' "$WORK/capsule.json" "$PSHA" "$SEED"
CSHA="$(sha "$WORK/capsule.json")"
CBYTES="$(nbytes "$WORK/capsule.json")"
PERMITTED=$((PBYTES + CBYTES))

# A thin-but-legal capsule: admits nothing. Allowed to fail honestly downstream.
node -e '
const fs=require("fs");
const c={capsule_version:1,task_id:"T-thin",compiled_at:"2026-01-01T00:00:00Z",index_version:1,
  repo_head:process.argv[3],objective:"do the thing",acceptance:[],relevant_files:[],
  dependency_neighborhood:[],constraints:[],failed_approaches:[],allowed_mutation_surface:[],
  authority:{mode:"light",receipt:"none"},verification:{commands:[],expected:""},artifact_refs:[],
  provenance:{included_because:{},excluded_notable:[],prefix_sha256:process.argv[2]}};
fs.writeFileSync(process.argv[1], JSON.stringify(c,null,2)+"\n");' "$WORK/thin.json" "$PSHA" "$SEED"

printf '{"task_id":"T-1","capsule_sha256":null,"initial_artifacts":[]}\n' >"$WORK/task.json"
printf '{"task_id":"T-2","capsule_sha256":null,"initial_artifacts":["%s"]}\n' "$WORK/declared.txt" >"$WORK/task_decl.json"
printf '{"task_id":"T-3","capsule_sha256":"%s","initial_artifacts":[]}\n' \
  "0000000000000000000000000000000000000000000000000000000000000000" >"$WORK/task_badsha.json"

printf 'THE WHOLE REPOSITORY, pasted: file a, file b, file c ...\n' >"$WORK/broad.txt"
printf 'USER: hi\nASSISTANT: hi\nUSER: fix it\n' >"$WORK/transcript.txt"
printf 'Repository summary: 415 files, shell-dominant, see README.\n' >"$WORK/reposummary.txt"
printf 'declared but still not permitted\n' >"$WORK/declared.txt"
printf 'nobody declared this one\n' >"$WORK/undeclared.txt"
cp "$WORK/prefix.txt" "$WORK/prefix_mutated.txt"; printf 'X' >>"$WORK/prefix_mutated.txt"

echo
echo "== 1. the tools exist and refuse nonsense =="
[ -f "$CM" ] && ok "context-mode.mjs exists" || no "context-mode.mjs missing"
[ -f "$AD" ] && ok "admit.mjs exists" || no "admit.mjs missing"
[ -f "$AC" ] && ok "activation.mjs exists" || no "activation.mjs missing"
runcm --help; eq "context-mode --help exits 0" "$RC" "0"; has "help names both modes" "$OUT" "compiled_context"
has "help names standard_context" "$OUT" "standard_context"
runcm prepare --mode turbo_context --task "$WORK/task.json" --out "$WORK/x.json"
eq "an unknown mode is a usage error (exit 2)" "$RC" "2"
has "the unknown mode is named in the refusal" "$ERRTXT" "turbo_context"
runcm prepare --mode compiled_context --task "$WORK/task.json" --out "$WORK/x.json"
eq "compiled_context without a capsule is refused (exit 2)" "$RC" "2"
has "the missing capsule is named" "$ERRTXT" "--capsule"

echo
echo "== 2. compiled_context, the clean path (AMENDMENT 2 satisfied) =="
R="$WORK/clean.json"
runcm prepare --mode compiled_context --task "$WORK/task.json" --capsule "$WORK/capsule.json" \
  --prefix "$WORK/prefix.txt" --repo-commit "$SEED" --now "$NOW" --out "$R"
keep "$R"
eq "a conforming compiled_context task exits 0" "$RC" "0"
eq "mode is recorded" "$(q "$R" mode)" "compiled_context"
eq "confounded is false" "$(q "$R" confounded)" "false"
eq "prefix sha256 is carried" "$(q "$R" prefix_sha256)" "$PSHA"
eq "prefix byte count is carried" "$(q "$R" prefix_bytes)" "$PBYTES"
eq "capsule sha256 is carried" "$(q "$R" capsule_sha256)" "$CSHA"
eq "capsule byte count is carried" "$(q "$R" capsule_bytes)" "$CBYTES"
eq "starting-context bytes == prefix + capsule" "$(q "$R" starting_context_bytes)" "$PERMITTED"
eq "permitted bytes == prefix + capsule" "$(q "$R" permitted_starting_context_bytes)" "$PERMITTED"
eq "the non-permitted-initial-context boolean is present and false" "$(q "$R" non_permitted_initial_context_supplied)" "false"
eq "the repository commit is carried" "$(q "$R" repo_commit)" "$SEED"
eq "the timestamp is carried" "$(q "$R" recorded_at)" "$NOW"
eq "the disposition is admitted" "$(q "$R" disposition)" "admitted"
eq "the prefix is verified immutable" "$(q "$R" prefix_immutable)" "true"

echo
echo "== 3. the adversarial set: refuse or confound, never silently accept =="
adverse(){ # name, expected-code, args...
  local name="$1"; local code="$2"; shift 2
  local rec="$WORK/adv.json"; rm -f "$rec"
  runcm prepare "$@" --out "$rec"; keep "$rec"
  eq "$name — exits non-zero (3 = confounded)" "$RC" "3"
  if [ -f "$rec" ]; then ok "$name — the record is still emitted (marked, not suppressed)"; else no "$name — no record emitted"; fi
  eq "$name — confounded is true" "$(q "$rec" confounded)" "true"
  has "$name — the reason is named [$code]" "$(q "$rec" confound_reasons)" "$code"
  has "$name — stderr says EXCLUDED" "$ERRTXT" "excluded"
  has "$name — stderr says it was NOT repaired" "$ERRTXT" "NOT been repaired"
  has "$name — the disposition says excluded, NOT repaired" "$(q "$rec" disposition)" "NOT repaired"
}

adverse "broad context + capsule" "non_permitted_initial_context" \
  --mode compiled_context --task "$WORK/task.json" --capsule "$WORK/capsule.json" \
  --prefix "$WORK/prefix.txt" --initial "$WORK/broad.txt" --initial-label broad_context \
  --repo-commit "$SEED" --now "$NOW"

adverse "transcript + capsule" "non_permitted_initial_context" \
  --mode compiled_context --task "$WORK/task.json" --capsule "$WORK/capsule.json" \
  --prefix "$WORK/prefix.txt" --initial "$WORK/transcript.txt" --initial-label transcript \
  --repo-commit "$SEED" --now "$NOW"

adverse "repository summary + capsule" "non_permitted_initial_context" \
  --mode compiled_context --task "$WORK/task.json" --capsule "$WORK/capsule.json" \
  --prefix "$WORK/prefix.txt" --initial "$WORK/reposummary.txt" --initial-label repository_summary \
  --repo-commit "$SEED" --now "$NOW"

adverse "an undeclared initial artifact" "undeclared_initial_artifact" \
  --mode compiled_context --task "$WORK/task_decl.json" --capsule "$WORK/capsule.json" \
  --prefix "$WORK/prefix.txt" --initial "$WORK/undeclared.txt" \
  --repo-commit "$SEED" --now "$NOW"

adverse "duplicated capsule content" "duplicated_capsule_content" \
  --mode compiled_context --task "$WORK/task.json" --capsule "$WORK/capsule.json" \
  --capsule "$WORK/capsule.json" --prefix "$WORK/prefix.txt" \
  --repo-commit "$SEED" --now "$NOW"

adverse "a mutated prefix" "mutable_prefix" \
  --mode compiled_context --task "$WORK/task.json" --capsule "$WORK/capsule.json" \
  --prefix "$WORK/prefix_mutated.txt" --repo-commit "$SEED" --now "$NOW"

adverse "capsule digest mismatch" "capsule_digest_mismatch" \
  --mode compiled_context --task "$WORK/task_badsha.json" --capsule "$WORK/capsule.json" \
  --prefix "$WORK/prefix.txt" --repo-commit "$SEED" --now "$NOW"

# Starting bytes measured from what the harness ACTUALLY sent, per AMENDMENT 2's
# mechanical check, rather than from what this tool would have assembled.
cat "$WORK/prefix.txt" "$WORK/capsule.json" "$WORK/broad.txt" >"$WORK/sent_wide.txt"
adverse "starting bytes != prefix + capsule" "starting_bytes_mismatch" \
  --mode compiled_context --task "$WORK/task.json" --capsule "$WORK/capsule.json" \
  --prefix "$WORK/prefix.txt" --starting-context "$WORK/sent_wide.txt" \
  --repo-commit "$SEED" --now "$NOW"

# A declared-but-not-permitted artifact is STILL a confound (AMENDMENT 2 permits
# none), but it is not the "undeclared" one — the two codes are distinguished.
RD="$WORK/declared_case.json"
runcm prepare --mode compiled_context --task "$WORK/task_decl.json" --capsule "$WORK/capsule.json" \
  --prefix "$WORK/prefix.txt" --initial "$WORK/declared.txt" --repo-commit "$SEED" --now "$NOW" --out "$RD"
keep "$RD"
eq "a DECLARED extra artifact is still confounded" "$(q "$RD" confounded)" "true"
has "declared extra fires non_permitted_initial_context" "$(q "$RD" confound_reasons)" "non_permitted_initial_context"
hasnt "declared extra does NOT fire undeclared_initial_artifact" "$(q "$RD" confound_reasons)" "undeclared_initial_artifact"

# The prefix delivered twice (a rendered capsule carrying its own prefix, handed
# in alongside a prefix segment) double-counts and is caught.
cat "$WORK/prefix.txt" "$WORK/capsule.json" >"$WORK/rendered.md"
RP="$WORK/dupprefix.json"
runcm prepare --mode compiled_context --task "$WORK/task.json" --capsule "$WORK/rendered.md" \
  --prefix "$WORK/prefix.txt" --repo-commit "$SEED" --now "$NOW" --out "$RP"
keep "$RP"
eq "a prefix delivered inside the capsule too is confounded" "$(q "$RP" confounded)" "true"
has "duplicated prefix content is named" "$(q "$RP" confound_reasons)" "duplicated_prefix_content"

echo
echo "== 4. standard_context preserves today's behaviour exactly =="
RS="$WORK/std.json"
runcm prepare --mode standard_context --task "$WORK/task.json" --repo-commit "$SEED" --now "$NOW" --out "$RS"
keep "$RS"
eq "standard_context needs no capsule (exit 0)" "$RC" "0"
eq "standard_context is not confounded" "$(q "$RS" confounded)" "false"
eq "standard_context records a null capsule digest" "$(q "$RS" capsule_sha256)" "null"
eq "standard_context records its own starting bytes" "$(q "$RS" starting_context_bytes)" "0"
RS2="$WORK/std_broad.json"
runcm prepare --mode standard_context --task "$WORK/task.json" --initial "$WORK/broad.txt" --initial-label broad_context \
  --initial "$WORK/transcript.txt" --initial-label transcript --repo-commit "$SEED" --now "$NOW" --out "$RS2"
keep "$RS2"
eq "standard_context with broad context still exits 0" "$RC" "0"
eq "breadth NEVER confounds standard_context — that IS its contract" "$(q "$RS2" confounded)" "false"
eq "standard_context reports no non-permitted context" "$(q "$RS2" non_permitted_initial_context_supplied)" "false"
SBYTES=$(( $(nbytes "$WORK/broad.txt") + $(nbytes "$WORK/transcript.txt") ))
eq "standard_context measures its starting bytes for comparison" "$(q "$RS2" starting_context_bytes)" "$SBYTES"
eq "standard_context does not compile" "$(q "$RS2" compiled)" "false"
RL="$WORK/leak.json"
runcm prepare --mode standard_context --task "$WORK/task.json" --capsule "$WORK/capsule.json" \
  --repo-commit "$SEED" --now "$NOW" --out "$RL"
keep "$RL"
eq "a capsule leaking into arm A is confounded (exit 3)" "$RC" "3"
has "the leak is named as its own stop condition" "$(q "$RL" confound_reasons)" "capsule_leaked_into_standard_context"

echo
echo "== 5. expansion stays permitted, measured, and cannot rewrite the record =="
eq "expansion after start is permitted" "$(q "$R" expansion_after_start.permitted)" "true"
eq "expansion is NOT folded into the initial-context record" "$(q "$R" expansion_after_start.included_in_this_record)" "false"
has "the record names where expansion is measured" "$(q "$R" expansion_after_start.measured_by)" "expand.mjs"
D1="$(sha "$R")"
LEDGER="$WORK/events.tsv"
printf 'ts\ttask_id\trequest\tgranted\tbytes\treason\n' >"$LEDGER"
printf '2026-01-01T00:05:00Z\tT-1\tneed_file(src/a.mjs)\ty\t812\tok\n' >>"$LEDGER"
printf '2026-01-01T00:06:00Z\tT-1\tneed_callers(a)\ty\t410\tok\n' >>"$LEDGER"
D2="$(sha "$R")"
eq "appending expansion events elsewhere leaves the record digest unchanged" "$D2" "$D1"
ge "the expansion ledger really did grow" "$(wc -l <"$LEDGER" | tr -d ' ')" "3"
R2="$WORK/clean_again.json"
runcm prepare --mode compiled_context --task "$WORK/task.json" --capsule "$WORK/capsule.json" \
  --prefix "$WORK/prefix.txt" --repo-commit "$SEED" --now "$NOW" --out "$R2"
eq "the record is deterministic (same inputs, byte-identical)" "$(sha "$R2")" "$D1"
SRCTXT="$(cat "$CM" "$AD" "$AC")"
nonempty "the three sources were read for the structural greps" "$SRCTXT"
hasnt "no source appends to any file — a written record cannot be amended later" "$SRCTXT" "appendFileSync"
has "the record is written once, whole" "$SRCTXT" "writeFileSync"

echo
echo "== 6. an incomplete capsule is allowed to fail honestly — nothing rescues it =="
RT="$WORK/thin_rec.json"
TCBYTES="$(nbytes "$WORK/thin.json")"
runcm prepare --mode compiled_context --task "$WORK/task.json" --capsule "$WORK/thin.json" \
  --prefix "$WORK/prefix.txt" --repo-commit "$SEED" --now "$NOW" --out "$RT"
keep "$RT"
eq "a capsule that admits nothing still prepares (exit 0)" "$RC" "0"
eq "a thin capsule is NOT confounded — thinness is a result, not a defect here" "$(q "$RT" confounded)" "false"
eq "the thin capsule's starting bytes are prefix + capsule and nothing more" "$(q "$RT" starting_context_bytes)" "$((PBYTES + TCBYTES))"
eq "no artifact was added to compensate for the thin capsule" "$(q "$RT" initial_artifact_count)" "0"
ne "a thin capsule buys no extra bytes over the fat one" "$(q "$RT" starting_context_bytes)" "$PERMITTED"
hasnt "no source auto-rescues a thin capsule (no top-up path)" "$SRCTXT" "topUp"
hasnt "no source supplements a capsule" "$SRCTXT" "supplementCapsule"
hasnt "no source re-runs a confounded task" "$SRCTXT" "rerun("

echo
echo "== 7. a smaller starting prompt is never a win by itself =="
KEYS="$(node -e '
const fs=require("fs");const out=[];
const walk=(o)=>{if(Array.isArray(o))o.forEach(walk);else if(o&&typeof o==="object")for(const k of Object.keys(o)){out.push(k);walk(o[k]);}};
for(const f of process.argv.slice(1)) walk(JSON.parse(fs.readFileSync(f,"utf8")));
process.stdout.write(out.join("\n"));' "$RECORDS"/rec_*.json)"
ge "the record corpus is large enough for a grep-negative to mean anything" "$NREC" "8"
ge "the corpus exposes enough keys to scan" "$(grep -c . <<<"$KEYS")" "100"
if grep -qiE '(score|win|success|saving|efficien|smaller_is_better)' <<<"$KEYS"; then
  no "no emitted field derives a score/win/saving from size — found: $(grep -iE '(score|win|success|saving|efficien)' <<<"$KEYS" | tr '\n' ' ')"
else ok "no emitted field derives a score/win/saving from size"; fi
NONCOMMENT="$(grep -hvE '^[[:space:]]*(//|\*|/\*)' "$CM" "$AD" "$AC")"
nonempty "the non-comment source is non-empty" "$NONCOMMENT"
if grep -qiE '(score|win|winner|success|saving|efficien)[a-z_]*[[:space:]]*[:=]' <<<"$NONCOMMENT"; then
  no "no source defines a size-derived score field — found: $(grep -ioE '(score|win|winner|success|saving|efficien)[a-z_]*[[:space:]]*[:=]' <<<"$NONCOMMENT" | tr '\n' ' ')"
else ok "no source defines a size-derived score/win/saving field"; fi
has "the unobservable-provider-context limitation is stated in the record, not faked" "$(q "$R" limitations)" "provider"
has "the limitation says it is not observable" "$(q "$R" limitations)" "NOT OBSERVABLE"

echo
echo "== 8. INERTNESS — nothing live may reference this seam (operator's proof) =="
LIVE=()
while IFS= read -r f; do LIVE+=("$f"); done < <(
  { find "$SRC/.claude/hooks" -type f 2>/dev/null
    [ -f "$SRC/.claude/settings.json" ] && echo "$SRC/.claude/settings.json"
    find "$SRC/build-os/tools" -type f 2>/dev/null
    find "$SRC/build-os/runtime" -type f 2>/dev/null
    find "$SRC/build-os/compiler" -type f -not -path "$ENTRY/*" 2>/dev/null
  } | sort )
ge "the live surface actually contains files to scan" "${#LIVE[@]}" "20"
HITS="$(grep -lE 'context-mode\.mjs|entry/admit\.mjs|entry/activation\.mjs|compiler/entry' "${LIVE[@]}" 2>/dev/null || true)"
if [ -z "$HITS" ]; then ok "ZERO live references to the entry-point files"; else no "live references found: $HITS"; fi
MODEHITS="$(grep -lF 'compiled_context' "${LIVE[@]}" 2>/dev/null || true)"
if [ -z "$MODEHITS" ]; then ok "ZERO occurrences of compiled_context outside entry/ on the live surface"; else no "compiled_context leaked into: $MODEHITS"; fi
if [ -f "$SRC/.claude/settings.json" ]; then
  if grep -qE 'compiled_context|compiler/entry' "$SRC/.claude/settings.json"; then no ".claude/settings.json references the seam"; else ok ".claude/settings.json is clean of the seam"; fi
else ok ".claude/settings.json absent — nothing can reference the seam from it"; fi
POS="$(grep -lF 'compiled_context' "$CM" "$AD" "$AC" 2>/dev/null | wc -l | tr -d ' ')"
eq "positive control: the same grep DOES find the string in all three entry files" "$POS" "3"
has "context-mode.mjs declares itself unwired" "$(q "$R" wired)" "false"

echo
echo "== 9. admission is gated on measured eligibility, with NO override =="
mkidx(){ # out, count, parser, symbols(y/n), tests(y/n)
  node -e '
  const fs=require("fs");const [out,n,parser,sym,tst]=process.argv.slice(1);
  const files={};
  for(let i=0;i<Number(n);i++){files[`src/f${i}.mjs`]={blob:`b${i}`,lang:"javascript",kind:"source",parser:parser==="none"?undefined:parser,
    symbols:sym==="y"?[`sym${i}`]:[],imports:[],imported_by:[],tests_covering:tst==="y"?[`tests/t${i}.mjs`]:[],
    last_changed:"2026-01-01T00:00:00Z",error_count:0};}
  fs.writeFileSync(out,JSON.stringify({index_version:1,repo_head:"1111111111111111111111111111111111111111",
    generated_at:"2026-01-01T00:00:00Z",files,symbols:{}},null,2)+"\n");' "$@"
}
mkidx "$WORK/idx_good.json" 10 javascript y y
mkidx "$WORK/idx_blind.json" 10 none n n
mkidx "$WORK/idx_nosym.json" 10 javascript n y

runad(){ OUT="$(node "$AD" "$@" 2>"$WORK/aerr")"; RC=$?; ERRTXT="$(cat "$WORK/aerr")"; }
A1="$WORK/adm_good.json"
runad admit --mode-requested compiled_context --index "$WORK/idx_good.json" --now "$NOW" --out "$A1"
keep "$A1"
eq "an eligible repository admits compiled_context (exit 0)" "$RC" "0"
eq "the granted mode is compiled_context" "$(q "$A1" mode_granted)" "compiled_context"
eq "refused is false" "$(q "$A1" refused)" "false"
A2="$WORK/adm_blind.json"
runad admit --mode-requested compiled_context --index "$WORK/idx_blind.json" --now "$NOW" --out "$A2"
keep "$A2"
eq "a blind repository REFUSES compiled_context (exit 4)" "$RC" "4"
eq "the granted mode falls back to standard_context" "$(q "$A2" mode_granted)" "standard_context"
has "the refusal cites the measured verdict" "$(q "$A2" refusal_reason)" "NOT-ELIGIBLE"
A3="$WORK/adm_nosym.json"
runad admit --mode-requested compiled_context --index "$WORK/idx_nosym.json" --now "$NOW" --out "$A3"
keep "$A3"
eq "ELIGIBLE-but-bypass is still refused (the rule is conjunctive)" "$RC" "4"
has "the bypass state is cited by name" "$(q "$A3" refusal_reason)" "bypass"
for flag in --force --override --allow-bypass; do
  runad admit --mode-requested compiled_context --index "$WORK/idx_blind.json" --now "$NOW" --out "$WORK/o.json" "$flag"
  eq "$flag is refused, not honoured (exit 2)" "$RC" "2"
  has "$flag refusal says no override exists" "$ERRTXT" "no override"
done
has "eligibility evidence carries parser coverage" "$(q "$A1" eligibility_evidence.parser_coverage)" "/10"
has "eligibility evidence carries the no-parser share" "$(q "$A1" eligibility_evidence.no_parser_share)" "/10"
has "eligibility evidence carries symbol coverage" "$(q "$A1" eligibility_evidence.symbol_coverage)" "/10"
has "eligibility evidence carries test-linkage coverage" "$(q "$A1" eligibility_evidence.test_linkage_coverage)" "/10"
eq "eligibility evidence carries the recommended use state" "$(q "$A1" eligibility_evidence.recommended_use_state)" "normal"
has "the exact eligibility rule is recorded as text" "$(q "$A1" eligibility_rule_applied)" "strictly below"
eq "the eligibility timestamp is recorded" "$(q "$A1" eligibility_timestamp)" "$NOW"
eq "the commit the report was computed against is recorded" "$(q "$A1" report_repo_commit)" "$SEED"
has "the evidence names the reporter it consumed" "$(q "$A1" eligibility_evidence.source)" "report.mjs"
eq "no override path is advertised" "$(q "$A1" override_available)" "false"
# Executable source only: a COMMENT that names process.env is documentation of
# the rule, not a channel that reads it. The property is about code.
if grep -qF 'process.env' <<<"$NONCOMMENT"; then no "an entry tool reads the environment — that is an override channel"; else ok "no entry tool reads process.env: no environment override channel exists"; fi
RPT_JSON="$WORK/rpt.json"
node "$SRC/build-os/compiler/capability/report.mjs" report --index "$WORK/idx_good.json" --json >"$RPT_JSON" 2>/dev/null
runad admit --mode-requested compiled_context --report "$RPT_JSON" --now "$NOW" --out "$WORK/adm_rec.json"
keep "$WORK/adm_rec.json"
eq "a RECORDED reporter run is accepted as evidence" "$RC" "0"
eq "the recorded run yields the same verdict as the live run" "$(q "$WORK/adm_rec.json" mode_granted)" "compiled_context"

echo
echo "== 10. the activation boundary refuses unless every precondition holds =="
printf 'EXP-0004 FREEZE — task set pinned.\n' >"$WORK/freeze.md"
FSHA="$(sha "$WORK/freeze.md")"
mkact(){ node -e '
  const fs=require("fs");const [out,spec]=process.argv.slice(1);
  fs.writeFileSync(out, JSON.stringify(JSON.parse(spec),null,2)+"\n");' "$@"; }
GOOD="{\"eligibility_admission\":\"$A1\",\"freeze\":{\"path\":\"$WORK/freeze.md\",\"sha256\":\"$FSHA\"},\"arm\":\"B\",\"seed_commit\":\"$SEED\",\"starting_context_record\":\"$R\"}"
mkact "$WORK/act_ok.json" "$GOOD"
runac(){ OUT="$(node "$AC" check "$1" 2>"$WORK/cerr")"; RC=$?; ERRTXT="$(cat "$WORK/cerr")"; }
runac "$WORK/act_ok.json"
eq "every precondition met => exit 0" "$RC" "0"
has "the pass names the arm it authorised" "$OUT" "arm B"

badact(){ # name, needle, json
  mkact "$WORK/act_bad.json" "$3"
  runac "$WORK/act_bad.json"
  eq "$1 => refused (exit 2)" "$RC" "2"
  has "$1 => named individually" "$OUT$ERRTXT" "$2"
}
badact "missing freeze file" "freeze" \
  "{\"eligibility_admission\":\"$A1\",\"freeze\":{\"path\":\"$WORK/nope.md\",\"sha256\":\"$FSHA\"},\"arm\":\"B\",\"seed_commit\":\"$SEED\",\"starting_context_record\":\"$R\"}"
badact "freeze digest mismatch" "freeze_digest_mismatch" \
  "{\"eligibility_admission\":\"$A1\",\"freeze\":{\"path\":\"$WORK/freeze.md\",\"sha256\":\"0000000000000000000000000000000000000000000000000000000000000000\"},\"arm\":\"B\",\"seed_commit\":\"$SEED\",\"starting_context_record\":\"$R\"}"
badact "no experiment arm" "experiment arm" \
  "{\"eligibility_admission\":\"$A1\",\"freeze\":{\"path\":\"$WORK/freeze.md\",\"sha256\":\"$FSHA\"},\"seed_commit\":\"$SEED\",\"starting_context_record\":\"$R\"}"
badact "an invented arm C" "experiment arm" \
  "{\"eligibility_admission\":\"$A1\",\"freeze\":{\"path\":\"$WORK/freeze.md\",\"sha256\":\"$FSHA\"},\"arm\":\"C\",\"seed_commit\":\"$SEED\",\"starting_context_record\":\"$R\"}"
badact "no seed commit" "seed commit" \
  "{\"eligibility_admission\":\"$A1\",\"freeze\":{\"path\":\"$WORK/freeze.md\",\"sha256\":\"$FSHA\"},\"arm\":\"B\",\"starting_context_record\":\"$R\"}"
badact "seed commit differs from the record" "seed commit" \
  "{\"eligibility_admission\":\"$A1\",\"freeze\":{\"path\":\"$WORK/freeze.md\",\"sha256\":\"$FSHA\"},\"arm\":\"B\",\"seed_commit\":\"2222222222222222222222222222222222222222\",\"starting_context_record\":\"$R\"}"
badact "an ineligible repository" "eligib" \
  "{\"eligibility_admission\":\"$A2\",\"freeze\":{\"path\":\"$WORK/freeze.md\",\"sha256\":\"$FSHA\"},\"arm\":\"B\",\"seed_commit\":\"$SEED\",\"starting_context_record\":\"$R\"}"
badact "arm B against a standard_context record" "starting-context contract" \
  "{\"eligibility_admission\":\"$A1\",\"freeze\":{\"path\":\"$WORK/freeze.md\",\"sha256\":\"$FSHA\"},\"arm\":\"B\",\"seed_commit\":\"$SEED\",\"starting_context_record\":\"$RS\"}"
CONF="$RECORDS/rec_2.json"
badact "a confounded starting-context record" "confounded" \
  "{\"eligibility_admission\":\"$A1\",\"freeze\":{\"path\":\"$WORK/freeze.md\",\"sha256\":\"$FSHA\"},\"arm\":\"B\",\"seed_commit\":\"$SEED\",\"starting_context_record\":\"$CONF\"}"

mkact "$WORK/act_empty.json" "{}"
runac "$WORK/act_empty.json"
eq "nothing supplied => refused" "$RC" "2"
MISSING="$(grep -cE '^ +- ' <<<"$OUT" || true)"
ge "every missing precondition is named individually, not just the first" "$MISSING" "5"
hasnt "activation never claims to have activated anything" "$OUT" "ACTIVATED"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ] || exit 1
