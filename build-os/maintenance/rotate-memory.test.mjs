/**
 * GRAVITO:MANAGED — shipped by build-os/maintenance/install-maintenance.sh.
 * Edits made in an installed repo are REPLACED on the next install. Change it
 * upstream, or unmanage it by removing the path from .gravito-managed.
 *
 * Tests for build-os/maintenance/rotate-memory.sh
 *
 * Run: ./build-os/maintenance/run-tests.sh
 *
 * -------------------------------------------------------------------------
 * THE GUARANTEE, STATED EXACTLY. NOTHING OUTSIDE THIS SENTENCE IS CLAIMED.
 * -------------------------------------------------------------------------
 *
 *   A run under `./build-os/maintenance/run-tests.sh` cannot report success
 *   after moving the real tree between the two shell fingerprints, provided the
 *   `sha256sum`/`shasum` resolved at startup is the real one and no write is
 *   scheduled to land after node exits.
 *
 * The paths that sentence does NOT cover, named here as well as in the
 * wrapper's own header, because a reader who starts in this file must not have
 * to find the other one — these four, and no others:
 *
 *   - a hostile `sha256sum`/`shasum` already on PATH AT INVOCATION. The hasher
 *     is resolved once, at startup, through PATH, so resolution cannot outrank a
 *     PATH that was already hostile when the command was typed. A binary planted
 *     DURING the run is NOT in scope: it is never picked up. (`cut` is not in
 *     this sentence at all — the wrapper does not run it; the hash field is
 *     taken with a bash parameter expansion.)
 *   - a write scheduled to land after node exits: a detached, unref'd child that
 *     sleeps past the second fingerprint. The delay is chosen by whoever wrote
 *     the line, so no later fingerprint closes it.
 *   - a bare `node --test`, in every form. No preload, no outer fingerprint,
 *     and the in-process coverage scan's source mask has now been defeated three
 *     times — most recently by one line carrying two division-position regexes,
 *     which is pinned as a residual in section 10b below. That path is
 *     UNGUARDED. It is not "guarded, late".
 *   - hostile tampering with the wrapper shell itself — a test body that kills
 *     it before the second fingerprint is taken, or otherwise subverts the shell
 *     the fingerprints run in.
 *
 * (A test body that damages the real tree and restores it BYTE-FOR-BYTE before
 * the run ends is deliberately not in that list: byte-identical restoration is
 * indistinguishable from no damage by content hash, and is also not damage.)
 *
 * -------------------------------------------------------------------------
 * WHAT "CONTAINED" MEANS HERE, AND WHAT IT DOES NOT
 * -------------------------------------------------------------------------
 * Containment here is discoverability plus out-of-process detection via the
 * sanctioned wrapper, not enforcement: nothing prevents a hand-run bare
 * `node --test`, which takes no preload and no outer fingerprint.
 *
 * `npm run test:build-os-memory` is that same wrapper, exposed in package.json —
 * WHERE THE REPO HAS ONE — so it is findable from the repo root instead of only
 * by already knowing its path. This layer installs into repos that may have no
 * package.json at all, so that signpost is conditional; both halves of it are
 * pinned in rotate-memory.rootscan.test.mjs, which asserts the entry is exactly
 * the wrapper invocation and that no package script points a bare runner at
 * build-os/, and asserts the documented-path fallback where there is no manifest.
 * Neither half shortens the list of four above by one item.
 *
 * The two lines that turn detection into a failed run — the tripwire's
 * `process.exitCode = 1` and the wrapper's `BEFORE != AFTER` comparison — are
 * pinned in section 10c here and in rotate-memory.rootscan.test.mjs
 * respectively. They are mutually redundant, so no single edit yields
 * green-with-damage; the pins exist to keep that true.
 *
 * THAT COMMAND, NOT A BARE `node --test`. The wrapper preloads the real-memory
 * tripwire with `--import`, so it is armed before this file's first import — at
 * whatever column that import happens to be written — and it fingerprints the
 * four watched real memory files and the real archive in the shell, before and after,
 * where no exit handler inside node reaches. Running one file with a bare
 * `node --test` gives up both; run-tests.sh's own header says what that costs
 * and what it still does not cover.
 *
 * DELIBERATELY node:test AND DELIBERATELY CONFINED TO THIS DIRECTORY. This suite
 * ships into repos whose own test framework is unknown and none of its business:
 * it uses only `node:test` from the Node already required to run the rotation
 * tool, adds no dependency, and lives entirely under build-os/maintenance/, so it
 * cannot perturb whatever baseline the host repo runs. It is not registered with
 * the host's runner; the wrapper is the entry point.
 *
 * -------------------------------------------------------------------------
 * NO TEST IN THIS FILE INVOKES THE TOOL WITHOUT AN EXPLICIT SCRATCH `--root`.
 * -------------------------------------------------------------------------
 * That sentence is the RULE. It is NOT the same as the proof. What mechanically
 * enforces it, and what it leaves unenforced, is stated exactly below.
 *
 * WHY, PRECISELY. Three tests used to run `--root REPO_ROOT` without `--apply`
 * and lean on the tool's apply gate to keep them harmless. A ONE-LINE defect in
 * that gate turns this suite into a program that rotates the real Build OS
 * memory: all three live files rewritten, a multi-megabyte
 * build-os/memory/archive/ created. That was demonstrated, not hypothesised.
 * `git status` does show that archive appear, now that `.gitignore` un-ignores
 * it — but while it is untracked, status reports at most one `??` line for the
 * whole directory, identical whether a file inside was added, rewritten, or
 * removed (measured), so the check everyone uses cannot see the CONTENT damage.
 *
 * Worse than passing REPO_ROOT is OMITTING `--root`. The tool resolves
 * `opts.root ?? path.join(here, "..", "..")` — see `main()` in rotate-memory.mjs
 * — so its default root IS the real repo: correct for production, where the
 * archivist points it at the live tree on purpose, and lethal from a test. A
 * suite that only scans its own source for the token `REPO_ROOT` stays green
 * with a rootless applying invocation sitting in it. That is not hypothetical;
 * it passed a full green suite in an earlier round.
 *
 * HOW THE RULE IS ENFORCED — THREE MECHANISMS: RUNTIME, SOURCE-LEVEL, AND A
 * PROCESS-WIDE TRIPWIRE THAT BOUNDS WHAT THE OTHER TWO MISS.
 *
 * `run`, `runJson` and `runNodeJson` all call `requireScratchRoot` before
 * spawning anything. It throws unless the ACTUAL argument list carries an
 * explicit `--root` whose value, RESOLVED THROUGH SYMLINKS, lies outside
 * REPO_ROOT and under this run's temp dir. Both sides of both comparisons are
 * real paths: REPO_ROOT and SESSION_TMP are themselves resolved through
 * symlinks at module load, and each `--root` value is resolved through its
 * deepest existing ancestor (the root usually does not exist yet at gate time).
 * The lexical `path.resolve` checks are kept as well — realpath was ADDED, not
 * substituted.
 *
 * Because it reads the real argument list, none of the dressing that defeats a
 * source scan helps: an alias, a helper closing over the root, a default
 * parameter, a recomputed `path.resolve(HERE,"..","..")`,
 * `path.join(REPO_ROOT,".")`, object indirection, a relative root with
 * `{ cwd: REPO_ROOT }`, or a SYMLINK under the temp dir that points back out of
 * it. There is no rootless call path through the wrappers. The single exemption
 * is `--help`, which returns from `main()` before the root is computed at all.
 *
 * THE SECOND MECHANISM IS IN ANOTHER FILE, ON PURPOSE.
 *
 * `rotate-memory.rootscan.test.mjs` reads THIS file as data and reports any
 * wrapper call written here that omits `--root`, names a real-memory root, or
 * starts a child process outside the two gated wrapper bodies — whether or not
 * that call is ever executed. It never imports, spawns or invokes the rotation
 * tool, so there is nothing about it to guard.
 *
 * It lives in a separate file because a token-forbidding scanner written INSIDE
 * the file it scans must exempt the span that names the tokens, and that span is
 * executable code. The previous in-file scanner's list self-matched 23 times and
 * five rounds of patching kept finding holes in its exemptions. Cross-scanning
 * removes the fixed point: no file is the sole judge of itself. This file
 * returns the favour below, in "the root scanner can acquire nothing that starts
 * a process". Every deliberately dangerous control shape either half uses lives
 * in `rootscan-controls.json`, which cannot execute, so neither half needs a
 * carve-out for its own controls.
 *
 * THE THIRD MECHANISM IS A MODULE EVERY SUITE FILE IMPORTS.
 *
 * `real-memory-tripwire.mjs` baselines the four watched real memory files and the
 * real archive directory at load, and fails the run at exit if either moved. Under
 * the sanctioned command it is loaded by `--import`, BEFORE this file's module
 * graph is touched. It is also the first import of this file and of every other
 * `*.test.mjs` here — which is a CONVENTION, kept because it makes a bare run
 * better than nothing, and NOT a mechanism: a bare `node --test` is not covered
 * by it, because the file's own first import is whatever the file says it is.
 * Its load-time coverage scan reports any suite file in this directory that does
 * not request it first AS A HEURISTIC SOURCE MASK READS THAT FILE — a mask that
 * has been defeated three times, most recently by the shape pinned in section
 * 10b. As a preload, that report aborts the run before the offending file
 * executes; that part is a mechanism.
 *
 * It exists because an earlier round of this layer — in the reference deployment
 * it was built in, before the port — put this check at the bottom of THIS file
 * only, which left the cross-scanner (a file that binds the real repo root and
 * holds a filesystem binding) completely unguarded. One appended line in it
 * destroyed that repo's live memory at 0 fail / exit 0: a fully green run.
 *
 * -------------------------------------------------------------------------
 * WHAT IS *NOT* ENFORCED. Named, not papered over.
 * -------------------------------------------------------------------------
 *   1. AN ALIAS OF THE ALREADY-IMPORTED `spawnSync` IS STILL NOT DETECTED.
 *      `const s = spawnSync; s(...)` adds no import, so the cross-scan does not
 *      see it, and it never routes through a wrapper, so the runtime gate never
 *      runs. What CHANGED is not detection but consequence: if such a call
 *      reaches the real tree, the tripwire turns the run red at exit — on any
 *      path where the tripwire actually loaded, and provided no later exit
 *      handler unwinds the exit code. Under the sanctioned command the shell
 *      fingerprints make it unconditional. The shape is undetected; its damage
 *      is bounded. Do not read the second half as the first.
 *   2. THE CROSS-SCAN IS ENUMERATED, NOT UNIVERSAL. It reports a listed set of
 *      shapes on a listed set of files. It does not prove the real tree is
 *      unreachable from arbitrary source. Four specific misses are named in that
 *      file's header, with what does and does not cover each.
 *   3. A ROOT VALUE COMPUTED AT RUNTIME is invisible to the cross-scan; only the
 *      runtime gate sees the actual string.
 *   4. A BRAND-NEW TEST FILE, RUN ALONE UNDER A BARE `node --test`, is only as
 *      covered as its own first import. If it imports the tripwire late, what
 *      ran above that import has already run; if it imports nothing at all,
 *      nothing loads the tripwire and nothing runs the coverage scan. Both were
 *      measured at exit 0 with the real tree destroyed. Under the sanctioned
 *      command — `./build-os/maintenance/run-tests.sh` — neither happens: the
 *      preload arms the tripwire and runs the coverage scan before any test file
 *      is loaded, and both shapes give exit 1 with the tree untouched.
 *
 * The claim is exactly this: every wrapper call that RUNS is gated on its real
 * argument list against symlink-resolved paths; every wrapper call that is
 * WRITTEN here — dead or live — is checked for the enumerated bad shapes; and
 * whatever both of those miss, the real tree is hashed before and after every
 * run UNDER THE SANCTIONED COMMAND, so damage cannot pass as a green suite
 * there. Under any other invocation the last clause does not hold at all.
 *
 * The tests keep their full value — the real-content section still exercises
 * THIS repo's own live memory files, byte for byte, on scratch copies
 * (`realCopyRoot`), at whatever size and block count they happen to have.
 *
 * BE PRECISE ABOUT WHAT THAT BUYS: it is a real-CONTENT proof, not a proof at
 * any particular SCALE. Nothing in this suite pins how big the files it reads
 * are, and in a repo whose memory is small every real-content assertion here is
 * true of a small file. Scale is pinned only where a test states its own
 * fixture size. (In the reference deployment at commit `cb2bb7d` these files
 * were ~900/830/705 KB — that is the pressure the layer was built under, it is
 * a fact about that tree at that commit, and it says nothing about yours.)
 *
 * The apply gate is NOT the safety mechanism here. It is one of the things under
 * test.
 *
 * -------------------------------------------------------------------------
 * THIS SUITE MUST STAY GREEN AFTER A REAL --apply.
 * -------------------------------------------------------------------------
 * An explicit design constraint, not an accident: the archive is append-only and
 * is never deleted, so any assertion of the form "the real archive does not
 * exist" goes false forever the moment the tool is used for its one intended
 * purpose, and every later run of this suite would be red. Assertions about the
 * real tree are therefore written as DIFFERENCE invariants (nothing changed)
 * that hold whether or not the archive already exists.
 *
 * -------------------------------------------------------------------------
 * THE SUITE CLEANS UP AFTER ITSELF.
 * -------------------------------------------------------------------------
 * Every scratch root and every mutated tool copy is created UNDER `SESSION_TMP`,
 * one directory removed on process exit. A previous version left 44 directories
 * and 242 MB of mutated .mjs copies in /tmp per run, accumulating forever.
 */

/*
 * FIRST IMPORT, DELIBERATELY. Importing it arms the process-wide real-memory
 * tripwire: it baselines the real tree before anything else in this file runs,
 * and fails the run at exit if the real tree moved. Its position is not a
 * convention — `coverageFindings` in that module asserts it, for this file and
 * every other `*.test.mjs` in this directory, from whichever one you run.
 */
import {
  BASELINE_FILES,
  BASELINE_ARCHIVE,
  REAL_MEMORY_FILES,
  REAL_ARCHIVE_REL,
  SUITE_FILES,
  TRIPWIRE_SPECIFIER,
  currentDrift,
  driftAgainst,
  coverageFindings,
  snapshotFiles,
} from "./real-memory-tripwire.mjs";
import {
  moduleImportsOf,
  indirectAcquisitionFindings,
  maskNonCode,
  moduleRequestSpecifiers,
} from "./source-scan.mjs";
import { test, describe } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";

import {
  FILE_SPECS,
  DEFAULT_KEEP,
  DEFAULT_MAX_BYTES,
  EXIT,
  BANNER_START,
  BANNER_END,
  BANNER_MAX_LINES,
  segmentFile,
  assertSegmentPartition,
  routeSegments,
  findTrailingBanner,
  stripTrailingBanner,
} from "./rotate-memory.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const SCRIPT = path.join(HERE, "rotate-memory.sh");
const TOOL_MJS = path.join(HERE, "rotate-memory.mjs");
/**
 * THIS FILE DOES READ ITS OWN SOURCE, and it is worth saying so plainly because
 * a previous comment in the cross-scanner asserted the opposite — "neither file
 * scans itself, therefore neither file needs a single exemption".
 *
 * It is used for ONE thing: asserting that a documentation sentence is still in
 * the header. That needs no exemption, because it is a search for a sentence
 * rather than a prohibition on a token — nothing about it becomes false by being
 * written here.
 *
 * The self-scan that DID need an exemption is gone. It counted the child-process
 * module specifier in this text and required exactly one, which forced the test
 * to spell the specifier as `"node:" + "child_process"` so its own mention would
 * not count — an exemption device, and the same two-fragment trick a review then
 * used to obtain a spawn API while the count still read one. The count now lives
 * in rotate-memory.rootscan.test.mjs, which folds concatenations before it looks.
 */
const SUITE_SRC = fs.readFileSync(fileURLToPath(import.meta.url), "utf8");

/**
 * `path.resolve` collapses `..` LEXICALLY and does not follow symlinks, so a
 * symlink `SESSION_TMP/x -> REPO_ROOT` resolves to a path that is textually
 * under the temp dir and textually outside the repo, while actually BEING the
 * repo. Both containment tests in `requireScratchRoot` would pass and the tool
 * would rotate the real memory. Every path either side of those tests is
 * therefore put through this first.
 *
 * A scratch root usually does not exist yet when the gate runs, and
 * `fs.realpathSync` throws on a missing path. So: walk up to the DEEPEST
 * EXISTING ancestor, resolve that through its symlinks, and re-join the
 * non-existent tail. The tail cannot itself be a symlink — it does not exist.
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
      // filesystem root reached without finding anything that exists
      if (parent === cur) return path.resolve(p);
      tail.unshift(path.basename(cur));
      cur = parent;
    }
  }
}

/**
 * READ-ONLY. The real repo root is used to COPY the genuine memory files into
 * scratch roots and to assert the real tree did not change. It is never passed
 * to the tool — see the header, and the test that enforces it.
 *
 * Resolved through symlinks so it is the same string a symlink-resolved
 * `--root` produces when it points here.
 */
const REPO_ROOT = realpathDeep(path.resolve(HERE, "..", ".."));

/**
 * One temp directory for the whole run, removed on exit. Every scratch root and
 * every mutated tool copy lives under it, so the suite cannot leak into /tmp.
 *
 * Resolved through symlinks: `os.tmpdir()` is itself a symlink on some
 * platforms (macOS `/tmp -> /private/tmp`), and if SESSION_TMP kept the
 * unresolved spelling then every legitimate scratch root — which IS resolved —
 * would fail the containment test. Normalising both sides keeps the happy path
 * green rather than trading one defect for a false positive.
 */
const SESSION_TMP = realpathDeep(fs.mkdtempSync(path.join(os.tmpdir(), "rotmem-suite-")));
process.on("exit", () => {
  try {
    fs.rmSync(SESSION_TMP, { recursive: true, force: true });
  } catch {
    /* best effort: a leaked temp dir must never fail the run */
  }
});

/** The exact bytes a rendered banner ends with. Mirrors the tool, on purpose. */
const BANNER_TAIL = `${BANNER_END}\n\n`;

/* ------------------------------------------------------------------ */
/* helpers                                                             */
/* ------------------------------------------------------------------ */

/**
 * SESSION_TMP must itself be outside the repo, or the scratch-root gate below
 * would be checking containment in something that is inside the blast radius.
 * Asserted at module load, before any test runs.
 */
if (SESSION_TMP === REPO_ROOT || SESSION_TMP.startsWith(REPO_ROOT + path.sep)) {
  throw new Error(`the session temp dir ${SESSION_TMP} is inside the repo ${REPO_ROOT}`);
}

/*
 * THE THREE WRAPPERS. Every child process this suite starts is started by one
 * of them, and every one of them calls `requireScratchRoot` first. Nothing here
 * is enforced by reading this file's source — see the header for exactly what
 * that leaves unproven.
 */

/**
 * THE SCRATCH-ROOT GATE. Throws before any process is spawned unless `args`
 * carries an explicit `--root` whose value resolves outside REPO_ROOT and
 * under this run's temp directory.
 *
 * WHY THIS IS A RUNTIME GATE AND NOT A SOURCE SCAN. `rotate-memory.mjs` line
 * `const root = path.resolve(opts.root ?? path.join(here, "..", ".."))` makes
 * the REAL repo the default root. That default is right for production — the
 * archivist runs this tool against the real repo, that is its whole job — but
 * it means an invocation from this suite that merely FORGETS `--root` rotates
 * the live Build OS memory. A scan of this file's source text cannot see that:
 * the root can arrive through an alias, a helper that closes over it, a default
 * parameter, a recomputed `path.resolve(HERE, "..", "..")`, or object
 * indirection. Checking the ACTUAL argument list at the ACTUAL call site is
 * blind to all of that dressing, so there is no rootless call path left.
 *
 * `--root` is checked at EVERY position it occupies, not just the last: the
 * tool's parseArgs takes the last one, so checking only the last would let
 * an earlier repo-rooted value pass unexamined if the parser ever changed.
 *
 * The value is resolved against the SPAWN's cwd, not this process's, so a
 * relative `--root` combined with `{ cwd: REPO_ROOT }` resolves the same way
 * the tool will resolve it.
 *
 * THE ONE EXEMPTION is `--help` (optionally with `--json`): `main()` returns
 * at `if (opts.help)` before the root is computed at all, so a help run cannot
 * reach any path. `--apply`, `--file`, `--keep` etc. alongside it are NOT
 * exempt.
 */
function requireScratchRoot(who, args, spawnOpts) {
  if (!Array.isArray(args)) {
    throw new Error(`${who}: refused — args must be an array (got ${typeof args})`);
  }
  const list = args.map(String);

  const helpish = (a) => a === "--help" || a === "-h";
  if (list.some(helpish) && list.every((a) => helpish(a) || a === "--json")) return;

  const cwd = spawnOpts && spawnOpts.cwd !== undefined ? String(spawnOpts.cwd) : process.cwd();
  const positions = [];
  for (let i = 0; i < list.length; i++) if (list[i] === "--root") positions.push(i);

  if (positions.length === 0) {
    throw new Error(
      `${who}: refused — this invocation carries no explicit --root, and the tool's ` +
        `DEFAULT root is the real repo (${REPO_ROOT}). A rootless run rotates the live ` +
        `Build OS memory. git status would show the archive it creates, but as one ` +
        `\`??\` line that reads the same however its contents changed. Pass a scratch ` +
        `root, e.g. ` +
        `${who}(["--root", makeRoot("label"), ...]). args=${JSON.stringify(list)}`
    );
  }
  for (const i of positions) {
    if (i === list.length - 1) {
      throw new Error(`${who}: refused — --root is the last argument and has no value`);
    }
    const raw = list[i + 1];
    /*
     * BOTH spellings are checked: the lexical resolution AND the same path
     * resolved through symlinks. Lexical alone is defeated by a symlink under
     * the temp dir pointing anywhere else; realpath alone would be the only
     * check standing if `fs.realpathSync` ever mis-resolved. Realpath was added
     * to the lexical checks, not substituted for them.
     */
    const resolved = path.resolve(cwd, raw);
    const real = realpathDeep(resolved);
    const inside = (p, dir) => p === dir || p.startsWith(dir + path.sep);

    for (const candidate of new Set([resolved, real])) {
      const how = candidate === resolved ? "resolves to" : "resolves, THROUGH SYMLINKS, to";
      if (inside(candidate, REPO_ROOT)) {
        throw new Error(
          `${who}: refused — --root ${JSON.stringify(raw)} ${how} ${candidate}, which is ` +
            `inside the REAL repo root ${REPO_ROOT}. Point it at a scratch copy ` +
            `(makeRoot / realCopyRoot). The apply gate is NOT the safety mechanism.`
        );
      }
      if (!inside(candidate, SESSION_TMP)) {
        throw new Error(
          `${who}: refused — --root ${JSON.stringify(raw)} ${how} ${candidate}, which is ` +
            `not under this run's temp dir ${SESSION_TMP}. Scratch roots come from ` +
            `tmpRoot/makeRoot/realCopyRoot so they are removed on exit.`
        );
      }
    }
  }
}

function run(args, opts = {}) {
  requireScratchRoot("run", args, opts);
  const res = spawnSync("bash", [SCRIPT, ...args], {
    encoding: "utf8",
    ...opts,
  });
  return {
    status: res.status,
    stdout: res.stdout ?? "",
    stderr: res.stderr ?? "",
    all: (res.stdout ?? "") + (res.stderr ?? ""),
  };
}

function runJson(args, opts = {}) {
  // gated here as well as in `run`: a refactor that stops delegating must not
  // silently drop the gate
  requireScratchRoot("runJson", args, opts);
  const res = run([...args, "--json"], opts);
  let parsed = null;
  try {
    parsed = JSON.parse(res.stdout);
  } catch {
    /* leave null; caller asserts on status/stderr */
  }
  return { ...res, json: parsed };
}

/**
 * Run a specific .mjs directly (used by the MUTATION tests below, which need to
 * execute a deliberately corrupted COPY of the tool rather than the shipped one).
 *
 * A corrupted copy is the MOST dangerous thing this suite runs — its guards are
 * deliberately broken — so it is gated exactly like the others.
 */
function runNodeJson(mjs, args, opts = {}) {
  requireScratchRoot("runNodeJson", args, opts);
  const res = spawnSync(process.execPath, [mjs, ...args, "--json"], {
    encoding: "utf8",
    ...opts,
  });
  let parsed = null;
  try {
    parsed = JSON.parse(res.stdout ?? "");
  } catch {
    /* leave null */
  }
  return {
    status: res.status,
    stdout: res.stdout ?? "",
    stderr: res.stderr ?? "",
    all: (res.stdout ?? "") + (res.stderr ?? ""),
    json: parsed,
  };
}

/* end of the wrappers */

const sha256 = (buf) => crypto.createHash("sha256").update(buf).digest("hex");
const md5 = (s) => crypto.createHash("md5").update(s, "utf8").digest("hex");
const escapeRe = (s) => s.replace(/[.*+?^${}()|[\]\\-]/g, "\\$&");
const countOf = (hay, needle) => (hay.match(new RegExp(escapeRe(needle), "g")) ?? []).length;

