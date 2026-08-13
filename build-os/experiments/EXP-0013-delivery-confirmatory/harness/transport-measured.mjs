#!/usr/bin/env node
// MEASURED + TEST transports (AMENDMENT v3).
//
//   measuredTransport — the ONLY module that may execute the real provider
//     CLI for a cell. Constructed exclusively by runMeasured after the
//     spend-authorization gate passes; rehearsal code paths never import it.
//   testFakeTransport — drives the measured state machine in tests with a
//     scripted behavior per call, writing a synthetic stream to outFile. It
//     REFUSES to execute anything: pure in-process file writes. It exists so
//     call-count, budget, model-check, rerun and void logic are proven
//     executable without any provider contact.
import fs from "node:fs";
import { supervise } from "./supervise.mjs";

export function measuredTransport() {
  return {
    kind: "measured-real",
    async call({ argv, stdinText, cwd, env, ceilingS, outFile, marker }) {
      return supervise({ argv, stdinText, cwd, env, ceilingS, outFile, marker });
    },
  };
}

/** script(req, callIndex) -> { streamText?, terminal_reason?, elapsed_s? } */
export function testFakeTransport(script) {
  let n = 0;
  return {
    kind: "test-fake",
    async call(req) {
      if (JSON.stringify(req.argv ?? []).includes("claude"))
        throw new Error("test transport must never see a real provider argv");
      const beh = script(req, n++) ?? {};
      fs.writeFileSync(req.outFile, beh.streamText ?? "");
      return {
        exit_code: 0, signal: null,
        terminal_reason: beh.terminal_reason ?? "success",
        elapsed_s: beh.elapsed_s ?? 1, stderr: "",
      };
    },
  };
}
