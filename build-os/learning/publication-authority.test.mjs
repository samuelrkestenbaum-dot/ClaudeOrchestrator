import fs from "node:fs";
import { publicationCheck, isClearlyDraft, statusClaims } from "./publication-authority.mjs";
let pass=0, fail=0; const out=[];
const check=(n,c,d="")=>{ if(c){pass++;out.push(`  ok   ${n}`);} else {fail++;out.push(`  FAIL ${n}${d?" — "+d:""}`);} };

// --- the real episode, replayed --------------------------------------------
const draftText = fs.readFileSync("build-os/experiments/EXP-0005-system-efficiency/PREREGISTRATION.md","utf8");
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
check("an ancestor that is neither draft nor status-free blocks",
  publicationCheck({ authorized: "x", incidental: [{ ref: "Z", text: "some ordinary prose with no markers" }] }).verdict === "ask_operator");

// --- no incidental ancestors: trivially fine --------------------------------
check("a publication with no incidental ancestors proceeds",
  publicationCheck({ authorized: "x", incidental: [] }).verdict === "proceed");
check("the three questions are stated in the artifact",
  /three different\s+questions/.test(publicationCheck({authorized:"x",incidental:[]}).principle));
check("packet closure claims are caught",
  statusClaims("the packet closed successfully").length > 0);
check("determinism", JSON.stringify(publicationCheck({authorized:"a",incidental:[{ref:"b",text:"**Status: DRAFT.**"}]}))
  === JSON.stringify(publicationCheck({authorized:"a",incidental:[{ref:"b",text:"**Status: DRAFT.**"}]})));

process.stdout.write(out.join("\n")+"\n");
process.stdout.write(`TESTS: ${pass} passed, ${fail} failed, 0 skipped\n`);
process.exit(fail?1:0);
