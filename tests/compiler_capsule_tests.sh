#!/usr/bin/env bash
# Build OS — context compiler LANE B: task compiler + context budgeter.
#
# These tests pin the compiler's side of the seam contracts in
# build-os/compiler/SEAMS.md. The indexer is built CONCURRENTLY by another
# lane; nothing here imports its code. Every index.json used below is a
# FABRICATED FIXTURE written to match SEAM 1 exactly — that is the whole
# point of a seam: the consumer is testable before the producer exists.
#
# What is asserted, and why each one is load-bearing:
#
#   SEAM 2 completeness  — a capsule missing a field is a capsule a worker
#                          cannot trust; absence must fail here, not in a run.
#   every `why` non-empty — "a capsule that cannot say why something is in it
#                          is malformed" (SEAMS.md). No file enters without a
#                          RULE that admitted it.
#   budget honesty       — silent truncation is the named failure mode. Every
#                          dropped candidate must land in excluded_notable
#                          with the priority it died at, and the arithmetic
#                          admitted + dropped == candidates must close.
#   determinism          — same inputs => byte-identical capsule.json AND
#                          capsule.md. Summarizers that paraphrase are the
#                          named enemy; byte-compare is the only real proof.
#   SEAM 5 prefix        — the immutable prefix must be byte-identical across
#                          DIFFERENT tasks, and volatile task content must
#                          never leak into it, or one task field invalidates
#                          the whole cached prefix.
#   facts / decisions    — injected only on scope/topic overlap; what was NOT
#                          injected is still disclosed.
#   artifact refs        — over threshold => sha256 + summary + bytes, and the
#                          artifact's body must be provably ABSENT.
#   token proxy tier     — chars/4 is an ESTIMATE. The tier vocabulary
#                          (EXACT | ESTIMATE | CLOSE-TIME | UNAVAILABLE) is
#                          binding; a proxy labeled EXACT is a lie.
#   degenerate inputs    — empty index / no seeds must produce an honest
#                          minimal capsule, not a crash and not a fake one.
#
# No network. Deterministic. Temp dirs only. Exits non-zero if any assertion
# fails, and prints a final "==== RESULT: N passed, M failed ====" line.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CDIR="$SRC/build-os/compiler/compile"
COMPILE="$CDIR/compile-task.mjs"
RENDER="$CDIR/render-capsule.mjs"
STATS="$CDIR/capsule-stats.mjs"
PREFIX_CONST="$CDIR/capsule-prefix.mjs"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# ---------------------------------------------------------------- helpers --
# Dotted-path read out of a JSON file. `.length` works on arrays.
cat > "$WORK/q.mjs" <<'EOF'
import fs from "node:fs";
const [file, path] = process.argv.slice(2);
let v = JSON.parse(fs.readFileSync(file, "utf8"));
for (const k of path.split(".")) {
  if (v === null || v === undefined) { v = undefined; break; }
  v = v[k];
}
if (v === undefined) console.log("__UNDEF__");
else if (typeof v === "object") console.log(JSON.stringify(v));
else console.log(String(v));
EOF
q(){ node "$WORK/q.mjs" "$1" "$2"; }

# Section of a rendered capsule, sentinels excluded.
sect(){ awk -v s="<!-- CAPSULE:$2:START -->" -v e="<!-- CAPSULE:$2:END -->" \
  'index($0,s){f=1;next} index($0,e){f=0} f' "$1"; }

# ---------------------------------------------------------------- fixtures --
FIX="$WORK/fix"; mkdir -p "$FIX"

