#!/usr/bin/env bash
# UCDL Phase 1 — failure-first proof of the Unified Context Delivery Layer.
#
# Section 1 REPRODUCES the EXP-0011 starvation from SEALED evidence
# (read-only): the legacy selector, given the exact store state G5 saw live
# (rules 1-4) and G5's real query, matches rules and delivers 0 bytes —
# then UCDL, same store, same query, same 1536B budget, delivers non-empty
# because units are atomic below the budget floor. The defect and the fix
# are demonstrated against the same frozen inputs.
set -u
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d /tmp/bos-ucdl.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT
PASS=0; FAIL=0
ok(){ if eval "$1"; then PASS=$((PASS+1)); echo "  PASS: $2"; else FAIL=$((FAIL+1)); echo "  FAIL: $2"; fi }
EXP="$SRC/build-os/experiments/EXP-0011-reusable-skills"
run(){ node --input-type=module -e "$1" 2>"$WORK/err"; }

echo "== 1. the sealed-evidence replay: legacy starves, UCDL delivers =="
run "
import { selectRules, splitRules } from '$EXP/skill-lib.mjs';
import { deliver } from '$SRC/build-os/delivery/ucdl.mjs';
import fs from 'node:fs';
const full = fs.readFileSync('$EXP/memory-stores/G.rep1.leanrules/repair-rules.md','utf8');
const g5era = splitRules(full).slice(0,4).join('');           // the store G5 saw live
fs.writeFileSync('$WORK/g5-era-store.md', g5era);
const legacy = selectRules('$WORK/g5-era-store.md', ['TS2339']); // G5's real query
const u = deliver({ storeText: g5era, query: { codes: ['TS2339'] }, capBytes: 1536 });
console.log(JSON.stringify({ legacy_matched: legacy.matched, legacy_bytes: legacy.bytes,
  ucdl_ok: u.ok, ucdl_bytes: u.receipt.delivered_bytes, ucdl_selected: u.receipt.selected_ids.length,
  ucdl_truncated: u.receipt.truncated }));
" > "$WORK/replay.json"
ok '[ "$(python3 -c "import json;d=json.load(open(\"$WORK/replay.json\"));print(d[\"legacy_matched\"]>0 and d[\"legacy_bytes\"]==0)")" = "True" ]' \
  "legacy selector on G5-era sealed store: matched>0 yet 0 bytes (live starvation reproduced)"
ok '[ "$(python3 -c "import json;d=json.load(open(\"$WORK/replay.json\"));print(d[\"ucdl_ok\"] and d[\"ucdl_bytes\"]>0)")" = "True" ]' \
  "UCDL, same store/query/1536B budget: non-empty delivery (insight atoms fit)"
ok '[ "$(python3 -c "import json;print(json.load(open(\"$WORK/replay.json\"))[\"ucdl_truncated\"])")" = "True" ]' \
  "UCDL records the truncation it performed (oversize exhibits held back, not hidden)"

echo "== 2. unintended empty delivery is INVALID before spend =="
run "
import { deliver } from '$SRC/build-os/delivery/ucdl.mjs';
const r = deliver({ storeText: '', query: { codes: ['TS9999'] }, capBytes: 1536 });
console.log(JSON.stringify({ ok: r.ok, invalid: r.invalid_empty, out: r.output.length, empty: r.receipt.empty }));
" > "$WORK/empty.json"
ok '[ "$(python3 -c "import json;d=json.load(open(\"$WORK/empty.json\"));print((not d[\"ok\"]) and d[\"invalid\"] and d[\"out\"]==0)")" = "True" ]' \
  "empty selection without NO_CONTEXT => ok=false, invalid_empty=true, zero output"

echo "== 3. explicit NO_CONTEXT is a recorded decision, not a bypass =="
run "
import { deliver } from '$SRC/build-os/delivery/ucdl.mjs';
const r = deliver({ storeText: '', query: { codes: ['TS9999'] }, capBytes: 1536,
  no_context: { reason: 'position 1 of a fresh sequence — no prior units exist by design' } });
