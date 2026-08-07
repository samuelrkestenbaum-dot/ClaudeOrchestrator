#!/usr/bin/env node
// The WIRED publication-authority check. This is the control path, not a model
// of one: `.githooks/pre-push` calls it, so `git push` consults it regardless
// of who invokes the push.
//
// It answers the three separated questions:
//   1. CONTENT       — is there an operator authorisation for this change?
//   2. TOPOLOGY      — which already-existing ancestors become reachable?
//   3. STATE CHANGE  — would publishing any of them assert a new status?
//
// It does NOT invent authorisation. Absent an authorisation record it refuses,
// exactly as before. What it removes is the SECOND ask for an ancestor that
// already declares itself unfinished.

import { execFileSync } from "node:child_process";
import fs from "node:fs";
import { publicationCheck } from "../learning/publication-authority.mjs";

const AUTH_FILE = "build-os/authority/publish-authorization.json";
const git = (args) => execFileSync("git", args, { encoding: "utf8" }).trim();

function arg(name, dflt = null) {
  const i = process.argv.indexOf(name);
  return i > 0 && process.argv[i + 1] ? process.argv[i + 1] : dflt;
}

const localRef = arg("--local", "HEAD");
const remoteRef = arg("--remote", null);

// Commits that would become newly reachable, oldest first.
let range;
try {
  range = remoteRef ? `${remoteRef}..${localRef}` : localRef;
  var commits = git(["rev-list", "--reverse", range]).split("\n").filter(Boolean);
} catch {
  console.error("publish-check: cannot compute the push range — refusing rather than guessing");
  process.exit(1);
}
if (!commits.length) { console.log("publish-check: nothing to publish"); process.exit(0); }

// The authorisation record names an INTENT, not a SHA. Only an operator go
// creates it; this tool never writes it.
let auth = null;
try { auth = JSON.parse(fs.readFileSync(AUTH_FILE, "utf8")); } catch {}
if (!auth || !auth.authorized) {
  console.error(`publish-check: REFUSED — no operator authorisation in ${AUTH_FILE}`);
  console.error("  Content authorisation is required and is never self-granted.");
  process.exit(1);
}

// The authorisation must name the TIP it was granted for. Without this the
// record would authorise every future push simply by continuing to exist —
// self-granting by staleness. The fix that prompted this file was about
// ANCESTORS, never about waiving the go for new work.
const tipSha = git(["rev-parse", localRef]);
if (!auth.authorized_tip) {
  console.error(`publish-check: REFUSED — the authorisation names no authorized_tip`);
  console.error("  An authorisation that names no commit would authorise every future push.");
  process.exit(1);
}
if (git(["rev-parse", auth.authorized_tip]) !== tipSha) {
  console.error(`publish-check: REFUSED — authorisation is STALE`);
  console.error(`  granted for ${auth.authorized_tip}, but the push tip is ${tipSha.slice(0, 7)}`);
  console.error("  New work needs its own go; only incidental ancestors ride along.");
  process.exit(1);
}

// The authorised tip is the last commit; everything before it is incidental —
// it already existed and is only becoming reachable.
const tip = commits[commits.length - 1];
const incidentalShas = commits.slice(0, -1);

// For each incidental commit, read the text it introduced so its status can be
// checked. Unreadable content stays a refusal.
const incidental = incidentalShas.map((sha) => {
  let text = null;
  try {
    const files = git(["show", "--name-only", "--pretty=format:", sha]).split("\n").filter(Boolean);
    text = files.map((f) => { try { return git(["show", `${sha}:${f}`]); } catch { return ""; } }).join("\n");
  } catch { text = null; }
  const subject = (() => { try { return git(["log", "-1", "--pretty=%s", sha]); } catch { return "?"; } })();
  return { ref: `${sha.slice(0, 7)} ${subject.slice(0, 60)}`, text };
});

const result = publicationCheck({
  authorized: auth.authorized,
  incidental,
  confers_status: auth.confers_status === true,
});

console.log(`publish-check: ${result.verdict.toUpperCase()}`);
console.log(`  authorised: ${auth.authorized}`);
console.log(`  tip: ${tip.slice(0, 7)}`);
for (const r of result.reasons) console.log(`  · ${r}`);
for (const b of result.blocking) console.error(`  ✗ ${b}`);
if (result.verdict !== "proceed") {
  console.error("  A fresh operator go is required for the blocking item(s) above.");
  process.exit(1);
}
process.exit(0);
