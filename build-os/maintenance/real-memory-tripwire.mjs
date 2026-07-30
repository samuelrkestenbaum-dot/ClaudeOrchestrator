/**
 * GRAVITO:MANAGED — shipped by build-os/maintenance/install-maintenance.sh.
 * Edits made in an installed repo are REPLACED on the next install. Change it
 * upstream, or unmanage it by removing the path from .gravito-managed.
 *
 * THE REAL-MEMORY TRIPWIRE — PRELOADED by the sanctioned command, and also
 * imported first by every test file beside it.
 *
 *   ./build-os/maintenance/run-tests.sh        <- the sanctioned command
 *
 * -------------------------------------------------------------------------
 * WHY A PRELOAD, AND WHAT THAT DID AND DID NOT FIX
 * -------------------------------------------------------------------------
 * Being imported first by every suite file is not the same as running first.
 * The check that enforced "first" read the suite files' text with a LINE-
 * ANCHORED regular expression, so an import written at any column but 0 was
 * invisible to it — while the ESM loader evaluated it in source order anyway.
 * One leading space did it:
 *
 *     ␠␠import "./payload.mjs";
 *     import "./real-memory-tripwire.mjs";
 *
 * The payload ran, this module then baselined the ALREADY-DAMAGED tree, and
 * drift was zero. Measured in the reference deployment at the commit before this
 * change, with the planted file ordered last, the whole suite under
 * `--test-concurrency=1` reported 0 fail / exit 0 — having destroyed all three
 * real memory files and created a real archive. Four shapes produced identical
 * numbers: a leading space, a leading tab, an import after a `;`, and an import
 * after a closed block comment on the same line.
 *
 * `run-tests.sh` passes this module to `node --import`, so it loads BEFORE the
 * first line of any test file's module graph, at any column, in the runner and
 * in every test child. Ordering stops being a property of how the imports are
 * spelled.
 *
 * WHAT THE COVERAGE SCAN BELOW IS DOING DEPENDS ON THE PATH, and the two are
 * different enough to be worth separating:
 *   - AS A PRELOAD it runs before any test file is loaded at all, so a file that
 *     does not request this module FIRST aborts the run before its own first
 *     import is evaluated. That is PREVENTION. Measured on a clone: each of the
 *     four shapes above gives 0 pass / exit 1 with the real tree untouched, and
 *     so does a file with no static imports at all. The failure count is one per
 *     suite file in this directory, offending file included, so it is a property
 *     of the directory and not a number worth quoting; re-measured in this port,
 *     on a fresh install into a blank repo, the no-import shape gives
 *     0 pass / 3 fail / exit 1 with the tree untouched.
 *   - UNDER A BARE `node --test` IT IS A CONVENIENCE CHECK AND NOTHING MORE. It
 *     runs only once some file has already imported this module — by which time
 *     anything above that import has run — and whether it sees an import at all
 *     depends on a source mask that has now been beaten three times (exempt
 *     regions, then a `^` anchor, then the lexer; the current defeat is one line
 *     carrying two division-position regexes, and is written out in
 *     `source-scan.mjs`). THIS FILE MAKES NO DETECTION CLAIM FOR THAT PATH. An
 *     earlier version of this comment said the four shapes above "are reported
 *     by name, and go red" there; that is true of those four shapes and was
 *     measured, but it was read as a property of the path, and it is not one.
 *     Treat a bare run as unguarded.
 *
 * AND NOTE WHAT THE HASHING HALF CAN AND CANNOT DO: this module hashes, it does
 * not intercept. It cannot stop a write. What it adds is that a run which moved
 * the real tree cannot also report success — damage plus exit 1, not damage plus
 * exit 0 — subject to the hostile-handler case named below. The version of that
 * property which is actually GUARANTEED is the sentence at the top of
 * `run-tests.sh`, because it does not depend on any handler inside this process.
 *
 * -------------------------------------------------------------------------
 * WHY THIS IS A MODULE AND NOT A BLOCK INSIDE ONE SUITE FILE
 * -------------------------------------------------------------------------
 * An earlier round — in the reference deployment this layer was built in, before
 * the port — put this check at the bottom of `rotate-memory.test.mjs`.
 * That left `rotate-memory.rootscan.test.mjs` — a file that binds the real repo
 * root and holds a filesystem binding — with no tripwire at all, so one appended
 * line in it destroyed that repo's live Build OS memory at 0 fail / exit 0 (a
 * fully green run) under the command printed in that file's own header. The
 * machinery meant to
 * prove containment landed outside the reach of the check that would have
 * caught it. Moving the check into a module that every suite file imports is
 * the structural fix: whichever file you run, and whichever subset, the check
 * loads with it.
 *
 * -------------------------------------------------------------------------
 * WHAT IT DOES
 * -------------------------------------------------------------------------
 *   1. At MODULE LOAD — as a preload, before any test file's module graph is
 *      touched at all — it records the size and sha256 of the four watched real
 *      memory files (the three the rotation tool rewrites, plus the never-rotated
 *      `standing_gates.md`) and a full recursive snapshot of
 *      `build-os/memory/archive/`.
 *   2. It registers a `process.on("exit")` handler, FIRST, before doing anything
 *      else that can fail. At exit it re-reads both and sets `process.exitCode`
 *      to 1 with a loud stderr report if either moved.
 *   3. At load it also scans every `*.test.mjs` beside it and FAILS THE IMPORT
 *      if any of them does not request this module first — at any column, in a
 *      comment- and string-masked copy of the source. Adding a file that is
 *      uncovered AS THE MASK READS IT turns every other file in the directory
 *      red, by name. Loaded as a preload, that happens before any of them
 *      executes; loaded by an import, it happens after whatever preceded that
 *      import has already run. The mask is a heuristic and is defeatable — see
 *      the residual at the foot of this header — so this step is a convenience
 *      check, not a boundary.
 *
 * IT DELIBERATELY DOES NOT CONSULT `git status`. Since `.gitignore` un-ignored
 * `build-os/memory/archive/`, status DOES show a run that creates a multi-megabyte
 * real archive: the directory appears. But while that directory is untracked,
 * status reports at most one `??` line for the whole of it, and that line is
 * identical whether a file inside was added, rewritten, or removed (measured).
 * The check everyone reaches for still cannot see CONTENT damage. Content hashes
 * can.
 *
 * -------------------------------------------------------------------------
 * WHAT THIS MODULE MAY NOT DO, AND WHO CHECKS THAT
 * -------------------------------------------------------------------------
 * It reads files. It starts no process, calls no filesystem-mutating API, and
 * acquires no module beyond the four `node:` reads below and `./source-scan.mjs`
 * — which imports nothing at all, so it can act on nothing. Those are flat
 * properties of its source with no exemption span anywhere in it, and they are
 * asserted BY `rotate-memory.rootscan.test.mjs`, which reads this file as data.
 * This module does not vouch for itself.
 *
 * -------------------------------------------------------------------------
 * WHAT IT DOES NOT COVER. Named, not implied away.
 * -------------------------------------------------------------------------
 *   - AN ACTIVELY HOSTILE TEST BODY, UNDER A BARE `node --test`. This module is
 *     last-registered-wins on its own exit handler, and it does not defend it.
 *     Both of these still leave a damaged tree at exit 0 on that path:
 *         process.on("exit", () => { process.exitCode = 0 })
 *         process.removeAllListeners("exit")
 *     Measured: exit 0 with all three files destroyed and a real archive left
 *     behind. Under the sanctioned command they give exit 1 — and not because
 *     this module got cleverer. `run-tests.sh` fingerprints the real tree in the
 *     SHELL, before and after the whole node run; the tree is still damaged, but
 *     the run cannot report success. What that outer check does not survive is
 *     named in its own header, not here.
 *   - A TEST FILE THAT IMPORTS NOTHING, RUN BY A BARE `node --test`. Nothing can
 *     load from a file that references nothing, so on that path there is no
 *     tripwire and no scan: measured, exit 0 with the tree destroyed. Under the
 *     sanctioned command the preload runs the coverage scan before that file is
 *     loaded, which reports it and aborts — measured, exit 1, tree untouched.
 *   - FILES OUTSIDE `build-os/maintenance/`. The coverage scan is pointed at
 *     this directory.
 *   - DAMAGE THAT RESTORES ITSELF BEFORE EXIT. Byte-identical restoration is
 *     indistinguishable from no damage by content hash, and is also not damage.
 *   - WHAT THE MASK BEHIND THE COVERAGE SCAN CANNOT LEX. The scan finds imports
 *     at any column by blanking comments and strings first, and it can be made
 *     to blank a real import. The claim that used to stand here — "the residual
 *     is bounded in the direction that matters" — is FALSE, and the direction it
 *     reaches is the false-negative one. One line does it:
 *
 *         if (a) /'/.test(b); import "./payload.mjs"; if (c) /'/.test(d);
 *
 *     Both regexes are in division position, so each `'` is read as a string
 *     delimiter; they balance, so nothing throws; the span between them is
 *     blanked, so the import inside it is not returned by
 *     `moduleRequestSpecifiers` — while the loader hoists and runs it. Under a
 *     bare `node --test` that file is reported by nothing, its payload runs
 *     first, and the run is green with the tree destroyed. Under the sanctioned
 *     command the payload STILL RUNS and the tree is STILL DAMAGED — nothing
 *     here prevents a write — but the run cannot report success, and not because
 *     of this scan: the preload armed the tripwire before the file was loaded,
 *     and `run-tests.sh` fingerprints the tree in the shell either side of node.
 *     Measured on a clone: exit 1. No fourth mask heuristic is being written.
 *     The scan is best-effort; the out-of-process mechanisms are the guarantee.
 */

