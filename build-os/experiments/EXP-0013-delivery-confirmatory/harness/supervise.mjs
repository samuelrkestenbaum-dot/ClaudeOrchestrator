#!/usr/bin/env node
// Supervised execution primitives (moved out of controller.mjs in AMENDMENT v3
// so the REHEARSAL transport can live in a module with NO child_process
// import at all — structural, not procedural, inability to execute).
// Behavior is byte-for-byte the controller v2 semantics: one supervisor,
// detached process group, controller-owned SIGKILL at the ceiling, recorded
// terminal_reason, and a post-cell /proc orphan scan.
import fs from "node:fs";
import { spawn, spawnSync } from "node:child_process";

export function supervise({ argv, stdinText, cwd, env, ceilingS, outFile, marker }) {
  return new Promise((resolve) => {
    const started = Date.now();
    const out = fs.openSync(outFile, "w");
    const child = spawn(argv[0], argv.slice(1), {
      cwd, env: { ...env, EXP0013_CELL_MARKER: marker },
      stdio: ["pipe", out, "pipe"], detached: true,
    });
    let stderr = ""; child.stderr.on("data", (b) => { if (stderr.length < 100_000) stderr += b.toString(); });
    child.stdin.write(stdinText ?? ""); child.stdin.end();
    let timedOut = false;
    const timer = setTimeout(() => {
      timedOut = true;
      try { process.kill(-child.pid, "SIGKILL"); } catch {}
      try { process.kill(child.pid, "SIGKILL"); } catch {}
    }, ceilingS * 1000);
    child.on("exit", (code, signal) => {
      clearTimeout(timer); fs.closeSync(out);
      const elapsed_s = (Date.now() - started) / 1000;
      const terminal_reason = timedOut ? "timeout" : code === 0 ? "success" : signal ? `killed:${signal}` : `exit:${code}`;
      resolve({ exit_code: code, signal, terminal_reason, elapsed_s, stderr: stderr.slice(0, 4000) });
    });
  });
}

export function detectOrphans(marker) {
  const r = spawnSync("bash", ["-c",
    `for p in /proc/[0-9]*; do if grep -qz "EXP0013_CELL_MARKER=${marker}" "$p/environ" 2>/dev/null; then basename "$p"; fi; done`],
    { encoding: "utf8" });
  const pids = (r.stdout || "").split("\n").filter(Boolean).filter((p) => Number(p) !== process.pid);
  return { clean: pids.length === 0, orphan_pids: pids };
}
