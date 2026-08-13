#!/usr/bin/env node
// TEST transport only (AMENDMENT v4).
//
// The real measured transport NO LONGER LIVES HERE: inference capability is
// owned exclusively by provider-call-site.mjs, acquired only through
// acquireProviderTransport() after spend-authorization validation. This
// module keeps testFakeTransport, which drives the measured state machine
// with scripted synthetic streams and REFUSES to execute anything — it has
// no child_process import and throws on any provider-shaped argv.
import fs from "node:fs";

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
