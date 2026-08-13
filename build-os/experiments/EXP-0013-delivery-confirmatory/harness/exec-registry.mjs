#!/usr/bin/env node
// TYPED EXTERNAL-EXECUTABLE REGISTRY (AMENDMENT v4 — incident prevention).
//
// Closed world: the harness may only run executables registered here, only
// with argv shapes the registry allows for the current mode, only with an
// env assembled from an allowlist (CLAUDE_CODE_SESSION_ID is STRIPPED — the
// incident call silently joined the orchestration session's identity via
// inherited env). Unknown executable, unknown argv shape, or a mode the
// entry does not permit => typed refusal BEFORE any spawn. "If command
// semantics are uncertain, do not execute" is enforced here, not remembered.
//
// The provider CLI (`claude`) has exactly ONE registered non-inferential
// form: ["--version"] — proven cost-free. Every other claude argv refuses
// here; inference goes ONLY through provider-call-site.mjs, which does not
// use this registry for the worker spawn (it is the separately-audited sole
// call site).
import { spawnSync, execFileSync } from "node:child_process";
import fs from "node:fs";

const ENV_ALLOW = ["PATH", "HOME", "LANG", "LC_ALL", "TMPDIR", "NODE_OPTIONS_NONE"]; // NO CLAUDE_* / ANTHROPIC_* inheritance
export function scrubbedRegistryEnv(extra = {}) {
  const env = {};
  for (const k of ENV_ALLOW) if (process.env[k] !== undefined) env[k] = process.env[k];
  return { ...env, ...extra };
}

// argv matchers: exact string, or {re} anchored regex per position, or {rest} to allow any tail.
const REGISTRY = {
  claude: {
    transmission_risk: "ANY NON-REGISTERED ARGV IS A PAID INFERENCE CALL (incident 2026-08-13); only --version is proven non-inferential",
    spend_risk: "paid per call outside this allowlist",
    timeout_ms: 15000,
    result_schema: "single version line on stdout",
    failure: "non-zero exit or version mismatch => preflight refusal upstream",
    modes: { any: [["--version"]] },
  },
  git: {
    transmission_risk: "none (proxy-mediated fetch/push are NOT registered; only local plumbing is)",
    spend_risk: "none", timeout_ms: 120000, result_schema: "porcelain/plumbing text",
    failure: "non-zero exit surfaces as typed step failure",
    modes: { any: [
      [{ re: "^-C$" }, { rest: true }],           // git -C <dir> <local plumbing...> (archive/init/add/commit/rev-parse/status/remote)
      [{ re: "^(rev-parse|status|log|diff|ls-tree)$" }, { rest: true }],
    ] },
  },
  bash: {
    transmission_risk: "none (registered scripts are local)", spend_risk: "none",
    timeout_ms: 300000, result_schema: "script-defined", failure: "non-zero exit surfaces",
    modes: { any: [
      [{ re: "^-c$" }, { re: "^git -C .*archive.*tar -x -C.*$" }],  // the pinned corpus archive pipe
      [{ re: "^-c$" }, { re: "^cd [^;|&`$()]+ && npx tsc --noEmit -p tsconfig\\.json$" }], // the acceptance-oracle compile (AMENDMENT v6)
      [{ re: ".*/h0-check\\.sh$" }, { re: "^--gate$" }],
      [{ re: ".*/fake-worker\\.sh$" }, { rest: true }],
    ] },
  },
  node: {
    transmission_risk: "none (local scripts only)", spend_risk: "none",
    timeout_ms: 300000, result_schema: "script-defined", failure: "non-zero exit surfaces",
    modes: { any: [
      [{ re: ".*/freeze[0-9]?\\.mjs$" }, { re: "^verify$" }],
      [{ re: "^--input-type=module$" }, { re: "^-e$" }, { rest: true }], // planner-descriptor eval (local modules only)
    ] },
  },
  gravito: {
    transmission_risk: "none", spend_risk: "none", timeout_ms: 120000,
    result_schema: "gravito CLI text", failure: "non-zero exit surfaces",
    modes: { any: [
      [{ re: "^(init|goal)$" }, { rest: true }],
    ] },
  },
};

function argvAllowed(entry, argv, mode) {
  const shapes = [...(entry.modes[mode] ?? []), ...(entry.modes.any ?? [])];
  outer: for (const shape of shapes) {
    let i = 0;
    for (const m of shape) {
      if (typeof m === "object" && m.rest) { i = argv.length; continue; }
      if (i >= argv.length) continue outer;
      const a = argv[i++];
      if (typeof m === "string" ? a !== m : !(new RegExp(m.re)).test(a)) continue outer;
    }
    if (i === argv.length || shape.some((m) => typeof m === "object" && m.rest)) return true;
  }
  return false;
}

/** Resolve identity + drift facts for a registered executable (no inference). */
export function executableIdentity(name) {
  const which = spawnSync("bash", ["-c", `command -v ${JSON.stringify(name)}`], { encoding: "utf8" });
  const p = (which.stdout || "").trim() || null;
  let real = null;
  try { real = p ? fs.realpathSync(p) : null; } catch {}
  return { name, path: p, realpath: real, is_symlink_or_wrapper: p !== null && p !== real };
}

/** THE gate: refuse-before-spawn for anything not exactly registered. */
export function runRegistered(name, argv, { mode = "no-provider", cwd, env = {}, timeoutMs = null, input = null, basename = null } = {}) {
  const key = basename ?? name.split("/").pop();
  const entry = REGISTRY[key];
  if (!entry) return { refused: `EXEC_NOT_REGISTERED:${key}` };
  if (!argvAllowed(entry, argv, mode)) return { refused: `EXEC_ARGV_NOT_ALLOWED:${key}:${JSON.stringify(argv).slice(0, 120)}` };
  const r = spawnSync(name, argv, {
    encoding: "utf8", cwd, input: input ?? undefined,
    env: scrubbedRegistryEnv(env), timeout: timeoutMs ?? entry.timeout_ms,
  });
  return { refused: null, status: r.status, stdout: r.stdout ?? "", stderr: r.stderr ?? "" };
}

/** The single permitted non-inferential provider-CLI probe. */
export function cliVersionProbe() {
  return runRegistered("claude", ["--version"], { mode: "no-provider" });
}

export function registryTable() {
  return Object.fromEntries(Object.entries(REGISTRY).map(([k, v]) => [k, {
    transmission_risk: v.transmission_risk, spend_risk: v.spend_risk,
    timeout_ms: v.timeout_ms, result_schema: v.result_schema, failure: v.failure,
    allowed_argv: v.modes,
  }]));
}
