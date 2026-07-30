/**
 * GRAVITO:MANAGED — shipped by build-os/maintenance/install-maintenance.sh.
 * Edits made in an installed repo are REPLACED on the next install. Change it
 * upstream, or unmanage it by removing the path from .gravito-managed.
 *
 * SOURCE SCAN of rotate-memory.test.mjs — ENUMERATED shapes, not a universal.
 *
 * Run: ./build-os/maintenance/run-tests.sh
 *
 * THAT COMMAND, NOT A BARE `node --test`. This file's own header used to print
 * one, and that is the line an attack was written against: `node --test` takes
 * no preload, so it leaves the real-memory tripwire's arming to the spelling of
 * this file's first import. The wrapper preloads it instead.
 *
 * -------------------------------------------------------------------------
 * WHY THIS FILE EXISTS SEPARATELY FROM THE FILE IT SCANS
 * -------------------------------------------------------------------------
 * A scanner that forbids a set of tokens, written INSIDE the file it scans, must
 * exempt the span that names those tokens — and that span is executable code.
 * The previous attempt's token list self-matched its own list 23 times, and five
 * rounds of patching kept finding holes in the exemptions, because it is a fixed
 * point rather than an oversight. That scanner was deleted.
 *
 * This one is built as MUTUAL CROSS-SCANNING instead:
 *
 *   this file               ->  reads rotate-memory.test.mjs, the tripwire and
 *                               source-scan.mjs AS DATA and scans them
 *   rotate-memory.test.mjs  ->  reads THIS file as data and asserts it can
 *                               acquire no module that starts a process
 *
 * WHAT IS TRUE ABOUT SELF-SCANNING, EXACTLY. An earlier version of this comment
 * said "neither file scans itself, therefore neither file needs a single
 * exemption, and there is no exemption anywhere for a defect to hide in." That
 * was false in both halves, and it is worth writing down why rather than
 * quietly deleting it:
 *
 *   - rotate-memory.test.mjs DID read its own source (`SUITE_SRC`) and count a
 *     token in it. That is self-scanning.
 *   - To keep that count at one, it wrote the module specifier as
 *     `"node:" + "child_process"` so its own mention would not be counted. That
 *     is an exemption device — a cleverer member of the same family as the
 *     region markers and caps that grew holes for five rounds, not an escape
 *     from it. A review then used the SAME two-fragment trick to obtain a spawn
 *     API through `createRequire`, and every count still read zero.
 *
 * Both are gone. The self-count is deleted; the composed-specifier hole is
 * closed for real by folding string concatenations before scanning (see
 * `source-scan.mjs`), so a specifier written in fragments is scanned as the
 * string it denotes. What survives of the original idea is only the true part:
 * NO FILE HERE IS THE SOLE JUDGE OF ITSELF.
 *
 * This file NEVER imports rotate-memory.mjs, never starts a process, and never
 * invokes the rotation tool by any route. It reads files as text. It also
 * imports the real-memory tripwire, which is what bounds the damage if that
 * ever stops being true.
 *
 * -------------------------------------------------------------------------
 * WHAT THE SCAN REPORTS
 * -------------------------------------------------------------------------
 * For every call to a tool wrapper (`run`, `runJson`, `runNodeJson`) written in
 * the scanned source, whether or not it is ever executed:
 *
 *   1. NO `--root` AT ALL. The tool resolves `opts.root ?? path.join(here,
 *      "..", "..")`, so its default root IS the real repo. That default is right
 *      for production and lethal from a test: a rootless invocation rotates live
 *      Build OS memory. Since `.gitignore` un-ignored that path, the damage is
 *      no longer invisible — `git status` reports `?? build-os/memory/archive/`
 *      once the archive is created — but being reported is not being backed up:
 *      nothing in the archive is in version control until it is committed. This
 *      is the exact shape that passed a full green suite in an earlier round.
 *   2. A REAL-MEMORY ROOT. `REPO_ROOT`, any binding transitively assigned from
 *      it, the literal repo path, or a `path.join`/`path.resolve` derivation
 *      from `HERE` with two `".."` steps — appearing anywhere in the call,
 *      including in a `{ cwd: ... }` option beside a relative `--root`.
 *   3. A CHILD-PROCESS CALL outside the two enumerated wrapper bodies, or a
 *      child-process import/require/dynamic-import other than the one asserted
 *      import statement.
 *   4. AN INDIRECT MODULE ACQUISITION anywhere: `createRequire`, an `eval` call,
 *      a `new Function` call, the `binding` back-door, or the CommonJS module
 *      constructor. Rule 3 asks which specifiers are imported; rule 4 asks
 *      whether the file holds a way to import one without saying so.
 *
 * RULES 3 AND 4 SCAN A CONCATENATION-FOLDED COPY of the source, so a specifier
 * assembled from four fragments and handed to a `createRequire` result is read
 * as the string it denotes. (Spelled out, that is the last
 * `acquisitionProbes.indirect` entry in rootscan-controls.json. It is not
 * spelled out here: this file is scanned for exactly that shape by
 * rotate-memory.test.mjs, and prose is scanned like code on purpose.) It was
 * demonstrated against the previous version of this scan: it obtained a spawn
 * API and rotated live memory while every literal-token count still read zero.
 *
 * Findings are produced by a PURE function, `scanSuiteSource`, whose positive
 * controls are SYNTHETIC SOURCE STRINGS defined in this file. No control has to
 * live in the scanned file, so the scanned file never carries a deliberately
 * dangerous shape for a scanner's benefit.
 *
 * COMMENTS ARE SCANNED LIKE CODE. A call shape written in prose is reported.
 * That is deliberate: it over-reports and never under-reports, and a false
 * positive is a loud, one-line fix.
 *
 * -------------------------------------------------------------------------
 * WHAT THIS DOES *NOT* CATCH. Named, not implied away.
 * -------------------------------------------------------------------------
 *   a. AN ALIAS OF THE ALREADY-IMPORTED `spawnSync` in the scanned file
 *      (`const s = spawnSync; s(TOOL, args)`). It adds no import, so rule 3 does
 *      not see it, and it never routes through a wrapper, so the runtime gate
 *      never runs. THIS SCAN STILL DOES NOT CATCH IT. What now bounds it is the
 *      real-memory tripwire: whatever such a call spawns, if the real tree moves
 *      the run goes red at exit. That is containment of the CONSEQUENCE, not
 *      detection of the shape, and the difference is the whole of the residual.
 *   b. A ROOT VALUE COMPUTED AT RUNTIME. `run(["--root", pick()])` is accepted
 *      by rule 2 whatever `pick()` returns. Only the runtime gate in the scanned
 *      file (`requireScratchRoot`) sees the actual value.
 *   c. A CALL INSIDE `assert.throws(() => ...)` is classified as a NEGATIVE
 *      CONTROL for the runtime gate and its root is deliberately not checked —
 *      those calls exist precisely to pass bad roots. The exemption is pinned:
 *      the scanned file's control count is asserted to an exact number, so a new
 *      one cannot be added silently.
 *   d. THIS SCAN PROVES NOTHING ABOUT RUNTIME. It reads text. That the gate
 *      actually fires is proven in the scanned file, by executed controls.
 *   e. A REAL ROOT REACHED THROUGH A PROPERTY RATHER THAN A BINDING.
 *      `cfg["r"] = REPO_ROOT; run(["--root", cfg["r"]])` and
 *      `const W = { run }; W.run([...])` are both invisible here: rule 2's alias
 *      set is built from `const/let/var` declarations only, and the wrapper-call
 *      pattern excludes member calls on purpose (`obj.run(...)` is usually not
 *      this `run`). Neither is a scan miss with consequences: the first passes a
 *      real root to the wrapper and the RUNTIME GATE throws on it, and the
 *      second still enters the gated wrapper body. Named because they are real
 *      holes in THIS scan, and because "the runtime gate has it" is a claim
 *      about the other mechanism, not about this one.
 *   f. A SPECIFIER COMPUTED AT RUN TIME. Folding handles literal fragments
 *      joined by `+`. It does not handle `"node:" + mod`, an array `.join("")`,
 *      or character arithmetic. Rule 4 is what makes those expensive: they still
 *      need a loader, and every named way to reach one is reported.
 *   g. A LOADER RENAMED AT ITS IMPORT. Rule 4 matches NAMES, so
 *      `import { createRequire as cr } from "node:module"` and then `cr(...)`
 *      escapes it, in exactly the way an alias of `spawnSync` escapes rule 3 —
 *      same hole, one level up. Both were measured: with the literal name every
 *      invocation path goes red at scan time; with the name aliased the scan
 *      says nothing and the run still goes red, at exit, on every path where the
 *      call actually ran, because the real tree moved. Detection is defeated by
 *      a rename; containment is not.
 *   h. ANY FILE OTHER THAN THE THREE NAMED HERE — rotate-memory.test.mjs,
 *      real-memory-tripwire.mjs and source-scan.mjs. A new file in this
 *      directory is not scanned by these rules; if it is a `*.test.mjs` it is
 *      still forced to arm the tripwire, by the tripwire's own coverage check.
 */

/*
 * FIRST IMPORT, DELIBERATELY — see the note at the top of the tripwire module.
 * This file binds the real repo root and holds a filesystem binding; before the
 * tripwire became a shared module, one appended line here rewrote live Build OS
 * memory at exit 0 under the command printed at the top of this file.
 */
import {
  REAL_MEMORY_FILES,
  ROTATED_MEMORY_FILES,
  REAL_ARCHIVE_REL,
} from "./real-memory-tripwire.mjs";
import { test, describe } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