/**
 * Write a CORRUPTED copy of rotate-memory.mjs into a temp dir and return its
 * path.
 *
 * WHY THIS EXISTS. Several of the tool's guards are unreachable from the CLI
 * while the code is correct — that is what makes them guards. A suite that only
 * drives the CLI therefore cannot tell a live guard from a dead one, which is
 * exactly how a silent-data-loss defect shipped: the arithmetic that was
 * supposed to catch it was derived from the already-corrupted string. Each
 * mutation below reintroduces one specific defect and asserts the guard fires
 * with its real exit code and writes nothing.
 *
 * Each edit anchor is asserted PRESENT and UNIQUE, so a refactor that moves the
 * code these tests are about fails loudly instead of silently testing nothing.
 */
function mutatedTool(label, edits) {
  const dir = fs.mkdtempSync(path.join(SESSION_TMP, `mut-${label}-`));
  const src = fs.readFileSync(TOOL_MJS, "utf8");
  let out = src;
  for (const [from, to] of edits) {
    assert.equal(
      out.split(from).length - 1,
      1,
      `mutation anchor must appear exactly once in rotate-memory.mjs: ${JSON.stringify(from)}`
    );
    out = out.replace(from, to);
  }
  assert.notEqual(out, src, "mutation produced no change");
  const mjs = path.join(dir, "rotate-memory.mjs");
  fs.writeFileSync(mjs, out, "utf8");
  return mjs;
}

/**
 * The M18 mutation: replace the positionally anchored banner strip with the
 * unanchored `indexOf(BANNER_START)` applied to EVERY retained segment.
 *
 * This is the exact defect that destroyed 117 bytes of a retained block while
 * every self-reported number balanced and the run exited 0.
 */
const M18_UNANCHORED_STRIP = [
  [
    "export const BANNER_MAX_LINES = 12;",
    `export const BANNER_MAX_LINES = 12;

function legacyUnanchoredStripBanner(text) {
  const s = text.indexOf(BANNER_START);
  if (s === -1) return text;
  const e = text.indexOf(BANNER_END, s);
  if (e === -1) return text;
  let end = e + BANNER_END.length;
  if (text[end] === "\\n") end++;
  if (text[end] === "\\n") end++;
  return text.slice(0, s) + text.slice(end);
}`,
  ],
  [
    "  const strip = stripTrailingBanner(parts[idx]);",
    `  for (let i = 0; i < parts.length; i++) parts[i] = legacyUnanchoredStripBanner(parts[i]);
  const strip = stripTrailingBanner(parts[idx]);`,
  ],
];

/** sha256 of every file under `root`, keyed by repo-relative path. */
function hashTree(root) {
  const out = {};
  const walk = (dir) => {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) walk(full);
      else if (entry.isFile()) out[path.relative(root, full)] = sha256(fs.readFileSync(full));
    }
  };
  walk(root);
  return out;
}

/**
 * Existence + per-file size, mtime and content hash of a directory subtree.
 *
 * Returns a comparable snapshot WHETHER OR NOT `dir` exists, so the same
 * assertion holds before the first real rotation and forever after it.
 */
function snapshotDir(dir) {
  if (!fs.existsSync(dir)) return { exists: false, entries: {} };
  const entries = {};
  const walk = (d) => {
    for (const entry of fs.readdirSync(d, { withFileTypes: true }).sort((a, b) =>
      a.name < b.name ? -1 : 1
    )) {
      const full = path.join(d, entry.name);
      if (entry.isDirectory()) walk(full);
      else if (entry.isFile()) {
        const st = fs.statSync(full);
        entries[path.relative(dir, full)] = {
          size: st.size,
          mtimeMs: st.mtimeMs,
          hash: sha256(fs.readFileSync(full)),
        };
      }
    }
  };
  walk(dir);
  return { exists: true, entries };
}

function tmpRoot(label) {
  return fs.mkdtempSync(path.join(SESSION_TMP, `${label}-`));
}

function writeFixture(root, relPath, content) {
  const full = path.join(root, relPath);
  fs.mkdirSync(path.dirname(full), { recursive: true });
  fs.writeFileSync(full, content, "utf8");
  return full;
}

/* ---------------------------- fixture builders --------------------- */

const CS_PREAMBLE = `# Current State

> The one-screen answer to "where is this project right now".
> The archivist prepends the newest block directly beneath this preamble.


`;

/**
 * current_state.md-shaped fixture: `## ` LATEST/PRIOR blocks, with prose `### `
 * sub-headers in the head region, MID-SEQUENCE, and in the tail. None of them is
 * special to the tool — that is the point: rotation is by RECENCY ONLY.
 *
 * THE HEADINGS ARE `## ` BECAUSE THE SPEC'S DELIMITER IS. In the reference
 * deployment `current_state.md` used blockquote `> **LATEST` / `> **PRIOR`
 * entries and this fixture matched that. The scaffold every installed repo gets
 * writes `##` sections instead, `FILE_SPECS.current_state` follows the scaffold,
 * and a fixture that did not follow both would parse to 0 blocks — which the
 * tool reports as a NO-OP at exit 0, so the whole current_state half of this
 * suite would have gone quietly vacuous rather than red. The LATEST/PRIOR
 * markers are kept inside the heading so the ordering assertions still read.
 *
 * The structural sections are `### ` so they stay INSIDE whatever block precedes
 * them, which is what makes them a test of "no section is exempt" rather than
 * three more blocks.
 */
function makeCurrentState({ nBlocks = 40, whereWeAreAfter = 15, bodyPad = 1 } = {}) {
  let out = CS_PREAMBLE;
  out += `### Project\n\nThe fixture project line.\n\n`;
  for (let i = 1; i <= nBlocks; i++) {
    const kind = i === 1 ? "LATEST" : "PRIOR";
    out += `## **${kind} (2026-07-${String(28 - (i % 28)).padStart(2, "0")}) — block ${i}** — headline ${i}\n`;
    for (let j = 0; j < bodyPad; j++) {
      out += `> **DETAIL ${j}:** body line ${j} of block ${i}\n`;
    }
    out += `>\n> ---\n\n`;
    if (i === whereWeAreAfter) {
      out += `### Where we are\n\nMid-sequence structural header.\n\n`;
    }
  }
  out += `### Stable facts (slow-changing)\n\n- a slow-changing fact\n- another slow-changing fact\n- a third\n`;
  return out;
}

const AP_PREAMBLE = `# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.


`;

/**
 * active_packet.md-shaped fixture: heterogeneous `## ` block headings, then
 * three structural sections in the tail. `## Gated steps` is the operator's
 * pending-deploy-go register. It is NOT protected by this tool — see the
 * "recency only" suite, which pins that behaviour down explicitly.
 */
function makeActivePacket({ nBlocks = 40, bodyPad = 1 } = {}) {
  const headings = [
    "## NO PACKET IN FLIGHT (2026-07-27, PACKET CLOSE) — `pkt_%d` CLOSED",
    "## PRIOR — NO PACKET IN FLIGHT (2026-07-18, PACKET CLOSE) — `pkt_%d` CLOSED",
    "## CLOSED — `pkt_%d`",
    "## ACTIVE — `pkt_%d`",
    "## JUST CLOSED — `pkt_%d`",
    "## Closed — pkt_%d",
    "## PARALLEL TRACKS (status at close %d)",
    "## IN PARALLEL (%d)",
  ];
  let out = AP_PREAMBLE;
  for (let i = 1; i <= nBlocks; i++) {
    out += headings[i % headings.length].replace("%d", String(i)) + "\n\n";
    for (let j = 0; j < bodyPad; j++) {
      out += `**WHAT CLOSED (${j}):** body line ${j} of block ${i}\n\n`;
    }
  }
  out += `## Gated steps (each needs explicit operator go)\n\n- deploy PR #202 — PENDING OPERATOR GO\n- flip content-risk flag — PENDING OPERATOR GO\n\n`;
  out += `## Next candidates (each needs its own packet + explicit go)\n\n- candidate a\n\n`;
  out += `## Branch base (for whichever packet is chosen next)\n\n- base \`origin/main\` = d5ae200\n`;
  return out;
}

const RES_PREAMBLE = `# Residue

> What was deferred, left behind, or noted as risk.


`;

/**
 * residue.md-shaped fixture. 114 blocks, of which exactly 57 use
 * `## PACKET CLOSE` and 57 use nine OTHER heading conventions. A delimiter
 * narrowed to `^## PACKET CLOSE` silently drops the other 57.
 */
function makeResidue({ nBlocks = 114 } = {}) {
  const others = [
    "## TRUTH-UP %d — stage-health recorder LIVE",
    "## PROJECT HANDOFF %d",
    "## MERGED + DEPLOYED %d",
    "## fixture_%d residue",
    "## CANONICAL ALIGNMENT %d — strategic backlog",
    "## Deferred (follow-up packets) %d",
    "## Known risks / debt %d",
    "## Conventions / gotchas %d",
    "## Open boundaries (awaiting explicit go) %d",
  ];
  let out = RES_PREAMBLE;
  let otherIdx = 0;
  for (let i = 1; i <= nBlocks; i++) {
    // even i -> PACKET CLOSE, odd i -> one of the nine other conventions
    if (i % 2 === 0) {
      out += `## PACKET CLOSE (2026-07-27) — \`pkt_${i}\`\n\n`;
    } else {
      out += others[otherIdx % others.length].replace("%d", String(i)) + "\n\n";
      otherIdx++;
    }
    out += `- residue line for block ${i}\n\n`;
  }
  return out;
}

/**
 * A residue-shaped fixture whose CONTENT is booby-trapped with the tool's own
 * banner markers, in every arrangement an unanchored strip would eat.
 *
 * `realBanner` must be the exact bytes of a banner the tool really rendered
 * (lifted off a rotated file), so the "content that is byte-identical to a real
 * banner" case is genuinely byte-identical rather than an approximation.
 *
 * Every trap appears TWICE: once among the newest blocks (retained region) and
 * once among the oldest (archive region).
 */
function makeMarkerAttackResidue(realBanner) {
  const B = BANNER_START;
  const E = BANNER_END;

  // preamble: markers present, but NOT at the tail — this is content
  let out = `# Residue (marker attack fixture)\n\n`;
  out += `> The archive-pointer markers are \`${B}\` and \`${E}\`.\n\n`;
  out += `${B}\nMID-PREAMBLE PAIR: not at the preamble tail, therefore content, therefore untouchable.\n${E}\n\n`;
  out += `Trailing preamble prose that sits AFTER that pair.\n\n`;

  const traps = (tag) => [
    `## ATTACK ${tag} a marker PAIR inside a block body\n\n` +
      `${B}\nEXACTLY THESE BYTES MUST SURVIVE ROTATION VERBATIM (${tag}).\n${E}\n\n`,
    `## ATTACK ${tag} markers inside a fenced code block\n\n` +
      "```\n" + B + `\nfenced body ${tag}: the fence must stand AND the body must stay\n` + E + "\n```\n\n",
    `## ATTACK ${tag} a lone unpaired START marker\n\n${B}\nno closing marker anywhere (${tag})\n\n`,
    `## ATTACK ${tag} a lone unpaired END marker\n\n${E}\nno opening marker anywhere (${tag})\n\n`,
    `## ATTACK ${tag} body byte-identical to a real rendered banner\n\n${realBanner}`,
    `## ATTACK ${tag} block ENDING in a real rendered banner\n\nprose first (${tag}).\n\n${realBanner}`,
  ];

  const filler = (tag, n) =>
    Array.from({ length: n }, (_, i) => `## PACKET CLOSE ${tag}-${i}\n\n- ordinary residue line ${i}\n\n`);

  // newest first: 10 retained blocks, then 10 that rotate away
  for (const b of [...traps("KEEP"), ...filler("keep", 4)]) out += b;
  for (const b of [...traps("ARCHIVE"), ...filler("archive", 4)]) out += b;
  return out;
}

/**
 * Rotate a throwaway fixture and return the exact banner bytes it wrote.
 *
 * Memoised: several suites need a REAL rendered banner, and a banner is only a
 * banner if it parses as one the tool emits, so an approximation written by hand
 * would not exercise the same path. Rotating one fixture once is cheaper than
 * rotating six.
 */
let CAPTURED_BANNER = null;
function captureRealBanner() {
  if (CAPTURED_BANNER !== null) return CAPTURED_BANNER;
  const root = makeRoot("capture-banner");
  assert.equal(run(["--root", root, "--file", "residue", "--keep", "10", "--apply"]).status, 0);
  const live = read(root, RETAINED.residue);
  const s = live.indexOf(BANNER_START);
  const e = live.indexOf(BANNER_TAIL, s);
  assert.ok(s >= 0 && e > s, "could not capture a rendered banner");
  CAPTURED_BANNER = live.slice(s, e + BANNER_TAIL.length);
  return CAPTURED_BANNER;
}

/** Build a complete fixture root with all three memory files. */
function makeRoot(label, overrides = {}) {
  const root = tmpRoot(label);
  writeFixture(
    root,
    "build-os/memory/current_state.md",
    overrides.current_state ?? makeCurrentState()
  );
  writeFixture(root, "build-os/memory/residue.md", overrides.residue ?? makeResidue());
  writeFixture(
    root,
    "build-os/packets/active_packet.md",
    overrides.active_packet ?? makeActivePacket()
  );
  return root;
}

const read = (root, rel) => fs.readFileSync(path.join(root, rel), "utf8");
/** Watched by the tripwire, never rotated — see the tripwire sandbox in section 10c. */
const STANDING_GATES_REL = "build-os/memory/standing_gates.md";
const RETAINED = {
  current_state: "build-os/memory/current_state.md",
  residue: "build-os/memory/residue.md",
  active_packet: "build-os/packets/active_packet.md",
};
const ARCHIVE = {
  current_state: "build-os/memory/archive/current_state.archive.md",
  residue: "build-os/memory/archive/residue.archive.md",
  active_packet: "build-os/memory/archive/active_packet.archive.md",
};

/**
 * Unqualified permanence claims. Any of these, in any string the tool writes
 * into memory, is a defect: memory is what the next session believes, and none
 * of these is true without saying WHOSE writes it is true of.
 */
const UNQUALIFIED_PERMANENCE_CLAIMS = [
  "nothing was deleted",
  "nothing is deleted",
  "nothing is ever deleted",
  "nothing here is ever deleted",
  "deletes nothing",
  "no content was deleted.",
  "deletes no content",
  "never deleted",
  "cannot be deleted",
  "nothing is ever lost",
  "byte-exact",
];

/** The banner region of a rotated file, or null. */
function bannerOf(text) {
  const s = text.indexOf(BANNER_START);
  if (s === -1) return null;
  const e = text.indexOf(BANNER_END, s);
  if (e === -1) return null;
  return text.slice(s, e + BANNER_END.length);
}

/* ------------------------------------------------------------------ */
/* EXTERNAL banner recognition — deliberately NOT the tool's           */
/* ------------------------------------------------------------------ */

/*
 * The shape of a banner the tool renders, restated here from the rendered bytes
 * rather than imported. THIS DUPLICATION IS THE POINT.
 *
 * `assertExternalReconstruction` used to define "the tool's own banner" by
 * calling the tool's own `stripTrailingBanner`. That made the reconstruction
 * blind to exactly the defect it exists to catch: if the strip over-reaches, the
 * expectation over-reaches with it and both sides agree on the wrong answer. An
 * external check that consults the thing it is checking is not an external
 * check. Every line below is asserted against a REAL rendered banner by
 * `the external banner recogniser agrees with the tool on a REAL banner`, so the
 * duplication cannot rot unnoticed.
 */
const EXT_BANNER_LINE_RE = [
  new RegExp(`^${escapeRe(BANNER_START)}$`),
  /^\*\*THIS FILE IS NOT THE WHOLE RECORD\.\*\* \d+ older blocks \(\d+ B\) were rotated out of it; \d+ newest blocks \(\d+ B\) remain here\.$/,
  /^$/,
  /^- batch: `[^`\n]+`$/,
  /^- archive: `build-os\/memory\/archive\/[A-Za-z0-9_]+\.archive\.md`$/,
  /^- index: `build-os\/memory\/archive\/INDEX\.md`$/,
  /^- rotation is by RECENCY ONLY\. Older does not mean less important\. No source$/,
  /^ {2}content was deleted; only a prior banner THIS TOOL generated was replaced\.$/,
  new RegExp(`^${escapeRe(BANNER_END)}$`),
  /^$/,
  /^$/,
];

/** Does `text` parse as a banner the tool rendered? Computed WITHOUT the tool. */
function externallyIsRenderedBanner(text) {
  const lines = text.split("\n");
  if (lines.length !== EXT_BANNER_LINE_RE.length) return false;
  return lines.every((l, i) => EXT_BANNER_LINE_RE[i].test(l));
}

/**
 * Split a preamble into `{ head, banner }` using only the rules above.
 * `banner` is "" unless the preamble ends with bytes that PARSE as a rendered
 * banner — a marker-paired region of hand-authored prose is head, not banner.
 */
function externalSplitPreamble(preambleText) {
  if (!preambleText.endsWith(BANNER_TAIL)) return { head: preambleText, banner: "" };
  // walk candidate starts from the innermost outwards. `s > 0` in the step, not
  // `s >= 0`: lastIndexOf(needle, -1) clamps to 0 and would loop forever on a
  // preamble whose first byte opens a marker.
  for (let s = preambleText.lastIndexOf(BANNER_START); s >= 0; s = s > 0 ? preambleText.lastIndexOf(BANNER_START, s - 1) : -1) {
    if (s !== 0 && preambleText[s - 1] !== "\n") continue;
    const region = preambleText.slice(s);
    if (externallyIsRenderedBanner(region)) return { head: preambleText.slice(0, s), banner: region };
  }
  return { head: preambleText, banner: "" };
}

/* ------------------------------------------------------------------ */
/* EXTERNAL byte conservation                                          */
/* ------------------------------------------------------------------ */

/**
 * Reconstruct the source file from the bytes the tool ACTUALLY WROTE and
 * md5-compare against the source.
 *
 * THIS IS THE POINT: the failure mode that shipped — a span excised from the
 * middle of a retained block — balances the tool's own arithmetic exactly
 * (`retainedContentBytes + archivedBytes == originalBytes` still held while 117
 * bytes existed in neither output), because the numbers were derived from the
 * already-shortened string. Nothing here reads the tool's report.
 *
 * `enc` selects the byte domain: fixtures are compared as utf8 strings, real
 * memory content as latin1 (one char == one byte), so byte counts and string
 * lengths cannot drift apart. `originalText` must already be decoded the same
 * way.
 *
 * Returns `{ rotated }` so callers can assert on which path was taken.
 */
function assertExternalReconstruction(root, name, originalText, keep, enc = "utf8") {
  const segs = segmentFile(originalText, FILE_SPECS[name]);
  assertSegmentPartition(originalText, segs);
  const blocks = segs.filter((s) => s.kind === "block");
  const keptLabels = new Set(blocks.slice(0, keep).map((s) => s.label));
  const expRetained = segs
    .filter((s) => s.kind !== "block" || keptLabels.has(s.label))
    .map((s) => s.text)
    .join("");
  const expArchived = segs
    .filter((s) => s.kind === "block" && !keptLabels.has(s.label))
    .map((s) => s.text)
    .join("");
  assert.equal(
    expRetained + expArchived,
    originalText,
    `${name}: the source must split into retained ++ archived with no remainder`
  );

  const live = fs.readFileSync(path.join(root, RETAINED[name])).toString(enc);

  if (expArchived.length === 0) {
    // the genuine no-op path: nothing rotates, so nothing may change
    assert.equal(live, originalText, `${name}: a no-op must leave the file byte-identical`);
    assert.equal(bannerOf(live), bannerOf(originalText), `${name}: a no-op must not add a banner`);
    return { rotated: false };
  }

  // the tool's banner slot: the tail of the preamble, with any PRIOR banner
  // (present when the source has already been rotated once) replaced in place.
  // Located with the EXTERNAL recogniser above — never with the tool's own
  // strip, which would make this function agree with the code it is auditing.
  const preText = segs.find((s) => s.kind === "preamble")?.text ?? "";
  const prior = externalSplitPreamble(preText);
  const priorBannerText = prior.banner;
  const headLen = prior.head.length;
  const pad = headLen > 0 && !prior.head.endsWith("\n") ? 1 : 0;

  assert.equal(live.slice(0, headLen), prior.head, `${name}: preamble head is not byte-exact`);
  assert.ok(
    live.startsWith(BANNER_START, headLen + pad),
    `${name}: the banner is not at the anchored offset ${headLen + pad}`
  );
  const tailAt = live.indexOf(BANNER_TAIL, headLen + pad);
  assert.ok(tailAt >= headLen + pad, `${name}: the banner has no closing marker`);
  const liveContent = live.slice(0, headLen) + live.slice(tailAt + BANNER_TAIL.length);

  // (1) the live file, banner removed, is byte-exact the retained content of
  //     the source — minus only the prior banner the tool is allowed to replace
  const expLiveContent = prior.head + expRetained.slice(preText.length);
  assert.equal(
    liveContent.length,
    expLiveContent.length,
    `${name}: live content is ${liveContent.length} B, expected ${expLiveContent.length} B ` +
      `(${expLiveContent.length - liveContent.length} B destroyed)`
  );
  assert.equal(liveContent, expLiveContent, `${name}: live content is not byte-exact`);

  // (2) the archive holds the rotated-away bytes, byte-exact and contiguous
  const archive = fs.readFileSync(path.join(root, ARCHIVE[name])).toString(enc);
  const hdr = archive.lastIndexOf("## ARCHIVED BATCH ");
  assert.ok(hdr >= 0, `${name}: the archive carries no batch header`);
  const bodyAt = archive.indexOf("\n\n", hdr) + 2;
  const archivedOnDisk = archive.slice(bodyAt, bodyAt + expArchived.length);
  assert.equal(archivedOnDisk, expArchived, `${name}: archived bytes are not byte-exact`);

  // (3) FULL RECONSTRUCTION: put the prior banner back where it was, append the
  //     archived region, and the md5 must be the source's md5
  const reconstructed =
    liveContent.slice(0, headLen) + priorBannerText + liveContent.slice(headLen) + archivedOnDisk;
  assert.equal(
    md5(reconstructed),
    md5(originalText),
    `${name}: md5 of the reconstruction != md5 of the source`
  );
  return { rotated: true };
}

/* ================================================================== */
/* 1. CENTRAL: rotation is by RECENCY ONLY — and says so               */
/* ================================================================== */

describe("CENTRAL: rotation is by RECENCY ONLY and guarantees nothing about meaning", () => {
  test("the pending-deploy-go section of active_packet rotates like any other block", () => {
    const root = makeRoot("recency-only");
    const original = read(root, RETAINED.active_packet);
    assert.ok(original.includes("## Gated steps (each needs explicit operator go)"));

    const res = runJson(["--root", root, "--file", "active_packet", "--keep", "10", "--apply"]);
    assert.equal(res.status, 0, res.all);

    const retained = read(root, RETAINED.active_packet);
    const archive = read(root, ARCHIVE.active_packet);

    // The pending-deploy-go register sits in the archive region, so it rotates.
    // This is the tool's ACTUAL behaviour, asserted rather than hoped for:
    // content that must never rotate belongs in a file absent from FILE_SPECS.
    assert.ok(
      !retained.includes("- deploy PR #202 — PENDING OPERATOR GO"),
      "recency-only rotation does NOT exempt structural sections"
    );
    assert.ok(
      archive.includes("- deploy PR #202 — PENDING OPERATOR GO"),
      "...it is moved, never deleted"
    );

    // Nothing anywhere claims a retention/meaning guarantee.
    assert.ok(!/retention/i.test(res.all), `output must not claim retention: ${res.all}`);
    assert.ok(!/\bpinned\b/i.test(res.all), `output must not mention pinning: ${res.all}`);
  });

  test("no pinnedPrefixes/assertRetention/naive-flag token, and a spec carries only name+path+delimiter", () => {
    const src = fs.readFileSync(path.join(HERE, "rotate-memory.mjs"), "utf8");
    const sh = fs.readFileSync(SCRIPT, "utf8");
    for (const [label, text] of [["mjs", src], ["sh", sh]]) {
      assert.ok(!/pinnedPrefixes/.test(text), `${label} still references pinnedPrefixes`);
      assert.ok(!/assertRetention/.test(text), `${label} still references assertRetention`);
      assert.ok(!/naive-tail-rotation/.test(text), `${label} still references the naive flag`);
    }
    /*
     * `assert.equal(spec.pinnedPrefixes, undefined)` would pass for ANY renamed
     * pinning key, so it proves nothing. Pin the whole key set instead: a spec
     * may carry a name, a path and a delimiter, and nothing else.
     */
    const ALLOWED_SPEC_KEYS = ["blockDelimiter", "name", "path"];
    for (const name of ["current_state", "residue", "active_packet"]) {
      assert.deepEqual(
        Object.keys(FILE_SPECS[name]).sort(),
        ALLOWED_SPEC_KEYS,
        `${name} spec carries an unexpected key — a pinning mechanism may be back under a new name`
      );
    }
  });

  test("standing_gates.md is named as a designated PATH, is absent from FILE_SPECS, and one --apply does not create it", () => {
    const src = fs.readFileSync(path.join(HERE, "rotate-memory.mjs"), "utf8");
    const sh = fs.readFileSync(SCRIPT, "utf8");

    // it IS named — routing content out of the blast radius is the whole advice
    assert.match(src, /build-os\/memory\/standing_gates\.md/);
    assert.match(sh, /build-os\/memory\/standing_gates\.md/);

    // ...but nothing asserts it currently exists, and the docs say so plainly
    assert.match(src, /never reads, writes or creates/);
    assert.match(sh, /never reads, writes or creates/);
    for (const [name, spec] of Object.entries(FILE_SPECS)) {
      assert.ok(
        !spec.path.includes("standing_gates"),
        `${name}: standing_gates.md must never enter FILE_SPECS`
      );
    }

    // the CLI help names it without claiming it is there to be read
    const help = run(["--help"]);
    assert.equal(help.status, 0, help.all);
    assert.match(
      help.stdout,
      /build-os\/memory\/standing_gates\.md, which this tool never reads, writes or\ncreates/
    );

    // and no run — not even an --apply — brings it into existence
    const root = makeRoot("standing-gates");
    assert.equal(run(["--root", root, "--keep", "10", "--apply"]).status, 0);
    assert.ok(!fs.existsSync(path.join(root, "build-os/memory/standing_gates.md")));
  });

  test("--naive-tail-rotation is gone from the argument surface", () => {
    const root = makeRoot("no-naive-flag");
    const before = hashTree(root);
    const res = run(["--root", root, "--naive-tail-rotation"]);
    assert.equal(res.status, EXIT.USAGE, res.all);
    assert.match(res.all, /unknown argument/);
    assert.deepEqual(hashTree(root), before);
  });

  test("the newest N blocks are the ones kept, in original order", () => {
    const root = makeRoot("recency-order");
    assert.equal(
      run(["--root", root, "--file", "current_state", "--keep", "3", "--apply"]).status,
      0
    );
    const retained = read(root, RETAINED.current_state);

    const blocks = retained.match(/^## \*\*(LATEST|PRIOR)/gm) ?? [];
    assert.equal(blocks.length, 3);
    assert.ok(retained.includes("block 3**"));
    assert.ok(!retained.includes("block 4**"));

    // original relative order is preserved — two EXPLICIT pairwise comparisons.
    // (`a < b < c` would parse as `(a < b) < c` and compare a boolean to a
    // number, which proves nothing.)
    const i1 = retained.indexOf("block 1**");
    const i2 = retained.indexOf("block 2**");
    const i3 = retained.indexOf("block 3**");
    assert.ok(i1 >= 0 && i2 >= 0 && i3 >= 0);
    assert.ok(i1 < i2, "block 1 precedes block 2 in the retained file");
    assert.ok(i2 < i3, "block 2 precedes block 3 in the retained file");
  });
});

/* ================================================================== */
/* 2. Segment-partition conservation                                   */
/* ================================================================== */

describe("segment-partition conservation", () => {
  for (const name of ["current_state", "residue", "active_packet"]) {
    test(`${name}: segments join byte-exact and lengths sum to the original`, () => {
      const root = makeRoot(`part-${name}`);
      const original = read(root, RETAINED[name]);
      const segments = segmentFile(original, FILE_SPECS[name]);

      const sum = segments.reduce((a, s) => a + Buffer.byteLength(s.text), 0);
      assert.equal(sum, Buffer.byteLength(original), "sum(len(seg)) == len(original)");
      assert.equal(segments.map((s) => s.text).join(""), original, "join in order == original");
      assertSegmentPartition(original, segments);
    });
  }

  test("every segment of current_state at keep=5 is routed to exactly one output", () => {
    const root = makeRoot("route-once");
    const original = read(root, RETAINED.current_state);
    const segments = segmentFile(original, FILE_SPECS.current_state);
    const { retained, archived } = routeSegments(segments, 5);

    const labels = [...retained, ...archived].map((s) => s.label);
    assert.equal(labels.length, segments.length);
    assert.equal(new Set(labels).size, segments.length, "no label appears twice");
    assert.deepEqual(
      [...labels].sort(),
      segments.map((s) => s.label).sort(),
      "union of outputs == full segment list"
    );
  });

  /*
   * The two live branches of assertSegmentPartition are pinned SEPARATELY, each
   * by a fixture only that branch can catch and by its own message. A single
   * "throws /CONSERVATION/" fixture cannot distinguish them: disabling the
   * length branch still trips the byte branch, so it dies silently.
   *
   * (The third branch — the latin1 byte-length re-check — is unreachable, and
   * unreachable given branch (a) ALONE: `Buffer.byteLength(s, "latin1")` is
   * `s.length` for EVERY JS string, and branch (a) has already proved the
   * summed segment lengths equal `original.length`. Branch (b) is not needed to
   * kill it. Deliberately left uncovered rather than given a test that could not
   * fail; kept rather than deleted, because removing a guard is a reviewer's
   * call.)
   */
  test("conservation branch (a): a LENGTH mismatch is caught, and reported as one", () => {
    const original = "a\nb\nc\n";
    const segments = [{ label: "preamble", kind: "preamble", text: "a\nb\n" }];
    assert.throws(
      () => assertSegmentPartition(original, segments),
      (e) => {
        assert.equal(e.code, EXIT.CONSERVATION);
        assert.match(e.message, /sum\(len\(seg\)\) = 4 != len\(original\) = 6/);
        return true;
      }
    );
  });

  test("conservation branch (b): EQUAL lengths but different bytes is caught, with the offset", () => {
    const original = "a\nb\nc\n";
    const segments = [{ label: "preamble", kind: "preamble", text: "a\nb\nX\n" }];
    // the length branch cannot see this one: 6 === 6
    assert.equal(segments[0].text.length, original.length);
    assert.throws(
      () => assertSegmentPartition(original, segments),
      (e) => {
        assert.equal(e.code, EXIT.CONSERVATION);
        assert.match(e.message, /not byte-exact \(first divergence at byte 4\)/);
        return true;
      }
    );
  });

  test("the head preamble is preserved byte-exact at the head of the retained file", () => {
    const root = makeRoot("preamble");
    const original = read(root, RETAINED.current_state);
    // the run's exit status is asserted: without it this test passes when the
    // tool does NOTHING AT ALL, since an unrotated file also starts with its
    // own preamble
    const res = runJson(["--root", root, "--file", "current_state", "--keep", "3", "--apply"]);
    assert.equal(res.status, 0, res.all);
    assert.equal(res.json.results[0].noop, false, "the run must actually have rotated");
    const retained = read(root, RETAINED.current_state);
    assert.ok(original.startsWith(CS_PREAMBLE));
    // the WHOLE preamble segment, not merely the CS_PREAMBLE constant that
    // opens it: the segment also carries the `## Project` prose section, and a
    // prefix assertion would say nothing about those bytes
    const preamble = segmentFile(original, FILE_SPECS.current_state).find(
      (s) => s.kind === "preamble"
    );
    assert.ok(preamble.text.length > CS_PREAMBLE.length, "fixture preamble must exceed the constant");
    assert.ok(retained.startsWith(preamble.text), "the whole preamble segment is unchanged at the head");
    assert.ok(retained.length < original.length, "the file must actually have been rewritten");
  });
});