console.log(JSON.stringify({ ok: r.ok, no_context: r.receipt.no_context }));
" > "$WORK/noctx.json"
ok '[ "$(python3 -c "import json;d=json.load(open(\"$WORK/noctx.json\"));print(d[\"ok\"] and d[\"no_context\"][\"allowed\"] and \"fresh sequence\" in d[\"no_context\"][\"reason\"])")" = "True" ]' \
  "NO_CONTEXT with reason => valid, decision recorded verbatim in the receipt"

echo "== 4. receipts are complete: every candidate has a decision and a reason =="
run "
import { deliver, parseRuleStore } from '$SRC/build-os/delivery/ucdl.mjs';
import fs from 'node:fs';
const store = fs.readFileSync('$EXP/memory-stores/M.rep1.leanrules/repair-rules.md','utf8');
const r = deliver({ storeText: store, query: { codes: ['TS18046'] }, capBytes: 2048 });
const c = r.receipt.considered;
const complete = c.length === r.receipt.candidates && c.every(x => x.decision && x.reason && (x.decision==='selected' || x.reason.length>0));
const prov = c.every(x => x.provenance && x.provenance.sequence === 'M');
console.log(JSON.stringify({ complete, prov, n: c.length, rejected_reasons: [...new Set(c.filter(x=>x.decision==='rejected').map(x=>x.reason))] }));
" > "$WORK/receipt.json"
ok '[ "$(python3 -c "import json;d=json.load(open(\"$WORK/receipt.json\"));print(d[\"complete\"] and d[\"prov\"])")" = "True" ]' \
  "every candidate carries decision+reason; provenance intact from the sealed store"

echo "== 5. determinism: identical inputs => byte-identical receipts =="
run "
import { deliver } from '$SRC/build-os/delivery/ucdl.mjs';
import fs from 'node:fs';
const store = fs.readFileSync('$EXP/memory-stores/G.rep1.leanrules/repair-rules.md','utf8');
const a = deliver({ storeText: store, query: { codes: ['TS2339'] }, capBytes: 3072 });
const b = deliver({ storeText: store, query: { codes: ['TS2339'] }, capBytes: 3072 });
console.log(JSON.stringify({ identical: JSON.stringify(a.receipt) === JSON.stringify(b.receipt), sha: a.receipt.output_sha256 === b.receipt.output_sha256 }));
" > "$WORK/det.json"
ok '[ "$(python3 -c "import json;d=json.load(open(\"$WORK/det.json\"));print(d[\"identical\"] and d[\"sha\"])")" = "True" ]' \
  "two runs, same inputs: receipts and output hashes byte-identical (no clock, no randomness)"

echo "== 6. selection is separated from rendering: two surfaces, one selection =="
run "
import { deliver } from '$SRC/build-os/delivery/ucdl.mjs';
import fs from 'node:fs';
const store = fs.readFileSync('$EXP/memory-stores/G.rep1.leanrules/repair-rules.md','utf8');
const ctx = deliver({ storeText: store, query: { codes: ['TS2339'] }, capBytes: 3072, renderer: 'context' });
const skl = deliver({ storeText: store, query: { codes: ['TS2339'] }, capBytes: 3072, renderer: 'skill', rendererMeta: { name: 'repair-governance' } });
console.log(JSON.stringify({ same_selection: JSON.stringify(ctx.receipt.selected_ids) === JSON.stringify(skl.receipt.selected_ids),
  different_output: ctx.receipt.output_sha256 !== skl.receipt.output_sha256,
  skill_frontmatter: /^---\nname: repair-governance\n/.test(skl.output) }));
" > "$WORK/sep.json"
ok '[ "$(python3 -c "import json;d=json.load(open(\"$WORK/sep.json\"));print(d[\"same_selection\"] and d[\"different_output\"] and d[\"skill_frontmatter\"])")" = "True" ]' \
  "context vs SKILL.md renderers: identical selected_ids, different surfaces only"

