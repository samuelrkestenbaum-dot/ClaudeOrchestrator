#!/usr/bin/env node
// Proof of the implementation-read classifier, BEFORE any number it produces is
// used. The figure this replaces was withdrawn because its classifier matched
// its own subject matter; these assertions exist to make that class of mistake
// impossible to repeat silently.
import fs from "node:fs"; import os from "node:os"; import path from "node:path";
import { classifyRead, measureStream } from "./implementation-reads.mjs";
let pass=0, fail=0;
const t=(n,c,d="")=>{ if(c){pass++;console.log(`  ok   ${n}`);} else {fail++;console.log(`  FAIL ${n}${d?" — "+d:""}`);} };

// KNOWN POSITIVES — real paths the worker actually read in EXP-0006/0007.
for (const p of [
  "/home/user/exp0007-arm/.claude/hooks/routing-gate.sh",
  "/home/user/exp0007-arm/build-os/motion/queue.json",
  "/home/user/exp0007-arm/build-os/packets/routing/routing-T03-x.md",
  "/home/user/exp0006-arm/CLAUDE.md",
  "/home/user/exp0006-arm/build-os/memory/tool_router.md",
]) t(`KNOWN POSITIVE: ${p.replace(/^.*arm\//,"")}`, classifyRead("Read", p) === "implementation");

// KNOWN NEGATIVES — the actual task files from the frozen selection.
for (const p of [
  "/home/user/exp0007-arm/server/services/organizational-memory.ts",
  "/home/user/exp0007-arm/client/src/pages/UserDashboard.tsx",
  "/home/user/exp0006-arm/server/agent/github-app.ts",
  "/home/user/exp0007-arm/drizzle/schema.ts",
]) t(`KNOWN NEGATIVE: ${p.replace(/^.*arm\//,"")}`, classifyRead("Read", p) === "product");

// THE MUTATION THAT WOULD HAVE CAUGHT THE ORIGINAL DEFECT.
// The withdrawn metric classified by RESULT CONTENT, so a product file whose
// text merely mentioned the gate was counted as gate volume. This classifier
// never receives content, so it cannot be fooled that way — asserted rather
// than assumed, because "it can't happen" is what the last one implied too.
t("MUTATION content is not an input at all — classifyRead takes no body",
  classifyRead.length === 2, `arity ${classifyRead.length}`);
t("MUTATION a PRODUCT file whose content is gate source is still product",
  classifyRead("Read", "/home/user/exp0007-arm/server/copy-of-routing-gate.ts") === "product");
t("MUTATION an IMPLEMENTATION file with product-looking name is still implementation",
  classifyRead("Read", "/home/user/exp0007-arm/build-os/server/services/thing.ts") === "implementation");

// Non-reads must not be counted at all.
for (const n of ["Bash","Edit","Write","Glob","Grep","Task"])
  t(`non-read tool ${n} is not classified as a read`, classifyRead(n, "/x/build-os/y.mjs") === null);
t("a Read with no path is not classified", classifyRead("Read", null) === null);

// END-TO-END on a synthetic stream: the pairing must follow tool_use_id, not order.
const d = fs.mkdtempSync(path.join(os.tmpdir(),"impl-reads-"));
const sp = path.join(d,"stream.jsonl");
fs.writeFileSync(sp, [
  JSON.stringify({message:{content:[{type:"tool_use",id:"a",name:"Read",input:{file_path:"/x/exp0007-arm/build-os/motion/queue.json"}}]}}),
  JSON.stringify({message:{content:[{type:"tool_use",id:"b",name:"Read",input:{file_path:"/x/exp0007-arm/server/thing.ts"}}]}}),
  // results arrive OUT OF ORDER relative to the calls
  JSON.stringify({message:{content:[{type:"tool_result",tool_use_id:"b",content:"PRODUCT-"+"x".repeat(99)}]}}),
  JSON.stringify({message:{content:[{type:"tool_result",tool_use_id:"a",content:"IMPL-"+"y".repeat(995)}]}}),
].join("\n"));
const m = measureStream(sp);
t("END-TO-END implementation bytes attributed correctly", m.implementation_chars === 1000, String(m.implementation_chars));
t("END-TO-END product bytes attributed correctly", m.product_chars === 107, String(m.product_chars));
t("END-TO-END pairing follows tool_use_id, not arrival order",
  m.implementation_reads.length === 1 && m.implementation_reads[0].path === "build-os/motion/queue.json");
fs.rmSync(d,{recursive:true,force:true});

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail?1:0);
