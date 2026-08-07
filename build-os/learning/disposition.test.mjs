// Post-Outcome Disposition v0 — fixtures. All synthetic except the last block,
// which reads the FROZEN EXP-0004 artifacts and is the point of the exercise:
// would the mechanism have produced the corrective actions from the evidence
// alone, without being told the answer?
import { dispose, RULES, CLASSES, DISPOSITIONS } from "./disposition.mjs";
import exp0004 from "./adapters/exp0004.mjs";

let pass = 0, fail = 0; const out = [];
const check = (n, c, d = "") => { if (c) { pass++; out.push(`  ok   ${n}`); } else { fail++; out.push(`  FAIL ${n}${d ? " — " + d : ""}`); } };

// --- a clean outcome produces no corrective findings ------------------------
const clean = dispose({
  experiment: "SYNTH-clean", per_task: [{ task_id: "T1", delta: 30 }, { task_id: "T2", delta: 28 }, { task_id: "T3", delta: 31 }],
  rejected: [], admitted: 6, attempted: 6, gates_met: 2,
});
check("a clean outcome generates no findings", clean.findings_generated === 0, JSON.stringify(clean.findings.map(f => f.rule)));

// --- rejection with a regression is a product defect, not economics ---------
const reg = dispose({ experiment: "SYNTH-reg", rejected: [{ task_id: "T2", condition: "treated", regressions: 1 }], admitted: 4, attempted: 4, per_task: [{ task_id: "T1", delta: 5 }], gates_met: 1 });
const rf = reg.findings.find((f) => f.rule === "acceptance-shortfall-with-regression");
check("a rejection carrying a regression fires the product-defect rule", !!rf);
check("it is classed product_defect, not optimization", rf?.class === "product_defect");
check("it is severity high", rf?.severity === "high");
check("it proposes a bounded change, not an architectural one", rf?.authority === "bounded_internal_product_change");
check("it demands a regression fixture, not a re-run of the frozen task",
  /fixture reproducing this failure SHAPE/.test(rf?.revalidation || ""));

// --- a sign flip queues a policy question; it does not execute one ----------
const flip = dispose({ experiment: "SYNTH-flip", per_task: [{ task_id: "A", delta: 60 }, { task_id: "B", delta: -200 }, { task_id: "C", delta: -20 }], rejected: [], admitted: 6, attempted: 6, gates_met: 1 });
const ff = flip.findings.find((f) => f.rule === "sign-flip-across-tasks");
check("a sign flip across tasks fires the routing rule", !!ff);
check("a policy question is QUEUED, never executed", ff?.disposition === "queue");
check("a policy question needs architectural authority", ff?.authority === "architectural_change");
check("a uniform-sign set does NOT fire the routing rule",
  !dispose({ experiment: "S", per_task: [{ task_id: "A", delta: 60 }, { task_id: "B", delta: 40 }, { task_id: "C", delta: 55 }], rejected: [], admitted: 6, attempted: 6, gates_met: 1 })
    .findings.some((f) => f.rule === "sign-flip-across-tasks"));

// --- harness losses are a measurement defect, not a thesis result ----------
const harness = dispose({ experiment: "SYNTH-h", admitted: 10, attempted: 14, per_task: [{ task_id: "A", delta: 5 }], rejected: [], gates_met: 1, void_reasons: ["x"] });
const hf = harness.findings.find((f) => f.rule === "fixture-reliability-shortfall");
check("a low admitted/attempted ratio is a measurement_defect", hf?.class === "measurement_defect");
check("a full-yield harness does not fire it",
  !dispose({ experiment: "S", admitted: 10, attempted: 10, per_task: [{ task_id: "A", delta: 5 }], rejected: [], gates_met: 1 })
    .findings.some((f) => f.rule === "fixture-reliability-shortfall"));

// --- schema discipline ------------------------------------------------------
const all = [...reg.findings, ...flip.findings, ...harness.findings];
check("every finding carries a registered class", all.every((f) => CLASSES.includes(f.class)));
check("every finding carries a registered disposition", all.every((f) => DISPOSITIONS.includes(f.disposition)));
check("every finding names a component", all.every((f) => typeof f.component === "string" && f.component.length > 0));
check("every finding cites evidence", all.every((f) => Array.isArray(f.evidence) && f.evidence.length > 0));
check("no rule names a specific experiment, task or component",
  !RULES.some((r) => /EXP-\d|E[1-5]\b|ContextCompiler|compiled_context/.test(r.when.toString() + r.build.toString())));
check("output is deterministic", JSON.stringify(dispose({ experiment: "D", per_task: [{ task_id: "A", delta: 5 }], rejected: [], admitted: 4, attempted: 5, gates_met: 0 })) ===
  JSON.stringify(dispose({ experiment: "D", per_task: [{ task_id: "A", delta: 5 }], rejected: [], admitted: 4, attempted: 5, gates_met: 0 })));
check("execute is scoped to bounded internal change only",
  all.filter((f) => f.disposition === "execute").every((f) => f.authority === "bounded_internal_product_change" || f.authority === "none"));

// --- THE HISTORICAL FIXTURE: frozen EXP-0004 evidence, answer withheld ------
const real = dispose(exp0004);
const rules = real.findings.map((f) => f.rule);
check("HISTORICAL: derives the semantic/correctness defect from frozen evidence",
  rules.includes("acceptance-shortfall-with-regression"), rules.join(","));
check("HISTORICAL: derives the context-packaging defect from frozen evidence",
  rules.includes("starting-context-dominates-and-loses"), rules.join(","));
check("HISTORICAL: derives that universal application is unsupported",
  rules.includes("sign-flip-across-tasks"), rules.join(","));
check("HISTORICAL: the correctness defect outranks the economics one",
  real.findings.findIndex((f) => f.rule === "acceptance-shortfall-with-regression") <
  real.findings.findIndex((f) => f.rule === "sign-flip-across-tasks"));
check("HISTORICAL: the routing change is queued, not self-executed",
  real.findings.find((f) => f.rule === "sign-flip-across-tasks")?.disposition === "queue");
check("HISTORICAL: the generality limitation is stated in the artifact",
  /has NOT been shown to generalise/.test(real.generality_note));

process.stdout.write(out.join("\n") + "\n");
process.stdout.write(`TESTS: ${pass} passed, ${fail} failed, 0 skipped\n`);
process.exit(fail ? 1 : 0);
