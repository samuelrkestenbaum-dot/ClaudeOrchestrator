#!/usr/bin/env bash
# Neurocosmology architecture invariants — the boundaries that keep the math
# suite honest. Each test is mechanical: greps against LIVE surfaces, code
# ORDER checks, UCDL behavior probes, and schema enforcement of the
# math-to-effect registry (a wired claim must trace to a real caller).
set -u
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d /tmp/bos-ncinv.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT
PASS=0; FAIL=0
ok(){ if eval "$1"; then PASS=$((PASS+1)); echo "  PASS: $2"; else FAIL=$((FAIL+1)); echo "  FAIL: $2"; fi }
REG="$SRC/build-os/registry/neurocosmology_math_registry.md"

# The speculative (R/C) vocabulary that must stay out of factual substrate
# and hard authority. Word-boundary'd to avoid incidental prose hits.
RC='curvature|attractor|geodesic|christoffel|emotional_mass|correction_mass|salience|entropy_gradient|rumination_score|trust_score|latent_density|hubble'

echo "== 1. R/C math cannot enter FACTUAL SUBSTRATE builders =="
SUBSTRATE="$SRC/.claude/hooks/project-identity.sh $SRC/build-os/tools/goal-check.sh $SRC/build-os/tools/meter-run.sh $SRC/build-os/tools/residue-sweep.sh"
ok '! grep -EiqH "$RC" $SUBSTRATE' "substrate builders carry no speculative-geometry vocabulary"

echo "== 2. R/C math cannot permit, block, or widen AUTHORITY =="
AUTH="$SRC/.claude/hooks/routing-gate.sh $SRC/build-os/tools/publish-check.mjs $SRC/build-os/learning/publication-authority.mjs $SRC/.claude/hooks/mcp-readonly-allowlist.txt"
ok '! grep -EiqH "$RC" $AUTH' "authority surfaces carry no speculative-geometry vocabulary"
ok '! grep -q "ucdl" "$SRC/.claude/hooks/routing-gate.sh"' "authority hook never consults the cognition compiler (UCDL)"

echo "== 3. no score can resurrect an unreachable/unmatched action =="
node --input-type=module -e "
import { deliver } from '$SRC/build-os/delivery/ucdl.mjs';
const store = '## RULE TS9998 — unrelated\n- applicability: files where tsc reports any of: TS9998\n- provenance: sequence=X rep=1 position=1 run=r authored_by=t\n';
const r = deliver({ storeText: store, query: { codes: ['TS1111'] }, capBytes: 10_000_000,
  no_context: { reason: 'invariant probe' } });
const leaked = r.receipt.selected_ids.length;
const reason = r.receipt.considered[0]?.reason || '';
console.log(JSON.stringify({ leaked, reason }));
" > "$WORK/resurrect.json" 2>"$WORK/err"
ok '[ "$(python3 -c "import json;d=json.load(open(\"$WORK/resurrect.json\"));print(d[\"leaked\"]==0 and \"no_match\" in d[\"reason\"])")" = "True" ]' \
  "an unmatched unit is NEVER selected, even with effectively infinite budget; rejection reason recorded"

echo "== 4. homeostasis and gates run BEFORE autonomy/dispatch (code order) =="
# The authority gate is invoked ONCE, inside the reachability construction
# (admission = the same evaluation, not a second control). cmd_run order:
# H0 -> reachability(authority inside) -> dispatch.
H0_LINE=$(grep -n 'h0-check.sh" "\$d" >/dev/null' "$SRC/bin/gravito" | head -1 | cut -d: -f1)
REACH_LINE=$(grep -n 'reachability.mjs" --json' "$SRC/bin/gravito" | head -1 | cut -d: -f1)
SPAWN_LINE=$(grep -n 'claude -p --output-format' "$SRC/bin/gravito" | head -1 | cut -d: -f1)
ok '[ -n "$H0_LINE" ] && [ -n "$REACH_LINE" ] && [ -n "$SPAWN_LINE" ] && [ "$H0_LINE" -lt "$REACH_LINE" ] && [ "$REACH_LINE" -lt "$SPAWN_LINE" ]' \
  "cmd_run: H0 ($H0_LINE) -> reachability ($REACH_LINE) -> dispatch ($SPAWN_LINE), in order"
ok 'grep -q -- "--gate" "$SRC/build-os/tools/reachability.mjs" && ! grep -q -- "--gate \"\$d/gravito.goal\"" "$SRC/bin/gravito"' \
  "the authority gate runs ONCE, inside the reachability construction (no duplicate gate in cmd_run)"
