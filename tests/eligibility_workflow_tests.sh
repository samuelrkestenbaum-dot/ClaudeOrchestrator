#!/usr/bin/env bash
# POST-PILOT ELIGIBILITY WORKFLOW tests — build-os/compiler/eligibility/.
#
# WHAT THIS PINS. AB_PREREGISTRATION AMENDMENT 1 makes repository signal a
# PRECONDITION for EXP-0004: the no_parser share of admitted-candidate files
# must be strictly below one half, measured by the indexer's own stats and
# RECORDED before arm A begins. assess-repo.sh is the bounded procedure that
# produces that record. This suite pins:
#
#   1. THE FROZEN-PILOT SAFETY PROPERTY. PILOT-0002 is frozen and has not yet
#      run. The tool is READ-ONLY toward its target under all circumstances:
#      section 5 snapshots a fixture target repository's complete file list and
#      content hashes (INCLUDING .git) before and after a full run and asserts
#      byte-identity with no new and no removed files. Section 8 additionally
#      refuses, statically, any mutating git verb in the tool's source.
#   2. THE ELIGIBLE PATH. A high-signal repository is ELIGIBLE, the candidate
#      backlog is emitted, and every prior-pilot task is excluded from it — an
#      excluded-task-shaped candidate is PLANTED in the fixture precisely so the
#      filter is proven to fire rather than assumed to.
#   3. THE INELIGIBLE PATH IS A LEGITIMATE OUTCOME. A shell-dominant repository
#      exits non-zero, emits NO backlog, and says in words that bypassing the
#      compiler is the correct answer and not a failure to work around.
#   4. REPRODUCIBILITY. A dirty tree is refused with its reason: the indexer
#      reads WORKTREE bytes, so a verdict computed against an uncommitted tree
#      is not attributable to the commit it claims to pin.
#   5. THE TOOL NEVER PICKS A WINNER. If the reporter's own verdict and the
#      mechanical rule ever disagree, that is a defect in the pair, and the
#      procedure refuses and says so rather than choosing one.
#   6. DETERMINISM. Same commit => byte-identical eligibility.json, with
#      --deterministic zeroing the only wall-clock field.
#
# FIXTURES are mktemp git repositories built here, byte by byte, so every
# coverage number is known by construction. THE FROZEN PILOT REPOSITORY IS
# NEVER TOUCHED: this suite contains no path into it, and section 8 greps for
# that absence in the tool's source as well.
#
# A NOTE ON ASSERTION STYLE. This suite deliberately uses no `-ge N` / `-gt N`
# with N > 1. Those constants are a registered family (control_registry_tests.sh
# section 21, control `tests.nonvacuity_minimums`) and an unregistered one would
# turn that reconciliation red. Exact counts are asserted with `=` / `-eq`
# instead, which is stronger anyway: this suite knows its fixtures exactly.
#
# No network. Deterministic. Exits non-zero if any assertion fails, and prints a
# final "==== RESULT: N passed, M failed ====" line.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ELIG="$SRC/build-os/compiler/eligibility"
ASSESS="$ELIG/assess-repo.sh"
EXCL="$ELIG/prior-pilot-exclusions.txt"
RPT="$SRC/build-os/compiler/capability/report.mjs"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); printf '  ok  %s\n' "$1"; }
no(){ FAIL=$((FAIL+1)); printf '  NO  %s\n' "$1"; }
eq(){ if [ "$2" = "$3" ]; then ok "$1"; else no "$1 — got [$2] want [$3]"; fi; }
has(){ if grep -qF -- "$3" <<<"$2"; then ok "$1"; else no "$1 — [$3] absent"; fi; }
hasnt(){ if grep -qF -- "$3" <<<"$2"; then no "$1 — [$3] present and must not be"; else ok "$1"; fi; }
isfile(){ if [ -f "$2" ]; then ok "$1"; else no "$1 — $2 does not exist"; fi; }
nofile(){ if [ -f "$2" ]; then no "$1 — $2 exists and must not"; else ok "$1"; fi; }

