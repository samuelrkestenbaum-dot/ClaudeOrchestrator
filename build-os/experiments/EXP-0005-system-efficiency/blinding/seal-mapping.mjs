#!/usr/bin/env node
// Item 7 — seal the EXP-0005 blinded mapping.
//
// ONE global mapping, sealed OUTSIDE the repository, with only its digest
// committed. Committing the digest before any arm runs is the integrity
// property: the mapping is fixed in advance and cannot be re-chosen once
// results exist.
//
// THE MAPPING IS DERIVED, NOT SAMPLED — carried over from EXP-0004. A sampled
// mapping has no witness: nobody can later check that the recorded assignment
// is the one that was actually drawn. A derived assignment is reproducible from
// (salt, arm names) alone, so the reveal step recomputes it rather than trusting
// a stored value.
//
// Usage:
//   EXP0005_SALT=<salt> seal-mapping.mjs --selection <SELECTION.json> --seal-out <path outside repo> --digest-out <path in repo>
//
// The salt arrives by ENVIRONMENT, never argv: argv is world-readable through
// /proc and `ps`, and a salt visible to any process on the box is not sealed.

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { deriveIds, buildView, attemptJoin, ROLE_FORBIDDEN } from "./roles.mjs";
import { isGovernancePath } from "./governance-strip.mjs";

const arg = (n, d = null) => { const i = process.argv.indexOf(`--${n}`); return i > 0 && process.argv[i + 1] ? process.argv[i + 1] : d; };

const SALT = process.env.EXP0005_SALT;
if (!SALT || SALT.length < 24) {
  console.error("REFUSED: EXP0005_SALT must be set and at least 24 characters. A short or absent salt is not a seal.");
  process.exit(2);
}
const SELECTION = arg("selection");
const SEAL_OUT = arg("seal-out");
const DIGEST_OUT = arg("digest-out");
if (!SELECTION || !SEAL_OUT || !DIGEST_OUT) {
  console.error("REFUSED: --selection, --seal-out and --digest-out are all required.");
  process.exit(2);
}

// The sealed mapping must not land inside the repository, whatever path is
// passed. A seal committed alongside its digest seals nothing.
const REPO_ROOT = path.resolve(path.join(path.dirname(new URL(import.meta.url).pathname), "..", "..", "..", ".."));
if (path.resolve(SEAL_OUT).startsWith(REPO_ROOT + path.sep)) {
  console.error(`REFUSED: --seal-out is inside the repository (${REPO_ROOT}). Only the digest may be committed.`);
  process.exit(2);
}

const ARMS = ["native_claude", "whole_gravito"];

const sel = JSON.parse(fs.readFileSync(SELECTION, "utf8"));
const TASKS = sel.selected.map((t) => t.task_id);
if (TASKS.length < 10) {
  console.error(`REFUSED: ${TASKS.length} tasks, below the registered minimum of 10.`);
  process.exit(2);
}

// --- the ONE global condition mapping, derived ------------------------------
// A single bit decides which arm is X. Derived from the salt over a fixed
// domain string, so it is reproducible at reveal and unguessable before it.
const parityHex = crypto.createHash("sha256").update(`${SALT}|exp0005-global-condition-parity`).digest("hex");
const flip = parseInt(parityHex.slice(0, 8), 16) % 2 === 1;
const armToLabel = flip ? { native_claude: "Y", whole_gravito: "X" } : { native_claude: "X", whole_gravito: "Y" };

// --- per-unit opaque identities ---------------------------------------------
const units = [];
for (const task_id of TASKS) {
  for (const arm of ARMS) {
    const { adj_id, ana_id } = deriveIds(SALT, task_id, arm);
    units.push({ task_id, arm, condition_label: armToLabel[arm], adj_id, ana_id });
  }
}

// --- verification, before anything is written -------------------------------
const checks = [];
const check = (name, ok, detail) => { checks.push({ name, ok, detail }); return ok; };

check("all_task_ids_represented", new Set(units.map((u) => u.task_id)).size === TASKS.length,
  `${new Set(units.map((u) => u.task_id)).size} of ${TASKS.length}`);
check("one_unit_per_task_per_arm", units.length === TASKS.length * ARMS.length,
  `${units.length} units = ${TASKS.length} tasks x ${ARMS.length} arms`);
check("mapping_is_global_not_per_task", new Set(units.map((u) => `${u.arm}=${u.condition_label}`)).size === ARMS.length,
  "each arm carries exactly one label across every task");

const adjIds = units.map((u) => u.adj_id), anaIds = units.map((u) => u.ana_id);
check("no_adj_id_collision", new Set(adjIds).size === adjIds.length, `${new Set(adjIds).size} distinct`);
check("no_ana_id_collision", new Set(anaIds).size === anaIds.length, `${new Set(anaIds).size} distinct`);
check("id_domains_disjoint", adjIds.every((a) => !anaIds.includes(a)),
  "no identifier appears in both domains — this is what makes the views unjoinable");

