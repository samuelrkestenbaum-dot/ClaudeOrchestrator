/**
 * GRAVITO:MANAGED — shipped by build-os/maintenance/install-maintenance.sh.
 * Edits made in an installed repo are REPLACED on the next install. Change it
 * upstream, or unmanage it by removing the path from .gravito-managed.
 *
 * PURE TEXT FUNCTIONS used by both halves of the cross-scan.
 *
 * -------------------------------------------------------------------------
 * THIS FILE HAS NO IMPORTS, AND THAT IS THE POINT
 * -------------------------------------------------------------------------
 * It takes strings and returns strings, arrays and numbers. It has no binding
 * for the filesystem, for a spawn API, or for anything else: a module that
 * imports nothing and never reaches a global back-door cannot act on the
 * machine at all, whatever is wrong with it.
 *
 * That property is a FLAT COUNT of its own source, asserted by
 * `rotate-memory.rootscan.test.mjs`, which reads this file as data. It needs no
 * exemption span, because the rules are written so that their own text does not
 * satisfy them: each looks for a name IMMEDIATELY FOLLOWED BY `(`, and in a
 * regular-expression source the name is followed by a backslash. That is a real
 * property of the text, not a carve-out, but it is stated here rather than left
 * for a reader to discover.
 *
 * -------------------------------------------------------------------------
 * WHY CONCATENATION FOLDING EXISTS
 * -------------------------------------------------------------------------
 * A scan that looks for a module specifier as a literal token is defeated by
 * writing the specifier in fragments. That is not hypothetical: it is the trick
 * `rotate-memory.rootscan.test.mjs` itself used to keep its own literal count at
 * zero, and it is the trick a review used to obtain a spawn API inside a suite
 * file while every count still read zero.
 *
 * `foldConcatenations` folds adjacent quoted literals joined by `+` to
 * convergence, so a composed specifier is scanned as the string it actually
 * denotes. It preserves BOTH the byte length and the newline count of every
 * span it rewrites, so every line number taken from the folded source is the
 * line number in the original file.
 *
 * WHAT IT DOES NOT FOLD, named: anything computed at run time. `"node:" + mod`,
 * `["chi","ld"].join("")`, `String.fromCharCode(...)` and template literals with
 * substitutions all survive folding unchanged. Folding raises the cost of
 * hiding a specifier from "write it in two pieces" to "compute it"; it does not
 * make hiding impossible. The real-memory tripwire, not this scan, is what
 * bounds what a computed specifier can do.
 */

/*
 * -------------------------------------------------------------------------
 * WHY `maskNonCode` EXISTS
 * -------------------------------------------------------------------------
 * The tripwire's coverage scan used to find a suite file's imports with a
 * LINE-ANCHORED regular expression. The anchor was there for a real reason —
 * every line of a block comment here begins with ` * `, and prose naming an
 * import must not be read as one — but it made every import written at any
 * other column INVISIBLE to the scan while the ESM loader still evaluated it in
 * source order. One leading space was enough to run a payload before the
 * tripwire baselined anything.
 *
 * `maskNonCode` replaces the anchor. It blanks comment, string and template
 * bodies while preserving length and newlines, so a scan can look for the
 * `import` keyword IN CODE CONTEXT at any column and read the specifier back
 * out of the original source by offset.
 *
 * ITS TWO FAILURE DIRECTIONS ARE NOT SYMMETRIC, and that governed its design:
 *   - masking too LITTLE gives a false positive — prose read as an import. The
 *     scan goes red, somebody reads one line, and fixes it.
 *   - masking too MUCH gives a false negative — a real import hidden inside a
 *     span wrongly believed to be a string. That is silent, and it is the exact
 *     class of defect this function was written to remove.
 *
 * IT DOES NOT ACHIEVE THE SECOND, AND THE PREVIOUS VERSION OF THIS COMMENT SAID
 * IT DID. What was written here was: "an unterminated string, template or block
 * comment — the shapes that mean the lexer has lost sync — is a THROW, not a
 * recovery. The one ambiguity it resolves silently is regex-versus-division."
 * The throw is real, but it only fires when a mis-read leaves an ODD number of
 * quotes. Two division-position regexes on one line, each carrying one quote,
 * balance — so nothing is unterminated, nothing throws, and the span BETWEEN
 * them is blanked. Measured, on this exact input:
 *
 *     if (a) /'/.test(b); import "./payload.mjs"; if (c) /'/.test(d);
 *
 * `moduleRequestSpecifiers` returns everything except `./payload.mjs`. The
 * import is real, the ESM loader hoists and runs it, and the scan reports
 * nothing. "The one ambiguity it resolves silently" IS the false-negative
 * direction, not a residual beside it.
 *
 * THIS IS THE THIRD TIME THIS SCAN HAS BEEN DEFEATED — exempt regions that
 * hosted live code, then a `^` anchor beaten by one leading space, then this
 * lexer. The response is not a fourth heuristic. THE SCAN IS BEST-EFFORT: it
 * catches the accidental late import and the honest mistake, and it is not a
 * boundary. What is load-bearing lives outside this process, in
 * `run-tests.sh`'s `--import` preload and its two shell fingerprints, and the
 * exact sentence those two mechanisms buy is written at the top of that file.
 */

