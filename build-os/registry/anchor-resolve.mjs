#!/usr/bin/env node
// CONTENT-ANCHORED EVIDENCE REFERENCES.
//
// THE DEBT THIS PAYS. `evidence_refs` were `path:line`. A line number is a
// position, and positions move: inserting four chain_suite calls into
// build_os_tests.sh silently turned two citations into references pointing at
// comments, and adding a census exemption to three suites turned five more.
// VACUOUS-REF went 6 -> 11 during a session whose subject was assurance. The
// guard was not detecting a problem; it WAS the problem, decaying whenever
// anything above it moved.
//
// THE DISTINCTION THAT MATTERS, and the whole point of the migration:
//
//   IRRELEVANT MOVEMENT  — text is inserted or deleted elsewhere in the file.
//                          The evidence is untouched. The citation must SURVIVE.
//   RELEVANT CHANGE      — the cited text itself is edited or removed.
//                          The evidentiary basis is gone. The citation must GO
//                          STALE, loudly.
//
// A line number cannot tell those apart: it breaks on the first and silently
// keeps resolving-to-something on the second. A content anchor separates them
// exactly.
//
// FORM: `path#c:<12 hex>` where the hex is sha256 of the cited line with
// leading and trailing whitespace stripped. Hex rather than the literal text
// because refs are whitespace-separated in the registry, so an anchor may not
// contain spaces. The human-readable content is preserved in the migration
// ledger, which is what makes a stale anchor diagnosable rather than opaque.
//
// AMBIGUITY IS A REFUSAL, NOT A GUESS. Content occurring more than once names
// no single object, so it does not identify evidence. Such a citation cannot be
// migrated mechanically and is recorded as requiring authorship — never
// resolved to "the first match", which would be inventing a fact.

import fs from "node:fs";
import crypto from "node:crypto";
import path from "node:path";

export const ANCHOR_PREFIX = "#c:";
export const HEX_LEN = 12;

export const contentHash = (line) =>
  crypto.createHash("sha256").update(String(line).trim()).digest("hex").slice(0, HEX_LEN);

/** Is this ref the anchored form? */
export const isAnchored = (ref) => String(ref).includes(ANCHOR_PREFIX);

export function splitRef(ref) {
  const i = String(ref).indexOf(ANCHOR_PREFIX);
  return i < 0 ? null : { file: ref.slice(0, i), hex: ref.slice(i + ANCHOR_PREFIX.length) };
}

/**
 * Resolve one anchored ref against the tree.
 * @returns {object} { status, line, content, matches }
 *   RESOLVED    exactly one line carries the anchored content
 *   AMBIGUOUS   more than one — names no single object
 *   STALE       none — the cited text is gone or was edited
 *   NO_FILE     the artifact itself is missing
 */
export function resolveAnchor(repo, ref) {
  const parts = splitRef(ref);
  if (!parts) return { status: "NOT_ANCHORED", line: null, matches: 0 };
  const abs = path.join(repo, parts.file);
  let lines;
  try { lines = fs.readFileSync(abs, "utf8").split("\n"); }
  catch { return { status: "NO_FILE", line: null, matches: 0, file: parts.file }; }

  const hits = [];
  for (let i = 0; i < lines.length; i++) {
    if (lines[i].trim() === "") continue;
    if (contentHash(lines[i]) === parts.hex) hits.push(i + 1);
  }
  if (hits.length === 1) return { status: "RESOLVED", line: hits[0], content: lines[hits[0] - 1].trim(), matches: 1, file: parts.file };
  if (hits.length > 1) return { status: "AMBIGUOUS", line: null, matches: hits.length, lines: hits, file: parts.file };
  return { status: "STALE", line: null, matches: 0, file: parts.file };
}

/** Compute the anchor for a path:line ref, reporting why it cannot be migrated. */
export function anchorFor(repo, file, line) {
  const abs = path.join(repo, file);
  let lines;
  try { lines = fs.readFileSync(abs, "utf8").split("\n"); }
  catch { return { ok: false, reason: "NO_FILE" }; }
  if (line < 1 || line > lines.length) return { ok: false, reason: "OUT_OF_RANGE" };
  const content = lines[line - 1];
  if (content.trim() === "") return { ok: false, reason: "BLANK_LINE" };
  const hex = contentHash(content);
  const dupes = lines.filter((l) => l.trim() !== "" && contentHash(l) === hex).length;
  // Refusing here is the load-bearing part. Migrating an ambiguous citation to
  // "whichever line matched first" would convert an honest positional
  // reference into a confident content reference that names the wrong object.
  if (dupes > 1) return { ok: false, reason: "AMBIGUOUS_CONTENT", occurrences: dupes, content: content.trim() };
  return { ok: true, ref: `${file}${ANCHOR_PREFIX}${hex}`, hex, content: content.trim() };
}

// CLI: resolve refs given on argv, one verdict per line, for shell callers.
if (import.meta.url === `file://${process.argv[1]}`) {
  const repo = process.argv[2] || ".";
  for (const ref of process.argv.slice(3)) {
    const r = resolveAnchor(repo, ref);
    console.log([ref, r.status, r.line ?? "-", r.matches].join("\t"));
  }
}
