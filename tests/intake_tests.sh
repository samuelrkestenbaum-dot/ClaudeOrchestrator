#!/usr/bin/env bash
# Gravito — second-repository intake tests (LANE 3).
#
# WHAT THIS PINS. build-os/intake/ is the procedure Gravito runs when it enters
# a repository it has never seen: identify the stack, discover commands, find
# repo-local instructions, map mutation surfaces, flag authority-sensitive
# areas, establish (or honestly decline to claim) a baseline, seed a task
# graph, and preflight an install without writing a byte. The failure modes it
# exists to catch, in the order a customer would hit them:
#
#   1. A GUESS DRESSED AS A DISCOVERY. Every command carries DISCOVERED (read
#      from a manifest) or GUESSED (convention). A guess presented as
#      discovered is the intake lying about its own evidence.
#   2. A BASELINE CLAIMED BUT NEVER RUN. Baseline execution is OFF by default;
#      without --run-baseline the report must say NOT MEASURED, not imply green.
#   3. A SECRET VALUE IN A REPORT. Secrets-shaped files are flagged by NAME
#      pattern only. No fixture secret VALUE may appear in any intake output.
#   4. AN INSTALL THAT EATS CUSTOMER BYTES. install-preflight.sh must refuse
#      (non-zero, WOULD-REFUSE) when a target already holds a same-path file
#      with different content, and must write NOTHING while deciding.
#   5. A VACUOUS REPORT. Required sections must exist even when the answer is
#      "unrecognized" — the honest empty answer, stated out loud.
#
# HONESTY DOCTRINE OF THIS SUITE. Every fixture below is a SYNTHETIC TEST
# FIXTURE fabricated in mktemp by this file. Nothing here is an external
# repository, and a green run here is NOT independent proof of intake quality
# on real customer code — it proves the mechanics against fabricated shapes.
#
# No network. Temp dirs only; this repo is READ, never written. Exits non-zero
# on any failure and prints the "==== RESULT: N passed, M failed ====" line.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INTAKE="$SRC/build-os/intake/repo-intake.sh"
PREFLIGHT="$SRC/build-os/intake/install-preflight.sh"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# The planted secret VALUE. If this string ever appears in an intake report,
# intake.json, a baseline log, or intake stdout, the name-only doctrine broke.
SECRET_VALUE="hunter2-swordfish-xyzzy-9911"

# ---------------------------------------------------------------- fixtures --
# Each fixture carries FIXTURE.md declaring itself synthetic, so a human who
# stumbles on a leftover temp dir cannot mistake it for a customer repo.
label_fixture(){
  cat > "$1/FIXTURE.md" <<'EOF'
SYNTHETIC TEST FIXTURE — fabricated by tests/intake_tests.sh in mktemp.
Not an external repository. Not independent proof of anything.
EOF
}

NODE_FX="$WORK/fx-node"
mkdir -p "$NODE_FX/src" "$NODE_FX/tests" "$NODE_FX/migrations" \
         "$NODE_FX/.github/workflows" "$NODE_FX/.claude"
label_fixture "$NODE_FX"
cat > "$NODE_FX/package.json" <<'EOF'
{
  "name": "fixture-node-app",
  "private": true,
  "scripts": { "test": "vitest run", "build": "node build.js" },
  "dependencies": { "react": "^18.0.0" },
  "devDependencies": { "vitest": "^1.6.0" }
}
EOF
cat > "$NODE_FX/CLAUDE.md" <<'EOF'
# SYNTHETIC TEST FIXTURE instructions
Repo-local instructions for the intake to find.
EOF
echo '{}' > "$NODE_FX/.claude/settings.json"
cat > "$NODE_FX/tests/sample.test.js" <<'EOF'
// deliberately failing fixture test
import { expect, test } from "vitest";
test("fixture red baseline", () => { expect(1).toBe(2); });
EOF
echo 'export const one = 1;' > "$NODE_FX/src/index.js"
echo '-- fixture migration' > "$NODE_FX/migrations/001_init.sql"
printf 'name: ci\non: push\n' > "$NODE_FX/.github/workflows/ci.yml"
printf 'FIXTURE_API_TOKEN=%s\n' "$SECRET_VALUE" > "$NODE_FX/.env"

