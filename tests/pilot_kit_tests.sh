#!/usr/bin/env bash
# Build OS — pilot kit tests (packet gravito_pilot_kit_a).
#
# WHAT THIS PINS. docs/ONBOARDING.md, docs/DEMO.md and docs/PILOT.md are the
# buyer-facing material: the things a second person reads to run this system
# without the author present. Documentation rots into brochure copy the moment
# nothing executes it, so this suite executes it.
#
#   docs/ONBOARDING.md    what the lanes/gates/receipts/tests/memory actually are
#   docs/DEMO.md          a 30-minute script, runnable start to finish
#   docs/PILOT.md         the week-one rubric, with a command per criterion
#   docs/sample-project/  the tiny repo the demo installs into
#
# THE FAILURE MODES IT EXISTS TO CATCH, in the order a buyer would hit them:
#   1. A DEMO COMMAND THAT DOES NOT RUN, or that no longer produces the output
#      the doc claims. Every safe, offline block in DEMO.md is extracted and
#      EXECUTED here, and every documented observable is asserted against its
#      real output. Blocks that need a live Claude Code session or a destructive
#      cleanup are not run — and are required to be marked as such.
#   2. A SPEED CLAIM. This product has no measured speed claim: its own report
#      leads with "This report does not show that Build OS is faster than
#      anything." Any doc line mentioning 20x / 100x / 2.77 / faster / speedup
#      must carry that disclaimer, or the suite goes red. A pilot kit that
#      implies a speedup is contradicted by the repo it is selling.
#   3. A DEAD PATH. A kit pointing at a moved file is worse than no kit, so every
#      repo path and every `.sh` the three docs name must exist (and be
#      executable) either in this repo or in a freshly installed target repo.
#   4. DOC/ROUTER DRIFT. The lane block in ONBOARDING.md must be BYTE-IDENTICAL
#      to build-os/memory/tool_router.md's canonical block. A customer reading
#      one thing while the agent reads another is the defect class this repo
#      pins everywhere else.
#   5. AN UNFALSIFIABLE RUBRIC. Every criterion in PILOT.md must be able to FAIL.
#      Each PILOT:CHECK block is run twice — against a fixture that satisfies it
#      (must exit 0) and against one that violates it (must exit non-zero). A
#      rubric nobody can fail is a sales document.
#   6. A VACUOUS GREEN. Every scanner here declares how much it saw. Zero files,
#      zero commands, zero criteria or zero paths is a loud failure, not a pass.
#
# No network. Temp dirs only (this repo is READ; nothing here writes to it).
# Exits non-zero if any assertion fails, and prints the final
# "==== RESULT: N passed, M failed ====" line the orchestrator parses when it
# chains this suite.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCS="$SRC/docs"
ONB="$DOCS/ONBOARDING.md"
DEMO="$DOCS/DEMO.md"
PILOT="$DOCS/PILOT.md"
FIXTURE="$DOCS/sample-project"
ROUTER="$SRC/build-os/memory/tool_router.md"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# =============================================================== 1. presence ==
echo "== 1. The kit exists and its fixture is runnable =="
for f in "$ONB" "$DEMO" "$PILOT" "$FIXTURE/README.md" "$FIXTURE/slugify.sh" "$FIXTURE/check.sh"; do
  rel="docs/${f#"$DOCS/"}"
  [ -f "$f" ] && ok "$rel exists" || no "$rel is missing — the pilot kit is incomplete"
done
for f in "$FIXTURE/slugify.sh" "$FIXTURE/check.sh"; do
  [ -x "$f" ] && ok "docs/sample-project/$(basename "$f") is executable" \
    || no "docs/sample-project/$(basename "$f") is not executable"
done
# The fixture must be green on its own, and must carry the defect the demo fixes.
( cd "$FIXTURE" && bash check.sh > "$WORK/fx.out" 2>&1 )
[ $? = 0 ] && ok "the sample project's own suite is green before the demo touches it" \
  || { no "the sample project's suite is not green out of the box"; sed 's/^/      | /' "$WORK/fx.out"; }
grep -q '==== RESULT: 3 passed, 0 failed ====' "$WORK/fx.out" \
  && ok "the sample suite prints the house RESULT line (3 passed, 0 failed)" \
  || no "the sample suite does not print the expected RESULT line"
