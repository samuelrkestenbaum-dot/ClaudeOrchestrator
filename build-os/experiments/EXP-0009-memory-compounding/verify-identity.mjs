#!/usr/bin/env node
// EXP-0009 — IDENTITY-UNIFORMITY VERIFIER for the mid-run orchestration
// disclosure (MID-RUN-INTERVENTION.md). Precommitted criterion, checked
// mechanically here: the intervention is benign IF AND ONLY IF per-arm
// identity evidence is uniform across the 19:51:50Z attachment boundary.
// Any deviating cell is named for quarantine; silence is never the proof.
import fs from "node:fs";
import path from "node:path";
const HERE = path.dirname(new URL(import.meta.url).pathname);
const RUNS = path.join(HERE, "results/runs");
const BOUNDARY = Date.parse("2026-08-11T19:51:50Z");
const j = (p) => { try { return JSON.parse(fs.readFileSync(p, "utf8")); } catch { return null; } };

const cells = [];
for (const d of fs.readdirSync(RUNS)) {
  if (!/^[AB][1-5]\.(native|leanmem)\.r\d+$/.test(d)) continue; // preserved partials excluded by name
  const v = j(path.join(RUNS, d, "variant.json"));
  const rr = j(path.join(RUNS, d, "run-record.json"));
  if (!v || !rr) continue;
  cells.push({
    d, era: Date.parse(rr.launched_at) < BOUNDARY ? "pre" : "post",
    admissible: rr.admissible === true,
    seqpos: `${v.sequence}${v.position}`, config: v.config,
    promptSha: v.prompt_sha256_16,
    pin: v.source_identity?.resolved_commit || "(native)",
    verification: v.verification, permission: v.permission_mode,
    allowed: JSON.stringify(v.allowed_tools), timeouts: JSON.stringify(v.bash_timeouts),
  });
}

let fails = 0;
const fail = (m) => { console.log(`FAIL ${m}`); fails++; };
const ok = (m) => console.log(`ok   ${m}`);

// 1. Prompt identity per position — across configs, reps, AND eras.
const byPos = {};
for (const c of cells) (byPos[c.seqpos] ||= new Set()).add(c.promptSha);
const badPos = Object.entries(byPos).filter(([, s]) => s.size > 1);
badPos.length ? fail(`prompt sha differs within position(s): ${badPos.map(([k, s]) => `${k}:${[...s].join("/")}`).join(", ")}`)
  : ok(`prompt sha uniform within every position (${Object.keys(byPos).length} positions)`);

// 2. Leanmem pin — one resolved commit everywhere, both eras.
const pins = new Set(cells.filter((c) => c.config === "leanmem").map((c) => c.pin));
pins.size === 1 ? ok(`leanmem pin uniform: ${[...pins][0].slice(0, 12)}`) : fail(`leanmem pins differ: ${[...pins].join(", ")}`);

// 3. Environment fields uniform across every cell.
for (const f of ["verification", "permission", "allowed", "timeouts"]) {
  const s = new Set(cells.map((c) => c[f]));
  s.size === 1 ? ok(`${f} uniform: ${String([...s][0]).slice(0, 60)}`) : fail(`${f} differs across cells: ${[...s].join(" | ")}`);
}

// 4. Era-vs-era: for every field above, the post-era value set must equal the
// pre-era value set (a uniform drift in ALL cells would pass 1-3 but not this
// if it correlates with the boundary — belt and braces).
for (const f of ["promptSha", "pin", "verification", "permission", "allowed", "timeouts"]) {
  const pre = new Set(cells.filter((c) => c.era === "pre").map((c) => f === "promptSha" ? `${c.seqpos}:${c[f]}` : String(c[f])));
  const post = new Set(cells.filter((c) => c.era === "post").map((c) => f === "promptSha" ? `${c.seqpos}:${c[f]}` : String(c[f])));
  const onlyPost = [...post].filter((x) => !pre.has(x) && !(f === "promptSha" && ![...pre].some((y) => y.startsWith(x.split(":")[0]))));
  const novel = f === "promptSha"
    ? onlyPost.filter((x) => [...pre].some((y) => y.split(":")[0] === x.split(":")[0])) // same position, new sha = drift
    : onlyPost;
  novel.length ? fail(`${f}: post-boundary value(s) unseen pre-boundary: ${novel.join(", ")}`)
    : ok(`${f}: no post-boundary drift (${post.size} post values all consistent with pre era)`);
}

console.log(`\ncells examined: ${cells.length} (pre=${cells.filter((c) => c.era === "pre").length}, post=${cells.filter((c) => c.era === "post").length}), admissible ${cells.filter((c) => c.admissible).length}`);
console.log(fails ? `VERDICT: ${fails} FAILURE(S) — quarantine the named cells and report the deviation` : "VERDICT: UNIFORM — the intervention is benign under the precommitted criterion");
process.exit(fails ? 1 : 0);
