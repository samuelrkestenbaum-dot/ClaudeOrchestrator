#!/usr/bin/env node
// FORWARD AND REVERSE, as one tool with one ledger.
//
// Attempt 1 had a forward migrator and no reverse at all — "reversible" was an
// inference from the ledger's columns, never an executed path. Keeping both
// directions in one file means the reversal cannot rot separately from the
// migration, and the round-trip test exercises the same code the real
// migration would use.
//
// Usage:
//   anchor-roundtrip.mjs --repo D --registry F --ledger F --version V --stamp S --forward
//   anchor-roundtrip.mjs --repo D --registry F --ledger F --version V --stamp S --reverse

import fs from "node:fs";
import { anchorFor, isAnchored } from "./anchor-resolve.mjs";
import { append, read, liveMappings, reversalRows } from "./anchor-ledger.mjs";

const arg = (n, d = null) => { const i = process.argv.indexOf(`--${n}`); return i > 0 && process.argv[i + 1] ? process.argv[i + 1] : d; };
const REPO = arg("repo", ".");
const REG = arg("registry");
const LED = arg("ledger");
const VER = arg("version", "v1");
const STAMP = arg("stamp", "-");
const FORWARD = process.argv.includes("--forward");
const REVERSE = process.argv.includes("--reverse");

if (!REG || !LED || (FORWARD === REVERSE)) {
  console.error("need --registry, --ledger, and exactly one of --forward / --reverse");
  process.exit(2);
}

const src = fs.readFileSync(REG, "utf8");
const lines = src.split("\n");

if (FORWARD) {
  const rows = [];
  let curId = null, migrated = 0, refused = 0, already = 0;
  for (let i = 0; i < lines.length; i++) {
    const idm = lines[i].match(/^id:\s*(\S+)/);
    if (idm) { curId = idm[1]; continue; }
    const em = lines[i].match(/^(evidence_refs:\s*)(.*)$/);
    if (!em) continue;
    const out = [];
    for (const raw of em[2].split(";")) {
      const ref = raw.trim();
      if (!ref) continue;
      if (isAnchored(ref)) { out.push(ref); already++; continue; }
      const m = ref.match(/^(.*):(\d+)$/);
      if (!m) { out.push(ref); continue; }
      const a = anchorFor(REPO, m[1], Number(m[2]));
      if (!a.ok) {
        out.push(ref);
        rows.push({ migration_version: VER, control_id: curId, old_ref: ref, new_ref: "-", status: "REFUSED",
                    provenance: a.reason, old_line: m[2], content: (a.content ?? "-").slice(0, 90), reviewed: "false", stamp: STAMP });
        refused++; continue;
      }
      out.push(a.ref);
      rows.push({ migration_version: VER, control_id: curId, old_ref: ref, new_ref: a.ref, status: "MIGRATED",
                  provenance: "mechanical_migration", old_line: m[2], content: a.content.slice(0, 90), reviewed: "false", stamp: STAMP });
      migrated++;
    }
    lines[i] = em[1] + out.join("; ");
  }
  fs.writeFileSync(REG, lines.join("\n"));
  append(rows, LED);
  console.log(JSON.stringify({ artifact: "anchor_forward", migrated, refused, already_anchored: already }, null, 2));
} else {
  // REVERSE reads the LIVE mapping — every MIGRATED row not already reversed —
  // computed by replaying an append-only log. That is why a redundant re-run of
  // the forward tool cannot destroy reversibility: it appends nothing, and the
  // replay is unchanged.
  const live = liveMappings(LED);
  let text = lines.join("\n");
  let reversed = 0;
  for (const r of live) {
    if (r.new_ref !== "-" && text.includes(r.new_ref)) { text = text.split(r.new_ref).join(r.old_ref); reversed++; }
  }
  fs.writeFileSync(REG, text);
  append(reversalRows(live.filter((r) => r.new_ref !== "-"), VER, STAMP), LED);
  console.log(JSON.stringify({ artifact: "anchor_reverse", reversed, live_before: live.length }, null, 2));
}
