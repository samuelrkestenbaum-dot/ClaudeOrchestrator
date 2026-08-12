#!/usr/bin/env node
// Zone 4 — the smallest correct DETERMINISTIC planner. Class-B only.
//
// CONTRACT (audit-frozen): the planner receives ONLY admissible candidates
// (R_t+ from the reachability construction, same invocation), validates
// identity and integrity, and produces a content-addressed plan receipt
// with a deterministic reason trace. It cannot admit, resurrect, or widen:
// a candidate outside R_t+ is refused, whatever presentation score it
// carries. Authority ordering is preserved — admission precedes planning,
// and Class-A facts are REVALIDATED before dispatch (validatePlan below):
// a plan is never assumed authorized indefinitely.
//
// DETERMINISTIC ORDERING POLICY (lexicographic — a weighted "smart score"
// would smuggle Class-C judgment into a Class-B layer):
//   1. dependency_satisfied  (satisfied before unsatisfied)
//   2. produces_evidence     (evidence-producing work first)
//   3. reversible            (reversible before irreversible)
//   4. blast_radius          (none < engine < worktree < all), ascending
//   5. action name           (stable tie-break)
// A presentation rank is the position in this order — derivable, admitted
// candidates only, never able to override the constraints above.
//
// PARALLELISM CLASSIFICATION (contract only — NOTHING is executed in
// parallel by this packet): two actions are safely_parallel ONLY when both
// write sets are declared and provably disjoint. UNKNOWN write sets are
// NEVER safe. The worker's product writes are UNKNOWN by nature, so 'run'
// never joins a parallel group.
//
// FORBIDDEN HERE by authority class: success probability, expected utility,
// attractor/curvature/entropy/trust scores, global Phi, model routing,
// semantic relevance, adaptive thresholds, hidden LLM calls.
//
// Plans persist to build-os/receipts/plans.jsonl (append-only, hash-chained
// like deltas.jsonl). plan content hash = sha256 of the canonical plan body:
// identical inputs => identical content_hash => the SAME plan (idempotent by
// content address); concurrent identical planning may append twice but both
// lines carry one content_hash — the canonical plan IS the hash.

import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { execFileSync } from "node:child_process";

const sha = (s) => crypto.createHash("sha256").update(s).digest("hex");

// Deterministic Class-B facts per supported action. write_set values:
// 'none' | 'receipts' | 'engine' | 'worktree-unknown' | 'all-gravito-state'.
const ACTION_FACTS = {
  status:    { produces_evidence: false, reversible: true,  blast_radius: 0, write_set: "none",              depends_on: null },
  diagnose:  { produces_evidence: true,  reversible: true,  blast_radius: 0, write_set: "receipts",          depends_on: null },
  stop:      { produces_evidence: false, reversible: true,  blast_radius: 0, write_set: "receipts",          depends_on: null },
  review:    { produces_evidence: true,  reversible: true,  blast_radius: 0, write_set: "receipts",          depends_on: "run-stream-exists" },
  run:       { produces_evidence: true,  reversible: false, blast_radius: 2, write_set: "worktree-unknown",  depends_on: null },
  rollback:  { produces_evidence: true,  reversible: true,  blast_radius: 1, write_set: "engine",            depends_on: "previous-manifest-exists" },
  uninstall: { produces_evidence: true,  reversible: false, blast_radius: 1, write_set: "engine",            depends_on: "manifest-exists" },
  push:      { produces_evidence: true,  reversible: false, blast_radius: 3, write_set: "none",              depends_on: null },
};

function depSatisfied(dir, dep) {
  if (!dep) return true;
  const rec = path.join(dir, "build-os/receipts");
  try {
    if (dep === "run-stream-exists") return fs.readdirSync(rec).some((f) => /^run-\d{8}T.*\.jsonl$/.test(f));
    if (dep === "previous-manifest-exists") return fs.readdirSync(rec).filter((f) => f.startsWith("install-manifest-")).length >= 2;
    if (dep === "manifest-exists") return fs.readdirSync(rec).some((f) => f.startsWith("install-manifest-"));
  } catch { return false; }
  return false;
}

function headOf(dir) { try { return execFileSync("git", ["-C", dir, "rev-parse", "HEAD"], { encoding: "utf8" }).trim(); } catch { return null; } }
function goalShaOf(dir) { try { return sha(fs.readFileSync(path.join(dir, "gravito.goal"), "utf8")); } catch { return "no-goal"; } }