/* ================================================================== */
/* 3. The BROAD residue delimiter                                      */
/* ================================================================== */

describe("residue.md uses a BROAD `^## ` delimiter", () => {
  test("keeps all 114 blocks; narrowing to `^## PACKET CLOSE` would find only 57", () => {
    const root = makeRoot("residue-broad");
    const original = read(root, RETAINED.residue);

    const narrow = (original.match(/^## PACKET CLOSE/gm) ?? []).length;
    assert.equal(narrow, 57, "the narrow delimiter sees only half the blocks");

    const res = runJson(["--root", root, "--file", "residue", "--keep", "10"]);
    assert.equal(res.status, 0, res.all);
    const r = res.json.results[0];
    assert.equal(r.totalBlocks, 114, "broad delimiter finds every block");
    assert.equal(r.retainedBlocks, 10);
    assert.equal(r.archivedBlocks, 104);
    assert.equal(r.totalBlocks - narrow, 57, "57 blocks would be misrouted by narrowing");
  });

  test("the shipped delimiters are PER-FILE objects, never one shared regex", () => {
    /*
     * WHAT CHANGED IN THE PORT, AND WHY THIS TEST NOW ASSERTS SOMETHING ELSE.
     *
     * This used to pin three literal sources, one of which
     * (`^> \*\*(LATEST|PRIOR)`) described the reference deployment's
     * `current_state.md`. The scaffold every installed repo receives writes `##`
     * sections in all three files, so all three delimiters are now the same
     * PATTERN — and the old assertion, kept as-is, would have pinned this layer
     * to a format its own installer does not produce.
     *
     * "Never one shared regex" is still the rule, and it is now asserted as the
     * property it actually is: three INDEPENDENT regex objects, one per spec. Two
     * files agreeing on a pattern today is a fact about the scaffold; sharing one
     * object would mean a future change to one file's convention silently
     * re-cutting the other two, which is the failure this rule exists to stop.
     */
    const specs = [FILE_SPECS.current_state, FILE_SPECS.residue, FILE_SPECS.active_packet];
    for (const spec of specs) {
      assert.ok(spec.blockDelimiter instanceof RegExp, `${spec.name}: delimiter is not a RegExp`);
      assert.equal(spec.blockDelimiter.source, "^## ", `${spec.name}: unexpected delimiter`);
    }
    for (let i = 0; i < specs.length; i++) {
      for (let j = i + 1; j < specs.length; j++) {
        assert.notEqual(
          specs[i].blockDelimiter,
          specs[j].blockDelimiter,
          `${specs[i].name} and ${specs[j].name} SHARE one regex object. Give each spec its ` +
            `own: a shared object makes changing one file's block convention change all of them.`
        );
      }
    }
  });
});

/* ================================================================== */
/* 4. Dry-run is the default; --apply is required to write             */
/* ================================================================== */

describe("dry-run default", () => {
  test("no --apply writes NOTHING but reports what would move", () => {
    const root = makeRoot("dryrun");
    const before = hashTree(root);

    const res = run(["--root", root, "--keep", "10"]);
    assert.equal(res.status, 0, res.all);
    assert.deepEqual(hashTree(root), before, "dry-run must not write");
    assert.match(res.stdout, /DRY-RUN/);
    assert.match(res.stdout, /would archive/i);
  });

  test("a dry-run leaves an ALREADY-POPULATED archive directory bit-identical", () => {
    const root = makeRoot("dryrun-after-apply");
    assert.equal(run(["--root", root, "--keep", "20", "--apply"]).status, 0);
    const archiveDir = path.join(root, "build-os/memory/archive");
    assert.ok(fs.existsSync(archiveDir), "fixture apply must have created the archive");

    const before = snapshotDir(archiveDir);
    const res = run(["--root", root, "--keep", "10"]);
    assert.equal(res.status, 0, res.all);
    assert.deepEqual(snapshotDir(archiveDir), before, "a dry-run must not touch the archive");
  });
});

/* ================================================================== */
/* 4b. THE DEFAULT ROOT — the one line this suite may never execute     */
/* ================================================================== */

/*
 * WHY A SOURCE PIN AND NOT A RUN. The default root is what the tool uses when no
 * `--root` is given, and a rootless invocation from this suite rotates the LIVE
 * Build OS memory — that is the shape the scratch-root gate exists to make
 * unreachable. So the one line that decides it can never be exercised from here,
 * and it was consequently pinned by nothing. Measured in the reference
 * deployment at commit `cb2bb7d`, before this pin existed: changing
 * `path.join(here, "..", "..")` to `path.join(here, "..")` left the whole suite
 * GREEN — 0 fail, wrapper exit 0. The pass count of that run was a fact about
 * that repo's suite on that day and is not quoted; what generalises, and what
 * this pin is for, is that the mutation was invisible.
 *
 * It matters because the rest of the safety story quotes this expression. This
 * file's header, `requireScratchRoot`'s own error message and the
 * cross-scanner's rule 1 all say "the tool's default root IS the real repo",
 * and two of them quote the expression verbatim. If that stopped being
 * true — silently, by one deleted argument — every one of those sentences would
 * be wrong, and the tool would rotate whatever `build-os/` happened to be a
 * sibling of instead.
 *
 * The pin is SEMANTIC rather than textual: it reads the steps out of the source
 * and resolves them, so it passes for any spelling that lands on the repo root
 * and fails for any that does not.
 */
describe("the tool's default root", () => {
  test("the `opts.root ??` fallback resolves to the repo root — and one step short does not", () => {
    const src = fs.readFileSync(TOOL_MJS, "utf8");

    const DEFAULT_ROOT = /const root = path\.resolve\(\s*opts\.root \?\? path\.join\(\s*here\s*,([^)]*)\)\s*\)/;
    const m = src.match(DEFAULT_ROOT);
    assert.ok(
      m,
      "rotate-memory.mjs no longer computes its default root as " +
        "`path.resolve(opts.root ?? path.join(here, ...))`. That expression is quoted as " +
        "the reason the scratch-root gate exists, in this file's header, in the gate's own " +
        "error message and in the cross-scanner's rule 1. Re-point this pin, and re-read " +
        "those sentences, before changing it."
    );

    const steps = m[1]
      .split(",")
      .map((s) => s.trim())
      .filter((s) => s.length > 0);
    assert.ok(
      steps.length > 0 && steps.every((s) => /^"[^"]*"$/.test(s)),
      `the default root is built from steps this pin cannot resolve: ${JSON.stringify(m[1])}`
    );
    const parts = steps.map((s) => s.slice(1, -1));

    // `here` is the tool's own directory, and the tool lives in THIS directory
    assert.match(
      src,
      /const here = path\.dirname\(fileURLToPath\(import\.meta\.url\)\);/,
      "`here` is no longer the tool's own directory, so resolving the steps from HERE " +
        "would prove nothing"
    );

    // THE PIN: those steps, from that directory, land on the repo root
    assert.equal(
      realpathDeep(path.resolve(HERE, ...parts)),
      REPO_ROOT,
      `the default root resolves to ${realpathDeep(path.resolve(HERE, ...parts))}, not to ` +
        `the repo root ${REPO_ROOT}`
    );

    // ...and that directory really is the live Build OS tree, so "the default
    // root is the real repo" is grounded rather than asserted
    for (const rel of REAL_MEMORY_FILES) {
      assert.ok(
        fs.existsSync(path.join(REPO_ROOT, rel)),
        `${rel} is not under the resolved default root — the claim is hollow`
      );
    }

    // NON-VACUITY: the pin discriminates. One `..` short is build-os/, and the
    // mutation that deletes an argument therefore cannot pass this test.
    assert.notEqual(
      realpathDeep(path.resolve(HERE, "..")),
      REPO_ROOT,
      "one step short resolves to the repo root too, so this pin proves nothing"
    );
    assert.equal(parts.length, 2, "the fallback no longer takes exactly two steps up");
  });
});

/* ================================================================== */
/* 5. Idempotence + green against already-rotated inputs               */
/* ================================================================== */

describe("idempotence", () => {
  test("a second --apply is a no-op with ZERO diff", () => {
    const root = makeRoot("idem");

    const first = runJson(["--root", root, "--keep", "10", "--apply"]);
    assert.equal(first.status, 0, first.all);
    const afterFirst = hashTree(root);

    const second = runJson(["--root", root, "--keep", "10", "--apply"]);
    assert.equal(second.status, 0, second.all);
    const afterSecond = hashTree(root);

    assert.deepEqual(afterSecond, afterFirst, "second --apply produced a diff");
    for (const r of second.json.results) {
      assert.equal(r.noop, true, `${r.name} should be a no-op on the second apply`);
      assert.equal(r.archivedBlocks, 0);
    }

    // a third one too, for good measure
    assert.equal(runJson(["--root", root, "--keep", "10", "--apply"]).status, 0);
    assert.deepEqual(hashTree(root), afterFirst);
  });

  test("archive is append-only across two DIFFERENT rotations", () => {
    const root = makeRoot("append-only");
    assert.equal(run(["--root", root, "--file", "residue", "--keep", "40", "--apply"]).status, 0);
    const firstArchive = read(root, ARCHIVE.residue);

    assert.equal(run(["--root", root, "--file", "residue", "--keep", "10", "--apply"]).status, 0);
    const secondArchive = read(root, ARCHIVE.residue);

    assert.ok(secondArchive.startsWith(firstArchive), "existing archive bytes must be untouched");
    assert.ok(secondArchive.length > firstArchive.length, "second batch appended");
    assert.equal((secondArchive.match(/^<!-- rotation-batch:/gm) ?? []).length, 2);
  });

  /**
   * THE GAP THIS CLOSES: every other fixture starts from PRISTINE memory. Once
   * the tool is used, the real inputs are rotated files carrying a banner in the
   * preamble. Planning must stay correct — and this suite green — against THAT
   * shape, not only against the pristine one.
   */
  test("planning is correct and green against ALREADY-ROTATED inputs", () => {
    const root = makeRoot("already-rotated");
    assert.equal(runJson(["--root", root, "--keep", "10", "--apply"]).status, 0);
    const afterApply = hashTree(root);

    for (const name of ["current_state", "residue", "active_packet"]) {
      const rotated = read(root, RETAINED[name]);
      assert.ok(bannerOf(rotated), `${name}: rotated file must carry the archive pointer`);

      // conservation still holds on the rotated shape
      const segments = segmentFile(rotated, FILE_SPECS[name]);
      assertSegmentPartition(rotated, segments);
      assert.equal(
        segments.filter((s) => s.kind === "block").length,
        10,
        `${name}: rotated file re-parses to exactly the kept blocks`
      );
      // the banner lives inside the preamble and is not mistaken for a block
      assert.equal(segments[0].kind, "preamble");
      assert.ok(segments[0].text.includes(BANNER_START), `${name}: banner is inside the preamble`);
    }

    // re-planning the rotated tree is a clean no-op, and writes nothing
    const dry = runJson(["--root", root, "--keep", "10"]);
    assert.equal(dry.status, 0, dry.all);
    for (const r of dry.json.results) {
      assert.equal(r.noop, true, `${r.name}: re-planning rotated input must be a no-op`);
      assert.equal(r.archivedBlocks, 0);
      assert.equal(r.retainedBlocks, 10);
      assert.equal(r.conservationOk, true);
    }
    assert.deepEqual(hashTree(root), afterApply, "re-planning must not write");

    // and a further --apply on the rotated tree is still a zero-diff no-op
    assert.equal(runJson(["--root", root, "--keep", "10", "--apply"]).status, 0);
    assert.deepEqual(hashTree(root), afterApply);
  });
});

/* ================================================================== */
/* 6. The archive-pointer banner                                       */
/* ================================================================== */

describe("archive-pointer banner", () => {
  test("apply writes a banner naming the batch, the counts and both archive paths", () => {
    const root = makeRoot("banner");
    const res = runJson(["--root", root, "--file", "residue", "--keep", "10", "--apply"]);
    assert.equal(res.status, 0, res.all);
    const r = res.json.results[0];

    const retained = read(root, RETAINED.residue);
    const banner = bannerOf(retained);
    assert.ok(banner, "rotated file must carry an archive pointer banner");

    assert.ok(banner.includes(r.batchId), "banner names the batch id");
    assert.ok(banner.includes(String(r.archivedBlocks)), "banner names the archived block count");
    assert.ok(banner.includes(String(r.archivedBytes)), "banner names the archived byte count");
    assert.ok(
      banner.includes("build-os/memory/archive/residue.archive.md"),
      "banner names the exact archive path"
    );
    assert.ok(
      banner.includes("build-os/memory/archive/INDEX.md"),
      "banner names the exact index path"
    );

    // it sits immediately after the preamble, so a session reading the top of
    // the file cannot miss it
    assert.ok(retained.startsWith(RES_PREAMBLE), "preamble still leads the file byte-exact");
    assert.equal(
      retained.indexOf(BANNER_START),
      RES_PREAMBLE.length,
      "banner sits immediately after the preamble"
    );
  });

  /**
   * Drives the ACTUAL no-op path (`archived.length === 0`) — residue has 114
   * blocks, so keeping 200 rotates nothing. A previous version of this test ran
   * `--file residue` and then inspected `current_state`, which that invocation
   * never plans at all; it proved "an unprocessed file gets no banner", which
   * is a different claim.
   */
  test("a file with nothing to archive takes the no-op path: NO banner, byte-identical file", () => {
    const root = makeRoot("banner-noop");
    const before = read(root, RETAINED.residue);
    const totalBlocks = segmentFile(before, FILE_SPECS.residue).filter(
      (s) => s.kind === "block"
    ).length;
    assert.ok(totalBlocks < 200, "fixture must have fewer blocks than the keep used below");

    const res = runJson(["--root", root, "--file", "residue", "--keep", "200", "--apply"]);
    assert.equal(res.status, 0, res.all);
    const r = res.json.results[0];

    assert.equal(r.noop, true, "keep > totalBlocks must take the no-op path");
    assert.equal(r.archivedBlocks, 0);
    assert.equal(r.retainedBlocks, totalBlocks);
    assert.equal(r.bannerBytes, 0, "the no-op path renders no banner at all");
    assert.equal(r.bannerPadBytes, 0);
    assert.equal(r.priorBannerBytes, 0);

    assert.equal(bannerOf(read(root, RETAINED.residue)), null, "no banner may be written");
    assert.equal(read(root, RETAINED.residue), before, "the file must be byte-identical");
    assert.ok(
      !fs.existsSync(path.join(root, "build-os/memory/archive")),
      "a no-op must not even create the archive directory"
    );
  });

  test("a file that ALREADY rotated takes the no-op path on the next run and keeps its banner", () => {
    const root = makeRoot("banner-noop-again");
    assert.equal(run(["--root", root, "--file", "residue", "--keep", "10", "--apply"]).status, 0);
    const afterFirst = read(root, RETAINED.residue);
    const bannerOne = bannerOf(afterFirst);
    assert.ok(bannerOne);

    const res = runJson(["--root", root, "--file", "residue", "--keep", "10", "--apply"]);
    assert.equal(res.status, 0, res.all);
    assert.equal(res.json.results[0].noop, true);
    assert.equal(res.json.results[0].bannerBytes, 0, "a no-op renders no new banner");
    assert.equal(read(root, RETAINED.residue), afterFirst, "no-op must be a ZERO-diff");
  });

  test("the banner is REPLACED, not accumulated, across two successive applies", () => {
    const root = makeRoot("banner-bounded");

    const first = runJson(["--root", root, "--file", "residue", "--keep", "40", "--apply"]);
    assert.equal(first.status, 0, first.all);
    const afterFirst = read(root, RETAINED.residue);
    const bannerOne = bannerOf(afterFirst);
    assert.ok(bannerOne);

    const second = runJson(["--root", root, "--file", "residue", "--keep", "10", "--apply"]);
    assert.equal(second.status, 0, second.all);
    const afterSecond = read(root, RETAINED.residue);
    const bannerTwo = bannerOf(afterSecond);
    assert.ok(bannerTwo);

    // exactly one banner region survives — no accumulation
    assert.equal(
      (afterSecond.match(new RegExp(BANNER_START.replace(/[|\\{}()[\]^$+*?.-]/g, "\\$&"), "g")) ?? [])
        .length,
      1,
      "a second apply must REPLACE the banner, not stack another one"
    );
    assert.equal(
      (afterSecond.match(new RegExp(BANNER_END.replace(/[|\\{}()[\]^$+*?.-]/g, "\\$&"), "g")) ?? [])
        .length,
      1
    );

    // and it is still bounded
    for (const [label, b] of [["first", bannerOne], ["second", bannerTwo]]) {
      const lines = b.split("\n").length;
      assert.ok(
        lines <= BANNER_MAX_LINES,
        `${label} banner is ${lines} lines, over the ${BANNER_MAX_LINES}-line bound`
      );
    }
    // the surviving banner reports the SECOND rotation's counts, not the first's
    // (both applies can land inside the same second, so the batch id is not a
    // reliable discriminator here — the counts are)
    assert.ok(bannerTwo.includes(second.json.results[0].batchId));
    assert.ok(
      bannerTwo.includes(`${second.json.results[0].archivedBlocks} older blocks`),
      "banner reports the second rotation's archived count"
    );
    assert.ok(
      !bannerTwo.includes(`${first.json.results[0].archivedBlocks} older blocks`),
      "the stale first-rotation count must not survive"
    );
    assert.notEqual(bannerOne, bannerTwo, "the banner is refreshed, not left stale");
  });

  /*
   * CHARACTERISATION — THE ONE CASE WHERE REPLACEMENT DEGRADES TO REFUSAL.
   *
   * The strip is positional: a banner is only stripped when it is the byte-exact
   * TAIL of the preamble, terminating newline and owned blank line included. A
   * later edit can displace it out of that slot without touching a byte of it —
   * insert a block immediately after the end-marker and the blank line the
   * banner owns is consumed, so `findTrailingBanner` refuses and the next
   * rotation APPENDS its banner instead of replacing one. Two banners.
   *
   * This test exists because that is the conservative branch behaving as
   * designed, and it should not be rediscovered as a bug. It pins the BOUND,
   * which is the part worth having in a test rather than in prose:
   *   - the cost is ONE orphan PER DISPLACING EDIT — rotation alone never adds
   *     another, which is the accumulation that would actually matter;
   *   - the orphan's bytes are never touched again (nothing was destroyed, and
   *     its counts stay STALE — that is the actual harm);
   *   - the SECOND banner lands at the anchored slot and is REPLACED on every
   *     subsequent rotation, so the marker count stays pinned at 2 forever.
   * Measured on this fixture: refusal once (priorBannerBytes 0), then replacement
   * on each of three further rotations, marker count 2 throughout.
   */
  test("a banner displaced out of its anchored slot is REFUSED, and the orphan is bounded at one", () => {
    const root = makeRoot("banner-displaced-orphan");
    const startRe = new RegExp(escapeRe(BANNER_START), "g");
    const countStarts = (t) => (t.match(startRe) ?? []).length;
    /*
     * Every banner BODY in the file, in order: `START` through `END`, stopping
     * short of the blank line. Short of it deliberately — the displacement below
     * consumes that blank line and nothing else, so a comparison that included it
     * would report "the banner changed" when what changed is the byte after it.
     */
    const bodiesIn = (t) => {
      const out = [];
      for (let i = t.indexOf(BANNER_START); i !== -1; i = t.indexOf(BANNER_START, i + 1)) {
        const e = t.indexOf(BANNER_END, i);
        assert.ok(e > i, "a start marker with no paired end marker");
        out.push(t.slice(i, e + BANNER_END.length));
      }
      return out;
    };

    // 1. an ordinary rotation: one banner, in its anchored slot
    const first = runJson(["--root", root, "--file", "residue", "--keep", "40", "--apply"]);
    assert.equal(first.status, 0, first.all);
    const afterFirst = read(root, RETAINED.residue);
    assert.equal(countStarts(afterFirst), 1);
    const bannerAt = afterFirst.indexOf(BANNER_START);
    const originalRendered = afterFirst.slice(
      bannerAt,
      afterFirst.indexOf(BANNER_TAIL, bannerAt) + BANNER_TAIL.length
    );
    assert.ok(externallyIsRenderedBanner(originalRendered), "fixture must start from a real banner");
    const [originalBody] = bodiesIn(afterFirst);

    // 2. a later edit inserts a block immediately after the end-marker,
    //    CONSUMING the blank line the banner owns. Not one byte of the banner
    //    itself changes — only what follows it.
    const tailAt = afterFirst.indexOf(BANNER_TAIL);
    assert.ok(tailAt > 0);
    const INSERTED = "## INSERTED BY A LATER EDIT\n\nsomebody's note.\n\n";
    const displaced =
      afterFirst.slice(0, tailAt + BANNER_TAIL.length - 1) +
      INSERTED +
      afterFirst.slice(tailAt + BANNER_TAIL.length);
    fs.writeFileSync(path.join(root, RETAINED.residue), displaced, "utf8");
    assert.ok(displaced.includes(`${BANNER_END}\n${INSERTED}`), "the blank line must be gone");
    assert.equal(bodiesIn(displaced)[0], originalBody, "the banner's own bytes are untouched");

    // 3. the next rotation REFUSES to strip it and writes a second one
    const second = runJson(["--root", root, "--file", "residue", "--keep", "30", "--apply"]);
    assert.equal(second.status, 0, second.all);
    const afterSecond = read(root, RETAINED.residue);
    assert.equal(
      second.json.results[0].priorBannerBytes,
      0,
      "a displaced banner must be REFUSED, not stripped — refusing is what protects content"
    );
    assert.ok(second.json.results[0].bannerBytes > 0, "and a fresh banner is still written");
    assert.equal(countStarts(afterSecond), 2, "refusal costs exactly one extra banner");
    assert.equal(bodiesIn(afterSecond)[0], originalBody, "the orphan is preserved byte-exact");
    assert.ok(afterSecond.includes(INSERTED), "and the human's inserted block survives");

    // 4. THE BOUND. Every later rotation replaces the SECOND banner normally, so
    //    the orphan is a one-time cost and the count never reaches three.
    let prevLive = bodiesIn(afterSecond)[1];
    for (const keep of ["20", "15", "10"]) {
      const res = runJson(["--root", root, "--file", "residue", "--keep", keep, "--apply"]);
      assert.equal(res.status, 0, res.all);
      const live = read(root, RETAINED.residue);
      assert.ok(
        res.json.results[0].priorBannerBytes > 0,
        `keep=${keep}: the anchored banner must be REPLACED, not accumulated`
      );
      assert.equal(countStarts(live), 2, `keep=${keep}: pinned at two banners — no third`);
      const [orphan, current] = bodiesIn(live);
      assert.equal(orphan, originalBody, `keep=${keep}: the orphan is never rewritten`);
      assert.notEqual(current, prevLive, `keep=${keep}: the anchored banner is refreshed`);
      assert.ok(
        current.includes(`${res.json.results[0].archivedBlocks} older blocks`),
        `keep=${keep}: the anchored banner carries THIS rotation's counts`
      );
      prevLive = current;
    }

    // 5. and name the harm the orphan actually does: it still reads as authoritative
    //    while reporting counts from a rotation several runs ago.
    assert.ok(
      originalBody.includes(`${first.json.results[0].archivedBlocks} older blocks`),
      "the orphan keeps the FIRST rotation's counts — stale, and that is the cost"
    );
    assert.notEqual(
      first.json.results[0].archivedBlocks,
      Number(prevLive.match(/\*\* (\d+) older blocks/)[1]),
      "…demonstrably stale: it disagrees with the live banner beside it"
    );
  });

  /*
   * The previous title claimed "banner bytes are identical in shape across
   * files" and its body never compared two files. The equality is also FALSE:
   * the banner embeds decimal counts, so its byte length varies with their
   * digits (measured: 507 / 501 / 507 B). What is actually true, and what the
   * banner is FOR, is that it is fixed-SHAPE and bounded — it does not grow
   * with how much rotated away. That is what this test asserts, across files
   * and across two rotations of very different size.
   */
  /**
   * The banner is written INTO Build OS memory, so it is the highest-leverage
   * place for an overclaim: whatever it says is what a future session believes.
   * It used to assert "nothing was deleted" flat out, which is false on a
   * re-rotation — this tool consumes the previous run's banner bytes in its own
   * anchored slot. The enumerated phrases below are the unqualified forms; the
   * qualified sentence the banner now carries must be present instead.
   *
   * SCOPE. This test scans the banner. Scanning ONLY the banner is how
   * `INDEX_HEADER` — which is also written into memory, and carried the
   * strongest permanence claim in the tool — went unaudited for a round. The
   * test immediately below audits every string the tool writes, and this one is
   * kept because it also pins the QUALIFIED sentences, which the general audit
   * cannot know about.
   */
  test("the rendered banner carries no unqualified deletes-nothing claim", () => {
    const banner = captureRealBanner();
    for (const claim of UNQUALIFIED_PERMANENCE_CLAIMS) {
      assert.ok(
        !banner.toLowerCase().includes(claim.toLowerCase()),
        `the banner written into memory carries the unqualified claim ${JSON.stringify(claim)}:\n${banner}`
      );
    }
    // ...and it does carry the qualified statement, so the claim was narrowed
    // rather than merely removed
    assert.match(banner, /No source\n\s+content was deleted; only a prior banner THIS TOOL generated was replaced\./);
    assert.match(banner, /rotation is by RECENCY ONLY/);
  });

  /**
   * EVERY STRING THE TOOL WRITES INTO MEMORY, not an enumerated subset of them.
   *
   * The audit above was built to stop an unqualified permanence claim reaching
   * memory, and it scanned `captureRealBanner()` and nothing else. `INDEX_HEADER`
   * — written into `build-os/memory/archive/INDEX.md`, i.e. into memory a future
   * session reads — said `Nothing here is ever deleted.` and was scanned by
   * nothing. Same class of claim, same class of location, no coverage.
   *
   * HOW THIS ONE FINDS THEM ALL WITHOUT AN ENUMERATION. Rotate a fixture, then
   * subtract: every line of every file the tool wrote that did NOT already exist
   * in the input is, by construction, a line the tool authored — content is only
   * ever MOVED, byte-exact, so a content line always has an input twin. What is
   * left over is the tool's own prose: the banner, the archive batch headers, the
   * index header and the index rows. No registry to keep in step, and no way to
   * add a new written string without it appearing here.
   */
  test("EVERY string the tool writes into memory is audited, not just the banner", () => {
    const root = makeRoot("memory-prose-audit");

    const inputLines = new Set();
    for (const rel of Object.values(RETAINED)) {
      for (const line of read(root, rel).split("\n")) inputLines.add(line);
    }

    assert.equal(run(["--root", root, "--keep", "10", "--apply"]).status, 0);

    const authored = [];
    const files = Object.keys(hashTree(root)).sort();
    for (const rel of files) {
      read(root, rel)
        .split("\n")
        .forEach((line, i) => {
          if (line !== "" && !inputLines.has(line)) authored.push({ rel, at: i + 1, line });
        });
    }

    // the audit must actually be looking at the places prose lives
    assert.ok(
      files.includes("build-os/memory/archive/INDEX.md"),
      `the index was not written; files=${JSON.stringify(files)}`
    );
    for (const rel of [...Object.values(RETAINED), ...Object.values(ARCHIVE)]) {
      assert.ok(files.includes(rel), `${rel} was not written`);
    }
    const touched = new Set(authored.map((a) => a.rel));
    assert.ok(touched.size >= 5, `only ${touched.size} files carry tool-authored lines`);
    assert.ok(authored.length >= 40, `only ${authored.length} tool-authored lines were found`);

    const offenders = authored.filter((a) =>
      UNQUALIFIED_PERMANENCE_CLAIMS.some((c) => a.line.toLowerCase().includes(c.toLowerCase()))
    );
    assert.deepEqual(
      offenders,
      [],
      `the tool wrote an unqualified permanence claim into memory:\n` +
        offenders.map((o) => `  ${o.rel}:${o.at}  ${o.line}`).join("\n")
    );

    // ...and the index says the three things that make the qualification true
    const index = read(root, "build-os/memory/archive/INDEX.md");
    assert.match(index, /property of THIS TOOL,\n> not of this directory/);
    assert.match(
      index,
      /version-control backing until it is committed/,
      "the index must say its directory has no VCS backing until something commits it"
    );
    assert.match(index, /THE ROWS BELOW ARE LOSSY/);
  });

  /**
   * ...and the audit above is not vacuous. The same subtraction is run over a
   * tool whose index header carries the claim that was actually shipped, and it
   * must be reported. Without this, "no offenders" is indistinguishable from
   * "the audit looked at nothing" — which is exactly what the banner-only
   * version was.
   */
  test("...and that audit REPORTS the claim that was actually shipped, when it is present", () => {
    const mjs = mutatedTool("index-claim", [
      [
        "  `> repo — still resolves). Written by \\`${TOOL_ID}\\`.\\n` +",
        "  `> repo — still resolves). Written by \\`${TOOL_ID}\\`. Nothing here is ever deleted.\\n` +",
      ],
    ]);
    const root = makeRoot("memory-prose-audit-control");
    const inputLines = new Set();
    for (const rel of Object.values(RETAINED)) {
      for (const line of read(root, rel).split("\n")) inputLines.add(line);
    }

    assert.equal(runNodeJson(mjs, ["--root", root, "--keep", "10", "--apply"]).status, 0);

    const offenders = [];
    for (const rel of Object.keys(hashTree(root))) {
      read(root, rel)
        .split("\n")
        .forEach((line, i) => {
          if (line === "" || inputLines.has(line)) return;
          if (UNQUALIFIED_PERMANENCE_CLAIMS.some((c) => line.toLowerCase().includes(c.toLowerCase()))) {
            offenders.push(`${rel}:${i + 1}`);
          }
        });
    }
    assert.equal(offenders.length, 1, `expected exactly the index header: ${offenders.join(", ")}`);
    assert.match(offenders[0], /build-os\/memory\/archive\/INDEX\.md/);
  });

  test("the banner has one line count across the 3 files, and the same across a 104-block and a 20-block rotation", () => {
    const root = makeRoot("banner-shape");
    const res = runJson(["--root", root, "--keep", "10", "--apply"]);
    assert.equal(res.status, 0, res.all);

    const lineCounts = new Set();
    const byteSizes = [];
    for (const r of res.json.results) {
      const banner = bannerOf(read(root, r.path));
      assert.ok(banner, `${r.name} must carry a banner`);
      const lines = banner.split("\n").length;
      assert.ok(lines <= BANNER_MAX_LINES, `${r.name}: ${lines} lines`);
      lineCounts.add(lines);
      byteSizes.push(r.bannerBytes);
      // bannerOf() spans START..END inclusive; the written banner additionally
      // owns its terminating newline and the blank line separating it from the
      // first live block. This is a MEASUREMENT of the rendered banner, and the
      // report must agree with it.
      assert.equal(r.bannerBytes, banner.length + 2, `${r.name}: reported banner bytes are exact`);
    }

    // identical SHAPE across all three files...
    assert.equal(
      lineCounts.size,
      1,
      `banner line counts differ across files: ${[...lineCounts].join(", ")}`
    );
    // ...and byte sizes that differ only by the digits of the embedded counts
    assert.ok(
      Math.max(...byteSizes) - Math.min(...byteSizes) <= 16,
      `banner byte sizes vary by more than the embedded digits: ${byteSizes.join(", ")}`
    );

    // and it does NOT scale with the amount rotated: 104 blocks vs 20
    const big = makeRoot("banner-shape-big");
    const small = makeRoot("banner-shape-small");
    const a = runJson(["--root", big, "--file", "residue", "--keep", "10", "--apply"]);
    const b = runJson(["--root", small, "--file", "residue", "--keep", "94", "--apply"]);
    assert.equal(a.status, 0, a.all);
    assert.equal(b.status, 0, b.all);
    assert.equal(a.json.results[0].archivedBlocks, 104);
    assert.equal(b.json.results[0].archivedBlocks, 20);
    assert.equal(
      bannerOf(read(big, RETAINED.residue)).split("\n").length,
      bannerOf(read(small, RETAINED.residue)).split("\n").length,
      "a 5x larger rotation must not change the banner's shape"
    );
    assert.ok(
      Math.abs(a.json.results[0].bannerBytes - b.json.results[0].bannerBytes) <= 16,
      "banner size must not scale with the number of rotated blocks"
    );
  });
});

/* ================================================================== */
/* 6b. COMPOSITION CANNOT EAT CONTENT                                  */
/* ================================================================== */

/*
 * THE DEFECT THIS SECTION EXISTS FOR.
 *
 * The banner strip used to be an unanchored `indexOf(BANNER_START)` run over
 * EVERY retained segment. Any retained block that happened to contain the
 * marker pair had that span excised — it reached neither the live file nor the
 * archive. The run exited 0, `conservationOk` was true, and
 * `retainedContentBytes + archivedBytes == originalBytes` still balanced,
 * because those numbers were derived from the already-shortened string; the
 * reported banner size absorbed the loss exactly.
 *
 * Three things fix it, and all three are tested here:
 *
 *   1. the strip is POSITIONAL — only a region at the exact tail of the
 *      preamble, paired, line-anchored and bounded, is a candidate;
 *   2. the candidate must PARSE as a banner `renderBanner` emits, so a human's
 *      marker-wrapped note is refused rather than eaten (section 6c);
 *   3. a POST-COMPOSITION BYTE CHECK compares the string about to be written
 *      against an expectation derived without `composeRetained` — and audits
 *      the dropped region with a recogniser derived without the strip either
 *      (section 6d).
 *
 * Point 3 is split deliberately. Checks (i)-(iii) are independent of
 * `composeRetained` but NOT of `stripTrailingBanner`: they derive their
 * expectation through the same strip composition uses, so an over-reaching strip
 * is agreed with by both sides. Only check (iv), which asks WHICH BYTES were
 * dropped, is independent of the strip. Section 6d proves that separation by
 * mutation rather than asserting it.
 */

describe("the banner strip is POSITIONAL, never a search — and the region must PARSE", () => {
  const B = BANNER_START;
  const E = BANNER_END;
  /* A banner the tool REALLY RENDERED. Not an approximation: since the strip
   * only accepts bytes that parse as a rendered banner, a hand-written stand-in
   * would exercise the refusal path and prove the opposite of what it looks
   * like it proves. */
  const REAL = captureRealBanner();
  /* Hand-authored prose in a paired, line-anchored, <= 12-line region. Passes
   * every POSITIONAL rule and is still not a banner. */
  const HAND =
    `${B}\nHAND-AUTHORED. A human wrapped this note in the documented markers.\n` +
    `It is content and it must survive.\n${E}\n\n`;

  test("a REAL rendered banner at the exact tail of the preamble IS found and stripped", () => {
    const text = `# Head\n\nprose\n\n${REAL}`;
    const at = findTrailingBanner(text);
    assert.ok(at, "the writer's own banner must be recognised");
    assert.equal(at.start, `# Head\n\nprose\n\n`.length);
    assert.equal(at.end, text.length);
    assert.deepEqual(stripTrailingBanner(text), {
      text: `# Head\n\nprose\n\n`,
      bannerBytes: REAL.length,
    });
  });

  for (const [label, text] of [
    // --- POSITIONAL refusals: real banner bytes, wrong place ---
    ["a real banner that is not at the tail", `# Head\n\n${REAL}trailing prose\n`],
    [
      "a real banner with content appended to its closing line",
      `# Head\n\n${REAL.slice(0, REAL.length - BANNER_TAIL.length)}${E} trailing\n\n`,
    ],
    ["an unpaired START", `# Head\n\n${B}\nno close\n\n`],
    ["an unpaired END", `# Head\n\n${E}\n\n`],
    ["a START that is not at a line boundary", `# Head\n\nprefix ${REAL}`],
    ["a START not followed by a newline", `# Head\n\n${B} x\n${E}\n\n`],
    ["a stray second END inside the region", `# Head\n\n${B}\n${E}\nx\n${E}\n\n`],
    ["a real banner missing the blank line it owns", `# Head\n\n${REAL.slice(0, -1)}`],
    [
      "a pair longer than the fixed-size bound",
      `# Head\n\n${B}\n${"filler line\n".repeat(BANNER_MAX_LINES + 2)}${E}\n\n`,
    ],
    ["no markers at all", `# Head\n\nprose\n\n`],
    // --- STRUCTURAL refusals: right place, not a banner this tool wrote ---
    ["HAND-AUTHORED prose in a paired, anchored, bounded region", `# Head\n\nprose\n\n${HAND}`],
    ["the WHOLE preamble is one hand-authored paired region", HAND],
    [
      "a real banner with one field label altered",
      `# Head\n\n${REAL.replace("- batch:", "- batchx:")}`,
    ],
    [
      "a real banner with its recency sentence reworded",
      `# Head\n\n${REAL.replace("Older does not mean less important", "Older means less important")}`,
    ],
    [
      "a real banner with one extra line spliced in",
      `# Head\n\n${REAL.replace(`${E}\n\n`, `- extra: injected\n${E}\n\n`)}`,
    ],
    [
      "a real banner with its blank separator line removed",
      `# Head\n\n${REAL.replace("remain here.\n\n", "remain here.\n")}`,
    ],
  ]) {
    test(`NOT a banner: ${label} — the bytes are content and survive untouched`, () => {
      assert.equal(findTrailingBanner(text), null, `${label} must not be treated as a banner`);
      assert.deepEqual(stripTrailingBanner(text), { text, bannerBytes: 0 });
    });
  }

  test("ties break towards destroying LESS: a duplicated START pairs innermost", () => {
    // two opening markers could pair with the single closing one. The innermost
    // pairing is the smallest possible banner, so the outer marker line is
    // treated as content and survives.
    const text = `# Head\n\n${B}\nOUTER CONTENT\n${REAL}`;
    const at = findTrailingBanner(text);
    assert.ok(at);
    const kept = stripTrailingBanner(text);
    assert.equal(kept.text, `# Head\n\n${B}\nOUTER CONTENT\n`);
    assert.ok(kept.text.includes("OUTER CONTENT"), "the outer region must not be eaten");
    assert.equal(kept.bannerBytes, REAL.length);
  });

  test("the external banner recogniser agrees with the tool on a REAL banner", () => {
    // pins the DUPLICATED shape rules used by assertExternalReconstruction
    // against bytes the tool actually emitted, so the duplication cannot rot
    assert.ok(externallyIsRenderedBanner(REAL), "the external recogniser rejects a real banner");
    assert.ok(!externallyIsRenderedBanner(HAND), "the external recogniser accepts hand-authored prose");
    const at = findTrailingBanner(`# Head\n\n${REAL}`);
    const split = externalSplitPreamble(`# Head\n\n${REAL}`);
    assert.equal(split.banner, REAL, "external split must isolate exactly the banner");
    assert.equal(split.head.length, at.start, "external split must agree with the tool's offset");
  });
});

/* ================================================================== */
/* 6c. HAND-AUTHORED PREAMBLE TAILS ARE NOT BANNERS                    */
/* ================================================================== */

/*
 * THE DEFECT THIS SECTION EXISTS FOR.
 *
 * Recognising a banner by "paired markers, line-anchored, <= 12 lines" is not
 * enough. Hand-authored content matching that description at the tail of a
 * preamble was CONSUMED: it reached neither the live file nor the archive, the
 * run exited 0, and the human report printed `conservation : OK (... byte-exact)`
 * while ~200-300 B per file were gone. The loss was confined to the writer's own
 * banner slot, which is narrow — and still a deletion.
 *
 * The fix is that a region is only a banner if it PARSES as one this tool
 * renders. Each shape below is measured end to end: source bytes in, live bytes
 * plus archived bytes out, and the difference must be ZERO.
 */
describe("4 hand-authored shapes at the preamble tail are not eaten as a banner", () => {
  const B = BANNER_START;
  const E = BANNER_END;

  /** 197 B of hand-authored prose in a paired, anchored, bounded region. */
  const HAND_TAIL =
    `${B}\n` +
    `HAND-AUTHORED, NOT A BANNER. A human wrote this note into the preamble and\n` +
    `wrapped it in the archive-pointer markers because the markers are documented\n` +
    `right above. It is real content and it must survive.\n` +
    `${E}\n\n`;

  const body = (tag) => {
    let s = "";
    for (let i = 1; i <= 30; i++) s += `## PACKET CLOSE ${tag}-${i}\n\n- residue line ${i}\n\n`;
    return s;
  };

  const SHAPES = {
    // qa's A5a: paired hand-authored region at the tail of an ordinary preamble
    A5a: `# Residue\n\n> preamble prose.\n\n${HAND_TAIL}${body("a5a")}`,
    // A8: same, behind a UTF-8 BOM at the very head of the file
    A8: `﻿# Residue\n\n> preamble prose, BOM at the head.\n\n${HAND_TAIL}${body("a8")}`,
    // A9: same, with high-latin1 bytes in the preamble
    A9: `# Résidué\n\n> préambule with high bytes: ÿþéà.\n\n${HAND_TAIL}${body("a9")}`,
    // A10: the WHOLE preamble is the paired region
    A10:
      `${B}\nTHE ENTIRE PREAMBLE IS THE PAIRED REGION. Every byte of it is\n` +
      `hand-authored content and none of it is a rendered banner.\n${E}\n\n${body("a10")}`,
  };

  for (const [label, fixture] of Object.entries(SHAPES)) {
    test(`${label}: rotation destroys ZERO bytes and the hand-authored region survives`, () => {
      const root = makeRoot(`hand-${label}`, { residue: fixture });
      // the fixture must reach disk byte-exact, in the byte domain the tool uses
      const original = fs.readFileSync(path.join(root, RETAINED.residue)).toString("latin1");

      const res = runJson(["--root", root, "--file", "residue", "--keep", "10", "--apply"]);
      assert.equal(res.status, 0, res.all);
      const r = res.json.results[0];

      // NOTHING was treated as a prior banner: this is hand-authored content
      assert.equal(r.priorBannerBytes, 0, `${label}: hand-authored bytes were taken for a banner`);

      // ---- byte accounting, computed from disk, not from the report ----
      const live = fs.readFileSync(path.join(root, RETAINED.residue)).toString("latin1");
      const archive = fs.readFileSync(path.join(root, ARCHIVE.residue)).toString("latin1");
      const segs = segmentFile(original, FILE_SPECS.residue);
      const blocks = segs.filter((s) => s.kind === "block");
      const kept = new Set(blocks.slice(0, 10).map((s) => s.label));
      const expArchived = segs
        .filter((s) => s.kind === "block" && !kept.has(s.label))
        .map((s) => s.text)
        .join("");

      // excise the banner the tool wrote, located externally
      const preText = segs.find((s) => s.kind === "preamble").text;
      const at = live.indexOf(BANNER_START, preText.length);
      assert.ok(at >= 0, `${label}: the tool wrote no banner`);
      const end = live.indexOf(BANNER_TAIL, at) + BANNER_TAIL.length;
      assert.ok(
        externallyIsRenderedBanner(live.slice(at, end)),
        `${label}: the region the tool added does not parse as a rendered banner`
      );
      const liveContent = live.slice(0, at) + live.slice(end);
      assert.ok(archive.includes(expArchived), `${label}: archived bytes are not byte-exact`);

      const survived = liveContent.length + expArchived.length;
      assert.equal(
        original.length - survived,
        0,
        `${label}: ${original.length - survived} B reached NEITHER output ` +
          `(source ${original.length} B, live ${liveContent.length} B, archived ${expArchived.length} B)`
      );

      // and the region itself is there, verbatim
      assert.ok(
        live.includes(preText),
        `${label}: the preamble, including the hand-authored region, is not byte-exact`
      );

      // full reconstruction, md5-confirmed
      assertExternalReconstruction(root, "residue", original, 10, "latin1");
    });
  }

  test("the human report drops the unqualified byte-exact claim on the rotation that replaces a prior banner", () => {
    const root = makeRoot("human-prior-banner");

    // FIRST rotation: nothing is replaced, so the byte-exact claim is legitimate
    const first = run(["--root", root, "--file", "residue", "--keep", "40", "--apply"]);
    assert.equal(first.status, 0, first.all);
    assert.match(first.stdout, /conservation\s+: OK \(.*byte-exact\)/);
    assert.ok(!/prior banner/.test(first.stdout), "nothing was replaced on the first rotation");

    // SECOND rotation over the now-rotated file: a real prior banner IS dropped
    const json = runJson(["--root", root, "--file", "residue", "--keep", "10"]);
    assert.equal(json.status, 0, json.all);
    assert.ok(json.json.results[0].priorBannerBytes > 0, "the second rotation must replace one");
    const replaced = run(["--root", root, "--file", "residue", "--keep", "10"]);
    assert.equal(replaced.status, 0, replaced.all);

    // priorBannerBytes is SURFACED in the human output, not --json-only
    assert.match(replaced.stdout, /prior banner\s+: \d+ B REPLACED in place/);
    // ...and the unqualified byte-exact claim is gone
    assert.ok(
      !/conservation\s+: OK \(.*byte-exact\)/.test(replaced.stdout),
      `an unqualified byte-exact claim survived a banner replacement:\n${replaced.stdout}`
    );
    assert.match(replaced.stdout, /conservation\s+: OK APART FROM those \d+ B/);
    assert.match(replaced.stdout, /NOT byte-exact overall/);
  });
});

describe("marker-laced CONTENT survives rotation byte-exact", () => {
  /**
   * Every trap the unanchored strip used to eat, in both the retained and the
   * archived region, proven by EXTERNAL reconstruction + md5 — never by the
   * tool's self-report.
   */
  test("markers in blocks, in fences, unpaired, and byte-identical to a real banner", () => {
    const realBanner = captureRealBanner();
    const attack = makeMarkerAttackResidue(realBanner);
    const root = makeRoot("marker-attack", { residue: attack });
    const original = read(root, RETAINED.residue);
    assert.equal(original, attack, "fixture must land on disk byte-exact");

    // sanity: the traps really are in the fixture, on both sides of the cut
    assert.ok(countOf(original, BANNER_START) >= 10, "fixture must be densely marker-laced");
    assert.ok(original.includes("EXACTLY THESE BYTES MUST SURVIVE ROTATION VERBATIM (KEEP)."));
    assert.ok(original.includes("EXACTLY THESE BYTES MUST SURVIVE ROTATION VERBATIM (ARCHIVE)."));

    const res = runJson(["--root", root, "--file", "residue", "--keep", "10", "--apply"]);
    assert.equal(res.status, 0, res.all);

    const out = assertExternalReconstruction(root, "residue", original, 10);
    assert.equal(out.rotated, true, "the fixture must actually rotate");

    // and spelled out for the specific spans the old defect destroyed
    const live = read(root, RETAINED.residue);
    const archive = read(root, ARCHIVE.residue);
    assert.ok(
      live.includes("EXACTLY THESE BYTES MUST SURVIVE ROTATION VERBATIM (KEEP)."),
      "a marker pair inside a RETAINED block must not be excised"
    );
    assert.ok(
      live.includes("fenced body KEEP: the fence must stand AND the body must stay"),
      "markers inside a fenced code block must not gut the fence body"
    );
    assert.ok(live.includes("no closing marker anywhere (KEEP)"));
    assert.ok(
      archive.includes("EXACTLY THESE BYTES MUST SURVIVE ROTATION VERBATIM (ARCHIVE)."),
      "a marker pair inside an ARCHIVED block must not be excised"
    );
    assert.ok(archive.includes("fenced body ARCHIVE: the fence must stand AND the body must stay"));

    // the MID-PREAMBLE pair is content too: it is not at the preamble tail
    assert.ok(
      live.includes("MID-PREAMBLE PAIR: not at the preamble tail, therefore content"),
      "a marker pair inside the preamble but not at its tail must survive"
    );

    // exactly ONE of the marker regions is the tool's: the one it just wrote
    assert.equal(
      live.indexOf(BANNER_START),
      original.indexOf(BANNER_START),
      "the mid-preamble pair still leads; the real banner comes after the preamble"
    );
  });

  test("re-rotating the marker-laced file replaces ONLY the tool's own banner", () => {
    const realBanner = captureRealBanner();
    const root = makeRoot("marker-attack-again", { residue: makeMarkerAttackResidue(realBanner) });
    assert.equal(run(["--root", root, "--file", "residue", "--keep", "10", "--apply"]).status, 0);

    const rotated = read(root, RETAINED.residue);
    const res = runJson(["--root", root, "--file", "residue", "--keep", "5", "--apply"]);
    assert.equal(res.status, 0, res.all);
    const r = res.json.results[0];

    // the prior banner is accounted for EXPLICITLY, not inferred by subtraction
    assert.ok(r.priorBannerBytes > 0, "the prior banner must be measured, not guessed");
    assert.equal(r.liveContentBytes, r.retainedContentBytes - r.priorBannerBytes);
    assert.equal(r.retainedBytes, r.liveContentBytes + r.bannerPadBytes + r.bannerBytes);

    // byte-exact against the ALREADY-ROTATED source: the only bytes that may
    // differ are the replaced banner's
    assertExternalReconstruction(root, "residue", rotated, 5);

    // and the retained marker traps are still intact after a SECOND pass
    const live = read(root, RETAINED.residue);
    assert.ok(live.includes("EXACTLY THESE BYTES MUST SURVIVE ROTATION VERBATIM (KEEP)."));
    assert.ok(live.includes("MID-PREAMBLE PAIR: not at the preamble tail, therefore content"));
  });
});

describe("MUTATION: the post-composition byte check kills the unanchored strip (M18)", () => {
  test("the shipped tool rotates the marker-laced fixture cleanly", () => {
    const root = makeRoot("m18-control", { residue: makeMarkerAttackResidue(captureRealBanner()) });
    const original = read(root, RETAINED.residue);
    const res = runJson(["--root", root, "--file", "residue", "--keep", "10", "--apply"]);
    assert.equal(res.status, 0, res.all);
    assertExternalReconstruction(root, "residue", original, 10);
  });

  test("the corrupted tool EXITS EXIT.CONSERVATION and writes nothing", () => {
    const mjs = mutatedTool("m18", M18_UNANCHORED_STRIP);
    const root = makeRoot("m18", { residue: makeMarkerAttackResidue(captureRealBanner()) });
    const before = hashTree(root);

    const res = runNodeJson(mjs, ["--root", root, "--file", "residue", "--keep", "10", "--apply"]);

    assert.equal(
      res.status,
      EXIT.CONSERVATION,
      `the unanchored strip must be caught before any write: ${res.all}`
    );
    assert.match(res.all, /POST-COMPOSITION CONSERVATION FAILED/);
    assert.match(res.all, /B of retained content were DESTROYED by composition/);
    assert.deepEqual(hashTree(root), before, "a failed composition must write NOTHING");
  });

  /*
   * The previous version of this test was titled "the corrupted tool is caught
   * on ORDINARY already-rotated input too" and its body asserted exit 0 on BOTH
   * rotations, with a comment claiming "the guard still stands". Nothing in it
   * observed any guard. The two tests below say what is actually true: on
   * ordinary input the defect is INVISIBLE — which is exactly why it shipped —
   * and the guard fires the moment the input carries a marker pair anywhere the
   * unanchored search can reach.
   */
  test("M18 is INVISIBLE on ordinary input: exit 0 twice, and byte-identical to the shipped tool", () => {
    const mjs = mutatedTool("m18-plain", M18_UNANCHORED_STRIP);
    const corrupted = makeRoot("m18-plain");
    const shipped = makeRoot("m18-plain-control");

    for (const keep of ["40", "10"]) {
      const bad = runNodeJson(mjs, ["--root", corrupted, "--file", "residue", "--keep", keep, "--apply"]);
      const good = runJson(["--root", shipped, "--file", "residue", "--keep", keep, "--apply"]);
      assert.equal(bad.status, 0, `corrupted tool, keep=${keep}: ${bad.all}`);
      assert.equal(good.status, 0, `shipped tool, keep=${keep}: ${good.all}`);
    }

    /*
     * The claim, stated as an assertion rather than as an exit code: on a file
     * with no marker-laced content the corrupted tool produces the SAME BYTES as
     * the shipped one. No guard can fire because nothing is destroyed, and no
     * suite driving only ordinary fixtures could ever tell the two apart. That
     * is the case for the mutation harness, not an argument against it.
     */
    const strip = (t) => t.replace(/- batch: `[^`]*`/g, "- batch: `<id>`");
    assert.equal(
      strip(read(corrupted, RETAINED.residue)),
      strip(read(shipped, RETAINED.residue)),
      "on ordinary input the defect must be indistinguishable — that is the point"
    );
  });

  test("...and the guard FIRES once an already-rotated file carries a marker pair in one block", () => {
    const mjs = mutatedTool("m18-rotated", M18_UNANCHORED_STRIP);
    const root = makeRoot("m18-rotated");

    // an ORDINARY first rotation with the SHIPPED tool: the file now has a real
    // banner in its preamble, which is the shape the real memory files are in
    assert.equal(run(["--root", root, "--file", "residue", "--keep", "40", "--apply"]).status, 0);

    // then an ordinary edit: someone quotes the markers inside one retained
    // block, exactly as this repo's own docs do
    const rotated = read(root, RETAINED.residue);
    const marker = "## PACKET CLOSE (2026-07-27) — `pkt_2`\n\n";
    assert.ok(rotated.includes(marker), "fixture must contain the block being edited");
    const laced = rotated.replace(
      marker,
      `${marker}${BANNER_START}\nEXACTLY THESE BYTES MUST SURVIVE (M18-ROTATED).\n${BANNER_END}\n\n`
    );
    fs.writeFileSync(path.join(root, RETAINED.residue), laced, "utf8");
    const before = hashTree(root);

    const res = runNodeJson(mjs, ["--root", root, "--file", "residue", "--keep", "10", "--apply"]);

    // THE GUARD FIRING IS THE OBSERVATION: exit code, message, and no write
    assert.equal(res.status, EXIT.CONSERVATION, `the guard did not fire: ${res.all}`);
    assert.match(res.all, /POST-COMPOSITION CONSERVATION FAILED/);
    assert.match(res.all, /B of retained content were DESTROYED by composition/);
    assert.deepEqual(hashTree(root), before, "a failed composition must write NOTHING");

    // and the shipped tool handles the same input without losing a byte
    const control = makeRoot("m18-rotated-control", { residue: laced });
    const original = read(control, RETAINED.residue);
    assert.equal(
      runJson(["--root", control, "--file", "residue", "--keep", "10", "--apply"]).status,
      0
    );
    assertExternalReconstruction(control, "residue", original, 10);
    assert.ok(read(control, RETAINED.residue).includes("EXACTLY THESE BYTES MUST SURVIVE (M18-ROTATED)."));
  });
});

/* ================================================================== */
/* 6d. THE POST-COMPOSITION CHECK IS INDEPENDENT OF THE STRIP          */
/* ================================================================== */

describe("MUTATION: an OVER-REACHING strip is caught by post-composition check (iv)", () => {
  /*
   * WHY THIS EXISTS. Checks (i) and (iii) derive their expectation through the
   * SAME `stripTrailingBanner` that composition uses, so a strip that removes
   * too much is agreed with by both sides and every number still balances. The
   * previous check (iv) was a length identity that could not fail for ANY strip.
   *
   * The mutation below makes the strip swallow 10 bytes of preamble beyond the
   * banner. Nothing about the arithmetic notices. Only a check that looks at
   * WHICH BYTES were dropped can.
   */
  const OVERREACH = [["  return { start, end: text.length };", "  return { start: start - 10, end: text.length };"]];

  test("the shipped tool re-rotates an already-rotated file cleanly", () => {
    const root = makeRoot("overreach-control");
    assert.equal(run(["--root", root, "--file", "residue", "--keep", "40", "--apply"]).status, 0);
    const rotated = read(root, RETAINED.residue);
    assert.equal(
      runJson(["--root", root, "--file", "residue", "--keep", "10", "--apply"]).status,
      0
    );
    assertExternalReconstruction(root, "residue", rotated, 10);
  });

  test("the over-reaching strip exits EXIT.CONSERVATION and writes nothing", () => {
    const mjs = mutatedTool("overreach", OVERREACH);
    const root = makeRoot("overreach");
    // a real banner must be present for the strip to over-reach PAST
    assert.equal(run(["--root", root, "--file", "residue", "--keep", "40", "--apply"]).status, 0);
    const before = hashTree(root);

    const res = runNodeJson(mjs, ["--root", root, "--file", "residue", "--keep", "10", "--apply"]);

    assert.equal(res.status, EXIT.CONSERVATION, `an over-reaching strip was not caught: ${res.all}`);
    assert.match(res.all, /POST-COMPOSITION CONSERVATION FAILED/);
    assert.match(res.all, /do NOT parse as an\s+archive-pointer banner/);
    assert.deepEqual(hashTree(root), before, "a failed composition must write NOTHING");
  });

  test("checks (i) and (iii) are BLIND to it — only (iv) sees it", () => {
    /*
     * Proves the previous check (iv) was dead rather than merely redundant: with
     * the content audit removed, the SAME over-reaching strip runs to completion
     * and destroys bytes at exit 0. Every remaining arithmetic check passes.
     */
    const mjs = mutatedTool("overreach-no-iv", [
      ...OVERREACH,
      [
        "      if (!isRenderedBanner(dropped)) {",
        "      if (false && !isRenderedBanner(dropped)) {",
      ],
    ]);
    const root = makeRoot("overreach-no-iv");
    assert.equal(run(["--root", root, "--file", "residue", "--keep", "40", "--apply"]).status, 0);
    const rotated = read(root, RETAINED.residue);

    const res = runNodeJson(mjs, ["--root", root, "--file", "residue", "--keep", "10", "--apply"]);
    assert.equal(res.status, 0, `without (iv) the arithmetic checks must all pass: ${res.all}`);

    // ...and 10 bytes of preamble are gone, at exit 0
    const prior = externalSplitPreamble(
      segmentFile(rotated, FILE_SPECS.residue).find((s) => s.kind === "preamble").text
    );
    const live = read(root, RETAINED.residue);
    assert.ok(
      !live.startsWith(prior.head),
      "without (iv) the over-reaching strip must be observed eating preamble bytes"
    );
    assert.equal(
      res.json.results[0].priorBannerBytes,
      prior.banner.length + 10,
      "the strip reported dropping 10 bytes more than the banner, and nothing objected"
    );
  });
});

/* ================================================================== */
/* 6d-2. POST-COMPOSITION CHECK (iii) — POSITION, NOT ONLY LENGTH      */
/* ================================================================== */

describe("MUTATION: a MISPLACED banner is caught by post-composition check (iii)", () => {
  /*
   * WHY THIS EXISTS. Check (ii) — "the banner really is at bannerOffset" — was
   * deleted as a check that could not fire, and the comment left in its place
   * says the coverage is not lost because "(iii) pins the length AND position of
   * the inserted span". Nothing drove that. Measured in the reference deployment
   * at commit `cb2bb7d`, before this mutation test existed, with (iii) disabled
   * and nothing else changed: the whole suite stayed GREEN — 0 fail, wrapper
   * exit 0 — so the sentence justifying the deletion of (ii) was resting on an
   * unexecuted check. (The pass count of that run described that repo's suite on
   * that day, not this one's, and is deliberately not quoted.)
   *
   * The mutation below makes `composeRetained` append the banner at the END of
   * the file instead of inserting it after the preamble. It is LENGTH-NEUTRAL by
   * construction, so check (i)'s byte accounting balances exactly; the prior
   * banner is untouched, so (iv) has nothing to object to. Only a check that
   * looks at WHERE the inserted span is can see it — which is (iii), and which
   * is precisely the claim the deletion of (ii) was licensed by.
   */
  const MISPLACE = [
    [
      `  parts[idx] = head + banner;\n  return parts.join("");`,
      `  parts[idx] = head;\n  return parts.join("") + banner;`,
    ],
  ];

  test("the misplaced banner exits EXIT.CONSERVATION and writes nothing", () => {
    const mjs = mutatedTool("misplaced-banner", MISPLACE);
    const root = makeRoot("misplaced-banner");
    const before = hashTree(root);

    const res = runNodeJson(mjs, ["--root", root, "--file", "residue", "--keep", "10", "--apply"]);

    assert.equal(
      res.status,
      EXIT.CONSERVATION,
      `a banner composed at the wrong offset was not caught: ${res.all}`
    );
    assert.match(res.all, /POST-COMPOSITION CONSERVATION FAILED/);
    assert.match(res.all, /removing the banner does not reproduce the retained content/);
    assert.deepEqual(hashTree(root), before, "a failed composition must write NOTHING");
  });

  test("check (i) is BLIND to it — the byte count balances either way", () => {
    /*
     * Proves (iii) is discriminating rather than redundant with the arithmetic:
     * with (iii) disabled and nothing else changed, the same misplaced banner
     * gets past every remaining check.
     */
    const mjs = mutatedTool("misplaced-banner-no-iii", [
      ...MISPLACE,
      [
        "    if (withoutBanner !== liveContentText) {",
        "    if (false && withoutBanner !== liveContentText) {",
      ],
    ]);
    const root = makeRoot("misplaced-banner-no-iii");

    const res = runNodeJson(mjs, ["--root", root, "--file", "residue", "--keep", "10", "--apply"]);

    assert.equal(
      res.status,
      0,
      `without (iii) every remaining guard must pass — including (i)'s byte ` +
        `accounting, which cannot see position: ${res.all}`
    );

    // ...and the banner is observed at the TAIL of the live file rather than
    // after the preamble, which is what (iii) is the only check to notice
    const live = read(root, RETAINED.residue);
    assert.ok(live.trimEnd().endsWith(BANNER_END), "the banner must be observed at the file tail");
    assert.ok(
      !live.slice(0, live.indexOf("\n## ")).includes(BANNER_START),
      "the banner must be observed missing from its place after the preamble"
    );
  });
});