echo "== 7. budget policies are explicit and their differences are visible =="
run "
import { deliver } from '$SRC/build-os/delivery/ucdl.mjs';
import fs from 'node:fs';
const store = fs.readFileSync('$EXP/memory-stores/G.rep1.leanrules/repair-rules.md','utf8');
const atom = deliver({ storeText: store, query: { codes: ['TS2339'] }, capBytes: 1536, policyName: 'insight-first@1' });
const unit = deliver({ storeText: store, query: { codes: ['TS2339'] }, capBytes: 1536, policyName: 'whole-unit@1',
  no_context: { reason: 'controlled comparison arm may legitimately deliver nothing' } });
let bad=false; try { deliver({ storeText: store, query: { codes:['TS2339'] }, capBytes: 999, policyName: 'made-up@9' }); } catch(e) { bad = /never guessed/.test(e.message); }
console.log(JSON.stringify({ atom_bytes: atom.receipt.delivered_bytes, unit_bytes: unit.receipt.delivered_bytes,
  policies_differ: atom.receipt.delivered_bytes !== unit.receipt.delivered_bytes,
  policy_recorded: atom.receipt.policy.name === 'insight-first@1' && atom.receipt.policy.cap_bytes === 1536,
  unknown_policy_refused: bad }));
" > "$WORK/pol.json"
ok '[ "$(python3 -c "import json;d=json.load(open(\"$WORK/pol.json\"));print(d[\"policies_differ\"] and d[\"policy_recorded\"] and d[\"unknown_policy_refused\"])")" = "True" ]' \
  "insight-first vs whole-unit differ measurably at 1536B; policy+cap in receipt; unknown policy refused"

echo "== 8. migration: sealed stores parse losslessly into units =="
run "
import { parseRuleStore } from '$SRC/build-os/delivery/ucdl.mjs';
import fs from 'node:fs';
let total=0, withProv=0, stores=0;
for (const s of ['G.rep1.leanrules','M.rep1.leanrules','G.rep2.leanrules','G.rep1.leanskills','M.rep1.leanskills']) {
  const p = '$EXP/memory-stores/' + s + '/repair-rules.md';
  if (!fs.existsSync(p)) continue;
  stores++;
  const txt = fs.readFileSync(p,'utf8');
  const units = parseRuleStore(txt);
  const headings = (txt.match(/^## RULE /gm) || []).length;
  if (units.length !== headings) { console.log(JSON.stringify({error:'count mismatch',s,units:units.length,headings})); process.exit(1); }
  total += units.length; withProv += units.filter(u=>u.provenance).length;
}
console.log(JSON.stringify({ stores, total, withProv, lossless: total===withProv }));
" > "$WORK/mig.json"
ok '[ "$(python3 -c "import json;d=json.load(open(\"$WORK/mig.json\"));print(d[\"stores\"]>=3 and d[\"total\"]>0 and d[\"lossless\"])")" = "True" ]' \
  "every sealed store parses; unit count == heading count; provenance on every unit"

echo "== 9. no-spend concurrency calibration runs and reports the precommitted rule =="
node "$SRC/build-os/delivery/calibrate-noload.mjs" --width 2 --reps 2 --work 40 > "$WORK/cal.json" 2>&1; CAL_RC=$?
ok '[ "$CAL_RC" = 0 ] || [ "$CAL_RC" = 1 ]' "calibration completes with a verdict (exit $CAL_RC), no model workers spawned"
ok '[ "$(python3 -c "import json;d=json.load(open(\"$WORK/cal.json\"));print(d[\"bound\"]==0.10 and \"inflation\" in d and \"provider-side\" in d[\"scope\"])")" = "True" ]' \
  "verdict carries the precommitted 10% bound and states its provider-blindness honestly"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