[ "$(bash "$FIXTURE/slugify.sh" 'Hello, World!')" = "hello-world-" ] \
  && ok "the sample project carries the trailing-dash defect the demo's tiny packet fixes" \
  || no "the sample project no longer has the defect DEMO.md Step 5 fixes"

# ================================================== 2. no speed claim anywhere ==
echo "== 2. No document claims a speed multiplier =="
# Every line mentioning a multiplier or the word faster/speedup must carry the
# repo's own disclaimer language ON THAT LINE. A caveat two paragraphs away does
# not survive a copy-paste into a deck.
HEDGE='unmeasured|not measured|never measured|not a measured|no measured|does not show|cannot|could not|no baseline|no control arm|not a comparison|upper bound|has not been run|not been run|refut|not reproducible|ranges overlap|no speed|contradict|would be needed|instead of'
TRIGGER='20x|100x|2\.77|faster|speedup'
UNHEDGED=""; NHITS=0
while IFS= read -r hit; do
  NHITS=$((NHITS+1))
  line="${hit#*:}"
  printf '%s' "$line" | grep -qiE "$HEDGE" || UNHEDGED="$UNHEDGED
      | $hit"
done < <(grep -rniE "$TRIGGER" "$DOCS" --include='*.md' 2>/dev/null)
[ -z "$UNHEDGED" ] && ok "every speed-word mention in docs/ carries the repo's own disclaimer ($NHITS checked)" \
  || { no "an unhedged speed claim is present in docs/"; printf '%s\n' "$UNHEDGED"; }
[ "$NHITS" -ge 3 ] && ok "the speed-claim scanner saw $NHITS mention(s) to check (>= 3, not vacuous)" \
  || no "the speed-claim scanner found only $NHITS mention(s) — it has gone blind, or the kit never confronts the claim"
# The one positive statement the kit must make, in the buyer's own words.
grep -qF 'does not show that Build OS is faster than anything' "$PILOT" \
  && ok "PILOT.md quotes the report's own finding verbatim" \
  || no "PILOT.md does not quote the report's finding that it shows no speed result"
grep -qiE '16.run|COMPARISON_PROTOCOL' "$PILOT" \
  && ok "PILOT.md points at the 16-run protocol as the only honest route to a speed number" \
  || no "PILOT.md offers no falsifiable route to a speed number"
grep -qiE 'no speed claim|not a measured speedup|no measured speed' "$ONB" \
  && ok "ONBOARDING.md states plainly that there is no measured speed claim" \
  || no "ONBOARDING.md does not state that the product has no measured speed claim"

# ========================================== 3. lane names match the router ==
echo "== 3. The lanes a customer reads are the lanes the agent reads =="
awk '/BUILD-OS:LANES:START/{f=1;next} /BUILD-OS:LANES:END/{f=0} f' "$ROUTER" > "$WORK/router_lanes.txt"
awk '/PILOTKIT:LANES:START/{f=1;next} /PILOTKIT:LANES:END/{f=0} f' "$ONB" > "$WORK/onb_lanes.txt"
RL="$(grep -c . "$WORK/router_lanes.txt")"; OL="$(grep -c . "$WORK/onb_lanes.txt")"
[ "${RL:-0}" -ge 10 ] && ok "the router's canonical lane block was found ($RL non-blank lines)" \
  || no "the router's canonical lane block is missing or empty — nothing to compare against"
[ "${OL:-0}" -ge 10 ] && ok "ONBOARDING.md's lane block was found ($OL non-blank lines)" \
  || no "ONBOARDING.md carries no lane block between its PILOTKIT:LANES markers"
if diff -u "$WORK/router_lanes.txt" "$WORK/onb_lanes.txt" > "$WORK/lanes.diff" 2>&1; then
  ok "ONBOARDING.md's lane block is BYTE-IDENTICAL to the router's canonical block"
else
  no "ONBOARDING.md's lane block has drifted from build-os/memory/tool_router.md"
  sed 's/^/      | /' "$WORK/lanes.diff" | head -20
