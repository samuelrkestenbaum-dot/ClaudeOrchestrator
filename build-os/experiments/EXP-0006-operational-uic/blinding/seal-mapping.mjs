#!/usr/bin/env node
// EXP-0006 — seal the blinded mapping BEFORE any arm executes.
//
// The role machinery is IMPORTED from EXP-0005 rather than reimplemented. That
// experiment is frozen and this file does not touch it; it reuses the code
// because a second copy of a blinding scheme is a second thing that can drift
// from the scheme that was tested. `blinding.test.mjs` over there is the test
// for this behaviour, and it stays the only one.
//
// The integrity property is the ORDER: the mapping is fixed and its digest is
// committed while every acceptance result is still unknown, so it cannot be
// re-chosen once results exist. If this file runs after an arm, the property is
// gone and no amount of care afterwards restores it — which is why the driver
// refuses to launch without the digest present.
//
// The salt arrives by ENVIRONMENT, never argv: argv is world-readable through
// /proc and `ps`, and a salt visible to any process on the box is not sealed.
//
// Usage:
//   EXP0006_SALT=<salt> seal-mapping.mjs --seal-out <path OUTSIDE repo> --digest-out <path in repo>

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { deriveIds, buildView, attemptJoin, ROLE_FORBIDDEN } from "../../EXP-0005-system-efficiency/blinding/roles.mjs";
import { isGovernancePath } from "../../EXP-0005-system-efficiency/blinding/governance-strip.mjs";

const arg = (n, d = null) => { const i = process.argv.indexOf(`--${n}`); return i > 0 && process.argv[i + 1] ? process.argv[i + 1] : d; };

const SALT = process.env.EXP0006_SALT;
if (!SALT || SALT.length < 24) {
  console.error("REFUSED: EXP0006_SALT must be set and at least 24 characters. A short or absent salt is not a seal.");
  process.exit(2);
}
const SEAL_OUT = arg("seal-out"), DIGEST_OUT = arg("digest-out");
if (!SEAL_OUT || !DIGEST_OUT) { console.error("REFUSED: --seal-out and --digest-out are both required."); process.exit(2); }

const HERE = path.dirname(new URL(import.meta.url).pathname);
const REPO_ROOT = path.resolve(path.join(HERE, "..", "..", "..", ".."));
if (path.resolve(SEAL_OUT).startsWith(REPO_ROOT + path.sep)) {
  console.error(`REFUSED: --seal-out is inside the repository (${REPO_ROOT}). A seal committed alongside its digest seals nothing.`);
  process.exit(2);
}

const ARMS = ["native", "gravito"];
const sel = JSON.parse(fs.readFileSync(path.join(HERE, "../results/task-selection.json"), "utf8"));
const TASKS = sel.selected.map((t) => t.task_id);
if (TASKS.length < 10) { console.error(`REFUSED: ${TASKS.length} tasks, below the registered minimum of 10.`); process.exit(2); }

// One global condition mapping, DERIVED not sampled, so the reveal recomputes
// it rather than trusting a stored value.
const parityHex = crypto.createHash("sha256").update(`${SALT}|exp0006-global-condition-parity`).digest("hex");
const flip = parseInt(parityHex.slice(0, 8), 16) % 2 === 1;
const armToLabel = flip ? { native: "Y", gravito: "X" } : { native: "X", gravito: "Y" };

const units = [];
for (const task_id of TASKS) for (const arm of ARMS) {
  const { adj_id, ana_id } = deriveIds(SALT, task_id, arm);
  units.push({ task_id, arm, condition_label: armToLabel[arm], adj_id, ana_id });
}

const checks = [];
const check = (name, ok, detail) => { checks.push({ name, ok, detail }); return ok; };

check("all_task_ids_represented", new Set(units.map((u) => u.task_id)).size === TASKS.length, `${new Set(units.map((u) => u.task_id)).size} of ${TASKS.length}`);
check("one_unit_per_task_per_arm", units.length === TASKS.length * ARMS.length, `${units.length} = ${TASKS.length} tasks x ${ARMS.length} arms`);
check("mapping_is_global_not_per_task", new Set(units.map((u) => `${u.arm}=${u.condition_label}`)).size === ARMS.length, "each arm carries exactly one label across every task");

const adjIds = units.map((u) => u.adj_id), anaIds = units.map((u) => u.ana_id);
check("no_adj_id_collision", new Set(adjIds).size === adjIds.length, `${new Set(adjIds).size} distinct`);
check("no_ana_id_collision", new Set(anaIds).size === anaIds.length, `${new Set(anaIds).size} distinct`);
check("id_domains_disjoint", adjIds.every((a) => !anaIds.includes(a)), "no identifier appears in both domains — this is what makes the views unjoinable");

