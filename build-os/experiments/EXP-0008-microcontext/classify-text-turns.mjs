import fs from "node:fs";
import { CLASSES, classifyCorpus } from "/home/user/ClaudeOrchestrator/build-os/experiments/EXP-0008-microcontext/text-turn-classes.mjs";
const turns = fs.readFileSync(process.argv[2], "utf8").split("\n").filter(Boolean).map(JSON.parse);
const cl = classifyCorpus(turns);
const armsOf = (g) => new Set(cl.filter((t) => t.group === g).map((t) => t.arm)).size;
const N = { native: armsOf("native"), corrected: armsOf("corrected") };

const per = (g, k, f) => cl.filter((t) => t.group === g && t.cls === k).reduce((a, t) => a + f(t), 0) / N[g];

console.log(`=== TEXT-ONLY TURNS BY CLASS (per arm) — native n=${N.native}, corrected n=${N.corrected} ===\n`);
console.log("class".padEnd(26) + "native".padStart(8) + "corrected".padStart(11) + "EXCESS".padStart(9) + "  share of excess");
const rows = CLASSES.map((k) => {
  const nv = per("native", k, () => 1), co = per("corrected", k, () => 1);
  return { k, nv, co, ex: co - nv };
});
const totalEx = rows.reduce((a, r) => a + r.ex, 0);
for (const r of rows.slice().sort((a, b) => b.ex - a.ex)) {
  const share = totalEx > 0 ? (r.ex / totalEx * 100) : 0;
  console.log(r.k.padEnd(26) + r.nv.toFixed(2).padStart(8) + r.co.toFixed(2).padStart(11) +
    (r.ex >= 0 ? "+" : "") + r.ex.toFixed(2).padStart(8) + "  " +
    (r.ex > 0 ? `${share.toFixed(0)}%  ${"#".repeat(Math.round(share / 2))}` : ""));
}
console.log("".padEnd(26) + per("native", "x", () => 1).toFixed(2).padStart(0));
const tot = (g) => cl.filter((t) => t.group === g).length / N[g];
console.log("TOTAL".padEnd(26) + tot("native").toFixed(2).padStart(8) + tot("corrected").toFixed(2).padStart(11) +
  "+" + (tot("corrected") - tot("native")).toFixed(2).padStart(8));

console.log(`\n=== OUTPUT VOLUME BY CLASS (chars per arm) ===\n`);
console.log("class".padEnd(26) + "native".padStart(10) + "corrected".padStart(12) + "EXCESS".padStart(10));
for (const k of CLASSES) {
  const nv = per("native", k, (t) => t.chars), co = per("corrected", k, (t) => t.chars);
  if (!nv && !co) continue;
  console.log(k.padEnd(26) + Math.round(nv).toString().padStart(10) + Math.round(co).toString().padStart(12) +
    ((co - nv) >= 0 ? "+" : "") + Math.round(co - nv).toString().padStart(9));
}
const totC = (g) => cl.filter((t) => t.group === g).reduce((a, t) => a + t.chars, 0) / N[g];
console.log("TOTAL".padEnd(26) + Math.round(totC("native")).toString().padStart(10) + Math.round(totC("corrected")).toString().padStart(12) +
  "+" + Math.round(totC("corrected") - totC("native")).toString().padStart(9));

console.log(`\n=== FINAL REPORTS PER ARM (the re-summarisation tax) ===\n`);
for (const g of ["native", "corrected"]) {
  const byArm = {};
  for (const t of cl.filter((x) => x.group === g && x.cls === "final_report")) byArm[t.arm] = (byArm[t.arm] || 0) + 1;
  const arms = [...new Set(cl.filter((x) => x.group === g).map((x) => x.arm))];
  const counts = arms.map((a) => byArm[a] || 0);
  console.log(`${g.padEnd(11)} ${counts.join(" ")}   mean ${(counts.reduce((a, b) => a + b, 0) / counts.length).toFixed(2)}/arm  range ${Math.min(...counts)}-${Math.max(...counts)}`);
}

fs.writeFileSync(process.argv[3], cl.map((t) => JSON.stringify(t)).join("\n") + "\n");
