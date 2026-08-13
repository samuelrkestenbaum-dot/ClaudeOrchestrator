#!/usr/bin/env node
// THE SOLE PROVIDER CALL SITE (AMENDMENT v4).
//
// This is the only module in the harness permitted to spawn the provider
// CLI for inference, and the only module that may hand out a transport
// carrying that capability. Structure of the guarantee:
//   - no other harness module imports this one except through
//     acquireProviderTransport() at measured-run entry (statically tested);
//   - acquireProviderTransport validates the spend authorization FIRST and
//     returns a transport whose every call re-checks: expiry, cell
//     allowlist, request-digest allowlist (arbitrary prompts cannot be
//     authorized), ledger call ceiling and budget projection;
//   - retry/resume have no other route: whatever restarts, it must come
//     back through this gate, and the ledger it re-reads still holds every
//     reservation;
//   - synthetic authority (tests) REQUIRES an injected fake adapter and can
//     NEVER reach the real spawn; real authority REFUSES an injected
//     adapter. The two paths cannot be crossed.
import fs from "node:fs";
import crypto from "node:crypto";
import { supervise } from "./supervise.mjs";
import { buildProviderArgv } from "./provider-argv.mjs";
import { validateAuthorization, requestAllowed } from "./authorization.mjs";
import * as ledger from "./spend-ledger.mjs";

const sha = (s) => crypto.createHash("sha256").update(s).digest("hex");

export function acquireProviderTransport({ auth, config, binding, adapter = null, now = null }) {
  const t = now ?? Date.parse(new Date().toISOString());
  const v = validateAuthorization(auth, { ...binding, now: t });
  if (!v.ok) return { refused: v.reason };
  const A = v.auth;
  if (A.synthetic === true && !adapter) return { refused: "SYNTHETIC_AUTHORITY_REQUIRES_FAKE_ADAPTER" };
  if (A.synthetic !== true && adapter) return { refused: "REAL_AUTHORITY_REFUSES_INJECTED_ADAPTER" };
  const kind = A.synthetic === true ? "test-fake" : "measured-real";
  return {
    transport: {
      kind,
      async call(req) {
        if (!(new Date(A.expires_at).getTime() > (now ?? Date.now()))) return { refused: "AUTH_EXPIRED" };
        const adm = requestAllowed(A, { cell: req.cell, stdinText: req.stdinText });
        if (!adm.ok) return { refused: adm.reason };
        const led = ledger.loadLedger(A.ledger_dir);
        if (!led.ok) return { refused: led.reason };
        if (led.calls >= A.max_calls) return { refused: "AUTH_CALLS_EXHAUSTED" };
        if (led.spent_conservative_usd + config.spend.per_call_worst_usd > A.max_spend_usd) return { refused: "AUTH_SPEND_EXHAUSTED" };
        const argv = buildProviderArgv(config, crypto.randomUUID());
        if (A.synthetic === true) {
          const beh = adapter(req, argv) ?? {};
          fs.writeFileSync(req.outFile, beh.streamText ?? "");
          return { exit_code: 0, signal: null, terminal_reason: beh.terminal_reason ?? "success", elapsed_s: beh.elapsed_s ?? 1, stderr: "", request_sha256: sha(req.stdinText) };
        }
        // Incident lesson: the worker must NOT inherit the orchestration
        // session's identity or stray CLAUDE_* state from the caller env.
        const env = { ...req.env };
        for (const k of Object.keys(env)) if (/^CLAUDE_CODE_|^CLAUDECODE/.test(k)) delete env[k];
        const res = await supervise({ argv, stdinText: req.stdinText, cwd: req.cwd, env, ceilingS: req.ceilingS, outFile: req.outFile, marker: req.marker });
        return { ...res, request_sha256: sha(req.stdinText) };
      },
    },
  };
}
