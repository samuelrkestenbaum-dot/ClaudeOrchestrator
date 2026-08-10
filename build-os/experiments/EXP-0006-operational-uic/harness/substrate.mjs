// EXP-0006 — ADMINISTERING THE TREATMENT, and saying exactly what it is.
//
// THE PROBLEM THIS FILE EXISTS TO SOLVE, STATED BEFORE IT IS SOLVED.
//
// The frozen preregistration defines the Gravito arm as carrying "the CURRENT
// load-bearing substrate: persistent memory, routing, live authority
// compatibility selection, mutation enforcement, capability exhaustion,
// continuation and value prioritisation, evidence handling and verification."
//
// The arm tree is empathiq-website at seed 2543c873. That tree carries a
// Gravito EMBED — 206 files — but the embed is a SNAPSHOT, and it does not
// contain the controllers the preregistration names. There is no
// build-os/motion (continuation, objective, concession-gate, capability-map),
// no build-os/assumptions (authority selector, host profiles, registry), no
// build-os/surfaces, no build-os/audit. Its .claude/hooks/routing-gate.sh
// predates this session's CODE_ROOT/DATA_ROOT repair and therefore carries a
// known product regression.
//
// So running the arm against the embed as-found would administer a DIFFERENT,
// OLDER, KNOWN-DEFECTIVE treatment from the one the preregistration froze —
// and would then report the result as a verdict on the current substrate. That
// is EXP-0005's error in a new key: EXP-0005 measured a precondition failure
// and called it a product verdict. Measuring a stale snapshot and calling it
// "Gravito" would be the same mistake, one layer up.
//
// THE RULE. Gravito CODE is administered from the orchestrator; Gravito DATA
// stays whatever the arm tree already had. That is not a new distinction
// invented for this experiment — it is the same CODE_ROOT/DATA_ROOT split that
// .claude/hooks/routing-gate.sh already resolves at runtime, and the split
// whose confusion WAS the regression this session fixed.
//
// Both lists below are ENUMERATED with a stated reason per entry. An unstated
// rule is a rule that can be widened quietly later.

import fs from "node:fs";
import path from "node:path";

/** The orchestrator repository that supplies CODE. */
export const CODE_SOURCE = "/home/user/ClaudeOrchestrator";

/**
 * DATA — per-repository durable state. The arm works on empathiq-website, so
 * empathiq-website's own memory, receipts and packets are the correct memory
 * for it to carry. Overwriting them with the orchestrator's would hand the arm
 * another project's history and call it persistence.
 */
export const DATA_DIRS = [
  { dir: "build-os/memory",   why: "the arm's own durable memory; another repo's memory is not this repo's persistence" },
  { dir: "build-os/receipts", why: "closed-packet history belongs to the repository that closed them" },
  { dir: "build-os/packets",  why: "packet state, including live routing ledgers, is per-repository" },
  { dir: "build-os/design",   why: "product design records, authored in this repository" },
  { dir: "build-os/graph",    why: "project graph data, derived from this repository" },
];

/**
 * NEVER ADMINISTERED — contamination, not substrate. These would let a measured
 * arm read the experiment that is measuring it.
 */
export const WITHHELD_DIRS = [
  { dir: "build-os/experiments", why: "CONTAMINATION: contains this experiment's own preregistration, task selection and prior arms. An arm that can read the benchmark it is being scored by is not measurable." },
  { dir: "build-os/pilots",      why: "CONTAMINATION: orchestrator pilot records naming the substrate under test" },
];

/** Top-level substrate paths outside build-os. */
export const ROOT_CODE = [
  { p: ".claude",   why: "agents, hooks, commands and settings — the runtime that enforces routing and mutation gating" },
  { p: "CLAUDE.md", why: "the doctrine the arm is governed by; the current one, not a snapshot of it" },
];

/**
 * The controllers the preregistration names by function. The administration is
 * verified against THIS list — presence is checked, not assumed, because
 * "the substrate was copied" and "the substrate is there" are different claims.
 */
export const LOAD_BEARING = [
  "build-os/motion/continuation.mjs",
  "build-os/motion/objective.mjs",
  "build-os/motion/concession-gate.mjs",
  "build-os/motion/capability-map.mjs",
  "build-os/assumptions/authority-selector.mjs",
  "build-os/assumptions/host-profiles.mjs",
  "build-os/assumptions/gate-recovery.mjs",
  "build-os/tools/route-task.sh",
  "build-os/tools/routing-check.sh",
  ".claude/hooks/routing-gate.sh",
  ".claude/settings.json",
  "CLAUDE.md",
  "build-os/memory/tool_router.md",   // DATA — must survive administration, not be replaced
];

/**
 * SESSION-LOCAL STATE — excluded by LIFECYCLE, not by directory.
 *
 * THE DEFECT THIS EXISTS FOR. `build-os/motion` was classified CODE, so every
 * measured Gravito arm received `queue.json` — THIS orchestrator's live work
 * queue, carrying tasks #49-#55 of the experiment session that was measuring
 * them. Workers read it (11,415-22,830 chars/arm) and adopted the posture it
 * implied: 19 turns of "Holding.", plus "Stopping.", "Standing by." and
 * "T04 complete. #55 needs your go." A worker asked to fix two type errors was
 * waiting for operator authorisation on the experiment queue. Native arms
 * produced ZERO such turns.
 *
 * The directory convention was the failure. `motion` holds both controllers
 * (reusable implementation) and a live queue (session state), and a rule that
 * classifies by folder cannot tell them apart. So classification is now by what
 * a file IS, enumerated per file with a reason, and the regression below proves
 * a sentinel cannot cross.
 *
 * THE RULE: state crosses into worker cognition only when its relevance and
 * authority class permit it. Reusable substrate implementation is administered;
 * orchestrator-, session- and run-local state is not, wherever it lives.
 */
