import { execFileSync } from "node:child_process";
import { publicationCheck, isClearlyDraft, statusClaims } from "./publication-authority.mjs";
let pass=0, fail=0; const out=[];
const check=(n,c,d="")=>{ if(c){pass++;out.push(`  ok   ${n}`);} else {fail++;out.push(`  FAIL ${n}${d?" — "+d:""}`);} };

// --- the real episode, replayed --------------------------------------------
// PINNED TO THE COMMIT WHERE THE FIXTURE WAS ACTUALLY A DRAFT.
//
// This read the LIVE file, and the live file was frozen at 07ba463 — so from
// that moment the test asserted "the real EXP-0005 draft asserts no status"
// about a document whose first line reads **Status: FROZEN.** Three assertions
// had been failing ever since, describing a draft that no longer existed.
//
// A fixture that changes underneath its test is a snapshot pretending to be an
// invariant. The repair is not to point at some other mutable file — that just
// resets the clock on the same rot — but to pin the historical content, which
// is real, is the content the episode actually concerned, and cannot change.
const draftText = execFileSync("git",
  ["show", "1ffb356:build-os/experiments/EXP-0005-system-efficiency/PREREGISTRATION.md"],
  { encoding: "utf8", maxBuffer: 8 * 1024 * 1024 });
const real = publicationCheck({
  authorized: "publish Post-Outcome Disposition v0",
  incidental: [{ ref: "1ffb356", description: "EXP-0005 preregistration", text: draftText }],
});
check("THE EPISODE: a clearly-draft ancestor does NOT require a fresh go",
  real.verdict === "proceed", JSON.stringify(real.blocking));
check("the reasoning names topology, not approval",
  real.reasons.some(r=>/topology consequence, not approval/.test(r)));
check("the real EXP-0005 draft is detected as draft", isClearlyDraft(draftText));
check("the real EXP-0005 draft asserts no status", statusClaims(draftText).length === 0, JSON.stringify(statusClaims(draftText)));

// --- a state transition still needs authority -------------------------------
const frozen = publicationCheck({
  authorized: "publish some finished work",
  incidental: [{ ref: "X", text: "**Status: FROZEN.** This preregistration is frozen and ready to execute." }],
});
check("an ancestor CLAIMING frozen status blocks", frozen.verdict === "ask_operator");
check("the block names the state transition",
  frozen.blocking.some(b=>/state transition/.test(b)), JSON.stringify(frozen.blocking));
check("a publication that itself confers status blocks",
  publicationCheck({ authorized: "freeze the preregistration", incidental: [], confers_status: true }).verdict === "ask_operator");

// --- unchecked is not cleared ------------------------------------------------
check("an ancestor whose content was not supplied blocks",
  publicationCheck({ authorized: "x", incidental: [{ ref: "Y" }] }).verdict === "ask_operator");
// --- THE DEFECT, BOTH DIRECTIONS --------------------------------------------
// This assertion previously read `=== "ask_operator"` and was named "neither
// draft nor status-free". Its own fixture is status-free — no status claim of
// any kind — so the test was pinning the inversion rather than guarding
// against it. Publishing EXP-0006 is what exposed it: eleven ordinary data and
// harness commits were refused as state transitions for saying nothing about
// status at all.
check("STATUS-FREE PROCEEDS: an ancestor asserting no status is not a transition",
  publicationCheck({ authorized: "x", incidental: [{ ref: "Z", text: "some ordinary prose with no markers" }] }).verdict === "proceed");
check("and the reason says so rather than staying silent",
  publicationCheck({ authorized: "x", incidental: [{ ref: "Z", text: "ordinary prose" }] })
    .reasons.some(r => /asserts no governed status transition/.test(r)));

// DESCRIPTION must pass. These are the operator's own examples.
for (const prose of [
  "record frozen experiment result",
  "experiment execution complete",
  "capture executed arm telemetry",
  "document accepted result",
  "EXP-0006 COMPLETE: native_higher_uic — 18.15 vs 10.36 over 12 matched pairs",
  "EXP-0006 harness: treatment administered and VERIFIED, mapping sealed before any arm",
  "the packet closed successfully last week, which is why the receipt exists",
]) {
  check(`DESCRIPTION passes: ${JSON.stringify(prose.slice(0, 46))}`,
    statusClaims(prose).length === 0, JSON.stringify(statusClaims(prose)));
}

// ASSERTION must still block. Same words, assertion form.
for (const [label, text] of [
  ["a Status field set to FROZEN", "**Status: FROZEN.** No measured arm executes before the digest below is recorded."],
  ["a Status field set to APPROVED", "Status: APPROVED"],
  ["a Status field set to executed", "> Status: EXECUTED"],
  ["a packet declaring itself closed", "This packet is now closed."],
  ["a Status field set to closed", "Status: closed"],
  ["an authorisation declared granted", "authorisation granted by the operator"],
  ["a declaration of readiness to execute", "The preregistration is ready to execute."],
]) {
  check(`ASSERTION still blocks: ${label}`, statusClaims(text).length > 0, text.slice(0, 50));
  check(`  ...and refuses the publication: ${label}`,
    publicationCheck({ authorized: "x", incidental: [{ ref: "A", text }] }).verdict === "ask_operator");
}

// The control must not have been weakened globally.
check("NOT WEAKENED: unreadable content still blocks",
  publicationCheck({ authorized: "x", incidental: [{ ref: "Y", text: null }] }).verdict === "ask_operator");
check("NOT WEAKENED: an unauthorised self-conferred status still blocks",
  publicationCheck({ authorized: "x", incidental: [], confers_status: true }).verdict === "ask_operator");
check("NOT WEAKENED: one asserting ancestor among many status-free ones still blocks",
  publicationCheck({ authorized: "x", incidental: [
    { ref: "ok1", text: "data" }, { ref: "bad", text: "Status: FROZEN" }, { ref: "ok2", text: "more data" },
  ]}).verdict === "ask_operator");

// --- no incidental ancestors: trivially fine --------------------------------
check("a publication with no incidental ancestors proceeds",
  publicationCheck({ authorized: "x", incidental: [] }).verdict === "proceed");
check("the three questions are stated in the artifact",
  /three different\s+questions/.test(publicationCheck({authorized:"x",incidental:[]}).principle));
// UPDATED, and the change is the point: this asserted that the PROSE "the
// packet closed successfully" performs a closure. It does not — it describes
// one. The assertion form is what carries authority, so that is what is now
// checked, and the prose case is asserted to PASS in the DESCRIPTION block above.
check("packet closure ASSERTIONS are caught",
  statusClaims("This packet is now closed.").length > 0);
check("...and a Status field set to closed is caught",
  statusClaims("Status: closed").length > 0);
check("determinism", JSON.stringify(publicationCheck({authorized:"a",incidental:[{ref:"b",text:"**Status: DRAFT.**"}]}))
  === JSON.stringify(publicationCheck({authorized:"a",incidental:[{ref:"b",text:"**Status: DRAFT.**"}]})));

process.stdout.write(out.join("\n")+"\n");
process.stdout.write(`TESTS: ${pass} passed, ${fail} failed, 0 skipped\n`);
process.exit(fail?1:0);