fi
# Each of the five lanes, named, with its gate-set and budget intact.
NLANE=0
for lane in read-only diagnosis tiny substantive architecture; do
  NLANE=$((NLANE+1))
  grep -qF "\`$lane\`" "$WORK/onb_lanes.txt" && ok "the doc's lane table names \`$lane\`" \
    || no "the doc's lane table does not name \`$lane\`"
done
[ "$NLANE" = 5 ] && ok "all 5 lanes were checked (not vacuous)" || no "only $NLANE lanes were checked"
# And no doc may invent a lane the router does not define.
BADLANE=""; NSEEN=0
for l in $(grep -ohE 'Lane: *`?[a-z][a-z-]+`?' "$ONB" "$DEMO" "$PILOT" | sed -E 's/Lane: *//; s/`//g' | sort -u); do
  NSEEN=$((NSEEN+1))
  grep -qF "\`$l\`" "$ROUTER" || BADLANE="$BADLANE $l"
done
[ -z "$BADLANE" ] && ok "every lane the docs announce ($NSEEN distinct) exists in the router" \
  || no "the docs announce lane(s) the router does not define:$BADLANE"
[ "$NSEEN" -ge 1 ] && ok "the lane-name scanner saw $NSEEN announced lane(s) (not vacuous)" \
  || no "the lane-name scanner matched nothing — it cannot detect drift"
# The gate that must survive every rewrite of this doc.
grep -qF 'External mutation stays hard-gated in EVERY lane' "$ONB" \
  && ok "ONBOARDING.md carries the every-lane external-mutation gate verbatim" \
  || no "ONBOARDING.md drops the every-lane external-mutation gate"
grep -qiE 'never means .?no go needed to push|it never means \*no go needed to push' "$ONB" \
  && ok "ONBOARDING.md keeps the \"no gates on tiny is not no-go-needed-to-push\" clarification" \
  || no "ONBOARDING.md drops the clarification that tiny's \"no gates\" still gates pushes"

# ================================================ 4. DEMO.md block structure ==
echo "== 4. DEMO.md's blocks are marked, and every runnable one is executable =="
mkdir -p "$WORK/blocks"
awk -v dir="$WORK/blocks" '
  function newblk(kind, hdr) { n++; f=sprintf("%s/%03d", dir, n);
    printf "%s\n", kind > (f ".kind"); printf "%s\n", hdr > (f ".meta");
    printf "%s\n", NR > (f ".line"); state=1 }
  /^<!-- DEMO:RUN /    { newblk("run", $0); next }
  /^<!-- DEMO:MANUAL/  { newblk("manual", $0); next }
  /^<!-- DEMO:EXPECT / { s=$0; sub(/^<!-- DEMO:EXPECT /,"",s); sub(/ -->$/,"",s);
                         if (f != "") printf "%s\n", s > (f ".expect"); else bad++; next }
  /^```bash$/ { if (state == 1) { state=2; next } else { printf "%s\n", NR > (dir "/UNMARKED") ; next } }
  /^```/      { if (state == 2) { state=0 } ; next }
  state == 2  { printf "%s\n", $0 > (f ".sh") }
  END { printf "%d\n", n > (dir "/COUNT") }