// The adversarial join, run on views built from THIS mapping.
const rows = units.map((u) => ({
  ...u, objective: "(withheld until execution)", acceptance_criteria: "(frozen per task)",
  product_diff_ref: `diff/${u.adj_id}.patch`, tests_run: 0, tests_passed: 0, verification_evidence: "(pending)",
  acceptance_result: "(pending)", uncached_tokens: 0, total_tokens: 0, total_elapsed_s: 0,
  subagent_invocations: 0, rework_rounds: 0, human_interventions: 0, regressions: 0, api_equivalent_cost_usd: 0,
}));
const adjView = buildView("adjudicator", rows);
const anaView = buildView("analyst", rows);
const join = attemptJoin(adjView, anaView);
check("adversarial_join_fails", join.condition_identity_recovered === false, join.verdict);

// Neither blinded view may carry condition identity in any form.
const flat = (v) => JSON.stringify(v);
check("adjudicator_view_free_of_condition", !/"(arm|condition|condition_label)"/.test(flat(adjView)) && !/native_claude|whole_gravito/.test(flat(adjView)), "no arm or condition field");
check("analyst_view_free_of_condition", !/"(arm|condition|condition_label)"/.test(flat(anaView)) && !/native_claude|whole_gravito/.test(flat(anaView)), "no arm or condition field");
check("adjudicator_view_free_of_economics", !ROLE_FORBIDDEN.adjudicator.some((f) => adjView.units.some((u) => u[f] !== undefined)), "no economic field");
check("analyst_view_free_of_diffs", !ROLE_FORBIDDEN.analyst.some((f) => anaView.units.some((u) => u[f] !== undefined)), "no diff reference");

// Governance paths must not be able to carry identity into the adjudicated
// artifact: every diff reference the adjudicator sees is keyed by adj_id and
// must not itself be a governance path.
check("no_governance_path_in_adjudicated_refs", adjView.units.every((u) => !isGovernancePath(u.product_diff_ref)),
  "adjudicated diff references are product paths only");
// The identifiers must depend on the SALT, not on (task, arm) alone. This is
// the check that matters: if ids were a salt-free function of task and arm,
// anyone could recompute both domains for every unit and join them without the
// seal, and the whole structure would be decorative.
//
// (An earlier version of this check asserted that an id does not literally
// contain the arm name. That could never fail — adj_id is `adj-` plus 16 hex
// characters — so it was a vacuous check being counted as a passing one. It is
// replaced rather than kept alongside.)
const probeSalt = crypto.createHash("sha256").update(`${SALT}|probe`).digest("hex");
check("ids_are_salt_dependent",
  units.every((u) => {
    const alt = deriveIds(probeSalt, u.task_id, u.arm);
    return alt.adj_id !== u.adj_id && alt.ana_id !== u.ana_id;
  }),
  "a different salt yields different ids for the same (task, arm), so ids cannot be recomputed without the seal");

const failed = checks.filter((c) => !c.ok);

// --- the seal ----------------------------------------------------------------
const seal = {
  artifact: "exp0005_sealed_mapping",
  experiment: "EXP-0005",
  sealed_at_seed: "2543c873141fa64653a7993d326465d5e0dd1006",
  arms: ARMS,
  global_condition_mapping: armToLabel,
  derivation: "condition label from sha256(salt|exp0005-global-condition-parity); ids from sha256(salt|<role-domain>|<task>|<arm>) — DERIVED, not sampled, so the reveal recomputes rather than trusts",
  n_tasks: TASKS.length,
  n_units: units.length,
  units,
  verification: checks,
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

fs.writeFileSync(DIGEST_OUT, JSON.stringify({
  artifact: "exp0005_mapping_digest",
  experiment: "EXP-0005",
  mapping_sha256: digest,
  n_tasks: TASKS.length,
  n_units: units.length,
  arms: ARMS,
  task_ids: TASKS,
  sealed_location: "OUTSIDE the repository — deliberately not recorded here, because a path is a lead",
  verification: checks.map((c) => ({ name: c.name, ok: c.ok, detail: c.detail })),
  what_this_digest_proves:
    "The mapping existed, in exactly this form, BEFORE any arm executed. It does not reveal the mapping, and it " +
    "cannot be satisfied by a different one. Re-deriving from the salt at reveal reproduces this digest or the " +
    "reveal is invalid.",
  what_it_does_not_prove:
    "It says nothing about whether the ROLES stay separate during execution. That is a property of who holds what " +
    "at run time, not of this file.",
}, null, 2) + "\n");

console.log(`SEALED — ${TASKS.length} tasks, ${units.length} units, ${checks.length} checks all passing`);
console.log(`  mapping sha256: ${digest}`);
console.log(`  seal written outside the repository, mode 0600`);
console.log(`  digest written to ${DIGEST_OUT}`);
