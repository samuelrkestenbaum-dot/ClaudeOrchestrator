#!/usr/bin/env node
// The self-audit CLI: "what must be true for me to work, and which of those
// truths have I actually demonstrated?"
//
// Exit 1 on a VIOLATED load-bearing assumption. Untested ones are reported as
// risk, not failure — an untested claim is unknown, not wrong, and conflating
// the two is how an unknown gets quietly recorded as a zero.
import { coverage } from "./registry.mjs";
const gatePath = process.argv[2] || ".claude/hooks/routing-gate.sh";
const c = coverage({ gatePath });
console.log(`ASSUMPTION COVERAGE — ${c.total} claims  ${JSON.stringify(c.counts)}\n`);
for (const r of c.rows) {
  const mark = r.status === "violated" ? "VIOLATED" : r.status === "untested" ? "UNTESTED" : r.status === "partially_validated" ? "partial " : "ok      ";
  console.log(`${mark} [${r.kind}] ${r.id}`);
  console.log(`         ${r.claim}`);
  if (r.derived_paths) console.log(`         derived: ${r.derived_paths.join(" | ")}`);
  if (r.validated_in?.length) console.log(`         validated in: ${r.validated_in.join(", ")}`);
  if (r.untested_in?.length) console.log(`         UNTESTED in: ${r.untested_in.join(", ")}`);
  for (const v of r.violations || []) console.log(`         !! ${v}`);
}
if (c.untested_load_bearing.length) {
  console.log(`\nUNTESTED LOAD-BEARING ASSUMPTIONS — ${c.untested_load_bearing.length}. These are risk, not failure:`);
  for (const u of c.untested_load_bearing) console.log(`  * ${u.id}: untested in ${u.untested_in.join(", ")}`);
}
if (c.violated_load_bearing.length) { console.log("\nVIOLATED — a load-bearing assumption does not hold."); process.exit(1); }