# SEAM 1 index fixture. Note src/legacy/blob.rb: symbols [] WITH partial:true
# and error_count null — SEAM 1's honesty rule (null means not-measured, an
# unparsed language is never a silent empty). The compiler must carry that
# through rather than reporting an empty symbol list as fact.
cat > "$FIX/index.json" <<'EOF'
{
  "index_version": 3,
  "repo_head": "9f1c0de4ab77c2b1e5d3f6a0b8c9d1e2f3a4b5c6",
  "generated_at": "2026-08-01T00:00:00.000Z",
  "files": {
    "src/auth/token.js": {
      "blob": "b0001", "lang": "javascript", "kind": "source",
      "symbols": ["mintToken", "verifyToken"],
      "imports": ["src/auth/crypto.js"],
      "imported_by": ["src/api/login.js", "src/api/refresh.js"],
      "tests_covering": ["tests/token.test.js"],
      "last_changed": "2026-07-30T10:00:00.000Z", "error_count": 3
    },
    "src/auth/crypto.js": {
      "blob": "b0002", "lang": "javascript", "kind": "source",
      "symbols": ["hmac"], "imports": [],
      "imported_by": ["src/auth/token.js"], "tests_covering": [],
      "last_changed": "2026-05-02T10:00:00.000Z", "error_count": 0
    },
    "src/api/login.js": {
      "blob": "b0003", "lang": "javascript", "kind": "source",
      "symbols": ["login"], "imports": ["src/auth/token.js"],
      "imported_by": [], "tests_covering": ["tests/login.test.js"],
      "last_changed": "2026-07-28T10:00:00.000Z", "error_count": 1
    },
    "src/api/refresh.js": {
      "blob": "b0004", "lang": "javascript", "kind": "source",
      "symbols": ["refresh"], "imports": ["src/auth/token.js"],
      "imported_by": [], "tests_covering": [],
      "last_changed": "2026-07-27T10:00:00.000Z", "error_count": 0
    },
    "tests/token.test.js": {
      "blob": "b0005", "lang": "javascript", "kind": "test",
      "symbols": [], "imports": ["src/auth/token.js"],
      "imported_by": [], "tests_covering": [],
      "last_changed": "2026-07-30T10:00:00.000Z", "error_count": 0
    },
    "src/billing/invoice.js": {
      "blob": "b0006", "lang": "javascript", "kind": "source",
      "symbols": ["renderInvoice"], "imports": [], "imported_by": [],
      "tests_covering": [], "last_changed": "2026-06-01T10:00:00.000Z",
      "error_count": 2
    },
    "src/legacy/blob.rb": {
      "blob": "b0007", "lang": "ruby", "kind": "source",
      "symbols": [], "partial": true, "imports": [], "imported_by": [],
      "tests_covering": [], "last_changed": "2024-01-01T10:00:00.000Z",
      "error_count": null
    }
  },
  "symbols": {
    "mintToken":     { "defined_in": "src/auth/token.js",      "line": 12, "referenced_in": ["src/api/login.js", "src/api/refresh.js"] },
    "verifyToken":   { "defined_in": "src/auth/token.js",      "line": 44, "referenced_in": ["src/api/login.js"] },
    "hmac":          { "defined_in": "src/auth/crypto.js",     "line": 5,  "referenced_in": ["src/auth/token.js"] },
    "login":         { "defined_in": "src/api/login.js",       "line": 9,  "referenced_in": [] },
    "refresh":       { "defined_in": "src/api/refresh.js",     "line": 9,  "referenced_in": [] },
    "renderInvoice": { "defined_in": "src/billing/invoice.js", "line": 20, "referenced_in": [] }
  },
  "error_clusters": [
    { "signature": "TS2345 argument of type string is not assignable",
      "count": 5,
      "files": ["src/auth/token.js", "src/billing/invoice.js", "src/legacy/blob.rb"] }
  ]
}
EOF

# Artifacts: one over the inline threshold (body must be REFERENCED, never
# inlined), one under it (body may be inlined). The sentinel is buried deep in
# the big one so that a naive "first line" summary cannot smuggle it in.
{ echo "targeted baseline run, 2026-08-01"; i=0
  while [ "$i" -lt 60 ]; do echo "  filler line $i ..........................................."; i=$((i+1)); done
  echo "  SENTINELBIGARTIFACTBODY should never be inlined into a capsule"
  i=0; while [ "$i" -lt 60 ]; do echo "  filler line b$i .........................................."; i=$((i+1)); done
} > "$FIX/baseline.log"
echo "SENTINELSMALLARTIFACTBODY: repro is 'node run.js --seed 7'" > "$FIX/repro.txt"

cat > "$FIX/task-a.json" <<'EOF'
{
  "task_id": "TASK-A-TOKEN",
  "objective": "Fix mintToken so refresh tokens carry the same issuer claim as access tokens.",
  "acceptance": [
    "tests/token.test.js passes with 0 failures",
    "no change to the public signature of verifyToken"
  ],
  "seed_symbols": ["mintToken", "doesNotExistAnywhere"],
  "targeted_baseline": "tests/token.test.js: 3 failing (issuer claim undefined)",
  "repo_wide_baseline": "778 errors at pinned base",
  "baseline_measured_at": "2026-08-01T09:00:00.000Z",
  "authority": { "mode": "full", "receipt": "build-os/receipts/TASK-A-TOKEN.md" },
  "budget": { "bytes": null },
  "verification": {
    "commands": ["node --test tests/token.test.js"],
    "expected": "0 failing"
  },
  "artifacts": [
    { "id": "baseline_log", "path": "ARTIFACT_DIR/baseline.log",
      "summary": "targeted baseline: 3 failing assertions in tests/token.test.js" },
    { "id": "repro_note", "path": "ARTIFACT_DIR/repro.txt",
      "summary": "one-line reproduction command" }
  ]
}
EOF
sed -i "s|ARTIFACT_DIR|$FIX|g" "$FIX/task-a.json"