function pairClass(a, b) {
  const wa = ACTION_FACTS[a]?.write_set, wb = ACTION_FACTS[b]?.write_set;
  if (!wa || !wb) return "unknown";
  if (wa === "worktree-unknown" || wb === "worktree-unknown") return "unknown";        // UNKNOWN is never safe
  if (wa === "none" && wb === "none") return "safely_parallel";
  if (wa === "none" || wb === "none") return "safely_parallel";
  if (wa === wb) return "conflicting";                                                  // same declared write set
  return "conflicting";                                                                 // distinct engine/receipt writers still share files conservatively
}

/**
 * plan(input) -> { status, plan?, refusal? }
 * input: { run_id, dir, objective, reach, h0_agency, candidates? (subset of verbs), scores? (presentation only) }
 */
export function plan(input) {
  const refuse = (reason) => ({ status: "REFUSED", refusal: reason });
  const { run_id, dir, objective, reach } = input || {};
  if (!run_id || !dir || !reach) return refuse("missing run_id/dir/reach — planning without identity or admission evidence is refused");
  if (reach.artifact !== "reachability") return refuse("reach receipt is not a reachability artifact (corrupt or wrong object)");
  if (path.resolve(reach.dir || "") !== path.resolve(dir)) return refuse(`repository identity mismatch: reach.dir=${reach.dir} vs dir=${dir}`);
  if (!Array.isArray(reach.R_t_plus)) return refuse("reach receipt carries no R_t+ (stale or corrupt)");
  const admitted = new Set(reach.R_t_plus);
  const requested = input.candidates || reach.R_t_plus;
  for (const c of requested) {
    if (!admitted.has(c)) return refuse(`candidate '${c}' is NOT in R_t+ — a score cannot resurrect an inadmissible action`);
    if (!ACTION_FACTS[c]) return refuse(`candidate '${c}' is not a supported action — hypothetical planner objects are refused`);
  }
  if (requested.length === 0) {
    return { status: "NO_REACHABLE_ACTION", plan: null, refusal: "R_t+ intersection is empty — reporting, not inventing work" };
  }
  // Lexicographic ordering over ADMITTED candidates only.
  const facts = requested.map((a) => {
    const f = ACTION_FACTS[a];
    return { action: a, ...f, dependency_satisfied: depSatisfied(dir, f.depends_on) };
  });
  const ordered = facts.slice().sort((x, y) =>
    (y.dependency_satisfied - x.dependency_satisfied) ||
    (y.produces_evidence - x.produces_evidence) ||
    (y.reversible - x.reversible) ||
    (x.blast_radius - y.blast_radius) ||
    x.action.localeCompare(y.action));
  const selected = ordered[0];
  const rejected = ordered.slice(1).map((f, i) => ({
    action: f.action, rank: i + 2,
    reason: `ordered after '${selected.action}' by lexicographic policy: dep_satisfied=${f.dependency_satisfied} evidence=${f.produces_evidence} reversible=${f.reversible} blast=${f.blast_radius}`,
  }));
  // Parallelism classification (contract only; nothing executes in parallel).
  const parallel = [];
  for (let i = 0; i < ordered.length; i++) for (let j = i + 1; j < ordered.length; j++)
    parallel.push({ pair: [ordered[i].action, ordered[j].action], class: pairClass(ordered[i].action, ordered[j].action) });
  const head = headOf(dir), goal_sha = goalShaOf(dir);
  const goalTxt = (() => { try { return fs.readFileSync(path.join(dir, "gravito.goal"), "utf8"); } catch { return ""; } })();
  const acc = (goalTxt.match(/^acceptance_cmd: (.*)$/m) || [, null])[1];
  const budgetTok = (goalTxt.match(/^budget_tokens: (\d+)$/m) || [, null])[1];
  const body = {
    artifact: "plan",
    run_id, objective: objective || "dispatch",
    dir, head, goal_sha,
    h0_agency: input.h0_agency ?? "unknown",
    candidates_admitted: requested.length,
    degenerate: requested.length === 1,
    selected: selected.action,
    reason_trace: requested.length === 1
      ? [`single admitted candidate '${selected.action}' — degenerate plan; no comparison occurred and none is claimed`]
      : [`lexicographic policy over ${requested.length} admitted candidates: dependency_satisfied > produces_evidence > reversible > blast_radius asc > name`],
    ordered: ordered.map((f, i) => ({ rank: i + 1, action: f.action, dependency_satisfied: f.dependency_satisfied, produces_evidence: f.produces_evidence, reversible: f.reversible, blast_radius: f.blast_radius, write_set: f.write_set })),
    rejected,
    parallel_classification: parallel,
    required_verification: acc ? `acceptance_cmd: ${acc}` : "human-judgment acceptance (no acceptance_cmd in contract)",
    rollback_expectation: selected.reversible ? "reversible per engine-manifest semantics" : "NOT reversible by gravito rollback — worker product changes are the operator's to keep or revert",
    cognition_requirement: {
      action: selected.action,
      state: selected.action === "run" ? "CONTEXT_REQUIRED" : "NO_CONTEXT_ALLOWED",
      factual_surfaces: ["gravito.goal", "target diff", "acceptance criteria"],
      knowledge_classes: ["verified-repair-rules"],
      authority_summary: (goalTxt.match(/^authority: (.*)$/m) || [, "unknown"])[1],
      verification: acc || "human judgment",
      max_context_budget_tokens: budgetTok ? Number(budgetTok) : null,
      consumer: "UCDL — IMPLEMENTED_UNWIRED; this descriptor is the seam, not an invocation",
      correlation: { run_id },
    },
    evidence_scale: "task",
    provenance: { planner: "build-os/tools/planner.mjs", policy: "lexicographic@1", freshness: "same-invocation reachability receipt" },
  };
  const content_hash = sha(JSON.stringify(body));
  return { status: "PLANNED", plan: { ...body, content_hash } };
}

