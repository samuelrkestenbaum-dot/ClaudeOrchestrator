// Pin the guarded-source fingerprint for checks whose mutation was JUST RUN.
// Run this ONLY after actually executing the mutation, never to make a report
// look better: pinning without re-running converts a real shelf-life signal
// into a rubber stamp.
import fs from "node:fs";
import { CHECKS, fingerprint } from "./checks.mjs";
const only = new Set(process.argv.slice(2));
let pins = {};
try { pins = JSON.parse(fs.readFileSync("build-os/audit/proofs.json", "utf8")); } catch {}
for (const c of CHECKS) {
  if (c.proof_taken_at !== "SELF") continue;
  if (only.size && !only.has(c.id)) continue;
  pins[c.id] = fingerprint(c.guarded_source);
}
fs.writeFileSync("build-os/audit/proofs.json", JSON.stringify(pins, null, 2) + "\n");
console.log(`pinned ${Object.keys(pins).length} proof fingerprints`);