cat > "$FIX/task-b.json" <<'EOF'
{
  "task_id": "TASK-B-INVOICE",
  "objective": "Make renderInvoice tolerate a null tax region without throwing.",
  "acceptance": ["renderInvoice returns a string for a null region"],
  "seed_files": ["src/billing/invoice.js"],
  "authority": { "mode": "light", "receipt": "build-os/receipts/TASK-B-INVOICE.md" }
}
EOF

cat > "$FIX/facts.jsonl" <<'EOF'
{"fact_id":"F-0001","task_id":"TASK-OLD-1","attempted":"regenerate the signing key inside mintToken on every call","failed_because":"observed: refresh handshake rejected tokens minted with a rotated key","reusable_conclusion":"SENTINELFACTMATCH do not rotate the signing key inside mintToken","scope":["src/auth/token.js"],"evidence_class":"observed","created_at":"2026-07-01T00:00:00.000Z"}
{"fact_id":"F-0002","task_id":"TASK-OLD-2","attempted":"build the README with node 18","failed_because":"observed: docs build aborted on an unsupported flag","reusable_conclusion":"SENTINELFACTNOMATCH the docs build needs node 20 or later","scope":["docs/README.md"],"evidence_class":"observed","created_at":"2026-07-02T00:00:00.000Z"}
EOF

cat > "$FIX/decisions.txt" <<'EOF'
# topic: text
src/auth: SENTINELDECISIONMATCH tokens are signed HS256; RS256 is out of scope for v0
docs/marketing: SENTINELDECISIONUNMATCHED never inline customer logos in the README
EOF

OUTA="$WORK/out-a"; OUTB="$WORK/out-b"
run_a(){ node "$COMPILE" compile --index "$FIX/index.json" --task "$FIX/task-a.json" \
  --facts "$FIX/facts.jsonl" --decisions "$FIX/decisions.txt" --deterministic --out "$1" >"$WORK/a.log" 2>&1; }

echo "== 0. The three components exist and are runnable =="
for f in "$COMPILE" "$RENDER" "$STATS" "$PREFIX_CONST"; do
  [ -f "$f" ] && ok "present: ${f#$SRC/}" || no "missing: ${f#$SRC/}"
done
if ! run_a "$OUTA"; then
  no "compile of task A exited non-zero"
  sed 's/^/    /' "$WORK/a.log"
  echo; echo "==== RESULT: $PASS passed, $FAIL failed ===="; exit 1
fi
ok "compile of task A exited 0"
CA="$OUTA/capsule.json"; MA="$OUTA/capsule.md"
[ -s "$CA" ] && ok "capsule.json written and non-empty" || no "capsule.json missing/empty"
[ -s "$MA" ] && ok "capsule.md written and non-empty" || no "capsule.md missing/empty"
node -e 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"))' "$CA" 2>/dev/null \
  && ok "capsule.json is valid JSON" || no "capsule.json is not valid JSON"

echo
echo "== 1. SEAM 2 schema completeness — every declared field is present =="
for k in capsule_version task_id compiled_at index_version repo_head objective \
         acceptance relevant_files dependency_neighborhood baseline constraints \
         failed_approaches allowed_mutation_surface authority budget verification \
         artifact_refs provenance; do
  v="$(q "$CA" "$k")"
  [ "$v" != "__UNDEF__" ] && ok "SEAM 2 field present: $k" || no "SEAM 2 field MISSING: $k"
done
[ "$(q "$CA" "provenance.included_because")" != "__UNDEF__" ] \
  && ok "provenance.included_because present" || no "provenance.included_because MISSING"
[ "$(q "$CA" "provenance.excluded_notable")" != "__UNDEF__" ] \
  && ok "provenance.excluded_notable present" || no "provenance.excluded_notable MISSING"
[ "$(q "$CA" "capsule_version")" = "1" ] && ok "capsule_version is 1" || no "capsule_version is not 1"
[ "$(q "$CA" "index_version")" = "3" ] && ok "index_version carried from the index" || no "index_version not carried"
[ "$(q "$CA" "repo_head")" = "9f1c0de4ab77c2b1e5d3f6a0b8c9d1e2f3a4b5c6" ] \
  && ok "repo_head carried from the index" || no "repo_head not carried"