const rows = units.map((u) => ({
  ...u, objective: "(withheld until execution)", acceptance_criteria: "(frozen per task)",
  product_diff_ref: `diff/${u.adj_id}.patch`, tests_run: 0, tests_passed: 0, verification_evidence: "(pending)",
  acceptance_result: "(pending)", uncached_tokens: 0, total_tokens: 0, total_elapsed_s: 0,
  subagent_invocations: 0, rework_rounds: 0, human_interventions: 0, regressions: 0, api_equivalent_cost_usd: 0,
}));
const adjView = buildView("adjudicator", rows), anaView = buildView("analyst", rows);
const join = attemptJoin(adjView, anaView);
check("adversarial_join_fails", join.condition_identity_recovered === false, join.verdict);

const flat = (v) => JSON.stringify(v);
check("adjudicator_view_free_of_condition", !/"(arm|condition|condition_label)"/.test(flat(adjView)) && !/"(native|gravito)"/.test(flat(adjView)), "no arm or condition field");
check("analyst_view_free_of_condition", !/"(arm|condition|condition_label)"/.test(flat(anaView)) && !/"(native|gravito)"/.test(flat(anaView)), "no arm or condition field");
check("adjudicator_view_free_of_economics", !ROLE_FORBIDDEN.adjudicator.some((f) => adjView.units.some((u) => u[f] !== undefined)), "no economic field");
check("analyst_view_free_of_diffs", !ROLE_FORBIDDEN.analyst.some((f) => anaView.units.some((u) => u[f] !== undefined)), "no diff reference");
check("no_governance_path_in_adjudicated_refs", adjView.units.every((u) => !isGovernancePath(u.product_diff_ref)), "adjudicated diff references are product paths only");

// The check that matters: ids must depend on the SALT, not on (task, arm)
// alone. Were they salt-free, anyone could recompute both domains and join them
// without the seal, and the structure would be decorative.
const probeSalt = crypto.createHash("sha256").update(`${SALT}|probe`).digest("hex");
check("ids_are_salt_dependent", units.every((u) => {
  const alt = deriveIds(probeSalt, u.task_id, u.arm);
  return alt.adj_id !== u.adj_id && alt.ana_id !== u.ana_id;
}), "a different salt yields different ids for the same (task, arm)");

// EXP-0006-specific: the digest must be committed while every acceptance result
// is still unknown. Any run directory already present means it is not.
const runsDir = path.join(HERE, "../results/runs");
const existingRuns = fs.existsSync(runsDir) ? fs.readdirSync(runsDir) : [];
check("sealed_before_any_arm_executed", existingRuns.length === 0,
  existingRuns.length ? `REFUSED: ${existingRuns.length} run director(ies) already exist — the mapping would be chosen with results in hand` : "no measured arm has produced a run directory");

const failed = checks.filter((c) => !c.ok);

const seal = {
  artifact: "exp0006_sealed_mapping",
  experiment: "EXP-0006",
  sealed_at_seed: "2543c873141fa64653a7993d326465d5e0dd1006",
  arms: ARMS,
  global_condition_mapping: armToLabel,
  derivation: "condition label from sha256(salt|exp0006-global-condition-parity); ids from sha256(salt|<role-domain>|<task>|<arm>) — DERIVED, so the reveal recomputes rather than trusts",
  n_tasks: TASKS.length, n_units: units.length, units, verification: checks,
};
const sealJson = JSON.stringify(seal, null, 2);
const digest = crypto.createHash("sha256").update(sealJson).digest("hex");

if (failed.length) {
  console.error("REFUSED — the seal did not verify. Nothing was written.");
  for (const f of failed) console.error(`  x ${f.name}: ${f.detail}`);
  process.exit(1);
}

fs.mkdirSync(path.dirname(SEAL_OUT), { recursive: true });
fs.writeFileSync(SEAL_OUT, sealJson, { mode: 0o600 });
fs.mkdirSync(path.dirname(DIGEST_OUT), { recursive: true });
fs.writeFileSync(DIGEST_OUT, JSON.stringify({
  artifact: "exp0006_mapping_digest",
  experiment: "EXP-0006",
  mapping_sha256: digest,
  n_tasks: TASKS.length, n_units: units.length, arms: ARMS, task_ids: TASKS,
  sealed_location: "OUTSIDE the repository — deliberately not recorded here, because a path is a lead",
  verification: checks.map((c) => ({ name: c.name, ok: c.ok, detail: c.detail })),
  what_this_digest_proves:
    "The mapping existed, in exactly this form, BEFORE any arm executed. It does not reveal the mapping and cannot " +
    "be satisfied by a different one. Re-deriving from the salt at reveal reproduces this digest, or the reveal is invalid.",
  what_it_does_not_prove:
    "Nothing about whether the ROLES stay separate during execution. That is a property of who holds what at run time.",
}, null, 2) + "\n");

console.log(`SEALED — ${TASKS.length} tasks, ${units.length} units, ${checks.length} checks all passing`);
console.log(`  mapping sha256: ${digest}`);
console.log(`  seal written outside the repository, mode 0600; digest written to ${DIGEST_OUT}`);