PY_FX="$WORK/fx-python"
mkdir -p "$PY_FX/tests"
label_fixture "$PY_FX"
cat > "$PY_FX/pyproject.toml" <<'EOF'
[project]
name = "fixture-python-app"
version = "0.0.1"
EOF
printf 'def test_red():\n    assert 1 == 2\n' > "$PY_FX/tests/test_sample.py"

EMPTY_FX="$WORK/fx-empty"
mkdir -p "$EMPTY_FX/mystery"
label_fixture "$EMPTY_FX"
echo 'nothing recognizable here' > "$EMPTY_FX/random.txt"
echo 'artifact' > "$EMPTY_FX/mystery/blob.bin"

CLEAN_FX="$WORK/fx-clean"
mkdir -p "$CLEAN_FX"
label_fixture "$CLEAN_FX"
echo 'customer readme' > "$CLEAN_FX/README.md"

REFUSE_FX="$WORK/fx-refuse"
mkdir -p "$REFUSE_FX/.claude/hooks"
label_fixture "$REFUSE_FX"
cat > "$REFUSE_FX/.claude/hooks/routing-gate.sh" <<'EOF'
#!/usr/bin/env bash
# CUSTOMER-OWNED routing-gate.sh — different content than Gravito ships.
echo "customer gate"
EOF
printf '{\n  "customerKey": true\n}\n' > "$REFUSE_FX/.claude/settings.json"

IDENT_FX="$WORK/fx-identical"
mkdir -p "$IDENT_FX/.claude/hooks"
label_fixture "$IDENT_FX"
cp "$SRC/.claude/hooks/routing-gate.sh" "$IDENT_FX/.claude/hooks/routing-gate.sh"

BADJSON_FX="$WORK/fx-badjson"
mkdir -p "$BADJSON_FX/.claude"
label_fixture "$BADJSON_FX"
echo 'this is not json {' > "$BADJSON_FX/.claude/settings.json"

# ================================================== 0. artifacts exist ======
echo "== 0. intake artifacts exist and are executable =="
[ -f "$INTAKE" ]    && ok "repo-intake.sh exists"        || no "repo-intake.sh missing"
[ -x "$INTAKE" ]    && ok "repo-intake.sh executable"    || no "repo-intake.sh not executable"
[ -f "$PREFLIGHT" ] && ok "install-preflight.sh exists"  || no "install-preflight.sh missing"
[ -x "$PREFLIGHT" ] && ok "install-preflight.sh executable" || no "install-preflight.sh not executable"
if [ ! -f "$INTAKE" ] || [ ! -f "$PREFLIGHT" ]; then
  echo
  echo "==== RESULT: $PASS passed, $((FAIL)) failed ===="
  exit 1
fi

# ================================= 1. node fixture: detection + honesty =====
echo "== 1. node/vitest fixture: detection, provenance labels, name-only secrets =="
OUT1="$WORK/out-node"
STDOUT1="$WORK/out-node.stdout"
bash "$INTAKE" "$NODE_FX" --out "$OUT1" > "$STDOUT1" 2>&1
RC=$?
[ "$RC" -eq 0 ] && ok "intake exits 0 on node fixture" || no "intake exit $RC on node fixture"
REP1="$OUT1/INTAKE_REPORT.md"; JSON1="$OUT1/intake.json"
[ -f "$REP1" ]  && ok "INTAKE_REPORT.md written" || no "INTAKE_REPORT.md missing"
[ -f "$JSON1" ] && ok "intake.json written"      || no "intake.json missing"
if [ ! -f "$REP1" ] || [ ! -f "$JSON1" ]; then REP1=/dev/null; JSON1=/dev/null; fi

python3 -m json.tool "$JSON1" > /dev/null 2>&1 \
  && ok "intake.json is valid JSON" || no "intake.json is not valid JSON"

# language + framework, each with explicit confidence
grep -q 'language: node' "$REP1" && ok "detects node" || no "node not detected"
grep -Eq 'language: node.*CONFIDENCE: HIGH' "$REP1" \
  && ok "node finding carries CONFIDENCE: HIGH (manifest present)" || no "node finding lacks explicit confidence"
