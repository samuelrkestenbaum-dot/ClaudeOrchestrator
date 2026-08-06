#!/usr/bin/env node
// Context compiler — CAPSULE SIZE ACCOUNTING.
//
//   capsule-stats.mjs --capsule <capsule.json> [--md <capsule.md>] [--json]
//
// Answers "what did this capsule actually cost, and where did the bytes go?"
// broken down by SEAM 5 segment, so the cache-stable prefix can be measured
// separately from the volatile tail it exists to protect.
//
// TIERING IS BINDING (build-os/memory/provider_adapter_contract.md):
//
//   EXACT       — counted here. Byte counts and item counts are exact: this
//                 tool reads the bytes and counts the items itself.
//   ESTIMATE    — a derived proxy. The token figure is characters/4. It is
//                 NOT a tokenizer, it is NOT billing truth, and it is never
//                 labeled EXACT. A proxy that presents as exact is a lie, and
//                 the one this repo already refuses to tell.
//   CLOSE-TIME  — reconcilable from provider telemetry after a run.
//   UNAVAILABLE — not visible on this surface.
//
// Only the first two occur here; real token counts are CLOSE-TIME at best and
// this tool does not pretend otherwise.
//
// Dependencies: node stdlib only.

import fs from "node:fs";

const PROXY_FORMULA = "chars/4";
const PROXY_NOTE = "chars/4 proxy, not billing truth";

const bytesOf = (s) => Buffer.byteLength(s, "utf8");
const proxyTokens = (s) => Math.ceil(s.length / 4);

// Text strictly between the SEAM 5 sentinels; "" when the section is absent.
function section(md, name) {
  const s = md.indexOf(`<!-- CAPSULE:${name}:START -->`);
  const e = md.indexOf(`<!-- CAPSULE:${name}:END -->`);
  if (s < 0 || e < 0 || e < s) return "";
  return md.slice(s + `<!-- CAPSULE:${name}:START -->`.length, e);
}

function collect(capsuleFile, mdFile) {
  const jsonText = fs.readFileSync(capsuleFile, "utf8");
  const c = JSON.parse(jsonText);

  const counts = {
    admitted_files: Array.isArray(c.relevant_files) ? c.relevant_files.length : 0,
    excluded_notable: (c.provenance && Array.isArray(c.provenance.excluded_notable))
      ? c.provenance.excluded_notable.length : 0,
    dependency_neighborhood: Array.isArray(c.dependency_neighborhood) ? c.dependency_neighborhood.length : 0,
    constraints: Array.isArray(c.constraints) ? c.constraints.length : 0,
    failed_approaches: Array.isArray(c.failed_approaches) ? c.failed_approaches.length : 0,
    acceptance: Array.isArray(c.acceptance) ? c.acceptance.length : 0,
    artifact_refs: Array.isArray(c.artifact_refs) ? c.artifact_refs.length : 0,
  };

  // Per-field byte cost of capsule.json — where the structured budget went.
  const fieldBytes = {};
  for (const k of Object.keys(c).sort()) fieldBytes[k] = bytesOf(JSON.stringify(c[k]));

  let md = null;
  const sections = {};
  if (mdFile) {
    md = fs.readFileSync(mdFile, "utf8");
    for (const name of ["PREFIX", "SLOW", "VOLATILE"]) sections[name] = section(md, name);
  }

  return { capsule: c, jsonText, md, counts, fieldBytes, sections };
}

function toReport(d) {
  const { capsule: c, jsonText, md, counts, fieldBytes, sections } = d;
  const rep = {
    task_id: c.task_id ?? "(unnamed)",
    tier_legend: {
      EXACT: "counted directly by this tool",
      ESTIMATE: "a derived proxy; never billing truth",
    },
    counts: Object.fromEntries(Object.entries(counts).map(([k, v]) => [k, { value: v, tier: "EXACT" }])),
    bytes: {
      capsule_json_total: { value: bytesOf(jsonText), tier: "EXACT" },
      by_field: Object.fromEntries(Object.entries(fieldBytes).map(([k, v]) => [k, { value: v, tier: "EXACT" }])),
    },
    token_proxy: {
      tier: "ESTIMATE",
      formula: PROXY_FORMULA,
      note: PROXY_NOTE,
      estimated_tokens_json: proxyTokens(jsonText),
    },
  };
  if (md !== null) {
    rep.bytes.capsule_md_total = { value: bytesOf(md), tier: "EXACT" };
    rep.bytes.sections = {
      prefix_bytes: { value: bytesOf(sections.PREFIX || ""), tier: "EXACT" },
      slow_bytes: { value: bytesOf(sections.SLOW || ""), tier: "EXACT" },
      volatile_bytes: { value: bytesOf(sections.VOLATILE || ""), tier: "EXACT" },
    };
    rep.token_proxy.estimated_tokens_md = proxyTokens(md);
    rep.token_proxy.estimated_tokens_prefix = proxyTokens(sections.PREFIX || "");
    rep.token_proxy.estimated_tokens_volatile = proxyTokens(sections.VOLATILE || "");
    // The cache economics in one number: how much of the rendered capsule is
    // the reusable prefix. High is good; it is the part a cache can keep.
    const total = bytesOf(md) || 1;
    rep.bytes.prefix_share_pct = {
      value: Math.round((bytesOf(sections.PREFIX || "") / total) * 1000) / 10,
      tier: "EXACT",
    };
  }
  return rep;
}