/* ================================================================== */
/* 6e. ROUTING RECONSTRUCTION — the guard that replaced three dead ones */
/* ================================================================== */

describe("MUTATION: an INTERLEAVED cut is caught by routing reconstruction (1d)", () => {
  /*
   * WHY THIS EXISTS. Three guards in the tool could not come out false for any
   * input and were deleted this round. One replacement was added, and unlike
   * them it has to be able to fire — otherwise the deletion traded dead code for
   * different dead code.
   *
   * The defect it catches is real and nothing else sees it. `routeSegments`
   * keeps the newest blocks, which are a PREFIX of the file. Make it keep
   * `blocks.slice(1, keepN + 1)` instead and the cut interleaves: the NEWEST
   * block is archived while blocks 2..N+1 stay live. The retained block COUNT is
   * still exactly keepN, the preamble is still first, the composition checks
   * still balance (they only ever look at the retained side), and the re-parse
   * still finds keepN blocks. Every one of those is blind to interleaving.
   */
  const INTERLEAVE = [
    [
      "  const keep = new Set(blocks.slice(0, Math.max(0, keepN)).map((s) => s.label));",
      "  const keep = new Set(blocks.slice(1, Math.max(0, keepN) + 1).map((s) => s.label));",
    ],
  ];

  test("the shipped tool rotates the same fixture cleanly", () => {
    const root = makeRoot("interleave-control");
    const original = read(root, RETAINED.residue);
    assert.equal(
      runJson(["--root", root, "--file", "residue", "--keep", "10", "--apply"]).status,
      0
    );
    assertExternalReconstruction(root, "residue", original, 10);
  });

  test("the interleaved cut exits EXIT.CONSERVATION and writes nothing", () => {
    const mjs = mutatedTool("interleave", INTERLEAVE);
    const root = makeRoot("interleave");
    const before = hashTree(root);

    const res = runNodeJson(mjs, ["--root", root, "--file", "residue", "--keep", "10", "--apply"]);

    assert.equal(res.status, EXIT.CONSERVATION, `an interleaved cut was not caught: ${res.all}`);
    assert.match(res.all, /ROUTING RECONSTRUCTION FAILED/);
    assert.match(res.all, /the two outputs are INTERLEAVED/);
    assert.deepEqual(hashTree(root), before, "a failed routing check must write NOTHING");
    assert.ok(!fs.existsSync(path.join(root, "build-os/memory/archive")));
  });

  test("with (1d) disabled the same cut exits 0 and archives the newest block — no other guard fires", () => {
    /*
     * Proves (1d) is discriminating rather than decorative. With the routing
     * reconstruction disabled and nothing else changed, the same interleaved cut
     * runs to completion, exits 0, and silently moves the newest block out of
     * the live file.
     */
    const mjs = mutatedTool("interleave-no-1d", [
      ...INTERLEAVE,
      [
        "  if (contentText + archivedText !== original) {",
        "  if (false && contentText + archivedText !== original) {",
      ],
    ]);
    const root = makeRoot("interleave-no-1d");
    const original = read(root, RETAINED.residue);
    const firstBlockHeader = "## TRUTH-UP 1 — stage-health recorder LIVE";
    assert.ok(original.includes(firstBlockHeader), "fixture must carry the newest block");

    const res = runNodeJson(mjs, ["--root", root, "--file", "residue", "--keep", "10", "--apply"]);
    assert.equal(res.status, 0, `without (1d) every remaining guard must pass: ${res.all}`);

    const live = read(root, RETAINED.residue);
    const archive = read(root, ARCHIVE.residue);
    assert.ok(
      !live.includes(firstBlockHeader),
      "without (1d) the newest block must be observed leaving the live file"
    );
    assert.ok(archive.includes(firstBlockHeader), "the newest block was archived instead");
    // ...and the tool still reported the expected block count, which is exactly
    // why a count-based check could not have caught this
    assert.equal(res.json.results[0].retainedBlocks, 10);
  });
});

