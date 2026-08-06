#!/usr/bin/env node
// Context compiler — RENDERER (capsule.json -> capsule.md), SEAM 5.
//
//   render-capsule.mjs --capsule <capsule.json> [--out <file>]
//
// Also importable: `import { renderCapsule } from "./render-capsule.mjs"`.
//
// SEAM 5 is a CACHE contract, not a style guide. Rendered capsules are ordered
// so that the expensive, reusable part of the prompt is byte-identical across
// every task, and only the cheap tail changes:
//
//   1. PREFIX   — protocol, authority classes, receipt schema, tier
//                 vocabulary. Byte-identical across ALL tasks, always.
//   2. SLOW     — repository-derived: the file map, artifact refs. Changes
//                 when the repo changes, not when the task changes.
//   3. VOLATILE — this task: objective, baseline, constraints, acceptance,
//                 authority, budget accounting, provenance.
//
// The rule that makes this worth anything: VOLATILE CONTENT MAY NEVER BE
// INTERLEAVED INTO THE PREFIX. One task's objective appearing in segment 1
// invalidates the cached prefix for every other task — which is precisely the
// cost SEAM 5 exists to avoid. The section sentinels below are machine-checked
// by tests/compiler_capsule_tests.sh, which byte-compares the prefix of two
// capsules for different tasks.
//
// Rendering is a pure function of (capsule, prefix). No clock, no filesystem,
// no environment: same capsule.json in, same bytes out.
//
// Dependencies: node stdlib only.

import fs from "node:fs";
import { IMMUTABLE_PREFIX } from "./capsule-prefix.mjs";

const S = (name) => `<!-- CAPSULE:${name}:START -->`;
const E = (name) => `<!-- CAPSULE:${name}:END -->`;

const esc = (s) => String(s ?? "");
const list = (xs, empty) =>
  Array.isArray(xs) && xs.length ? xs.map((x) => `- ${esc(x)}`).join("\n") : `_${empty}_`;

/**
 * @param {object} capsule parsed capsule.json (SEAM 2)
 * @param {string} prefix  the immutable prefix (defaults to the constant)
 * @returns {string} capsule.md
 */
