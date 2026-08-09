#!/usr/bin/env node
// EXP-0006 harness — MUTATION TESTS.
//
// Every check below decides something the experiment cannot recover from if it
// is wrong: whether the treatment was administered, and whether a task was
// accepted. A check that has never demonstrated a failure tells you it ran, not
// that it guards — and EXP-0005's session-isolation check passed VACUOUSLY on
// its first run while the child had inherited the orchestrator's exact id.
//
// So each assertion here damages the thing under test and requires the check to
// notice. A test that only exercises the passing path is a transcription.

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { verifyAdministration, LOAD_BEARING, WITHHELD_DIRS, CODE_SOURCE } from "./substrate.mjs";
import { adjudicate, scanDiff } from "./acceptance.mjs";

let pass = 0, fail = 0;
const t = (name, ok, detail = "") => {
  if (ok) { pass++; console.log(`  ok   ${name}`); }
  else { fail++; console.log(`  FAIL ${name}${detail ? " — " + detail : ""}`); }
};

// ---- a minimal fake arm tree ----------------------------------------------
function fakeGravitoTree() {
  const d = fs.mkdtempSync(path.join(os.tmpdir(), "exp0006-mut-"));
  for (const p of LOAD_BEARING) {
    fs.mkdirSync(path.join(d, path.dirname(p)), { recursive: true });
    fs.writeFileSync(path.join(d, p), `stub for ${p}\n`);
  }
  // Distinct from the orchestrator's own memory, so the DATA check should pass.
  fs.writeFileSync(path.join(d, "build-os/memory/current_state.md"), "ARM TREE OWN MEMORY\n");
  return d;
}

console.log("substrate administration — mutation tests");
{
  const d = fakeGravitoTree();
  t("baseline: a correctly administered gravito tree VERIFIES", verifyAdministration(d, "gravito").ok);

  // MUTATION 1 — a load-bearing controller goes missing.
  const victim = "build-os/motion/continuation.mjs";
  fs.rmSync(path.join(d, victim));
  const v1 = verifyAdministration(d, "gravito");
  t("MUTATION missing controller -> REFUSED", v1.ok === false &&
    v1.checks.some((c) => c.name === "load_bearing_controllers_present" && !c.ok && c.detail.includes(victim)));
  fs.writeFileSync(path.join(d, victim), "restored\n");

  // MUTATION 2 — DATA is trampled by CODE: the arm's memory becomes the
  // orchestrator's. This is the failure that would hand the arm another
  // project's history and call it persistence.
  const orchMem = path.join(CODE_SOURCE, "build-os/memory/current_state.md");
  if (fs.existsSync(orchMem)) {
    fs.copyFileSync(orchMem, path.join(d, "build-os/memory/current_state.md"));
    const v2 = verifyAdministration(d, "gravito");
    t("MUTATION data overwritten by code -> REFUSED", v2.ok === false &&
      v2.checks.some((c) => c.name === "data_retained_not_overwritten" && !c.ok));
    fs.writeFileSync(path.join(d, "build-os/memory/current_state.md"), "ARM TREE OWN MEMORY\n");
  } else t("MUTATION data overwritten by code -> REFUSED", false, "orchestrator memory unreadable, mutation not exercised");

  // MUTATION 3 — the benchmark leaks into the arm tree.
  const leak = WITHHELD_DIRS[0].dir;
  fs.mkdirSync(path.join(d, leak, "EXP-0006-operational-uic"), { recursive: true });
  const v3 = verifyAdministration(d, "gravito");
  t("MUTATION benchmark visible to the arm -> REFUSED", v3.ok === false &&
    v3.checks.some((c) => c.name === "benchmark_withheld_from_arm" && !c.ok));
  fs.rmSync(path.join(d, leak), { recursive: true, force: true });

  t("post-mutation: the tree verifies again, so the checks are not stuck-failing", verifyAdministration(d, "gravito").ok);

  // MUTATION 4 — the native arm still carries substrate.
  t("MUTATION native arm with substrate present -> REFUSED", verifyAdministration(d, "native").ok === false);
  const bare = fs.mkdtempSync(path.join(os.tmpdir(), "exp0006-bare-"));
  t("baseline: a bare tree passes the native check", verifyAdministration(bare, "native").ok);

  fs.rmSync(d, { recursive: true, force: true });
  fs.rmSync(bare, { recursive: true, force: true });
}

