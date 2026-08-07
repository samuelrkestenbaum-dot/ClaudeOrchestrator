// Bounded internal mutation authority — fixtures.
// Demonstrates the closed loop on synthetic defect / optimization / hypothesis
// findings, and proves the authority boundary refuses what it must.
import { createPacket, authorityCheck, closePacket, traceBackward, unfinishedLearning,
         AUTO_EXECUTABLE, NEVER_AUTOMATIC } from "./corrective-packet.mjs";
import { dispose } from "./disposition.mjs";
import exp0004 from "./adapters/exp0004.mjs";

let pass = 0, fail = 0; const out = [];
const check = (n, c, d = "") => { if (c) { pass++; out.push(`  ok   ${n}`); } else { fail++; out.push(`  FAIL ${n}${d ? " — " + d : ""}`); } };

const defect = { finding_id: "F-defect", class: "product_defect", disposition: "execute",
  authority: "bounded_internal_product_change", component: "x.parser", confidence: "high",
  evidence: ["single-line literals yielded nothing"], proposed_change: "match keys after { and ,",
  revalidation: "fixture reproducing the shape" };
const optim = { ...defect, finding_id: "F-optim", class: "optimization_opportunity", component: "x.disclosure" };
const hypo  = { finding_id: "F-hypo", class: "unsupported_hypothesis", disposition: "queue",
  authority: "architectural_change", component: "x.routing", confidence: "medium",
  evidence: ["sign flips"], proposed_change: "route per task", revalidation: "decision fixtures" };
const observed = { finding_id: "F-obs", class: "unsupported_hypothesis", disposition: "observe",
  authority: "none", component: "exp.hypothesis", confidence: "high", evidence: ["no gate met"],
  proposed_change: "none", revalidation: "not applicable" };

// --- 1. DEFECT: the loop closes ---------------------------------------------
const p1 = createPacket(defect, { change_kind: "parser_extractor_defect", mutation_boundary: ["build-os/compiler/compile/semantic.mjs"] });
check("a defect finding opens an EXECUTABLE packet", p1.state === "executable" && p1.may_execute === true, JSON.stringify(p1.refusals));
check("the packet carries every required field",
  ["finding_id","finding_class","component","evidence_refs","confidence","proposed_change","mutation_boundary","authority_class","rollback","verification","completion_criteria","prohibited_adjacent","outcome_record"].every((k) => p1[k] !== undefined && p1[k] !== null));
const c1 = closePacket(p1, { fixture_passed: true, existing_tests_passed: true, mutated_paths: ["build-os/compiler/compile/semantic.mjs"], outcome_recorded: true });
check("verification passing CLOSES the packet", c1.state === "closed");
check("closure states the finding is resolved", /resolved/.test(c1.closure_note));

// --- 2. verification failure is failed learning, not success ----------------
const c2 = closePacket(p1, { fixture_passed: false, existing_tests_passed: true, mutated_paths: ["build-os/compiler/compile/semantic.mjs"], outcome_recorded: true });
check("a failed fixture yields unresolved_failed, NOT closed", c2.state === "unresolved_failed");
check("failed verification is named as failed learning", /failed learning, not completed/.test(c2.closure_note));
const c3 = closePacket(p1, { fixture_passed: true, existing_tests_passed: true, mutated_paths: ["build-os/compiler/compile/semantic.mjs", "server/secret.ts"], outcome_recorded: true });
check("a mutation escaping its boundary fails closure", c3.state === "unresolved_failed" && c3.verification_failures.some((f) => /escaped its boundary/.test(f)));
check("writing no outcome record fails closure",
  closePacket(p1, { fixture_passed: true, existing_tests_passed: true, mutated_paths: ["build-os/compiler/compile/semantic.mjs"] }).state === "unresolved_failed");

// --- 3. OPTIMIZATION: also executable, same gate ----------------------------
const p2 = createPacket(optim, { change_kind: "prompt_disclosure_to_artifact", mutation_boundary: ["build-os/compiler/compile/"] });
check("an optimization finding opens an executable packet", p2.may_execute === true);

// --- 4. HYPOTHESIS: queued, never executed ----------------------------------
const p3 = createPacket(hypo, { change_kind: "broad_architecture", mutation_boundary: ["build-os/compiler/"] });
check("a hypothesis finding is QUEUED, not executable", p3.state === "queued" && p3.may_execute === false);
check("the refusal names the hypothesis reason",
  p3.authority_reasons.some((r) => /HYPOTHESIS, not a defect/.test(r)), JSON.stringify(p3.authority_reasons));