export const SESSION_LOCAL_FILES = [
  { file: "build-os/motion/queue.json",
    why: "the orchestrator's LIVE work queue — the measured worker's agenda is its task, never the measurer's" },
  { file: "build-os/motion/current.json",
    why: "current in-flight item; session-local by definition" },
  { file: "build-os/learning/dispositions/EXP-0004.json",
    why: "a prior experiment's live disposition record — run-local state, not reusable definition" },
];

const isData = (d) => DATA_DIRS.some((x) => x.dir === d);
const isWithheld = (d) => WITHHELD_DIRS.some((x) => x.dir === d);

/** Which build-os subdirectories count as CODE, derived from the source tree. */
export function codeDirs(source = CODE_SOURCE) {
  return fs.readdirSync(path.join(source, "build-os"), { withFileTypes: true })
    .filter((e) => e.isDirectory())
    .map((e) => `build-os/${e.name}`)
    .filter((d) => !isData(d) && !isWithheld(d))
    .sort();
}

const cp = (src, dst) => {
  fs.rmSync(dst, { recursive: true, force: true });
  fs.cpSync(src, dst, { recursive: true, dereference: false });
};

/**
 * Administer the condition. Returns a record of exactly what was done, which is
 * written into the run record — a treatment nobody can enumerate afterwards is
 * a treatment nobody can reproduce.
 */
export function administer(armTree, arm, source = CODE_SOURCE) {
  const acts = [];

  if (arm === "native") {
    // The native arm is the ABSENCE of the substrate, and the embed counts as
    // substrate. Removing only what the orchestrator would have added would
    // leave the arm with a stale Gravito, which is neither condition.
    for (const p of ["build-os", ".claude", "CLAUDE.md"]) {
      fs.rmSync(path.join(armTree, p), { recursive: true, force: true });
      acts.push({ act: "remove", path: p });
    }
    return { arm, acts, code_source: null };
  }

  const dirs = codeDirs(source);
  for (const d of dirs) {
    cp(path.join(source, d), path.join(armTree, d));
    acts.push({ act: "administer_code", path: d });
  }
  // Session-local state is removed AFTER the copy, so the exclusion holds no
  // matter which CODE directory a live file is hiding inside.
  for (const { file, why } of SESSION_LOCAL_FILES) {
    const t = path.join(armTree, file);
    if (fs.existsSync(t)) { fs.rmSync(t, { force: true }); acts.push({ act: "withhold_session_state", path: file, why }); }
  }
  for (const { p } of ROOT_CODE) {
    cp(path.join(source, p), path.join(armTree, p));
    acts.push({ act: "administer_code", path: p });
  }
  for (const { dir } of DATA_DIRS) acts.push({ act: "retain_data", path: dir });
  for (const { dir } of WITHHELD_DIRS) {
    // Belt and braces: the source is not copied, and any same-named directory
    // that arrived with the seed is removed, so no route reaches the benchmark.
    fs.rmSync(path.join(armTree, dir), { recursive: true, force: true });
    acts.push({ act: "withhold", path: dir });
  }
  return { arm, acts, code_source: source, code_dirs: dirs };
}

/**
 * Verify the condition was actually administered. FAILING THIS IS A REFUSAL.
 * EXP-0005's whole failure mode was a treatment that did not execute while the
 * harness proceeded as though it had.
 */
export function verifyAdministration(armTree, arm) {
  const checks = [];
  const ck = (name, ok, detail) => { checks.push({ name, ok, detail }); return ok; };

  if (arm === "native") {
    const present = ["build-os", ".claude", "CLAUDE.md"].filter((p) => fs.existsSync(path.join(armTree, p)));
    ck("substrate_absent", present.length === 0, present.length ? `still present: ${present.join(", ")}` : "build-os, .claude, CLAUDE.md all removed");
  } else {
    const missing = LOAD_BEARING.filter((p) => !fs.existsSync(path.join(armTree, p)));
    ck("load_bearing_controllers_present", missing.length === 0,
      missing.length ? `MISSING: ${missing.join(", ")}` : `${LOAD_BEARING.length} named controllers present`);

    // The memory must be the ARM TREE's, not the orchestrator's. If the code
    // copy trampled it, the arm carries another project's history.
    const mem = path.join(armTree, "build-os/memory/current_state.md");
    let ownMemory = false, memDetail = "current_state.md absent";
    if (fs.existsSync(mem)) {
      const a = fs.readFileSync(mem, "utf8");
      const b = (() => { try { return fs.readFileSync(path.join(CODE_SOURCE, "build-os/memory/current_state.md"), "utf8"); } catch { return null; } })();
      ownMemory = b === null || a !== b;
      memDetail = ownMemory ? "arm tree retains its own durable memory" : "arm memory is byte-identical to the orchestrator's — DATA was overwritten by CODE";
    }
    ck("data_retained_not_overwritten", ownMemory, memDetail);

    const sessionLeak = SESSION_LOCAL_FILES.filter((f) => fs.existsSync(path.join(armTree, f.file))).map((f) => f.file);
    ck("no_session_local_state", sessionLeak.length === 0,
      sessionLeak.length ? `the worker can read the orchestrator's own state: ${sessionLeak.join(", ")}`
                         : `${SESSION_LOCAL_FILES.length} session-local files withheld by lifecycle, not by directory`);
    const leaked = WITHHELD_DIRS.filter((w) => fs.existsSync(path.join(armTree, w.dir))).map((w) => w.dir);
    ck("benchmark_withheld_from_arm", leaked.length === 0,
      leaked.length ? `the arm can read: ${leaked.join(", ")}` : "experiments and pilots absent from the arm tree");
  }
  return { ok: checks.every((c) => c.ok), checks };
}