export function renderCapsule(capsule, prefix = IMMUTABLE_PREFIX) {
  const c = capsule || {};
  const out = [];

  // ---------------------------------------------------------- 1. PREFIX --
  // Emitted verbatim. Nothing from `c` may be referenced between these two
  // sentinels — that is the invariant the whole seam rests on.
  out.push(S("PREFIX"));
  out.push(prefix.replace(/\n+$/, ""));
  out.push(E("PREFIX"));
  out.push("");

  // ------------------------------------------------------ 2. SLOW-MOVING --
  out.push(S("SLOW"));
  out.push("## Repository map (compiled selection)");
  out.push("");
  out.push(`index_version: ${esc(c.index_version ?? "not measured")}  ·  ` +
           `repo_head: ${esc(c.repo_head ?? "not measured")}`);
  out.push("");
  const rf = Array.isArray(c.relevant_files) ? c.relevant_files : [];
  if (!rf.length) {
    out.push("_No files admitted. See the provenance section for why — an empty map " +
             "here is a stated result, not a rendering failure._");
  } else {
    out.push("| file | admitted because (rule) | symbols |");
    out.push("|---|---|---|");
    for (const f of rf) {
      const syms = Array.isArray(f.symbols) && f.symbols.length
        ? f.symbols.join(", ")
        : (f.partial ? "(not extracted — index partial)" : "(none indexed)");
      out.push(`| \`${esc(f.path)}\` | ${esc(f.why)} | ${esc(syms)} |`);
    }
  }
  out.push("");
  out.push("### Dependency neighborhood");
  out.push("");
  out.push(list(c.dependency_neighborhood, "empty — no importer/import ring was admitted"));
  out.push("");
  out.push("### Allowed mutation surface");
  out.push("");
  out.push(list(c.allowed_mutation_surface,
    "empty — no mutation surface was declared or derived; do not widen it yourself"));
  out.push("");
  out.push("### Artifact references");
  out.push("");
  const ar = Array.isArray(c.artifact_refs) ? c.artifact_refs : [];
  if (!ar.length) {
    out.push("_None._");
  } else {
    for (const a of ar) {
      out.push(`- **${esc(a.id)}** — ${esc(a.summary)}`);
      out.push(`  - sha256 \`${esc(a.sha256)}\` · ${esc(a.bytes)} bytes` +
               (Object.prototype.hasOwnProperty.call(a, "inline")
                 ? " · inlined below"
                 : ` · body withheld, request with \`need_artifact(${esc(a.id)})\``));
      if (Object.prototype.hasOwnProperty.call(a, "inline")) {
        out.push("");
        out.push("```");
        out.push(String(a.inline).replace(/\n+$/, ""));
        out.push("```");
      }
    }
  }
  out.push(E("SLOW"));
  out.push("");

  // --------------------------------------------------------- 3. VOLATILE --
  out.push(S("VOLATILE"));
  out.push(`## Task ${esc(c.task_id)}`);
  out.push("");
  out.push("### Objective");
  out.push("");
  out.push(esc(c.objective) || "_No objective was supplied._");
  out.push("");
  out.push("### Acceptance criteria");
  out.push("");
  out.push(list(c.acceptance, "none stated — this task has no written definition of done"));
  out.push("");
  out.push("### Measured baseline");
  out.push("");
  const b = c.baseline || {};
  out.push(`- targeted: ${esc(b.targeted ?? "not measured")}`);
  out.push(`- repo-wide: ${esc(b.repo_wide ?? "not measured")}`);
  out.push(`- measured at: ${esc(b.measured_at ?? "not measured")}`);
  out.push("");
  out.push("### Constraints (active prior decisions)");
  out.push("");
  out.push(list(c.constraints, "none matched this task's admitted files"));
  out.push("");
  out.push("### Failed approaches (durable facts, observed)");
  out.push("");
  out.push(list(c.failed_approaches, "none on record for this scope"));
  out.push("");
  out.push("### Verification");
  out.push("");
  const v = c.verification || {};
  out.push(list(v.commands, "no verification command was supplied — say so rather than inventing one"));
  out.push("");
  out.push(`expected: ${esc(v.expected ?? "not stated")}`);
  out.push("");
  out.push("### Authority");
  out.push("");
  const au = c.authority || {};
  out.push(`- class: \`${esc(au.mode ?? "direct")}\``);
  out.push(`- receipt: ${esc(au.receipt) || "_none declared_"}`);
  out.push("- external mutation (push / merge / deploy / publish / secrets): NOT authorized here.");
  out.push("");
  out.push("### Compilation accounting");
  out.push("");
  const bu = c.budget || {};
  out.push(`- compiled_at: ${esc(c.compiled_at ?? "not recorded")}`);
  out.push(`- byte budget: ${bu.bytes === null || bu.bytes === undefined ? "unbounded" : esc(bu.bytes)}` +
           ` · base ${esc(bu.base_bytes ?? "?")}B · spent on files ${esc(bu.spent_bytes ?? "?")}B`);
  out.push(`- candidates ${esc(bu.candidates_total ?? "?")} · admitted ${esc(bu.admitted ?? "?")}` +
           ` · dropped ${esc(bu.dropped ?? "?")}`);
  out.push(`- admission priority (fixed, not learned): ` +
           `${Array.isArray(bu.priority_order) ? bu.priority_order.join(" > ") : "not stated"}`);
  out.push("");
  out.push("### Provenance — withheld, and why");
  out.push("");
  const ex = (c.provenance && c.provenance.excluded_notable) || [];
  out.push(list(ex, "nothing was withheld"));
  out.push(E("VOLATILE"));
  out.push("");

  return out.join("\n");
}

// ------------------------------------------------------------------ CLI ----
function cli(argv) {
  let capsuleFile = null;
  let outFile = null;
  for (let i = 0; i < argv.length; i++) {
    const k = argv[i];
    if (k === "--capsule") capsuleFile = argv[++i];
    else if (k === "--out") outFile = argv[++i];
    else if (k === "-h" || k === "--help") {
      process.stdout.write("usage: render-capsule.mjs --capsule <capsule.json> [--out <file>]\n");
      return 0;
    } else {
      process.stderr.write(`render-capsule: unknown option: ${k}\n`);
      return 2;
    }
  }
  if (!capsuleFile) {
    process.stderr.write("render-capsule: --capsule is required\n");
    return 2;
  }
  let capsule;
  try {
    capsule = JSON.parse(fs.readFileSync(capsuleFile, "utf8"));
  } catch (e) {
    process.stderr.write(`render-capsule: cannot read capsule: ${e.message}\n`);
    return 2;
  }
  const md = renderCapsule(capsule);
  if (outFile) fs.writeFileSync(outFile, md, "utf8");
  else process.stdout.write(md);
  return 0;
}

const invoked = process.argv[1] &&
  fs.realpathSync(process.argv[1]) === fs.realpathSync(new URL(import.meta.url).pathname);
if (invoked) process.exit(cli(process.argv.slice(2)));
