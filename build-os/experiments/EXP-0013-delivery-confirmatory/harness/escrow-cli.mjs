#!/usr/bin/env node
// MAPPING-ESCROW CLI (AMENDMENT v4 — prepared, NOT executed in this leg).
//
// The owner runs this locally, after publication, on this machine:
//   node harness/escrow-cli.mjs create   — prompts for a passphrase with
//     echo DISABLED (nothing appears on screen, nothing lands in shell
//     history or chat), encrypts the sealed stores (scrypt + AES-256-GCM)
//     into corpus/mapping-escrow.json (ciphertext only — safe to commit),
//     immediately proves decryptability by round-tripping to a tmp file and
//     comparing bytes WITHOUT printing any label, then prints ONLY the
//     ciphertext digest for the repo record.
//   node harness/escrow-cli.mjs check    — re-proves decryptability later
//     (same no-echo prompt), printing ok/typed-refusal only.
// The passphrase is never stored, never transmitted, never echoed; wrong
// key, tampered ciphertext and weak passphrases are typed refusals
// (mapping-escrow.mjs, red-team-tested on synthetic mappings).
import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import crypto from "node:crypto";
import { escrowCreate, escrowRecover } from "./mapping-escrow.mjs";
import { SEALED_DIR } from "./seal-orders.mjs";

const HERE = path.dirname(new URL(import.meta.url).pathname);
const OUT = path.join(HERE, "..", "corpus", "mapping-escrow.json");
const sha = (b) => crypto.createHash("sha256").update(b).digest("hex");

// Hidden line reader. On a TTY, raw mode is enabled for the read: the
// terminal never echoes a character (no readline, no control-sequence
// games) and Ctrl-C still aborts. On a pipe (the release suite's synthetic
// rehearsal), lines are consumed from stdin without any echo. In both
// paths the passphrase exists only in process memory — never in argv, env,
// history, or any file.
process.stdin.setEncoding("utf8");
const _lines = []; const _resolvers = []; let _buf = "";
const restoreTty = () => { try { if (process.stdin.isTTY) process.stdin.setRawMode(false); } catch {} };
process.on("exit", restoreTty); // v6 (review F2): NEVER leave the owner's terminal in raw mode
let _eof = false;
process.stdin.on("data", (c) => {
  if (process.stdin.isTTY && c === "") { restoreTty(); process.stdout.write("\n"); process.exit(130); }
  _buf += c;
  let m;
  while ((m = _buf.match(/[\r\n]/))) {
    const line = _buf.slice(0, m.index); _buf = _buf.slice(m.index + 1);
    const r = _resolvers.shift(); if (r) r(line); else _lines.push(line);
  }
});
// v6 (review F2): stdin EOF previously let the event loop drain and the
// process exit 0 as a silent no-op "success". EOF now resolves every
// pending prompt with null, which callers treat as a typed refusal.
process.stdin.on("end", () => { _eof = true; while (_resolvers.length) _resolvers.shift()(null); });
async function promptHidden(q) {
  process.stdout.write(q);
  if (process.stdin.isTTY) process.stdin.setRawMode(true);
  process.stdin.resume();
  const ans = _lines.length ? _lines.shift() : (_eof ? null : await new Promise((r) => _resolvers.push(r)));
  restoreTty();
  process.stdout.write("\n");
  return ans;
}

async function main() {
  const mode = process.argv[2];
  // v6 (review F2): piped secrets can leak through shell history and process
  // plumbing. Real (owner) mode REQUIRES a TTY; non-TTY stdin is refused
  // unless the explicit synthetic-test adapter env is set (test suites only,
  // synthetic passphrases only).
  if (!process.stdin.isTTY && process.env.EXP0013_ESCROW_TEST_STDIN !== "1") {
    console.log("REFUSED: NON_TTY_STDIN — real escrow requires an interactive terminal; piped secrets can leak via shell history. (Tests set EXP0013_ESCROW_TEST_STDIN=1 with SYNTHETIC passphrases only.)");
    process.exit(1);
  }
  if (mode === "create") {
    if (fs.existsSync(OUT)) {
      console.log("REFUSED: ESCROW_ARTIFACT_ALREADY_EXISTS — refusing to overwrite a live escrow; delete it deliberately first if you intend to re-escrow.");
      process.exit(1);
    }
    // Bundle BOTH sealed stores (orders + rerun orders) into one plaintext.
    const bundle = {};
    for (const f of ["orders.json", "rerun-orders.json"]) {
      const p = path.join(SEALED_DIR, f);
      if (!fs.existsSync(p)) { console.log(`REFUSED: sealed store missing: ${f} — a fresh disclosed draw is required first`); process.exit(1); }
      bundle[f] = fs.readFileSync(p, "utf8");
    }
    const tmpPlain = path.join(os.tmpdir(), `escrow-src-${process.pid}.json`);
    fs.writeFileSync(tmpPlain, JSON.stringify(bundle), { mode: 0o600 });
    const pass = await promptHidden("Escrow passphrase (min 12 chars, echo disabled): ");
    const pass2 = await promptHidden("Repeat passphrase: ");
    if (pass === null || pass2 === null) { fs.rmSync(tmpPlain, { force: true }); console.log("REFUSED: STDIN_EOF before both passphrase entries"); process.exit(1); }
    if (pass !== pass2) { fs.rmSync(tmpPlain, { force: true }); console.log("REFUSED: passphrases differ"); process.exit(1); }
    // v6 (review F2): atomic create — write to a tmp name, rename into place;
    // an interrupted run can never leave a partial file at the real path.
    const OUT_TMP = OUT + `.tmp.${process.pid}`;
    const c = escrowCreate({ sealedPath: tmpPlain, passphrase: pass, outFile: OUT_TMP });
    if (!c.ok) { fs.rmSync(tmpPlain, { force: true }); fs.rmSync(OUT_TMP, { force: true }); console.log(`REFUSED: ${c.reason}`); process.exit(1); }
    fs.renameSync(OUT_TMP, OUT); fs.chmodSync(OUT, 0o644); // ciphertext is publish-safe by design
    // Decryptability proof WITHOUT revealing any label:
    const tmpRec = path.join(os.tmpdir(), `escrow-chk-${process.pid}.json`);
    const r = escrowRecover({ escrowFile: OUT, passphrase: pass, outPath: tmpRec });
    const same = r.ok && sha(fs.readFileSync(tmpPlain)) === sha(fs.readFileSync(tmpRec));
    fs.rmSync(tmpPlain, { force: true }); fs.rmSync(tmpRec, { force: true });
    if (!same) { console.log("REFUSED: decryptability check failed"); process.exit(1); }
    console.log(`escrow created: ${path.relative(process.cwd(), OUT)}`);
    console.log(`ciphertext sha256: ${sha(fs.readFileSync(OUT))}`);
    console.log("decryptability: PROVEN (byte-identical round trip; no labels printed)");
  } else if (mode === "check") {
    const pass = await promptHidden("Escrow passphrase (echo disabled): ");
    const tmpRec = path.join(os.tmpdir(), `escrow-chk-${process.pid}.json`);
    const r = escrowRecover({ escrowFile: OUT, passphrase: pass, outPath: tmpRec });
    fs.rmSync(tmpRec, { force: true });
    console.log(r.ok ? "decryptability: OK" : `REFUSED: ${r.reason}`);
    process.exit(r.ok ? 0 : 1);
  } else { console.log("usage: escrow-cli.mjs create|check"); process.exit(1); }
  process.exit(0);
}
main();