[ "$(q "$CA" "objective")" = "Fix mintToken so refresh tokens carry the same issuer claim as access tokens." ] \
  && ok "objective carried EXACT (not paraphrased)" || no "objective was altered — paraphrase is the named failure mode"
[ "$(q "$CA" "authority.mode")" = "full" ] && ok "authority.mode carried" || no "authority.mode not carried"

echo
echo "== 2. Relevance derivation — no file enters without a RULE =="
cat > "$WORK/why.mjs" <<'EOF'
import fs from "node:fs";
const c = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const rf = c.relevant_files || [];
const bad = [];
for (const f of rf) {
  if (!f || typeof f.path !== "string" || !f.path) bad.push("(entry with no path)");
  else if (typeof f.why !== "string" || f.why.trim() === "") bad.push(f.path + ": empty why");
  else if (!Object.prototype.hasOwnProperty.call(c.provenance.included_because, f.path))
    bad.push(f.path + ": no provenance.included_because row");
  else if (c.provenance.included_because[f.path] !== f.why)
    bad.push(f.path + ": why disagrees with provenance");
  else if (!Array.isArray(f.symbols)) bad.push(f.path + ": symbols not an array");
}
if (process.argv[3] === "count") console.log(rf.length);
else console.log(bad.length ? "BAD " + bad.join(" | ") : "OK");
EOF
r="$(node "$WORK/why.mjs" "$CA")"
[ "$r" = "OK" ] && ok "every relevant_file has a non-empty why that matches provenance" || no "$r"

nfiles="$(node "$WORK/why.mjs" "$CA" count)"
[ "$nfiles" -eq 7 ] 2>/dev/null && ok "all 7 reachable candidates admitted when unbudgeted (got $nfiles)" \
  || no "expected 7 admitted candidates unbudgeted, got $nfiles"

paths="$(q "$CA" relevant_files)"
for p in src/auth/token.js tests/token.test.js src/api/login.js src/api/refresh.js \
         src/auth/crypto.js src/billing/invoice.js src/legacy/blob.rb; do
  case "$paths" in *"$p"*) ok "walked to $p" ;; *) no "never walked to $p" ;; esac
done

whys="$(q "$CA" "provenance.included_because")"
case "$whys" in *"defines seed symbol mintToken"*) ok "rule text: defines seed symbol mintToken" ;;
  *) no "missing rule text 'defines seed symbol mintToken'" ;; esac
case "$whys" in *"test covering it"*) ok "rule text: test covering it" ;;
  *) no "missing rule text 'test covering it'" ;; esac
case "$whys" in *"imports the defining file"*) ok "rule text: imports the defining file" ;;
  *) no "missing rule text 'imports the defining file'" ;; esac
case "$whys" in *"import of the defining file"*) ok "rule text: direct import of the defining file" ;;
  *) no "missing rule text for the direct-import neighborhood" ;; esac
case "$whys" in *"same error cluster"*) ok "rule text: same error cluster" ;;
  *) no "missing rule text 'same error cluster'" ;; esac

# dependency_neighborhood is the importer/import ring, not everything.
dn="$(q "$CA" dependency_neighborhood)"
case "$dn" in *"src/api/login.js"*) ok "dependency_neighborhood holds the direct importer" ;;
  *) no "dependency_neighborhood missing the direct importer" ;; esac
case "$dn" in *"src/billing/invoice.js"*) no "cluster sibling leaked into dependency_neighborhood" ;;
  *) ok "dependency_neighborhood excludes cluster siblings (it is the import ring)" ;; esac

echo
echo "== 3. Index honesty rules survive the compile =="
ex="$(q "$CA" "provenance.excluded_notable")"
case "$ex" in *doesNotExistAnywhere*) ok "unresolved seed symbol is DISCLOSED, not swallowed" ;;
  *) no "unresolved seed symbol vanished silently" ;; esac
case "$ex" in *"partial"*) ok "index partial:true is disclosed (symbol list is not evidence of absence)" ;;
  *) no "a partial-index file was reported as if fully parsed" ;; esac

echo
echo "== 4. Context budgeter — overflow is disclosed, never silently truncated =="
base="$(q "$CA" budget.base_bytes)"; spent="$(q "$CA" budget.spent_bytes)"
cand="$(q "$CA" budget.candidates_total)"
[ "$cand" -eq 7 ] 2>/dev/null && ok "budget.candidates_total counts all 7 reachable candidates" \
  || no "budget.candidates_total is $cand, expected 7"