import {
  countOf,
  lineAt,
  lineNoAt,
  foldConcatenations,
  moduleImportsOf,
  indirectAcquisitionFindings,
  membersUsedOn,
  bareReferencesTo,
  moduleRequestSpecifiers,
} from "./source-scan.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const SCANNED_NAME = "rotate-memory.test.mjs";
const SCANNED_PATH = path.join(HERE, SCANNED_NAME);
const SCANNED_SRC = fs.readFileSync(SCANNED_PATH, "utf8");

/**
 * The real repo root, used ONLY as a needle to search for in the scanned text.
 * It is never passed anywhere: this file starts no process.
 */
const REPO_ROOT_PATH = path.resolve(HERE, "..", "..");

/**
 * EVERY DELIBERATELY DANGEROUS STRING THIS FILE USES LIVES IN A JSON FILE.
 *
 * Not for tidiness. A control planted in a `.mjs` file is, to any scan of that
 * file, indistinguishable from the defect it imitates — so the previous round
 * composed its own module specifier from two fragments to keep its own controls
 * out of its own counts, and that exemption device was then used to obtain a
 * real spawn API while every count read zero.
 *
 * JSON has no import syntax and no evaluation. A shape written there cannot run,
 * so both halves of the cross-scan can hold each other to a FLAT count with no
 * carve-out for "but that one is only a control".
 *
 * WHAT CHECKS THE JSON: every entry in it is exercised below, and both table
 * lengths are pinned in the test titles.
 */
const CONTROLS = JSON.parse(fs.readFileSync(path.join(HERE, "rootscan-controls.json"), "utf8"));

const CP_MODULE = CONTROLS.childProcessModule;

/** The two — and only two — child-process call sites the scanned file may have. */
const ALLOWED_CP_CALL_LINES = [
  'const res = spawnSync("bash", [SCRIPT, ...args], {',
  'const res = spawnSync(process.execPath, [mjs, ...args, "--json"], {',
];

/** The one import statement the scanned file may use to obtain a spawn API. */
const ALLOWED_CP_IMPORT = CONTROLS.allowedChildProcessImportLine;

/**
 * The one wrapper-to-wrapper delegation, which legitimately carries no literal
 * `--root` because it forwards an argument list its own caller already gated.
 * Pinned to exactly one occurrence, so a second one cannot appear unremarked.
 */
const ALLOWED_DELEGATION = 'const res = run([...args, "--json"], opts);';

/** Flags that may appear alone: the tool returns before computing any root. */
const HELP_ONLY_FLAGS = new Set(["--help", "-h", "--json"]);

/* ------------------------------------------------------------------ */
/* the pure scan                                                       */
/* ------------------------------------------------------------------ */

/** Text between the parentheses opened at `open`, or null if never closed. */
function balancedArgs(src, open) {
  let depth = 0;
  for (let i = open; i < src.length; i++) {
    if (src[i] === "(") depth++;
    else if (src[i] === ")") {
      depth--;
      if (depth === 0) return src.slice(open + 1, i);
    }
  }
  return null;
}