/** Occurrences of `needle` in `hay`. */
export function countOf(hay, needle) {
  return hay.split(needle).length - 1;
}

/** 1-based line number of `index` in `src`. */
export function lineNoAt(src, index) {
  return src.slice(0, index).split("\n").length;
}

/** The whole (trimmed) line containing `index`. */
export function lineAt(src, index) {
  const start = src.lastIndexOf("\n", index) + 1;
  const end = src.indexOf("\n", index);
  return src.slice(start, end === -1 ? src.length : end).trim();
}

/**
 * Fold `"a" + "b"` into `"ab"`, repeatedly, until nothing changes.
 *
 * LENGTH- AND NEWLINE-PRESERVING: each rewritten span keeps its original byte
 * length and its original newline count, so offsets after it — and therefore
 * every line number — are unchanged. The folded literal is placed first, the
 * padding spaces next, the newlines last.
 *
 * The pass limit is a LOUD failure, never a silent give-up: each pass that does
 * not converge strictly reduces the number of `+` operators between literals, so
 * the limit is unreachable for any finite input, and reaching it means this
 * function is wrong rather than that the input was clever.
 */
export function foldConcatenations(src, limit = 256) {
  const PAIR = /(["'])([^"'\\\n]*)\1(\s*\+\s*)(["'])([^"'\\\n]*)\4/g;
  let out = src;
  for (let pass = 0; ; pass++) {
    if (pass >= limit) {
      throw new Error(
        `foldConcatenations did not converge in ${limit} passes. Each pass removes at ` +
          `least one string-concatenation operator, so this cannot happen for a finite ` +
          `input: the folder is wrong. Refusing to scan a half-folded source.`
      );
    }
    const next = out.replace(PAIR, (whole, q, a, _gap, _q2, b) => {
      const folded = `${q}${a}${b}${q}`;
      const newlines = countOf(whole, "\n");
      const pad = whole.length - folded.length - newlines;
      return folded + " ".repeat(pad > 0 ? pad : 0) + "\n".repeat(newlines);
    });
    if (next === out) return out;
    out = next;
  }
}

/*
 * A `/` starts a regular-expression literal only in operand position. These two
 * sets are the ordinary lexical heuristic for deciding that from the previous
 * significant token, and they are deliberately CONSERVATIVE about `)` and `]`,
 * which are read as division: `(a + b) / 2` is common and `if (x) /re/.test(y)`
 * is not.
 */
const REGEX_MAY_FOLLOW_PUNCT = new Set(
  ["(", ",", "=", ":", "[", "!", "&", "|", "?", "{", "}", ";", "+", "-", "*", "%", "~", "^", "<", ">", "/"]
);
const REGEX_MAY_FOLLOW_WORD = new Set(
  ["return", "typeof", "instanceof", "in", "of", "new", "delete", "void", "throw",
    "case", "do", "else", "yield", "await"]
);

/** Whether a `/` seen after `prevSig` (last word being `word`) opens a regex. */
function regexMayStart(prevSig, word) {
  if (prevSig === "") return true;
  if (/[\w$]/.test(prevSig)) return REGEX_MAY_FOLLOW_WORD.has(word);
  if (prevSig === ")" || prevSig === "]" || prevSig === '"' || prevSig === "'" || prevSig === "`") {
    return false;
  }
  return REGEX_MAY_FOLLOW_PUNCT.has(prevSig);
}

/**
 * `src` with every comment body, string body and template body replaced by
 * spaces. SAME LENGTH, SAME NEWLINES, delimiters kept, so an offset into the
 * result is the same offset into `src`.
 *
 * Regular-expression literals are recognised and blanked too — not because a
 * scan wants to look inside one, but because `/["']/` holds an unbalanced quote
 * on each side and a lexer that missed it would open a string there and blank
 * whatever real code followed, up to the next quote. That is how a masker hides
 * an import.
 *
 * WHAT IT DOES NOT DECIDE, named:
 *   - A regular expression in a position the heuristic reads as division —
 *     after `)` or `]`, or after an identifier that is not one of the listed
 *     keywords — is left unmasked. Its contents are then scanned as code.
 *   - A `/` in operand position with no closing `/` on the same line is read as
 *     division, because a regex literal cannot span a line.
 *
 * AND HERE IS WHAT THAT COSTS, WHICH THIS COMMENT USED TO GET WRONG. It said:
 * "Neither case is silent for long: an unbalanced quote or comment opener left
 * behind by a mis-read throws below rather than masking on." That is only true
 * when the mis-read leaves the quote count ODD. Two division-position regexes
 * on one line, each carrying one quote, leave it EVEN:
 *
 *     if (a) /'/.test(b); import "./payload.mjs"; if (c) /'/.test(d);
 *
 * The first `'` opens a string, the second closes it, nothing is unterminated,
 * nothing throws — and everything between them, INCLUDING A REAL STATIC IMPORT,
 * is blanked. `moduleRequestSpecifiers` does not return `./payload.mjs`; the
 * loader still runs it. Measured on that literal input.
 *
 * So the false-negative direction is REACHABLE, not bounded away, and no
 * further heuristic is being added to chase it. Callers must treat this as a
 * best-effort convenience scan. `real-memory-tripwire.mjs` states what that
 * means for the coverage check built on it, and `run-tests.sh` states the one
 * guarantee that does not depend on this function at all.
 */
export function maskNonCode(src) {
  const out = src.split("");
  const n = src.length;
  const blank = (from, to) => {
    for (let k = from; k < to; k++) if (out[k] !== "\n") out[k] = " ";
  };
  const die = (what, at) => {
    throw new Error(
      `maskNonCode: unterminated ${what} at line ${lineNoAt(src, at)}: ` +
        `${JSON.stringify(lineAt(src, at))}. A masker that recovers silently from a desync ` +
        `blanks real code and hides real imports, which is the defect it exists to prevent.`
    );
  };

  let i = 0;
  let prevSig = "";
  let word = "";
  while (i < n) {
    const c = src[i];
    const d = i + 1 < n ? src[i + 1] : "";

    if (c === "/" && d === "/") {
      let j = src.indexOf("\n", i);
      if (j === -1) j = n;
      blank(i, j);
      i = j;
      continue;
    }
    if (c === "/" && d === "*") {
      const j = src.indexOf("*/", i + 2);
      if (j === -1) die("block comment", i);
      blank(i, j + 2);
      i = j + 2;
      continue;
    }
    if (c === '"' || c === "'") {
      let j = i + 1;
      for (;;) {
        if (j >= n || src[j] === "\n") die("string literal", i);
        if (src[j] === "\\") {
          j += 2;
          continue;
        }
        if (src[j] === c) break;
        j++;
      }
      blank(i + 1, j);
      i = j + 1;
      prevSig = c;
      word = "";
      continue;
    }
    if (c === "`") {
      let j = i + 1;
      for (;;) {
        if (j >= n) die("template literal", i);
        if (src[j] === "\\") {
          j += 2;
          continue;
        }
        if (src[j] === "`") break;
        j++;
      }
      blank(i + 1, j);
      i = j + 1;
      prevSig = c;
      word = "";
      continue;
    }
    if (c === "/" && regexMayStart(prevSig, word)) {
      let j = i + 1;
      let inClass = false;
      let closed = -1;
      while (j < n && src[j] !== "\n") {
        if (src[j] === "\\") {
          j += 2;
          continue;
        }
        if (src[j] === "[") inClass = true;
        else if (src[j] === "]") inClass = false;
        else if (src[j] === "/" && !inClass) {
          closed = j;
          break;
        }
        j++;
      }
      if (closed !== -1) {
        blank(i + 1, closed);
        i = closed + 1;
        prevSig = "/";
        word = "";
        continue;
      }
      /* no terminator on this line: a regex literal cannot span one, so divide */
    }
    if (c !== " " && c !== "\t" && c !== "\n" && c !== "\r") {
      prevSig = c;
      word = /[\w$]/.test(c) ? word + c : "";
    }
    i++;
  }
  return out.join("");
}

/**
 * Every STATIC MODULE REQUEST's specifier in `src`, in source order, at any
 * column: `import "s"`, `import x from "s"`, and `export { x } from "s"` — a
 * re-export evaluates the module exactly as an import does.
 *
 * Found in a masked copy, so prose and string literals that merely NAME an
 * import are not counted; the specifier itself is read back out of `src` by
 * offset, because in the mask it is blank.
 *
 * A deferred module request — the call form, or one inside a function — is not
 * a static request and is not listed: it cannot run before the static requests
 * above it, which is the only ordering this function is used to decide.
 */
export function moduleRequestSpecifiers(src) {
  const masked = maskNonCode(src);
  const RE = /(?<![\w$.])(?:import|export)(?![\w$])\s*(?:[^;()'"`]*?\bfrom\s*)?(["'])([^"'\n]*)\1/dg;
  const out = [];
  let m;
  while ((m = RE.exec(masked)) !== null) {
    const [start, end] = m.indices[2];
    out.push(src.slice(start, end));
  }
  return out;
}

/**
 * Every static import, dynamic import and require whose specifier contains
 * `token`, as `{ lineNo, line }`.
 *
 * `src` is folded first, so a specifier written in fragments is found.
 */
export function moduleImportsOf(src, token) {
  const folded = foldConcatenations(src);
  const q = `["'][^"'\\n]*${token}[^"'\\n]*["']`;
  const RE = new RegExp(
    `(?<![\\w$])(?:import\\s+[^;\\n]*\\bfrom\\s*${q}|import\\s*\\(\\s*${q}\\s*\\)|` +
      `require\\s*\\(\\s*${q}\\s*\\))`,
    "g"
  );
  const out = [];
  let m;
  while ((m = RE.exec(folded)) !== null) {
    out.push({ lineNo: lineNoAt(folded, m.index), line: lineAt(folded, m.index) });
  }
  return out;
}

/**
 * The ways to obtain a module, or to run code, WITHOUT writing an import or a
 * require of it. Every one of these is reported wherever it appears.
 *
 * This list is what closes the composed-specifier hole at its other end: a scan
 * can be defeated by computing a specifier, but not by computing it AND having
 * no way to hand it to a loader.
 *
 * It is enumerated, not exhaustive — a name is not a proof — and the named
 * residual is stated where it is used.
 */
const INDIRECT_ACQUISITION = [
  [/(?<![\w$.])createRequire\s*\(/g, "a createRequire call builds a require for any specifier, composed or not"],
  [/(?<![\w$.])eval\s*\(/g, "an eval call runs arbitrary source, including an import"],
  [/(?<![\w$])new\s+Function\s*\(/g, "a new Function call compiles arbitrary source"],
  [/(?<![\w$])process\s*\.\s*binding\s*\(/g, "the binding back-door reaches internal modules"],
  [/(?<![\w$])module\s*\.\s*constructor/g, "the CommonJS module constructor exposes a loader"],
];

/** Findings for every indirect module-acquisition or code-compilation shape. */
export function indirectAcquisitionFindings(src, label = "this file") {
  const folded = foldConcatenations(src);
  const findings = [];
  for (const [re, why] of INDIRECT_ACQUISITION) {
    re.lastIndex = 0;
    let m;
    while ((m = re.exec(folded)) !== null) {
      findings.push(
        `${label} line ${lineNoAt(folded, m.index)}: INDIRECT MODULE ACQUISITION — ${why}. ` +
          `line=${JSON.stringify(lineAt(folded, m.index))}`
      );
    }
  }
  return findings;
}

/**
 * Every member accessed on the identifier `binding`, e.g. `fs.readFileSync`.
 * Used to hold a module to a read-only whitelist.
 */
export function membersUsedOn(src, binding) {
  const RE = new RegExp(`(?<![\\w$.])${binding}\\s*\\.\\s*([A-Za-z_$][\\w$]*)`, "g");
  const out = new Set();
  let m;
  while ((m = RE.exec(src)) !== null) out.add(m[1]);
  return out;
}

/**
 * Offsets where `binding` appears as a bare identifier — not as the receiver of
 * a member access. A module that only ever writes `fs.something` cannot pass its
 * filesystem binding anywhere; one that writes a bare `fs` might.
 */
export function bareReferencesTo(src, binding) {
  const RE = new RegExp(`(?<![\\w$.])${binding}(?![\\w$])(?!\\s*\\.)`, "g");
  const out = [];
  let m;
  while ((m = RE.exec(src)) !== null) out.push({ lineNo: lineNoAt(src, m.index), line: lineAt(src, m.index) });
  return out;
}