BUD=$(( base + (spent * 6 / 10) ))
OUTC="$WORK/out-c"
node "$COMPILE" compile --index "$FIX/index.json" --task "$FIX/task-a.json" \
  --facts "$FIX/facts.jsonl" --decisions "$FIX/decisions.txt" --deterministic \
  --budget "$BUD" --out "$OUTC" >"$WORK/c.log" 2>&1 \
  && ok "budgeted compile exited 0" || no "budgeted compile failed"
CC="$OUTC/capsule.json"
adm="$(q "$CC" budget.admitted)"; drop="$(q "$CC" budget.dropped)"
ctot="$(q "$CC" budget.candidates_total)"
[ "$adm" -ge 1 ] 2>/dev/null && [ "$adm" -lt "$ctot" ] 2>/dev/null \
  && ok "budget bit: $adm of $ctot admitted" || no "budget did not bite (admitted=$adm of $ctot)"
[ $((adm + drop)) -eq "$ctot" ] 2>/dev/null \
  && ok "arithmetic closes: admitted + dropped == candidates (no silent loss)" \
  || no "candidate accounting does not close: $adm + $drop != $ctot"
nrf="$(node "$WORK/why.mjs" "$CC" count)"
[ "$nrf" -eq "$adm" ] 2>/dev/null && ok "relevant_files length equals budget.admitted" \
  || no "relevant_files ($nrf) disagrees with budget.admitted ($adm)"
ndrop="$(node -e '
const c=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));
console.log(c.provenance.excluded_notable.filter(s=>/budget: dropped at priority \d/.test(s)).length);
' "$CC")"
[ "$ndrop" -eq "$drop" ] 2>/dev/null \
  && ok "every dropped candidate has a 'budget: dropped at priority N' line ($ndrop)" \
  || no "dropped candidates without a disclosure line: $ndrop lines vs $drop dropped"
[ "$(node "$WORK/why.mjs" "$CC")" = "OK" ] \
  && ok "budgeted capsule still gives every admitted file a why" || no "budgeted capsule lost a why"
# Priority order must be respected: the defining file can never be the one dropped
# while a cluster sibling survives.
node -e '
const c=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));
const p=c.relevant_files.map(f=>f.path);
process.exit(p.includes("src/auth/token.js")?0:1);
' "$CC" && ok "priority respected: the defining file survives the budget" \
  || no "priority violated: the defining file was dropped while others survived"
po="$(q "$CA" budget.priority_order)"
case "$po" in *"defining"*"tests"*"importers"*) ok "budget.priority_order is stated in the capsule" ;;
  *) no "budget.priority_order not stated" ;; esac

echo
echo "== 5. Determinism — byte-identical capsule.json AND capsule.md =="
OUTA2="$WORK/out-a2"; run_a "$OUTA2"
cmp -s "$OUTA/capsule.json" "$OUTA2/capsule.json" \
  && ok "capsule.json is byte-identical across two runs" || no "capsule.json DRIFTED between runs"
cmp -s "$OUTA/capsule.md" "$OUTA2/capsule.md" \
  && ok "capsule.md is byte-identical across two runs" || no "capsule.md DRIFTED between runs"
[ "$(q "$CA" compiled_at)" = "1970-01-01T00:00:00.000Z" ] \
  && ok "--deterministic zeroes compiled_at (the only wall-clock field)" \
  || no "--deterministic did not zero compiled_at"
OUTW="$WORK/out-wall"
node "$COMPILE" compile --index "$FIX/index.json" --task "$FIX/task-a.json" --out "$OUTW" >/dev/null 2>&1
[ "$(q "$OUTW/capsule.json" compiled_at)" != "1970-01-01T00:00:00.000Z" ] \
  && ok "without --deterministic compiled_at is a real timestamp" || no "compiled_at is always zeroed"
# The renderer alone must also be deterministic and must agree with the compiler.
node "$RENDER" --capsule "$CA" --out "$WORK/re1.md" >/dev/null 2>&1 \
  && ok "render-capsule.mjs runs standalone" || no "render-capsule.mjs failed standalone"
cmp -s "$WORK/re1.md" "$MA" \
  && ok "standalone render reproduces the compiler's capsule.md byte-for-byte" \
  || no "standalone render disagrees with the compiler's capsule.md"

echo
echo "== 6. SEAM 5 — cache-stable order, immutable prefix =="
OUTB="$WORK/out-b"
node "$COMPILE" compile --index "$FIX/index.json" --task "$FIX/task-b.json" \
  --deterministic --out "$OUTB" >"$WORK/b.log" 2>&1 \
  && ok "compile of the SECOND, different task exited 0" || no "compile of task B failed"