grep -q 'framework hint: vitest' "$REP1" && ok "framework hint: vitest" || no "vitest hint missing"
grep -q 'framework hint: react'  "$REP1" && ok "framework hint: react"  || no "react hint missing"

# DISCOVERED vs GUESSED
grep -Eq 'test: npm test \[DISCOVERED' "$REP1" \
  && ok "npm test labeled DISCOVERED (from manifest scripts)" || no "npm test not labeled DISCOVERED"
grep -Eq 'build: npm run build \[DISCOVERED' "$REP1" \
  && ok "npm run build labeled DISCOVERED" || no "npm run build not labeled DISCOVERED"

# repo-local instructions
grep -q 'CLAUDE.md: present' "$REP1" && ok "CLAUDE.md listed as present" || no "CLAUDE.md not listed"
grep -q '.claude/settings.json: present' "$REP1" && ok ".claude/settings.json listed" || no ".claude/settings.json not listed"

# mutation-surface map + authority-sensitive, by name only
grep -Eq 'src/? — source'  "$REP1" && ok "src classified source" || no "src not classified source"
grep -Eq 'tests/? — test'  "$REP1" && ok "tests classified test" || no "tests not classified test"
grep -q 'AUTHORITY-SENSITIVE' "$REP1" && ok "authority-sensitive section present" || no "no authority-sensitive flags"
grep -Eq 'AUTHORITY-SENSITIVE.*\.github/workflows' "$REP1" \
  && ok "CI workflows flagged authority-sensitive" || no "workflows not flagged"
grep -Eq 'AUTHORITY-SENSITIVE.*migrations' "$REP1" \
  && ok "migrations dir flagged authority-sensitive" || no "migrations not flagged"
grep -Eq 'AUTHORITY-SENSITIVE.*\.env' "$REP1" \
  && ok ".env flagged by NAME" || no ".env not flagged"
grep -q 'contents never read' "$REP1" \
  && ok "report states secret contents are never read" || no "name-only doctrine not stated"

# THE secret VALUE must appear nowhere in any intake output
if grep -rq "$SECRET_VALUE" "$OUT1" 2>/dev/null; then
  no "secret VALUE leaked into the report directory"
else
  ok "secret VALUE absent from report directory"
fi
grep -q "$SECRET_VALUE" "$STDOUT1" \
  && no "secret VALUE leaked to intake stdout" || ok "secret VALUE absent from intake stdout"

# baseline honesty: OFF by default
grep -q 'BASELINE: NOT MEASURED' "$REP1" \
  && ok "baseline honestly NOT MEASURED without --run-baseline" || no "baseline default dishonest"
grep -q '"measured": false' "$JSON1" \
  && ok "intake.json baseline.measured=false by default" || no "intake.json claims a baseline it never ran"

# task graph seed: candidates, not commitments
grep -q '"status": "CANDIDATE"' "$JSON1" \
  && ok "task seeds labeled CANDIDATE in intake.json" || no "task seeds not labeled CANDIDATE"
grep -q 'CANDIDATES, not commitments' "$REP1" \
  && ok "report labels seeds as candidates, not commitments" || no "seed labeling missing"

# required sections all present
for sec in "## Language & framework detection" "## Command discovery" \
           "## Repo-local instructions" "## Mutation-surface map" \
           "## Baseline" "## Task graph seed" "## Unsupported assumptions"; do
  grep -qF "$sec" "$REP1" && ok "section present: $sec" || no "section missing: $sec"
done
UA_COUNT="$(sed -n '/## Unsupported assumptions/,$p' "$REP1" | grep -c '^- ')"
[ "${UA_COUNT:-0}" -gt 0 ] \
  && ok "unsupported-assumptions section is non-empty ($UA_COUNT item(s))" \
  || no "unsupported-assumptions section is empty — nothing is ever fully determined"

# ============================ 2. node fixture: measured (red) baseline ======
echo "== 2. node fixture with --run-baseline: measured, and honestly RED =="
OUT2="$WORK/out-node-baseline"
INTAKE_BASELINE_TIMEOUT=60 bash "$INTAKE" "$NODE_FX" --out "$OUT2" --run-baseline \
  > "$WORK/out2.stdout" 2>&1
