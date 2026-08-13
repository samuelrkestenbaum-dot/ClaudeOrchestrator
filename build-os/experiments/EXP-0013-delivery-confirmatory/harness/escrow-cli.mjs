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
import readline from "node:readline";
import crypto from "node:crypto";
import { escrowCreate, escrowRecover } from "./mapping-escrow.mjs";
import { SEALED_DIR } from "./seal-orders.mjs";

const HERE = path.dirname(new URL(import.meta.url).pathname);
const OUT = path.join(HERE, "..", "corpus", "mapping-escrow.json");
const sha = (b) => crypto.createHash("sha256").update(b).digest("hex");

function promptHidden(q) {
  return new Promise((resolve) => {
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout, terminal: true });
    const onData = (ch) => { if (!["\n", "\r"].includes(String(ch))) readline.moveCursor(process.stdout, -1, 0), process.stdout.write("*".repeat(0)); };
    process.stdout.write(q);
    // Mute echo: intercept output writes while the question is answered.
    const mutable = rl.output;
    rl._writeToOutput = () => {}; // suppress every echo, including the typed chars
    rl.question("", (ans) => { rl.close(); process.stdout.write("\n"); resolve(ans); });
    void onData; void mutable;
  });
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
}
main();