' "$DEMO"
NBLK="$(cat "$WORK/blocks/COUNT" 2>/dev/null || echo 0)"
NRUN=0; NMAN=0
for k in "$WORK/blocks"/*.kind; do
  [ -e "$k" ] || continue
  case "$(cat "$k")" in run) NRUN=$((NRUN+1)) ;; manual) NMAN=$((NMAN+1)) ;; esac
done
[ ! -e "$WORK/blocks/UNMARKED" ] \
  && ok "every \`\`\`bash block in DEMO.md carries a DEMO:RUN or DEMO:MANUAL marker" \
  || { no "DEMO.md has unmarked bash block(s) at line(s): $(tr '\n' ' ' < "$WORK/blocks/UNMARKED")"; }
[ "${NRUN:-0}" -ge 8 ] && ok "DEMO.md defines $NRUN runnable blocks (>= 8, not vacuous)" \
  || no "DEMO.md defines only ${NRUN:-0} runnable blocks — a demo that runs nothing proves nothing"
[ "${NMAN:-0}" -ge 1 ] && ok "DEMO.md marks $NMAN block(s) as not runnable here" \
  || no "DEMO.md marks no block as manual — the parts needing a live session must be named"
[ "${NBLK:-0}" = "$((NRUN + NMAN))" ] && ok "every marked block ($NBLK) resolved to run or manual" \
  || no "marker/block accounting disagrees: $NBLK markers, $NRUN run, $NMAN manual"
# Every runnable block must actually carry a command and at least one documented
# observable. A block with no expectation is a block that cannot regress.
NOEXP=""; EMPTY=""
for k in "$WORK/blocks"/*.kind; do
  b="${k%.kind}"; [ "$(cat "$k")" = "run" ] || continue
  [ -s "$b.sh" ] || EMPTY="$EMPTY $(basename "$b")"
  grep -q 'skip=' "$b.meta" && continue   # an exempted block is checked in §5 instead
  [ -s "$b.expect" ] || NOEXP="$NOEXP $(basename "$b")"
done
[ -z "$EMPTY" ] && ok "every runnable block contains at least one command" || no "empty runnable block(s):$EMPTY"
[ -z "$NOEXP" ] && ok "every runnable block documents at least one expected observable" \
  || no "runnable block(s) with no documented observable:$NOEXP"
# Manual blocks must say, in the doc, why they are not runnable.
BADMAN=""
for k in "$WORK/blocks"/*.kind; do
  b="${k%.kind}"; [ "$(cat "$k")" = "manual" ] || continue
  grep -qE 'reason=[a-z]' "$b.meta" || BADMAN="$BADMAN $(basename "$b"):no-reason"
  ln="$(cat "$b.line")"; from=$(( ln > 20 ? ln - 20 : 1 ))
  { sed -n "${from},$((ln + 12))p" "$DEMO"; } \
    | grep -qiE 'not runnable|live Claude Code session|requires a live|cannot be demonstrated|when you are done|run it yourself' \
    || BADMAN="$BADMAN $(basename "$b"):unexplained"
done
[ -z "$BADMAN" ] && ok "every manual block states why it is not run here (live session / destructive cleanup)" \
  || no "manual block(s) not clearly marked as requiring a live session or manual action:$BADMAN"

# ================================================= 5. run the demo for real ==
echo "== 5. Every runnable DEMO.md block executes and produces its documented output =="
export CO="$SRC"
export WORK_DEMO="$WORK/demo"; mkdir -p "$WORK_DEMO"
export SAMPLE="$WORK_DEMO/sample-project"
# The fixture must survive the demo untouched: the demo copies it and patches the
# COPY. A block that patched docs/sample-project itself would poison every later run.
find "$FIXTURE" -type f | sort | xargs cksum > "$WORK/fixture.before"
NRAN=0; NSKIP=0; BADSKIP=""
for k in $(ls "$WORK/blocks"/*.kind | sort); do
  b="${k%.kind}"; [ "$(cat "$k")" = "run" ] || continue
  id="$(sed -nE 's/.*id=([A-Za-z0-9]+).*/\1/p' "$b.meta")"; id="${id:-$(basename "$b")}"
  want_rc="$(sed -nE 's/.*[^-]rc=([0-9]+).*/\1/p' "$b.meta")"; want_rc="${want_rc:-0}"
  # A block may be exempted from execution ONLY with a declared reason. The one
  # legitimate case: this suite is chained from tests/build_os_tests.sh, so it
  # cannot execute a block that runs tests/build_os_tests.sh without re-entering
  # itself. An exemption still has to prove the command it names is real.
  if grep -q 'skip=' "$b.meta"; then
    NSKIP=$((NSKIP+1))
    reason="$(sed -nE 's/.*skip=([a-z-]+).*/\1/p' "$b.meta")"
    cmd="$(grep -oE '(bash +|\./)[A-Za-z0-9_./-]+\.sh' "$b.sh" | head -n1 | sed 's|^bash  *||')"
    if [ -n "$reason" ] && [ -n "$cmd" ] && [ -x "$SRC/${cmd#./}" ]; then
      ok "demo step $id is exempted from execution (reason: $reason) and the command it names ($cmd) exists and is executable"
    else
      BADSKIP="$BADSKIP $id"
    fi
    continue
  fi
  ( cd "$WORK_DEMO" && CO="$SRC" WORK="$WORK_DEMO" SAMPLE="$SAMPLE" \
      bash "$b.sh" > "$b.out" 2>&1 )
  rc=$?
  NRAN=$((NRAN+1))
  if [ "$rc" = "$want_rc" ]; then
    ok "demo step $id exits $rc as documented"
  else
    no "demo step $id exited $rc, the doc documents $want_rc"
    sed 's/^/      | /' "$b.out" | tail -12
  fi
  while IFS= read -r want; do
    [ -n "$want" ] || continue
    if grep -qF -- "$want" "$b.out"; then
      ok "demo step $id produced: ${want:0:72}"
    else
      no "demo step $id did NOT produce the documented observable: $want"
      sed 's/^/      | /' "$b.out" | tail -8
    fi
  done < "$b.expect"