/** Class-A revalidation before dispatch: a plan never stays authorized by age. */
export function validatePlan(dir, p) {
  if (!p || p.artifact !== "plan") return { ok: false, reason: "not a plan artifact" };
  if (path.resolve(p.dir) !== path.resolve(dir)) return { ok: false, reason: "repository identity changed" };
  if (headOf(dir) !== p.head) return { ok: false, reason: "repository HEAD changed since planning — replan required" };
  if (goalShaOf(dir) !== p.goal_sha) return { ok: false, reason: "goal/authority changed since planning — replan required" };
  return { ok: true, reason: "plan facts revalidated" };
}

export function appendPlanReceipt(dir, planObj, origin) {
  const f = path.join(dir, "build-os/receipts/plans.jsonl");
  fs.mkdirSync(path.dirname(f), { recursive: true });
  // mkdir mutex: the chain's prev_sha read+append must be atomic under
  // concurrent planning. Identical concurrent plans stay ONE canonical plan
  // by content_hash; the receipt stream just records each planning event.
  const lock = f + ".lock.d";
  const t0 = Date.now();
  for (;;) {
    try { fs.mkdirSync(lock); break; }
    catch { if (Date.now() - t0 > 5000) throw new Error("plan receipt lock timeout"); }
  }
  try {
    const prev = (() => {
      try { const lines = fs.readFileSync(f, "utf8").trim().split("\n"); return sha(lines[lines.length - 1]); } catch { return "genesis"; }
    })();
    const line = JSON.stringify({ at: new Date().toISOString().replace(/\.\d+Z/, "Z"), origin, content_hash: planObj.content_hash, run_id: planObj.run_id, selected: planObj.selected, status: "PLANNED", candidates: planObj.candidates_admitted, degenerate: planObj.degenerate, prev_sha: prev });
    fs.appendFileSync(f, line + "\n");
  } finally {
    try { fs.rmdirSync(lock); } catch {}
  }
  return f;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  // CLI: planner.mjs plan --dir D --run-id ID --origin O [--objective X]  (reach JSON on stdin)
  //      planner.mjs verify DIR
  const mode = process.argv[2];
  if (mode === "verify") {
    const f = path.join(path.resolve(process.argv[3] || "."), "build-os/receipts/plans.jsonl");
    if (!fs.existsSync(f)) { console.log("plans: no stream"); process.exit(0); }
    let prev = "genesis", n = 0, torn = 0;
    for (const raw of fs.readFileSync(f, "utf8").split("\n").filter(Boolean)) {
      let d; try { d = JSON.parse(raw); } catch { torn++; continue; }
      if (d.prev_sha !== prev) { console.log(`plans: TAMPER/REORDER at line ${n + 1}`); process.exit(1); }
      prev = sha(raw); n++;
    }
    console.log(`plans: chain intact — ${n} receipt(s)` + (torn ? `, ${torn} torn line(s) detected` : ""));
    process.exit(torn ? 1 : 0);
  }
  const arg = (n) => { const i = process.argv.indexOf(`--${n}`); return i > 0 ? process.argv[i + 1] : null; };
  const reach = JSON.parse(fs.readFileSync(0, "utf8"));
  const r = plan({ run_id: arg("run-id"), dir: path.resolve(arg("dir") || "."), objective: arg("objective") || "dispatch", reach, h0_agency: arg("h0") || "unknown", candidates: arg("candidates") ? arg("candidates").split(",") : undefined });
  if (r.status === "PLANNED") appendPlanReceipt(path.resolve(arg("dir") || "."), r.plan, arg("origin") || "cli");
  console.log(JSON.stringify(r));
  process.exit(r.status === "PLANNED" ? 0 : r.status === "NO_REACHABLE_ACTION" ? 3 : 2);
}
