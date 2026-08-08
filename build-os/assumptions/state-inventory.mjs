// The classified state items. DERIVED entries carry a path the auditor can
// check; DECLARED entries are labels a human applied and are weaker evidence.
import { execFileSync } from "node:child_process";
import fs from "node:fs";

/** Is a path tracked in git? Derived, not declared. */
const tracked = (repo, p) => {
  try { return execFileSync("git", ["-C", repo, "ls-files", "--error-unmatch", p], { stdio: "pipe", encoding: "utf8" }).trim().length > 0; }
  catch { return false; }
};
const existsOnDisk = (repo, p) => fs.existsSync(`${repo}/${p}`);

export function inventory(repo = "/home/user/empathiq-website") {
  const items = [];

  // DERIVED: the routing gate's own required state. `durable` is read from git,
  // not asserted — this is the pair whose misclassification caused EXP-0005's
  // published-and-later-refuted diagnosis.
  const gatePath = ".claude/hooks/routing-gate.sh";
  items.push({
    id: "routing_gate_hook", path: gatePath, provenance: "derived",
    durable: tracked(repo, gatePath), reconstructable: false, load_bearing: true,
    required_before_first_action: true, constructor_ref: null,
  });
  for (const p of ["build-os/packets/routing/live_state", "build-os/packets/routing/live_gate_log.tsv", ".gravito"]) {
    items.push({
      id: p, path: p, provenance: "derived",
      durable: tracked(repo, p), tracked: tracked(repo, p),
      ephemeral: !tracked(repo, p) && existsOnDisk(repo, p),
      session_local: true,
      // Post-#45 these are NOT load-bearing: the routing-request channel makes
      // first authority reachable without them. Derived from the selector.
      load_bearing: false, reconstructable: true,
      constructor_ref: "routing-request channel + route-task.sh",
    });
  }

  // DECLARED: labels applied by a human, and marked as the weaker evidence.
  items.push({
    id: "publish_authorization_grant", path: "build-os/authority/publish-authorization.json",
    provenance: "declared", must_never_persist: true, tracked: tracked("/home/user/ClaudeOrchestrator", "build-os/authority/publish-authorization.json"),
    durable: false, ephemeral: true, session_local: true, load_bearing: false,
  });
  items.push({
    id: "exp0005_sealed_mapping", path: "~/.exp0005/sealed-mapping.json",
    provenance: "declared", must_never_persist: true, tracked: false, durable: false,
    ephemeral: false, load_bearing: false, externally_supplied: false,
  });
  return items;
}