describe("MUTATION: renderBanner refuses to emit bytes its own recogniser rejects", () => {
  /*
   * WHY THIS EXISTS. `isRenderedBanner` is what licenses this tool to DROP a
   * prior banner's bytes. If the writer and the recogniser ever disagree, the
   * tool does not crash — it quietly stops recognising its own banner and
   * starts STACKING a new one on every run, growing the file it exists to
   * shrink, silently and at exit 0.
   *
   * `renderBanner` therefore asserts its own output parses, and that assertion
   * was the one guard in this file no test observed: it is unreachable while
   * the two agree, which is exactly what makes it a guard. Both directions of
   * the disagreement are driven below, on a scratch root, and both must fail at
   * EXIT.CONFIG during PLANNING, before a single byte is written.
   */
  const cases = [
    [
      "writer drifts",
      [
        [
          "**THIS FILE IS NOT THE WHOLE RECORD.** ${archivedBlocks} older blocks ",
          "**THIS FILE IS NOT THE ENTIRE RECORD.** ${archivedBlocks} older blocks ",
        ],
      ],
    ],
    [
      "recogniser drifts",
      [["  if (lines.length !== 11) return false;", "  if (lines.length !== 10) return false;"]],
    ],
  ];

  for (const [label, edits] of cases) {
    test(`${label}: EXIT.CONFIG, BANNER SHAPE DRIFT, and nothing written`, () => {
      const mjs = mutatedTool(`drift-${label.replace(/\s+/g, "-")}`, edits);
      const root = makeRoot(`drift-${label.replace(/\s+/g, "-")}`);
      const before = hashTree(root);

      const res = runNodeJson(mjs, ["--root", root, "--file", "residue", "--keep", "10", "--apply"]);

      assert.equal(res.status, EXIT.CONFIG, `writer/recogniser drift was not caught: ${res.all}`);
      assert.match(res.all, /BANNER SHAPE DRIFT/);
      assert.match(res.all, /writer and the recogniser must be edited together/);
      assert.deepEqual(hashTree(root), before, "a CONFIG failure must write NOTHING");
      assert.ok(!fs.existsSync(path.join(root, "build-os/memory/archive")));
    });
  }

  test("the shipped tool does NOT trip it — the two agree today", () => {
    const root = makeRoot("drift-control");
    const res = runJson(["--root", root, "--file", "residue", "--keep", "10", "--apply"]);
    assert.equal(res.status, 0, res.all);
    assert.doesNotMatch(res.all, /BANNER SHAPE DRIFT/);
  });
});

