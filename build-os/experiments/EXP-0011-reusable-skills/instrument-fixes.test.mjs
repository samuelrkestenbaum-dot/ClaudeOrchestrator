#!/usr/bin/env node
// EXP-0011 freeze preconditions — both instrument fixes, regression-tested.
// Test 1 uses the PRESERVED EXP-0010 false-positive diff VERBATIM, per the
// operator's instruction.
import fs from "node:fs";
import path from "node:path";
import { scanDiff } from "../EXP-0006-operational-uic/harness/acceptance.mjs";
import { selectRules } from "./skill-lib.mjs";
const HERE = path.dirname(new URL(import.meta.url).pathname);
let n = 0; const ok = (cond, msg) => { if (!cond) { console.error(`FAIL: ${msg}`); process.exit(1); } n++; };

// 1a. The preserved A1.leanrules.r1 diff must no longer trip any_cast.
const preserved = fs.readFileSync(path.join(HERE, "../EXP-0010-rule-memory/results/runs/A1.leanrules.r1/full.diff"), "utf8");
const s1 = scanDiff(preserved, "server/emotional-geometry-runtime/alert-analytics.ts");
ok(!(s1.net_introduced && s1.net_introduced.any_cast), "preserved A1.leanrules.r1 diff still trips any_cast (prose 'as any' in a comment)");

// 1b. Positive control — a REAL any cast on an added code line still rejects.
const realCast = `diff --git a/x.ts b/x.ts\n--- a/x.ts\n+++ b/x.ts\n@@ -1,1 +1,2 @@\n context\n+const y = data as any;\n`;
const s2 = scanDiff(realCast, "x.ts");
ok(s2.net_introduced.any_cast === 1, "real 'as any' code line no longer rejected — fix over-broad");

// 1c. Comment-dwelling suppressions must STILL fire (they only exist in comments).
const tsIgnore = `diff --git a/x.ts b/x.ts\n--- a/x.ts\n+++ b/x.ts\n@@ -1,1 +1,2 @@\n context\n+// @ts-ignore\n`;
const s3 = scanDiff(tsIgnore, "x.ts");
ok(s3.net_introduced.ts_ignore === 1, "@ts-ignore in a comment no longer rejected — comment-skip leaked onto suppression patterns");

// 1d. A prose 'as any' in a JSDoc interior line (the exact EXP-0010 shape).
const prose = `diff --git a/x.ts b/x.ts\n--- a/x.ts\n+++ b/x.ts\n@@ -1,1 +1,2 @@\n context\n+ * case on the same route as any other query failure: each exported function\n`;
const s4 = scanDiff(prose, "x.ts");
ok(!(s4.net_introduced && s4.net_introduced.any_cast), "JSDoc prose 'as any' still trips any_cast");

// 2. FIXED selector: an oversized newest rule is SKIPPED, not a blocker.
const tmp = path.join(HERE, "memory-stores", ".selector-test");
fs.mkdirSync(tmp, { recursive: true });
const store = path.join(tmp, "repair-rules.md");
const small = `## RULE TS9001 — small\n- provenance: sequence=T rep=1 position=1 run=t authored_by=harness-rule-distiller\n\nbody\n\n`;
const big = `## RULE TS9001 — big\n- provenance: sequence=T rep=1 position=2 run=t authored_by=harness-rule-distiller\n\n${"x".repeat(2000)}\n\n`;
fs.writeFileSync(store, small + big); // big is NEWEST (appended last)
const sel = selectRules(store, ["TS9001"]);
ok(sel.matched === 2, `selector matched ${sel.matched}, expected 2`);
ok(sel.text.includes("small") && !sel.text.includes("xxxx"), "oversized newest rule still blocks smaller older rule (break-at-cap regression)");
ok(sel.skipped_oversize === 1, "oversize skip not reported");
fs.rmSync(tmp, { recursive: true, force: true });

console.log(`${n} assertions passed — both freeze preconditions hold`);
