#!/usr/bin/env node
// REHEARSAL TRANSPORT — the impossible-to-cross barrier (AMENDMENT v3).
//
// This module imports NO process-execution capability of any kind: no
// child_process, no worker_threads, no net/http. A controller handed this
// transport is STRUCTURALLY unable to launch a provider call through it —
// the barrier is the module's import graph, not a PATH trick. (The PATH
// shim remains as a defense-in-depth tripwire behind this wall.)
//
// call() builds and persists the exact semantic request digest of the call
// the measured transport WOULD make — cell, full argv, stdin byte digest,
// cwd — and returns the NO_PROVIDER_CALL sentinel. Audit red-team note: the
// audit itself demonstrated that executing `claude` with any stray argv is a
// PAID model call (the argv is consumed as a prompt), so nothing outside an
// exact ["--version"] probe may ever reach an exec of the CLI in rehearsal.
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
const sha = (s) => crypto.createHash("sha256").update(s).digest("hex");

export function rehearsalTransport(studyDir) {
  return {
    kind: "rehearsal",
    async call({ cell, argv, stdinText, cwd }) {
      const digest = {
        artifact: "exp0013_semantic_request_digest", cell,
        argv, argv_sha256: sha(JSON.stringify(argv)),
        stdin_sha256: sha(stdinText), stdin_bytes: Buffer.byteLength(stdinText, "utf8"),
        cwd, model_flag: argv[argv.indexOf("--model") + 1] ?? null,
        sentinel: "NO_PROVIDER_CALL",
      };
      fs.appendFileSync(path.join(studyDir, "rehearsal-requests.jsonl"), JSON.stringify(digest) + "\n");
      return { launched: false, sentinel: "NO_PROVIDER_CALL" };
    },
  };
}