describe("MUTATION: each EXIT.RETENTION guard is driven by a fixture that fires it", () => {
  /*
   * All three retention guards are UNREACHABLE from the CLI while the code is
   * correct — routing cannot return the wrong block count, the preamble is
   * always the first retained segment, and the banner markers are chosen not to
   * match any delimiter. That is what makes them guards, and it is also why no
   * ordinary fixture can distinguish a live one from a deleted one. Each test
   * below reintroduces exactly the defect its guard exists to catch.
   */

  test("guard 1 — retained block count: exit EXIT.RETENTION, nothing written", () => {
    const mjs = mutatedTool("retention-count", [
      [
        "  const keep = new Set(blocks.slice(0, Math.max(0, keepN)).map((s) => s.label));",
        "  const keep = new Set(blocks.slice(0, Math.max(0, keepN - 1)).map((s) => s.label));",
      ],
    ]);
    const root = makeRoot("retention-count");
    const before = hashTree(root);
    const res = runNodeJson(mjs, ["--root", root, "--file", "residue", "--keep", "10", "--apply"]);
    assert.equal(res.status, EXIT.RETENTION, res.all);
    assert.match(res.all, /RETENTION FAILED .*retained 9 blocks, expected 10/);
    assert.deepEqual(hashTree(root), before);
  });

  test("guard 2 — preamble byte-exact at the head: exit EXIT.RETENTION, nothing written", () => {
    const mjs = mutatedTool("retention-preamble", [
      [
        "  const retained = segments.filter((s) => !isBlock(s) || keep.has(s.label));",
        "  const retained = segments.filter((s) => !isBlock(s) || keep.has(s.label)).reverse();",
      ],
    ]);
    const root = makeRoot("retention-preamble");
    const before = hashTree(root);
    const res = runNodeJson(mjs, ["--root", root, "--file", "residue", "--keep", "10", "--apply"]);
    assert.equal(res.status, EXIT.RETENTION, res.all);
    assert.match(res.all, /head preamble was not preserved byte-exact/);
    assert.deepEqual(hashTree(root), before);
  });

  test("guard 3 — post-composition re-parse: exit EXIT.RETENTION, nothing written", () => {
    // a banner marker that DOES match the residue delimiter, which is precisely
    // what the comment above BANNER_START promises will never happen
    const mjs = mutatedTool("retention-reparse", [
      [
        'export const BANNER_START = "<!-- rotate-memory:archive-pointer:start -->";',
        'export const BANNER_START = "## rotate-memory archive pointer";',
      ],
    ]);
    const root = makeRoot("retention-reparse");
    const before = hashTree(root);
    const res = runNodeJson(mjs, ["--root", root, "--file", "residue", "--keep", "10", "--apply"]);
    assert.equal(res.status, EXIT.RETENTION, res.all);
    assert.match(res.all, /re-parses to\s+11 blocks, expected 10/);
    assert.deepEqual(hashTree(root), before);
  });
});

/* ================================================================== */
/* 7. Size ceiling                                                     */
/* ================================================================== */

describe("post-rotation size ceiling", () => {
  test("the shipped defaults are a 200 KB ceiling and keep=10", () => {
    assert.equal(DEFAULT_MAX_BYTES, 200 * 1024);
    assert.equal(DEFAULT_KEEP, 10);
  });

  test("a breach exits non-zero, reports the measured size, and does not auto-reduce N", () => {
    const root = makeRoot("ceiling");
    const before = hashTree(root);

    const res = run([
      "--root",
      root,
      "--file",
      "current_state",
      "--keep",
      "20",
      "--max-bytes",
      "512",
      "--apply",
    ]);

    assert.equal(res.status, EXIT.CEILING, res.all);
    assert.match(res.all, /SIZE CEILING EXCEEDED/);
    assert.match(res.all, /measured/i);
    assert.match(res.all, /512/);
    assert.match(res.all, /lower/i); // tells the operator to lower N
    assert.match(res.all, /--keep/);
    assert.match(res.all, /\bkeep=20\b/); // reports the N it was GIVEN, unreduced
    assert.deepEqual(hashTree(root), before, "a ceiling breach must not write");
  });

  test("within the ceiling, the retained file ON DISK is under it", () => {
    const root = makeRoot("ceiling-ok");
    const res = runJson(["--root", root, "--keep", "5", "--apply"]);
    assert.equal(res.status, 0, res.all);
    for (const r of res.json.results) {
      assert.ok(r.withinCeiling);
      assert.ok(r.retainedBytes <= DEFAULT_MAX_BYTES);
      const onDisk = fs.statSync(path.join(root, r.path)).size;
      assert.ok(onDisk <= DEFAULT_MAX_BYTES);
      // the ceiling is measured against the BANNER-INCLUSIVE bytes actually written
      assert.equal(onDisk, r.retainedBytes, `${r.name}: reported size is the on-disk size`);
    }
  });
});

/* ================================================================== */
/* 8. Never delete + INDEX.md resolvability                            */
/* ================================================================== */

