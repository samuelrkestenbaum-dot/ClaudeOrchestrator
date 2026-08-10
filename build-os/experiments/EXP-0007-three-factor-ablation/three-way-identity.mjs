#!/usr/bin/env node
// THREE-WAY SOURCE IDENTITY — the preflight that refuses lean-vs-lean.
//
// Administers BOTH pinned treatments into scratch trees through the REAL
// administration path (substrate.administer with a pinned source), hashes the
// administered CODE, and FAILS unless current != lean by bytes. The record it
// writes is the operator-required source-identity artifact: requested ref,
// resolved commit, archive hash, administered-tree hash, and the proof.
//
// Labels prove nothing; two different git labels can name identical content.
// This compares what a worker would actually receive.

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { administer } from "../EXP-0006-operational-uic/harness/substrate.mjs";
import { applyVariant, verifyVariant } from "./variants.mjs";

const HERE = path.dirname(new URL(import.meta.url).pathname);
const ORCH = path.join(HERE, "../../..");
const sh = (c) => execFileSync("bash", ["-c", c], { encoding: "utf8" }).trim();
const PINS = { current: "241ac45", lean: "78bedf1" };

const out = { artifact: "three_way_source_identity", generated_by: "three-way-identity.mjs", treatments: {}, distinct: null, differing_files: [] };
const scratch = fs.mkdtempSync(path.join(os.tmpdir(), "three-way-id-"));

for (const [treatment, ref] of Object.entries(PINS)) {
  const resolved = sh(`git -C ${JSON.stringify(ORCH)} rev-parse ${ref}^{commit}`);
  const src = path.join(scratch, `src-${treatment}`);
  fs.mkdirSync(src, { recursive: true });
  sh(`git -C ${JSON.stringify(ORCH)} archive ${resolved} -- build-os .claude CLAUDE.md | tar -x -C ${JSON.stringify(src)}`);

  // A minimal seed-like tree so administer() has somewhere to land. DATA that
  // the real seed supplies (tool_router.md) is stubbed so the behaviour check
  // measures the ADMINISTERED content, not the fixture's poverty; the stub is
  // identical for both treatments, so it cannot create or mask a difference.
  const tree = path.join(scratch, `tree-${treatment}`);
  fs.mkdirSync(path.join(tree, "build-os/memory"), { recursive: true });
  fs.writeFileSync(path.join(tree, "build-os/memory/tool_router.md"), "# tool router (seed DATA stub, identical across treatments)\n");
  administer(tree, "gravito", src);
  const v = applyVariant(tree, treatment);
  const check = verifyVariant(tree, treatment);
  const hash = sh(`cd ${JSON.stringify(tree)} && find build-os .claude CLAUDE.md -type f ! -path 'build-os/memory/*' 2>/dev/null | LC_ALL=C sort | xargs sha256sum | sha256sum | cut -c1-64`);
  out.treatments[treatment] = {
    requested_ref: ref, resolved_commit: resolved,
    source_archive_sha256: sh(`git -C ${JSON.stringify(ORCH)} archive ${resolved} -- build-os .claude CLAUDE.md | sha256sum | cut -c1-64`),
    administered_tree_sha256: hash,
    variant_applied: v.config,
    content_checks: check.checks,
    content_checks_ok: check.ok,
  };
}

const c = out.treatments.current, l = out.treatments.lean;
out.distinct = c.administered_tree_sha256 !== l.administered_tree_sha256;

// Which files actually differ — evidence, not just a verdict.
if (out.distinct) {
  const diff = sh(`cd ${JSON.stringify(scratch)} && diff -rq tree-current tree-lean 2>/dev/null | head -40 || true`);
  out.differing_files = diff.split("\n").filter(Boolean);
}

fs.writeFileSync(path.join(HERE, "results/source-identity.json"), JSON.stringify(out, null, 2) + "\n");
fs.rmSync(scratch, { recursive: true, force: true });

console.log("THREE-WAY SOURCE IDENTITY");
for (const [t, r] of Object.entries(out.treatments)) {
  console.log(`  ${t.padEnd(8)} ${r.requested_ref} -> ${r.resolved_commit.slice(0, 12)}  administered ${r.administered_tree_sha256.slice(0, 16)}…  content-checks ${r.content_checks_ok ? "OK" : "FAILED"}`);
  for (const ck of r.content_checks) if (!ck.ok) console.log(`      FAIL ${ck.name}: ${ck.detail}`);
}
if (!out.distinct) {
  console.error("\nREFUSED — current and lean administer IDENTICAL bytes. This would be lean-vs-lean wearing two names.");
  process.exit(1);
}
if (!c.content_checks_ok || !l.content_checks_ok) {
  console.error("\nREFUSED — a treatment's content checks failed (see above). Distinct bytes are not enough; each treatment must BE what its label claims.");
  process.exit(1);
}
console.log(`\nDISTINCT — ${out.differing_files.length} differing path(s) recorded, e.g.:`);
for (const d of out.differing_files.slice(0, 6)) console.log(`  ${d}`);
console.log("\nrecord: results/source-identity.json");