RC=$?
[ "$RC" -eq 0 ] && ok "intake exits 0 with --run-baseline" || no "intake exit $RC with --run-baseline"
REP2="$OUT2/INTAKE_REPORT.md"; JSON2="$OUT2/intake.json"
[ -f "$REP2" ] || REP2=/dev/null
[ -f "$JSON2" ] || JSON2=/dev/null
grep -q 'BASELINE: MEASURED' "$REP2" && ok "baseline marked MEASURED when run" || no "baseline not marked measured"
grep -q '"measured": true' "$JSON2" && ok "intake.json baseline.measured=true" || no "json baseline not measured"
# The fixture test fails by design; whether vitest/npm is installed or not, the
# command cannot exit 0, so RED is deterministic either way — and honest.
grep -Eq 'npm test.*exit [0-9]+.*RED' "$REP2" \
  && ok "failing test command recorded with exit code and RED" || no "red baseline not recorded honestly"
if grep -rq "$SECRET_VALUE" "$OUT2" 2>/dev/null; then
  no "secret VALUE leaked via baseline logs"
else
  ok "secret VALUE absent from baseline output too"
fi

# ============================================= 3. python fixture: GUESSED ===
echo "== 3. python fixture: convention commands are GUESSED, never DISCOVERED =="
OUT3="$WORK/out-python"
bash "$INTAKE" "$PY_FX" --out "$OUT3" > /dev/null 2>&1
RC=$?
[ "$RC" -eq 0 ] && ok "intake exits 0 on python fixture" || no "intake exit $RC on python fixture"
REP3="$OUT3/INTAKE_REPORT.md"
[ -f "$REP3" ] || REP3=/dev/null
grep -q 'language: python' "$REP3" && ok "detects python" || no "python not detected"
grep -Eq 'test: pytest \[GUESSED' "$REP3" \
  && ok "pytest labeled GUESSED (convention, no manifest script)" || no "pytest not labeled GUESSED"
if grep -E 'test: pytest' "$REP3" | grep -q 'DISCOVERED'; then
  no "a convention guess (pytest) was presented as DISCOVERED"
else
  ok "the pytest guess is NOT presented as DISCOVERED"
fi

# ================================== 4. unrecognizable fixture: honest =======
echo "== 4. unrecognizable fixture: honest UNRECOGNIZED, exploration candidate =="
OUT4="$WORK/out-empty"
bash "$INTAKE" "$EMPTY_FX" --out "$OUT4" > /dev/null 2>&1
RC=$?
[ "$RC" -eq 0 ] && ok "intake exits 0 on unrecognizable fixture" || no "intake exit $RC on unrecognizable fixture"
REP4="$OUT4/INTAKE_REPORT.md"; JSON4="$OUT4/intake.json"
[ -f "$REP4" ] || REP4=/dev/null
[ -f "$JSON4" ] || JSON4=/dev/null
grep -q 'UNRECOGNIZED' "$REP4" \
  && ok "unrecognized stack stated honestly" || no "unrecognized path not honest"
sed -n '/## Unsupported assumptions/,$p' "$REP4" | grep -qi 'language' \
  && ok "unsupported assumptions names the undetermined language" || no "undetermined language not listed"
grep -qi 'explore' "$JSON4" && grep -q 'mystery' "$JSON4" \
  && ok "exploration candidate emitted for unrecognized area (mystery/)" \
  || no "no exploration candidate for unrecognized area"

# ====================================== 5. preflight on a clean target ======
echo "== 5. install-preflight: clean target — CLEAR, previews, writes nothing =="
BEFORE5="$WORK/clean.before"; AFTER5="$WORK/clean.after"
( cd "$CLEAN_FX" && find . -type f -exec sha256sum {} \; ) > "$BEFORE5"
PF5="$WORK/pf5.out"
bash "$PREFLIGHT" "$CLEAN_FX" > "$PF5" 2>&1
RC=$?
[ "$RC" -eq 0 ] && ok "preflight exits 0 on clean target" || no "preflight exit $RC on clean target"
grep -q 'PREFLIGHT: CLEAR' "$PF5" && ok "verdict PREFLIGHT: CLEAR" || no "no CLEAR verdict"
grep -q 'WOULD-CREATE: .claude/agents/builder.md' "$PF5" \
  && ok "would-create list names engine files" || no "would-create list incomplete (builder.md)"
