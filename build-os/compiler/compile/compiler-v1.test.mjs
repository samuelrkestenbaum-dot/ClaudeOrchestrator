// Context Compiler v1 — regression fixtures for the defects EXP-0004 found.
//
// Every fixture below is SYNTHETIC. None re-runs EXP-0004's five frozen tasks:
// those outcomes have been observed, so measuring v1 against them and calling
// the result an improvement would be post-treatment tuning of a frozen
// experiment. E2's SHAPE is reproduced here as a named fixture; E2 itself is
// not re-executed and no claim is made that v1 "would have passed" it.
//
// Run: node build-os/compiler/compile/compiler-v1.test.mjs

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { semanticEvidence, selectEvidence, errorSignals, writtenProperties } from "./semantic.mjs";
import { shouldCompile, THRESHOLDS } from "./should-compile.mjs";

let pass = 0, fail = 0;
const results = [];
function check(name, cond, detail = "") {
  if (cond) { pass++; results.push(`  ok   ${name}`); }
  else { fail++; results.push(`  FAIL ${name}${detail ? " — " + detail : ""}`); }
}

// ---------------------------------------------------------------- fixtures --
const root = fs.mkdtempSync(path.join(os.tmpdir(), "cc-v1-"));
const w = (rel, body) => {
  const f = path.join(root, rel);
  fs.mkdirSync(path.dirname(f), { recursive: true });
  fs.writeFileSync(f, body);
  return rel;
};

// FIXTURE A — the E2 SHAPE: a defining file writes a property that a test
// asserts on, and the task's own error names that property. This is the defect
// that decided EXP-0004's verdict.
w("src/policy-router.ts", `
import { upsert } from "./store";
export const policyRouter = {
  create(input: any) {
    return upsert({ name: input.name, domain: input.domain, enabled: true });
  },
};
`);
w("src/store.ts", `export function upsert(p: any) { return p; }`);
w("src/policy-router.test.ts", `
import { policyRouter } from "./policy-router";
it("keeps the policy name", () => {
  const r = policyRouter.create({ name: "n", domain: "d" });
  expect(r.name).toBe("n");
});
`);
// FIXTURE B — a mocked module: the test cannot see a shape change at all.
w("src/mocked.test.ts", `
import { policyRouter } from "./policy-router";
vi.mock("./policy-router", () => ({ policyRouter: { create: () => ({}) } }));
it("mocks it", () => { expect(policyRouter.create).toBeDefined(); });
`);
// FIXTURE C — a chatty neighbour that must NOT crowd out fixture A's witness.
w("src/loud.test.ts", `
import { policyRouter } from "./policy-router";
${Array.from({ length: 40 }, (_, i) => `it("loud ${i}", () => { expect(policyRouter.create({}).domain).toBe(${i}); });`).join("\n")}
`);

const idx = {
  index_version: 1,
  files: {
    "src/policy-router.ts": { symbols: ["policyRouter"], parser: "js-ts-regex-v0", partial: true, imports: ["src/store.ts"], imported_by: [], tests_covering: ["src/policy-router.test.ts"] },
    "src/store.ts": { symbols: ["upsert"], parser: "js-ts-regex-v0", partial: true, imports: [], imported_by: ["src/policy-router.ts"], tests_covering: [] },
    "src/policy-router.test.ts": { symbols: [], parser: "js-ts-regex-v0", partial: true, imports: ["src/policy-router.ts"], imported_by: [], tests_covering: [] },
    "src/mocked.test.ts": { symbols: [], parser: "js-ts-regex-v0", partial: true, imports: ["src/policy-router.ts"], imported_by: [], tests_covering: [] },
    "src/loud.test.ts": { symbols: [], parser: "js-ts-regex-v0", partial: true, imports: ["src/policy-router.ts"], imported_by: [], tests_covering: [] },
  },
  symbols: {}, error_clusters: [],
};

// ------------------------------------------------------- 1. error signals ---
const errLines = [
  `src/policy-router.ts(5,20): error TS2353: Object literal may only specify known properties, and 'name' does not exist in type 'PolicyDefinition'.`,
];
const sig = errorSignals(errLines);
check("errorSignals extracts the property named by TS2353", sig.properties.includes("name"), JSON.stringify(sig.properties));
check("errorSignals extracts the type named by TS2353", sig.types.includes("PolicyDefinition"));
check("errorSignals records the error line per file", (sig.by_file["src/policy-router.ts"] || {}).lines?.includes(5));
check("errorSignals on empty input returns empty, not a guess", errorSignals([]).properties.length === 0);

// ------------------------------------------- 2. E2 shape: dependency shown --
const sem = semanticEvidence(root, idx, ["src/policy-router.ts"], { errorProperties: sig.properties, maxItems: 6 });
const nameItems = sem.items.filter((i) => /`name`/.test(i.detail));
check("E2 SHAPE: evidence about the error-named property survives a tight bound",
  nameItems.length > 0, `items=${sem.items.length}`);