import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";
import { moduleRequestSpecifiers } from "./source-scan.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));

/**
 * `path.resolve` collapses `..` LEXICALLY. Resolve through symlinks so this is
 * the same spelling of the repo root that a symlink-resolved path produces.
 */
function realpathDeep(p) {
  let cur = path.resolve(p);
  const tail = [];
  for (;;) {
    try {
      const real = fs.realpathSync(cur);
      return tail.length ? path.join(real, ...tail) : real;
    } catch {
      const parent = path.dirname(cur);
      if (parent === cur) return path.resolve(p);
      tail.unshift(path.basename(cur));
      cur = parent;
    }
  }
}

export const REPO_ROOT = realpathDeep(path.resolve(HERE, "..", ".."));

/** The three files the rotation tool rewrites in place. */
export const ROTATED_MEMORY_FILES = [
  "build-os/memory/current_state.md",
  "build-os/memory/residue.md",
  "build-os/packets/active_packet.md",
];

/**
 * EVERY REAL FILE THIS MODULE WATCHES — the rotation set, PLUS the never-rotated
 * gates file. `run-tests.sh`'s `WATCHED` is pinned equal to this list.
 *
 * WHY THE FOURTH ONE IS HERE. `standing_gates.md` is the authority for standing
 * hard stops, and its protection is that it is absent from the rotation tool's
 * `FILE_SPECS` — which is protection from THE TOOL and from nothing else. It was
 * absent from this list and from `WATCHED` as well, so a test body that rewrote
 * the one file that must never change moved the real tree and exited 0 in
 * silence, under the sanctioned command. Being outside a tool's blast radius is
 * not the same as being watched.
 *
 * IT IS NOT ROTATED, AND THIS LIST IS NOT THE ROTATION SET. The two are pinned
 * apart in `rotate-memory.rootscan.test.mjs`: `FILE_SPECS` must equal
 * `ROTATED_MEMORY_FILES` and must not contain the gates file.
 */