PREF_LINE=$(grep -n 'cmd_preflight "\$d" || die' "$SRC/bin/gravito" | head -1 | cut -d: -f1)
INST_LINE=$(grep -n 'install-project.sh" "\$d"' "$SRC/bin/gravito" | head -1 | cut -d: -f1)
ok '[ -n "$PREF_LINE" ] && [ "$PREF_LINE" -lt "$INST_LINE" ]' \
  "cmd_init: substrate preflight (line $PREF_LINE) precedes install (line $INST_LINE)"

echo "== 5. cognition compilation only AFTER authority is resolved =="
GG_LINE=$(grep -n 'goal_gate_or_block "\$_gtool"' "$SRC/.claude/hooks/routing-gate.sh" | head -1 | cut -d: -f1)
CLS_LINE=$(grep -n 'mut_classify' "$SRC/.claude/hooks/routing-gate.sh" | grep -v '(){' | head -1 | cut -d: -f1)
ok '[ -n "$GG_LINE" ] && [ -n "$CLS_LINE" ] && [ "$GG_LINE" -lt "$CLS_LINE" ]' \
  "mutgate: goal gate (line $GG_LINE) precedes routing classification (line $CLS_LINE)"
ok '! grep -rq "delivery/ucdl" "$SRC/.claude/hooks" "$SRC/bin" "$SRC/build-os/tools"' \
  "UCDL has NO runtime caller in hooks/CLI/tools (Phase-1 boundary held; wiring needs its own go)"

echo "== 6. worker context excludes governance/convergence/machinery internals =="
node --input-type=module -e "
import { deliver } from '$SRC/build-os/delivery/ucdl.mjs';
import fs from 'node:fs';
const store = fs.readFileSync('$SRC/build-os/experiments/EXP-0011-reusable-skills/memory-stores/G.rep1.leanrules/repair-rules.md','utf8');
const ctx = deliver({ storeText: store, query: { codes: ['TS2339'] }, capBytes: 4096, renderer: 'context' });
const skl = deliver({ storeText: store, query: { codes: ['TS2339'] }, capBytes: 4096, renderer: 'skill' });
const dirty = /UCDL|ucdl_version|policy|receipt|candidates|decision:|score|convergence|attractor|routing ledger/i;
console.log(JSON.stringify({ ctx_clean: !dirty.test(ctx.output), skl_clean: !dirty.test(skl.output) }));
" > "$WORK/clean.json" 2>"$WORK/err"
ok '[ "$(python3 -c "import json;d=json.load(open(\"$WORK/clean.json\"));print(d[\"ctx_clean\"] and d[\"skl_clean\"])")" = "True" ]' \
  "rendered worker output carries no delivery machinery, scores, or governance vocabulary"
ok '! grep -Eiq "attractor|curvature|convergence|routing ledger|readiness" "$SRC/build-os/experiments/EXP-0011-reusable-skills/results/runs/G1.leanrules.r1/prompt.txt"' \
  "sealed real worker prompt (read-only spot check) contains no substrate bookkeeping"

echo "== 7-8. empty-unintended invalid before spend; NO_CONTEXT explicit + receipted =="
node --input-type=module -e "
import { deliver } from '$SRC/build-os/delivery/ucdl.mjs';
const bad = deliver({ storeText: '', query: { codes: ['TSX'] }, capBytes: 1000 });
const okd = deliver({ storeText: '', query: { codes: ['TSX'] }, capBytes: 1000, no_context: { reason: 'probe' } });
console.log(JSON.stringify({ bad_invalid: bad.invalid_empty && !bad.ok, ok_receipted: okd.ok && okd.receipt.no_context.reason === 'probe' }));
" > "$WORK/empty.json" 2>"$WORK/err"
ok '[ "$(python3 -c "import json;d=json.load(open(\"$WORK/empty.json\"));print(d[\"bad_invalid\"] and d[\"ok_receipted\"])")" = "True" ]' \
  "invalid-empty and explicit NO_CONTEXT semantics hold"

echo "== 9. raw evidence is immutable through the delivery layer =="
ok '! grep -Eq "writeFileSync|appendFileSync|rmSync|unlink|from \"node:fs\"|from '\''node:fs'\''" "$SRC/build-os/delivery/ucdl.mjs"' \
  "ucdl.mjs cannot write: no fs import, no write calls — stores are read-only inputs"