/** Every double- or single-quoted literal in `text`, unescaped naively. */
function stringLiterals(text) {
  return (text.match(/"[^"\\\n]*"|'[^'\\\n]*'/g) ?? []).map((s) => s.slice(1, -1));
}

const word = (id) => new RegExp(`(?<![\\w$])${id}(?![\\w$])`);

/**
 * Every identifier transitively bound to the real repo root:
 * `const a = REPO_ROOT; const b = a;` yields {REPO_ROOT, a, b}. This is what
 * makes rule 2 survive an alias, which is the dressing that defeated the
 * previous source scan.
 *
 * COMPUTED TO CONVERGENCE, NOT TO A BOUND. The previous version ran a fixed
 * `pass < 8` loop and DROPPED OUT SILENTLY when it hit the bound, so a chain of
 * nine aliases DECLARED IN REVERSE ORDER — each pass discovers exactly one link
 * — walked straight through it while the comment above it said "fixpoint". A
 * safety scanner that gives up quietly is the failure class this file exists to
 * remove, so the loop now runs until nothing grows.
 *
 * It terminates: `aliases` only ever gains names, every name it can gain is one
 * of `decls`, and a pass that gains none returns. `LIMIT` is therefore
 * unreachable — one growing pass per declaration is the worst case — and
 * reaching it means this function is wrong, so it THROWS rather than returning
 * a half-computed alias set that would read as "nothing found".
 */
export function realRootAliases(src, limit = null) {
  const DECL = /(?:const|let|var)\s+([A-Za-z_$][\w$]*)\s*=\s*([^;\n]+)/g;
  const decls = [];
  let d;
  while ((d = DECL.exec(src)) !== null) decls.push([d[1], d[2]]);

  const aliases = new Set(["REPO_ROOT"]);
  const LIMIT = limit ?? decls.length + 2;
  for (let pass = 0; ; pass++) {
    if (pass >= LIMIT) {
      throw new Error(
        `realRootAliases did not converge in ${LIMIT} passes over ${decls.length} ` +
          `declarations. Each non-final pass adds at least one alias and no alias is ` +
          `ever removed, so this is impossible for a finite source: the alias walk is ` +
          `wrong. Refusing to report a half-computed alias set as "clean".`
      );
    }
    let grew = false;
    for (const [name, rhs] of decls) {
      if (aliases.has(name)) continue;
      if (namesRealRoot(rhs, aliases, null) !== null) {
        aliases.add(name);
        grew = true;
      }
    }
    if (!grew) return aliases;
  }
}

/** Why `text` denotes a real-memory root, or null. */
function namesRealRoot(text, aliases, repoRootPath) {
  for (const a of aliases) {
    if (word(a).test(text)) return `names \`${a}\``;
  }
  if (repoRootPath && text.includes(repoRootPath)) {
    return `embeds the literal repo path \`${repoRootPath}\``;
  }
  if (word("HERE").test(text) && countOf(text, '".."') >= 2) {
    return "derives a root from `HERE` with two `..` steps";
  }
  return null;
}

/**
 * Scan `src` for the enumerated shapes above.
 *
 * Returns `{ findings, live, controls, exempt }`. `findings` is a list of
 * human-readable strings; an empty list is the pass condition. The counts are
 * returned so a caller can pin them and notice growth.
 */
export function scanSuiteSource(rawSrc, repoRootPath = null) {
  /*
   * EVERY RULE BELOW READS THE FOLDED SOURCE, not the raw text. Folding merges
   * adjacent quoted literals joined by `+`, and preserves both the byte length
   * and the newline count of each span it rewrites, so every line number
   * reported here is the line number in the file on disk.
   *
   * This is what makes rule 3b see `require("node:" + "child" + "_pro" +
   * "cess")`. Folding also, harmlessly, makes rule 1 see a `--root` flag spelled
   * in two pieces: that call really does pass `--root`, and its VALUE was never
   * this scan's business — the runtime gate owns that.
   */
  const src = foldConcatenations(rawSrc);
  const findings = [];
  const aliases = realRootAliases(src);

  /* ---- rule 1 and rule 2: wrapper call sites ---- */
  const WRAPPER_CALL = /(?<![\w$.])(runNodeJson|runJson|run)\s*\(/g;
  let live = 0;
  let controls = 0;
  let exempt = 0;
  let m;
  while ((m = WRAPPER_CALL.exec(src)) !== null) {
    const at = m.index;
    const where = `${m[1]}() at line ${lineNoAt(src, at)}`;

    // a declaration is not a call
    if (/(?:^|[^\w$])function\s+$/.test(src.slice(0, at))) continue;

    const args = balancedArgs(src, at + m[0].length - 1);
    if (args === null) {
      findings.push(`${where}: the argument list is never closed — cannot be scanned`);
      continue;
    }

    // a call inside `assert.throws(() => ...)` is a NEGATIVE CONTROL for the
    // runtime gate: it exists to pass a bad root and must not be reported.
    if (src.slice(0, at).replace(/\s+/g, "").endsWith("assert.throws(()=>")) {
      controls++;
      continue;
    }

    const literals = stringLiterals(args);
    const helpish = literals.filter((s) => s === "--help" || s === "-h");
    if (helpish.length > 0 && literals.every((s) => HELP_ONLY_FLAGS.has(s))) {
      exempt++;
      continue;
    }
    if (lineAt(src, at) === ALLOWED_DELEGATION) {
      exempt++;
      continue;
    }

    live++;
    if (!literals.includes("--root")) {
      findings.push(
        `${where}: NO --root. The tool's default root is the real repo, so this ` +
          `invocation rotates live Build OS memory. git status will show the ` +
          `archive appear, but nothing in it is version-controlled until it is ` +
          `committed. args=${JSON.stringify(args.trim())}`
      );
    }
    const why = namesRealRoot(args, aliases, repoRootPath);
    if (why !== null) {
      findings.push(
        `${where}: REAL-MEMORY ROOT — the call ${why}. Point it at a scratch ` +
          `copy. args=${JSON.stringify(args.trim())}`
      );
    }
  }

  /* ---- rule 3a: child-process call sites ---- */
  const CP_CALL = /(?<![\w$.])(spawnSync|execSync|execFileSync|execFile|spawn|exec|fork)\s*\(/g;
  let c;
  while ((c = CP_CALL.exec(src)) !== null) {
    const line = lineAt(src, c.index);
    if (!ALLOWED_CP_CALL_LINES.includes(line)) {
      findings.push(
        `${c[1]}() at line ${lineNoAt(src, c.index)}: a child-process call outside the ` +
          `two enumerated gated wrapper bodies. Every process must start inside a ` +
          `wrapper that calls requireScratchRoot first. line=${JSON.stringify(line)}`
      );
    }
  }
  for (const expected of [...ALLOWED_CP_CALL_LINES, ALLOWED_DELEGATION]) {
    const n = countOf(src, expected);
    if (n !== 1) {
      findings.push(
        `the gated wrapper body ${JSON.stringify(expected)} appears ${n} times, expected 1. ` +
          `Each exemption is pinned to one occurrence so a second copy cannot inherit it.`
      );
    }
  }

  /* ---- rule 3b: child-process imports (on the FOLDED source) ---- */
  const acquisitions = moduleImportsOf(src, CP_MODULE);
  for (const { lineNo, line } of acquisitions) {
    if (line !== ALLOWED_CP_IMPORT) {
      findings.push(
        `line ${lineNo}: a child-process import that is not the one asserted import ` +
          `statement. line=${JSON.stringify(line)}`
      );
    }
  }
  if (acquisitions.length !== 1) {
    findings.push(
      `the scanned file carries ${acquisitions.length} child-process imports, expected exactly 1`
    );
  }

  /* ---- rule 4: indirect module acquisition ---- */
  findings.push(...indirectAcquisitionFindings(src, "the scanned file"));

  return { findings, live, controls, exempt };
}

/* ------------------------------------------------------------------ */
/* positive controls — INERT DATA, never the scanned file              */
/* ------------------------------------------------------------------ */

/*
 * A minimal well-formed source that the scan must pass, used as the base for
 * every control so each control differs from a PASSING source by exactly the one
 * shape it is about. It, and every control, is read from rootscan-controls.json.
 */
const REPO_PATH_FIXTURE = "/home/user/some-repo";

/**
 * Twelve aliases of the real root, DECLARED IN REVERSE DEPENDENCY ORDER, so a
 * single sweep of the declarations resolves exactly one link. A bounded walk
 * that stops after N sweeps reports the first N and then reads clean. This is
 * the exact shape that walked through the previous `pass < 8` loop.
 */
const REVERSE_ALIAS_CHAIN =
  Array.from({ length: 11 }, (_, i) => `const z${12 - i} = z${11 - i};\n`).join("") +
  `const z1 = REPO_ROOT;\n`;

const CLEAN = CONTROLS.clean;

/** Expand the three placeholders the JSON uses, so it can stay free of code. */
const expand = (s) =>
  s
    .split("{{CLEAN}}")
    .join(CLEAN)
    .split("{{REPO_PATH}}")
    .join(REPO_PATH_FIXTURE)
    .split("{{REVERSE_ALIAS_CHAIN}}")
    .join(REVERSE_ALIAS_CHAIN);

/** [label, source, expected substring of the finding it must produce] */
const MUST_REPORT = CONTROLS.mustReport.map((c) => [c.label, expand(c.source), c.needle]);

/** Sources the scan must NOT report. */
const MUST_PASS = CONTROLS.mustPass.map((c) => [c.label, expand(c.source)]);

describe("the scan itself, driven by synthetic source strings", () => {
  test(`the 24 enumerated bad shapes are each reported`, () => {
    assert.equal(MUST_REPORT.length, 24, "the count in this title must match the table");
    for (const [label, src, needle] of MUST_REPORT) {
      const { findings } = scanSuiteSource(src, REPO_PATH_FIXTURE);
      assert.ok(
        findings.some((f) => f.includes(needle)),
        `${label}: expected a finding containing ${JSON.stringify(needle)}, got ${JSON.stringify(findings)}`
      );
    }
  });

  test("the 4 legitimate shapes are reported by nothing", () => {
    assert.equal(MUST_PASS.length, 4, "the count in this title must match the table");
    for (const [label, src] of MUST_PASS) {
      const { findings } = scanSuiteSource(src, REPO_PATH_FIXTURE);
      assert.deepEqual(findings, [], `${label}: expected no findings`);
    }
  });

  test("the negative-control exemption is narrow: the SAME call outside assert.throws is reported", () => {
    const inside = CLEAN + `test("x", () => { assert.throws(() => run(["--root", REPO_ROOT]), /x/); });\n`;
    const outside = CLEAN + `test("x", () => { run(["--root", REPO_ROOT]); });\n`;
    assert.deepEqual(scanSuiteSource(inside, REPO_PATH_FIXTURE).findings, []);
    assert.equal(scanSuiteSource(inside, REPO_PATH_FIXTURE).controls, 2);
    assert.ok(
      scanSuiteSource(outside, REPO_PATH_FIXTURE).findings.some((f) => f.includes("names `REPO_ROOT`")),
      "the exemption must depend on assert.throws and nothing else"
    );
  });

  /*
   * Folding is only safe to scan on if the line numbers it produces are the line
   * numbers of the file on disk. Otherwise every finding sends a reader to the
   * wrong place, which is its own kind of silent failure.
   */
  test("folding preserves byte length and newline count, so reported line numbers are the real ones", () => {
    const raw =
      `// line 1\n// line 2\n` +
      `const cp = require("node:" +\n  "child" +\n  "_process");\n` +
      `const marker = 1;\n`;
    const folded = foldConcatenations(raw);
    assert.equal(folded.length, raw.length, "folding changed the byte length");
    assert.equal(countOf(folded, "\n"), countOf(raw, "\n"), "folding changed the newline count");
    assert.equal(
      lineNoAt(folded, folded.indexOf("const marker")),
      lineNoAt(raw, raw.indexOf("const marker")),
      "a line after a folded span moved"
    );

    // ...and the composed specifier is now reported AT THE LINE IT STARTS ON
    const hits = moduleImportsOf(raw, "child_process");
    assert.equal(hits.length, 1, JSON.stringify(hits));
    assert.equal(hits[0].lineNo, 3, "the composed require must be reported at its own line");
  });

  test("the alias walk runs to convergence: an 11-hop reverse chain is fully resolved", () => {
    const src = REVERSE_ALIAS_CHAIN + `run(["--root", z12]);\n`;
    const { findings } = scanSuiteSource(src);
    assert.ok(
      findings.some((f) => f.includes("names `z12`")),
      `a reverse-order alias chain escaped the walk: ${JSON.stringify(findings)}`
    );
  });

  /*
   * Both walks below have bounds that no finite input can reach. The point of
   * these two tests is that reaching one is a THROW and not a shrug: a scanner
   * that returns "nothing found" because it ran out of passes is the exact
   * failure class this file exists to remove. The bound is passed in explicitly
   * because the computed default cannot be provoked.
   */
  test("the alias walk THROWS rather than giving up when its bound is hit", () => {
    const src = REVERSE_ALIAS_CHAIN;
    assert.deepEqual([...realRootAliases(src)].includes("z12"), true, "the default walk converges");
    assert.throws(() => realRootAliases(src, 3), /did not converge in 3 passes/);
  });

  test("concatenation folding THROWS rather than scanning a half-folded source", () => {
    assert.throws(
      () => foldConcatenations(`const a = "x" + "y";\n`, 0),
      /did not converge in 0 passes/
    );
  });
});

describe(`the enumerated scan of ${SCANNED_NAME}`, () => {
  test("reports nothing", () => {
    const { findings } = scanSuiteSource(SCANNED_SRC, REPO_ROOT_PATH);
    assert.deepEqual(
      findings,
      [],
      `${SCANNED_NAME} carries ${findings.length} scanned defect(s):\n  ${findings.join("\n  ")}`
    );
  });

  test("the counts are pinned, so a new call or a new negative control cannot arrive unnoticed", () => {
    const { live, controls, exempt } = scanSuiteSource(SCANNED_SRC, REPO_ROOT_PATH);
    assert.equal(controls, 20, "the assert.throws negative-control budget changed");
    assert.equal(exempt, 3, "the --help / delegation exemption budget changed");
    assert.ok(live >= 60, `only ${live} live wrapper calls were scanned — the scan may be blind`);
  });
});

/* ================================================================== */
/* the two non-test modules every suite file loads                      */
/* ================================================================== */

/*
 * WHAT CHECKS THE CHECKERS. The tripwire is imported by every test file here and
 * runs before any of them; source-scan.mjs supplies the folding both halves of
 * the cross-scan depend on. Neither is a test file, so neither is covered by the
 * tripwire's own coverage rule, and neither can honestly vouch for itself.
 *
 * They are checked HERE, as data, by a file that is not either of them, against
 * flat properties with no exemption span:
 *
 *   real-memory-tripwire.mjs — imports four read-only node modules, touches the
 *     filesystem only through an enumerated read-only whitelist, never lets its
 *     filesystem binding escape as a bare reference, and reaches no loader.
 *   source-scan.mjs — imports NOTHING. A module with no bindings and no loader
 *     cannot act on the machine at all, whatever it computes.
 *
 * The rules are written so their own text does not satisfy them: each looks for
 * a name immediately followed by `(`, and in a regular-expression source that
 * name is followed by a backslash. That is a property, not a carve-out, but it
 * is the kind of cleverness that has bitten this file before, so it is written
 * down rather than relied on quietly.
 */

const TRIPWIRE_NAME = "real-memory-tripwire.mjs";
const TRIPWIRE_SRC = fs.readFileSync(path.join(HERE, TRIPWIRE_NAME), "utf8");
const SCANLIB_NAME = "source-scan.mjs";
const SCANLIB_SRC = fs.readFileSync(path.join(HERE, SCANLIB_NAME), "utf8");

/** The only filesystem members the tripwire may name. All of them read. */
const TRIPWIRE_FS_WHITELIST = new Set([
  "readFileSync",
  "readdirSync",
  "statSync",
  "existsSync",
  "realpathSync",
]);

describe(`the modules every suite file loads: ${TRIPWIRE_NAME} and ${SCANLIB_NAME}`, () => {
  test("the tripwire reaches no loader and starts no process", () => {
    assert.deepEqual(indirectAcquisitionFindings(TRIPWIRE_SRC, TRIPWIRE_NAME), []);
    assert.deepEqual(moduleImportsOf(TRIPWIRE_SRC, CP_MODULE), []);
    const CP_CALL = /(?<![\w$.])(spawnSync|execSync|execFileSync|execFile|spawn|exec|fork)\s*\(/g;
    assert.equal(
      (foldConcatenations(TRIPWIRE_SRC).match(CP_CALL) ?? []).length,
      0,
      "the tripwire contains a child-process call"
    );
    assert.doesNotMatch(TRIPWIRE_SRC, /from\s*["']\.\/rotate-memory\.mjs["']/);
  });

  test("the tripwire acquires exactly the five modules its header names", () => {
    /*
     * Its header says "no module beyond the four `node:` reads and
     * source-scan.mjs". That sentence used to be unmeasured, and this round is
     * the one that added the fifth — so it is pinned as a list, in order, rather
     * than left as a claim somebody has to re-read the imports to check.
     */
    assert.deepEqual(moduleRequestSpecifiers(TRIPWIRE_SRC), [
      "node:fs",
      "node:path",
      "node:crypto",
      "node:url",
      "./source-scan.mjs",
    ]);
  });

  test("the tripwire touches the filesystem only through a read-only whitelist", () => {
    const used = [...membersUsedOn(TRIPWIRE_SRC, "fs")].sort();
    const forbidden = used.filter((m) => !TRIPWIRE_FS_WHITELIST.has(m));
    assert.deepEqual(
      forbidden,
      [],
      `${TRIPWIRE_NAME} uses non-whitelisted filesystem members: ${forbidden.join(", ")}. ` +
        `A tripwire that can write is not a tripwire.`
    );
    assert.ok(used.length >= 4, `only ${used.length} filesystem reads — the tripwire may be inert`);
  });

  test("the tripwire never lets its filesystem binding escape as a bare reference", () => {
    const bare = bareReferencesTo(TRIPWIRE_SRC, "fs");
    const offLine = bare.filter((b) => b.line !== 'import fs from "node:fs";');
    assert.deepEqual(
      offLine,
      [],
      `${TRIPWIRE_NAME} refers to \`fs\` outside its import statement: ${JSON.stringify(offLine)}. ` +
        `A bare reference can be passed somewhere the whitelist above cannot see.`
    );
    assert.ok(bare.length > 0, "the bare-reference scan found nothing at all — it may be blind");
  });

  test("the tripwire's baselines cover the four watched files AND the archive directory", () => {
    /*
     * NAMED LITERALLY, so silently narrowing what is watched is a red test.
     *
     * THE FOURTH ONE IS NOT ROTATED, AND THAT IS WHY IT IS HERE. The first three
     * are the rotation set. `standing_gates.md` is the never-rotated authority
     * for hard stops, and until this round NOTHING watched it: it was absent from
     * both this list and the wrapper's `WATCHED`, so a test body that rewrote the
     * one file that must never change was reported by neither mechanism and the
     * run exited 0. Being outside the rotation tool's blast radius (pinned at the
     * foot of this file) is protection from THE TOOL, not from a test body.
     */
    for (const needle of [
      '"build-os/memory/current_state.md"',
      '"build-os/memory/residue.md"',
      '"build-os/packets/active_packet.md"',
      '"build-os/memory/standing_gates.md"',
      '"build-os/memory/archive"',
    ]) {
      assert.equal(
        countOf(TRIPWIRE_SRC, needle),
        1,
        `${TRIPWIRE_NAME} no longer names ${needle} exactly once`
      );
    }
    /*
     * ...and it decides by CONTENT, not by asking git. Half of that rationale is
     * now obsolete: since `.gitignore` un-ignored `build-os/memory/archive/`,
     * `git status` DOES show the archive appear. The other half stands — while
     * the archive is untracked, status reports at most one line for the whole
     * directory, and that line is identical whether a file inside was just
     * added, rewritten, or deleted (measured). So git still cannot answer the
     * question the tripwire asks; hashing bytes remains the right mechanism, and
     * the tripwire has no way to start a git process anyway (asserted above).
     */
    assert.match(TRIPWIRE_SRC, /createHash\("sha256"\)/, "the tripwire no longer hashes content");
    assert.doesNotMatch(TRIPWIRE_SRC, /(?<![\w$.])(spawnSync|execSync|execFileSync)\s*\(/);
  });

  test(`${SCANLIB_NAME} imports nothing and reaches no loader`, () => {
    assert.deepEqual(indirectAcquisitionFindings(SCANLIB_SRC, SCANLIB_NAME), []);
    assert.equal(
      (SCANLIB_SRC.match(/^import\s/gm) ?? []).length,
      0,
      `${SCANLIB_NAME} has acquired an import. Its whole safety argument is that it has none.`
    );
    /*
     * ...and the same thing at any column. The line-anchored count above is the
     * one this round found a hole in; it is kept because it is independent of
     * the masker, and this one is added because the masker is what closes it.
     */
    assert.deepEqual(
      moduleRequestSpecifiers(SCANLIB_SRC),
      [],
      `${SCANLIB_NAME} has acquired a module request somewhere off column 0.`
    );
    for (const token of ["require(", "import(", "globalThis", "process."]) {
      assert.equal(
        countOf(SCANLIB_SRC, token),
        0,
        `${SCANLIB_NAME} names ${JSON.stringify(token)}; a pure text module has no use for it`
      );
    }
  });
});

/* ================================================================== */
/* THE SANCTIONED COMMAND                                               */
/* ================================================================== */

/*
 * WHY THE COMMAND ITSELF IS UNDER TEST.
 *
 * Everything the tripwire does that PREVENTS rather than merely REPORTS depends
 * on being loaded before the test files, and the only thing that arranges that
 * is the `--import` preload in `run-tests.sh`. Loaded by an import instead, the
 * same coverage scan runs after whatever preceded that import has already run,
 * and a file that imports nothing loads the tripwire on no path at all. So the
 * preload is load-bearing, and a wrapper that quietly stopped passing it would
 * restore the exact hole this round closed while every test still passed.
 *
 * So the wrapper is read AS DATA here and pinned: it must preload the tripwire,
 * it must run the suite files, and every suite file must print it as the way to
 * run the suite. A `Run:` line naming a bare `node --test` is not a
 * documentation nit — it is an instruction to use the uncovered path, and that
 * is precisely the line an attack was written against.
 */

const RUNNER_NAME = "run-tests.sh";
const RUNNER_PATH = path.join(HERE, RUNNER_NAME);

/*
 * DISCOVERABILITY, WHICH IS A SEPARATE THING FROM THE MECHANISMS ABOVE.
 *
 * Until this round the wrapper was reachable only by already knowing its path:
 * `grep -rn run-tests` over the repo found these files talking about themselves
 * and NOTHING outside this directory. The one place a reader looks for how a repo
 * runs its tests is package.json, so the sanctioned command is exposed there and
 * pinned here, in both directions — the entry must BE the wrapper invocation, and
 * no script may take the unsanctioned path into this directory.
 *
 * It is a signpost, not a fence. See the containment-boundary clause pinned in
 * both headers below: a package script cannot stop a hand-run bare `node --test`.
 *
 * A REPO MAY HAVE NO package.json AT ALL, and that is not a failure. This layer
 * installs into any git repo, not only Node projects: reading the manifest
 * unconditionally would make a Python, Go or docs-only repo red on arrival. When
 * there is no manifest the npm signpost is absent by construction, and what is
 * pinned instead is the fallback that still makes the command findable — the
 * wrapper is executable and named in build-os/maintenance/PORTING.md. Signpost
 * or fallback, neither is a fence, and neither shortens the uncovered list.
 */
const PKG_PATH = path.join(HERE, "..", "..", "package.json");
const PORTING_PATH = path.join(HERE, "PORTING.md");
const WRAPPER_INVOCATION = "./build-os/maintenance/run-tests.sh";

/** `{ scripts }` of the host repo's manifest, or null when it has none. */
function readPackageScripts() {
  let raw;
  try {
    raw = fs.readFileSync(PKG_PATH, "utf8");
  } catch (e) {
    if (e.code === "ENOENT") return null;
    throw e;
  }
  /*
   * A manifest that EXISTS but does not parse is a failure, not a fallback: it
   * would otherwise be the cheapest way to switch this pin off.
   */
  return JSON.parse(raw).scripts ?? {};
}

const PKG_SCRIPTS = readPackageScripts();

describe(`the sanctioned command: ${RUNNER_NAME}`, () => {
  test("exists and is executable", () => {
    const st = fs.statSync(RUNNER_PATH);
    assert.ok(st.isFile(), `${RUNNER_NAME} is not a file`);
    assert.ok(st.mode & 0o111, `${RUNNER_NAME} is not executable`);
  });

  test("preloads the tripwire with --import, before --test", () => {
    const src = fs.readFileSync(RUNNER_PATH, "utf8");

    /*
     * THE INVOCATION, NOT THE PROSE. This script's header explains the preload
     * at length, so a scan of the whole text finds `--import` inside a comment
     * first and proves nothing. Comment lines are dropped, and the assertions
     * are made against the line that actually runs node.
     */
    const cmd = src
      .split("\n")
      .filter((l) => !/^\s*#/.test(l))
      .find((l) => /(^|\s)node\s+--/.test(l));
    assert.ok(cmd, `${RUNNER_NAME} never invokes node with options`);

    const m = cmd.match(/--import\s+(\S+)/);
    assert.ok(m, `${RUNNER_NAME} does not pass --import: ${JSON.stringify(cmd)}`);
    assert.ok(
      cmd.indexOf("--import") < cmd.indexOf("--test"),
      `${RUNNER_NAME} passes --import after --test: ${JSON.stringify(cmd)}`
    );

    /*
     * ...and the argument it preloads is THIS file, resolved. Matching the name
     * as text would pass for a path that does not exist; the preload is the
     * whole mechanism, so it is checked against the filesystem.
     */
    const preloaded = m[1].replace(/["']/g, "").replace(/\$\{SCRIPT_DIR\}/g, HERE);
    assert.ok(
      path.isAbsolute(preloaded) && fs.existsSync(preloaded),
      `${RUNNER_NAME} preloads ${JSON.stringify(m[1])}, which does not resolve to a file`
    );
    assert.equal(
      fs.realpathSync(preloaded),
      fs.realpathSync(path.join(HERE, TRIPWIRE_NAME)),
      `${RUNNER_NAME} preloads ${preloaded}, not the tripwire`
    );

    assert.match(src, /\*\.test\.mjs/, `${RUNNER_NAME} does not run the suite files`);
  });

  /*
   * THE SECOND MECHANISM, AND THE HALF OF IT NOTHING WAS PINNING.
   *
   * The wrapper's value is one comparison: the real tree is hashed before and
   * after the node run, IN THIS SHELL, and a difference fails the run whatever
   * node reported. That comparison is the ONLY thing standing between "a test
   * body deleted the tripwire's exit handler" and "green with a destroyed tree",
   * and it was pinned by nothing at all. Measured in the reference deployment at
   * commit `cb2bb7d`, before this pin existed, each mutation applied alone:
   * flipping `!=` to `=` left the whole suite GREEN — 0 fail, wrapper exit 0 —
   * and deleting the `exit 1` from the branch it guards did the same. That is
   * the same asymmetry the tripwire's own `process.exitCode = 1` had — likewise
   * green with that line removed — and which is driven by an executed mutation
   * in rotate-memory.test.mjs. The pass counts of those runs belonged to that
   * repo's suite on that day; the invisibility is what carries over, and it is
   * the reason these two lines are pinned rather than trusted.
   *
   * This pin is STATIC. The wrapper cannot be driven from inside the suite it
   * runs without spawning a shell from a test body, which the cross-scan forbids
   * for good reasons, so what is checked here is the shape of the script: two
   * fingerprints, one either side of node, compared, and a non-zero exit inside
   * the branch that comparison guards. It is read off the NON-COMMENT lines,
   * because this script's header discusses all of these strings at length.
   */
  test("fingerprints either side of node, and the comparison FAILS THE RUN", () => {
    const src = fs.readFileSync(RUNNER_PATH, "utf8");
    const code = src
      .split("\n")
      .map((l, i) => [i + 1, l])
      .filter(([, l]) => !/^\s*#/.test(l));

    const one = (re, what) => {
      const hits = code.filter(([, l]) => re.test(l));
      assert.equal(hits.length, 1, `${what}: expected exactly one line, found ${hits.length}`);
      return hits[0];
    };

    const [beforeAt, beforeLine] = one(/^\s*BEFORE=/, "the BEFORE fingerprint");
    const [afterAt, afterLine] = one(/^\s*AFTER=/, "the AFTER fingerprint");
    const [nodeAt] = one(/(^|\s)node\s+--/, "the node invocation");
    const [cmpAt] = one(
      /\[\s*"\$\{BEFORE\}"\s*!=\s*"\$\{AFTER\}"\s*\]/,
      "the BEFORE != AFTER comparison"
    );

    // both snapshots come from the same function, so they are comparable at all
    assert.match(beforeLine, /\$\(\s*fingerprint\s*\)/, "BEFORE is not the fingerprint function");
    assert.match(afterLine, /\$\(\s*fingerprint\s*\)/, "AFTER is not the fingerprint function");

    // ...and node runs strictly between them, which is what makes the pair a window
    assert.ok(beforeAt < nodeAt, `BEFORE (line ${beforeAt}) is not taken before node (${nodeAt})`);
    assert.ok(nodeAt < afterAt, `AFTER (line ${afterAt}) is not taken after node (${nodeAt})`);
    assert.ok(afterAt < cmpAt, `the comparison (line ${cmpAt}) precedes AFTER (${afterAt})`);

    // THE ENFORCEMENT HALF: the branch that comparison guards exits non-zero.
    const tail = code.filter(([n]) => n > cmpAt);
    const closes = tail.findIndex(([, l]) => /^\s*fi\s*$/.test(l));
    assert.ok(closes > 0, "the fingerprint comparison's `if` is never closed");
    const guarded = tail.slice(0, closes);
    assert.ok(
      guarded.some(([, l]) => /^\s*exit\s+1\s*$/.test(l)),
      "the fingerprint comparison does not exit non-zero. A differing fingerprint would " +
        "then be REPORTED and IGNORED, which is exactly the failure mode the tripwire's " +
        "own exit handler had: detection without enforcement is a green run with a " +
        "destroyed tree."
    );

    // ...and node's own status is only propagated after that branch, never before
    const propagate = tail.filter(([, l]) => /^\s*exit\s+\$\{?status\}?\s*$/.test(l));
    assert.equal(propagate.length, 1, "node's exit status is not propagated exactly once");
    assert.ok(
      propagate[0][0] > guarded[guarded.length - 1][0],
      "node's status is propagated from inside the fingerprint branch"
    );
  });

  test("the fingerprint covers exactly what the tripwire watches", () => {
    /*
     * A comparison of the wrong tree is a comparison that always agrees. The
     * watched list is pinned against the tripwire's own list rather than against
     * a copy of the paths written here, so the two cannot drift apart.
     */
    const src = fs.readFileSync(RUNNER_PATH, "utf8");
    const block = src.match(/WATCHED=\(([\s\S]*?)\)/);
    assert.ok(block, "run-tests.sh no longer declares a WATCHED list");
    const watched = [...block[1].matchAll(/"([^"]+)"/g)].map((m) => m[1]);
    assert.deepEqual(
      watched,
      REAL_MEMORY_FILES,
      "the shell fingerprint and the in-process tripwire watch different files"
    );
    assert.match(
      src,
      new RegExp(`ARCHIVE_DIR="\\$\\{REPO_ROOT\\}/${REAL_ARCHIVE_REL}"`),
      "the shell fingerprint does not cover the archive directory the tripwire watches"
    );
  });

  test("its external tools are resolved once, and `cut` is gone from the path", () => {
    /*
     * F5. A `cut` planted on PATH defeated the fingerprint exactly as a planted
     * `sha256sum` did, and the header disclosed only the hasher. `cut` was
     * removed rather than disclosed — the hash field is taken with a bash
     * parameter expansion — and the remaining tools are resolved ONCE, before
     * the run, with every later use going through the captured path. Measured:
     * a `sha256sum` planted on PATH by a test body WHILE the suite runs is never
     * invoked at this commit, and is invoked at the commit before it. A PATH
     * that was already hostile at invocation is NOT closed by this, and is
     * disclosed in the wrapper's header instead.
     */
    const src = fs.readFileSync(RUNNER_PATH, "utf8");
    const code = src
      .split("\n")
      .filter((l) => !/^\s*#/.test(l))
      .join("\n");

    assert.doesNotMatch(code, /(?<![\w$-])cut\b/, "run-tests.sh invokes `cut` again");
    for (const tool of ["sha256sum", "shasum", "find", "sort"]) {
      assert.match(
        code,
        new RegExp(`command -v ${tool}\\b`),
        `${tool} is not resolved through \`command -v\` before the run`
      );
    }
    // ...and each resolved binary is invoked through its captured path
    assert.match(code, /"\$\{HASHER\[@\]\}"/, "the hasher is not invoked through its resolved path");
    assert.match(code, /"\$\{FIND_BIN\}"/, "find is not invoked through its resolved path");
    assert.match(code, /"\$\{SORT_BIN\}"/, "sort is not invoked through its resolved path");
    // the fail-closed claim in the header: no find/sort means no run at all
    assert.match(code, /\[ -z "\$\{FIND_BIN\}" \] \|\| \[ -z "\$\{SORT_BIN\}" \][\s\S]*?exit 6/);
  });

  test("the guarantee sentence is byte-identical in both copies, the boundary clause is in both, and neither names a tool the wrapper does not run", () => {
    /*
     * F5b. The sentence used to read "...provided `sha256sum`/`cut` are the real
     * ones...". `cut` was REMOVED from this script (the hash field is taken with
     * `${h%% *}`), so the clause named a tool the wrapper does not run: a bound
     * that cannot bind, and one that survived a round because NOTHING PINNED THE
     * SENTENCE TO THE CODE OR THE TWO COPIES TO EACH OTHER. That is the same
     * defect class as the banner comment — prose drifting away from the thing it
     * describes — so it is now enforced rather than asserted.
     *
     * This pins three things: that both copies still exist, that they normalise
     * to identical text, and that the corrected clause is the one present.
     */
    const norm = (s) =>
      s
        .split("\n")
        .map((l) => l.replace(/^\s*(?:#|\*)\s?/, "").trim())
        .join(" ")
        .replace(/\s+/g, " ");

    const OPENS = "A run under";
    const CLOSES = "node exits.";
    const extract = (src, label) => {
      const n = norm(src);
      const i = n.indexOf(OPENS);
      assert.ok(i >= 0, `${label} does not state the guarantee sentence`);
      const j = n.indexOf(CLOSES, i);
      assert.ok(j > i, `${label}'s guarantee sentence is not terminated`);
      return n.slice(i, j + CLOSES.length);
    };

    const wrapperSrc = fs.readFileSync(RUNNER_PATH, "utf8");
    const suiteSrc = fs.readFileSync(path.join(HERE, "rotate-memory.test.mjs"), "utf8");
    const fromWrapper = extract(wrapperSrc, RUNNER_NAME);
    const fromSuite = extract(suiteSrc, "rotate-memory.test.mjs");

    assert.equal(
      fromSuite,
      fromWrapper,
      "the two copies of the guarantee sentence have drifted apart"
    );
    assert.match(
      fromWrapper,
      /`sha256sum`\/`shasum` resolved at startup is the real one/,
      "the guarantee no longer names the hasher it actually depends on"
    );
    assert.doesNotMatch(
      fromWrapper,
      /cut/,
      "the guarantee names `cut`, which this script does not run"
    );

    /*
     * ...AND THE CONTAINMENT-BOUNDARY CLAUSE TRAVELS WITH IT. package.json now
     * names this wrapper, which is what makes it findable at all; a script entry
     * is not a fence, so both headers say so in the same words rather than
     * leaving "containment" to be read as "enforcement". Pinned by inclusion,
     * under the same normaliser, in both copies — one assertion, not a second
     * mechanism for one sentence.
     */
    const BOUNDARY_CLAUSE =
      "Containment here is discoverability plus out-of-process detection via the " +
      "sanctioned wrapper, not enforcement: nothing prevents a hand-run bare " +
      "`node --test`, which takes no preload and no outer fingerprint.";
    for (const [label, src] of [
      [RUNNER_NAME, wrapperSrc],
      ["rotate-memory.test.mjs", suiteSrc],
    ]) {
      assert.ok(
        norm(src).includes(BOUNDARY_CLAUSE),
        `${label} does not state the containment-boundary clause verbatim: ${JSON.stringify(BOUNDARY_CLAUSE)}`
      );
    }
  });

  test("every suite file documents THAT command, and no bare `node --test`", () => {
    const suite = fs
      .readdirSync(HERE)
      .filter((n) => n.endsWith(".test.mjs"))
      .sort();
    assert.ok(suite.length >= 2, `only ${suite.length} suite file(s) found`);
    for (const name of suite) {
      const head = fs.readFileSync(path.join(HERE, name), "utf8").slice(0, 4000);
      assert.match(
        head,
        /build-os\/maintenance\/run-tests\.sh/,
        `${name} does not print the sanctioned command in its header`
      );
    }
    /*
     * A DOCUMENTED INVOCATION, not every mention. These files have to be able to
     * DISCUSS the unsanctioned path — that is most of what their headers are
     * about — so the rule is about lines that read as an instruction: a line
     * whose first token, after comment decoration and an optional `Run:`, is
     * `node`. Inline prose naming the command is left alone on purpose.
     */
    const INSTRUCTION = /^[ \t]*(?:\*|#|\/\/)?[ \t]*(?:Run:[ \t]*)?node[ \t]+--test\b/gm;
    for (const name of [...suite, RUNNER_NAME, TRIPWIRE_NAME, SCANLIB_NAME]) {
      const src = fs.readFileSync(path.join(HERE, name), "utf8");
      const bare = [...src.matchAll(INSTRUCTION)];
      assert.deepEqual(
        bare.map((m) => `${name}:${lineNoAt(src, m.index)}`),
        [],
        `${name} still advertises a bare \`node --test\` as the way to run it; it takes no preload`
      );
    }
  });

  test("the sanctioned command is discoverable from outside this directory", () => {
    if (PKG_SCRIPTS === null) {
      /*
       * NO MANIFEST: the npm signpost cannot exist, so the fallback is pinned
       * instead — and it is pinned, not waived. The wrapper must be executable
       * (a non-executable wrapper is not a command) and PORTING.md, which ships
       * with this layer, must print the invocation verbatim. Both are things a
       * reader can find without already knowing the path.
       */
      const st = fs.statSync(RUNNER_PATH);
      assert.ok(st.mode & 0o111, `${RUNNER_NAME} is not executable, so it is not a command`);
      const porting = fs.readFileSync(PORTING_PATH, "utf8");
      assert.ok(
        porting.includes(WRAPPER_INVOCATION),
        `this repo has no package.json, so ${JSON.stringify(WRAPPER_INVOCATION)} must be printed ` +
          `in build-os/maintenance/PORTING.md — otherwise the command is reachable only by ` +
          `already knowing its path, which is how the suite spent every previous round.`
      );
      return;
    }
    const exposing = Object.entries(PKG_SCRIPTS).filter(
      ([, body]) => body.trim() === WRAPPER_INVOCATION
    );
    assert.deepEqual(
      exposing.map(([name]) => name),
      ["test:build-os-memory"],
      `exactly one package script must have ${JSON.stringify(WRAPPER_INVOCATION)} as its whole ` +
        `body, named test:build-os-memory. Found ${JSON.stringify(Object.fromEntries(exposing))}. ` +
        `Without it the sanctioned command is reachable only by already knowing its path, which ` +
        `is how the suite spent every previous round.`
    );
  });

  test("...and no package script takes the unsanctioned path into this directory", () => {
    /*
     * A script running the suite through the path that takes no preload and no
     * outer fingerprint is a documented instruction to use it — the same defect
     * as a `Run:` line naming it, one level further out. Matched PER COMMAND
     * SEGMENT so the sibling node:test suites, which legitimately run a bare
     * runner against scripts/, are not caught by it.
     *
     * THE DIRECTORY IS MATCHED AT A WORD BOUNDARY, NOT AS `build-os/`. The
     * earlier rule required the literal trailing slash, so `node --test
     * build-os` — no slash, node walks the directory just the same — read as
     * clean. MEASURED before this widening: `node --test build-os` and
     * `node --test ./build-os` both passed the scan; only
     * `node --test build-os/maintenance/` was caught. The boundary form catches
     * all three and still leaves the siblings alone, because `scripts/...` names
     * the directory nowhere.
     *
     * WHAT IT STILL DOES NOT CATCH, stated rather than implied away: a segment
     * that reaches this directory without naming it — a `cd` into it first, the
     * path held in an env var or npm variable, a glob expanded elsewhere. Those
     * are deliberately out of scope. This is a signpost against ACCIDENTAL
     * DRIFT, and it remains true that no package-script rule fences a hand-run
     * bare `node --test`.
     */
    const NODE_TEST = /(?:^|[\s/])node\s+(?:-\S+\s+)*--test\b/;
    const THIS_DIR = /build-os(?:\/|\b)/;
    const offenders = [];
    for (const [name, body] of Object.entries(PKG_SCRIPTS ?? {})) {
      for (const seg of body.split(/&&|\|\||;/)) {
        if (NODE_TEST.test(seg) && THIS_DIR.test(seg)) {
          offenders.push(`${name}: ${seg.trim()}`);
        }
      }
    }
    assert.deepEqual(
      offenders,
      [],
      `a package script runs this directory's suite through the uncovered path: ` +
        `${JSON.stringify(offenders)}. Point it at ${JSON.stringify(WRAPPER_INVOCATION)} instead.`
    );
    /*
     * ...AND THE SEGMENT SCAN IS NOT VACUOUS — PROVEN AGAINST LITERAL FIXTURES,
     * NOT AGAINST UNRELATED REPO STATE.
     *
     * This guard used to require that SOME package script matched `NODE_TEST`
     * while not naming this directory, and the only scripts that did were
     * `test:contacts` and `test:brand-case`. That coupled a build-os pin to two
     * sibling suites it has nothing to do with: migrating either of them off
     * `node --test` — a perfectly ordinary change — would have turned this file
     * red while proving nothing about the offender scan. The property actually
     * needed is that the two regexes DISCRIMINATE, and a literal fixture proves
     * exactly that and nothing else.
     */
    const CLEAN_FIXTURE = "node --test scripts/x.test.mjs";
    const OFFENDING_FIXTURE = "node --test build-os/maintenance/";
    assert.ok(
      NODE_TEST.test(CLEAN_FIXTURE),
      `the bare-runner regex does not match ${JSON.stringify(CLEAN_FIXTURE)} — it is blind, ` +
        `and the empty offender list above means nothing`
    );
    assert.ok(
      !THIS_DIR.test(CLEAN_FIXTURE),
      `the directory regex matches ${JSON.stringify(CLEAN_FIXTURE)}, which names another ` +
        `directory entirely — it would report every sibling suite`
    );
    assert.ok(
      NODE_TEST.test(OFFENDING_FIXTURE) && THIS_DIR.test(OFFENDING_FIXTURE),
      `the conjunction does not fire on ${JSON.stringify(OFFENDING_FIXTURE)}, which is the ` +
        `exact shape this scan exists to catch`
    );
  });
});

/* ------------------------------------------------------------------ */
/* THE ROTATION SET, PINNED FROM OUTSIDE THE TOOL                      */
/* ------------------------------------------------------------------ */

const TOOL_NAME = "rotate-memory.mjs";
const TOOL_SRC = fs.readFileSync(path.join(HERE, TOOL_NAME), "utf8");
const STANDING_GATES_REL = "build-os/memory/standing_gates.md";

describe(`the rotation set declared by ${TOOL_NAME}`, () => {
  test(`${STANDING_GATES_REL} is not in it, so the tool cannot rotate a standing gate away`, () => {
    /*
     * Rotation is BY RECENCY ONLY: the tool makes no guarantee about which
     * content survives by meaning. Measured in the reference deployment at
     * commit `cb2bb7d`, 22 of the 24 `HARD STOP` occurrences then live rotated
     * away on a normal run, at exit 0, because that is correct behaviour for a
     * recency rotation. That figure describes that tree, not this one; what is
     * general is that the loss is silent and exits 0. Preservation is
     * therefore a property of LOCATION — a file absent from `FILE_SPECS` is a
     * file this tool never reads, writes or creates. `standing_gates.md` is the
     * path this repo designates for content that must not rotate, and this pin
     * is the only thing standing between "absent by intent" and "absent until
     * someone adds it".
     *
     * READ AS TEXT, NOT IMPORTED. This file never imports rotate-memory.mjs —
     * that invariant is asserted about it by rotate-memory.test.mjs — so the
     * set is extracted from the tool's source the same way the WATCHED list is
     * extracted from run-tests.sh, and pinned against the tripwire's own list
     * so the extraction cannot silently start matching nothing.
     *
     * PINNED AGAINST `ROTATED_MEMORY_FILES`, NOT `REAL_MEMORY_FILES`. Those two
     * were the same list until `standing_gates.md` was put under watch; they are
     * deliberately different now, and the difference is the whole point of this
     * test. The rotation set must stay exactly the three rotating files; the
     * WATCHED/tripwire set is those three PLUS this file. Pinning the extraction
     * against the wider list would have made adding the gates file to the
     * rotation set the way to keep this test green.
     */
    const block = TOOL_SRC.match(/export const FILE_SPECS = \{([\s\S]*?)\n\};/);
    assert.ok(block, `${TOOL_NAME} no longer declares an \`export const FILE_SPECS\` object`);
    const rotated = [...block[1].matchAll(/\bpath:\s*"([^"]+)"/g)].map((m) => m[1]);

    // non-vacuity + drift: the extraction found the real rotation set, and it is
    // exactly the set the tripwire declares as rotating
    assert.deepEqual(
      rotated,
      ROTATED_MEMORY_FILES,
      `the paths extracted from ${TOOL_NAME}'s FILE_SPECS are not the rotation set the ` +
        `tripwire declares. Either the tool's rotation set changed or this extraction went ` +
        `blind; a blind extraction makes the assertion below pass for free.`
    );

    // ...and the two sets really are different, so the pin above is the narrow
    // one: the gates file is watched, and is not rotated.
    assert.deepEqual(
      REAL_MEMORY_FILES.filter((r) => !ROTATED_MEMORY_FILES.includes(r)),
      [STANDING_GATES_REL],
      `the watched set is no longer the rotation set plus exactly ${STANDING_GATES_REL}`
    );

    assert.ok(
      !rotated.includes(STANDING_GATES_REL),
      `${STANDING_GATES_REL} has been added to ${TOOL_NAME}'s FILE_SPECS. That file is the ` +
        `never-rotated home of standing hard stops; putting it in the rotation set makes the ` +
        `one location that was safe by construction rotate like any other, which is the exact ` +
        `failure this path exists to prevent. Revert it and keep the gates out of the tool's ` +
        `blast radius.`
    );
  });
});

/* ------------------------------------------------------------------ */
/* THE STANDING GATES FILE'S OWN ARITHMETIC, AND THE FORWARD MIRROR    */
/* ------------------------------------------------------------------ */

/*
 * WHAT IS PINNED HERE, AND WHAT DELIBERATELY IS NOT.
 *
 * PINNED: the two things that stay enforceable across every future rotation, in
 * any repo, whatever the gates file happens to contain.
 *   1. INTERNAL CONSISTENCY — the counts the file declares about ITSELF match
 *      what it contains, per source file and in total. A file that has not
 *      accumulated any gates yet declares no `## SOURCE:` section, and then what
 *      is checked is that the shipped CONTRACT is intact (see below): the point
 *      is that this arithmetic is never allowed to be decorative.
 *   2. THE FORWARD MIRROR — every line in the LIVE rotating files that STATES a
 *      hard stop is also in this file, verbatim modulo leading whitespace. That
 *      is the direction that matters: rotation deletes by recency, so a gate
 *      written into a rotating file and not copied here is a gate with an expiry
 *      date.
 *
 * NOT PINNED: anything keyed to a particular repo's gate inventory, or to line
 * numbers in the rotating files. Rotation moves those line numbers by
 * construction, so a test asserting them would be asserting a fact about a
 * commit rather than a fact about now.
 *
 * WHY THE CONSISTENCY RULE EXISTS AT ALL, from the reference deployment: its
 * gates file shipped a "24/24" coverage claim in PROSE ONLY — 24 `HARD STOP`
 * lines, 24 entries. Re-counted, the per-source headers declared 24 source lines
 * while the file carried 25 entry blocks, because one entry was a disclosed
 * companion excerpt spelling the gate `HARD-STOP`. Nothing was wrong with the
 * file; one number was standing for two different quantities, and only an
 * executed check could see it.
 *
 * A MISSING GATES FILE IS A REPORTED CONDITION, NOT A CRASH. The installer seeds
 * the template, but a customer may delete it, and this file is read as data at
 * module load — an unguarded read here would take the whole suite down with a
 * stack trace instead of one named failure.
 */

const GATES_PATH = path.join(HERE, "..", "..", STANDING_GATES_REL);
const GATES_SRC = fs.existsSync(GATES_PATH) ? fs.readFileSync(GATES_PATH, "utf8") : null;

/** `### CS-01 — ...` heads an entry block; the first fenced span in it is the excerpt. */
const ENTRY_HEAD = /^### ([A-Z]+-\d+) /;

/**
 * The file's entry blocks, split by `## SOURCE:` section, with each block's
 * declared id and its fenced excerpt.
 */
function gatesSections(src) {
  const lines = src.split("\n");
  const sections = [];
  lines.forEach((line, i) => {
    const head = line.match(
      /^## SOURCE: `([^`]+)` — (\d+) `HARD STOP` line\(s\), (\d+) entry block\(s\)$/
    );
    if (head) {
      sections.push({
        file: head[1],
        declaredHardStopLines: Number(head[2]),
        declaredBlocks: Number(head[3]),
        from: i,
        blocks: [],
      });
    }
  });
  for (let s = 0; s < sections.length; s++) {
    const end = s + 1 < sections.length ? sections[s + 1].from : lines.length;
    let cur = null;
    for (let i = sections[s].from + 1; i < end; i++) {
      const head = lines[i].match(ENTRY_HEAD);
      if (head) {
        cur = { id: head[1], excerpt: [], fences: 0 };
        sections[s].blocks.push(cur);
        continue;
      }
      if (!cur) continue;
      if (lines[i].trim() === "```") {
        cur.fences += 1;
        continue;
      }
      if (cur.fences === 1) cur.excerpt.push(lines[i]);
    }
  }
  return sections;
}

/**
 * Lines that STATE a hard stop, as opposed to lines that merely NAME the token.
 *
 * Inline code spans are blanked before the test, so `` `HARD STOP` `` inside a
 * sentence about the coverage claim is not read as a gate. That distinction is
 * not cosmetic: the rotation packet's own close wrote a follow-up note into
 * `residue.md` that discusses the 24/25 arithmetic, and every occurrence of the
 * token on that line is inside backticks. Counting it would have forced a
 * meta-comment about the gates file to be copied INTO the gates file.
 *
 * NAMED RESIDUAL: a real gate written entirely inside a code span is invisible
 * here. This is a mirror check over prose, not a lexer.
 */
function gateStatingLines(src) {
  const out = [];
  src.split("\n").forEach((raw, i) => {
    if (!raw.includes("HARD STOP")) return;
    if (!raw.replace(/`[^`]*`/g, "").includes("HARD STOP")) return;
    out.push({ at: i + 1, text: raw.replace(/^\s+/, "") });
  });
  return out;
}

/** Gate-stating lines of `live` (rel -> source) that `gatesSrc` does not carry. */
function mirrorGaps(live, gatesSrc) {
  const mirrored = new Set(gatesSrc.split("\n").map((l) => l.replace(/^\s+/, "")));
  const gaps = [];
  for (const [rel, src] of Object.entries(live)) {
    for (const { at, text } of gateStatingLines(src)) {
      if (!mirrored.has(text)) gaps.push(`${rel}:${at}  ${text.slice(0, 120)}`);
    }
  }
  return gaps;
}

/**
 * The five clauses of the shipped CONTRACT that make this file's protection
 * mean anything. Matched against a whitespace-flattened copy, so re-wrapping the
 * prose is allowed and deleting the guarantee is not.
 */
const GATES_CONTRACT_CLAUSES = [
  "THIS FILE IS NEVER ROTATED",
  "THE ROTATION TOOL MUST NEVER INCLUDE THIS FILE IN ITS ROTATION SET",
  "IT IS WATCHED, WHICH IS NOT THE SAME AS PROTECTED",
  "NOTHING HERE IS SATISFIED, RETIRED, OR SUPERSEDED BY BEING WRITTEN DOWN",
  "THIS FILE MUST STAY READABLE IN ONE PASS",
];

describe(`${STANDING_GATES_REL}`, () => {
  test("it exists, and carries the contract that makes it the never-rotated authority", () => {
    assert.ok(
      GATES_SRC !== null,
      `${STANDING_GATES_REL} is missing. It is the never-rotated home of this repo's hard ` +
        `stops, it is watched by the tripwire and by run-tests.sh, and the rotation tool is ` +
        `pinned never to touch it — none of which means anything if the path does not exist. ` +
        `Restore it from build-os/maintenance/templates/standing_gates.md.`
    );
    const flat = GATES_SRC.replace(/\s+/g, " ");
    const missing = GATES_CONTRACT_CLAUSES.filter((c) => !flat.includes(c));
    assert.deepEqual(
      missing,
      [],
      `${STANDING_GATES_REL} no longer states these contract clauses: ${JSON.stringify(missing)}. ` +
        `The contract is what tells the next reader why the file may not be rotated, edited ` +
        `into the rotation set, or treated as a clearance.`
    );
  });

  test("the counts it declares about itself are the counts it contains", () => {
    assert.ok(GATES_SRC !== null, `${STANDING_GATES_REL} is missing`);
    const sections = gatesSections(GATES_SRC);
    /*
     * NO SECTIONS = A FILE THAT HAS NOT ACCUMULATED GATES YET, which is the
     * state every freshly-installed repo starts in. There is no arithmetic to
     * check, and inventing a floor ("at least N gates") would be a pin on how
     * much trouble a repo has had rather than on whether its bookkeeping is
     * honest. The contract test above is what holds in that state; the moment a
     * first `## SOURCE:` section appears, everything below applies to it.
     */
    if (sections.length === 0) {
      assert.doesNotMatch(
        GATES_SRC,
        /^## SOURCE:/m,
        `${STANDING_GATES_REL} carries a \`## SOURCE:\` header this parse could not read. ` +
          `The declared format is: ## SOURCE: \`<path>\` — N \`HARD STOP\` line(s), M entry block(s)`
      );
      return;
    }
    for (const s of sections) {
      assert.ok(
        ROTATED_MEMORY_FILES.includes(s.file),
        `a \`## SOURCE:\` section names ${JSON.stringify(s.file)}, which is not a rotating ` +
          `file. Only content that CAN rotate away needs mirroring here.`
      );
    }

    let totalDeclaredLines = 0;
    let totalBlocks = 0;
    const companions = [];
    for (const s of sections) {
      assert.equal(
        s.blocks.length,
        s.declaredBlocks,
        `${s.file}'s section declares ${s.declaredBlocks} entry block(s) and contains ` +
          `${s.blocks.length}: ${JSON.stringify(s.blocks.map((b) => b.id))}`
      );
      const stating = s.blocks.filter((b) => b.excerpt.join("\n").includes("HARD STOP"));
      assert.equal(
        stating.length,
        s.declaredHardStopLines,
        `${s.file}'s section declares ${s.declaredHardStopLines} \`HARD STOP\` line(s) but ` +
          `${stating.length} of its ${s.blocks.length} excerpts carry that spelling`
      );
      companions.push(...s.blocks.filter((b) => !stating.includes(b)).map((b) => b.id));
      totalDeclaredLines += s.declaredHardStopLines;
      totalBlocks += s.blocks.length;
    }

    /*
     * NON-VACUITY, RELATIVE TO WHAT THE FILE ITSELF DECLARES. A section exists,
     * so it must contain at least one entry block: a `## SOURCE:` header
     * declaring nothing is a heading that says a file has been reviewed while
     * proving nothing about it, and it would satisfy every equality above for
     * free.
     */
    assert.ok(
      totalBlocks >= 1,
      `${sections.length} \`## SOURCE:\` section(s) parsed but 0 entry blocks — either the ` +
        `sections are empty or the block parse went blind, and both make the equalities above ` +
        `pass for nothing.`
    );

    /*
     * The two totals in the COVERAGE paragraph are the two sums, and they can
     * legitimately differ (a companion excerpt is an entry that is not one of the
     * counted source lines). Matched against a whitespace-flattened copy: this is
     * hard-wrapped prose in a file whose whole point is being readable, and a pin
     * that a sentence may not be re-wrapped is a pin on the wrong thing.
     *
     * THE PARAGRAPH IS OPTIONAL, THE ARITHMETIC IS NOT. A repo need not maintain
     * a totals paragraph at all — the shipped template has none — but if it
     * states EITHER total it must state BOTH, and both must be true. Half a
     * summary is exactly the defect this check exists for: one number standing in
     * for two quantities.
     */
    const flat = GATES_SRC.replace(/\s+/g, " ");
    const declaredTotal = flat.match(/contain exactly \*\*(\d+)\*\* lines matching `HARD STOP`/);
    const declaredBlocks = flat.match(/carries \*\*(\d+)\*\* entry blocks/);
    assert.equal(
      Boolean(declaredTotal),
      Boolean(declaredBlocks),
      `the COVERAGE paragraph states one total and not the other (HARD STOP lines: ` +
        `${Boolean(declaredTotal)}, entry blocks: ${Boolean(declaredBlocks)}). State both or ` +
        `neither — a single number standing for two quantities is the original defect.`
    );
    if (declaredTotal) {
      assert.equal(
        Number(declaredTotal[1]),
        totalDeclaredLines,
        `COVERAGE says ${declaredTotal[1]} \`HARD STOP\` lines; the per-source headers sum to ` +
          `${totalDeclaredLines}`
      );
      assert.equal(
        Number(declaredBlocks[1]),
        totalBlocks,
        `COVERAGE says ${declaredBlocks[1]} entry blocks; the file contains ${totalBlocks}`
      );
    }

    /*
     * ...and the difference between the two totals is accounted for BY NAME. The
     * whole defect was a single number standing for two quantities, so the
     * companion entries are not allowed to be an unexplained remainder.
     */
    assert.equal(
      totalBlocks - totalDeclaredLines,
      companions.length,
      `the two totals differ by ${totalBlocks - totalDeclaredLines} but ${companions.length} ` +
        `companion entr(ies) were found: ${JSON.stringify(companions)}`
    );
    for (const id of companions) {
      /*
       * DISCLOSED BY THE WORD `companion`, not by one repo's exact sentence. The
       * reference deployment's disclosure read "it says `HARD-STOP` not `HARD
       * STOP`", which is a fact about that entry; pinning that wording would make
       * every other repo's honest disclosure fail. What must hold everywhere is
       * that an entry which is NOT one of the counted source lines says so, by
       * name, where a reader will see it.
       */
      assert.match(
        flat,
        new RegExp(`### ${id} [^]*?companion`, "i"),
        `${id} is an entry whose excerpt does not carry \`HARD STOP\`, and its own block does ` +
          `not disclose itself as a companion. Every entry that is not one of the counted ` +
          `source lines must say so where a reader will see it.`
      );
    }
  });

  test("every hard stop still live in a rotating file is mirrored here, verbatim", () => {
    assert.ok(GATES_SRC !== null, `${STANDING_GATES_REL} is missing`);
    /*
     * A rotating file that does not exist is skipped, not fatal: a repo may not
     * have scaffolded every path. Zero of them existing IS fatal — the mirror
     * would then be checking nothing at all.
     */
    const live = {};
    for (const rel of ROTATED_MEMORY_FILES) {
      const full = path.join(HERE, "..", "..", rel);
      if (fs.existsSync(full)) live[rel] = fs.readFileSync(full, "utf8");
    }
    assert.ok(
      Object.keys(live).length > 0,
      `none of the rotating files exist (${JSON.stringify(ROTATED_MEMORY_FILES)}), so the ` +
        `forward-mirror check has nothing to read and would pass vacuously`
    );

    const found = Object.entries(live).flatMap(([rel, src]) =>
      gateStatingLines(src).map((g) => `${rel}:${g.at}`)
    );
    assert.deepEqual(
      mirrorGaps(live, GATES_SRC),
      [],
      `a hard stop is stated in a rotating file and is NOT in ${STANDING_GATES_REL}. Rotation ` +
        `deletes by recency, so that gate has an expiry date. Copy the line in verbatim. ` +
        `(${found.length} gate-stating line(s) live right now: ${JSON.stringify(found)}.)`
    );
  });

  test("...and that mirror check reports a gate that is NOT here, from literal fixtures", () => {
    /*
     * NON-VACUITY, SELF-CONTAINED. Driven from fixture strings rather than from
     * whatever the live files happen to contain: after a future rotation the live
     * count may legitimately be zero, and a guard that leaned on it would then
     * either go red for no reason or stop proving anything. These four assertions
     * hold whatever the live tree says.
     */
    assert.ok(GATES_SRC !== null, `${STANDING_GATES_REL} is missing`);
    const NOVEL = "> **A NOVEL HARD STOP THAT NOBODY COPIED INTO THE GATES FILE**";
    assert.deepEqual(
      mirrorGaps({ "fixture.md": `intro\n  ${NOVEL}\n` }, GATES_SRC),
      [`fixture.md:2  ${NOVEL}`],
      "a gate line absent from the gates file was not reported — the mirror check is blind"
    );

    // leading whitespace is not a difference; a line that IS here is not a gap
    const mirroredLine = gateStatingLines(GATES_SRC)[0];
    assert.ok(mirroredLine, `${STANDING_GATES_REL} states no hard stop at all`);
    assert.deepEqual(
      mirrorGaps({ "fixture.md": `\t${mirroredLine.text}\n` }, GATES_SRC),
      [],
      "a line already carried by the gates file was reported as a gap over leading whitespace"
    );

    // the code-span rule, both directions
    assert.equal(gateStatingLines("- a plain HARD STOP sentence\n").length, 1);
    assert.equal(gateStatingLines("- discusses `HARD STOP` as a token only\n").length, 0);
  });
});

/*
 * THE OTHER HALF OF THE CROSS-SCAN IS DELIBERATELY NOT HERE. That THIS file can
 * acquire nothing that starts a process is asserted BY rotate-memory.test.mjs,
 * which reads this file as data. Asserting it here would be this file scanning
 * itself — the shape that needed exemptions and grew holes for five rounds.
 */