done
[ "$NRAN" -ge 8 ] && ok "$NRAN demo blocks were actually executed (>= 8, not vacuous)" \
  || no "only $NRAN demo blocks were executed — this section proved nothing"
[ -z "$BADSKIP" ] && ok "every execution exemption declares a reason and names a real command" \
  || no "execution exemption(s) with no reason or naming a missing command:$BADSKIP"
[ "$NSKIP" -le 1 ] && ok "at most one demo block ($NSKIP) is exempted from execution" \
  || no "$NSKIP demo blocks are exempted from execution — exemptions are how a demo stops being runnable"
# The demo must leave the machine's real state alone: everything under $WORK.
[ -d "$SAMPLE/build-os" ] && ok "the demo built its throwaway repo under the temp dir, not in this repo" \
  || no "the demo did not create its sample repo where it said it would"
find "$FIXTURE" -type f | sort | xargs cksum > "$WORK/fixture.after"
cmp -s "$WORK/fixture.before" "$WORK/fixture.after" \
  && ok "running the demo left docs/sample-project byte-identical (it patched its copy, not the source)" \
  || { no "running the demo modified docs/sample-project in this repository"; diff "$WORK/fixture.before" "$WORK/fixture.after" | sed 's/^/      | /'; }

# ================================================== 6. every path is alive ==
echo "== 6. Every repo path and command the docs name exists (and .sh is executable) =="
# Some paths exist only in an INSTALLED target repo (.gravito-managed) or only
# after a rotation (memory/archive/). Resolve against this repo, a freshly
# installed repo, and the demo's own sample repo.
PCHK="$WORK/pathcheck"; mkdir -p "$PCHK"
( cd "$PCHK" && git init -q . && "$SRC/install-project.sh" "$PCHK" ) > "$WORK/pathcheck.log" 2>&1 \
  && ok "a fresh install into a blank repo succeeded (path resolution baseline)" \
  || { no "install-project.sh failed on a blank repo"; tail -5 "$WORK/pathcheck.log" | sed 's/^/      | /'; }

resolve(){ # resolve <relpath> -> 0 if it exists in any root the docs can mean
  local p="${1%/}"
  [ -e "$SRC/$p" ] || [ -e "$PCHK/$p" ] || [ -e "$SAMPLE/$p" ] || [ -e "$DOCS/$p" ]
}
executable(){ local p="${1%/}"
  for r in "$SRC" "$PCHK" "$SAMPLE" "$DOCS"; do
    [ -f "$r/$p" ] && { [ -x "$r/$p" ] && return 0 || return 1; }
  done
  return 1; }

# (a) the first word of every inline `code span` that looks like a repo path
grep -ohE '`[^`]+`' "$ONB" "$DEMO" "$PILOT" | tr -d '`' | awk '{print $1}' \
  | grep -E '/' | grep -vE '^[/~$]|^https?:|[*<>{}]|\$' | sed 's/[.,:;)]*$//' | sort -u > "$WORK/paths.txt"
# (b) every relative markdown link target
grep -ohE '\]\([^)]+\)' "$ONB" "$DEMO" "$PILOT" "$FIXTURE/README.md" \
  | sed -E 's/^\]\(//; s/\)$//' | grep -vE '^https?:|^#' | sort -u > "$WORK/links.txt"

NPATH=0; DEAD=""
while IFS= read -r p; do
  [ -n "$p" ] || continue
  NPATH=$((NPATH+1))
  resolve "$p" || DEAD="$DEAD $p"
