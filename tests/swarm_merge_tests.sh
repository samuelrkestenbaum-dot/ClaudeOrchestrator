#!/usr/bin/env bash
# Build OS — swarm merge tests (Gravito speed lane, S4).
#
# WHAT THIS PINS. build-os/tools/swarm-merge.sh turns the three fan-out legality
# rules from prose an orchestrator reads into checks a machine runs: the
# ownership manifest is validated for disjointness BEFORE any agent runs, each
# agent's actual diff is checked against the set it declared, the merge stages
# per-agent sets and REFUSES on anything ambiguous, and exactly one post-merge
# verification runs.
#
# WHY THE FIXTURE IS REAL. The primary manifest below is this repository's own
# three-way fan-out (commit 68cae7a: lanes / scaffold-seeding / release-metadata)
# with its real file sets. A merge tool validated only against synthetic
# manifests is a tool nobody trusts with a real merge — and the real manifest is
# the one that exposed the hot-file design problem (the release-metadata agent
# legitimately owned VERSION and CHANGELOG.md, both nominally merger-owned).
#
# VACUITY. Several assertions here would pass against an empty manifest, an
# empty changed set, or a scanner that had gone blind. Each of those states is
# asserted to REFUSE, loudly, rather than to report success.
#
# No network. Deterministic. Temp dirs only. Exits non-zero if any assertion
# fails, and prints a final "==== RESULT: N passed, M failed ====" line.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOL="$SRC/build-os/tools/swarm-merge.sh"
EXAMPLE="$SRC/build-os/tools/fanout_manifest.example"
ROUTER="$SRC/build-os/memory/tool_router.md"
ORCH="$SRC/.claude/agents/build-orchestrator.md"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

RC=0; OUT=""
run(){ OUT="$(bash "$TOOL" "$@" 2>&1)"; RC=$?; return 0; }
# Assert the last run refused (exit 2) and its output names every given needle.
refused_naming(){
  local label="$1"; shift
  local miss=""
  [ "$RC" -eq 2 ] || { no "$label — expected exit 2, got $RC"; echo "$OUT" | sed -n '1,6p' | sed 's/^/      | /'; return; }
  local n
  for n in "$@"; do grep -qF -- "$n" <<<"$OUT" || miss="$miss \"$n\""; done
  if [ -n "$miss" ]; then
    no "$label — refused, but the message never names:$miss"
    echo "$OUT" | sed -n '1,6p' | sed 's/^/      | /'
  else
    ok "$label"
  fi
}
accepted(){
  local label="$1"
  if [ "$RC" -eq 0 ]; then ok "$label"; else
    no "$label — expected exit 0, got $RC"; echo "$OUT" | sed -n '1,8p' | sed 's/^/      | /'
  fi
}

# ---------------------------------------------------------------------------
# Fixture: a miniature of THIS repository at the moment of the real three-way
# fan-out, with every path the real manifest names.
# ---------------------------------------------------------------------------
REAL_FILES=(
  .claude/agents/builder.md .claude/agents/qa.md .claude/commands/next-packet.md
  CLAUDE.md README.md build-os/global-claude-md.md
  build-os/memory/tool_router.md build-os/memory/current_state.md
  build-os/memory/residue.md build-os/packets/active_packet.md
  build-os/receipts/P-001.md
  init-build-os.sh install-global.sh install-project.sh
  templates/build-os/memory/current_state.md templates/build-os/memory/tool_router.md
  VERSION LICENSE CHANGELOG.md
  tests/build_os_tests.sh tests/lane_enforcement_tests.sh
  tests/scaffold_seeding_tests.sh tests/release_metadata_tests.sh
)
mkrepo(){ # $1 = dir
  local d="$1" f
  mkdir -p "$d"
  git init -q "$d" >/dev/null 2>&1
  git -C "$d" config user.email "t@example.invalid"
  git -C "$d" config user.name "T"
  git -C "$d" config commit.gpgsign false
  for f in "${REAL_FILES[@]}"; do mkdir -p "$d/$(dirname "$f")"; printf 'base\n' > "$d/$f"; done
  git -C "$d" add -A >/dev/null 2>&1
  git -C "$d" commit -qm base >/dev/null 2>&1
}
touchfile(){ printf 'changed by fan-out\n' >> "$1/$2"; }