console.log("\nacceptance — mutation tests");
{
  const F = "server/x.ts", G = "server/y.ts";
  const before = `${F}(10,5): error TS2322: Type 'a' is not assignable to type 'b'.\n${G}(3,1): error TS7006: Parameter implicitly has an 'any' type.\n`;
  const goodDiff = `diff --git a/${F} b/${F}\n--- a/${F}\n+++ b/${F}\n@@\n-const x: b = a;\n+const x: b = toB(a);\n`;

  // Baseline: the file is clean, nothing new elsewhere, the diff is honest.
  const okRes = adjudicate({ baselineRaw: before, afterRaw: `${G}(3,1): error TS7006: Parameter implicitly has an 'any' type.\n`, taskFile: F, diff: goodDiff });
  t("baseline: fixed file with no collateral -> ACCEPTED", okRes.accepted === true);

  // MUTATION A — the task file still has an error.
  const a = adjudicate({ baselineRaw: before, afterRaw: before, taskFile: F, diff: goodDiff });
  t("MUTATION errors remain in the task file -> REJECTED", a.accepted === false && a.condition_1_zero_errors_in_file.pass === false);

  // MUTATION B — a NEW error appears in another file.
  const b = adjudicate({ baselineRaw: before, afterRaw: `${G}(3,1): error TS7006: Parameter implicitly has an 'any' type.\n${G}(9,2): error TS2345: Argument of type 'c'.\n`, taskFile: F, diff: goodDiff });
  t("MUTATION new error elsewhere -> REJECTED", b.accepted === false && b.condition_2_no_new_errors_elsewhere.pass === false);

  // MUTATION C — the error was silenced, not fixed.
  for (const [label, line] of [["as any", "+const x = a as any;"], ["@ts-ignore", "+// @ts-ignore"], ["@ts-nocheck", "+// @ts-nocheck"], [": any", "+let x: any = a;"]]) {
    const d = adjudicate({ baselineRaw: before, afterRaw: "", taskFile: F, diff: `diff --git a/${F} b/${F}\n--- a/${F}\n+++ b/${F}\n@@\n${line}\n` });
    t(`MUTATION suppression via ${label} -> REJECTED`, d.accepted === false && d.diff_rejection.rejected === true);
  }

  // MUTATION D — the offending code was deleted.
  const del = adjudicate({ baselineRaw: before, afterRaw: "", taskFile: F, diff: `diff --git a/${F} b/${F}\n--- a/${F}\n+++ b/${F}\n@@\n-const x: b = a;\n-doThing(x);\n` });
  t("MUTATION offending code deleted -> REJECTED", del.accepted === false && del.diff_rejection.deletion_suspected === true);

  // NOT a mutation — the check must NOT fire on these, or it is stuck-failing.
  const shifted = adjudicate({ baselineRaw: before, afterRaw: `${G}(47,1): error TS7006: Parameter implicitly has an 'any' type.\n`, taskFile: F, diff: goodDiff });
  t("line shift in an untouched file is NOT a regression", shifted.accepted === true,
    "position is discarded on purpose: editing a file moves every line below the edit");
  const preexisting = adjudicate({
    baselineRaw: before, afterRaw: "", taskFile: F,
    diff: `diff --git a/${F} b/${F}\n--- a/${F}\n+++ b/${F}\n@@\n const legacy: any = z;\n+const x: b = toB(a);\n`,
  });
  t("a pre-existing `any` on a CONTEXT line does not reject", preexisting.accepted === true,
    "patterns match added lines only; matching the whole file would score the seed instead of the work");

  // The scanner must attribute to the right file.
  const other = scanDiff(`diff --git a/${G} b/${G}\n+const x = a as any;\n`, F);
  t("a suppression in ANOTHER file is not charged to this task", other.rejection_hits.length === 0 && other.section_found === false);
}

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