export const REAL_MEMORY_FILES = [
  ...ROTATED_MEMORY_FILES,
  "build-os/memory/standing_gates.md",
];

export const REAL_ARCHIVE_REL = "build-os/memory/archive";
export const REAL_ARCHIVE_DIR = path.join(REPO_ROOT, REAL_ARCHIVE_REL);

const sha256 = (buf) => crypto.createHash("sha256").update(buf).digest("hex");

/**
 * Size + content hash of each given repo-relative path.
 *
 * A path that does not exist yields `{ present: false }` rather than throwing,
 * so a file that DISAPPEARS during a run is reported as missing instead of
 * blowing up the snapshot and being reported as "could not read".
 */
export function snapshotFiles(rels = REAL_MEMORY_FILES) {
  const out = {};
  for (const rel of rels) {
    const full = path.join(REPO_ROOT, rel);
    try {
      const st = fs.statSync(full);
      out[rel] = { present: true, size: st.size, hash: sha256(fs.readFileSync(full)) };
    } catch {
      out[rel] = { present: false, size: 0, hash: "" };
    }
  }
  return out;
}

/**
 * Existence + per-file size and content hash of a directory subtree.
 *
 * Comparable WHETHER OR NOT the directory exists, so the same assertion holds
 * before the first real rotation and forever after it: this suite must stay
 * green after the tool has legitimately been used on the live tree.
 */