const pad = (k) => k.padEnd(30, " ");
const num = (v) => String(v).padStart(8, " ");

function toText(rep) {
  const L = [];
  L.push(`capsule-stats — ${rep.task_id}`);
  L.push(`tiers: EXACT = ${rep.tier_legend.EXACT}; ESTIMATE = ${rep.tier_legend.ESTIMATE}`);
  L.push("");
  L.push("== counts ==");
  for (const [k, o] of Object.entries(rep.counts)) L.push(`${pad(k)}${num(o.value)}   ${o.tier}`);
  L.push("");
  L.push("== bytes: capsule.json ==");
  L.push(`${pad("capsule_json_total")}${num(rep.bytes.capsule_json_total.value)}   EXACT`);
  for (const [k, o] of Object.entries(rep.bytes.by_field)) L.push(`${pad("  field " + k)}${num(o.value)}   ${o.tier}`);
  if (rep.bytes.sections) {
    L.push("");
    L.push("== bytes: capsule.md sections (SEAM 5 order) ==");
    L.push(`${pad("prefix_bytes")}${num(rep.bytes.sections.prefix_bytes.value)}   EXACT`);
    L.push(`${pad("slow_bytes")}${num(rep.bytes.sections.slow_bytes.value)}   EXACT`);
    L.push(`${pad("volatile_bytes")}${num(rep.bytes.sections.volatile_bytes.value)}   EXACT`);
    L.push(`${pad("capsule_md_total")}${num(rep.bytes.capsule_md_total.value)}   EXACT`);
    L.push(`${pad("prefix_share_pct")}${num(rep.bytes.prefix_share_pct.value)}   EXACT`);
  }
  L.push("");
  L.push("== token proxy — ESTIMATE tier only ==");
  const t = rep.token_proxy;
  for (const k of Object.keys(t)) {
    if (!k.startsWith("estimated_tokens")) continue;
    L.push(`${pad(k)}${num(t[k])}   ESTIMATE (${t.note})`);
  }
  L.push("");
  L.push(`token figures above are a ${t.formula} PROXY. They are not a tokenizer's`);
  L.push("output and not billing truth; real token cost is CLOSE-TIME at best.");
  return L.join("\n") + "\n";
}

function cli(argv) {
  let capsuleFile = null, mdFile = null, asJson = false;
  for (let i = 0; i < argv.length; i++) {
    const k = argv[i];
    if (k === "--capsule") capsuleFile = argv[++i];
    else if (k === "--md") mdFile = argv[++i];
    else if (k === "--json") asJson = true;
    else if (k === "-h" || k === "--help") {
      process.stdout.write("usage: capsule-stats.mjs --capsule <capsule.json> [--md <capsule.md>] [--json]\n");
      return 0;
    } else {
      process.stderr.write(`capsule-stats: unknown option: ${k}\n`);
      return 2;
    }
  }
  if (!capsuleFile) {
    process.stderr.write("capsule-stats: --capsule is required\n");
    return 2;
  }
  let rep;
  try {
    rep = toReport(collect(capsuleFile, mdFile));
  } catch (e) {
    process.stderr.write(`capsule-stats: ${e.message}\n`);
    return 2;
  }
  process.stdout.write(asJson ? JSON.stringify(rep, null, 2) + "\n" : toText(rep));
  return 0;
}

const invoked = process.argv[1] &&
  fs.realpathSync(process.argv[1]) === fs.realpathSync(new URL(import.meta.url).pathname);
if (invoked) process.exit(cli(process.argv.slice(2)));