MB="$OUTB/capsule.md"
sect "$MA" PREFIX > "$WORK/pre.a"; sect "$MB" PREFIX > "$WORK/pre.b"
[ -s "$WORK/pre.a" ] && ok "capsule.md has a non-empty PREFIX section" || no "no PREFIX section"
cmp -s "$WORK/pre.a" "$WORK/pre.b" \
  && ok "the immutable prefix is BYTE-IDENTICAL across two different tasks" \
  || no "the prefix DIFFERS between tasks — one task field invalidates the whole cache"
sect "$MA" SLOW > "$WORK/slow.a";  [ -s "$WORK/slow.a" ] \
  && ok "capsule.md has a non-empty SLOW section" || no "no SLOW section"
sect "$MA" VOLATILE > "$WORK/vol.a"; [ -s "$WORK/vol.a" ] \
  && ok "capsule.md has a non-empty VOLATILE section" || no "no VOLATILE section"
lp="$(grep -n 'CAPSULE:PREFIX:START' "$MA" | cut -d: -f1)"
ls_="$(grep -n 'CAPSULE:SLOW:START' "$MA" | cut -d: -f1)"
lv="$(grep -n 'CAPSULE:VOLATILE:START' "$MA" | cut -d: -f1)"
[ "$lp" -lt "$ls_" ] 2>/dev/null && [ "$ls_" -lt "$lv" ] 2>/dev/null \
  && ok "order is prefix -> slow-moving -> volatile (SEAM 5)" \
  || no "SEAM 5 order violated (prefix=$lp slow=$ls_ volatile=$lv)"
# Volatile content must never appear inside the prefix.
for leak in "TASK-A-TOKEN" "mintToken" "issuer claim" "SENTINELFACTMATCH" "SENTINELDECISIONMATCH" "9f1c0de4"; do
  grep -qF "$leak" "$WORK/pre.a" \
    && no "VOLATILE LEAK into the immutable prefix: $leak" \
    || ok "prefix free of volatile content: $leak"
done
grep -qF "TASK-A-TOKEN" "$WORK/vol.a" && ok "the task id lives in the volatile section" \
  || no "task id is not in the volatile section"
grep -qF "issuer claim" "$WORK/vol.a" && ok "the objective lives in the volatile section" \
  || no "objective is not in the volatile section"
grep -qF "src/auth/token.js" "$WORK/slow.a" && ok "the repo map lives in the slow-moving section" \
  || no "repo map is not in the slow-moving section"
# Provable stability: the prefix is a constant file with no interpolation.
grep -qF '${' "$PREFIX_CONST" \
  && no "the prefix constant contains template interpolation — it is not provably stable" \
  || ok "the prefix constant contains no interpolation (provably task-independent)"
grep -qE 'process\.argv|readFileSync|Date\(' "$PREFIX_CONST" \
  && no "the prefix constant reads input or the clock" \
  || ok "the prefix constant reads no input and no clock"
# The published prefix sha must match the prefix actually rendered.
node -e '
import("file://"+process.argv[1]).then(m=>{
  const crypto=require("node:crypto");
  const h=crypto.createHash("sha256").update(m.IMMUTABLE_PREFIX,"utf8").digest("hex");
  process.exit(h===m.PREFIX_SHA256?0:1);
});' "$PREFIX_CONST" \
  && ok "PREFIX_SHA256 matches the actual prefix bytes" || no "PREFIX_SHA256 is stale/wrong"
[ "$(q "$CA" provenance.prefix_sha256)" = "$(q "$OUTB/capsule.json" provenance.prefix_sha256)" ] \
  && ok "both capsules record the same prefix sha256" || no "capsules disagree on the prefix sha256"

echo
echo "== 7. Durable facts — injected ONLY on scope overlap =="
fa="$(q "$CA" failed_approaches)"
case "$fa" in *SENTINELFACTMATCH*) ok "a fact scoped to an admitted file IS injected" ;;
  *) no "a matching durable fact was not injected" ;; esac
grep -qF "SENTINELFACTNOMATCH" "$CA" \
  && no "a non-overlapping fact leaked into the capsule" \
  || ok "a fact with no scope overlap is NOT injected"
grep -qF "SENTINELFACTNOMATCH" "$MA" \
  && no "a non-overlapping fact leaked into the rendered capsule" \
  || ok "a non-overlapping fact is absent from capsule.md too"
case "$ex" in *F-0002*) ok "the withheld fact is still DISCLOSED by id in excluded_notable" ;;
  *) no "the withheld fact was hidden entirely" ;; esac
inc="$(q "$CA" provenance.included_because)"
case "$inc" in *"fact:F-0001"*) ok "the injected fact carries its admitting rule" ;;
  *) no "the injected fact has no provenance row" ;; esac