done < "$WORK/paths.txt"
[ -z "$DEAD" ] && ok "all $NPATH repo paths named in the three docs resolve" \
  || no "the docs name path(s) that do not exist:$DEAD"
[ "$NPATH" -ge 20 ] && ok "the path scanner checked $NPATH paths (>= 20, not vacuous)" \
  || no "the path scanner checked only $NPATH paths — it has gone blind"

NLINK=0; DEADLINK=""
while IFS= read -r l; do
  [ -n "$l" ] || continue
  NLINK=$((NLINK+1))
  # links are relative to docs/ (the sample README's are relative to its own dir)
  [ -e "$DOCS/$l" ] || [ -e "$FIXTURE/$l" ] || DEADLINK="$DEADLINK $l"
done < "$WORK/links.txt"
[ -z "$DEADLINK" ] && ok "all $NLINK markdown links in the kit resolve to a real file" \
  || no "dead markdown link(s):$DEADLINK"
[ "$NLINK" -ge 5 ] && ok "the link scanner checked $NLINK links (>= 5, not vacuous)" \
  || no "the link scanner checked only $NLINK links"

NSH=0; NOTX=""
while IFS= read -r p; do
  case "$p" in *.sh) ;; *) continue ;; esac
  NSH=$((NSH+1))
  executable "$p" || NOTX="$NOTX $p"
done < "$WORK/paths.txt"
[ -z "$NOTX" ] && ok "all $NSH scripts the docs tell you to run are executable" \
  || no "the docs name script(s) that are not executable:$NOTX"
[ "$NSH" -ge 5 ] && ok "the executable scanner checked $NSH scripts (>= 5, not vacuous)" \
  || no "the executable scanner checked only $NSH scripts"

# =============================================== 7. the rubric can be failed ==
echo "== 7. PILOT.md's rubric is falsifiable in form =="
grep -E '^\| \*\*R[0-9]+\*\*' "$PILOT" > "$WORK/rubric.txt"
NCRIT="$(grep -c . "$WORK/rubric.txt")"
[ "${NCRIT:-0}" -ge 6 ] && ok "the rubric declares $NCRIT criteria (>= 6, not vacuous)" \
  || no "the rubric declares only ${NCRIT:-0} criteria — too thin to fail on"
NOFAIL=""
while IFS= read -r row; do
  id="$(printf '%s' "$row" | awk -F'|' '{gsub(/[ *]/,"",$2); print $2}')"
  fails="$(printf '%s' "$row" | awk -F'|' '{v=$4; gsub(/^[ \t]+|[ \t]+$/,"",v); print v}')"
  [ "${#fails}" -ge 15 ] || NOFAIL="$NOFAIL $id"
done < "$WORK/rubric.txt"
[ -z "$NOFAIL" ] && ok "every criterion states, in its own row, the condition under which it FAILS" \
  || no "criteri(a) with no stated failure condition:$NOFAIL"
# Unfalsifiable criteria are the thing a rubric exists to exclude.
BANNED="$(grep -inE 'feels|satisfaction|seems|happier|morale|delight|smoother|more productive|confidence in' "$WORK/rubric.txt")"
[ -z "$BANNED" ] && ok "no criterion is stated in unfalsifiable terms (feelings, satisfaction, vibes)" \
  || { no "unfalsifiable criterion language in the rubric"; printf '      | %s\n' "$BANNED"; }
grep -qiE 'veto' "$PILOT" && ok "the rubric names a veto criterion that fails the pilot on its own" \
  || no "no single criterion can fail the pilot on its own — every rubric needs one"
grep -qiE 'INSUFFICIENT EVIDENCE' "$PILOT" \
  && ok "the rubric can return INSUFFICIENT EVIDENCE (a pilot that recorded nothing is not a pass)" \
  || no "the rubric has no verdict for a pilot that produced no evidence"
grep -qiE 'gamed|game' "$PILOT" && ok "the rubric states how it can be gamed" \
  || no "the rubric never says how it could be gamed — which is what a sales document omits"

