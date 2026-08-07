// SEAM 2b — semantic dependency evidence.
//
// WHY THIS EXISTS. EXP-0004 returned `context compilation harmful`, and the
// verdict was decided by one task. On E2 the compiled arm cleared all 13
// TS2353 errors and still lost, because it dropped `name: input.name` from the
// PolicyDefinition handed to `pceUpsertPolicy` and re-attached it only to the
// returned object. A covering test asserted on the behaviour that field drives.
// The worker never saw that dependency.
//
// The v0 capsule was not missing the FILE — it admitted 17 tests for E2. It was
// missing the CLAIM. A path plus a symbol list says "this test exists"; it does
// not say "this test asserts that a policy keeps its name". Admitting more
// files would not have fixed that, and would have made the other defect worse.
//
// So this layer answers a different question from the relevance walk:
//
//     If a fix changes the MEANING or PLACEMENT of a value, who relies on that
//     meaning, and what exactly do they rely on?
//
// HONESTY BOUNDS, binding on every item produced here:
//   - This is STATIC LINKAGE, never executed coverage. An item says a file
//     textually references a symbol or property near an assertion. It does not
//     say the test exercises it, and it must never be rendered as if it did.
//   - Extraction is regex over source text, in the same v0 register as the rest
//     of the compiler. It has no type resolution and no call graph.
//   - Every item carries the RULE that produced it and a file:line anchor, so a
//     reader can check it in one jump.
//   - Output is BOUNDED by construction. Unbounded evidence is how the other
//     EXP-0004 defect happened; this layer must not re-create it.

import fs from "node:fs";
import path from "node:path";

export const SEMANTIC_RULES = [
  { id: "importing-test", text: "a test file whose relative import resolves to a defining file" },
  { id: "mocked-module", text: "a test mocks a module that resolves to a defining file — its real behaviour is replaced, so a shape change is invisible to it" },
  { id: "asserted-symbol", text: "an assertion in an importing test names a defining file's symbol" },
  { id: "asserted-property", text: "an assertion in an importing test names a property that a defining file writes into an object literal" },
  { id: "property-consumer", text: "a non-test importer reads a property that a defining file writes into an object literal" },
];

