// Every check here is MUTATION-TESTED: for each refusal, a case that fires it
// AND a neighbouring case that does not. A check that has never been shown to
// fail tells you it ran, not that it guards -- which is the exact defect this
// session found five times in other checks.

import assert from "node:assert";
import { assess } from "./convergence.mjs";

let n = 0;
const t = (name, fn) => { fn(); n++; console.log(`  ok  ${name}`); };

const PROGRAM = {
  open_decisions: [
    { id: "D1", decision: "redesign or target normal-runtime overhead", status: "open",
      measurement_attempts: 3, attempt_log: ["EXP-0006 — contaminated by the administered queue", "EXP-0007 corrected — still capability-starved"] },
    { id: "D2", decision: "a fresh question", status: "open", measurement_attempts: 0, attempt_log: [] },
    { id: "D9", decision: "already answered", status: "closed", measurement_attempts: 1, attempt_log: ["done"] },
  ],
  stop_conditions: [{ id: "S1", applies_to: "D1", rule: "one clean baseline then stop", satisfied: false }],
};
const withStopSatisfied = { ...PROGRAM, stop_conditions: [{ ...PROGRAM.stop_conditions[0], satisfied: true }] };

const base = {
  work: "runnable-verification re-baseline", decision_id: "D1", hypothesis_id: "H-econ",
  differs_from_prior: "verification is executable for the first time",
  possible_results: [
    { result: "gap contracts materially", next_action: "target normal-runtime overhead" },
    { result: "gap stays >= 2x", next_action: "redesign the interaction model" },
  ],
};

console.log("convergence gate");

t("PROCEEDs when a result selects between two different next actions", () => {
  const r = assess(base, PROGRAM);
  assert.equal(r.verdict, "PROCEED", JSON.stringify(r));
  assert.equal(r.derived_gain, "high");
});

// R2 — the load-bearing rule. Same proposal, only the next_actions collapsed.
t("DEFERs when every possible result leads to the same next action", () => {
  const r = assess({ ...base, possible_results: [
    { result: "gap contracts", next_action: "redesign the interaction model" },
    { result: "gap stays", next_action: "redesign the interaction model" },
  ] }, PROGRAM);
  assert.equal(r.verdict, "DEFER");
  assert.equal(r.code, "no_result_changes_the_decision");
});

// R1 — the stop condition, and its mutation: identical proposal, satisfied flag flipped.
t("REFUSEs once the stop condition is satisfied", () => {
  const r = assess(base, withStopSatisfied);
  assert.equal(r.verdict, "REFUSE");
  assert.equal(r.code, "stop_condition_satisfied");
});
t("...and the SAME proposal PROCEEDs while it is not satisfied", () => {
  assert.equal(assess(base, PROGRAM).verdict, "PROCEED");
});

// R3
t("REFUSEs work that names no open decision", () => {
  const r = assess({ ...base, decision_id: "D-nonexistent" }, PROGRAM);
  assert.equal(r.code, "undeclared_decision");
});
t("REFUSEs work aimed at a closed decision", () => {
  const r = assess({ ...base, decision_id: "D9" }, PROGRAM);
  assert.equal(r.code, "decision_already_closed");
});

// R5
t("REFUSEs when fewer than two outcomes can be stated", () => {
  const r = assess({ ...base, possible_results: [{ result: "it works", next_action: "ship" }] }, PROGRAM);
  assert.equal(r.code, "no_distinguishable_outcomes");
});

// R4 — repeat attempts. Three cases: missing difference, recycled difference, novel difference.
t("REFUSEs a repeat attempt that states no difference", () => {
  const r = assess({ ...base, differs_from_prior: "" }, PROGRAM);
  assert.equal(r.code, "repeat_attempt_without_stated_difference");
});
t("REFUSEs a repeat attempt whose 'difference' is already in the attempt log", () => {
  const r = assess({ ...base, differs_from_prior: "contaminated by the administered queue" }, PROGRAM);
  assert.equal(r.code, "repeat_attempt_difference_already_tried");
});
t("...but a FIRST attempt needs no stated difference", () => {
  const r = assess({ ...base, decision_id: "D2", differs_from_prior: "" }, PROGRAM);
  assert.equal(r.verdict, "PROCEED");
});

// Derived gain is derived, not asserted: an inflated self-claim changes nothing.
t("ignores any self-asserted information gain", () => {
  const r = assess({ ...base, expected_information_gain: "enormous",
    possible_results: [{ result: "a", next_action: "x" }, { result: "b", next_action: "x" }] }, PROGRAM);
  assert.equal(r.verdict, "DEFER");
});

console.log(`\n${n} assertions passed`);
