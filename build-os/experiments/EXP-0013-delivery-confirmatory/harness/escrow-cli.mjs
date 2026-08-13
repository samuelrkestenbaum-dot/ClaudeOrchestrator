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
process.stdin.on("data", (c) => {
  if (process.stdin.isTTY && c === "") { process.stdout.write("\n"); process.exit(130); }
  _buf += c;
  let m;
  while ((m = _buf.match(/[\r\n]/))) {
    const line = _buf.slice(0, m.index); _buf = _buf.slice(m.index + 1);
    const r = _resolvers.shift(); if (r) r(line); else _lines.push(line);
  }
});
async function promptHidden(q) {
  process.stdout.write(q);
  if (process.stdin.isTTY) process.stdin.setRawMode(true);
  process.stdin.resume();
  const line = _lines.length ? Promise.resolve(_lines.shift()) : new Promise((r) => _resolvers.push(r));
  const ans = await line;
  if (process.stdin.isTTY) process.stdin.setRawMode(false);
  process.stdout.write("\n");
  return ans;
}

async function main() {
  const mode = process.argv[2];
  if (mode === "create") {
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
    if (pass !== pass2) { fs.rmSync(tmpPlain, { force: true }); console.log("REFUSED: passphrases differ"); process.exit(1); }
    const c = escrowCreate({ sealedPath: tmpPlain, passphrase: pass, outFile: OUT });
    if (!c.ok) { fs.rmSync(tmpPlain, { force: true }); console.log(`REFUSED: ${c.reason}`); process.exit(1); }
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