check("E2 SHAPE: the asserting test is named, with a line anchor",
  nameItems.some((i) => /policy-router\.test\.ts:\d+/.test(i.where)), JSON.stringify(nameItems.map((i) => i.where)));
check("E2 SHAPE: error-named items are flagged as such",
  nameItems.every((i) => i.error_named_property === true));

// ----------------------------------------------- 3. chatty neighbour bound --
check("a 40-assertion neighbour does not crowd out the quiet witness",
  new Set(sem.items.map((i) => i.consumer)).size >= 2,
  JSON.stringify(sem.items.map((i) => i.consumer)));
check("mocked modules are surfaced (a mock hides shape changes)",
  sem.items.some((i) => i.rule === "mocked-module") || sem.counts.mocked > 0);

// --------------------------------------------------- 4. bounds are honest ---
const big = Array.from({ length: 500 }, (_, i) => ({ defining: "d", rule: "asserted-property", where: `c${i % 7}.ts:${i}`, consumer: `c${i % 7}.ts`, detail: "x" }));
const sel = selectEvidence(big, { maxItems: 20, maxPerDefining: 20 });
check("selection is bounded", sel.items.length <= 20, String(sel.items.length));
check("selection is deterministic across runs",
  JSON.stringify(sel.items) === JSON.stringify(selectEvidence(big, { maxItems: 20, maxPerDefining: 20 }).items));
check("selection spreads across consumers rather than draining one",
  new Set(sel.items.map((i) => i.consumer)).size >= 5, String(new Set(sel.items.map((i) => i.consumer)).size));
check("withholding is disclosed when evidence is dropped",
  semanticEvidence(root, idx, ["src/policy-router.ts"], { maxItems: 1 }).notes.some((n) => /withheld|carried/.test(n)));

// --------------------------------------- 5. absence is not evidence of none --
const none = semanticEvidence(root, idx, ["src/store.ts"], {});
check("no dependants reports ABSENCE OF EVIDENCE, not 'nothing depends on it'",
  none.items.length > 0 || none.notes.some((n) => /ABSENCE OF EVIDENCE/.test(n)),
  JSON.stringify(none.notes));

// -------------------------------------------- 6. missing parser boundaries --
const noParse = semanticEvidence(root, idx, ["src/does-not-exist.ts"], {});
check("an unreadable defining file is reported, not silently skipped",
  noParse.notes.some((n) => /unreadable/.test(n)), JSON.stringify(noParse.notes));

// ------------------------------------------------- 7. selective compilation --
const good = shouldCompile({ seed_files: 6, candidates: 40, admitted: 30, declined: 10, predicted_bytes: 40000, defining_parsed: 6, defining_total: 6, semantic_items: 12, semantic_error_named: 3 });
check("a well-shaped task routes to compile", good.decision === "compile", good.decision + " " + good.reasons[0]);

const exploded = shouldCompile({ seed_files: 4, candidates: 288, admitted: 193, declined: 95, predicted_bytes: 185000, defining_parsed: 4, defining_total: 4, semantic_items: 30 });
check("an exploded candidate set refuses compilation", exploded.decision === "standard_context", exploded.decision);
check("refusal falls back cleanly to standard context", exploded.fallback === "standard_context");
check("refusal states WHY, in structural terms", exploded.reasons.some((r) => /expansion ratio|predicted capsule/.test(r)));

const blind = shouldCompile({ seed_files: 5, candidates: 20, admitted: 18, declined: 2, predicted_bytes: 30000, defining_parsed: 1, defining_total: 5, semantic_items: 0 });
check("weak parser fidelity yields insufficient_evidence, NOT a refusal",
  blind.decision === "insufficient_evidence", blind.decision);
check("no semantic evidence yields insufficient_evidence", blind.reasons.some((r) => /semantic dependency/.test(r)));

const unmeasured = shouldCompile({ seed_files: 5 });
check("an unmeasured signal is not a passing one", unmeasured.decision === "insufficient_evidence");
check("the decision is deterministic",
  JSON.stringify(shouldCompile({ seed_files: 6, candidates: 40, declined: 10, predicted_bytes: 40000, defining_parsed: 6, defining_total: 6, semantic_items: 12 })) ===
  JSON.stringify(shouldCompile({ seed_files: 6, candidates: 40, declined: 10, predicted_bytes: 40000, defining_parsed: 6, defining_total: 6, semantic_items: 12 })));
check("thresholds carry their structural reason, not a fitted number",
  good.confidence_note.includes("NOT fitted to EXP-0004"));

// -------------------------------------------------- 8. written properties ---
const props = writtenProperties(fs.readFileSync(path.join(root, "src/policy-router.ts"), "utf8"));
check("object-literal keys are extracted as the changeable surface", props.includes("name") && props.includes("domain"), JSON.stringify(props));

fs.rmSync(root, { recursive: true, force: true });

process.stdout.write(results.join("\n") + "\n");
process.stdout.write(`TESTS: ${pass} passed, ${fail} failed, 0 skipped\n`);
process.exit(fail ? 1 : 0);
