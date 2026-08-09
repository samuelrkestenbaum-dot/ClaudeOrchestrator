#!/usr/bin/env node
// MIGRATE evidence_refs from `path:line` to `path#c:<hex>`.
//
// THE RULE THE OPERATOR SET, and the one thing that makes this a migration
// rather than a rewrite: DO NOT SILENTLY RE-AUTHORIZE HISTORICAL EVIDENCE.
// Converting a citation's FORM is a mechanical act. Deciding that a citation
// points at the right thing is a REVIEW, and this tool performs the first and
// records that it has not performed the second.
//
// Every migrated ref therefore lands in the ledger as
// `provenance=mechanical_migration, reviewed=false`, carrying the literal line
// content it was pinned to and the line number it came from. Nothing here
// upgrades to `reviewed=true`; that requires a human reading the evidence, and
// the distinction stays visible instead of being laundered by the conversion.
//
// WHAT IT REFUSES. A citation whose content occurs more than once cannot be
// migrated: content naming two lines identifies no object. It is recorded as
// AMBIGUOUS_CONTENT and LEFT IN POSITIONAL FORM rather than resolved to the
// first match. Same for a citation already pointing at nothing — a stale
// positional ref migrated by content would silently anchor to whatever now
// occupies that line, which is exactly the class of error the migration exists
// to end.
//
// Usage: migrate-anchors.mjs --registry <f> --repo <d> [--apply] [--ledger <f>]

import fs from "node:fs";
import { anchorFor, isAnchored } from "./anchor-resolve.mjs";

const arg = (n, d = null) => { const i = process.argv.indexOf(`--${n}`); return i > 0 && process.argv[i + 1] ? process.argv[i + 1] : d; };
const APPLY = process.argv.includes("--apply");
const REG = arg("registry", "build-os/registry/control_registry.txt");
const REPO = arg("repo", ".");
const LEDGER = arg("ledger", "build-os/registry/anchor_migration.tsv");
const STAMP = arg("stamp", "-");   // supplied, never read from the clock

const src = fs.readFileSync(REG, "utf8");
const lines = src.split("\n");

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
    if (!m) { out.push(ref); rows.push([curId, ref, "-", "REFUSED", "NOT_POSITIONAL", "-", "-"]); refused++; continue; }
    const [, file, lineNo] = m;
    const a = anchorFor(REPO, file, Number(lineNo));
    if (!a.ok) {
      // LEFT AS-IS, deliberately. An un-migratable citation stays visibly
      // positional so it appears in the backlog rather than becoming a
      // confident anchor pointing somewhere nobody checked.
      out.push(ref);
      rows.push([curId, ref, "-", "REFUSED", a.reason, String(a.occurrences ?? "-"), (a.content ?? "-").slice(0, 90)]);
      refused++;
      continue;
    }
    out.push(a.ref);
    rows.push([curId, ref, a.ref, "MIGRATED", "mechanical_migration", lineNo, a.content.slice(0, 90)]);
    migrated++;
  }
  lines[i] = em[1] + out.join("; ");
}

const header = [
  "# ANCHOR MIGRATION LEDGER — old positional ref -> content anchor.",
  "#",
  "# provenance=mechanical_migration means the FORM was converted and the",
  "# evidence was NOT re-reviewed. reviewed stays false until a human reads the",
  "# citation and says it points at the right thing. A migration that silently",
  "# set reviewed=true would be re-authorising historical evidence by script,",
  "# which is the one thing this migration was told not to do.",
  "#",
  "# REFUSED rows were left in positional form on purpose: AMBIGUOUS_CONTENT",
  "# names more than one line and so identifies no object; OUT_OF_RANGE and",
  "# BLANK_LINE were already broken before the migration and anchoring them",
  "# would pin them to whatever happens to sit there now.",
  "#",
  "# FIELDS: control_id\told_ref\tnew_ref\tstatus\tprovenance\told_line\tcontent\treviewed\tmigrated_at",
].join("\n");

const body = rows.map((r) => [...r, "false", STAMP].join("\t")).join("\n");
const ledger = header + "\n" + body + "\n";

if (APPLY) {
  fs.writeFileSync(REG, lines.join("\n"));
  fs.writeFileSync(LEDGER, ledger);
}

console.log(JSON.stringify({
  artifact: "anchor_migration",
  applied: APPLY,
  migrated, refused, already_anchored: already,
  refusal_reasons: rows.filter((r) => r[3] === "REFUSED")
    .reduce((o, r) => { o[r[4]] = (o[r[4]] || 0) + 1; return o; }, {}),
  note: "MIGRATED rows converted FORM only. reviewed=false on every row — no historical evidence was re-authorised.",
}, null, 2));