export function snapshotDirState(dir) {
  if (!fs.existsSync(dir)) return { exists: false, entries: {} };
  const entries = {};
  const walk = (d) => {
    for (const entry of fs.readdirSync(d, { withFileTypes: true }).sort((a, b) =>
      a.name < b.name ? -1 : 1
    )) {
      const full = path.join(d, entry.name);
      if (entry.isDirectory()) walk(full);
      else if (entry.isFile()) {
        entries[path.relative(dir, full)] = {
          size: fs.statSync(full).size,
          hash: sha256(fs.readFileSync(full)),
        };
      }
    }
  };
  walk(dir);
  return { exists: true, entries };
}

/**
 * Differences between two snapshots, as human-readable lines. An empty list is
 * the pass condition.
 *
 * PURE with respect to its arguments: `nowFiles` / `nowArchive` may be supplied
 * so a test can drive every branch — including CREATED and NO LONGER PRESENT —
 * without going anywhere near the real tree. Omitted, they are read live.
 */
export function driftAgainst(fileBaseline, archiveBaseline, nowFiles = null, nowArchive = null) {
  const drift = [];
  const now = nowFiles ?? snapshotFiles(Object.keys(fileBaseline));
  for (const [rel, was] of Object.entries(fileBaseline)) {
    const is = now[rel] ?? { present: false, size: 0, hash: "" };
    if (was.present && !is.present) {
      drift.push(`${rel}: NO LONGER PRESENT (was ${was.size} B)`);
    } else if (!was.present && is.present) {
      drift.push(`${rel}: CREATED BY THIS RUN (${is.size} B)`);
    } else if (was.present && is.present && is.hash !== was.hash) {
      drift.push(
        `${rel}: CONTENT CHANGED (${was.size} B -> ${is.size} B, ` +
          `${was.hash.slice(0, 12)} -> ${is.hash.slice(0, 12)})`
      );
    }
  }
  const arch = nowArchive ?? snapshotDirState(REAL_ARCHIVE_DIR);
  if (arch.exists !== archiveBaseline.exists) {
    drift.push(`${REAL_ARCHIVE_REL}/: ${archiveBaseline.exists ? "REMOVED" : "CREATED BY THIS RUN"}`);
  } else if (JSON.stringify(arch.entries) !== JSON.stringify(archiveBaseline.entries)) {
    drift.push(`${REAL_ARCHIVE_REL}/: CONTENTS CHANGED`);
  }
  return drift;
}

/* ------------------------------------------------------------------ */
/* the baselines, and the exit handler, in that order                  */
/* ------------------------------------------------------------------ */

export const BASELINE_FILES = snapshotFiles();
export const BASELINE_ARCHIVE = snapshotDirState(REAL_ARCHIVE_DIR);

/** Drift of the real tree, right now, against the load-time baseline. */
export const currentDrift = () => driftAgainst(BASELINE_FILES, BASELINE_ARCHIVE);

/*
 * Registered BEFORE the coverage scan below, which can throw: a run that dies
 * during import must still report real-tree damage done before it died.
 *
 * Setting `process.exitCode` from an `exit` handler is honoured by Node, and the
 * test runner reports a non-zero child exit as a failed test file. So this turns
 * the whole run red even when every subtest passed.
 *
 * IT IS NOT THE LAST WORD, AND IS NOT WRITTEN AS IF IT WERE. `exit` handlers run
 * in registration order and the last write to `process.exitCode` wins, so a
 * later handler can set it back to 0, and `removeAllListeners("exit")` can take
 * this one out of the list entirely. Both were demonstrated, on a clone, at exit
 * 0 with the tree destroyed.
 *
 * Neither is defended HERE, and the reason is a trade rather than an oversight.
 * Throwing from this handler does abort the handlers registered after it — that
 * was measured too — but the handler registered after it in this suite is the
 * one that removes the session's temp directory. Buying a defence that one more
 * hostile line steps around, at the price of certain `/tmp` residue on every
 * genuine drift, is a bad trade. The defence against both lives OUTSIDE this
 * process, in `run-tests.sh`, where no exit handler reaches.
 */
process.on("exit", () => {
  let drift;
  try {
    drift = currentDrift();
  } catch (e) {
    drift = [`the real-memory tripwire could not read the real tree: ${e.message}`];
  }
  if (drift.length === 0) return;
  process.stderr.write(
    `\n=== REAL BUILD OS MEMORY WAS MUTATED BY THIS TEST RUN ===\n` +
      drift.map((d) => `  ${d}\n`).join("") +
      `No test in build-os/maintenance/ may write to the real tree.\n` +
      `\`git status\` DOES show the archive appear (one \`??\` line on the directory), but\n` +
      `that one line reads the same however its contents changed, and nothing under it\n` +
      `has version-control backing until it is committed. The hashes above, not git,\n` +
      `are what detected this.\n` +
      `Restore from git and find the invocation that reached the real root.\n`
  );
  process.exitCode = 1;
});