# ============================ 8. the rubric can be failed, PROVEN BY RUNNING ==
echo "== 8. Every PILOT:CHECK passes on a compliant repo and FAILS on a violating one =="
mkdir -p "$WORK/checks"
awk -v dir="$WORK/checks" '
  /^<!-- PILOT:CHECK / { id=$0; sub(/.*id=/,"",id); sub(/[^A-Za-z0-9].*/,"",id);
                         f=dir "/" id ".sh"; printf "%s\n", id >> (dir "/IDS"); state=1; next }
  /^```bash$/ { if (state == 1) { state=2; next } }
  /^```/      { if (state == 2) { state=0 }; next }
  state == 2  { printf "%s\n", $0 > f }
' "$PILOT"
NCHK="$(grep -c . "$WORK/checks/IDS" 2>/dev/null || echo 0)"
[ "${NCHK:-0}" -ge 6 ] && ok "PILOT.md ships $NCHK executable criterion checks (>= 6, not vacuous)" \
  || no "PILOT.md ships only ${NCHK:-0} executable checks — the rest is prose"

# --- fixtures -----------------------------------------------------------------
# PASS repo satisfies every criterion; FAIL repo violates every one of them.
TAB="$(printf '\t')"
row(){ local IFS="$TAB"; printf '%s\n' "$*"; }   # join 16 fields with tabs
mk_repo(){ # mk_repo <dir> <pass|fail>
  local d="$1" mode="$2"
  mkdir -p "$d" && cd "$d" || return 1
  git init -q .
  git config user.email pilot@example.com; git config user.name Pilot
  cp "$FIXTURE/check.sh" "$FIXTURE/slugify.sh" .
  chmod +x check.sh slugify.sh
  if [ "$mode" = "fail" ]; then
    # commit 1 is RED in isolation: the assertion lands (before the RESULT line,
    # where the suite actually evaluates it) without the fix that satisfies it.
    python3 - check.sh <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
a = 'eq "ALL CAPS"       "all-caps"        "input is lowercased"\n'
open(p, 'w').write(s.replace(a, a + 'eq "Hello, World!"  "hello-world"     "no trailing dash"\n'))
PY
  fi
  git add -A && git commit -qm "commit one"
  echo "$(git rev-parse HEAD)" > "$d/.commit1"
  printf 'note\n' > note.txt && git add -A && git commit -qm "commit two"
  mkdir -p build-os/memory build-os/receipts build-os/metrics
  cp "$ROUTER" build-os/memory/tool_router.md
  printf '# Current State\n\n## Now\n\nSmall.\n' > build-os/memory/current_state.md
  local store="build-os/metrics/packet_metrics.tsv"
  "$SRC/build-os/metrics/record-packet.sh" --header > "$store"
  if [ "$mode" = "pass" ]; then
    printf -- '- **Lane:** `tiny`\n' > build-os/receipts/pkt_one.md
    row pkt_one 2026-07-31 tiny 2 - - 1 1 3 0 1 1 0 - transcript \
        "week-one row, typed by the operator at close" >> "$store"
    git for-each-ref --format='%(refname) %(objectname)' refs/remotes > "$d/.baseline"
    : > "$d/.golog"
  else
    printf -- '- **Lane:** `turbo`\n' > build-os/receipts/pkt_one.md   # R1: unknown lane
    printf -- '- **Lane:** `tiny`\n'  > build-os/receipts/pkt_three.md # R5: receipt with no row
    # R6: a tiny packet at 6 rounds. R8: defects_escaped unaudited.
    row pkt_one 2026-07-31 tiny 6 - - 1 1 3 0 1 1 - - transcript \
        "over the round budget and never audited for escapes" >> "$store"
    # R3: a row with no receipt.
    row pkt_two 2026-07-31 tiny 1 - - 1 1 3 0 1 0 - - transcript \
        "closed without ever writing a receipt" >> "$store"
    # R7: a memory file past the 256 KB Read limit.
    head -c 300000 /dev/zero | tr '\0' 'x' > build-os/memory/residue.md
    # R2: a remote-tracking ref moved, with an empty baseline and no recorded go.
    git update-ref refs/remotes/origin/main "$(git rev-parse HEAD)"
    : > "$d/.baseline"
    : > "$d/.golog"
  fi
  cd - > /dev/null
}
mk_repo "$WORK/pass_repo" pass > "$WORK/mkpass.log" 2>&1 \
  && ok "built a fixture repo that satisfies the rubric" \
  || { no "could not build the compliant fixture"; tail -5 "$WORK/mkpass.log" | sed 's/^/      | /'; }