describe("archive completeness and INDEX.md", () => {
  test("each of residue's 114 blocks lands in exactly one output: 10 retained, 104 archived", () => {
    const root = makeRoot("no-delete");
    const original = read(root, RETAINED.residue);
    assert.equal(run(["--root", root, "--file", "residue", "--keep", "10", "--apply"]).status, 0);

    const retained = read(root, RETAINED.residue);
    const archive = read(root, ARCHIVE.residue);
    const blocks = segmentFile(original, FILE_SPECS.residue).filter((s) => s.kind === "block");
    assert.equal(blocks.length, 114);

    let inR = 0;
    let inA = 0;
    for (const b of blocks) {
      const r = retained.includes(b.text);
      const a = archive.includes(b.text);
      assert.ok(r !== a, `${b.label}: must be in exactly one output (retained=${r} archive=${a})`);
      if (r) inR++;
      else inA++;
    }
    assert.equal(inR, 10);
    assert.equal(inA, 104);
  });

  test("INDEX.md keeps a rotated-away citation resolvable by original line", () => {
    const root = makeRoot("index");
    const original = read(root, RETAINED.residue);

    // pick a block that will rotate away and note its 1-based source line.
    // `## PROJECT HANDOFF 93` is block 93 of 114, so keep=10 rotates it away —
    // this stands in for any `residue.md:<line>` citation held outside the file.
    const lines = original.split("\n");
    const targetLine = lines.findIndex((l) => l.startsWith("## PROJECT HANDOFF 93")) + 1;
    assert.ok(targetLine > 0, "fixture must contain the cited heading");

    assert.equal(run(["--root", root, "--file", "residue", "--keep", "10", "--apply"]).status, 0);

    const index = read(root, "build-os/memory/archive/INDEX.md");
    assert.match(index, /# Archived Build OS memory/);
    // resolvable: source path:line -> archive file + batch + line in the archive
    assert.ok(
      index.includes(`build-os/memory/residue.md:${targetLine}`),
      `INDEX must cite build-os/memory/residue.md:${targetLine}`
    );
    assert.ok(index.includes("residue.archive.md"));
    assert.ok(index.includes("PROJECT HANDOFF 93"));

    // the archive line the index points at really is that heading
    const row = index
      .split("\n")
      .find((l) => l.includes(`build-os/memory/residue.md:${targetLine}`));
    const archiveLine = Number(/residue\.archive\.md:(\d+)/.exec(row)?.[1]);
    assert.ok(Number.isInteger(archiveLine) && archiveLine > 0, `bad archive line in row: ${row}`);
    const archiveLines = read(root, ARCHIVE.residue).split("\n");
    assert.ok(
      archiveLines[archiveLine - 1].startsWith("## PROJECT HANDOFF 93"),
      `archive line ${archiveLine} is: ${archiveLines[archiveLine - 1]}`
    );
  });

  /**
   * SAFETY GREP. Comments are stripped from the shell before matching, so the
   * grep is aggressive against CODE instead of being loosened until it stops
   * tripping over prose.
   */
  test("neither the .mjs nor the .sh names any token from the enumerated delete/truncate/shell-out list", () => {
    const src = fs.readFileSync(path.join(HERE, "rotate-memory.mjs"), "utf8");

    const DESTRUCTIVE_FS = [
      "unlink",
      "unlinkSync",
      "rm",
      "rmSync",
      "rmdir",
      "rmdirSync",
      "truncate",
      "truncateSync",
      "ftruncate",
      "ftruncateSync",
    ];
    for (const fn of DESTRUCTIVE_FS) {
      assert.ok(
        !new RegExp(`\\bfs\\.${fn}\\b`).test(src),
        `.mjs calls the destructive fs.${fn}`
      );
      assert.ok(
        !new RegExp(`\\b${fn}\\s*\\(`).test(src),
        `.mjs calls the destructive ${fn}(`
      );
    }
    // no raw fd handling, no shelling out, no in-place open-for-truncate
    assert.ok(!/\bopenSync\b|\bcreateWriteStream\b/.test(src), ".mjs opens a raw write handle");
    // `src` here is rotate-memory.mjs, not this file: the tool must not shell out
    assert.ok(!/child_process|execSync|spawnSync/.test(src), ".mjs shells out");

    // the ONLY write is the staging file; the live file is replaced by rename
    const writes = src.match(/writeFileSync\([^,]+,/g) ?? [];
    assert.ok(writes.length > 0, "expected at least one write call");
    for (const w of writes) {
      assert.match(w, /writeFileSync\(staging,/, `unexpected write target: ${w}`);
    }

    // --- shell: strip comments and blank lines, then grep the CODE hard ---
    const sh = fs.readFileSync(SCRIPT, "utf8");
    const shCode = sh
      .split("\n")
      .filter((l) => !/^\s*#/.test(l) && l.trim() !== "")
      .join("\n");
    assert.ok(shCode.length > 0);
    for (const tok of [
      "rm",
      "rmdir",
      "unlink",
      "shred",
      "truncate",
      "mv",
      "cp",
      "dd",
      "tee",
      "find",
      "xargs",
      "chmod",
      "chown",
      "git",
      "curl",
      "ssh",
    ]) {
      assert.ok(
        !new RegExp(`(^|[\\s;&|(])${tok}([\\s;&|)]|$)`, "m").test(shCode),
        `.sh code invokes ${tok}`
      );
    }
    assert.ok(!/>\s*['"]?\$/.test(shCode), ".sh redirects into a variable path");
    assert.ok(!/(^|[^>2])>\s*[^&\s]/.test(shCode.replace(/>\/dev\/null/g, "")), ".sh truncates a file by redirect");
    // the shell is a pure entry point: its last effective statement execs the .mjs
    const last = shCode.split("\n").filter((l) => l.trim() !== "").pop();
    assert.match(last, /^exec node .*rotate-memory\.mjs/, `.sh must end by exec'ing the .mjs: ${last}`);
  });
});

/* ================================================================== */
/* 9. The REAL FILE CONTENT — exercised on scratch copies only          */
/* ================================================================== */

const REAL_TARGETS = [
  ["current_state", "build-os/memory/current_state.md"],
  ["residue", "build-os/memory/residue.md"],
  ["active_packet", "build-os/packets/active_packet.md"],
];

const snapshotReal = () =>
  Object.fromEntries(
    REAL_TARGETS.map(([, t]) => {
      const full = path.join(REPO_ROOT, t);
      const st = fs.statSync(full);
      return [t, { hash: sha256(fs.readFileSync(full)), size: st.size, mtimeMs: st.mtimeMs }];
    })
  );

/**
 * A scratch root holding BYTE-EXACT COPIES of the real three memory files.
 *
 * This is what makes the real tree structurally unreachable from the suite. The
 * tests below still run against this repo's genuine memory content, whatever its
 * size — the real delimiters, the real heterogeneous headings, the real byte
 * distribution — but the directory the tool is pointed at is a temp directory,
 * so no defect in the tool, and no defect in its apply gate, can reach
 * build-os/memory/.
 *
 * Copied as BUFFERS and verified by sha256, not as decoded strings: a string
 * round-trip would silently normalise any byte that is not valid UTF-8 and the
 * "copy" would stop being the file under test.
 */
/**
 * Copy one file as BUFFERS and verify the copy by sha256.
 *
 * ON THE sha256 ASSERTION. It cannot be made to FIRE through this interface on
 * a working filesystem — the bytes are read back through the same fs that just
 * accepted them — which is the same reachability condition as the tool's own
 * write-back check, and mutation testing kills nothing here for that reason.
 * What CAN be exercised, and is (see the test below), is the property the
 * assertion is guarding: that the copy is byte-exact for content a string
 * round-trip would have mangled. The three real files happen to be valid UTF-8
 * today, so only a synthetic fixture can show the difference.
 */
function copyVerified(srcPath, destPath, label) {
  const src = fs.readFileSync(srcPath);
  fs.mkdirSync(path.dirname(destPath), { recursive: true });
  fs.writeFileSync(destPath, src);
  assert.equal(
    sha256(fs.readFileSync(destPath)),
    sha256(src),
    `${label}: the scratch copy is not byte-identical to the source file`
  );
}

function realCopyRoot(label) {
  const root = tmpRoot(label);
  for (const [name, rel] of REAL_TARGETS) {
    copyVerified(path.join(REPO_ROOT, rel), path.join(root, rel), name);
  }
  return root;
}

test("copyVerified is byte-exact for content that is NOT valid UTF-8", () => {
  const dir = tmpRoot("copy-bytes");
  const src = path.join(dir, "src.md");
  // a lone 0xFF, an unpaired continuation byte, and a truncated 2-byte lead:
  // none of these survives a utf8 decode/encode round trip
  const bytes = Buffer.from([0x41, 0xff, 0xfe, 0x80, 0xc3, 0x0a, 0x42]);
  fs.writeFileSync(src, bytes);

  const dest = path.join(dir, "nested/dest.md");
  copyVerified(src, dest, "non-utf8 fixture");
  assert.deepEqual(fs.readFileSync(dest), bytes, "the buffer copy lost bytes");

  // ...and the guard is load-bearing: the string round-trip it exists to avoid
  // really would have replaced those bytes with U+FFFD
  const viaString = Buffer.from(fs.readFileSync(src).toString("utf8"), "utf8");
  assert.notDeepEqual(
    viaString,
    bytes,
    "expected a utf8 string round-trip to be LOSSY for these bytes — if it is not, " +
      "the reason realCopyRoot copies buffers no longer holds"
  );
  // latin1 is the tool's own encoding and IS lossless over the same bytes
  assert.deepEqual(Buffer.from(fs.readFileSync(src).toString("latin1"), "latin1"), bytes);
});

describe("the scratch-root gate", () => {
  /**
   * THE GATE, PROVEN BY POSITIVE CONTROL.
   *
   * Every one of these is a real call to a real wrapper. None of them starts a
   * process: `requireScratchRoot` throws first. That is the whole claim — the
   * check happens at the call, on the actual argument list, so none of the
   * dressing that defeats a source scan (an alias, a helper closing over the
   * root, a default parameter, a recomputed path, object indirection, a
   * symlink) helps.
   */
  test("20 rootless, repo-rooted, out-of-tmp, symlinked and malformed shapes throw before spawning", () => {
    const realRoot = REPO_ROOT;
    const scratch = makeRoot("gate-ok");
    const before = snapshotReal();

    /*
     * FAIL-SAFE ORDERING, and it matters. A positive control for this gate is
     * by construction an invocation that WOULD hit the real tree if the gate
     * were dead — so the order is chosen such that the first probe of each
     * branch is HARMLESS EVEN IF IT RAN, and `assert.throws` aborts the test
     * before any probe that would not be.
     *
     * Both openers below omit `--apply`, so the worst case if the gate were
     * removed is a read-only dry run over the real tree. Only after each has
     * proved its branch live do the `--apply` shapes follow.
     */
    assert.throws(() => run(["--file", "residue"]), /no explicit --root/); // harmless if it ran
    assert.throws(() => run(["--keep", "10", "--apply"]), /no explicit --root/);
    assert.throws(() => runJson(["--keep", "10", "--apply"]), /no explicit --root/);
    assert.throws(() => runNodeJson(TOOL_MJS, ["--keep", "10", "--apply"]), /no explicit --root/);
    assert.throws(() => run([]), /no explicit --root/);

    // the real repo, reached by shapes a source scan cannot see
    assert.throws(() => run(["--root", realRoot, "--keep", "10"]), /inside the REAL repo root/); // harmless if it ran
    assert.throws(() => runJson(["--root", realRoot, "--apply"]), /inside the REAL repo root/);
    assert.throws(() => runNodeJson(TOOL_MJS, ["--root", realRoot]), /inside the REAL repo root/);
    assert.throws(() => run(["--root", path.join(realRoot, ".")]), /inside the REAL repo root/);
    assert.throws(() => run(["--root", path.join(realRoot, "build-os")]), /inside the REAL repo root/);
    assert.throws(() => run(["--root", path.resolve(HERE, "..", "..")]), /inside the REAL repo root/);
    assert.throws(() => run(["--root", "."], { cwd: realRoot }), /inside the REAL repo root/);
    assert.throws(() => run(["--root", "build-os/.."], { cwd: realRoot }), /inside the REAL repo root/);

    // an earlier --root is checked too, not only the one parseArgs would keep
    assert.throws(
      () => run(["--root", realRoot, "--root", scratch, "--keep", "10"]),
      /inside the REAL repo root/
    );

    // outside the repo but outside this run's temp dir: still refused
    assert.throws(() => run(["--root", os.tmpdir(), "--keep", "10"]), /not under this run's temp dir/);
    assert.throws(() => run(["--root"]), /--root is the last argument/);
    assert.throws(() => run("--root " + scratch), /args must be an array/);

    /*
     * A SYMLINK UNDER THE TEMP DIR THAT POINTS OUT OF IT — the shape that
     * defeated the lexical-only gate. `path.resolve` does not follow symlinks,
     * so this path is textually under SESSION_TMP and textually outside
     * REPO_ROOT: BOTH lexical containment tests pass. Only resolution through
     * symlinks sees where it actually goes.
     *
     * The target is a DECOY scratch directory of this run's own making, never
     * REPO_ROOT. What has to be proven is "the link escapes SESSION_TMP and the
     * gate notices", and a decoy proves exactly that without ever aiming a live
     * probe at the real tree. The decoy is removed in `finally`.
     *
     * Fail-safe ordering holds here too: the first symlink probe omits
     * `--apply`.
     */
    const decoy = realpathDeep(fs.mkdtempSync(path.join(os.tmpdir(), "rotmem-decoy-")));
    try {
      assert.ok(decoy !== SESSION_TMP && !decoy.startsWith(SESSION_TMP + path.sep));
      assert.ok(decoy !== REPO_ROOT && !decoy.startsWith(REPO_ROOT + path.sep));

      const link = path.join(SESSION_TMP, "escaping-link");
      fs.symlinkSync(decoy, link, "dir");

      // the link is lexically indistinguishable from a legitimate scratch root
      assert.ok(link.startsWith(SESSION_TMP + path.sep), "the link is under the temp dir");
      assert.ok(!path.resolve(link).startsWith(REPO_ROOT + path.sep), "...and lexically outside the repo");

      const escaped = /THROUGH SYMLINKS.*not under this run's temp dir/;
      assert.throws(() => run(["--root", link, "--keep", "10"]), escaped); // harmless if it ran
      // a not-yet-existing root UNDER the link: resolved via its deepest
      // existing ancestor, which is the link, so it escapes too
      assert.throws(() => run(["--root", path.join(link, "nested")]), escaped);
      assert.throws(() => runJson(["--root", link, "--keep", "10", "--apply"]), escaped);

      fs.unlinkSync(link);
    } finally {
      fs.rmSync(decoy, { recursive: true, force: true });
    }

    // ...and the two things that ARE allowed still work
    assert.equal(run(["--help"]).status, 0);
    assert.equal(run(["--root", scratch, "--keep", "10"]).status, 0);

    // belt and braces: none of the above touched the real tree
    assert.deepEqual(snapshotReal(), before, "a gate probe reached the real tree");
  });

  /**
   * THE RETURN HALF OF THE CROSS-SCAN.
   *
   * rotate-memory.rootscan.test.mjs reads THIS file as data and reports the
   * enumerated bad root/spawn shapes written in it. This assertion is what makes
   * that scanner trustworthy without the scanner having to vouch for itself: a
   * file that cannot obtain a spawn API cannot start a process, and a file that
   * cannot start a process cannot invoke the rotation tool, whatever else is
   * wrong with it.
   *
   * -----------------------------------------------------------------------
   * WHAT THIS USED TO CLAIM, AND WHY THAT WAS FALSE
   * -----------------------------------------------------------------------
   * It used to assert that the scanner "never NAMES the child-process module at
   * all, WHICH STRICTLY IMPLIES IT NEVER IMPORTS ONE", and the scanner composed
   * its own specifier from two fragments so that flat count could be zero.
   *
   * The implication does not hold, and the counterexample is the very trick the
   * scanner was using on itself: a `createRequire` call handed a specifier
   * assembled from four fragments names the module nowhere as a literal token
   * and imports it anyway. (Written out, that shape is the
   * `acquisitionProbes.indirect` entry in rootscan-controls.json; it is not
   * written out here, because comments in this file are scanned like code — over-
   * reporting on prose is the price of never under-reporting on code.) It was
   * demonstrated, not hypothesised: it obtained a spawn API and rewrote live
   * Build OS memory while every count still read zero.
   *
   * WHAT IS ASSERTED NOW, which is true and is what actually matters: the
   * scanner has NO WAY TO OBTAIN A LOADER. The source is concatenation-folded
   * first, so a specifier written in pieces is read as the string it denotes;
   * then every named route to a module — a static import, a dynamic import, a
   * require, `createRequire`, an `eval` call, a `new Function` call, the
   * `binding` back-door, the CommonJS module constructor — is required to be
   * absent for the child-process module, and absent outright for the indirect
   * routes. Whether the file NAMES the module is no longer the question; the
   * scanner is free to name it, and does.
   *
   * NAMED RESIDUAL: a specifier COMPUTED at run time (`["chi","ld"].join("")`)
   * still folds to nothing. It is not free — it still needs one of the loaders
   * enumerated above, all of which are reported — and if it ever succeeds, the
   * real-memory tripwire both files import is what makes the run red.
   */
  test("the root scanner can acquire nothing that starts a process", () => {
    const ROOTSCAN = path.join(HERE, "rotate-memory.rootscan.test.mjs");
    assert.ok(fs.existsSync(ROOTSCAN), "the cross-scanner is missing — half the mechanism is gone");
    const src = fs.readFileSync(ROOTSCAN, "utf8");
    assert.ok(src.length > 4000, "the cross-scanner is implausibly short");

    assert.deepEqual(
      moduleImportsOf(src, "child_process"),
      [],
      "the cross-scanner imports the child-process module"
    );
    assert.deepEqual(
      indirectAcquisitionFindings(src, "rotate-memory.rootscan.test.mjs"),
      [],
      "the cross-scanner holds an indirect route to a loader"
    );
    // it must not import the tool under test either — there is then nothing
    // about it that needs guarding
    assert.doesNotMatch(
      src,
      /from\s*["']\.\/rotate-memory\.mjs["']/,
      "the cross-scanner imports the tool under test"
    );
  });

  /**
   * ...and the check above is not vacuous. The same three shapes it forbids are
   * planted in SYNTHETIC SOURCE — never in a real file — and each must be
   * reported. Without this, "no findings" is indistinguishable from "the scan
   * looked at nothing", which is how the previous version stayed green over a
   * hole big enough to destroy the live memory.
   */
  test("...and that check reports each forbidden shape when it is actually present", () => {
    /*
     * The planted shapes are read from rootscan-controls.json. They are NOT
     * written here: a control planted in this file is, to the cross-scan that
     * reads this file, indistinguishable from the defect it imitates — and this
     * file is scanned for exactly these shapes. JSON cannot execute, so the
     * control can be spelled out in full there without becoming one.
     */
    const probes = JSON.parse(
      fs.readFileSync(path.join(HERE, "rootscan-controls.json"), "utf8")
    ).acquisitionProbes;
    const BASE = probes.base;
    assert.ok(probes.moduleImports.length >= 3 && probes.indirect.length >= 4);

    for (const { label, source } of probes.moduleImports) {
      assert.notDeepEqual(
        moduleImportsOf(BASE + source, "child_process"),
        [],
        `${label} was not reported`
      );
    }
    for (const { label, source } of probes.indirect) {
      assert.notDeepEqual(
        indirectAcquisitionFindings(BASE + source, "synthetic"),
        [],
        `${label} was not reported`
      );
    }
    assert.deepEqual(moduleImportsOf(BASE, "child_process"), [], "the base source is clean");
    assert.deepEqual(indirectAcquisitionFindings(BASE, "synthetic"), []);
  });

  // the rule is documented where a future editor will read it
  test("the header states the rule sentence verbatim", () => {
    assert.match(SUITE_SRC, /NO TEST IN THIS FILE INVOKES THE TOOL WITHOUT AN EXPLICIT SCRATCH `--root`\./);
  });
});

describe("the real memory files are READ and copied; the real tree is unchanged by each run below", () => {
  test("a dry-run over a SCRATCH COPY of the real files writes nothing to that copy", () => {
    const root = realCopyRoot("real-dryrun");
    const before = hashTree(root);

    const res = runJson(["--root", root, "--keep", "10"]);
    assert.equal(res.status, 0, res.all);
    assert.equal(res.json.mode, "dry-run");
    assert.equal(res.json.results.length, 3);

    assert.deepEqual(hashTree(root), before, "a dry-run mutated a memory file");
    assert.ok(
      !fs.existsSync(path.join(root, "build-os/memory/archive")),
      "a dry-run must not create the archive directory"
    );
  });

  /**
   * The real tree is only ever READ by this suite, so this holds for the whole
   * run rather than around one invocation.
   *
   * Stated as a DIFFERENCE, never as "the real archive does not exist": the
   * archive is append-only and never deleted, so an existence assertion would go
   * false forever after the first real --apply and turn this suite red during
   * the very close it is meant to certify.
   */
  test("the real memory tree and its archive are byte-identical after an --apply on a scratch copy", () => {
    const before = snapshotReal();
    const archiveDir = path.join(REPO_ROOT, "build-os/memory/archive");
    const archiveBefore = snapshotDir(archiveDir);

    const root = realCopyRoot("real-untouched");
    assert.equal(runJson(["--root", root, "--keep", "10", "--apply"]).status, 0);

    assert.deepEqual(snapshotReal(), before, "a real memory file changed");
    assert.deepEqual(snapshotDir(archiveDir), archiveBefore, "the real archive changed");
  });

  /**
   * Every reported byte count recomputed from the BYTES ON DISK — the source
   * file, the live file the tool wrote, and its stat size — with nothing taken
   * from the tool's own report and nothing cross-checked against another
   * reported number.
   *
   * Run TWICE: a first rotation, then a RE-ROTATION of its output. The second
   * pass is the one that matters for banner replacement — `priorBannerBytes` is
   * 0 on an un-rotated file, so any assertion about it there is trivially
   * satisfiable, and the whole prior-banner path would go unexercised.
   *
   * The keeps are DERIVED from the files' actual block counts rather than
   * hard-coded, because this suite must stay green after a real --apply: once
   * the real memory has been rotated to 10 blocks, a hard-coded `keep=10` first
   * pass is a no-op and proves nothing.
   */
  test("real content: all 8 reported byte counts recomputed from disk, first rotation AND re-rotation", () => {
    const root = realCopyRoot("real-counts");

    const totals = REAL_TARGETS.map(([name, rel]) => {
      const t = fs.readFileSync(path.join(root, rel)).toString("latin1");
      return segmentFile(t, FILE_SPECS[name]).filter((s) => s.kind === "block").length;
    });
    const smallest = Math.min(...totals);
    /*
     * THE FLOOR THIS PROOF NEEDS, AND WHY IT IS 3.
     *
     * Both passes must actually rotate: the first takes the file from `smallest`
     * blocks to `keep1`, the second from `keep1` to `keep2`, and only the second
     * exercises the prior-banner path at all. That needs three distinct
     * descending counts, so a file carrying fewer than 3 blocks cannot drive this
     * proof — and saying so out loud is the honest form. It is NOT skipped
     * quietly: a repo whose memory is that small has nothing here to prove, and a
     * scaffolded repo is above the floor by construction (the shipped scaffold
     * seeds several `##` sections per file; that coupling is pinned by the
     * delimiter test below).
     */
    assert.ok(
      smallest >= 3,
      `this proof needs a two-pass rotation, so every rotating file must carry >= 3 blocks ` +
        `under its own FILE_SPECS delimiter; the smallest carries ${smallest} ` +
        `(per file: ${JSON.stringify(Object.fromEntries(REAL_TARGETS.map(([n], i) => [n, totals[i]])))}). ` +
        `A count of 0 means the delimiter does not match this file's format at all — see the ` +
        `FILE_SPECS comment in rotate-memory.mjs, and note that such a file silently never rotates.`
    );
    /*
     * Keeps DERIVED from the smallest real block count, never hard-coded: this
     * suite must stay green both on a pristine tree and after a real --apply has
     * already reduced it (a hard-coded keep that exceeds the block count is a
     * no-op, and a no-op pass proves nothing). Small keeps also stay under the
     * 200 KB ceiling whatever the file sizes are — the ceiling has its own tests,
     * and this one is about byte accounting.
     */
    const keep1 = Math.min(3, smallest - 1);
    const keep2 = keep1 - 1;
    assert.ok(keep2 >= 1, `derived keeps must both be >= 1 (got ${keep1} then ${keep2})`);

    for (const [pass, keep] of [["first rotation", keep1], ["re-rotation", keep2]]) {
      const sources = Object.fromEntries(
        REAL_TARGETS.map(([name, rel]) => [name, fs.readFileSync(path.join(root, rel)).toString("latin1")])
      );

      const res = runJson(["--root", root, "--keep", String(keep), "--apply"]);
      assert.equal(res.status, 0, res.all);
      const byName = Object.fromEntries(res.json.results.map((r) => [r.name, r]));

      for (const [name, rel] of REAL_TARGETS) {
        const original = sources[name];
        const segs = segmentFile(original, FILE_SPECS[name]);
        assertSegmentPartition(original, segs);

        const blocks = segs.filter((s) => s.kind === "block");
        const keptLabels = new Set(blocks.slice(0, keep).map((s) => s.label));
        const expRetained = segs
          .filter((s) => s.kind !== "block" || keptLabels.has(s.label))
          .map((s) => s.text)
          .join("");
        const expArchived = segs
          .filter((s) => s.kind === "block" && !keptLabels.has(s.label))
          .map((s) => s.text)
          .join("");
        assert.equal(expRetained + expArchived, original, `${name}/${pass}: partition not byte-exact`);
        assert.equal(md5(expRetained + expArchived), md5(original), `${name}/${pass}: md5 mismatch`);

        // ---- the bytes the tool actually wrote, measured from disk ----
        const live = fs.readFileSync(path.join(root, rel)).toString("latin1");
        const onDisk = fs.statSync(path.join(root, rel)).size;
        const preText = segs.find((s) => s.kind === "preamble")?.text ?? "";
        const prior = externalSplitPreamble(preText);
        const newBannerAt = live.indexOf(BANNER_START, prior.head.length);
        assert.ok(newBannerAt >= 0, `${name}/${pass}: the live file carries no banner`);
        const newBannerEnd = live.indexOf(BANNER_TAIL, newBannerAt) + BANNER_TAIL.length;
        const newBanner = live.slice(newBannerAt, newBannerEnd);
        assert.ok(
          externallyIsRenderedBanner(newBanner),
          `${name}/${pass}: what the tool wrote does not parse as a rendered banner`
        );
        const pad = prior.head.length > 0 && !prior.head.endsWith("\n") ? 1 : 0;
        const liveMinusBanner = live.slice(0, prior.head.length) + live.slice(newBannerEnd);

        const r = byName[name];
        assert.ok(r, `${name}/${pass} missing from the report`);
        assert.equal(r.noop, false, `${name}/${pass}: this pass must actually rotate`);

        // 1. originalBytes            2. retainedContentBytes   3. archivedBytes
        assert.equal(r.originalBytes, original.length, `${name}/${pass}: originalBytes`);
        assert.equal(r.retainedContentBytes, expRetained.length, `${name}/${pass}: retainedContentBytes`);
        assert.equal(r.archivedBytes, expArchived.length, `${name}/${pass}: archivedBytes`);
        // 4. priorBannerBytes — measured on the SOURCE preamble, externally
        assert.equal(r.priorBannerBytes, prior.banner.length, `${name}/${pass}: priorBannerBytes`);
        // 5. liveContentBytes — measured on the WRITTEN file, banner excised
        assert.equal(r.liveContentBytes, liveMinusBanner.length, `${name}/${pass}: liveContentBytes`);
        // 6. bannerBytes — measured on the banner found on disk
        assert.equal(r.bannerBytes, newBanner.length, `${name}/${pass}: bannerBytes`);
        // 7. bannerPadBytes          8. retainedBytes — the stat size
        assert.equal(r.bannerPadBytes, pad, `${name}/${pass}: bannerPadBytes`);
        assert.equal(r.retainedBytes, onDisk, `${name}/${pass}: retainedBytes != stat size`);

        // block counts, likewise recomputed
        assert.equal(r.totalBlocks, blocks.length, `${name}/${pass}: totalBlocks`);
        assert.equal(r.retainedBlocks, keep, `${name}/${pass}: retainedBlocks`);
        assert.equal(r.archivedBlocks, blocks.length - keep, `${name}/${pass}: archivedBlocks`);

        // full external reconstruction: live + prior banner + archive == source
        assertExternalReconstruction(root, name, original, keep, "latin1");
      }

      if (pass === "re-rotation") {
        // the non-trivial pass: a real banner, written over real content by the
        // previous pass, must actually be replaced
        for (const r of res.json.results) {
          assert.ok(r.priorBannerBytes > 0, `${r.name}: the re-rotation must replace a prior banner`);
        }
      }
    }
  });

  /**
   * The headline end-to-end proof, at the SHIPPED keep: rotate real content and
   * put it back together from the bytes on disk — live file minus the banner,
   * plus the prior banner where it stood, plus the archive — and require the
   * md5 to be the source's md5, per file.
   *
   * Written so it holds after a real --apply too: if the real files have already
   * been rotated to 10 blocks, keep=10 is the genuine no-op path, and
   * `assertExternalReconstruction` asserts byte-identity there instead.
   */
  test("external conservation on all three real files at keep=10, md5-reconstructed", () => {
    const root = realCopyRoot("real-keep10");
    const originals = Object.fromEntries(
      REAL_TARGETS.map(([name, rel]) => [name, fs.readFileSync(path.join(root, rel)).toString("latin1")])
    );

    const res = runJson(["--root", root, "--keep", "10", "--apply"]);
    assert.equal(res.status, 0, res.all);
    assert.equal(res.json.results.length, 3);

    for (const [name] of REAL_TARGETS) {
      const totalBlocks = segmentFile(originals[name], FILE_SPECS[name]).filter(
        (s) => s.kind === "block"
      ).length;
      const out = assertExternalReconstruction(root, name, originals[name], 10, "latin1");
      assert.equal(
        out.rotated,
        totalBlocks > 10,
        `${name}: a file with ${totalBlocks} blocks must ${totalBlocks > 10 ? "" : "not "}rotate at keep=10`
      );
    }
  });

  test("real content at the shipped defaults lands under the 256 KB Read limit", () => {
    const root = realCopyRoot("real-ceiling");
    const res = runJson(["--root", root, "--keep", String(DEFAULT_KEEP)]);
    assert.equal(res.status, 0, res.all);
    assert.equal(res.json.results.length, 3);
    for (const r of res.json.results) {
      assert.ok(r.withinCeiling, `${r.name} would still breach the ceiling`);
      assert.ok(
        r.retainedBytes < 256 * 1024,
        `${r.name} would be ${r.retainedBytes} B, at/over the 256 KB Read limit`
      );
    }
  });

  /**
   * THE DELIMITER/SCAFFOLD COUPLING, WHICH IS THE ONE THAT FAILS SILENTLY.
   *
   * `FILE_SPECS`' delimiters decide what a "block" is, and the memory files they
   * are pointed at arrive from the Gravito scaffold. If the two drift apart the
   * tool does not error: the whole file becomes one preamble, zero blocks are
   * found, nothing is archived, and the run REPORTS A NO-OP AT EXIT 0. A file
   * that never rotates is exactly the state this layer exists to prevent, and on
   * STDOUT it still reads exactly like "already rotated". What distinguishes the
   * two is a stderr warning, driven by section 9b below; this test is the other
   * half — it asserts the condition never arises in THIS repo in the first
   * place, which a warning nobody reads would not.
   *
   * Measured before this port: the reference deployment's `current_state`
   * delimiter (`/^> \*\*(LATEST|PRIOR)/`) found 0 blocks in a scaffolded
   * `current_state.md`, while `^## ` finds every section. So this is a real
   * defect class, not a hypothetical one.
   *
   * A MISSING FILE IS NOT A FAILURE — a repo may not have scaffolded that path
   * yet — but a file that EXISTS and yields zero blocks is.
   */
  test("every rotating file that exists yields blocks under its own delimiter (no silent no-op)", () => {
    /*
     * THE LOCALS BELOW ARE DELIBERATELY ODDLY NAMED (`memFull`, `memBlocks`).
     * `rotate-memory.rootscan.test.mjs` builds its real-root alias set from
     * `const/let/var` declarations across THIS WHOLE FILE by name, so binding a
     * common identifier (`src`, `full`, `blocks`) to an expression derived from
     * `REPO_ROOT` makes every other use of that name in the file read as a real
     * root, and the scan reports 75 false positives. Measured, not guessed.
     */
    const blind = [];
    let present = 0;
    for (const [name, rel] of REAL_TARGETS) {
      const memFull = path.join(REPO_ROOT, rel);
      if (!fs.existsSync(memFull)) continue;
      present++;
      const memBlocks = segmentFile(
        fs.readFileSync(memFull).toString("latin1"),
        FILE_SPECS[name]
      ).filter((s) => s.kind === "block").length;
      if (memBlocks === 0) {
        blind.push(`${rel} (delimiter ${String(FILE_SPECS[name].blockDelimiter)})`);
      }
    }
    assert.deepEqual(
      blind,
      [],
      `these memory files parse to ZERO blocks, so rotation is a silent no-op on them: ` +
        `${JSON.stringify(blind)}. Either the file uses a block convention this spec's ` +
        `delimiter does not match, or the delimiter was narrowed. Fix FILE_SPECS in ` +
        `rotate-memory.mjs — do not "fix" the memory file to suit the tool.`
    );
    assert.ok(present > 0, "no rotating memory file exists at all — this check ran vacuously");
  });

  /**
   * ...and the same check over the SHIPPED SCAFFOLD TEMPLATE, so the coupling is
   * pinned against what a customer actually receives rather than against
   * whatever this repo's live memory happens to look like today.
   */
  test("...and the shipped standing-gates template is NOT parsed as a rotating file", () => {
    const tpl = path.join(HERE, "templates", "standing_gates.md");
    assert.ok(fs.existsSync(tpl), "the standing-gates template is not shipped beside the tool");
    for (const spec of Object.values(FILE_SPECS)) {
      assert.ok(
        !spec.path.endsWith("standing_gates.md"),
        `${spec.path} would put the never-rotated authority in the rotation set`
      );
    }
    const tplSrc = fs.readFileSync(tpl, "utf8");
    assert.match(tplSrc, /THIS FILE IS NEVER ROTATED/, "the template lost its contract header");
    assert.match(tplSrc, /HARD STOP/, "the template states no hard stop, so the mirror check is vacuous");
  });
});


/* ================================================================== */
/* 9b. A DELIMITER THAT MATCHED NOTHING IS NOT "already rotated"        */
/* ================================================================== */

/**
 * THE REPORT USED TO COLLAPSE THREE DIFFERENT STATES INTO ONE LINE.
 *
 * `blocks: 0 total` plus `would archive: nothing — already rotated (no-op)` was
 * printed, byte for byte identically, by all of:
 *
 *   (a) A FILE WHOSE DELIMITER MATCHED NOTHING. Content is there, the whole file
 *       became one preamble, and the file will never rotate. This is the
 *       hazard — the failure mode the FILE_SPECS comment calls "the dangerous
 *       direction", and the exact shape the port's one load-bearing adaptation
 *       (`/^> \*\*(LATEST|PRIOR)/` → `/^## /`) exists to avoid.
 *   (b) AN EMPTY (or whitespace-only) FILE. Benign: a scaffolded repo that has
 *       not written a block yet legitimately parses to zero.
 *   (c) A FILE THAT PARSED FINE AND HAS NOTHING OLD ENOUGH TO ARCHIVE. Benign,
 *       and the literal meaning of "already rotated".
 *
 * A reader cannot act on a message that means three things, and the one it most
 * naturally reads as — "fine, nothing to do" — is the wrong reading for (a).
 *
 * WHAT IS PINNED HERE, BOTH DIRECTIONS IN ONE RUN: (a) raises a named warning on
 * STDERR, and (b) does not. STDOUT is deliberately unchanged, and the exit code
 * stays 0 in both: (b) and (c) are legitimate, an empty scaffold must not fail a
 * run, and this tool's whole discipline is that it does not decide what a
 * customer's memory format ought to be. The warning names the file and the
 * delimiter that matched nothing, which is what makes it actionable.
 */
describe("a zero-block file WITH CONTENT is warned about, not reported as a no-op", () => {
  /*
   * The reference deployment's `current_state.md` convention, which is exactly
   * what `^## ` does NOT match — so this fixture is the real defect shape, not
   * an invented one.
   */
  const WRONG_DELIMITER = `# Current State

> The one-screen answer to "where is this project right now".

> **LATEST (2026-07-30) — block 1** — headline one
> body line for block 1
>
> ---

> **PRIOR (2026-07-29) — block 2** — headline two
> body line for block 2
>
> ---
`;

  test("stderr names the file and the delimiter — and stays silent for an empty one", () => {
    const root = makeRoot("delimiter-matched-nothing", {
      current_state: WRONG_DELIMITER, // (a) content, zero blocks -> HAZARD
      residue: "", // (b) genuinely empty -> benign
      active_packet: "\n\n   \n\t\n", // (b) whitespace only -> benign
    });

    const res = run(["--root", root, "--keep", "10"]);

    // Exit code is unchanged: this is a warning, not a failure.
    assert.equal(res.status, 0, res.all);

    // All three parse to zero blocks, so all three take the same stdout branch.
    const json = runJson(["--root", root, "--keep", "10"]).json;
    assert.ok(json, "no JSON report");
    for (const r of json.results) {
      assert.equal(r.totalBlocks, 0, `${r.name} did not parse to zero blocks`);
      assert.equal(r.noop, true, `${r.name} is not a no-op`);
    }
    assert.equal(
      countOf(res.stdout, "already rotated (no-op)"),
      3,
      "stdout is expected to be unchanged — all three still print the no-op line"
    );

    // DIRECTION 1: the hazard is named on stderr, with the delimiter.
    assert.match(
      res.stderr,
      /build-os\/memory\/current_state\.md/,
      `the wrong-delimiter file was not named on stderr. stderr=${JSON.stringify(res.stderr)}`
    );
    assert.match(
      res.stderr,
      /\/\^## \//,
      `the warning does not quote the delimiter that matched nothing. stderr=${JSON.stringify(res.stderr)}`
    );
    assert.ok(
      /warn/i.test(res.stderr),
      `the stderr line does not read as a warning. stderr=${JSON.stringify(res.stderr)}`
    );

    // DIRECTION 2: the benign files are NOT warned about. This is the half that
    // makes the warning worth having — one that fires on every empty scaffold
    // is noise, and noise is ignored.
    assert.ok(
      !res.stderr.includes("build-os/memory/residue.md"),
      `an EMPTY file was warned about; the warning fires on the wrong condition. ` +
        `stderr=${JSON.stringify(res.stderr)}`
    );
    assert.ok(
      !res.stderr.includes("build-os/packets/active_packet.md"),
      `a WHITESPACE-ONLY file was warned about; "has content" must mean a ` +
        `non-whitespace byte. stderr=${JSON.stringify(res.stderr)}`
    );
    assert.equal(
      countOf(res.stderr, "matched NOTHING"),
      1,
      `expected exactly one warning, for the one file that has content. ` +
        `stderr=${JSON.stringify(res.stderr)}`
    );

    // ...and a fully legitimate tree — case (c), parsed fine, nothing old
    // enough to archive — stays silent too.
    const clean = makeRoot("delimiter-fine");
    const quiet = run(["--root", clean, "--keep", "1000"]);
    assert.equal(quiet.status, 0, quiet.all);
    assert.equal(
      quiet.stderr,
      "",
      `a parsed-fine no-op wrote to stderr: ${JSON.stringify(quiet.stderr)}`
    );
  });
});


/* ================================================================== */
/* 10. THE PROCESS-WIDE REAL-MEMORY TRIPWIRE                            */
/* ================================================================== */

/**
 * THE TRIPWIRE ITSELF IS NOT HERE ANY MORE. It lives in
 * `real-memory-tripwire.mjs`, is armed by the first import of this file, and is
 * armed identically by every other `*.test.mjs` in this directory.
 *
 * WHY IT MOVED. An earlier round — in the reference deployment this layer was
 * built in, before the port — put it at the bottom of this file. That left
 * `rotate-memory.rootscan.test.mjs` — which binds the real repo root and holds a
 * filesystem binding — with no tripwire at all. Run under the command printed in
 * its own header, one appended line in that file destroyed that repo's live
 * Build OS memory at 0 fail / exit 0: a fully green run. The machinery built to
 * prove containment was itself the uncontained thing, because it landed outside
 * the reach of the check that would have caught it.
 *
 * WHAT IS STRUCTURAL NOW, stated exactly:
 *   - Under the sanctioned command the tripwire is a `--import` PRELOAD, so it
 *     is armed before the first line of any test file's module graph — at any
 *     column, and whether or not that file has imports.
 *   - Whichever file you run, and whichever subset, it baselines the real tree
 *     and fails the run at exit — via `process.exitCode`, which the test runner
 *     reports as a failed file — if any of the four watched real memory files (the
 *     three that rotate, plus the never-rotated `standing_gates.md`) or the
 *     real archive directory moved, whatever moved it.
 *   - Its coverage rule is enforced from EVERY file, at ANY column: a
 *     `*.test.mjs` here that does not request it first turns every other file in
 *     the directory red, by name. Run as a preload, that happens before the
 *     offending file executes.
 *
 * WHAT IS NOT, and what covers it instead: an exit handler is last-registered-
 * wins, so a hostile test body can unset `process.exitCode` or remove this
 * module's listener, and under a bare `node --test` that leaves a damaged tree
 * at exit 0. The shell wrapper's before/after fingerprint is what catches that,
 * and it is the wrapper — not this module — that says so in its own header.
 *
 * The tests below prove the tripwire DISCRIMINATES. A guard that never fires and
 * a guard that cannot fire look identical from a green run, and this suite has
 * shipped the second kind before.
 */
describe("the real-memory tripwire", () => {
  test("reports no drift right now", () => {
    assert.deepEqual(currentDrift(), [], "the real tree drifted during this run");
  });

  test("...and is not vacuously empty: every kind of drift is reported", () => {
    // a changed file
    const wrongFiles = Object.fromEntries(
      Object.entries(BASELINE_FILES).map(([rel, v]) => [rel, { ...v, hash: "0".repeat(64) }])
    );
    const changed = driftAgainst(wrongFiles, BASELINE_ARCHIVE);
    assert.equal(changed.length, REAL_MEMORY_FILES.length, changed.join("; "));
    for (const d of changed) assert.match(d, /CONTENT CHANGED/);

    // the archive appearing (or, after a real rotation, disappearing)
    const wrongArchive = { exists: !BASELINE_ARCHIVE.exists, entries: {} };
    const arch = driftAgainst(BASELINE_FILES, wrongArchive);
    assert.equal(arch.length, 1, arch.join("; "));
    assert.match(arch[0], /build-os\/memory\/archive\/: (CREATED BY THIS RUN|REMOVED)/);

    // the archive keeping its existence but changing content
    const archiveWithFile = {
      exists: BASELINE_ARCHIVE.exists,
      entries: { ...BASELINE_ARCHIVE.entries, "INDEX.md": { size: 1, hash: "x" } },
    };
    const archContent = driftAgainst(BASELINE_FILES, archiveWithFile);
    assert.deepEqual(archContent, ["build-os/memory/archive/: CONTENTS CHANGED"]);
  });

  test("a file that DISAPPEARS is reported as missing, not skipped", () => {
    /*
     * The failure mode being excluded: a snapshot that throws on a missing path,
     * or one that iterates only over what it can still see. Either turns total
     * destruction into silence. Driven through the injected `now`, so no real
     * file has to be moved to prove it.
     */
    const gone = Object.fromEntries(
      Object.keys(BASELINE_FILES).map((rel) => [rel, { present: false, size: 0, hash: "" }])
    );
    const drift = driftAgainst(BASELINE_FILES, BASELINE_ARCHIVE, gone, BASELINE_ARCHIVE);
    assert.equal(drift.length, REAL_MEMORY_FILES.length, drift.join("; "));
    for (const d of drift) assert.match(d, /NO LONGER PRESENT/);

    // a baselined path that never existed is still named, not silently dropped
    const phantom = { "build-os/memory/does-not-exist.md": { present: true, size: 9, hash: "z" } };
    assert.deepEqual(driftAgainst(phantom, BASELINE_ARCHIVE), [
      "build-os/memory/does-not-exist.md: NO LONGER PRESENT (was 9 B)",
    ]);

    // ...and a file APPEARING where the baseline had none is reported too
    const appeared = driftAgainst(
      { "x.md": { present: false, size: 0, hash: "" } },
      BASELINE_ARCHIVE,
      { "x.md": { present: true, size: 4, hash: "q" } },
      BASELINE_ARCHIVE
    );
    assert.deepEqual(appeared, ["x.md: CREATED BY THIS RUN (4 B)"]);
  });

  test("the tripwire watches the four real memory files, by real path", () => {
    /*
     * THE FOURTH IS `standing_gates.md`, AND IT IS NOT ROTATED. The first three
     * are the rotation set; the fourth is the never-rotated authority for hard
     * stops, which until this round was watched by nothing at all — absent from
     * this list and from the wrapper's `WATCHED`, so a test body that rewrote it
     * exited 0 in silence. That the rotation TOOL cannot touch it is a separate
     * property, pinned in rotate-memory.rootscan.test.mjs against
     * `ROTATED_MEMORY_FILES`; the two lists are deliberately different now.
     */
    assert.deepEqual(REAL_MEMORY_FILES, [
      "build-os/memory/current_state.md",
      "build-os/memory/residue.md",
      "build-os/packets/active_packet.md",
      "build-os/memory/standing_gates.md",
    ]);
    /*
     * The baseline is of files that actually EXIST — not of an empty set, which
     * is what a hollow tripwire looks like from a green run.
     *
     * THE SIZE FLOOR IS 1 BYTE, NOT 1000. The reference deployment's floor was
     * 1000 B, which was really an assertion that its memory was large; a freshly
     * scaffolded repo has an `active_packet.md` of ~950 B and would fail it for
     * being new. What this check is actually for is a file that exists but is
     * EMPTY — the shape whose hash never changes and whose drift can therefore
     * never be detected — and that is what is pinned.
     */
    const live = snapshotFiles();
    for (const rel of REAL_MEMORY_FILES) {
      assert.equal(live[rel].present, true, `${rel} is not present — the baseline is hollow`);
      assert.ok(
        live[rel].size > 0,
        `${rel} is EMPTY, so its baseline hash is the hash of nothing and this watch entry ` +
          `cannot report meaningful drift`
      );
    }
    assert.equal(REAL_ARCHIVE_REL, "build-os/memory/archive");
  });

  /*
   * THE COVERAGE RULE IS WHAT KEEPS THE NEXT FILE FROM BEING THE HOLE.
   *
   * It ran at import, over the real directory, before any of this executed — if
   * it had found anything, this file would not have loaded. These tests prove it
   * can find something: an uncovered file, and a covered-but-late one.
   */
  test("coverage: every *.test.mjs here arms the tripwire first, AS THE MASK READS IT", () => {
    /*
     * READ THE TITLE LITERALLY. This proves how the imports in this directory
     * are SPELLED, as a heuristic lexer reads them — not that the tripwire is
     * armed. A file can be written whose real first import the mask cannot see
     * (pinned in the maskNonCode describe below), and this would still be empty.
     * What actually arms the tripwire is the `--import` preload in run-tests.sh.
     */
    assert.ok(SUITE_FILES.length >= 2, `only ${SUITE_FILES.length} suite file(s) were found`);
    assert.ok(SUITE_FILES.includes("rotate-memory.test.mjs"));
    assert.ok(SUITE_FILES.includes("rotate-memory.rootscan.test.mjs"));

    const real = SUITE_FILES.map((rel) => [rel, fs.readFileSync(path.join(HERE, rel), "utf8")]);
    assert.deepEqual(coverageFindings(real), []);
  });

  test("...and the coverage rule reports a file that does not arm it, or arms it late", () => {
    const armed = `import "${TRIPWIRE_SPECIFIER}";\nimport { test } from "node:test";\n`;
    const bare = `import { test } from "node:test";\nimport fs from "node:fs";\n`;
    const late = `import { test } from "node:test";\nimport "${TRIPWIRE_SPECIFIER}";\n`;
    const multiline = `import {\n  currentDrift,\n} from "${TRIPWIRE_SPECIFIER}";\nimport fs from "node:fs";\n`;

    assert.deepEqual(coverageFindings([["ok.test.mjs", armed]]), []);
    assert.deepEqual(coverageFindings([["ok2.test.mjs", multiline]]), []);

    const missing = coverageFindings([["new.test.mjs", bare]]);
    assert.equal(missing.length, 1, missing.join("; "));
    assert.match(missing[0], /new\.test\.mjs does not import/);

    const outOfOrder = coverageFindings([["late.test.mjs", late]]);
    assert.equal(outOfOrder.length, 1, outOfOrder.join("; "));
    assert.match(outOfOrder[0], /but as import #2 of 2/);

    // an empty directory must not pass vacuously
    assert.equal(coverageFindings([]).length, 1);
  });

  /*
   * THE FOUR SHAPES THAT DEFEATED THE ANCHORED SCAN.
   *
   * The scan used to require an import to begin at column 0, so that block-
   * comment prose (`* import "x"`) could not be read as an import. That made
   * every import at any other column INVISIBLE to it — while the ESM loader
   * evaluated it in source order regardless. One leading space was enough:
   * `coverageFindings` returned [] for a file whose first-evaluated module was a
   * payload, and the tripwire baselined an already-damaged tree.
   *
   * Each shape below runs BEFORE the tripwire import that follows it. Each must
   * be reported as a late arm, not silently accepted.
   */
  test("...and the scan sees a module request at ANY column, not only column 0", () => {
    const shapes = {
      "leading-space": `  import "./payload.mjs";\nimport "${TRIPWIRE_SPECIFIER}";\n`,
      "leading-tab": `\timport "./payload.mjs";\nimport "${TRIPWIRE_SPECIFIER}";\n`,
      "after-semicolon": `;import "./payload.mjs";\nimport "${TRIPWIRE_SPECIFIER}";\n`,
      "after-block-comment": `/*x*/import "./payload.mjs";\nimport "${TRIPWIRE_SPECIFIER}";\n`,
    };
    for (const [name, src] of Object.entries(shapes)) {
      const found = coverageFindings([[`${name}.test.mjs`, src]]);
      assert.equal(found.length, 1, `${name}: ${JSON.stringify(found)}`);
      assert.match(found[0], /but as import #2 of 2/, name);
    }
  });

  test("...and a re-export `from` clause counts: it evaluates the module too", () => {
    const src = `export { x } from "./payload.mjs";\nimport "${TRIPWIRE_SPECIFIER}";\n`;
    const found = coverageFindings([["reexport.test.mjs", src]]);
    assert.equal(found.length, 1, JSON.stringify(found));
    assert.match(found[0], /but as import #2 of 2/);
  });

  /*
   * ...AND THE REASON THE ANCHOR EXISTED IS STILL HANDLED — by masking, which is
   * what makes dropping the anchor safe. A mention of the specifier in prose or
   * in a string is NOT an arm; a mention of some other import in prose is NOT a
   * module request. Getting either of these wrong is a FALSE NEGATIVE, the class
   * this whole section exists to exclude.
   */
  test("...and a comment or string that MENTIONS an import is not one", () => {
    const armed = `import "${TRIPWIRE_SPECIFIER}";\nimport { test } from "node:test";\n`;

    // prose naming an import does not create one
    const prose = `/**\n * import "./payload.mjs";\n */\n${armed}`;
    assert.deepEqual(coverageFindings([["prose.test.mjs", prose]]), []);

    // a line comment likewise
    const lineComment = `// import "./payload.mjs";\n${armed}`;
    assert.deepEqual(coverageFindings([["line.test.mjs", lineComment]]), []);

    // a string literal likewise
    const inString = `${armed}const s = 'import "./payload.mjs";';\n`;
    assert.deepEqual(coverageFindings([["string.test.mjs", inString]]), []);

    // and prose naming THE TRIPWIRE does not arm a file that never imports it
    const fake = `/**\n * import "${TRIPWIRE_SPECIFIER}";\n */\nimport { test } from "node:test";\n`;
    const found = coverageFindings([["fake.test.mjs", fake]]);
    assert.equal(found.length, 1, JSON.stringify(found));
    assert.match(found[0], /does not import/);
  });

  /*
   * NON-VACUITY OF THE MASK ON THE REAL FILES. A masker that mis-lexes a regex
   * literal or a template can swallow real code and hide a real import — the
   * exact failure the anchor was covering for. The anchored scan had no false
   * negatives for column-0 imports, so it is usable as a lower bound: every
   * specifier it found must still be found.
   */
  test("...and the masked scan is a SUPERSET of the anchored scan on the real files", () => {
    const ANCHORED = /^import\s+(?:[^;'"]*?\bfrom\s*)?(["'])([^"'\n]+)\1/gm;
    for (const rel of SUITE_FILES) {
      const src = fs.readFileSync(path.join(HERE, rel), "utf8");
      const anchored = [...src.matchAll(ANCHORED)].map((m) => m[2]);
      const now = moduleRequestSpecifiers(src);
      assert.ok(anchored.length > 0, `${rel}: the lower bound is empty — it proves nothing`);
      for (const spec of anchored) {
        assert.ok(now.includes(spec), `${rel}: the masked scan lost the import of ${spec}`);
      }
      assert.equal(now[0], TRIPWIRE_SPECIFIER, `${rel}: first module request is not the tripwire`);
    }
  });
});

/* ================================================================== */
/* 10b. THE MASK THE COVERAGE SCAN IS BUILT ON                          */
/* ================================================================== */

/*
 * `maskNonCode` is what replaced the `^` anchor. It returns a string of the SAME
 * LENGTH as its input in which comment bodies, string bodies and template bodies
 * are spaces, so a scan can find the `import` keyword in code context at any
 * column and read the specifier back out of the original source by offset.
 *
 * Its two failure directions are not symmetric:
 *   - masking too little  -> a false POSITIVE: prose read as an import. Loud.
 *   - masking too much    -> a false NEGATIVE: a real import hidden. Silent, and
 *     the whole reason this round exists.
 * The tests below drive both, and the same-length property that makes offsets
 * usable at all.
 */
describe("maskNonCode", () => {
  test("is length- and newline-preserving", () => {
    for (const src of [
      `import "a";\n/* b\n c */\nconst s = "d";\n`,
      "`t${1}t`\n// x\n",
      "const re = /[\"']/g;\nimport 'x';\n",
    ]) {
      const masked = maskNonCode(src);
      assert.equal(masked.length, src.length, JSON.stringify(src));
      assert.equal(masked.split("\n").length, src.split("\n").length, JSON.stringify(src));
    }
  });

  test("blanks comment bodies, string bodies and template bodies in each shape below", () => {
    /*
     * THE TITLE USED TO END "— and nothing else". That was false and is now
     * pinned false by the residual test at the foot of this describe: in the
     * division-position-regex shape this function blanks real code, including a
     * real import. What is asserted here is exactly what is written here — six
     * shapes, byte for byte — and nothing about the general case.
     */
    assert.equal(maskNonCode(`a// b\nc`), `a    \nc`);
    assert.equal(maskNonCode(`a/* b */c`), `a       c`);
    assert.equal(maskNonCode(`a"bc"d`), `a"  "d`);
    assert.equal(maskNonCode("a`bc`d"), "a`  `d");
    assert.equal(maskNonCode(`a'b\\'c'd`), `a'    'd`);
    assert.equal(maskNonCode("a`b\nc`d"), "a` \n `d");
  });

  test("a quote inside an OPERAND-POSITION regex literal does not open a string", () => {
    /*
     * THE DESYNC THAT WOULD HIDE AN IMPORT. `/["']/` holds one double and one
     * single quote. A masker that does not know it is a regex opens a string at
     * the first of them and blanks everything up to the next one — swallowing
     * whatever code lies between, imports included.
     *
     * OPERAND POSITION IS THE WHOLE SCOPE OF THIS TEST, and the title used to
     * omit it. Here the `/` follows `=`, which the heuristic reads as a regex
     * opener. In DIVISION position — after `)` or `]` or a plain identifier —
     * the same literal is scanned as code and its quotes are live. That is not a
     * hypothetical difference: it is the residual pinned at the foot of this
     * describe.
     */
    const src = `const re = /["']/g;\nimport "./x.mjs";\n`;
    const masked = maskNonCode(src);
    assert.equal(masked, `const re = /    /g;\nimport "       ";\n`);
    assert.deepEqual(moduleRequestSpecifiers(src), ["./x.mjs"]);
  });

  test("a division is not read as a regex", () => {
    // `a / b` then `/ c` — read as a regex, the span between the two slashes
    // would be blanked, and with it any code written there
    const src = `const q = a / b / c;\nimport "./x.mjs";\n`;
    assert.equal(maskNonCode(src).split("\n")[0], `const q = a / b / c;`);
    assert.deepEqual(moduleRequestSpecifiers(src), ["./x.mjs"]);
  });

  test("a regex after a keyword is still a regex", () => {
    const src = `function f(){ return /["']/.test(s); }\nimport "./x.mjs";\n`;
    assert.deepEqual(moduleRequestSpecifiers(src), ["./x.mjs"]);
  });

  test("an apostrophe inside a comment does not open a string", () => {
    const src = `// don't\nimport "./x.mjs";\n`;
    assert.deepEqual(moduleRequestSpecifiers(src), ["./x.mjs"]);
    const block = `/* it's fine */\nimport "./x.mjs";\n`;
    assert.deepEqual(moduleRequestSpecifiers(block), ["./x.mjs"]);
  });

  test("a comment delimiter inside a string does not open a comment", () => {
    const src = `const u = "http://x/*y";\nimport "./x.mjs";\n`;
    assert.deepEqual(moduleRequestSpecifiers(src), ["./x.mjs"]);
  });

  test("an unterminated string or block comment throws instead of masking on", () => {
    /*
     * A LOUD FAILURE IS THE POINT. Silent recovery from a desync is exactly how a
     * masker hides an import. Anything the lexer cannot close is a hard stop.
     */
    assert.throws(() => maskNonCode(`const s = "abc\n`), /unterminated/i);
    assert.throws(() => maskNonCode(`/* abc\n`), /unterminated/i);
    assert.throws(() => maskNonCode("const t = `abc\n"), /unterminated/i);
  });

  test("it survives the real sources in this directory", () => {
    for (const rel of [...SUITE_FILES, "real-memory-tripwire.mjs", "source-scan.mjs", "rotate-memory.mjs"]) {
      const src = fs.readFileSync(path.join(HERE, rel), "utf8");
      const masked = maskNonCode(src);
      assert.equal(masked.length, src.length, rel);
      assert.equal(masked.split("\n").length, src.split("\n").length, rel);
    }
  });

  /*
   * THE RESIDUAL, PINNED AS A FACT RATHER THAN LEFT AS A CAVEAT.
   *
   * This test asserts the CURRENT, DEFEATED behaviour on purpose. Three rounds
   * of hardening this mask have each been beaten — exempt regions that hosted
   * live code, a `^` anchor beaten by one leading space, and now the lexer — so
   * the decision is to stop hardening it and to write the hole down where it
   * cannot be forgotten. If someone later makes the mask see this shape, THIS
   * TEST GOES RED, which is the correct outcome: it is the notification that the
   * documented residual moved, and the headers that name it must move with it.
   *
   * What it does NOT mean: that a file like this is safe to run. Under the
   * sanctioned command the preload has already armed the tripwire and
   * `run-tests.sh` fingerprints the tree either side of node, so the run cannot
   * report success. Under a bare `node --test` there is nothing at all.
   */
  test("...and a division-position regex hides a real import from the scan — residual, pinned", () => {
    const evasion =
      `if (a) /'/.test(b); import "./payload.mjs"; if (c) /'/.test(d);\n` +
      `import "${TRIPWIRE_SPECIFIER}";\n`;

    // the import is really there, spelled in the ordinary way
    assert.ok(evasion.includes(`import "./payload.mjs";`), "the fixture lost its payload import");

    // ...and the scan does not see it, because the mask blanked the span
    assert.deepEqual(
      moduleRequestSpecifiers(evasion),
      [TRIPWIRE_SPECIFIER],
      "the mask now sees the division-position payload — update the residual named in " +
        "source-scan.mjs, real-memory-tripwire.mjs and run-tests.sh before deleting this test"
    );
    assert.deepEqual(
      coverageFindings([["evasion.test.mjs", evasion]]),
      [],
      "the coverage scan now reports this shape — same instruction as above"
    );

    // nothing throws: the two mis-read apostrophes balance
    const masked = maskNonCode(evasion);
    assert.equal(masked.length, evasion.length);
    assert.ok(
      masked.includes("payload") === false,
      "the payload specifier must be inside the blanked span for this to be the residual"
    );
  });
});

/* ================================================================== */
/* 10c. THE LINE THAT TURNS DETECTION INTO A FAILED RUN                 */
/* ================================================================== */

/*
 * WHY THIS SECTION EXISTS, AND WHY IT IS SEPARATE FROM EVERYTHING ABOVE.
 *
 * The tripwire has two halves and they had very different amounts of proof:
 *
 *   DETECTION — snapshot, diff, report. Driven from every direction above:
 *     CONTENT CHANGED, CREATED, NO LONGER PRESENT, archive created, archive
 *     contents changed, and an injected `now` for each.
 *   ENFORCEMENT — the single line `process.exitCode = 1` in the exit handler.
 *     NOTHING drove it. Measured in the reference deployment at commit
 *     `cb2bb7d`, before this section existed, with that one line removed and
 *     nothing else changed: the whole suite stayed GREEN — 0 fail, wrapper
 *     exit 0. (Its pass count was that repo's, on that day, and is not quoted.)
 *     The stderr report is unchanged, so the damage is still described in full —
 *     and the run is still green.
 *
 * That asymmetry is the defect this section closes. It is the same asymmetry the
 * wrapper's `BEFORE != AFTER` comparison had, and that one is pinned statically
 * in rotate-memory.rootscan.test.mjs.
 *
 * THE TWO ARE MUTUALLY REDUNDANT, MEASURED. On a clone, with a planted suite
 * file that damages a real memory file from an `exit` handler and then does
 * `removeAllListeners("exit")` and `process.exitCode = 0`:
 *   - both lines present:            wrapper exit 1, outer fingerprint fired.
 *   - `process.exitCode = 1` gone:   wrapper exit 1, outer fingerprint fired.
 *   - the comparison gone:           wrapper exit 1, from node's own status.
 * So no single edit to either line yields green-with-damage, and these two pins
 * are what keeps that true. Neither is a defence against BOTH being edited, and
 * neither prevents the write.
 *
 * HOW IT IS DRIVEN WITHOUT GOING NEAR THE REAL TREE. The tripwire computes its
 * repo root from ITS OWN LOCATION, so a copy of it placed at
 * `<scratch>/build-os/maintenance/` watches `<scratch>`, not this repo. The
 * sandbox below is a scratch root of exactly that shape; the driver damages a
 * file inside it and exits normally. Every process is started by the same gated
 * wrapper as every other child in this file, with an explicit scratch `--root`.
 */

const TRIPWIRE_MJS = path.join(HERE, "real-memory-tripwire.mjs");
const SCANLIB_MJS = path.join(HERE, "source-scan.mjs");

/**
 * The driver, written into the sandbox and run there.
 *
 * It imports the sandbox's COPY of the tripwire first — so the copy baselines
 * the sandbox — then damages one watched file and returns normally. Its own exit
 * code is 0; anything else can only have come from the tripwire's exit handler.
 *
 * Assembled from a list rather than written as one template so that no line of
 * it begins at column 0 with the `import` keyword: the coverage scan's "the
 * masked scan is a SUPERSET of the anchored scan" test reads THIS file's raw
 * text, and a column-0 import inside a string would be a false lower bound.
 */
const driverSrcFor = (victimRel) =>
  [
    `import "./build-os/maintenance/real-memory-tripwire.mjs";`,
    `import fs from "node:fs";`,
    `import path from "node:path";`,
    `const root = process.argv[process.argv.indexOf("--root") + 1];`,
    `fs.writeFileSync(path.join(root, ${JSON.stringify(victimRel)}), "DAMAGED BY THE DRIVER\\n");`,
    ``,
  ].join("\n");

const TRIPWIRE_DRIVER_SRC = driverSrcFor("build-os/memory/residue.md");

const TRIPWIRE_DAMAGE = "DAMAGED BY THE DRIVER\n";

/**
 * A scratch repo carrying a (possibly mutated) copy of the tripwire, plus a
 * driver that damages it.
 *
 * `edits` uses the same anchor discipline as `mutatedTool`: each anchor must
 * appear EXACTLY ONCE in the real tripwire, so a refactor that moves the line
 * these tests are about fails loudly instead of silently testing nothing.
 */
function tripwireSandbox(label, edits = [], driverSrc = TRIPWIRE_DRIVER_SRC) {
  const root = makeRoot(label);
  const maint = path.join(root, "build-os", "maintenance");
  fs.mkdirSync(maint, { recursive: true });

  /*
   * The sandbox carries a `standing_gates.md` too, because the tripwire now
   * watches it. It is NOT written by `makeRoot`: the gates file is outside the
   * rotation set, so putting it in the rotation fixtures would misrepresent what
   * the tool reads. Without it here the fourth baseline entry would simply be
   * `{ present: false }` — the tripwire tolerates a missing file by design — and
   * the "damage the gates file" driver below would have nothing to damage.
   */
  writeFixture(root, STANDING_GATES_REL, `# STANDING GATES (sandbox fixture)\n\nA HARD STOP.\n`);

  const original = fs.readFileSync(TRIPWIRE_MJS, "utf8");
  let src = original;
  for (const [from, to] of edits) {
    assert.equal(
      src.split(from).length - 1,
      1,
      `mutation anchor must appear exactly once in real-memory-tripwire.mjs: ${JSON.stringify(from)}`
    );
    src = src.replace(from, to);
  }
  if (edits.length > 0) assert.notEqual(src, original, "mutation produced no change");

  fs.writeFileSync(path.join(maint, "real-memory-tripwire.mjs"), src, "utf8");
  fs.copyFileSync(SCANLIB_MJS, path.join(maint, "source-scan.mjs"));
  // the tripwire's coverage scan refuses to pass vacuously on an empty
  // directory, so the sandbox carries one properly-armed suite file
  fs.writeFileSync(
    path.join(maint, "placeholder.test.mjs"),
    `import "${TRIPWIRE_SPECIFIER}";\n`,
    "utf8"
  );

  const driver = path.join(root, "drive-tripwire.mjs");
  fs.writeFileSync(driver, driverSrc, "utf8");
  return { root, driver, victim: path.join(root, RETAINED.residue) };
}

describe("the tripwire's ENFORCEMENT line, `process.exitCode = 1`", () => {
  test("a sandbox copy of the tripwire reports damage AND exits 1", () => {
    const sb = tripwireSandbox("tripwire-enforce");
    const before = fs.readFileSync(sb.victim, "utf8");

    const res = runNodeJson(sb.driver, ["--root", sb.root]);

    assert.match(
      res.all,
      /REAL BUILD OS MEMORY WAS MUTATED BY THIS TEST RUN/,
      `the tripwire did not report the damage: ${res.all}`
    );
    assert.match(res.all, /residue\.md: CONTENT CHANGED/);
    assert.equal(
      res.status,
      1,
      `the tripwire reported damage but the run still exited ${res.status}. ` +
        `Detection without enforcement is a green run with a destroyed tree.`
    );
    // ...and the damage really happened: this is not a run that failed early
    assert.notEqual(fs.readFileSync(sb.victim, "utf8"), before);
    assert.equal(fs.readFileSync(sb.victim, "utf8"), TRIPWIRE_DAMAGE);
  });

  test("...and with that ONE line removed the same run reports the same damage at exit 0", () => {
    /*
     * NON-VACUITY, and the exact measurement that made this section necessary:
     * the report is unchanged, the damage is unchanged, and the run is green.
     * Every other assertion in this file about the tripwire is satisfied by this
     * mutant — which is why "the tripwire reports it" was never the guarantee.
     */
    const sb = tripwireSandbox("tripwire-unenforced", [
      ["\n  process.exitCode = 1;\n", "\n  /* enforcement deliberately removed */\n"],
    ]);

    const res = runNodeJson(sb.driver, ["--root", sb.root]);

    assert.match(res.all, /REAL BUILD OS MEMORY WAS MUTATED BY THIS TEST RUN/);
    assert.match(res.all, /residue\.md: CONTENT CHANGED/);
    assert.equal(
      res.status,
      0,
      `without the enforcement line the run must be observed going green with a ` +
        `damaged tree — got ${res.status}: ${res.all}`
    );
    assert.equal(fs.readFileSync(sb.victim, "utf8"), TRIPWIRE_DAMAGE);
  });

  test("...and the never-rotated `standing_gates.md` is enforced identically", () => {
    /*
     * THE FILE THAT NOTHING WATCHED. `standing_gates.md` is the authority for
     * hard stops and is deliberately outside the rotation tool's `FILE_SPECS`,
     * which protects it from THE TOOL and from nothing else: before this round it
     * was absent from the tripwire's watch list and from the wrapper's `WATCHED`,
     * so a test body that rewrote it was reported by neither mechanism.
     *
     * This is the executed half of the fix. The static half — that both lists name
     * the path — is pinned above and in rotate-memory.rootscan.test.mjs; static
     * pins cannot show that the drift machinery actually fires on the new entry.
     */
    const sb = tripwireSandbox(
      "tripwire-gates",
      [],
      driverSrcFor(STANDING_GATES_REL)
    );
    const gates = path.join(sb.root, STANDING_GATES_REL);
    const before = fs.readFileSync(gates, "utf8");

    const res = runNodeJson(sb.driver, ["--root", sb.root]);

    assert.match(
      res.all,
      /standing_gates\.md: CONTENT CHANGED/,
      `the tripwire did not name the gates file in its drift report: ${res.all}`
    );
    assert.equal(
      res.status,
      1,
      `the gates file was rewritten and the run still exited ${res.status}`
    );
    // the rotating files are untouched, so this is the fourth entry firing alone
    assert.doesNotMatch(res.all, /residue\.md: CONTENT CHANGED/);
    assert.notEqual(fs.readFileSync(gates, "utf8"), before);
    assert.equal(fs.readFileSync(gates, "utf8"), TRIPWIRE_DAMAGE);
  });
});
