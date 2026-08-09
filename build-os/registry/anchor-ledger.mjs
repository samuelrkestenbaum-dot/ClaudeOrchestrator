#!/usr/bin/env node
// THE APPEND-ONLY MIGRATION LEDGER.
//
// WHY APPEND-ONLY, IN ONE SENTENCE: attempt 1's ledger was rewritten on every
// run, so a re-migration that found nothing to do replaced it with a
// refusal-only file and destroyed the old->new mapping for 712 references —
// after its commit message had claimed the mapping was "reversible and
// auditable". That claim was made by reading the code. When the code was
// finally executed it reversed 0 of 0.
//
// So this module cannot overwrite. `append()` opens with the "a" flag and never
// truncates; there is no write path that replaces the file. A reversal APPENDS
// a REVERSED row rather than deleting the MIGRATED row it undoes, because a
// ledger that forgets what it undid cannot answer "what was this citation
// before?" — the only question a reversal makes urgent.

import fs from "node:fs";
import path from "node:path";

export const LEDGER = "build-os/registry/anchor_migration.tsv";
export const FIELDS = [
  "migration_version", "control_id", "old_ref", "new_ref",
  "status", "provenance", "old_line", "content", "reviewed", "stamp",
];
export const STATUSES = ["MIGRATED", "REFUSED", "REVERSED"];

const HEADER = [
  "# ANCHOR MIGRATION LEDGER — APPEND-ONLY.",
  "#",
  "# Attempt 1's ledger was OVERWRITTEN on every run. A re-migration that found",
  "# nothing to do replaced it with a refusal-only file, destroying the old->new",
  "# mapping for 712 references and making the migration unreversible. Nothing",
  "# here truncates: reversal appends a REVERSED row rather than deleting the",
  "# MIGRATED row it undoes.",
  "#",
  "# provenance=mechanical_migration means the FORM was converted and the",
  "# evidence was NOT re-read. reviewed stays false until a human reads the",
  "# citation and says it points at the right thing. No tool in this migration",
  "# may set reviewed=true: a script may convert a citation, it may not decide",
  "# the citation is correct.",
  "#",
  "# FIELDS: " + FIELDS.join("\t"),
].join("\n") + "\n";

/** Ensure the ledger exists with its header. Never truncates an existing file. */
export function ensure(file = LEDGER) {
  if (fs.existsSync(file)) return false;
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, HEADER);
  return true;
}

/**
 * Append rows. The ONLY write path, and it cannot replace prior content.
 * @param {Array<object>} rows  keyed by FIELDS
 */
export function append(rows, file = LEDGER) {
  if (!rows.length) return 0;
  ensure(file);
  for (const r of rows) {
    if (!STATUSES.includes(r.status)) throw new Error(`illegal ledger status: ${r.status}`);
    // The one value this module refuses to write. Enforced here rather than
    // trusted to every caller, because "the migration marked it reviewed" is
    // the exact laundering the contract forbids.
    if (String(r.reviewed) === "true") throw new Error("a migration may not record reviewed=true — form conversion is not review");
  }
  const body = rows.map((r) => FIELDS.map((f) => String(r[f] ?? "-").replace(/[\t\n]/g, " ")).join("\t")).join("\n") + "\n";
  fs.appendFileSync(file, body);   // "a" — never "w"
  return rows.length;
}

/** Read every row, in the order written. */
export function read(file = LEDGER) {
  let raw;
  try { raw = fs.readFileSync(file, "utf8"); } catch { return []; }
  return raw.split("\n").filter((l) => l.trim() && !l.startsWith("#"))
    .map((l) => Object.fromEntries(FIELDS.map((f, i) => [f, l.split("\t")[i] ?? "-"])));
}

/**
 * The live mapping: every MIGRATED row not subsequently REVERSED.
 * Computed by replay rather than by mutation, which is what append-only buys.
 */
export function liveMappings(file = LEDGER) {
  const rows = read(file);
  const live = new Map();
  for (const r of rows) {
    // Keyed by the ANCHORED ref throughout. A REVERSED row carries the anchor
    // in old_ref (it is the source of that reversal) and the positional form in
    // new_ref (the destination), so deleting by new_ref removed nothing and the
    // mapping never cleared. Caught by the ledger's own round-trip assertion.
    if (r.status === "MIGRATED") live.set(r.new_ref, r);
    else if (r.status === "REVERSED") live.delete(r.old_ref);
  }
  return [...live.values()];
}

/** Rows describing a reversal of the given migrated rows. */
export function reversalRows(migrated, version, stamp = "-") {
  return migrated.map((r) => ({
    migration_version: version,
    control_id: r.control_id,
    old_ref: r.new_ref,          // reversing: the anchored form becomes the source
    new_ref: r.old_ref,          // ...and the positional form the destination
    status: "REVERSED",
    provenance: "mechanical_reversal",
    old_line: r.old_line,
    content: r.content,
    reviewed: "false",
    stamp,
  }));
}