const ASSERT = /\b(expect|assert|should|toEqual|toBe|toMatchObject|toHaveProperty|toContain)\b/;
const SPEC = /(?:from\s*|import\s*\(\s*|require\s*\(\s*|vi\.(?:do)?[Mm]ock\s*\(\s*|jest\.mock\s*\(\s*)['"]([^'"]+)['"]/g;
const MOCK = /(?:vi\.(?:do)?[Mm]ock|jest\.mock)\s*\(\s*['"]([^'"]+)['"]/g;
// Property keys written into an object literal.
//
// The first cut anchored this to the START of a line, which made every
// single-line literal invisible — `upsert({ name: input.name, domain: d })`
// yielded nothing at all. It passed on this repository only because the
// literals that mattered happened to be multi-line. A key is preceded by `{`,
// by `,`, or by line start; all three are matched, and a leading `?` guards
// against reading a ternary's `:` as a property.
const PROP_KEY = /(^|[{,])\s*([A-Za-z_$][\w$]*)\s*:(?!:)/g;

const stripExt = (p) => p.replace(/\.(tsx?|jsx?|mjs|cjs)$/, "");
const isTest = (p) => /\.(test|spec)\.[jt]sx?$/.test(p);
const oneLine = (s, max = 140) => {
  const f = String(s).replace(/\s+/g, " ").trim();
  return f.length > max ? f.slice(0, max - 1) + "…" : f;
};

function read(root, rel) {
  try { return fs.readFileSync(path.join(root, rel), "utf8"); } catch { return null; }
}

/** Relative specifiers in `body`, resolved against `fromDir`, extension-stripped. */
function resolvedSpecs(body, fromDir, re) {
  const out = [];
  re.lastIndex = 0;
  let m;
  while ((m = re.exec(body)) !== null) {
    const spec = m[1];
    if (!spec.startsWith(".")) continue;
    out.push(stripExt(path.normalize(path.join(fromDir, spec))));
  }
  return out;
}

/**
 * Property keys a defining file writes into object literals. These are the
 * values whose PLACEMENT a fix can silently change — exactly the E2 shape.
 * Bounded to `max` most-frequent keys so a large file cannot flood the capsule.
 */
export function writtenProperties(body, max = 40) {
  const counts = new Map();
  for (const line of body.split("\n")) {
    if (/\?/.test(line) && !/[{,]/.test(line)) continue;   // bare ternary, not a literal
    PROP_KEY.lastIndex = 0;
    let m;
    while ((m = PROP_KEY.exec(line)) !== null) {
      const k = m[2];
      if (k.length < 3) continue;                     // `id:` is too weak a signal
      if (/^(if|for|case|default|return|type|const|let|var|else|do|try|catch|new|await)$/.test(k)) continue;
      counts.set(k, (counts.get(k) || 0) + 1);
    }
  }
  return [...counts.entries()]
    .sort((a, b) => b[1] - a[1] || (a[0] < b[0] ? -1 : 1))
    .slice(0, max)
    .map(([k]) => k);
}

/**
 * Properties and types NAMED BY THE TASK'S OWN ERRORS.
 *
 * This is the cheapest and strongest signal available, and v0 ignored it. E2's
 * error read:
 *
 *   control-tower-router.ts(2268,9): error TS2353: Object literal may only
 *   specify known properties, and 'name' does not exist in type
 *   'PolicyDefinition'.
 *
 * The property the compiler needed to protect was printed in the error text.
 * The worker cleared the error by DELETING `name`, and four tests that assert
 * on `name` never reached the capsule. A fix that removes the named property is
 * the single most likely wrong answer to these diagnostics, so evidence about
 * that property is promoted above everything else.
 */
export function errorSignals(errorLines = []) {
  const byFile = new Map();
  const props = new Set();
  const types = new Set();
  const PATTERNS = [
    /and '([^']+)' does not exist in type '([^']+)'/,          // TS2353
    /Property '([^']+)' does not exist on type '([^']+)'/,     // TS2339
    /Property '([^']+)' is missing in type '([^']+)'/,         // TS2741
    /'([^']+)' does not exist on type '([^']+)'\. Did you mean/, // TS2551
  ];
  for (const raw of errorLines) {
    const loc = /^(.+?)\((\d+),\d+\):/.exec(raw);
    if (loc) {
      const f = loc[1];
      if (!byFile.has(f)) byFile.set(f, { lines: [], properties: new Set() });
      byFile.get(f).lines.push(Number(loc[2]));
    }
    for (const re of PATTERNS) {
      const m = re.exec(raw);
      if (!m) continue;
      props.add(m[1]);
      types.add(m[2]);
      if (loc && byFile.has(loc[1])) byFile.get(loc[1]).properties.add(m[1]);
      break;
    }
  }
  return {
    properties: [...props].sort(),
    types: [...types].sort(),
    by_file: Object.fromEntries([...byFile.entries()].map(([f, v]) =>
      [f, { lines: v.lines.sort((a, b) => a - b), properties: [...v.properties].sort() }])),
  };
}

// Severity order. `mocked-module` ranks highest because it is the one item that
// tells the worker a test CANNOT see its change: the real module is replaced,
// so a shape change there passes silently. `importing-test` ranks lowest — it
// says a relationship exists without saying what depends on what.
const SEVERITY = ["mocked-module", "asserted-symbol", "asserted-property", "property-consumer", "importing-test"];
const sev = (r) => { const i = SEVERITY.indexOf(r); return i < 0 ? SEVERITY.length : i; };

/**
 * Fair, deterministic selection. Round-robins across CONSUMERS within each
 * defining file, taking each consumer's most severe unused item per pass, so a
 * file with forty assertions cannot displace a file with one. Ties break on
 * (rule severity, where) and never on discovery order.
 */
export function selectEvidence(all, { maxItems = 60, maxPerDefining = 12, errorProperties = [] } = {}) {
  // An item about a property the task's OWN ERROR names outranks everything.
  // Deleting that property is the most likely wrong fix, so who depends on it
  // is the one thing the worker must not have to discover for itself.
  const hot = new Set(errorProperties);
  const isHot = (it) => {
    const m = /`([^`]+)`/.exec(it.detail || "");
    return m ? hot.has(m[1]) : false;
  };
  const byDefining = new Map();
  for (const it of all) {
    if (!byDefining.has(it.defining)) byDefining.set(it.defining, new Map());
    const byConsumer = byDefining.get(it.defining);
    if (!byConsumer.has(it.consumer)) byConsumer.set(it.consumer, []);
    byConsumer.get(it.consumer).push(it);
  }

  const chosen = [];
  let perConsumerCap = 0;
  for (const defining of [...byDefining.keys()].sort()) {
    const byConsumer = byDefining.get(defining);
    for (const list of byConsumer.values()) {
      list.sort((a, b) => (isHot(b) - isHot(a)) || sev(a.rule) - sev(b.rule) || (a.where < b.where ? -1 : a.where > b.where ? 1 : 0));
    }
    // Consumers ordered by their BEST item's severity, then by name. A consumer
    // holding a mocked-module fact is heard before one holding only an import.
    const consumers = [...byConsumer.keys()].sort((a, b) => {
      const A = byConsumer.get(a)[0], B = byConsumer.get(b)[0];
      return (isHot(B) - isHot(A)) || sev(A.rule) - sev(B.rule) || (a < b ? -1 : 1);
    });

    const cursor = new Map(consumers.map((c) => [c, 0]));
    let takenHere = 0;
    let progressed = true;
    while (progressed && takenHere < maxPerDefining && chosen.length < maxItems) {
      progressed = false;
      for (const c of consumers) {
        if (takenHere >= maxPerDefining || chosen.length >= maxItems) break;
        const i = cursor.get(c);
        const list = byConsumer.get(c);
        if (i >= list.length) continue;
        chosen.push(list[i]);
        cursor.set(c, i + 1);
        perConsumerCap = Math.max(perConsumerCap, i + 1);
        takenHere++;
        progressed = true;
      }
    }
  }

  chosen.sort((a, b) =>
    (a.defining < b.defining ? -1 : a.defining > b.defining ? 1 : 0) ||
    (isHot(b) - isHot(a)) ||
    sev(a.rule) - sev(b.rule) ||
    (a.where < b.where ? -1 : a.where > b.where ? 1 : 0));
  for (const it of chosen) if (isHot(it)) it.error_named_property = true;
  return { items: chosen, perConsumerCap: Math.max(1, perConsumerCap) };
}

/**
 * Build bounded semantic evidence for a task's defining files.
 *
 * @param root        repository root
 * @param idx         SEAM 1 index
 * @param definingFiles  the task's defining (priority-1) files
 * @param opts        { maxItems, maxPerDefining, candidateFiles }
 * @returns { items, notes, counts, rules_used }
 */
export function semanticEvidence(root, idx, definingFiles, opts = {}) {
  const maxItems = opts.maxItems ?? 60;
  const errorProperties = opts.errorProperties ?? [];
  const maxPerDefining = opts.maxPerDefining ?? 12;
  const items = [];
  const notes = [];
  const counts = { importing_tests: 0, mocked: 0, asserted_symbol: 0, asserted_property: 0, property_consumer: 0 };

  const allFiles = Object.keys(idx.files || {});
  const defSet = new Set(definingFiles.map(stripExt));

  // Property vocabulary per defining file, read once.
  const props = new Map();   // defining -> string[]
  const syms = new Map();    // defining -> Set<string>
  for (const d of definingFiles) {
    const body = read(root, d);
    if (body === null) { notes.push(`${d}: unreadable on disk — no semantic evidence could be gathered from it`); continue; }
    props.set(d, writtenProperties(body));
    syms.set(d, new Set((idx.files[d]?.symbols) || []));
  }

  // Collect UNBOUNDED here, select fairly afterwards. The first cut of this
  // layer capped as it went, and one chatty test file consumed the whole
  // budget for its defining file — so the very witness the E2 defect needed
  // (`fix-preview.test.ts`) was crowded out by a louder neighbour. Capping at
  // collection time makes the bound a function of directory order, which is
  // not a property anyone should be relying on.
  const all = [];
  const add = (defining, rule, where, detail) => {
    all.push({ defining, rule, where, consumer: String(where).split(":")[0], detail: oneLine(detail) });
    return true;
  };

  for (const consumer of allFiles) {
    if (defSet.has(stripExt(consumer))) continue;
    const body = read(root, consumer);
    if (body === null) continue;
    const dir = path.dirname(consumer);

    const imported = new Set(resolvedSpecs(body, dir, SPEC));
    const mocked = new Set(resolvedSpecs(body, dir, MOCK));
    const hits = definingFiles.filter((d) => imported.has(stripExt(d)));
    if (!hits.length) continue;

    const lines = body.split("\n");
    const testFile = isTest(consumer);

    for (const d of hits) {
      if (testFile) {
        counts.importing_tests++;
        add(d, "importing-test", consumer, `imports it; static linkage only, NOT executed coverage`);
      }
      if (mocked.has(stripExt(d))) {
        counts.mocked++;
        add(d, "mocked-module", consumer,
          `MOCKS this module — its real behaviour is replaced here, so a shape change in it is invisible to this test`);
      }

      const symbolSet = syms.get(d) || new Set();
      const propList = props.get(d) || [];
      const seenSym = new Set();
      const seenProp = new Set();

      for (let n = 0; n < lines.length; n++) {
        const line = lines[n];
        const assertive = ASSERT.test(line);
        if (testFile && assertive) {
          for (const s of symbolSet) {
            if (seenSym.has(s) || s.length < 4) continue;
            if (new RegExp(`\\b${s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}\\b`).test(line)) {
              seenSym.add(s);
              counts.asserted_symbol++;
              add(d, "asserted-symbol", `${consumer}:${n + 1}`, `asserts on \`${s}\` — ${line}`);
            }
          }
        }
        for (const p of propList) {
          if (seenProp.has(p) || p.length < 4) continue;
          if (!new RegExp(`\\b${p}\\b`).test(line)) continue;
          if (testFile && assertive) {
            seenProp.add(p);
            counts.asserted_property++;
            add(d, "asserted-property", `${consumer}:${n + 1}`,
              `asserts on property \`${p}\`, which ${path.basename(d)} writes into an object literal — ${line}`);
          } else if (!testFile) {
            seenProp.add(p);
            counts.property_consumer++;
            add(d, "property-consumer", `${consumer}:${n + 1}`,
              `reads property \`${p}\` that ${path.basename(d)} writes — ${line}`);
          }
        }
      }
    }
  }

  const selected = selectEvidence(all, { maxItems, maxPerDefining, errorProperties });
  items.push(...selected.items);
  const dropped = all.length - items.length;
  if (dropped > 0) {
    notes.push(`semantic walk: ${all.length} evidence items found, ${items.length} carried — ` +
      `selection is fair across CONSUMERS (at most ${selected.perConsumerCap} per consumer per defining file) ` +
      `so one chatty test cannot crowd out a quieter witness; ${dropped} withheld and requestable`);
  }

  const hotSet = new Set(errorProperties);
  const hotAll = all.filter((i) => { const m = /`([^`]+)`/.exec(i.detail || ""); return m && hotSet.has(m[1]); });
  const hotKept = items.filter((i) => i.error_named_property).length;
  if (hotAll.length && hotKept < hotAll.length) {
    notes.push(`semantic walk: ${hotAll.length} item(s) concern a property named by this task's own errors ` +
      `(${errorProperties.join(", ")}); ${hotKept} carried. Those properties are the likeliest thing a fix ` +
      `deletes, so treat the carried ones as a floor, not a census`);
  }

  if (!items.length) {
    notes.push("semantic walk: no importer referenced a defining file's symbols or written properties — " +
      "that is an ABSENCE OF EVIDENCE, not evidence that nothing depends on this code");
  }
  return { items, notes, counts, rules_used: SEMANTIC_RULES, bounds: { maxItems, maxPerDefining } };
}