/* ------------------------------------------------------------------ */
/* coverage: a BEST-EFFORT check for the unsanctioned `node --test` path */
/* ------------------------------------------------------------------ */

/** The specifier a suite file must import to be covered. */
export const TRIPWIRE_SPECIFIER = "./real-memory-tripwire.mjs";

/**
 * Which of `files` (as `[relPath, source]`) fail to arm the tripwire first.
 *
 * WHAT THIS IS FOR, NOW THAT THE PRELOAD EXISTS. Under `run-tests.sh` this scan
 * decides nothing about safety: the tripwire is already armed by `--import`
 * before any of these files is read. It is a convenience check for the person
 * who types a bare `node --test`, which takes no preload — on that path the
 * file's own first module request really is what runs first, and this reports
 * any file where that is not the tripwire AS THE MASK READS THE FILE.
 *
 * THAT QUALIFIER IS THE WHOLE ACCURACY OF THIS FUNCTION and it is not a hedge.
 * `moduleRequestSpecifiers` reports what a heuristic lexer can see; a file can
 * be written so a real static import is inside a span the mask blanks, and then
 * this returns nothing while the loader runs the import first. The shape is in
 * `source-scan.mjs` and in this file's header. DO NOT READ AN EMPTY RESULT FROM
 * THIS FUNCTION AS "the bare path is covered". It is not; the preload and the
 * shell fingerprints are.
 *
 * FIRST, not merely present: static module requests are evaluated in source
 * order, so a request above the tripwire's runs before the baseline is taken.
 * `moduleRequestSpecifiers` finds them AT ANY COLUMN, in a comment- and
 * string-masked copy of the source. The previous line-anchored version could
 * not see an import that began at column 1.
 */
export function coverageFindings(files, specifier = TRIPWIRE_SPECIFIER) {
  const findings = [];
  if (files.length === 0) {
    findings.push(
      `COVERAGE: no *.test.mjs was found beside the tripwire — the coverage scan is ` +
        `pointed at nothing and would pass vacuously`
    );
  }
  for (const [rel, src] of files) {
    const specs = moduleRequestSpecifiers(src);
    const at = specs.indexOf(specifier);
    if (at === -1) {
      findings.push(
        `COVERAGE: ${rel} does not import ${specifier}. Run alone, that file has no ` +
          `real-memory tripwire: one appended line in it can rewrite live Build OS ` +
          `memory and the run still exits 0. The four watched files are TRACKED, so ` +
          `git status does show such a rewrite; what is missing is the RUN FAILING on it.`
      );
    } else if (at !== 0) {
      findings.push(
        `COVERAGE: ${rel} imports ${specifier}, but as import #${at + 1} of ` +
          `${specs.length}. It must be the FIRST import, so the baseline is taken ` +
          `before any other module in the file can run.`
      );
    }
  }
  return findings;
}

/** Every `*.test.mjs` under `dir`, as paths relative to `dir`, sorted. */
export function listSuiteFiles(dir) {
  const out = [];
  const walk = (d) => {
    for (const entry of fs.readdirSync(d, { withFileTypes: true }).sort((a, b) =>
      a.name < b.name ? -1 : 1
    )) {
      const full = path.join(d, entry.name);
      if (entry.isDirectory()) walk(full);
      else if (entry.isFile() && entry.name.endsWith(".test.mjs")) {
        out.push(path.relative(dir, full));
      }
    }
  };
  walk(dir);
  return out;
}

export const SUITE_FILES = listSuiteFiles(HERE);

export const COVERAGE_FINDINGS = coverageFindings(
  SUITE_FILES.map((rel) => [rel, fs.readFileSync(path.join(HERE, rel), "utf8")])
);

if (COVERAGE_FINDINGS.length > 0) {
  throw new Error(
    `THE REAL-MEMORY TRIPWIRE IS NOT ARMED EVERYWHERE:\n  ` +
      COVERAGE_FINDINGS.join("\n  ") +
      `\nAdd \`import "${TRIPWIRE_SPECIFIER}";\` as the first import of each file listed.`
  );
}
