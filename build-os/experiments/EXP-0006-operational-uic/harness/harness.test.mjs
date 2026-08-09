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

  // ---- path normalisation, found by the pilot on the FIRST arm ------------
  // The danger of a fix like this is that it widens the rule while looking like
  // it narrows an artifact. So the pair below is the whole point: the same
  // error under a different tree root must NOT count, and a genuinely new error
  // under the arm's tree root MUST still count.
  const B_ROOT = "/home/user/empathiq-website", A_ROOT = "/home/user/exp0006-arm";
  const withRoot = (root, extra = "") =>
    `${G}(4,3): error TS2551: Property 'q' does not exist on type 'typeof import("${root}/drizzle/schema")'.\n` + extra;

  const artifact = adjudicate({ baselineRaw: `${F}(1,1): error TS2322: x\n` + withRoot(B_ROOT), afterRaw: withRoot(A_ROOT), taskFile: F, diff: goodDiff });
  t("SAME error under a different tree root is NOT a regression", artifact.accepted === true &&
    artifact.condition_2_no_new_errors_elsewhere.new_error_count === 0);
  t("the normalisation is REPORTED, not silent", artifact.path_normalisations_applied >= 2,
    `counted ${artifact.path_normalisations_applied}`);

  // MUTATION E — the regression detector must survive its own fix.
  const stillCaught = adjudicate({
    baselineRaw: `${F}(1,1): error TS2322: x\n` + withRoot(B_ROOT),
    afterRaw: withRoot(A_ROOT, `server/z.ts(9,2): error TS2345: Argument of type 'c' is not assignable.\n`),
    taskFile: F, diff: goodDiff,
  });
  t("MUTATION a genuinely new error still REJECTS after normalisation", stillCaught.accepted === false &&
    stillCaught.condition_2_no_new_errors_elsewhere.new_error_count === 1);

  // And a new error whose message CONTAINS the arm root is still new — the
  // normaliser must not become a blanket amnesty for anything path-shaped.
  const newUnderRoot = adjudicate({
    baselineRaw: `${F}(1,1): error TS2322: x\n` + withRoot(B_ROOT),
    afterRaw: withRoot(A_ROOT) + `server/z.ts(2,1): error TS2339: Property 'r' does not exist on type 'typeof import("${A_ROOT}/drizzle/schema")'.\n`,
    taskFile: F, diff: goodDiff,
  });
  t("MUTATION a NEW error that also carries the arm root still REJECTS", newUnderRoot.accepted === false &&
    newUnderRoot.condition_2_no_new_errors_elsewhere.new_error_count === 1);

  // ---- net introduction, found by the pilot on T03/native -----------------
  // A MODIFIED line is both a removal and an addition. Charging its
  // pre-existing `any` as newly introduced rejected an arm that had strictly
  // IMPROVED the typing. All three directions are asserted, because a fix that
  // only demonstrates the case it was written for is a transcription.
  const modLine = (extra) => `diff --git a/${F} b/${F}\n--- a/${F}\n+++ b/${F}\n@@\n${extra}`;

  const improved = adjudicate({ baselineRaw: before, afterRaw: "", taskFile: F,
    diff: modLine("-  issues: xs.map((i: any) => ({\n+  issues: xs.map((i: any): Issue => ({\n") });
  t("a pre-existing `any` carried through an IMPROVED line does not reject", improved.accepted === true,
    JSON.stringify(improved.diff_rejection.net_introduced));

  const introduced = adjudicate({ baselineRaw: before, afterRaw: "", taskFile: F,
    diff: modLine("-  issues: xs.map((i: Issue) => ({\n+  issues: xs.map((i: any) => ({\n") });
  t("MUTATION replacing a TYPED line with an `any` version still REJECTS", introduced.accepted === false &&
    introduced.diff_rejection.net_introduced.any_cast === 1);

  const ignored = adjudicate({ baselineRaw: before, afterRaw: "", taskFile: F,
    diff: modLine("-  const x: b = a;\n+  // @ts-ignore\n+  const x: b = a;\n") });
  t("MUTATION an ADDED @ts-ignore still REJECTS (1 added / 0 removed)", ignored.accepted === false &&
    ignored.diff_rejection.net_introduced.ts_ignore === 1);

  // TWO added, ONE removed -> one is genuinely new, so it must still reject.
  const twoOne = adjudicate({ baselineRaw: before, afterRaw: "", taskFile: F,
    diff: modLine("-  f(a: any);\n+  f(a: any);\n+  g(b: any);\n") });
  t("MUTATION two `any` added against one removed still REJECTS", twoOne.accepted === false &&
    twoOne.diff_rejection.net_introduced.any_cast === 1);

  // The KNOWN residual weakness, asserted as a LIMIT rather than dressed up as
  // a pass: an unrelated deletion cancels a genuine introduction. Recorded so
  // nobody later mistakes silence here for coverage.
  const coincidence = adjudicate({ baselineRaw: before, afterRaw: "", taskFile: F,
    diff: modLine("-  legacy(z: any);\n+  const x = a as any;\n") });
  t("KNOWN LIMIT: an unrelated removal cancels a real introduction (documented, not fixed)",
    coincidence.accepted === true && coincidence.diff_rejection.hits_offset_by_removals.length === 1,
    "counting cannot distinguish this from a modified line; the compiler conditions remain independent of this scan");

  // The scanner must attribute to the right file.
  const other = scanDiff(`diff --git a/${G} b/${G}\n+const x = a as any;\n`, F);
  t("a suppression in ANOTHER file is not charged to this task", other.rejection_hits.length === 0 && other.section_found === false);
}

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