check("an observe finding cannot execute either",
  createPacket(observed, { change_kind: "regression_fixture", mutation_boundary: ["tests/"] }).may_execute === false);
check("queue is never silently upgraded to execute",
  authorityCheck({ ...hypo, disposition: "queue" }, "regression_fixture").may_execute === false);

// --- 5. the authority boundary ----------------------------------------------
for (const k of NEVER_AUTOMATIC) {
  check(`never-automatic change kind refused: ${k}`,
    authorityCheck({ ...defect }, k).may_execute === false);
}
check("every auto-executable kind passes with a defect finding",
  AUTO_EXECUTABLE.every((k) => authorityCheck({ ...defect }, k).may_execute === true));
check("a wider authority class is refused even for a defect",
  authorityCheck({ ...defect, authority: "architectural_change" }, "parser_extractor_defect").may_execute === false);
check("an unevidenced finding is refused",
  authorityCheck({ ...defect, evidence: [] }, "parser_extractor_defect").may_execute === false);

// --- 6. frozen evidence is immutable input ----------------------------------
const pf = createPacket(defect, { change_kind: "parser_extractor_defect",
  mutation_boundary: ["build-os/experiments/EXP-0004-context-compiler/results/"] });
check("a packet may NOT declare frozen evidence inside its boundary",
  pf.may_execute === false && pf.refusals.some((r) => /FROZEN EVIDENCE/.test(r)), JSON.stringify(pf.refusals));
check("touching frozen evidence at closure fails verification",
  closePacket(p1, { fixture_passed: true, existing_tests_passed: true, outcome_recorded: true,
    mutated_paths: ["build-os/experiments/EXP-0004-context-compiler/RESULT.md"] }).verification_failures.some((f) => /FROZEN EVIDENCE/.test(f)));
check("an unbounded packet is refused",
  createPacket(defect, { change_kind: "parser_extractor_defect", mutation_boundary: [] }).may_execute === false);

// --- 7. traceability --------------------------------------------------------
const tr = traceBackward(c1, defect, "EXP-0004");
check("backward trace reaches evidence deterministically",
  tr.chain.map((s) => s.step).join(">") === "mutation>corrective_packet>finding>outcome>evidence" && tr.deterministic === true);

// --- 8. unfinished learning -------------------------------------------------
const ul = unfinishedLearning([defect, optim, hypo, observed], [c1, { ...p2, state: "unresolved_failed", verification_failures: ["x"] }]);
check("a closed packet leaves no unfinished execute-class finding",
  !ul.execute_without_completed_action.some((f) => f.finding_id === "F-defect"), JSON.stringify(ul.execute_without_completed_action));
check("an execute finding whose packet failed IS unfinished",
  ul.execute_without_completed_action.some((f) => f.finding_id === "F-optim"));
check("failed packets are listed", ul.packets_failed_verification.length === 1);
check("queued hypotheses are listed with what they need",
  ul.queued_hypotheses_awaiting_evidence.length === 1 && !!ul.queued_hypotheses_awaiting_evidence[0].needs);
check("observed-only findings are tracked separately", ul.observed_only.includes("F-obs"));
check("an empty result is not claimed to mean 'none exists'", /NOT that none exists/.test(ul.note));

// --- 9. end-to-end on the real frozen EXP-0004 findings ---------------------
const real = dispose(exp0004);
const kinds = { "acceptance-shortfall-with-regression": "bounded_relevance_rule",
  "starting-context-dominates-and-loses": "prompt_disclosure_to_artifact",
  "fixture-reliability-shortfall": "harness_defect",
  "sign-flip-across-tasks": "broad_architecture",
  "no-gate-met-either-direction": "regression_fixture" };
const realPackets = real.findings.map((f) => createPacket(f, { change_kind: kinds[f.rule], mutation_boundary: ["build-os/compiler/compile/"] }));
const execCount = realPackets.filter((p) => p.may_execute).length;
check("EXP-0004 findings yield exactly 3 executable packets", execCount === 3, String(execCount));
check("the routing hypothesis is NOT among them",
  realPackets.find((p) => p.finding_id.endsWith("sign-flip-across-tasks"))?.may_execute === false);
check("the observe finding is NOT among them",
  realPackets.find((p) => p.finding_id.endsWith("no-gate-met-either-direction"))?.may_execute === false);

process.stdout.write(out.join("\n") + "\n");
process.stdout.write(`TESTS: ${pass} passed, ${fail} failed, 0 skipped\n`);
process.exit(fail ? 1 : 0);