# With no --facts at all the field must still exist, empty and honest.
[ "$(q "$OUTB/capsule.json" failed_approaches)" = "[]" ] \
  && ok "no facts file => failed_approaches is [] (present, not missing)" \
  || no "failed_approaches malformed when no facts file is given"

echo
echo "== 8. Prior decisions — matched inject, unmatched are disclosed not injected =="
co="$(q "$CA" constraints)"
case "$co" in *SENTINELDECISIONMATCH*) ok "a decision whose topic matches an admitted path IS injected" ;;
  *) no "a matching prior decision was not injected" ;; esac
grep -qF "SENTINELDECISIONUNMATCHED" "$CA" \
  && no "an unmatched decision's TEXT leaked into the capsule" \
  || ok "an unmatched decision's text is NOT injected"
case "$ex" in *"docs/marketing"*) ok "the unmatched decision's TOPIC is listed in excluded_notable" ;;
  *) no "the unmatched decision was withheld without disclosure" ;; esac
case "$inc" in *"decision:src/auth"*) ok "the injected decision carries its admitting rule" ;;
  *) no "the injected decision has no provenance row" ;; esac

echo
echo "== 9. Artifact refs — over threshold is referenced, never inlined =="
ar="$(q "$CA" artifact_refs)"
case "$ar" in *baseline_log*) ok "the oversized artifact appears as an artifact_ref" ;;
  *) no "the oversized artifact is not referenced" ;; esac
node -e '
const c=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));
const a=(c.artifact_refs||[]).find(x=>x.id==="baseline_log");
if(!a) process.exit(1);
const okSha=/^[0-9a-f]{64}$/.test(a.sha256||"");
const okBytes=Number.isInteger(a.bytes)&&a.bytes>0;
const okSum=typeof a.summary==="string"&&a.summary.trim()!==""&&!a.summary.includes("\n");
const notInlined=!("inline" in a);
process.exit(okSha&&okBytes&&okSum&&notInlined?0:1);
' "$CA" && ok "artifact_ref carries sha256 + one-line summary + bytes, and no inline body" \
  || no "artifact_ref is malformed or inlined an oversized artifact"
grep -qF "SENTINELBIGARTIFACTBODY" "$CA" \
  && no "the oversized artifact body was inlined into capsule.json" \
  || ok "the oversized artifact body is ABSENT from capsule.json"
grep -qF "SENTINELBIGARTIFACTBODY" "$MA" \
  && no "the oversized artifact body was inlined into capsule.md" \
  || ok "the oversized artifact body is ABSENT from capsule.md"
grep -qF "SENTINELSMALLARTIFACTBODY" "$CA" \
  && ok "the small artifact IS inlined (the threshold cuts both ways)" \
  || no "a small artifact was needlessly referenced instead of inlined"
node -e '
const c=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));
const a=(c.artifact_refs||[]).find(x=>x.id==="index");
process.exit(a && /^[0-9a-f]{64}$/.test(a.sha256||"") ? 0 : 1);
' "$CA" && ok "the index itself is pinned by sha256 as an artifact_ref" \
  || no "the index is not pinned by sha256 — the capsule cannot prove what it was built from"
# A JSON file's first line is not a summary — it is a leak of the very bytes
# the capsule declined to inline. The index summary must be DERIVED.
node -e '
const c=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));
const a=(c.artifact_refs||[]).find(x=>x.id==="index");
process.exit(a && /repository index/.test(a.summary) && !a.summary.includes("\"index_version\":") ? 0 : 1);
' "$CA" && ok "the index summary is derived prose, not a leaked first line of the index" \
  || no "the index summary leaks raw index bytes instead of describing it"
th="$(q "$CA" budget.artifact_inline_threshold_bytes)"
[ "$th" -gt 0 ] 2>/dev/null && ok "the inline threshold is stated in the capsule ($th bytes)" \
  || no "the inline threshold is not stated"

echo
echo "== 10. capsule-stats — honest tiers, proxy is ESTIMATE and never EXACT =="
node "$STATS" --capsule "$CA" --md "$MA" > "$WORK/stats.txt" 2>&1 \
  && ok "capsule-stats.mjs exited 0" || no "capsule-stats.mjs failed"
grep -qE 'estimated_tokens[a-z_]*[[:space:]]+[0-9]+[[:space:]]+ESTIMATE' "$WORK/stats.txt" \
  && ok "the token proxy is LABELED ESTIMATE" || no "the token proxy is not labeled ESTIMATE"