grep -q 'WOULD-CREATE: build-os/memory/tool_router.md' "$PF5" \
  && ok "would-create list names memory seeds" || no "would-create list incomplete (tool_router.md)"
grep -q 'SETTINGS-MERGE:.*SessionStart' "$PF5" \
  && ok "settings merge preview covers SessionStart" || no "no SessionStart merge preview"
grep -q 'SETTINGS-MERGE:.*UserPromptSubmit' "$PF5" \
  && ok "settings merge preview covers UserPromptSubmit" || no "no UserPromptSubmit merge preview"
grep -q 'CLAUDE-MD:' "$PF5" && ok "CLAUDE.md managed-block preview present" || no "no CLAUDE.md preview"
( cd "$CLEAN_FX" && find . -type f -exec sha256sum {} \; ) > "$AFTER5"
diff -q "$BEFORE5" "$AFTER5" > /dev/null \
  && ok "preflight wrote NOTHING to the clean target" || no "preflight mutated the clean target"

# ============================== 6. preflight refusal on collision ===========
echo "== 6. install-preflight: pre-existing different routing-gate.sh — WOULD-REFUSE =="
BEFORE6="$WORK/refuse.before"; AFTER6="$WORK/refuse.after"
( cd "$REFUSE_FX" && find . -type f -exec sha256sum {} \; ) > "$BEFORE6"
PF6="$WORK/pf6.out"
bash "$PREFLIGHT" "$REFUSE_FX" > "$PF6" 2>&1
RC=$?
[ "$RC" -eq 0 ] && no "preflight exited 0 despite a collision" || ok "preflight exits non-zero on collision (exit $RC)"
grep -q 'WOULD-REFUSE: .claude/hooks/routing-gate.sh' "$PF6" \
  && ok "collision names the exact file (routing-gate.sh)" || no "collision not named"
grep -q 'PREFLIGHT: WOULD-REFUSE' "$PF6" && ok "verdict PREFLIGHT: WOULD-REFUSE" || no "no refusal verdict"
grep -q 'nothing written' "$PF6" && ok "verdict states nothing was written" || no "verdict silent about writes"
( cd "$REFUSE_FX" && find . -type f -exec sha256sum {} \; ) > "$AFTER6"
diff -q "$BEFORE6" "$AFTER6" > /dev/null \
  && ok "customer bytes untouched after refusal" || no "preflight mutated the refusal target"
grep -q 'customer gate' "$REFUSE_FX/.claude/hooks/routing-gate.sh" \
  && ok "customer routing-gate.sh content survives verbatim" || no "customer routing-gate.sh changed"

# ================================ 7. preflight identical + bad settings =====
echo "== 7. install-preflight: identical file is not a collision; bad JSON is honest =="
PF7="$WORK/pf7.out"
bash "$PREFLIGHT" "$IDENT_FX" > "$PF7" 2>&1
RC=$?
[ "$RC" -eq 0 ] && ok "identical pre-existing file does not refuse (exit 0)" || no "identical file refused (exit $RC)"
grep -q 'IDENTICAL: .claude/hooks/routing-gate.sh' "$PF7" \
  && ok "identical file reported IDENTICAL" || no "identical file not reported"
if grep -q 'WOULD-REFUSE: .claude/hooks/routing-gate.sh' "$PF7"; then
  no "identical file wrongly counted as collision"
else
  ok "identical file not counted as collision"
fi
PF8="$WORK/pf8.out"
bash "$PREFLIGHT" "$BADJSON_FX" > "$PF8" 2>&1
RC=$?
[ "$RC" -eq 0 ] && no "unparseable settings.json passed preflight" || ok "unparseable settings.json refuses (exit $RC)"
grep -q 'SETTINGS-MERGE:.*not valid JSON' "$PF8" \
  && ok "invalid settings.json reported honestly" || no "invalid settings.json not reported"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