command -v node >/dev/null 2>&1 || { no "node is required"; echo "==== RESULT: $PASS passed, $FAIL failed ===="; exit 1; }
command -v git  >/dev/null 2>&1 || { no "git is required";  echo "==== RESULT: $PASS passed, $FAIL failed ===="; exit 1; }
[ -f "$ASSESS" ] || { no "build-os/compiler/eligibility/assess-repo.sh does not exist"; echo "==== RESULT: $PASS passed, $FAIL failed ===="; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Read a dotted path out of a JSON file with node stdlib only.
jget(){ node -e '
const fs=require("node:fs");
let j; try { j=JSON.parse(fs.readFileSync(process.argv[1],"utf8")); } catch { process.stdout.write(""); process.exit(0); }
let v=j; for (const k of process.argv[2].split(".")) { v = (v===undefined||v===null) ? undefined : v[k]; }
process.stdout.write(v===undefined ? "" : (typeof v==="object" ? JSON.stringify(v) : String(v)));
' "$1" "$2"; }

run_assess(){ OUT="$(bash "$ASSESS" "$@" 2>&1)"; RC=$?; }

git_init(){
  mkdir -p "$1"
  git -C "$1" init -q -b main
  git -C "$1" config user.email 'fixture@example.invalid'
  git -C "$1" config user.name  'Fixture'
  git -C "$1" config commit.gpgsign false
}
git_commit(){ git -C "$1" add -A && git -C "$1" commit -q -m "$2"; }

# --------------------------------------------------------------- fixtures --
# HIGH-SIGNAL REPO: 6 tracked files, 5 with a real extractor, 1 (README.md)
# without => no_parser 1/6 (16.7%), strictly below one half => ELIGIBLE.
# One test file whose basename stem matches a source file, so test linkage is
# non-zero and the recommended use state is `normal` rather than
# `expansion-heavy`. Both numbers are known by construction, not observed.
HI="$WORK/high-signal"
git_init "$HI"
mkdir -p "$HI/src/cart" "$HI/src/util" "$HI/src/server/trpc" "$HI/tests"
cat >"$HI/src/util/format.ts" <<'EOF'
export function formatMoney(n) { return "$" + n; }
export function formatQty(n) { return n + "x"; }
EOF
cat >"$HI/src/cart/cart.ts" <<'EOF'
import { formatMoney } from '../util/format';
export function addItem(cart, item) { return cart.concat([item]); }
export function removeItem(cart, id) { return cart.filter((x) => x.id !== id); }
export const CART_VERSION = 3;
EOF
cat >"$HI/src/cart/total.ts" <<'EOF'
import { formatMoney } from '../util/format';
export function cartTotal(items) { return items.reduce((a, b) => a + b.price, 0); }
EOF
cat >"$HI/src/server/trpc/client.ts" <<'EOF'
export function callBridge(router) { return router.bridge; }
EOF
cat >"$HI/tests/cart.test.ts" <<'EOF'
import { addItem } from '../src/cart/cart';
export function testAddItem() { return addItem([], { id: 1 }); }
EOF
printf '# fixture\n\nA high-signal fixture repository.\n' >"$HI/README.md"
git_commit "$HI" 'fixture: high-signal repository'
HI_HEAD="$(git -C "$HI" rev-parse HEAD)"

# The planted error list. Cluster A (TS2345, 2 errors, cart files) must SURVIVE
# the exclusion filter. Cluster B is deliberately shaped like PILOT-0002's
# frozen T1 (the trpc bridge->bridges cluster) and must be FILTERED OUT.
ERRS="$WORK/errors.txt"
cat >"$ERRS" <<'EOF'
src/cart/total.ts(2,40): error TS2345: Argument of type 'string' is not assignable to parameter of type 'number'.
src/cart/cart.ts(3,14): error TS2345: Argument of type 'boolean' is not assignable to parameter of type 'number'.
src/server/trpc/client.ts(1,45): error TS2339: Property 'bridge' does not exist on type 'AppRouter'. Did you mean 'bridges'?
EOF

# SHELL-DOMINANT REPO: 5 tracked files, none with an extractor => no_parser
# 5/5 (100%) => NOT-ELIGIBLE, and the recommended use state is `bypass`.
SH="$WORK/shell-dominant"
git_init "$SH"
mkdir -p "$SH/lib" "$SH/docs"
printf '#!/usr/bin/env bash\nset -euo pipefail\nmain(){ echo run; }\nmain "$@"\n' >"$SH/run.sh"
printf '#!/usr/bin/env bash\nset -euo pipefail\ndeploy(){ echo deploy; }\n'       >"$SH/deploy.sh"
printf '#!/usr/bin/env bash\nhelper(){ echo helper; }\n'                          >"$SH/lib/util.sh"
printf '# shell fixture\n'                                                        >"$SH/README.md"
printf '# notes\n\nnothing structural here.\n'                                    >"$SH/docs/notes.md"
git_commit "$SH" 'fixture: shell-dominant repository'

echo "== 1. usage, arguments and output-directory safety =="
run_assess
eq "no arguments is refused with exit 2" "$RC" "2"
has "the refusal states the usage" "$OUT" "usage:"
run_assess --repo "$HI" --out "$WORK/o-missing-repo-x" --repo-extra
eq "an unknown flag is refused with exit 2" "$RC" "2"
run_assess --repo "$WORK/not-a-repo" --out "$WORK/o1"
eq "a non-existent target is refused with exit 2" "$RC" "2"
mkdir -p "$WORK/plain-dir"
run_assess --repo "$WORK/plain-dir" --out "$WORK/o2"
eq "a non-git target is refused with exit 2" "$RC" "2"
has "the non-git refusal names the reason" "$OUT" "not a git repository"
run_assess --repo "$HI" --out "$HI/eligibility-out"
eq "an --out inside the target repository is refused with exit 2" "$RC" "2"
has "the inside-the-target refusal names the read-only rule" "$OUT" "never writes inside the target"
nofile "and no such directory was created inside the target" "$HI/eligibility-out/eligibility.json"
mkdir -p "$WORK/o-nonempty" && : >"$WORK/o-nonempty/stale.json"
run_assess --repo "$HI" --out "$WORK/o-nonempty"
eq "a non-empty --out directory is refused with exit 2" "$RC" "2"
has "the non-empty refusal explains stale-evidence confusion" "$OUT" "stale"

echo "== 2. (a) the high-signal repository is ELIGIBLE and the backlog is emitted =="
A="$WORK/out-a"
run_assess --repo "$HI" --out "$A" --errors "$ERRS" --deterministic
eq "the eligible run exits 0" "$RC" "0"
isfile "ELIGIBILITY.md was written" "$A/ELIGIBILITY.md"
isfile "eligibility.json was written" "$A/eligibility.json"
isfile "the index it was computed from was kept" "$A/index.json"
isfile "the indexer stats it was cross-checked against were kept" "$A/index-stats.txt"
isfile "the capability report (text) was kept" "$A/capability-report.txt"
isfile "the capability report (json) was kept" "$A/capability-report.json"
isfile "the procedure log records every step" "$A/procedure.tsv"
MD="$(cat "$A/ELIGIBILITY.md" 2>/dev/null)"
eq "the recorded verdict is ELIGIBLE" "$(jget "$A/eligibility.json" verdict)" "ELIGIBLE"
eq "the disposition is the eligible one" "$(jget "$A/eligibility.json" disposition)" "ELIGIBLE"
eq "the pinned commit is the fixture HEAD" "$(jget "$A/eligibility.json" pinned_commit)" "$HI_HEAD"
eq "the repo path is recorded" "$(jget "$A/eligibility.json" repo)" "$HI"
eq "the index version is recorded" "$(jget "$A/eligibility.json" index_version)" "1"
eq "the no-parser numerator is the one the fixture was built to have" "$(jget "$A/eligibility.json" no_parser_share.n)" "1"
eq "the no-parser denominator is the one the fixture was built to have" "$(jget "$A/eligibility.json" no_parser_share.total)" "6"
eq "the no-parser share is recorded as n/total AND a percentage" "$(jget "$A/eligibility.json" no_parser_share.text)" "1/6 (16.7%)"
eq "the recommended use state is recorded" "$(jget "$A/eligibility.json" recommended_use_state)" "normal"
eq "the reporter's verdict line is recorded verbatim" "$(jget "$A/eligibility.json" reporter_verdict_line)" "VERDICT: ELIGIBLE"
has "the human record shows the pinned commit" "$MD" "$HI_HEAD"
has "the human record shows the parser coverage" "$MD" "== PARSER COVERAGE =="
has "the human record shows the symbol coverage" "$MD" "== SYMBOL COVERAGE =="
has "the human record shows the test-linkage coverage" "$MD" "== TEST-LINKAGE COVERAGE =="
has "the human record quotes the exact rule text applied" "$MD" "no_parser share of files admitted-as-candidates must be below 50%"
has "the human record cites the rule's source" "$MD" "build-os/compiler/AB_PREREGISTRATION.md"
has "the human record shows the arithmetic" "$MD" "2 * 1 = 2 < 6"
has "the human record carries a timestamp field" "$MD" "timestamp:"
has "the human record quotes the reporter verdict line verbatim" "$MD" "VERDICT: ELIGIBLE"
has "the human record states this is recorded BEFORE arm A" "$MD" "before arm A begins"
has "the procedure records step 1, the pinned commit" "$(cat "$A/procedure.tsv")" "pin-commit"
has "the procedure records step 2, the index" "$(cat "$A/procedure.tsv")" "index-commit"
has "the procedure records step 3, the reporter" "$(cat "$A/procedure.tsv")" "capability-report"
has "the procedure records step 4, the evidence record" "$(cat "$A/procedure.tsv")" "record-evidence"
has "the procedure records step 5, the mechanical rule" "$(cat "$A/procedure.tsv")" "apply-rule"
has "the procedure records step 7, the backlog" "$(cat "$A/procedure.tsv")" "emit-backlog"

echo "== 3. (a cont.) the backlog is CANDIDATES, and prior-pilot tasks are excluded =="
isfile "the candidate backlog (json) was emitted" "$A/candidates.json"
isfile "the candidate backlog (markdown) was emitted" "$A/CANDIDATES.md"
CMD="$(cat "$A/CANDIDATES.md" 2>/dev/null)"
has "the backlog says it is candidates, not a selection" "$CMD" "CANDIDATES for selection, not a selection"
has "the backlog says selection is a separate operator-gated step" "$CMD" "operator-gated"
eq "exactly one candidate survives the filter" "$(jget "$A/candidates.json" candidate_count)" "1"
eq "exactly one planted prior-pilot-shaped candidate is excluded" "$(jget "$A/candidates.json" excluded_count)" "1"
has "the surviving candidate is the cart cluster" "$(cat "$A/candidates.json")" "src/cart/total.ts"
hasnt "the excluded trpc path is absent from the surviving candidate list" "$(jget "$A/candidates.json" candidates)" "src/server/trpc/client.ts"
has "the exclusion is attributed to PILOT-0002 by name" "$(jget "$A/candidates.json" excluded)" "PILOT-0002"
has "the exclusion names the frozen task it protects" "$(jget "$A/candidates.json" excluded)" "trpc"
has "the backlog states which exclusion file it applied" "$CMD" "prior-pilot-exclusions.txt"
EXTXT="$(cat "$EXCL" 2>/dev/null)"
eq "the shipped exclusion list carries exactly ten prior-pilot tasks" \
   "$(grep -cvE '^[[:space:]]*(#|$)' "$EXCL" 2>/dev/null)" "10"
has "the exclusion list names PILOT-0001's red-baseline diagnosis" "$EXTXT" "red baseline"
has "the exclusion list names PILOT-0001's hermetic notification test" "$EXTXT" "notification"
has "the exclusion list names PILOT-0001's four_eyes_state_change audit kind" "$EXTXT" "four_eyes_state_change"
has "the exclusion list names PILOT-0001's executeFixLayer dry-run timeout" "$EXTXT" "executeFixLayer"
has "the exclusion list names PILOT-0001's stripe SDK-drift cluster" "$EXTXT" "stripe"
has "the exclusion list names PILOT-0002's trpc bridge cluster" "$EXTXT" "bridges"
has "the exclusion list names PILOT-0002's CoverageReportData drift" "$EXTXT" "CoverageReportData"
has "the exclusion list names PILOT-0002's agents hermetic/live-LLM tests" "$EXTXT" "agents"
has "the exclusion list names PILOT-0002's training/router interface conflict" "$EXTXT" "AutoRetrainingPipeline"
has "the exclusion list names PILOT-0002's voice-stream LogDomain + webhooks task" "$EXTXT" "LogDomain"

echo "== 4. (b) the shell-dominant repository is INELIGIBLE, and that is legitimate =="
B="$WORK/out-b"
run_assess --repo "$SH" --out "$B" --errors "$ERRS" --deterministic
eq "the ineligible run exits 1" "$RC" "1"
eq "the recorded verdict is NOT-ELIGIBLE" "$(jget "$B/eligibility.json" verdict)" "NOT-ELIGIBLE"
eq "the no-parser share is the whole repository" "$(jget "$B/eligibility.json" no_parser_share.text)" "5/5 (100.0%)"
eq "the recommended use state is bypass" "$(jget "$B/eligibility.json" recommended_use_state)" "bypass"
nofile "NO candidate backlog (json) was emitted" "$B/candidates.json"
nofile "NO candidate backlog (markdown) was emitted" "$B/CANDIDATES.md"
isfile "the ineligibility is still recorded as evidence" "$B/ELIGIBILITY.md"
has "the run says task selection must not proceed" "$OUT" "task selection MUST NOT proceed"
has "the run says the compiler should be bypassed for this repository" "$OUT" "bypass the compiler for this repository"
has "the run says this is a legitimate outcome" "$OUT" "legitimate outcome"
has "the run says it is not a failure to work around" "$OUT" "not a failure to work around"
has "the record repeats the stop instruction in writing" "$(cat "$B/ELIGIBILITY.md")" "MUST NOT proceed"

echo "== 5. (c) a dirty tree is refused, with the reproducibility reason =="
DIRTY="$WORK/dirty"
cp -a "$HI" "$DIRTY"
printf '\n// uncommitted edit\n' >>"$DIRTY/src/cart/cart.ts"
C="$WORK/out-c"
run_assess --repo "$DIRTY" --out "$C" --deterministic
eq "the dirty run is refused with exit 2" "$RC" "2"
has "the refusal names the dirty tree" "$OUT" "tree is not clean"
has "the refusal gives the reproducibility reason" "$OUT" "not reproducible"
has "the refusal shows what is dirty" "$OUT" "src/cart/cart.ts"
nofile "no eligibility verdict was recorded from a dirty tree" "$C/eligibility.json"
nofile "no backlog was emitted from a dirty tree" "$C/candidates.json"
# Untracked files are refused too: the operator is told which, not left guessing.
DIRTY2="$WORK/dirty-untracked"
cp -a "$HI" "$DIRTY2"
printf 'scratch\n' >"$DIRTY2/scratch.tmp"
run_assess --repo "$DIRTY2" --out "$WORK/out-c2" --deterministic
eq "an untracked file also refuses with exit 2" "$RC" "2"
has "the untracked refusal shows the offending path" "$OUT" "scratch.tmp"

echo "== 6. (d) READ-ONLY PROOF: the tool writes nothing inside its target =="
# The frozen-pilot safety property, executed. Snapshot EVERY file under the
# target — including .git — by path and by content hash, run the full procedure,
# and re-snapshot. Byte-identical, no additions, no removals.
snap(){ ( cd "$1" && find . \( -type f -o -type l \) -print | LC_ALL=C sort \
          | while IFS= read -r f; do printf '%s  %s\n' "$(sha256sum "$f" 2>/dev/null | cut -d' ' -f1)" "$f"; done ) }
RO="$WORK/readonly-target"
cp -a "$HI" "$RO"
snap "$RO" >"$WORK/snap.before"
D="$WORK/out-d"
run_assess --repo "$RO" --out "$D" --errors "$ERRS" --deterministic
snap "$RO" >"$WORK/snap.after"
eq "the run under proof actually completed (a no-op would prove nothing)" "$RC" "0"
isfile "the run under proof produced its verdict OUTSIDE the target" "$D/eligibility.json"
SNAP_N="$(grep -c . "$WORK/snap.before")"
if [ -n "$SNAP_N" ] && [ "$SNAP_N" -ge 1 ]; then ok "the snapshot is not vacuous: $SNAP_N file(s) hashed inside the target"; else no "the snapshot hashed nothing — the proof below would be empty"; fi
if diff -u "$WORK/snap.before" "$WORK/snap.after" >"$WORK/snap.diff" 2>&1; then
  ok "READ-ONLY PROVEN: every file inside the target is byte-identical after the run"
else
  no "the tool mutated its target — $(grep -c '^[+-][^+-]' "$WORK/snap.diff") differing line(s)"
  sed -n '1,20p' "$WORK/snap.diff" | sed 's/^/      | /'
fi
BEFORE_PATHS="$(cut -d' ' -f3- "$WORK/snap.before")"
AFTER_PATHS="$(cut -d' ' -f3- "$WORK/snap.after")"
eq "no file was created inside the target and none was removed" "$AFTER_PATHS" "$BEFORE_PATHS"
hasnt "no output artifact leaked into the target" "$AFTER_PATHS" "ELIGIBILITY.md"
hasnt "no index leaked into the target" "$AFTER_PATHS" "index.json"

echo "== 7. (e) a verdict disagreement is REFUSED, never resolved by choosing =="
# Three stub reporters, each a thin node wrapper that runs the REAL reporter and
# corrupts exactly one thing. Corrupting the real output (rather than
# fabricating one) keeps every other number genuine, so each stub isolates the
# check it is aimed at.
cat >"$WORK/stub-flip-both.mjs" <<'EOF'
import { execFileSync } from 'node:child_process';
const real = process.env.REAL_REPORTER;
const args = process.argv.slice(2);
const out = execFileSync(process.execPath, [real, ...args], { encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
const flip = (v) => (v === 'ELIGIBLE' ? 'NOT-ELIGIBLE' : 'ELIGIBLE');
if (args.includes('--json')) {
  const j = JSON.parse(out);
  j.exp0004_eligibility.verdict = flip(j.exp0004_eligibility.verdict);
  process.stdout.write(JSON.stringify(j, null, 2) + '\n');
} else {
  process.stdout.write(out.replace(/^VERDICT: (ELIGIBLE|NOT-ELIGIBLE)$/m, (m, v) => `VERDICT: ${flip(v)}`));
}
EOF
cat >"$WORK/stub-flip-json-only.mjs" <<'EOF'
import { execFileSync } from 'node:child_process';
const real = process.env.REAL_REPORTER;
const args = process.argv.slice(2);
const out = execFileSync(process.execPath, [real, ...args], { encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
if (args.includes('--json')) {
  const j = JSON.parse(out);
  j.exp0004_eligibility.verdict = j.exp0004_eligibility.verdict === 'ELIGIBLE' ? 'NOT-ELIGIBLE' : 'ELIGIBLE';
  process.stdout.write(JSON.stringify(j, null, 2) + '\n');
} else process.stdout.write(out);
EOF
cat >"$WORK/stub-skew-count.mjs" <<'EOF'
import { execFileSync } from 'node:child_process';
const real = process.env.REAL_REPORTER;
const args = process.argv.slice(2);
const out = execFileSync(process.execPath, [real, ...args], { encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
if (args.includes('--json')) {
  const j = JSON.parse(out);
  j.parser_coverage.no_parser.n = j.parser_coverage.no_parser.n + 1;
  process.stdout.write(JSON.stringify(j, null, 2) + '\n');
} else process.stdout.write(out);
EOF
export REAL_REPORTER="$RPT"
run_assess --repo "$HI" --out "$WORK/out-e1" --deterministic --reporter "$WORK/stub-flip-both.mjs"
eq "a reporter verdict contradicting the arithmetic exits 3" "$RC" "3"
has "the refusal names the disagreement" "$OUT" "disagree"
has "the refusal calls it a defect" "$OUT" "defect"
has "the refusal declines to choose a winner" "$OUT" "will not choose between them"
has "the refusal shows the reporter's verdict" "$OUT" "reporter verdict: NOT-ELIGIBLE"
has "the refusal shows the mechanical verdict" "$OUT" "mechanical verdict: ELIGIBLE"
nofile "no backlog is emitted from a disagreement" "$WORK/out-e1/candidates.json"
isfile "the refusal is itself recorded as evidence" "$WORK/out-e1/ELIGIBILITY.md"
eq "the recorded disposition is the refusal" "$(jget "$WORK/out-e1/eligibility.json" disposition)" "REFUSED"
run_assess --repo "$HI" --out "$WORK/out-e2" --deterministic --reporter "$WORK/stub-flip-json-only.mjs"
eq "a json/text verdict mismatch inside the reporter exits 3" "$RC" "3"
has "that refusal names the two renderings" "$OUT" "verdict line"
run_assess --repo "$HI" --out "$WORK/out-e3" --deterministic --reporter "$WORK/stub-skew-count.mjs"
eq "an indexer/reporter count disagreement exits 3" "$RC" "3"
has "that refusal names the derivation-parity breach" "$OUT" "build-index.mjs stats"
unset REAL_REPORTER

echo "== 8. the tool is read-only toward its target BY CONSTRUCTION =="
SRC_ALL="$(cat "$ASSESS" "$ELIG"/*.mjs 2>/dev/null)"
if [ -n "$SRC_ALL" ]; then ok "the tool source was read for the static safety scan"; else no "the tool source could not be read"; fi
for verb in checkout stash "clean -" reset commit "add -" worktree "rm -" push merge fetch pull; do
  if grep -nE "git[^|;&]*\b${verb%% *}\b" <<<"$SRC_ALL" | grep -vE '^\s*#' | grep -q .; then
    no "the tool source contains a mutating git verb: $verb"
  else
    ok "no mutating git verb in the tool source: $verb"
  fi
done
has "the tool suppresses git's optional index locks" "$SRC_ALL" "GIT_OPTIONAL_LOCKS=0"
has "the tool passes --no-optional-locks to git" "$SRC_ALL" "--no-optional-locks"
hasnt "the tool source contains no path into the frozen pilot repository" "$SRC_ALL" "empathiq-website"
hasnt "this suite contains no path into the frozen pilot repository" "$(grep -v 'empathiq' "${BASH_SOURCE[0]}")" "/home/user/empathiq"

echo "== 9. (f) determinism: same commit => same eligibility.json =="
F1="$WORK/out-f1"; F2="$WORK/out-f2"
run_assess --repo "$HI" --out "$F1" --errors "$ERRS" --deterministic
RC1="$RC"
run_assess --repo "$HI" --out "$F2" --errors "$ERRS" --deterministic
eq "both deterministic runs exit 0" "$RC1-$RC" "0-0"
eq "--deterministic zeroes the only wall-clock field" "$(jget "$F1/eligibility.json" timestamp)" "1970-01-01T00:00:00.000Z"
if diff -q "$F1/eligibility.json" "$F2/eligibility.json" >/dev/null 2>&1; then
  ok "two runs of the same commit produce a byte-identical eligibility.json"
else
  no "eligibility.json drifted between two runs of the same commit"
  diff -u "$F1/eligibility.json" "$F2/eligibility.json" | sed -n '1,20p' | sed 's/^/      | /'
fi
if diff -q "$F1/candidates.json" "$F2/candidates.json" >/dev/null 2>&1; then
  ok "the candidate backlog is byte-identical too"
else
  no "candidates.json drifted between two runs of the same commit"
fi
# And a NON-deterministic run must carry a real timestamp — the zeroing is a
# mode, not the tool quietly refusing to record when it ran.
run_assess --repo "$HI" --out "$WORK/out-f3" --errors "$ERRS"
TS3="$(jget "$WORK/out-f3/eligibility.json" timestamp)"
if [ -n "$TS3" ] && [ "$TS3" != "1970-01-01T00:00:00.000Z" ]; then
  ok "without --deterministic the record carries a real timestamp"
else
  no "without --deterministic the timestamp is missing or still zeroed — got [$TS3]"
fi

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