grep -E 'estimated_tokens' "$WORK/stats.txt" | grep -q 'EXACT' \
  && no "the token proxy is labeled EXACT — the tier vocabulary is binding" \
  || ok "the token proxy is never labeled EXACT"
grep -qE 'chars/4' "$WORK/stats.txt" && ok "stats names the proxy formula (chars/4)" \
  || no "stats does not disclose how the proxy is derived"
grep -qE 'prefix_bytes[[:space:]]+[0-9]+' "$WORK/stats.txt" && ok "bytes reported for the prefix section" \
  || no "no per-section byte accounting for the prefix"
grep -qE 'slow_bytes[[:space:]]+[0-9]+' "$WORK/stats.txt" && ok "bytes reported for the slow section" \
  || no "no per-section byte accounting for the slow section"
grep -qE 'volatile_bytes[[:space:]]+[0-9]+' "$WORK/stats.txt" && ok "bytes reported for the volatile section" \
  || no "no per-section byte accounting for the volatile section"
grep -qE 'admitted_files[[:space:]]+7[[:space:]]+EXACT' "$WORK/stats.txt" \
  && ok "admitted_files count is reported and EXACT (a count truly is exact)" \
  || no "admitted_files count wrong or untiered"
grep -qE 'excluded_notable[[:space:]]+[0-9]+[[:space:]]+EXACT' "$WORK/stats.txt" \
  && ok "excluded_notable count is reported" || no "excluded_notable count not reported"
node "$STATS" --capsule "$CA" --md "$MA" --json > "$WORK/stats.json" 2>&1
node -e '
const s=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));
const t=s.token_proxy;
process.exit(t && t.tier==="ESTIMATE" && typeof t.formula==="string" ? 0 : 1);
' "$WORK/stats.json" && ok "--json marks the token proxy tier ESTIMATE with its formula" \
  || no "--json does not tier the token proxy"

echo
echo "== 11. Degenerate inputs produce an HONEST minimal capsule, not a crash =="
echo '{}' > "$FIX/empty-index.json"
cat > "$FIX/task-min.json" <<'EOF'
{ "task_id": "TASK-MIN", "objective": "Do the smallest possible thing." }
EOF
OUTD="$WORK/out-d"
node "$COMPILE" compile --index "$FIX/empty-index.json" --task "$FIX/task-min.json" \
  --deterministic --out "$OUTD" >"$WORK/d.log" 2>&1 \
  && ok "empty index + seedless task exits 0 (no crash)" || { no "degenerate compile crashed"; sed 's/^/    /' "$WORK/d.log"; }
CD="$OUTD/capsule.json"
if [ -s "$CD" ]; then
  [ "$(q "$CD" relevant_files)" = "[]" ] && ok "degenerate capsule admits no files rather than inventing some" \
    || no "degenerate capsule invented relevant files"
  [ "$(q "$CD" acceptance)" = "[]" ] && ok "missing acceptance renders as [] (present, honest)" \
    || no "missing acceptance is malformed"
  [ "$(q "$CD" baseline.targeted)" = "not measured" ] \
    && ok "unmeasured baseline says 'not measured' (never a fabricated number)" \
    || no "unmeasured baseline is not honestly labeled"
  exd="$(q "$CD" provenance.excluded_notable)"
  case "$exd" in *"no seed"*) ok "the capsule states WHY it is empty (no seeds supplied)" ;;
    *) no "an empty capsule that does not explain itself" ;; esac
  for k in capsule_version task_id relevant_files provenance authority budget verification; do
    [ "$(q "$CD" "$k")" != "__UNDEF__" ] && ok "degenerate capsule still carries $k" \
      || no "degenerate capsule dropped $k"
  done
  [ -s "$OUTD/capsule.md" ] && ok "degenerate capsule still renders a capsule.md" || no "no capsule.md for the degenerate case"
  sect "$OUTD/capsule.md" PREFIX > "$WORK/pre.d"
  cmp -s "$WORK/pre.d" "$WORK/pre.a" && ok "even the degenerate capsule carries the identical prefix" \
    || no "the degenerate capsule's prefix drifted"
  node "$STATS" --capsule "$CD" --md "$OUTD/capsule.md" >/dev/null 2>&1 \
    && ok "capsule-stats survives a degenerate capsule" || no "capsule-stats crashed on a degenerate capsule"
else
  no "degenerate compile produced no capsule.json"
fi
node "$COMPILE" compile --index "$FIX/index.json" --task "$FIX/nonexistent.json" >/dev/null 2>&1 \
  && no "a missing task file was accepted silently" || ok "a missing task file exits non-zero with an error"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