echo "== 10. registry schema: statuses valid; wired claims trace to real callers =="
python3 - "$REG" "$SRC" <<'PY' > "$WORK/reg.json"
import json, re, sys, os
reg, src = sys.argv[1], sys.argv[2]
txt = open(reg).read()
entries = [e for e in re.split(r'^## ', txt, flags=re.M)[1:]]
FIELDS = ['equation','class','zone','implementation','caller','inputs','decision','receipt','baseline','falsifier','outcome-test','status']
STATUSES = {'theoretical','implemented-unwired','wired-unproven','outcome-proven'}
LEVELS = ('event','arm','task','sequence','experiment','subsystem','program')
problems, n = [], 0
for e in entries:
    n += 1
    name = e.split('\n')[0].strip()
    f = {}
    for fld in FIELDS:
        m = re.search(r'^- %s: (.*)$' % re.escape(fld), e, flags=re.M)
        if not m: problems.append(f'{name}: missing field {fld}'); continue
        f[fld] = m.group(1).strip()
    st = f.get('status','')
    if st not in STATUSES: problems.append(f'{name}: bad status {st!r}')
    cls = f.get('class','')
    if cls not in ('R','A','B','C','D'): problems.append(f'{name}: bad class {cls!r}')
    if cls in ('C','D'):
        for k in ('falsifier','baseline'):
            if f.get(k,'').lower() in ('','none','n/a'): problems.append(f'{name}: class {cls} needs a real {k}')
    if st in ('wired-unproven','outcome-proven'):
        if f.get('caller','none').strip().lower() == 'none':
            problems.append(f'{name}: wired status with caller=none')
        paths = re.findall(r'[A-Za-z0-9_./\-]+\.(?:sh|mjs|json|txt|md)', f.get('implementation','')) or []
        if not any(os.path.exists(os.path.join(src,p)) for p in paths):
            problems.append(f'{name}: wired status but no implementation path exists on disk')
        callers = re.findall(r'(?:bin/gravito|[A-Za-z0-9_./\-]+\.(?:sh|mjs|json))', f.get('caller','')) or []
        traced = False
        for c in callers:
            cp = os.path.join(src,c)
            if not os.path.exists(cp): continue
            ctext = open(cp, errors='ignore').read()
            if any(os.path.basename(p) in ctext for p in paths) or c in f.get('implementation',''):
                traced = True; break
        if callers and not traced:
            problems.append(f'{name}: no caller file references any implementation basename (wired-by-filename?)')
    if st == 'outcome-proven':
        if not any((lv + ' level') in f.get('outcome-test','') for lv in LEVELS):
            problems.append(f'{name}: outcome-proven without a named proof LEVEL (scale rule)')
print(json.dumps({'entries': n, 'problems': problems}))
PY
ok '[ "$(python3 -c "import json;d=json.load(open(\"$WORK/reg.json\"));print(d[\"entries\"]>=40 and len(d[\"problems\"])==0)")" = "True" ]' \
  "registry: >=40 entries, all 12 fields, valid enums, C/D falsifier+baseline, wired claims trace to real callers, proof levels named"
python3 -c "import json;d=json.load(open('$WORK/reg.json'));[print('   ',p) for p in d['problems'][:12]]"

echo "== 11. outcome feedback may calibrate selection but cannot rewrite history =="
ok 'grep -q "theta_sufficiency" "$SRC/build-os/delivery/ucdl.mjs" && grep -q "never blocking" "$SRC/build-os/delivery/ucdl.mjs"' \
  "uncalibrated C-class threshold is declared+receipted, holds no hard authority (calibration deferred to Zone 10)"
ok 'grep -q "no wall clock" "$SRC/build-os/delivery/ucdl.mjs" || grep -q "byte-identical" "$SRC/build-os/delivery/ucdl.mjs"' \
  "delivery receipts are deterministic derivations of inputs — never retro-edited truth"

echo "== 12b. reachability status is SPLIT by decision boundary — no collapse =="
ok 'grep -q "^## Reachability: run/dispatch admission" "$REG" && grep -q "^## Zone-4 deterministic planner" "$REG"' \
  "registry carries admission and planner as SEPARATE entries (statuses cannot re-merge)"
ok '! grep -q "^## Reachability set R_t and admissible R_t+$" "$REG"' "the old combined entry is gone"
ok 'grep -A20 "^## Zone-4 deterministic planner" "$REG" | grep "^- caller:" | grep -q "cmd_run"' \
  "planner wired status is backed by a NAMED production caller, never source presence"
ok 'grep -A30 "^## Zone-4 deterministic planner" "$REG" | grep -q "OUTCOME VALUE: UNPROVEN"' \
  "planner outcome value explicitly UNPROVEN (E2E tests prove wiring, not benefit)"

echo "== 12. sealed experiment evidence untouched by this packet =="
ok '[ -z "$(cd "$SRC" && git status --porcelain -- build-os/experiments/EXP-0011-reusable-skills build-os/experiments/EXP-0010* 2>/dev/null)" ]' \
  "no modification to sealed EXP-0010/0011 trees in the working tree"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