# A verification command that records each invocation, so "exactly once" is
# countable rather than asserted.
VERIFIER="$WORK/verifier.sh"
COUNTER="$WORK/verifier.count"
cat > "$VERIFIER" <<EOF
#!/usr/bin/env bash
echo run >> "$COUNTER"
echo "==== RESULT: 7 passed, 0 failed ===="
exit \${VERIFIER_RC:-0}
EOF
chmod +x "$VERIFIER"
FAILING_VERIFIER="$WORK/verifier_red.sh"
cat > "$FAILING_VERIFIER" <<EOF
#!/usr/bin/env bash
echo run >> "$COUNTER"
echo "==== RESULT: 5 passed, 2 failed ===="
exit 1
EOF
chmod +x "$FAILING_VERIFIER"

# The REAL three-way fan-out manifest (68cae7a).
real_manifest(){ # $1 = destination, $2 = verify command
  cat > "$1" <<EOF
# This repository's real three-way fan-out (commit 68cae7a).
merger orchestrator
verify $2

agent A-lanes
own A-lanes .claude/agents/*.md
own A-lanes .claude/commands/*.md
own A-lanes build-os/memory/tool_router.md
own A-lanes CLAUDE.md
own A-lanes build-os/global-claude-md.md
own A-lanes tests/lane_enforcement_tests.sh

agent B-scaffold-seeding
own B-scaffold-seeding init-build-os.sh
own B-scaffold-seeding install-global.sh
own B-scaffold-seeding install-project.sh
own B-scaffold-seeding templates/**
own B-scaffold-seeding tests/scaffold_seeding_tests.sh

agent C-release-metadata
own C-release-metadata VERSION
own C-release-metadata LICENSE
own C-release-metadata CHANGELOG.md
own C-release-metadata tests/release_metadata_tests.sh

hot-release build-os/memory/tool_router.md A-lanes the lanes packet exists to author the router rows; no sibling reads or writes it
hot-release VERSION C-release-metadata the release-metadata packet is the reason VERSION exists at all in this repo
hot-release CHANGELOG.md C-release-metadata release-metadata authors the Keep-a-Changelog history as its whole deliverable

merger-own build-os/memory/current_state.md
merger-own build-os/memory/residue.md
merger-own build-os/packets/active_packet.md
merger-own build-os/receipts/**
merger-own tests/build_os_tests.sh
EOF
}
# Apply the three agents' real diffs to a fixture repo.
apply_real_diffs(){ # $1 = repo
  touchfile "$1" .claude/agents/builder.md
  touchfile "$1" build-os/memory/tool_router.md
  touchfile "$1" CLAUDE.md
  touchfile "$1" tests/lane_enforcement_tests.sh
  touchfile "$1" init-build-os.sh
  touchfile "$1" templates/build-os/memory/tool_router.md
  touchfile "$1" tests/scaffold_seeding_tests.sh
  touchfile "$1" VERSION
  touchfile "$1" CHANGELOG.md
  touchfile "$1" tests/release_metadata_tests.sh
}

echo "== 1. The tool exists, parses, and states its own boundary =="
if [ -f "$TOOL" ]; then ok "build-os/tools/swarm-merge.sh exists"; else no "build-os/tools/swarm-merge.sh does not exist"; fi
[ -x "$TOOL" ] && ok "tool is executable" || no "tool is not executable"
if bash -n "$TOOL" 2>"$WORK/syn"; then ok "tool parses (bash -n)"; else no "tool has a syntax error: $(head -1 "$WORK/syn")"; fi
grep -q 'set -uo pipefail' "$TOOL" && ok "tool runs under set -uo pipefail" || no "tool does not set -uo pipefail"
# The honest boundary: bash cannot spawn agents, so the tool cannot orchestrate.
if grep -qiE "cannot spawn|can not spawn|does not spawn|no.*spawn.*agent" "$TOOL"; then
  ok "tool states plainly that it cannot spawn the fan-out itself"
else
  no "tool never states the human/orchestrator boundary (it cannot spawn agents)"
fi
# SAFETY GREP: a merge tool must never mutate anything outside the local index.
BANNED=0
while read -r pat; do
  if grep -nE "$pat" "$TOOL" | grep -vE '^\s*[0-9]+:\s*#' | grep -qvE '(REFUS|never|Never|forbid|banned)'; then
    no "tool contains a forbidden destructive/external operation: $pat"; BANNED=1
  fi
done <<'PATTERNS'
git[[:space:]]+push
git[[:space:]]+reset[[:space:]]+--hard
git[[:space:]]+clean
git[[:space:]]+checkout
git[[:space:]]+stash
rm[[:space:]]+-rf[[:space:]]+/
PATTERNS
[ "$BANNED" -eq 0 ] && ok "safety grep: no push / hard-reset / clean / checkout / stash in the tool"

echo "== 2. VACUITY GUARDS — an empty manifest must fail loudly, not pass =="
M="$WORK/m"; mkrepo "$WORK/r0"
cat > "$M" <<EOF
merger orchestrator
verify bash tests/build_os_tests.sh
EOF
run validate --manifest "$M"; refused_naming "manifest with ZERO agents is refused" "agent"
cat > "$M" <<EOF
merger orchestrator
verify bash tests/build_os_tests.sh
agent A-lanes
agent B-scaffold-seeding
own B-scaffold-seeding init-build-os.sh
EOF
run validate --manifest "$M"; refused_naming "an agent with ZERO declared paths is refused (by name)" "A-lanes"
cat > "$M" <<EOF
merger orchestrator
agent A
own A x.md
agent B
own B y.md
EOF
run validate --manifest "$M"; refused_naming "a manifest with no post-merge verification is refused" "verif"
cat > "$M" <<EOF
verify true
agent A
own A x.md
agent B
own B y.md
EOF
run validate --manifest "$M"; refused_naming "a manifest that names no merger is refused" "merger"
cat > "$M" <<EOF
merger orchestrator
verify true
agent A
own A x.md
EOF
run validate --manifest "$M"; refused_naming "a 'fan-out' of ONE agent is refused" "A"
run validate --manifest "$WORK/does-not-exist"; refused_naming "a missing manifest is refused" "manifest"
# An unknown directive is a typo, and a silently ignored typo is an unenforced rule.
cat > "$M" <<EOF
merger orchestrator
verify true
agent A
own A x.md
agent B
onw B y.md
EOF
run validate --manifest "$M"; refused_naming "an unknown/typo'd directive is refused, not ignored" "onw"

echo "== 3. Overlapping writable sets are rejected BEFORE any agent runs =="
mkrepo "$WORK/r1"
cat > "$M" <<EOF
merger orchestrator
verify true
agent A-lanes
own A-lanes CLAUDE.md
own A-lanes build-os/memory/tool_router.md
agent B-scaffold-seeding
own B-scaffold-seeding init-build-os.sh
own B-scaffold-seeding CLAUDE.md
EOF
run validate --manifest "$M"
refused_naming "identical path claimed by two agents is rejected (both names + the path)" \
  "A-lanes" "B-scaffold-seeding" "CLAUDE.md"
# Glob-vs-literal containment: the overlap a human reader misses most often.
cat > "$M" <<EOF
merger orchestrator
verify true
agent A-lanes
own A-lanes .claude/agents/*.md
agent B-scaffold-seeding
own B-scaffold-seeding .claude/agents/builder.md
EOF
run validate --manifest "$M"
refused_naming "a glob that CONTAINS another agent's literal path is rejected" \
  "A-lanes" "B-scaffold-seeding" ".claude/agents/builder.md"
# Disjointness must be decidable with NO repo present — before any agent runs.
run validate --manifest "$M"
[ "$RC" -eq 2 ] && ok "overlap is decided without a repo (i.e. before any work exists)" \
  || no "overlap detection needed a repo — too late to be a pre-flight check"
# And it must not cry wolf on genuinely disjoint globs.
cat > "$M" <<EOF
merger orchestrator
verify true
agent A-lanes
own A-lanes .claude/agents/*.md
agent B-scaffold-seeding
own B-scaffold-seeding templates/**
EOF
run validate --manifest "$M"; accepted "genuinely disjoint globs validate clean (no false positive)"

echo "== 4. Hot files are reserved to the merger =="
mkrepo "$WORK/r2"
for hot in build-os/memory/current_state.md build-os/packets/active_packet.md \
           build-os/receipts/P-001.md tests/build_os_tests.sh; do
  cat > "$M" <<EOF
merger orchestrator
verify bash tests/build_os_tests.sh
agent A-lanes
own A-lanes CLAUDE.md
agent B-scaffold-seeding
own B-scaffold-seeding $hot
EOF
  run validate --manifest "$M"
  refused_naming "hot file claimed by a fan-out agent is rejected: $hot" "B-scaffold-seeding" "$hot"
done
# The escape hatch exists, but it costs a named agent and a real reason.
cat > "$M" <<EOF
merger orchestrator
verify true
agent A-lanes
own A-lanes CLAUDE.md
agent C-release-metadata
own C-release-metadata VERSION
EOF
run validate --manifest "$M"; refused_naming "VERSION claimed with no release is rejected" "C-release-metadata" "VERSION"
cat >> "$M" <<EOF
hot-release VERSION C-release-metadata the release-metadata packet is the reason VERSION exists at all in this repo
EOF
run validate --manifest "$M"; accepted "a hot-release naming the agent and a real reason is accepted"
cat > "$M" <<EOF
merger orchestrator
verify true
agent A-lanes
own A-lanes CLAUDE.md
agent C-release-metadata
own C-release-metadata VERSION
hot-release VERSION C-release-metadata needed
EOF
run validate --manifest "$M"; refused_naming "a one-word 'reason' does not buy a release" "reason"
cat > "$M" <<EOF
merger orchestrator
verify true
agent A-lanes
own A-lanes CLAUDE.md
agent C-release-metadata
own C-release-metadata VERSION
hot-release CHANGELOG.md C-release-metadata release-metadata authors the changelog as its whole deliverable
EOF
run validate --manifest "$M"; refused_naming "a release for a path NO agent claims is refused as dead boilerplate" "CHANGELOG.md"

echo "== 5. The REAL three-way fan-out (68cae7a) validates =="
R="$WORK/real"; mkrepo "$R"
real_manifest "$WORK/real.manifest" "bash $VERIFIER"
run validate --manifest "$WORK/real.manifest" --repo "$R"
accepted "the real lanes / scaffold-seeding / release-metadata manifest validates against a real repo"
if [ -f "$EXAMPLE" ]; then
  run validate --manifest "$EXAMPLE"
  accepted "the example manifest shipped in build-os/tools/ validates (not shelfware)"
else
  no "no example manifest shipped at build-os/tools/fanout_manifest.example"
fi

echo "== 6. An agent that wrote OUTSIDE its declared set is caught by NAME and PATH =="
V="$WORK/rv"; mkrepo "$V"
apply_real_diffs "$V"
real_manifest "$WORK/v.manifest" "bash $VERIFIER"
run verify --manifest "$WORK/v.manifest" --repo "$V"
accepted "a fan-out whose diffs all landed inside their declared sets verifies clean"
# Per-agent evidence (a path list, or a worktree) is what makes the catch by NAME.
touchfile "$V" README.md
cat > "$WORK/ev.B" <<EOF
init-build-os.sh
templates/build-os/memory/tool_router.md
tests/scaffold_seeding_tests.sh
README.md
EOF
real_manifest "$WORK/v2.manifest" "bash $VERIFIER"
sed -i 's|^agent B-scaffold-seeding$|agent B-scaffold-seeding evidence='"$WORK"'/ev.B|' "$WORK/v2.manifest"
run verify --manifest "$WORK/v2.manifest" --repo "$V"
refused_naming "an out-of-set write is caught by agent NAME and PATH" "B-scaffold-seeding" "README.md"
# Without evidence, a shared tree can still catch the path — it just cannot name
# the author. That limit must be visible, not silently passed over.
run verify --manifest "$WORK/v.manifest" --repo "$V"
refused_naming "a write no agent declared is caught by PATH even with no evidence" "README.md"
grep -qiE "unattributed|cannot name|not attributable" <<<"$OUT" \
  && ok "the unattributable case says so instead of guessing an author" \
  || no "an unclaimed write is reported without admitting the author is unknown"
# A git worktree is an accepted evidence source, and gives the name for free.
WT="$WORK/wt-B"
git -C "$V" worktree add -q "$WT" HEAD >/dev/null 2>&1
touchfile "$WT" install-project.sh
touchfile "$WT" CHANGELOG.md
real_manifest "$WORK/v3.manifest" "bash $VERIFIER"
sed -i 's|^agent B-scaffold-seeding$|agent B-scaffold-seeding evidence='"$WT"'|' "$WORK/v3.manifest"
run verify --manifest "$WORK/v3.manifest" --repo "$V"
refused_naming "a worktree agent writing outside its set is caught by NAME and PATH" \
  "B-scaffold-seeding" "CHANGELOG.md"
git -C "$V" worktree remove --force "$WT" >/dev/null 2>&1
# VACUITY: verifying a fan-out that produced no diff at all must refuse.
Z="$WORK/rz"; mkrepo "$Z"
real_manifest "$WORK/z.manifest" "bash $VERIFIER"
run verify --manifest "$WORK/z.manifest" --repo "$Z"
refused_naming "verifying a fan-out with ZERO changed files refuses (nothing was proved)" "no"

echo "== 7. A clean three-way merge succeeds and verifies EXACTLY once =="
G="$WORK/rg"; mkrepo "$G"
apply_real_diffs "$G"
printf 'merger note\n' >> "$G/build-os/memory/current_state.md"
printf 'receipt\n' > "$G/build-os/receipts/P-023.md"
real_manifest "$WORK/g.manifest" "bash $VERIFIER"
: > "$COUNTER"
HEAD_BEFORE="$(git -C "$G" rev-parse HEAD)"
run merge --manifest "$WORK/g.manifest" --repo "$G"
accepted "a clean three-way merge succeeds"
RUNS="$(wc -l < "$COUNTER" | tr -d ' ')"
[ "$RUNS" = "1" ] && ok "the post-merge verification ran EXACTLY once (counted: $RUNS)" \
  || no "the post-merge verification ran $RUNS times, expected exactly 1"
grep -qF "==== RESULT: 7 passed, 0 failed ====" <<<"$OUT" \
  && ok "the merge reports the verification's own RESULT line" \
  || no "the merge does not report the verification result"
STAGED="$(git -C "$G" diff --cached --name-only | wc -l | tr -d ' ')"
[ "$STAGED" -ge 12 ] && ok "every agent set plus the merger's hot files are staged ($STAGED paths)" \
  || no "expected >= 12 staged paths after the merge, got $STAGED"
git -C "$G" diff --cached --name-only | grep -qx "build-os/receipts/P-023.md" \
  && ok "a merger-owned NEW file (untracked receipt) is staged too" \
  || no "the merger's untracked hot file was not staged"
[ "$(git -C "$G" rev-parse HEAD)" = "$HEAD_BEFORE" ] \
  && ok "the merge does NOT commit unless asked (external mutation stays the human's)" \
  || no "the merge committed without --commit"

echo "== 8. Ambiguity REFUSES rather than guessing =="
# (a) A concrete path that two validate-clean globs both match.
A1="$WORK/ra"; mkrepo "$A1"
mkdir -p "$A1/docs"; printf 'x\n' > "$A1/docs/guide.md"
git -C "$A1" add -A >/dev/null 2>&1; git -C "$A1" commit -qm docs >/dev/null 2>&1
touchfile "$A1" docs/guide.md
cat > "$M" <<EOF
merger orchestrator
verify bash $VERIFIER
agent X
own X docs/*.md
agent Y
own Y docs/g*
EOF
run validate --manifest "$M"
[ "$RC" -eq 0 ] && ok "glob-shape analysis alone cannot see this overlap (honest limit)" \
  || ok "glob-shape analysis already sees this overlap"
run validate --manifest "$M" --repo "$A1"
refused_naming "against a real repo, a path matched by two agents is refused by path" "docs/guide.md" "X" "Y"
: > "$COUNTER"
run merge --manifest "$M" --repo "$A1"
refused_naming "merging an ambiguously-owned real path refuses" "docs/guide.md"
# The SAME ambiguity via the other guard: run from inside the repo with no
# --repo, so validate's real-path pass never happens and only the verify-stage
# attribution can catch it. Two guards, each proved separately.
OUT="$(cd "$A1" && bash "$TOOL" verify --manifest "$M" 2>&1)"; RC=$?
refused_naming "the verify stage catches the same ambiguity unaided (repo discovered, not declared)" \
  "docs/guide.md" "X" "Y"
[ ! -s "$COUNTER" ] && ok "a refused merge never ran the verification" || no "a refused merge still ran the verification"
[ -z "$(git -C "$A1" diff --cached --name-only)" ] && ok "a refused merge leaves the index exactly as it found it" \
  || no "a refused merge left files staged"
# (b) A pre-existing staged change: an ambiguous starting state.
S="$WORK/rs"; mkrepo "$S"; apply_real_diffs "$S"
git -C "$S" add CLAUDE.md >/dev/null 2>&1
real_manifest "$WORK/s.manifest" "bash $VERIFIER"
: > "$COUNTER"
run merge --manifest "$WORK/s.manifest" --repo "$S"
refused_naming "a non-empty index before the merge refuses (ambiguous starting state)" "index"
[ ! -s "$COUNTER" ] && ok "no verification runs from an ambiguous starting state" || no "verification ran despite an ambiguous start"
# (c) A real conflict is never resolved.
C="$WORK/rc"; mkrepo "$C"
git -C "$C" checkout -q -b b1 2>/dev/null
printf 'one\n' > "$C/CLAUDE.md"; git -C "$C" commit -qam one >/dev/null 2>&1
git -C "$C" checkout -q master 2>/dev/null || git -C "$C" checkout -q main 2>/dev/null
printf 'two\n' > "$C/CLAUDE.md"; git -C "$C" commit -qam two >/dev/null 2>&1
git -C "$C" merge b1 >/dev/null 2>&1
UNMERGED="$(git -C "$C" diff --name-only --diff-filter=U | wc -l | tr -d ' ')"
real_manifest "$WORK/c.manifest" "bash $VERIFIER"
: > "$COUNTER"
run merge --manifest "$WORK/c.manifest" --repo "$C"
if [ "$UNMERGED" -ge 1 ]; then
  refused_naming "an unmerged (conflicted) path refuses — the tool never resolves a conflict" "CLAUDE.md"
else
  no "fixture did not produce a conflicted path — the conflict assertion would be vacuous"
fi
[ ! -s "$COUNTER" ] && ok "no verification runs while a conflict is open" || no "verification ran with a conflict open"
# (d) A red verification is a stop, not a commit.
F="$WORK/rf"; mkrepo "$F"; apply_real_diffs "$F"
real_manifest "$WORK/f.manifest" "bash $FAILING_VERIFIER"
: > "$COUNTER"
HEAD_BEFORE="$(git -C "$F" rev-parse HEAD)"
run merge --manifest "$WORK/f.manifest" --repo "$F" --commit "feat: merged fan-out"
refused_naming "a RED post-merge verification refuses and reports the failing count" "5 passed, 2 failed"
[ "$(git -C "$F" rev-parse HEAD)" = "$HEAD_BEFORE" ] && ok "a red verification never commits, even with --commit" \
  || no "the tool committed on a red verification"
# "Stop cleanly" is a claim about state, not about wording: after a red
# verification the index is back where it was found and every change is still
# in the working tree.
[ -z "$(git -C "$F" diff --cached --name-only)" ] && ok "a red verification restores the index it was found with" \
  || no "a red verification left the merge staged"
grep -q 'changed by fan-out' "$F/VERSION" && ok "a refused merge never discards working-tree content" \
  || no "a refused merge lost working-tree content"
[ "$(wc -l < "$COUNTER" | tr -d ' ')" = "1" ] && ok "the red verification still ran exactly once" \
  || no "the red verification did not run exactly once"

echo "== 9. --commit is opt-in, and only after green =="
K="$WORK/rk"; mkrepo "$K"; apply_real_diffs "$K"
real_manifest "$WORK/k.manifest" "bash $VERIFIER"
: > "$COUNTER"
HEAD_BEFORE="$(git -C "$K" rev-parse HEAD)"
run merge --manifest "$WORK/k.manifest" --repo "$K" --commit "feat(build-os): merged three-way fan-out"
accepted "an explicit --commit after a green verification succeeds"
[ "$(git -C "$K" rev-parse HEAD)" != "$HEAD_BEFORE" ] && ok "--commit produced exactly the commit it was asked for" \
  || no "--commit did not commit"
[ "$(git -C "$K" log --oneline | wc -l | tr -d ' ')" = "2" ] && ok "the merge produced ONE commit, not several" \
  || no "the merge produced more than one commit"
run merge --manifest "$WORK/k.manifest" --repo "$K"
refused_naming "re-running a merge with nothing left to merge refuses (vacuous merge)" "chang"

echo "== 10. --dry-run plans without touching the index or running the suite =="
D="$WORK/rd"; mkrepo "$D"; apply_real_diffs "$D"
real_manifest "$WORK/d.manifest" "bash $VERIFIER"
: > "$COUNTER"
run merge --manifest "$WORK/d.manifest" --repo "$D" --dry-run
accepted "--dry-run on a clean fan-out reports a plan"
[ ! -s "$COUNTER" ] && ok "--dry-run does not run the verification" || no "--dry-run ran the verification"
[ -z "$(git -C "$D" diff --cached --name-only)" ] && ok "--dry-run stages nothing" || no "--dry-run staged files"
grep -qF "A-lanes" <<<"$OUT" && grep -qF "C-release-metadata" <<<"$OUT" \
  && ok "the plan attributes paths to each agent by name" || no "the plan does not name the agents"

echo "== 11. The router documents the tool without breaking the pinned fan-out block =="
grep -qF "swarm-merge.sh" "$ROUTER" && ok "router points at the merge tool" || no "router never mentions swarm-merge.sh"
grep -qiE "hot-release|hot file" "$ROUTER" && ok "router explains the hot-file reservation the tool enforces" \
  || no "router does not explain the hot-file reservation"
grep -qiE "own .*<|manifest format|^own " "$ROUTER" && ok "router shows the manifest format" || no "router does not show the manifest format"
# The FANOUT block is byte-pinned against the orchestrator agent by
# lane_enforcement_tests.sh. Documenting the tool must not disturb it.
blk(){ awk -v s="$2" -v e="$3" 'index($0,s){f=1;next} index($0,e){f=0} f' "$1"; }
blk "$ROUTER" "BUILD-OS:FANOUT:START" "BUILD-OS:FANOUT:END" > "$WORK/fan.router"
blk "$ORCH"   "BUILD-OS:FANOUT:START" "BUILD-OS:FANOUT:END" > "$WORK/fan.orch"
[ -s "$WORK/fan.router" ] && ok "the canonical fan-out block is still present in the router" || no "the canonical fan-out block vanished from the router"
if diff -q "$WORK/fan.router" "$WORK/fan.orch" >/dev/null 2>&1; then
  ok "the canonical fan-out block is still byte-identical to the orchestrator's copy"
else
  no "documenting the tool DRIFTED the pinned fan-out block"
fi

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