mk_repo "$WORK/fail_repo" fail > "$WORK/mkfail.log" 2>&1 \
  && ok "built a fixture repo that violates the rubric" \
  || { no "could not build the violating fixture"; tail -5 "$WORK/mkfail.log" | sed 's/^/      | /'; }

run_check(){ # run_check <id> <repo> ; echoes exit code
  local id="$1" repo="$2"
  ( export PILOT_REPO="$repo" CO="$SRC" \
      PILOT_STORE="$repo/build-os/metrics/packet_metrics.tsv" \
      PILOT_BASELINE="$repo/.baseline" PILOT_GOLOG="$repo/.golog" \
      PILOT_COMMIT1="$(cat "$repo/.commit1")" PILOT_SUITE='bash check.sh'
    cd "$repo" && bash "$WORK/checks/$id.sh" ) > "$WORK/checks/$id.$(basename "$repo").out" 2>&1
  echo $?
}
NPAIR=0
while IFS= read -r id; do
  [ -n "$id" ] || continue
  NPAIR=$((NPAIR+1))
  rc_pass="$(run_check "$id" "$WORK/pass_repo")"
  rc_fail="$(run_check "$id" "$WORK/fail_repo")"
  if [ "$rc_pass" = "0" ]; then
    ok "$id passes (exit 0) on a repo that satisfies it"
  else
    no "$id FAILED on a compliant repo (exit $rc_pass) — the criterion is unsatisfiable as written"
    sed 's/^/      | /' "$WORK/checks/$id.pass_repo.out" | tail -6
  fi
  if [ "$rc_fail" != "0" ]; then
    ok "$id FAILS (exit $rc_fail) on a repo that violates it — the criterion is falsifiable"
  else
    no "$id passed on a repo that violates it — an unfalsifiable criterion is a sales document"
    sed 's/^/      | /' "$WORK/checks/$id.fail_repo.out" | tail -6
  fi
done < "$WORK/checks/IDS"
[ "$NPAIR" -ge 6 ] && ok "$NPAIR criteria were exercised in both directions (>= 6, not vacuous)" \
  || no "only $NPAIR criteria were exercised — this section proved nothing"

# ============================================ 9. the kit's own honesty rules ==
echo "== 9. The kit says what it cannot do =="
grep -qiE 'live Claude Code session' "$DEMO" \
  && ok "DEMO.md names the live-session limit rather than staging it" \
  || no "DEMO.md does not name what needs a live Claude Code session"
grep -qiE 'instruction|permission system' "$ONB" \
  && ok "ONBOARDING.md is explicit that the hard gates are instructions + your permission system" \
  || no "ONBOARDING.md implies the hard gates are mechanically enforced"
grep -qiE 'UNGUARDED' "$ONB" \
  && ok "ONBOARDING.md states that a bare node --test is unguarded" \
  || no "ONBOARDING.md does not state why the sanctioned wrapper exists"
grep -qF 'run-tests.sh' "$ONB" && grep -qF 'node --test' "$ONB" \
  && ok "ONBOARDING.md names the sanctioned command and the unguarded one it replaces" \
  || no "ONBOARDING.md does not name both the sanctioned command and the unguarded path"
grep -qiE 'GRAVITO:MANAGED' "$ONB" && grep -qiE 'gravito-managed' "$ONB" \
  && ok "ONBOARDING.md explains the managed/yours split and names the manifest file" \
  || no "ONBOARDING.md does not explain which files are managed and which are yours"
grep -qiE '`-` means unmeasured|means unmeasured and never means zero' "$ONB" \
  && ok "ONBOARDING.md states that \`-\` means unmeasured, never zero" \
  || no "ONBOARDING.md does not explain the store's unmeasured cell convention"
grep -qiE 'receipt' "$ONB" && grep -qF 'build-os/receipts/' "$ONB" \
  && ok "ONBOARDING.md explains what a receipt is and where it lives" \
  || no "ONBOARDING.md does not explain receipts"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
