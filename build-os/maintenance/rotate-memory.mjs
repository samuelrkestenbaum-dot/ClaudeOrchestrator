/**
 * GRAVITO:MANAGED — shipped by build-os/maintenance/install-maintenance.sh.
 * Edits made in an installed repo are REPLACED on the next install. Change it
 * upstream, or unmanage it by removing the path from .gravito-managed.
 *
 * rotate-memory — ROTATION (not truncation) of Build OS memory files.
 *
 * Invoked through ./rotate-memory.sh. Keeps the newest N blocks live and moves
 * the tail into an append-only archive.
 *
 * -------------------------------------------------------------------------
 * WHAT THIS TOOL GUARANTEES — AND WHAT IT DOES NOT
 * -------------------------------------------------------------------------
 * IT DOES: preserve the newest N blocks per file, BY RECENCY ONLY. Everything
 * older is moved byte-exact into an append-only archive, order preserved within
 * each output.
 *
 * IT PERFORMS GENERATED-BANNER REPLACEMENT. This is deliberately NOT phrased as
 * "it deletes nothing", because on a re-rotation it does consume bytes: exactly
 * one class of byte reaches neither output, and it is stated here rather than
 * glossed. A prior ARCHIVE-POINTER BANNER — bytes THIS TOOL ITSELF generated on
 * an earlier run, sitting in the writer's own anchored slot at the preamble tail
 * — is REPLACED in place by the current run's banner, so those bytes are neither
 * kept live nor archived. The human report names the exact count and withdraws
 * the byte-exact claim on such a run (`prior banner : N B REPLACED in place`);
 * `--json` carries it as `priorBannerBytes`. When it is 0 — every first
 * rotation, and every file whose preamble tail is not a generated banner — every
 * byte of the original is accounted for by exactly one output.
 *
 * "A prior banner" is a MUCH narrower thing than "a marker-paired region". A
 * region is only treated as one if it PARSES as a banner `renderBanner` emits:
 * its exact line count, field labels and prose (see `isRenderedBanner`). Prose
 * a human wrapped in the markers does not parse, is refused, and survives into
 * the live file untouched. Recognising by markers alone destroyed ~200-300 B of
 * hand-authored preamble tail per file, at exit 0, while the report still said
 * `byte-exact`.
 *
 * IT DOES NOT: make ANY guarantee about WHICH CONTENT survives, by meaning,
 * importance, or kind. There is no notion of a protected section. A standing
 * gate, a pending-deploy-go register, a hard stop — if it sits in the archive
 * region it is archived, exactly like any other older content. Measured in the
 * reference deployment at commit `cb2bb7d`, on memory files of ~900/830/705 KB:
 * 22 of the 24 `HARD STOP` occurrences then live rotated away on a normal run,
 * and the run exited 0 because that is correct behaviour for a recency rotation.
 * That number is a property of THAT tree at THAT commit and is quoted only as
 * evidence that the loss is real and silent; it says nothing about yours.
 *
 * CONTENT THAT MUST NEVER ROTATE THEREFORE BELONGS IN A FILE THAT IS NOT LISTED
 * IN `FILE_SPECS`. Preservation is a property of LOCATION, not of text: a file
 * this tool does not know about is a file this tool cannot move. The path
 * designated for that content is `build-os/memory/standing_gates.md` — a path
 * absent from `FILE_SPECS`, which this tool therefore
 * never reads, writes or creates. Whether it exists yet is outside this tool's
 * knowledge and outside its blast radius either way. The Gravito installer seeds
 * a TEMPLATE of that file (`build-os/maintenance/templates/standing_gates.md`),
 * copied only if absent, so a repo that has never used it still has the location.
 *
 * An earlier version tried to protect sections by matching prose headers. That
 * mechanism was circular — the protected span was terminated by the same `^## `
 * delimiter it was meant to override, so a protected body containing a nested
 * `^## ` silently split — and it is deleted rather than re-cut.
 *
 * -------------------------------------------------------------------------
 * THE ONE PRE-WRITE INVARIANT
 * -------------------------------------------------------------------------
 * SEGMENT-PARTITION CONSERVATION — the ordered labelled segment list reproduces
 * the original byte-exact, and every segment is routed to exactly one output.
 * Enforced before any write, for every file, with nothing written for ANY file
 * if any file fails.
 *
 * That invariant runs on the SEGMENTS, i.e. BEFORE composition, and it says
 * nothing about the ORDER of the two outputs relative to each other. Two further
 * checks (section 5) close those two gaps:
 *
 *   ROUTING RECONSTRUCTION (1d) — the retained bytes followed by the archived
 *   bytes must BE the original, compared as strings. Catches an interleaved cut
 *   that every count-based and partition-based check above is blind to.
 *
 *   POST-COMPOSITION BYTE CONSERVATION (2a) — excising exactly the pad and the
 *   banner from the string about to be written must reproduce the live retained
 *   content byte for byte, and any prior-banner bytes composition dropped must
 *   themselves parse as a banner this tool generated. That is what makes success
 *   with byte loss impossible; it does not re-verify the CONTENT of the inserted
 *   banner span, which `renderBanner`'s drift check settles before composition.
 *
 * An earlier version had no post-composition check and lost content silently —
 * an unanchored banner-strip run over every retained segment excised any span
 * that happened to contain the marker pair, and every self-reported number still
 * balanced because they were derived from the already-shortened string.
 *
 * Conservation proves nothing was LOST. It does NOT prove the right thing was
 * RETAINED, and this tool makes no such claim. Because rotation makes a file
 * SHORTER rather than unreadable, the loss it can cause is silent: a session
 * reads a small file and believes it has the whole record. The fixed-SHAPE,
 * bounded ARCHIVE-POINTER BANNER written into the head of every rotated file is
 * what keeps that failure loud — it names the batch, the counts and the exact
 * archive paths, right where the file is read. (Not fixed-SIZE, and "replaced
 * on every apply" holds only while the prior banner still sits in its anchored
 * slot; both qualifications are measured and stated in section 4.)
 */

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

/* ------------------------------------------------------------------ */
/* configuration                                                       */
/* ------------------------------------------------------------------ */

export const DEFAULT_KEEP = 10;
export const DEFAULT_MAX_BYTES = 200 * 1024; // 200 KB

/**
 * THE CLOSE-SIZE BUDGET — DERIVED FROM THIS REPOSITORY'S OWN CLOSES, NOT INVENTED.
 *
 * Refusal condition 7 needs to know how many bytes the packet that is rotating
 * will itself write back into the file afterwards. A rotation that leaves less
 * headroom than the close needs has not solved the problem it was run for; it
 * has moved the breach past the point where this tool can still act, because
 * once a file is over `maxBytes` rotation refuses at EXIT.CEILING.
 *
 * THE NUMBER IS THE LARGEST SINGLE-COMMIT GROWTH ANY FILE IN `FILE_SPECS` HAS
 * EVER TAKEN IN THIS REPOSITORY. Measured, not chosen — the maximum of the
 * positive per-commit byte deltas over each file's whole history:
 *
 *   build-os/memory/current_state.md   62 commits, max +18702  (at `2a3c070`)
 *   build-os/memory/residue.md         61 commits, max +13763
 *   build-os/packets/active_packet.md  39 commits, max +8257
 *
 * The MAXIMUM is used rather than a percentile on purpose: undershooting is the
 * failure mode this condition exists to prevent, and a median close (about 1-3
 * KB here) tells you nothing about the close that actually breaches. Re-derive
 * it rather than trusting the digit — `git log --format=%H -- <path>`, then
 * difference `git cat-file -s` across each consecutive pair.
 *
 * IT IS A DEFAULT, NOT A CONSTANT: `--close-budget N` overrides it explicitly,
 * which is the honest way to carry a number whose provenance is one repository.
 */
export const DEFAULT_CLOSE_BUDGET_BYTES = 18702;

export const EXIT = {
  OK: 0,
  RETENTION: 1,
  USAGE: 2,
  CEILING: 3,
  CONFIG: 4,
  CONSERVATION: 5,
  IO: 6,
  SENTINEL: 7,
};

/**
 * PER-FILE delimiters, ONE ENTRY PER FILE and never one shared regex.
 *
 * ------------------------------------------------------------------------
 * THESE DELIMITERS ARE COUPLED TO THE SCAFFOLD'S MEMORY FORMAT. READ THIS
 * BEFORE CHANGING EITHER SIDE.
 * ------------------------------------------------------------------------
 * A customer's memory files arrive from `init-build-os.sh` / `install-project.sh`,
 * so what counts as a "block" here is decided by the format those scaffolds
 * write. All three scaffolded files use markdown `##` sections, so all three
 * entries below currently carry the SAME regex. That is a fact about the
 * scaffold, NOT a licence to collapse them into one shared constant: the moment
 * one file's convention diverges, its entry changes alone.
 *
 * HOW A MISMATCH FAILS, AND WHY IT IS THE DANGEROUS DIRECTION. A delimiter that
 * matches nothing in a file does not error: the whole file becomes one preamble
 * segment, zero blocks are found, `archived` is empty, and the run is a
 * REPORTED NO-OP at exit 0 — a file that silently never rotates. It is no longer
 * SILENT: when zero blocks are found in a file that has non-whitespace content,
 * a warning naming the file and the delimiter is written to STDERR (see
 * `delimiterMatchedNothing`). The exit code still does not change, because an
 * empty or not-yet-written file parses to zero blocks legitimately and must not
 * fail a run. The reference deployment's `current_state.md` used
 * blockquote `> **LATEST` / `> **PRIOR` entries and its spec's delimiter was
 * `/^> \*\*(LATEST|PRIOR)/`; pointed at a scaffolded `current_state.md` that
 * same regex finds 0 blocks. Measured against the product scaffold before this
 * port: 0 / 0 / 0 blocks under the reference delimiters, versus 3 / 3 / 5 under
 * the ones below.
 *
 * PINNED, NOT TRUSTED: `rotate-memory.rootscan.test.mjs` asserts that each
 * shipped scaffold template yields at least one block under its own spec's
 * delimiter, so this coupling cannot rot silently in either direction.
 *
 * - current_state.md : BROAD `^## ` — the scaffold's section headings
 *                      (`## Project`, `## Where we are`, ...).
 * - residue.md       : BROAD `^## `. Do NOT narrow to `^## PACKET CLOSE`: real
 *                      trees use ~10 other conventions (`## TRUTH-UP`,
 *                      `## PROJECT HANDOFF`, `## MERGED + DEPLOYED`,
 *                      `## <name> residue`, ...) and narrowing drops them into
 *                      the wrong segment.
 * - active_packet.md : BROAD `^## ` (headings likewise vary: `## NO PACKET IN
 *                      FLIGHT`, `## CLOSED`, `## ACTIVE`, `## JUST CLOSED`,
 *                      `## Closed -- <id>`, `## PARALLEL TRACKS`).
 *
 * THIS LIST IS THE ENTIRE BLAST RADIUS. A file absent from it is never read,
 * never planned and never written by this tool -- which is exactly why a file
 * that is not listed here is the correct home for content that must not rotate.
 */
export const FILE_SPECS = {
  current_state: {
    name: "current_state",
    path: "build-os/memory/current_state.md",
    blockDelimiter: /^## /,
  },
  residue: {
    name: "residue",
    path: "build-os/memory/residue.md",
    blockDelimiter: /^## /,
  },
  active_packet: {
    name: "active_packet",
    path: "build-os/packets/active_packet.md",
    blockDelimiter: /^## /,
  },
};

const ARCHIVE_DIR = "build-os/memory/archive";
const INDEX_REL = `${ARCHIVE_DIR}/INDEX.md`;
const TOOL_ID = "build-os/maintenance/rotate-memory.sh";

/* ------------------------------------------------------------------ */
/* byte-domain helpers                                                 */
/* ------------------------------------------------------------------ */

/*
 * All file content is handled as a latin1 string: one JS char == one byte, so
 * slicing and concatenation are byte-exact by construction and independent of
 * whether the source is valid UTF-8. Content written to disk is re-encoded
 * latin1, reproducing the original bytes. Only human/JSON output is decoded.
 */
const toDisplay = (s) => Buffer.from(s, "latin1").toString("utf8");
const toBytes = (s) => Buffer.from(s, "utf8").toString("latin1");
const clip = (s, n) => {
  const d = toDisplay(s);
  return toBytes(d.length > n ? `${d.slice(0, n)}…` : d);
};
const countLines = (s) => {
  let c = 0;
  for (let i = 0; i < s.length; i++) if (s.charCodeAt(i) === 10) c++;
  return c;
};

class RotateError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

/* ------------------------------------------------------------------ */
/* 1. SEGMENTATION                                                     */
/* ------------------------------------------------------------------ */

/**
 * Split `text` into an ordered, labelled segment list: preamble, then
 * block_1..block_N in file order.
 *
 * Pure slicing -- no normalisation, no rewriting, no notion of a special
 * section. Every line that matches the per-file delimiter opens a block; every
 * other byte belongs to whichever segment precedes it.
 */
export function segmentFile(text, spec) {
  const delim = spec.blockDelimiter;
  const segments = [];

  let curStart = 0;
  let curStartLine = 1;
  let curKind = "preamble";
  let curLabel = "preamble";
  let curHeader = null;
  let blockN = 0;

  const close = (endOffset) => {
    const body = text.slice(curStart, endOffset);
    if (curKind === "preamble" && body.length === 0) return;
    segments.push({
      label: curLabel,
      kind: curKind,
      text: body,
      headerLine: curHeader,
      startLine: curStartLine,
      startOffset: curStart,
    });
  };

  const n = text.length;
  let i = 0;
  let lineNo = 0;
  while (i < n) {
    const nl = text.indexOf("\n", i);
    const lineEnd = nl === -1 ? n : nl;
    const next = nl === -1 ? n : nl + 1;
    const line = text.slice(i, lineEnd);
    lineNo++;

    if (delim.test(line)) {
      close(i);
      curStart = i;
      curStartLine = lineNo;
      curHeader = line;
      blockN++;
      curKind = "block";
      curLabel = `block_${blockN}`;
    }
    i = next;
  }
  close(n);
  return segments;
}

/* ------------------------------------------------------------------ */
/* 2. SEGMENT-PARTITION CONSERVATION                                   */
/* ------------------------------------------------------------------ */

/**
 * (a) sum(len(seg)) == len(original)
 * (b) joining the segments IN ORIGINAL ORDER reproduces the original byte-exact
 *
 * Enforced before any write. Throws on violation.
 */
export function assertSegmentPartition(original, segments) {
  const sum = segments.reduce((a, s) => a + s.text.length, 0);
  if (sum !== original.length) {
    throw new RotateError(
      EXIT.CONSERVATION,
      `CONSERVATION FAILED: sum(len(seg)) = ${sum} != len(original) = ${original.length}`
    );
  }
  const joined = segments.map((s) => s.text).join("");
  if (joined !== original) {
    let at = 0;
    while (at < joined.length && joined[at] === original[at]) at++;
    throw new RotateError(
      EXIT.CONSERVATION,
      `CONSERVATION FAILED: rejoined segments are not byte-exact (first divergence at byte ${at})`
    );
  }
  // A third branch used to sit here comparing `Buffer.byteLength(joined,
  // "latin1")` with `Buffer.byteLength(original, "latin1")`. It was DELETED
  // rather than left in place: `Buffer.byteLength(s, "latin1")` is `s.length`
  // for every JS string, and branch (a) has already proved those two lengths
  // equal, so the comparison could not come out false for any input. A guard
  // that cannot fail reads as safety and adds no discriminating power.
  return true;
}

/* ------------------------------------------------------------------ */
/* 3. ROUTING                                                          */
/* ------------------------------------------------------------------ */

/**
 * Route every segment to exactly ONE output: the newest `keepN` blocks (plus
 * the preamble) stay live, the rest go to the archive. Both outputs keep the
 * original segment order.
 */
export function routeSegments(segments, keepN) {
  const isBlock = (s) => s.kind === "block";

  const blocks = segments.filter(isBlock);
  const keep = new Set(blocks.slice(0, Math.max(0, keepN)).map((s) => s.label));

  const retained = segments.filter((s) => !isBlock(s) || keep.has(s.label));
  const archived = segments.filter((s) => isBlock(s) && !keep.has(s.label));

  // every segment appears exactly once across the two outputs
  const labels = [...retained, ...archived].map((s) => s.label);
  if (labels.length !== segments.length) {
    throw new RotateError(
      EXIT.CONSERVATION,
      `ROUTING FAILED: ${labels.length} routed segments != ${segments.length} source segments`
    );
  }
  const seen = new Set(labels);
  if (seen.size !== segments.length) {
    throw new RotateError(EXIT.CONSERVATION, "ROUTING FAILED: a segment was routed twice");
  }
  for (const s of segments) {
    if (!seen.has(s.label)) {
      throw new RotateError(EXIT.CONSERVATION, `ROUTING FAILED: ${s.label} was routed nowhere`);
    }
  }
  return { retained, archived };
}

/* ------------------------------------------------------------------ */
/* 4. THE ARCHIVE-POINTER BANNER                                       */
/* ------------------------------------------------------------------ */

/*
 * Before rotation, an over-limit memory file fails to Read and the session
 * KNOWS it is blind -- a loud failure. After rotation the same file reads fine
 * and the session believes it has the whole record -- a silent one. The banner
 * is what keeps it loud: fixed-SHAPE and bounded, sitting immediately after the
 * preamble where the file is read, and REPLACED rather than accumulated on
 * every apply -- with one qualification, stated below because it is real.
 *
 * NOT "fixed-size": the template is a fixed 10 lines, but it interpolates
 * decimal counts, so its byte length moves with their digits -- 503-513 B
 * measured over the runs described here (513/507/513 across the three files at
 * keep=10, and 507 down to 503 across the successive rotations below). Fixed
 * SHAPE, bounded by BANNER_MAX_LINES; it does not grow with how much rotated
 * away.
 *
 * AND "replaced" HOLDS ONLY WHILE THE PRIOR BANNER STILL OCCUPIES ITS ANCHORED
 * SLOT. The strip below is positional, so a later edit can displace a banner out
 * of that slot without altering a byte of it -- insert a block immediately after
 * the end-marker and the blank line the banner owns is consumed. `stripTrailing-
 * Banner` then REFUSES rather than replaces -- that refusal is the whole point
 * of the recogniser, whose own comment already calls the cost "additive" (see
 * `isRenderedBanner`) -- and the next apply appends its banner beside the
 * displaced one instead of over it.
 *
 * WHAT THAT COSTS, MEASURED, NOT ARGUED: ONE orphaned banner (~505 B) PER
 * DISPLACING EDIT -- and rotation alone never adds another. No source bytes are
 * lost: the orphan and the displacing edit are both preserved intact. The new
 * banner lands correctly at the anchored slot and is replaced normally by every
 * subsequent run, so repeated rotation is bounded at two banners and does not
 * reach three. (Read the bound exactly: it is per displacement, not for all
 * time. A SECOND edit that displaces the new banner the same way buys a second
 * orphan. What is ruled out is unbounded growth from rotating, which is the
 * thing that would actually accumulate.) Measured on a rotated copy of this
 * repo's memory: refusal once (priorBannerBytes 0), then four further rotations
 * each reporting a replacement (505/505/504/503 B), with the marker count pinned
 * at 2 and the orphan's bytes untouched throughout. The real harm is not size --
 * it is that the orphan keeps STALE counts from the rotation that wrote it while
 * still reading as authoritative. Pinned by "a banner displaced out of its
 * anchored slot is REFUSED, and the orphan is bounded at one" in the suite.
 *
 * The markers are HTML comments so the banner is invisible in rendered
 * markdown, unambiguous to locate, and impossible to mistake for content. They
 * are chosen NOT to match any delimiter in FILE_SPECS, so on the next run the
 * banner is absorbed into the preamble segment and never parsed as a block --
 * an invariant re-checked after composition, below.
 *
 * ------------------------------------------------------------------------
 * THE STRIP IS POSITIONAL, NEVER A SEARCH
 * ------------------------------------------------------------------------
 * A banner is only a banner if it sits EXACTLY where this file's writer puts
 * one: as the byte-exact TAIL of the preamble segment, opened by a
 * line-anchored BANNER_START, closed by the PAIRED line-anchored BANNER_END,
 * carrying its own terminating newline and the single blank line separating it
 * from the first live block, and bounded by BANNER_MAX_LINES.
 *
 * ...AND IT MUST PARSE. Position and pairing are necessary but NOT sufficient.
 * The region must additionally parse as bytes `renderBanner` really emits --
 * exact line count, exact field labels, exact prose (`isRenderedBanner`).
 * Without that last gate, ~200-300 B of a human's own marker-wrapped note at
 * the preamble tail was consumed into neither output at exit 0. "Looks like a
 * banner" is not a licence to delete; only "is one this tool wrote" is.
 *
 * Every other occurrence of either marker anywhere in the file -- inside a
 * retained block, inside a fenced code block, an unpaired marker, a marker in
 * the archive region, a hand-authored paired region at the preamble tail, or a
 * block whose bytes are an exact copy of a rendered banner -- IS CONTENT and is
 * preserved untouched.
 *
 * This is the whole defect class: an unanchored `indexOf(BANNER_START)` applied
 * to content silently excises the span between the markers, and it lands in
 * neither output. There must be no unanchored marker search anywhere in the
 * composition path.
 */
export const BANNER_START = "<!-- rotate-memory:archive-pointer:start -->";
export const BANNER_END = "<!-- rotate-memory:archive-pointer:end -->";
export const BANNER_MAX_LINES = 12;

/** The exact bytes a rendered banner ends with -- marker line, then a blank line. */
const BANNER_TAIL = `${BANNER_END}\n\n`;

/* The fixed prose lines of a rendered banner. Named so `renderBanner` and
 * `isRenderedBanner` cannot drift apart by an edit to one of them.
 *
 * THIS TEXT IS WRITTEN INTO BUILD OS MEMORY ITSELF, so it is the one place an
 * overclaim does the most damage. It used to read "nothing was deleted", full
 * stop -- an unqualified claim, and false on a re-rotation, where this tool
 * consumes the previous run's banner bytes. It now says exactly what holds: no
 * SOURCE CONTENT was moved out of both outputs, and the one thing replaced is
 * this tool's own generated banner. */
const BANNER_RECENCY_1 = "- rotation is by RECENCY ONLY. Older does not mean less important. No source";
const BANNER_RECENCY_2 =
  "  content was deleted; only a prior banner THIS TOOL generated was replaced.";
const BANNER_INDEX_LINE = `- index: \`${INDEX_REL}\``;
const BANNER_HEADLINE_RE =
  /^\*\*THIS FILE IS NOT THE WHOLE RECORD\.\*\* \d+ older blocks \(\d+ B\) were rotated out of it; \d+ newest blocks \(\d+ B\) remain here\.$/;
const BANNER_BATCH_RE = /^- batch: `[^`\n]+`$/;
const BANNER_ARCHIVE_RE = new RegExp(
  `^- archive: \`${ARCHIVE_DIR.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}/[A-Za-z0-9_]+\\.archive\\.md\`$`
);

/**
 * Does `text` parse as a banner THIS TOOL'S `renderBanner` actually emits?
 *
 * PAIRED MARKERS ARE NOT ENOUGH, and treating them as enough is a data-loss
 * bug: a human note wrapped in the documented markers at the tail of a preamble
 * satisfied "paired, line-anchored, <= 12 lines" and was consumed into neither
 * output. A rendered banner is machine-generated with a known exact structure,
 * so the recogniser demands that structure and refuses everything else. Refusal
 * costs an un-replaced banner (loud, visible, additive); acceptance costs
 * somebody's bytes (silent, permanent). The tie breaks towards refusing.
 *
 * This is an INDEPENDENT recogniser: it calls neither `findTrailingBanner` nor
 * `stripTrailingBanner`, which is what lets the post-composition check use it to
 * audit what the strip removed instead of the strip agreeing with itself.
 * `renderBanner` asserts its own output parses here, so drift between the two
 * fails loudly at EXIT.CONFIG on the very next run rather than silently
 * widening or narrowing what counts as a banner.
 */
export function isRenderedBanner(text) {
  // 9 content lines, the blank line the banner owns, and the empty tail element
  const lines = text.split("\n");
  if (lines.length !== 11) return false;
  if (lines[0] !== BANNER_START) return false;
  if (!BANNER_HEADLINE_RE.test(lines[1])) return false;
  if (lines[2] !== "") return false;
  if (!BANNER_BATCH_RE.test(lines[3])) return false;
  if (!BANNER_ARCHIVE_RE.test(lines[4])) return false;
  if (lines[5] !== BANNER_INDEX_LINE) return false;
  if (lines[6] !== BANNER_RECENCY_1) return false;
  if (lines[7] !== BANNER_RECENCY_2) return false;
  if (lines[8] !== BANNER_END) return false;
  if (lines[9] !== "" || lines[10] !== "") return false;
  return true;
}

/**
 * Locate a banner occupying the exact tail of `text`, or return null.
 *
 * Returns `{ start, end }` with `end === text.length` always: by construction
 * the only banner this tool recognises is a suffix. Anchoring is checked in
 * both directions -- a bare `lastIndexOf` would be just as unsafe as the
 * `indexOf` it replaces.
 */
export function findTrailingBanner(text) {
  if (!text.endsWith(BANNER_TAIL)) return null;

  // the closing marker must occupy a whole line of its own
  const endAt = text.length - BANNER_TAIL.length;
  if (endAt !== 0 && text[endAt - 1] !== "\n") return null;

  // Pair it with the NEAREST preceding opening marker. Where several opening
  // markers could pair with this closing one, the innermost is the SMALLEST
  // region that could be a banner, so choosing it removes the fewest bytes.
  // Every tie in this function breaks towards destroying less.
  const start = text.lastIndexOf(BANNER_START, endAt);
  if (start === -1) return null;

  // ...which must itself be a whole line, at a line boundary
  if (start !== 0 && text[start - 1] !== "\n") return null;
  if (text[start + BANNER_START.length] !== "\n") return null;

  // ...with no stray CLOSING marker inside the region. That would mean this
  // closing marker is not the one that pairs with this opening marker, and the
  // extent is ambiguous -- so refuse and leave every byte alone.
  // (A stray OPENING marker inside is impossible: `start` is the last one.)
  if (text.slice(start + BANNER_START.length, endAt).includes(BANNER_END)) return null;

  // ...and within the fixed-size bound the banner is guaranteed to obey
  if (countLines(text.slice(start)) > BANNER_MAX_LINES) return null;

  // ...and, DECISIVELY, the region must parse as bytes this tool rendered.
  // Everything above is about WHERE the region sits; this is about WHAT IT IS.
  // A human's marker-wrapped note passes every positional check and fails here,
  // which is the difference between preserving 197 B of somebody's prose and
  // eating it.
  if (!isRenderedBanner(text.slice(start))) return null;

  return { start, end: text.length };
}

/**
 * Remove a trailing banner from a PREAMBLE segment. Returns the remaining text
 * and the exact number of bytes removed (0 when there was no banner), so the
 * caller can account for them rather than infer them by subtraction.
 */
export function stripTrailingBanner(text) {
  const at = findTrailingBanner(text);
  if (at === null) return { text, bannerBytes: 0 };
  return { text: text.slice(0, at.start), bannerBytes: at.end - at.start };
}

function renderBanner({ batchId, name, archivedBlocks, archivedBytes, retainedBlocks, contentBytes }) {
  const archiveRel = `${ARCHIVE_DIR}/${name}.archive.md`;
  const banner = toBytes(
    `${BANNER_START}\n` +
      `**THIS FILE IS NOT THE WHOLE RECORD.** ${archivedBlocks} older blocks ` +
      `(${archivedBytes} B) were rotated out of it; ${retainedBlocks} newest blocks ` +
      `(${contentBytes} B) remain here.\n` +
      `\n` +
      `- batch: \`${batchId}\`\n` +
      `- archive: \`${archiveRel}\`\n` +
      `${BANNER_INDEX_LINE}\n` +
      `${BANNER_RECENCY_1}\n` +
      `${BANNER_RECENCY_2}\n` +
      `${BANNER_END}\n\n`
  );
  /*
   * A `countLines(banner) > BANNER_MAX_LINES` gate used to sit here. It was
   * DELETED. The template above is a fixed 10 lines and every interpolated value
   * is a number or an ISO batch id, none of which can contain a newline, so
   * `10 > 12` could not come out true for any input. The edit it claimed to stop
   * -- growing the template by a line -- is stopped by the drift check below,
   * whose recogniser requires exactly 11 split elements, and that check is
   * DRIVEN by a test in both directions. A gate that only duplicates a tested
   * one, and only in the cases the tested one already covers, is not safety.
   */
  /*
   * The writer and the recogniser must agree, ALWAYS. `isRenderedBanner` is what
   * licenses this tool to drop a prior banner's bytes; if an edit here made the
   * emitted shape something the recogniser no longer accepts, the next run would
   * quietly stop replacing banners and start stacking them. Fail at CONFIG on
   * this run instead, before anything is written.
   */
  if (!isRenderedBanner(banner)) {
    throw new RotateError(
      EXIT.CONFIG,
      `BANNER SHAPE DRIFT: renderBanner emitted bytes that isRenderedBanner refuses. ` +
        `The writer and the recogniser must be edited together — the recogniser is what ` +
        `permits a prior banner's bytes to be dropped, so they may never disagree.`
    );
  }
  return banner;
}

/**
 * Compose the bytes that will be written to the live file: retained segments in
 * original order, with a PRIOR banner removed from the tail of the preamble --
 * and ONLY from there -- and the new one placed at that same anchored offset.
 * Replacement, never accumulation.
 *
 * Every non-preamble segment is copied through byte-for-byte. Nothing in this
 * function searches content for a marker.
 *
 * The caller re-derives the expected result independently and refuses to write
 * unless it matches byte for byte (see `planFile`); this function is not
 * trusted on its own.
 */
export function composeRetained(retainedSegments, banner) {
  const parts = retainedSegments.map((s) => s.text);
  if (banner === "") return parts.join("");
  const idx = retainedSegments.findIndex((s) => s.kind === "preamble");
  if (idx === -1) return banner + parts.join("");
  const strip = stripTrailingBanner(parts[idx]);
  const head = strip.text + (strip.text.length > 0 && !strip.text.endsWith("\n") ? "\n" : "");
  parts[idx] = head + banner;
  return parts.join("");
}

/* ------------------------------------------------------------------ */
/* 4b. THE ROTATION SENTINEL                                           */
/* ------------------------------------------------------------------ */

/*
 * WHAT THIS IS, AND WHAT IT IS NOT.
 *
 * Everything above rotates BY RECENCY and says so: "IT DOES NOT: make ANY
 * guarantee about WHICH CONTENT survives, by meaning, importance, or kind."
 * That statement is still true of the routing. The sentinel does not change it.
 * It adds ONE thing, in front of the routing, and refuses rather than reroutes:
 *
 *   minimum_safe_keep = max( block position of every protected or still-open object )
 *
 * and any requested `--keep` below that value is REFUSED BEFORE MUTATION. The
 * tool still keeps a prefix; it now knows how short a prefix it is allowed to
 * keep. A refusal is the whole remedy — the sentinel never silently raises N,
 * because auto-correcting a dangerous request is how a guard becomes invisible.
 *
 * WHY IT EXISTS. The first governed rotation of a real memory file in this
 * repository was safe because a HUMAN read the open-item markers, found the
 * oldest, and derived `--keep 25` by hand. That rule was then written down as
 * prose, which recorded the knowledge and enforced nothing:
 * `DEFECT-0014-retention-order-assumed-not-verified` is the standing entry for
 * exactly that gap. This is the enforcement, and it is deliberately in THIS
 * file rather than in a new validator: a guard that lives beside the routing it
 * guards cannot be forgotten at the call site.
 *
 * -------------------------------------------------------------------------
 * IT RESOLVES BY IDENTITY. IT DOES NOT TRUST WHERE A MARKER SITS.
 * -------------------------------------------------------------------------
 * This is the single most important property here and it is not decorative.
 * A protection marker is a sentence ABOUT an object; it is not the object. In
 * this repository's own `residue.md` the marker "IS NOT CONSUMED AND MUST NOT
 * BE MARKED SO" for `(ddd)` sits in BLOCK 15, while `(ddd)` is DECLARED in
 * BLOCK 16. A scan that takes the marker's own block derives 15, permits
 * `--keep 15`, and archives the object it was built to protect — at exit 0.
 *
 * That is this tree's named recurring defect class: a POSITIONAL fact reported
 * as a SEMANTIC one. It has already cost three separate instruments reporting
 * 1 / 2 / 31 citation breaks when the true count was 0, each because it
 * conflated positional shift with identity. A guard built to prevent an
 * archiving accident must not commit the very error that produces one, so:
 *
 *   - a marker NAMES identities (a backticked letter tag, or any stable id);
 *   - each named identity is resolved to the block that DECLARES it;
 *   - an identity a marker names and no block declares is a REFUSAL, NOT A
 *     SKIP — the guard cannot prove which block holds an object it cannot
 *     find, so it cannot prove any keep protects it;
 *   - and a marker additionally anchors at its OWN owner (the declaration it
 *     sits under, or failing that its own block), so a marker that names
 *     nothing still protects the thing it is written on.
 *
 * The two anchorings are a MAX, never an either/or: naming another object
 * widens the protected set, it never narrows it.
 *
 * -------------------------------------------------------------------------
 * RESOLUTION IS CROSS-FILE OVER THE GOVERNED MEMORY SET — AND WAS NOT
 * -------------------------------------------------------------------------
 * THIS PARAGRAPH USED TO SAY THE OPPOSITE, and the change is a SPEC REVISION
 * rather than a fix, so the old text is described rather than merely replaced.
 * It said: "No block declares it" means NO BLOCK OF THE FILE CURRENTLY BEING
 * PLANNED... an object that legitimately LIVES ELSEWHERE and is merely CITED
 * here is indistinguishable, to this scan, from an object that has gone
 * missing. Both refuse. It then recorded the cost and routed the widening to
 * the operator instead of taking it.
 *
 * THE COST WAS REAL AND WAS PAID. `SENTINEL-C2` is keep-independent, so NO
 * `--keep` clears it: `build-os/packets/active_packet.md` refused at every legal
 * N because it cites `(S1)` and `(ddd)`, which `build-os/memory/residue.md`
 * declares. Nothing was wrong with the record and the file could not rotate.
 *
 * "No block declares it" NOW MEANS: no file in `GOVERNED_IDENTITY_SET` declares
 * it. Section 4c holds the resolver. Three things follow, and only the third
 * can lower a floor:
 *
 *   - a citation of a sibling-declared object RESOLVES instead of refusing;
 *   - the sibling's LIVE marker PROTECTS the declaring block in the owning
 *     file, which the single-file scan did not do at all;
 *   - a structurally QUOTED marker whose every named identity is declared in
 *     ANOTHER governed file no longer anchors at the block doing the quoting.
 *
 * WHAT STILL REFUSES, UNCHANGED: an identity NO governed file declares (C2),
 * and — new with the widening — an identity TWO governed files both declare
 * (C8). The set itself is deliberately narrow: it is not "the repository", so
 * an object whose only record lives outside it, such as
 * `build-os/registry/defect_classes.txt`, still refuses at C2. Admitting a new
 * file to the set is the next spec revision and it is an operator decision.
 *
 * -------------------------------------------------------------------------
 * ARMING IS EXPLICIT, AND AN UNARMED SENTINEL SAYS SO
 * -------------------------------------------------------------------------
 * A file in which the scan resolves ZERO protected objects is UNARMED: a
 * scaffolded repo, a generated fixture, a memory file that has not yet grown a
 * standing region. Conditions 1, 2 and 3 are then vacuous by construction (no
 * objects, no identities, nothing to strand), and conditions 5 and 7 — the
 * pre-registration requirement and the close budget — are NOT applied, because
 * both are governance obligations about a governed memory file and imposing
 * them on a blank scaffold would break every honest caller.
 *
 * THAT IS EXACTLY THE SHAPE OF A GUARD THAT DEGRADES TO NOTHING WITHOUT SAYING
 * SO, so it says so: an unarmed file raises `SENTINEL NOT ARMED` on STDERR,
 * the same way `delimiterMatchedNothing` refuses to let a silent no-op read as
 * success. Conditions 4 and 6 are cross-checks on the tool's own arithmetic and
 * run for every file, armed or not.
 */

/** The stable identity families this tree mints, longest alternative first. */
const SENTINEL_ID_FAMILIES =
  "SIGNAL-SNAPSHOT|OCCURRENCE|DECISION|DEFECT|PACKET|DISP|EVT|HOF|ANC|ART|ACT|CTX|MUT|OBJ|REL|NS|EV";

export const SENTINEL_ID_RE = new RegExp(`\\b(?:${SENTINEL_ID_FAMILIES})-\\d{4}\\b`, "g");

/*
 * THE LETTER-TAG FAMILY, AND WHY IT IS ONLY READ INSIDE BACKTICKS.
 *
 * This tree names residue items `(a)`..`(zzzzzz)` and the operator decision
 * `(S1)`. Read bare, that pattern also matches ordinary English parentheticals
 * — `(ci)`, `(see)`, `(and)` — and every false positive becomes a REFUSAL
 * under the unresolvable rule, which would jam the tool on prose. This tree
 * cites a tag in backticks every time it means the object (`(ddd)`, `(S1)`),
 * so the backtick is the disambiguator, measured rather than assumed.
 *
 * A DECLARATION is matched WITHOUT the backtick requirement, because a
 * declaration opens a bullet: `- **(ddd) ...`.
 */
export const SENTINEL_NAMED_TAG_RE = /`\((S\d+|[a-z]{1,6})\)/g;
/*
 * THE DECLARATION FORM REQUIRES A **BARE** TAG, AND THE BACKTICK THAT USED TO BE
 * OPTIONAL HERE WAS THE DEFECT.
 *
 * The comment above already states this tree's convention: a BACKTICKED tag is a
 * CITATION of an object, a BARE tag opening a bold bullet is its DECLARATION.
 * This pattern then wrote `\`?` and accepted both, which collapsed the very
 * distinction the comment draws. Measured on the live tree, not argued:
 * `build-os/packets/active_packet.md:558` reads ``- **`(ddd)` STAYS QUEUED**``
 * — a citation — and was indexed as a DECLARATION of `(ddd)`, while `(ddd)` is
 * really declared at `build-os/memory/residue.md:1711` as `- **(ddd) THE ...`.
 * One object, two "canonical" declarations, in two files, purely because of an
 * optional backtick.
 *
 * IT IS TIGHTENED RATHER THAN WIDENED, and the direction matters: a form this
 * no longer accepts becomes an UNRESOLVED identity, which REFUSES. Narrowing a
 * declaration recogniser can cost a refusal; widening one costs an archived
 * object. The tie breaks the same way it does everywhere else in this file.
 */
export const SENTINEL_DECL_RE = new RegExp(
  `^\\s*[-*]\\s+\\*\\*(?:\\((S\\d+|[a-z]{1,6})\\)|((?:${SENTINEL_ID_FAMILIES})-\\d{4}))`
);

/* ------------------------------------------------------------------ */
/* 4c. CROSS-FILE IDENTITY RESOLUTION                                  */
/* ------------------------------------------------------------------ */

/*
 * WHY THIS EXISTS, AND WHAT IT DELIBERATELY DOES NOT DO.
 *
 * Resolution used to be SINGLE-FILE SCOPED, and the section above states the
 * cost in terms: "an object that legitimately LIVES ELSEWHERE and is merely
 * CITED here is indistinguishable, to this scan, from an object that has gone
 * missing. Both refuse." `SENTINEL-C2` is keep-independent, so NO `--keep`
 * clears it — a file that only cites open objects it does not own could not
 * rotate at all, at any N, forever.
 *
 * THIS IS NOT A WEAKENING OF C2. C2 still refuses an identity nothing declares;
 * it now looks in the whole GOVERNED MEMORY SET before saying so. Two new things
 * follow, and both INCREASE what is protected:
 *
 *   - a live reference in file A to an object declared in file B now PROTECTS
 *     B's declaring block. Before, that reference produced a refusal on A and no
 *     protection at all on B.
 *   - an identity with canonical declarations in TWO governed files is
 *     AMBIGUOUS and refuses at C8, rather than being resolved by picking one.
 *
 * THE ONE THING THAT LOWERS A FLOOR IS THE QUOTED-REFERENCE DEMOTION, AND ITS
 * FAILURE DIRECTION IS STATED PLAINLY BELOW rather than left to be discovered.
 *
 * -------------------------------------------------------------------------
 * STRUCTURE, NEVER VOCABULARY — AND THIS IS A MEASURED LESSON
 * -------------------------------------------------------------------------
 * `PACKET-0042` shipped a live-vs-quoted guard keyed on six withdrawal-marker
 * WORDS occurring on the same line. Executed probes killed it in both
 * directions: a LIVE assertion that happened to contain `no longer` passed
 * GREEN (fail-OPEN), and a REWORDED cap was invisible to it entirely. A word
 * list is a guess about how humans write; it is not a property of the text.
 *
 * Everything here reads STRUCTURE instead: fenced-code state, blockquote depth,
 * matched inline-code spans, matched quotation spans, the declaration FORM, and
 * the `## ARCHIVED BATCH` heading THIS TOOL ITSELF writes. None of it consults a
 * word list, and none of it can be defeated by rewording.
 */

/**
 * The GOVERNED MEMORY IDENTITY SET — the only files identity is resolved across.
 *
 * IT IS NOT "THE REPOSITORY". A whole-tree scan would make every receipt, every
 * changelog entry and every test fixture a potential declaration, and the first
 * false declaration silently lowers a floor. The set is the rotating memory
 * files plus the never-rotated gates file, and nothing else.
 *
 * ONE MEMBER IS DECLARED AND WITHHELD, AND THE REASON IS A PINNED CONTRACT
 * RATHER THAN AN OVERSIGHT. `build-os/memory/standing_gates.md` belongs in this
 * set by design — it is where permanent obligations are supposed to live. It is
 * NOT read, because this tool's own shipped documentation states, in the header,
 * in `rotate-memory.sh` and in `--help`, that it "never reads, writes or
 * creates" that path, and `rotate-memory.test.mjs` asserts that exact phrase in
 * all three places. Reading it would falsify a customer-visible claim while
 * every one of those assertions stayed green — which is precisely the shape this
 * repository keeps paying for. Admitting it is an OPERATOR decision: retract the
 * claim first, then flip `read`. Until then the boundary is declared here, is
 * reported on every run, and is not taken silently.
 */
export const GOVERNED_IDENTITY_SET = [
  { name: "residue", path: "build-os/memory/residue.md", read: true },
  { name: "current_state", path: "build-os/memory/current_state.md", read: true },
  { name: "active_packet", path: "build-os/packets/active_packet.md", read: true },
  {
    name: "standing_gates",
    path: "build-os/memory/standing_gates.md",
    read: false,
    /*
     * WORDED TO AVOID `retention` AND `pinned`, ON PURPOSE. This string is
     * printed on EVERY run, and `rotate-memory.test.mjs` asserts that no output
     * of this tool contains either word — because both are the vocabulary of a
     * meaning guarantee this tool does not make. The constraint is real and the
     * wording obeys it rather than arguing with it.
     */
    withheld:
      "declared in the governed identity set and NOT read: this tool's own documentation " +
      "states it never reads, writes or creates this path, and rotate-memory.test.mjs asserts " +
      "that phrase in the tool, the wrapper and the --help text. Retracting the claim is an " +
      "operator act, so the boundary is declared here instead of being crossed quietly.",
  },
];

/** The five outcomes an identity occurrence can have. Reported verbatim. */
export const IDENTITY_CLASS = {
  DECLARATION: "DECLARATION",
  LIVE_REFERENCE: "LIVE_REFERENCE",
  QUOTED_REFERENCE: "QUOTED_REFERENCE",
  HISTORICAL_REFERENCE: "HISTORICAL_REFERENCE",
  UNRESOLVED: "UNRESOLVED",
};

/**
 * A block heading THIS TOOL writes into an archive file. A declaration sitting
 * under one is a COPY of a declaration, never the declaration itself.
 *
 * It is deliberately the tool's OWN generated heading and not a guess at what
 * "historical" prose looks like. Measured on this tree, the guess would have
 * been catastrophic: `build-os/memory/residue.md` blocks 4..25 are ALL headed
 * `## History — ...`, and blocks 25 holds the still-open `(o)` and `(S1)`. A
 * rule that demoted "History" headings would have archived both at exit 0.
 */
export const SENTINEL_ARCHIVED_BLOCK_RE = /^##\s+ARCHIVED BATCH\b/;

/** A fenced-code opener/closer, at any indent. */
const FENCE_RE = /^\s*(?:```|~~~)/;

/**
 * Per-line "is this line inside a MATCHED fenced code block?".
 *
 * ONLY A MATCHED PAIR OPENS A QUOTED REGION. An unterminated fence at EOF opens
 * nothing, so a stray triple-backtick cannot silently demote the whole tail of a
 * memory file. That is the fail-CLOSED direction and it is the reason for the
 * two-pass shape below rather than a single running toggle.
 */
export function fencedLineFlags(lines) {
  const flags = new Array(lines.length).fill(false);
  let open = -1;
  for (let i = 0; i < lines.length; i++) {
    if (!FENCE_RE.test(lines[i])) continue;
    if (open === -1) {
      open = i;
    } else {
      for (let j = open; j <= i; j++) flags[j] = true;
      open = -1;
    }
  }
  return flags;
}

/**
 * Matched inline-code spans and matched quotation spans on one line, as
 * half-open `[start, end)` index ranges.
 *
 * MATCHED, NOT COUNTED: an ODD number of backticks (or of quotation marks)
 * yields NO span of that kind for the line at all. An unbalanced delimiter is
 * ambiguous, and the tie breaks towards treating the text as live.
 */
export function quotedSpans(line) {
  const spans = [];
  for (const ch of ["`", '"']) {
    const at = [];
    for (let i = 0; i < line.length; i++) if (line[i] === ch) at.push(i);
    if (at.length % 2 !== 0) continue;
    for (let k = 0; k + 1 < at.length; k += 2) spans.push([at[k], at[k + 1] + 1]);
  }
  return spans;
}

/** Is index `at` inside any of `spans`? */
export function isInSpans(spans, at) {
  for (const [s, e] of spans) if (at >= s && at < e) return true;
  return false;
}

/**
 * Classify every line of `text` structurally, once, so nothing downstream has to
 * re-derive it: which block it is in, whether it is fenced, whether it is a
 * blockquote, and whether its block is an archived batch.
 */
export function structuralLineMap(text, spec) {
  const lines = text.split("\n");
  const fenced = fencedLineFlags(lines);
  const blockOfLine = [];
  const archived = new Array(lines.length).fill(false);
  let blockNo = 0;
  let blockArchived = false;
  for (let i = 0; i < lines.length; i++) {
    /*
     * BLOCK NUMBERING IS FENCE-INSENSITIVE, AND DELIBERATELY SO. It must agree
     * with `segmentFile`, which is what ROUTING is built from and which counts a
     * delimiter line wherever it appears. A fence-aware count here would produce
     * block positions the routing does not share, and the floor would then name
     * a block number that means something different to the two halves of the
     * tool. Fence state is used for QUOTATION decisions only.
     */
    if (spec.blockDelimiter.test(lines[i])) {
      blockNo++;
      blockArchived = SENTINEL_ARCHIVED_BLOCK_RE.test(lines[i]);
    }
    blockOfLine.push(blockNo);
    archived[i] = blockNo >= 1 && blockArchived;
  }
  const quoted = lines.map((l, i) => fenced[i] || /^\s*>/.test(l));
  return { lines, fenced, quoted, archived, blockOfLine };
}

/**
 * The canonical DECLARATIONS a single governed file makes.
 *
 * A line is a declaration only when it matches the (bare-tag) declaration form,
 * sits inside a block, and is neither structurally quoted nor inside an archived
 * batch. Within one file the DEEPEST declaration wins, unchanged: retention is a
 * prefix, so the deepest anchor is the only one that retains every copy.
 */
export function declarationsIn(text, spec, precomputedMap) {
  const map = precomputedMap ?? structuralLineMap(text, spec);
  const declaredAt = new Map();
  map.lines.forEach((line, i) => {
    const m = SENTINEL_DECL_RE.exec(line);
    if (!m) return;
    if (map.quoted[i] || map.archived[i]) return;
    const id = m[1] ? `(${m[1]})` : m[2];
    const at = map.blockOfLine[i];
    if (at >= 1 && (!declaredAt.has(id) || declaredAt.get(id).block < at)) {
      declaredAt.set(id, { block: at, line: i + 1 });
    }
  });
  return declaredAt;
}

/**
 * Build the cross-file declaration index over the governed set.
 *
 * Returns `{ index, sources, withheld, missing }`. `index` maps a stable id to
 * EVERY governed file that canonically declares it — a list rather than a single
 * winner, because two entries is an ambiguity to be refused (C8), not a
 * tie-break to be taken.
 *
 * A governed file that is absent from `root` is recorded and skipped: a
 * scaffolded repo, a generated fixture and a scratch root all legitimately carry
 * only one of them, and refusing there would break every honest caller.
 */
export function buildIdentityIndex(root, readFile) {
  const index = new Map();
  const sources = [];
  const withheld = [];
  const missing = [];
  for (const gov of GOVERNED_IDENTITY_SET) {
    if (!gov.read) {
      withheld.push({ path: gov.path, reason: gov.withheld });
      continue;
    }
    const full = path.join(root, gov.path);
    let text;
    try {
      text = readFile ? readFile(full) : fs.readFileSync(full).toString("latin1");
    } catch {
      missing.push(gov.path);
      continue;
    }
    /*
     * THE SPEC COMES FROM `FILE_SPECS` AND IS NEVER INVENTED HERE. A fallback
     * delimiter would be a SECOND definition of how a memory file is blocked,
     * sitting outside the one list that is pinned from outside the tool, and the
     * two would drift the first time a file's convention changed. A governed
     * entry marked `read` with no spec is a CONFIG error, not a default.
     */
    const spec = FILE_SPECS[gov.name];
    if (!spec) {
      throw new RotateError(
        EXIT.CONFIG,
        `GOVERNED_IDENTITY_SET marks "${gov.name}" (${gov.path}) as readable but FILE_SPECS ` +
          `declares no block delimiter for it. Identity resolution needs the SAME segmentation ` +
          `the routing uses; inventing one here would create a second, drifting definition.`
      );
    }
    const decls = declarationsIn(text, spec);
    sources.push({ name: gov.name, path: gov.path, declarations: decls.size });
    for (const [id, where] of decls) {
      if (!index.has(id)) index.set(id, []);
      index.get(id).push({ file: gov.name, path: gov.path, block: where.block, line: where.line });
    }
  }
  return { index, sources, withheld, missing };
}

/**
 * Every protection marker a governed file OTHER than `spec` carries that names
 * an identity `spec` canonically declares.
 *
 * THIS IS THE INBOUND HALF, and it is what makes the resolution safe rather than
 * merely permissive. Under the single-file scan, `file A says (qqq) must not be
 * consumed` and `file B declares (qqq)` produced a REFUSAL on A and NO
 * PROTECTION AT ALL on B — the object was unprotected in the only file that
 * could archive it. Now the marker protects B's declaring block.
 *
 * QUOTED markers are excluded here for the same reason they are excluded from
 * anchoring in their own file: a narrative about a past fixture is not a
 * liveness claim, and it must not become one by crossing a file boundary.
 */
export function inboundProtections(root, spec, index, readFile) {
  const found = [];
  for (const gov of GOVERNED_IDENTITY_SET) {
    if (!gov.read || gov.name === spec.name) continue;
    const full = path.join(root, gov.path);
    let text;
    try {
      text = readFile ? readFile(full) : fs.readFileSync(full).toString("latin1");
    } catch {
      continue;
    }
    // Same rule as `buildIdentityIndex`: the segmentation is FILE_SPECS' or
    // there is none. `buildIdentityIndex` has already refused a readable
    // governed entry with no spec, so reaching this line without one is
    // impossible; the guard is a skip rather than a second error path.
    const otherSpec = FILE_SPECS[gov.name];
    if (!otherSpec) continue;
    const map = structuralLineMap(text, otherSpec);
    map.lines.forEach((line, i) => {
      if (map.blockOfLine[i] < 1) return;
      for (const marker of SENTINEL_MARKERS) {
        const hit = marker.re.exec(line);
        if (!hit) continue;
        if (markerIsQuoted(line, hit.index, map, i)) continue;
        const named = new Set();
        for (const m of line.matchAll(SENTINEL_ID_RE)) named.add(m[0]);
        for (const m of line.matchAll(SENTINEL_NAMED_TAG_RE)) named.add(`(${m[1]})`);
        for (const id of named) {
          const owners = index.get(id) ?? [];
          const here = owners.filter((o) => o.file === spec.name);
          if (owners.length !== 1 || here.length !== 1) continue;
          found.push({
            id,
            kind: marker.kind,
            block: here[0].block,
            line: here[0].line,
            named_in: gov.path,
            named_at_line: i + 1,
          });
        }
      }
    });
  }
  return found;
}

/**
 * Is the marker occurrence at `index` on this line structurally QUOTED?
 *
 * Three structural facts, no vocabulary: the line is inside a matched fence, the
 * line is a blockquote, or the marker phrase itself falls inside a matched
 * inline-code span or a matched quotation span.
 *
 * THE FAILURE DIRECTION, NAMED. This predicate is the only thing here that can
 * LOWER a floor, so it is the only one that can fail OPEN, and it does so in
 * exactly one shape: a LIVE, floor-raising marker that a human wrote inside
 * backticks or inside quotation marks. That is why the demotion it feeds is
 * additionally conditioned (see `scanProtectedObjects`) on every identity the
 * marker names resolving to a canonical declaration in ANOTHER governed file —
 * so the object is still protected where it lives, and the only thing lost is
 * protection of the block doing the quoting. A quoted marker that names nothing,
 * or names something this file declares, or names something nothing declares,
 * anchors exactly as it always did.
 */
export function markerIsQuoted(line, at, map, i) {
  if (map.quoted[i]) return true;
  return isInSpans(quotedSpans(line), at);
}

/**
 * The protection vocabulary, as this repository actually writes it.
 *
 * Every entry was taken from a marker that occurs in the live memory files, not
 * invented: the list is short on purpose. A wide vocabulary produces false
 * positives, every false positive is a refusal, and a guard that refuses
 * everything is uninstalled within a week.
 */
export const SENTINEL_MARKERS = [
  { kind: "non-consumable", re: /IS NOT CONSUMED AND MUST NOT BE MARKED SO/ },
  { kind: "still-open", re: /\bSTILL OPEN\b/ },
  { kind: "stays-open", re: /\bSTAYS OPEN\b/ },
  { kind: "remains-open", re: /\bREMAINS OPEN\b/ },
  { kind: "open-standing", re: /\bOPEN as a standing\b/ },
  { kind: "operator-decision", re: /\bOPERATOR DECISION\b/ },
  { kind: "non-archivable", re: /\b(?:MUST NOT BE ARCHIVED|NON-ARCHIVABLE|MUST NOT ROTATE)\b/ },
];

/*
 * ONE CANDIDATE MARKER WAS MEASURED AND THEN REJECTED, AND IT IS RECORDED HERE
 * RATHER THAN QUIETLY OMITTED.
 *
 * `awaiting explicit go` was in this list. It is a real phrase — this
 * repository's `residue.md` carries a whole block headed
 * `## Open boundaries (awaiting explicit go)`. It was removed because a HEADING
 * names a SECTION KIND, not the status of the objects inside it, and this
 * repository's own generated fixtures reuse that heading verbatim
 * (`rotate-memory.test.mjs`'s 114-block residue fixture cycles nine real
 * heading conventions including that one). Measured: with it in the list, six
 * synthetic blocks in a fixture whose bodies read "- residue line for block N"
 * were protected, `minimum_safe_keep` came out 107 of 114, and 38 tests in the
 * shipped suite failed on a rotation that endangers nothing.
 *
 * WHAT IT COSTS, STATED RATHER THAN GLOSSED: nothing measurable on this tree.
 * `residue.md`'s open-boundaries block is block 3 and the floor there is 25, so
 * the phrase never moved the answer. Protection is decided by the OBJECTS a
 * block holds. The only headings that protect on their own are the ones that
 * say so — see `SENTINEL_PROTECTED_HEADING_RE`.
 */

/** A block heading that declares its whole block protected. */
export const SENTINEL_PROTECTED_HEADING_RE = /^##\s+(?:Standing\b|.*PROTECTED REGION)/;

/**
 * Literals other suites read out of these files with `head -n1`, so an archived
 * FIRST occurrence would silently re-point the guard that reads them. A pin
 * that is absent from a file is recorded as `absent` and is NOT a refusal:
 * rotation cannot archive a literal the file does not contain.
 */
export const SENTINEL_GATE_PINS = {
  residue: [
    { literal: "license model", ci: true },
    { literal: "no tags", ci: true },
    { literal: "single-platform", ci: true },
  ],
  current_state: [
    { literal: "**Build/test command:**", ci: false },
    { literal: "**Last closed packet:**", ci: false },
  ],
  active_packet: [],
};

/**
 * An INDEPENDENT block map, derived by its own line scan rather than by reusing
 * `segmentFile`'s output.
 *
 * That independence is the entire point: refusal condition 4 compares this map
 * with the segments the plan was built from, so a defect in either one is
 * caught by the other. Reusing `segmentFile` here would produce a check that
 * agrees with itself, which is the shape this file has already deleted twice.
 */
export function sentinelBlockMap(text, spec) {
  const delim = spec.blockDelimiter;
  const map = [];
  let i = 0;
  let lineNo = 0;
  const n = text.length;
  while (i < n) {
    const nl = text.indexOf("\n", i);
    const lineEnd = nl === -1 ? n : nl;
    const line = text.slice(i, lineEnd);
    lineNo++;
    if (delim.test(line)) {
      if (map.length > 0) map[map.length - 1].endOffset = i;
      map.push({
        index: map.length + 1,
        header: line,
        startOffset: i,
        startLine: lineNo,
        endOffset: n,
      });
    }
    i = nl === -1 ? n : nl + 1;
  }
  return map;
}

/**
 * Resolve every protected object in `text` to the block that holds it.
 *
 * Returns `{ objects, unresolvable }`. `objects` carries one record per
 * protected object with the block position it resolved to and the evidence that
 * put it there; `unresolvable` carries every identity a marker named that no
 * block declares. Both are reported in full — nothing is dropped silently,
 * which is what "a REFUSAL, not a skip" means in practice.
 */
export function scanProtectedObjects(text, spec, resolution) {
  const map = structuralLineMap(text, spec);
  const { lines, blockOfLine } = map;
  const crossIndex = resolution?.index ?? new Map();

  /*
   * (1) THE DECLARATION INDEX FOR THIS FILE — derived by `declarationsIn`, the
   *     SAME function the cross-file index is built from.
   *
   *     IT IS ONE FUNCTION AND NOT TWO COPIES, deliberately. An inlined second
   *     copy of the deepest-declaration rule would let this file's own view of
   *     who declares what drift from the view every OTHER file gets of it, and
   *     the two would then disagree about ownership without anything failing.
   *     It also keeps the rule at exactly one site, which is what the suite's M4
   *     mutation fixture depends on to be able to break it.
   */
  const declaredAt = declarationsIn(text, spec, map);

  const objects = [];
  const unresolvable = [];
  const crossFileResolved = [];
  const quotedReferences = [];
  const ambiguous = [];
  const seen = new Set();
  const add = (id, kind, block, line, resolution) => {
    const key = `${id}|${kind}|${block}`;
    if (seen.has(key)) return;
    seen.add(key);
    objects.push({ id, kind, block_position: block, evidence_line: line, resolution });
  };

  // (2) STRUCTURAL: a block whose own heading declares it protected.
  lines.forEach((line, i) => {
    if (blockOfLine[i] >= 1 && SENTINEL_PROTECTED_HEADING_RE.test(line)) {
      add(`PROTECTED-REGION:block_${blockOfLine[i]}`, "protected-region", blockOfLine[i], i + 1, "heading");
    }
  });

  /*
   * (3) GATE PINS: literals other suites read out of this file with `head -n1`,
   *     so the FIRST occurrence is the one that must not move — an archived
   *     first occurrence silently re-points that reader at whatever comes next,
   *     or at nothing.
   *
   * THEY ARE ARMED ONLY IN A FILE THAT HAS DECLARED A STANDING REGION, and that
   * qualification is load-bearing rather than decorative. The pins are required
   * to live INSIDE the standing region and nowhere else — that is exactly what
   * `tests/build_os_maintenance_tests.sh` sections 8(d) and 9(d) assert. A file
   * with no standing region has not been governed yet: in the SHIPPED SCAFFOLD
   * these two literals are template placeholders sitting in blocks 1 and 2 of a
   * three-block file, and arming on them there would set a floor of 2 on memory
   * that carries nothing worth protecting. Measured: doing so broke the
   * two-pass rotation proof in `rotate-memory.test.mjs` on a scaffold whose
   * `**Last closed packet:**` line reads "none — no packet has closed".
   *
   * A pin that is ABSENT is recorded and skipped, not refused: rotation cannot
   * archive a literal the file does not contain.
   */
  const hasStandingRegion = objects.some((o) => o.kind === "protected-region");
  for (const pin of (hasStandingRegion ? SENTINEL_GATE_PINS[spec.name] : undefined) ?? []) {
    const needle = pin.ci ? pin.literal.toLowerCase() : pin.literal;
    let at = -1;
    for (let i = 0; i < lines.length; i++) {
      const hay = pin.ci ? lines[i].toLowerCase() : lines[i];
      if (hay.includes(needle)) { at = i; break; }
    }
    if (at === -1) continue;
    if (blockOfLine[at] >= 1) {
      add(`GATE-PIN:${pin.literal}`, "gate-pin", blockOfLine[at], at + 1, "first-occurrence");
    }
  }

  // (4) MARKERS, resolved BY IDENTITY and, separately, by ownership.
  lines.forEach((line, i) => {
    const block = blockOfLine[i];
    if (block < 1) return;
    for (const marker of SENTINEL_MARKERS) {
      const hit = marker.re.exec(line);
      if (!hit) continue;
      const quoted = markerIsQuoted(line, hit.index, map, i);

      // (4a) identities this marker NAMES
      const named = new Set();
      for (const m of line.matchAll(SENTINEL_ID_RE)) named.add(m[0]);
      for (const m of line.matchAll(SENTINEL_NAMED_TAG_RE)) named.add(`(${m[1]})`);
      // Every named identity that resolved to a single canonical declaration in
      // ANOTHER governed file. This is the set the quoted demotion below is
      // conditioned on, so it is computed whether or not the marker is quoted.
      const resolvedElsewhere = new Set();
      for (const id of named) {
        const decl = declaredAt.get(id);
        if (decl) {
          add(id, marker.kind, decl.block, decl.line, "declaration");
          continue;
        }
        const owners = (crossIndex.get(id) ?? []).filter((o) => o.file !== spec.name);
        if (owners.length === 1) {
          resolvedElsewhere.add(id);
          crossFileResolved.push({
            id,
            kind: marker.kind,
            classification: IDENTITY_CLASS[quoted ? "QUOTED_REFERENCE" : "LIVE_REFERENCE"],
            named_at_line: i + 1,
            named_in_block: block,
            declared_in: owners[0].file,
            declared_path: owners[0].path,
            declared_block: owners[0].block,
            declared_line: owners[0].line,
          });
          continue;
        }
        if (owners.length > 1) {
          ambiguous.push({
            id,
            kind: marker.kind,
            named_at_line: i + 1,
            named_in_block: block,
            claimants: owners.map((o) => `${o.file} (${o.path}) block ${o.block} line ${o.line}`),
            reason:
              "this identity is canonically DECLARED in more than one governed memory file, so " +
              "no single block owns it and the guard cannot say which one retention must reach. " +
              "Ambiguous ownership is refused rather than tie-broken: picking one claimant is " +
              "how a guard silently strands the other",
          });
          continue;
        }
        unresolvable.push({
          id,
          kind: marker.kind,
          named_at_line: i + 1,
          named_in_block: block,
          classification: IDENTITY_CLASS.UNRESOLVED,
          reason:
            "a protection marker names this identity and NO FILE IN THE GOVERNED MEMORY SET " +
            "declares it, so the block that holds the object cannot be established at all. " +
            "Resolution is CROSS-FILE over the governed set and this identity was not found in " +
            "any of it, so this is not the old single-file blind spot: it is a genuinely " +
            "missing declaration. Two things resolve it — declare the object in a governed " +
            "memory file, or stop marking it protected here. (A third case is possible and is " +
            "NOT silently covered: an object whose record lives OUTSIDE the governed set, such " +
            "as a registry file. Admitting a new file to the set is a spec revision and an " +
            "operator decision, not something this tool takes on its own.)",
        });
      }

      /*
       * (4b) THE MARKER'S OWN ANCHOR — with the ONE demotion this change adds.
       *
       * A marker that is structurally QUOTED and whose every named identity is
       * canonically declared in ANOTHER governed file does not anchor here: the
       * object is protected where it lives, and the block doing the quoting is
       * not where it lives. That is what stops a packet or history block from
       * raising a floor solely because it CONTAINS the text.
       *
       * EVERY OTHER CASE ANCHORS EXACTLY AS BEFORE — a quoted marker that names
       * nothing, or names something THIS file declares, or names something no
       * governed file declares. The tie breaks towards protecting.
       */
      if (quoted && named.size > 0 && [...named].every((id) => resolvedElsewhere.has(id))) {
        quotedReferences.push({
          kind: marker.kind,
          classification: IDENTITY_CLASS.QUOTED_REFERENCE,
          line: i + 1,
          block,
          names: [...named],
          reason:
            "the marker phrase sits inside a matched code span, quotation, fence or blockquote, " +
            "and every identity it names is canonically declared in another governed file, so " +
            "this occurrence is a QUOTATION of a protection rather than an assertion of one",
        });
        continue;
      }

      let owner = null;
      for (let j = i; j >= 0 && blockOfLine[j] === block; j--) {
        const m = SENTINEL_DECL_RE.exec(lines[j]);
        if (m) { owner = m[1] ? `(${m[1]})` : m[2]; break; }
      }
      if (owner) {
        const decl = declaredAt.get(owner) ?? { block, line: i + 1 };
        add(owner, marker.kind, decl.block, decl.line, "owning-declaration");
      } else {
        add(`BLOCK:${block}`, marker.kind, block, i + 1, "owning-block");
      }
    }
  });

  // (5) INBOUND: markers in OTHER governed files naming identities THIS file
  //     declares. Protection follows the object, so it lands on the block that
  //     actually holds it rather than on the block that talks about it.
  for (const p of resolution?.inbound ?? []) {
    add(p.id, p.kind, p.block, p.line, `cross-file (named in ${p.named_in}:${p.named_at_line})`);
  }

  objects.sort((a, b) => a.block_position - b.block_position || a.id.localeCompare(b.id));
  return {
    objects,
    unresolvable,
    declaredAt,
    crossFileResolved,
    quotedReferences,
    ambiguous,
    identitySources: resolution?.sources ?? [],
    identityWithheld: resolution?.withheld ?? [],
    identityMissing: resolution?.missing ?? [],
  };
}

/**
 * `max( block position of every protected or still-open object )`, or 0 when
 * the file carries none (an UNARMED file).
 */
export function deriveMinimumSafeKeep(scan) {
  let max = 0;
  for (const o of scan.objects) if (o.block_position > max) max = o.block_position;
  return { minimumSafeKeep: max, armed: scan.objects.length > 0 };
}

function sentinelRefusalLines(path, s) {
  const L = [];
  L.push(`SENTINEL REFUSED — ${path}. Nothing was written, for this file or any other.`);
  L.push(`  requested_keep            ${s.requested_keep}`);
  L.push(`  minimum_safe_keep         ${s.minimum_safe_keep}`);
  L.push(`  protected_object_ids      ${s.protected_object_ids.join(", ") || "(none)"}`);
  L.push(`  protected_block_positions ${s.protected_block_positions.join(", ") || "(none)"}`);
  L.push(`  blocks_to_archive         ${s.blocks_to_archive}`);
  L.push(`  bytes_to_reclaim          ${s.bytes_to_reclaim}`);
  L.push(`  post_rotation_headroom    ${s.post_rotation_headroom}`);
  for (const r of s.refusals) L.push(`  ${r.code}: ${r.detail}`);
  return L.join("\n");
}

/**
 * Evaluate all eight refusal conditions and return the sentinel report.
 *
 * IT WAS SEVEN. C8 arrived with cross-file resolution and could not have existed
 * before it: an identity two governed files both declare is a failure mode a
 * single-file scan had no way to see.
 *
 * EVERY violated condition is reported, not just the first. Reporting only the
 * first turns a fix round into a queue: the operator repairs one thing, re-runs,
 * and is handed the next — which is exactly how a fix list arrives in
 * installments. The conditions are also deliberately overlapping, so more than
 * one firing at once is normal rather than a sign of double-counting.
 */
export function evaluateSentinel(input) {
  const {
    spec, scan, requestedKeep, archivedBlocks, archivedBytes, retainedBytes,
    maxBytes, closeBudget, apply, preRegistration, mapAgreement, restorationOk,
  } = input;

  const derived = deriveMinimumSafeKeep(scan);
  // NAMED AND ASSIGNED ON ITS OWN LINE so a mutation fixture can suppress it and
  // prove that conditions 3, 4 and 6 are not merely shadowed by condition 1.
  const sentinelFloor = derived.minimumSafeKeep;

  const refusals = [];
  const s = {
    armed: derived.armed,
    requested_keep: requestedKeep,
    minimum_safe_keep: sentinelFloor,
    protected_object_ids: [...new Set(scan.objects.map((o) => o.id))],
    protected_block_positions: [...new Set(scan.objects.map((o) => o.block_position))].sort((a, b) => a - b),
    blocks_to_archive: archivedBlocks,
    bytes_to_reclaim: archivedBytes,
    post_rotation_headroom: maxBytes - retainedBytes,
    close_budget_bytes: closeBudget,
    protected_objects: scan.objects,
    unresolvable_identities: scan.unresolvable,
    /*
     * THE CROSS-FILE HALF OF THE REPORT. It is printed and carried in `--json`
     * for the same reason the floor is printed on an allowed run: a resolution
     * nobody can see is indistinguishable from a resolution that did not happen,
     * and this one LOWERS refusals, so it is the half most in need of an audit
     * trail. `identity_set_withheld` names the governed file that was NOT read.
     */
    cross_file_resolutions: scan.crossFileResolved ?? [],
    quoted_references: scan.quotedReferences ?? [],
    ambiguous_identities: scan.ambiguous ?? [],
    identity_sources: scan.identitySources ?? [],
    identity_set_withheld: scan.identityWithheld ?? [],
    identity_set_missing: scan.identityMissing ?? [],
    refusals,
    verdict: "ALLOW",
  };

  // C1 — the rule itself.
  if (requestedKeep < sentinelFloor) {
    refusals.push({
      condition: 1,
      code: "SENTINEL-C1",
      detail:
        `requested --keep ${requestedKeep} is BELOW the derived minimum_safe_keep ${sentinelFloor}. ` +
        `Retention is a PREFIX, so every block from ${requestedKeep + 1} to the end would be ` +
        `archived, and a protected or still-open object is anchored at block ${sentinelFloor}. ` +
        `N is NOT auto-raised: re-run with --keep ${sentinelFloor} or higher, or close the object.`,
    });
  }

  // C2 — a protected identity that cannot be resolved.
  if (scan.unresolvable.length > 0) {
    refusals.push({
      condition: 2,
      code: "SENTINEL-C2",
      detail:
        `${scan.unresolvable.length} protected identity/identities cannot be resolved to a block in ` +
        `${spec.path}: ${scan.unresolvable.map((u) => `${u.id} (named at line ${u.named_at_line})`).join(", ")}. ` +
        `An unresolvable identity is a REFUSAL, not a skip. THE SCAN IS CROSS-FILE over the ` +
        `governed memory set (${(scan.identitySources ?? []).map((x) => x.path).join(", ") || "none readable"}` +
        `${(scan.identityWithheld ?? []).length ? `; WITHHELD: ${scan.identityWithheld.map((w) => w.path).join(", ")}` : ""}` +
        `), and the identity was found in NONE of it — so this is a genuinely missing ` +
        `declaration, not the old single-file blind spot. Two remedies: (a) declare the object ` +
        `in a governed memory file; or (b) stop marking it protected here. A third case exists ` +
        `and is NOT covered silently: an object whose only record lives OUTSIDE the governed ` +
        `set, such as a registry file. Admitting a file to that set widens what "resolve" ` +
        `means, which is a spec revision and an operator decision, not something this tool ` +
        `takes on its own.`,
    });
  }

  // C3 — an open object would move to the archive. Derived from the ROUTING that
  //      is actually about to happen, not from the floor, so it still fires when
  //      the floor is wrong.
  const stranded = scan.objects.filter((o) => o.block_position > requestedKeep);
  if (stranded.length > 0) {
    refusals.push({
      condition: 3,
      code: "SENTINEL-C3",
      detail:
        `${stranded.length} protected object(s) sit in blocks this rotation would ARCHIVE: ` +
        `${stranded.map((o) => `${o.id}@block ${o.block_position} (${o.kind})`).join(", ")}. ` +
        `Moving an open object into an append-only archive is an operator act, not a tool's.`,
    });
  }

  // C4 — the block map and the live file disagree.
  if (!mapAgreement.ok) {
    refusals.push({
      condition: 4,
      code: "SENTINEL-C4",
      detail:
        `the independently-derived block map and the segments this plan was built from disagree ` +
        `for ${spec.path}: ${mapAgreement.detail}. Every block position above is measured against ` +
        `a map that does not describe the file, so none of them can be trusted.`,
    });
  }

  // C5 — the apply was not pre-registered.
  if (apply && derived.armed) {
    if (!preRegistration) {
      refusals.push({
        condition: 5,
        code: "SENTINEL-C5",
        detail:
          `this --apply over a file carrying ${scan.objects.length} protected object(s) was NOT ` +
          `pre-registered. Pass --pre-registration <file> naming { file, keep, sourceSha256 }, ` +
          `written and committed BEFORE the apply, so the ordering is checkable from the tree ` +
          `rather than from the builder's word for it.`,
      });
    } else if (!preRegistration.ok) {
      refusals.push({
        condition: 5,
        code: "SENTINEL-C5",
        detail: `the pre-registration does not bind this run: ${preRegistration.detail}`,
      });
    }
  }

  // C6 — deterministic restoration cannot be proved.
  if (!restorationOk.ok) {
    refusals.push({
      condition: 6,
      code: "SENTINEL-C6",
      detail:
        `deterministic restoration cannot be proved for ${spec.path}: ${restorationOk.detail}. ` +
        `The archive is the only copy of what leaves, so a move that cannot be reversed on paper ` +
        `is not a move this tool will make.`,
    });
  }

  /*
   * C7 — the projected result cannot absorb the packet's own close.
   *
   * THE REMEDY IS ORDERED BY WHAT IS ACTUALLY FOLLOWABLE, which the first
   * wording got backwards. It led with "lower --keep", and on a file whose
   * floor equals its block count there IS no lower keep: every one of them
   * trips C1 immediately, so the advice sent the reader into a second refusal.
   * `--close-budget` leads, and the dead end is named rather than left to be
   * discovered.
   */
  if (derived.armed && s.post_rotation_headroom < closeBudget) {
    const atFloor = requestedKeep <= sentinelFloor;
    refusals.push({
      condition: 7,
      code: "SENTINEL-C7",
      detail:
        `the projected result leaves ${s.post_rotation_headroom} B of headroom under the ` +
        `${maxBytes} B ceiling, which does not cover the ${closeBudget} B close budget. A rotation ` +
        `that does not leave room for its own close moves the breach past the point where this ` +
        `tool can still act — past the ceiling it refuses at EXIT.CEILING. ` +
        (atFloor
          ? `THIS REQUEST IS ALREADY AT OR BELOW THE FLOOR (minimum_safe_keep ${sentinelFloor}), ` +
            `SO THERE IS NO LOWER --keep TO TRY: every one of them trips SENTINEL-C1. Set ` +
            `--close-budget deliberately if the real close is smaller than ${closeBudget} B; ` +
            `otherwise ROTATION CANNOT RELIEVE THIS FILE AT ALL and the content has to go ` +
            `somewhere rotation is not the answer to — close the open objects, or move them to ` +
            `the head of the file so the tail becomes archivable.`
          : `Set --close-budget deliberately if the real close is smaller than ${closeBudget} B, ` +
            `or lower --keep — but not below minimum_safe_keep ${sentinelFloor}, which leaves ` +
            `${requestedKeep - sentinelFloor} step(s) of room.`),
    });
  }

  /*
   * C8 — ONE STABLE IDENTITY, TWO CANONICAL DECLARATIONS, TWO GOVERNED FILES.
   *
   * This condition exists BECAUSE cross-file resolution exists: widening the
   * search from one file to four creates a failure mode one file could not have
   * — an identity two files both claim to own. There is no safe tie-break.
   * Choosing the deeper block is meaningless across files (block 6 of one file
   * and block 6 of another are unrelated positions), and choosing either
   * claimant silently strands the other, which is the exact harm the deepest-
   * declaration rule exists to prevent WITHIN a file.
   *
   * IT IS NOT GATED ON `armed`. Conditions 5 and 7 are governance obligations
   * that would be wrong to impose on a blank scaffold; this is an inconsistency
   * in the identity graph, and an inconsistent graph is not less inconsistent
   * for sitting in a file that happens to resolve no protected object.
   */
  if ((scan.ambiguous ?? []).length > 0) {
    refusals.push({
      condition: 8,
      code: "SENTINEL-C8",
      detail:
        `${scan.ambiguous.length} identity/identities are canonically DECLARED in more than one ` +
        `governed memory file, so ownership is ambiguous: ` +
        `${scan.ambiguous
          .map((a) => `${a.id} (named at line ${a.named_at_line}) claimed by ${a.claimants.join(" AND ")}`)
          .join("; ")}. ` +
        `Cross-file resolution requires exactly ONE canonical declaration per stable identity. ` +
        `This is NOT tie-broken: picking a claimant would strand the other, which is the same ` +
        `harm the deepest-declaration rule prevents inside a single file. Remedy: keep one ` +
        `declaration and turn the other into a citation (this tree's convention is that a ` +
        `BACKTICKED tag cites an object and a BARE tag opening a bold bullet declares it).`,
    });
  }

  s.verdict = refusals.length > 0 ? "REFUSE" : "ALLOW";
  return s;
}

/** Read and validate a pre-registration record against the run it authorises. */
function readPreRegistration(recordPath, spec, keep, originalBytes) {
  if (!fs.existsSync(recordPath)) {
    return { ok: false, detail: `no pre-registration record at ${recordPath}` };
  }
  let doc;
  try {
    doc = JSON.parse(fs.readFileSync(recordPath, "utf8"));
  } catch (e) {
    return { ok: false, detail: `the pre-registration at ${recordPath} is not valid JSON (${e.message})` };
  }
  const records = Array.isArray(doc) ? doc : Array.isArray(doc.records) ? doc.records : [doc];
  const mine = records.filter((r) => r && r.file === spec.name);
  if (mine.length === 0) {
    return { ok: false, detail: `the pre-registration names no record for file "${spec.name}"` };
  }
  const sha = crypto.createHash("sha256").update(Buffer.from(originalBytes, "latin1")).digest("hex");
  for (const r of mine) {
    if (r.keep !== keep) {
      return {
        ok: false,
        detail: `the pre-registration for "${spec.name}" names keep ${r.keep}, this run requested ${keep}`,
      };
    }
    if (r.sourceSha256 !== sha) {
      return {
        ok: false,
        detail:
          `the pre-registration for "${spec.name}" was taken over source sha256 ${r.sourceSha256} ` +
          `and the file on disk is now ${sha} — the record is bound to the exact bytes it was ` +
          `written over, so it cannot authorise a rotation of different ones`,
      };
    }
  }
  return { ok: true, sha, detail: "matches file, keep and source sha256" };
}

/* ------------------------------------------------------------------ */
/* 5. PLANNING (no writes)                                             */
/* ------------------------------------------------------------------ */

function planFile(root, spec, opts) {
  const full = path.join(root, spec.path);
  if (!fs.existsSync(full)) {
    throw new RotateError(EXIT.IO, `MISSING SOURCE: ${spec.path} (root ${root})`);
  }
  const original = fs.readFileSync(full).toString("latin1");
  const segments = segmentFile(original, spec);

  // (1a/1b) conservation, before anything else
  assertSegmentPartition(original, segments);

  const blocks = segments.filter((s) => s.kind === "block");
  const keepN = Math.min(opts.keep, blocks.length);

  // (1c) route each segment to exactly one output
  const { retained, archived } = routeSegments(segments, opts.keep);

  const contentText = retained.map((s) => s.text).join("");
  const retainedBlocks = retained.filter((s) => s.kind === "block").length;
  if (retainedBlocks !== keepN) {
    throw new RotateError(
      EXIT.RETENTION,
      `RETENTION FAILED for ${spec.path}: retained ${retainedBlocks} blocks, expected ${keepN}`
    );
  }

  // preamble byte-exact at the head, so the archivist's prepend region is
  // unchanged (the banner is inserted AFTER it, never before or inside it)
  const preamble = segments.find((s) => s.kind === "preamble");
  if (preamble && !contentText.startsWith(preamble.text)) {
    throw new RotateError(
      EXIT.RETENTION,
      `RETENTION FAILED for ${spec.path}: head preamble was not preserved byte-exact`
    );
  }

  /*
   * (1d) ROUTING RECONSTRUCTION -- the check that replaced three guards that
   * could not fire, and unlike them it CAN.
   *
   * `assertSegmentPartition` proves the segments rejoin to the original.
   * `routeSegments` proves every segment lands in exactly one output. Neither
   * proves the two outputs are in the right ORDER relative to each other, and
   * that is a real gap rather than a hypothetical one: routing keeps the newest
   * blocks, which are a PREFIX of the file, so `retained ++ archived` must be
   * the original byte for byte. Select a non-prefix set of blocks instead --
   * `blocks.slice(1, keepN + 1)` -- and the count guard above still passes, the
   * preamble guard still passes, the post-composition checks still pass and the
   * re-parse still passes, because every one of them is blind to interleaving.
   * The live file would then carry the wrong blocks and the archive would carry
   * a block that is also still live. Only this comparison sees it, and a
   * mutation test drives it.
   *
   * It is also what licenses the word "byte-exact" in the human report: the
   * printed identity `live + archived == original` is verified here as a string
   * comparison, not inferred from three separately-asserted facts.
   */
  const archivedText = archived.map((s) => s.text).join("");
  if (contentText + archivedText !== original) {
    let at = 0;
    const rejoined = contentText + archivedText;
    while (at < rejoined.length && rejoined[at] === original[at]) at++;
    throw new RotateError(
      EXIT.CONSERVATION,
      `ROUTING RECONSTRUCTION FAILED for ${spec.path}: the retained bytes followed by the ` +
        `archived bytes are not the original file (first divergence at byte ${at}). Every ` +
        `segment was routed exactly once, so the two outputs are INTERLEAVED: at least one ` +
        `block is on the wrong side of the cut. Refusing to write.`
    );
  }

  // (2) the archive-pointer banner -- only when something actually rotates, so
  // a no-op run stays a ZERO-DIFF no-op
  const noop = archived.length === 0;

  /*
   * The expected shape of the composed file, derived HERE and independently of
   * composeRetained, so that the check below is a genuine cross-check rather
   * than composeRetained agreeing with itself:
   *
   *   liveContentText = the retained segments exactly as they came out of the
   *                     original file, minus ONLY a positionally-anchored prior
   *                     banner at the tail of the preamble
   *   bannerOffset    = where the new banner goes (end of the stripped preamble,
   *                     after the newline pad if the preamble lacks one)
   */
  const preambleSeg = retained.find((s) => s.kind === "preamble");
  let liveContentText = contentText;
  let priorBannerBytes = 0;
  let padBytes = 0;
  let bannerOffset = 0;
  if (!noop && preambleSeg) {
    const strip = stripTrailingBanner(preambleSeg.text);
    priorBannerBytes = strip.bannerBytes;
    padBytes = strip.text.length > 0 && !strip.text.endsWith("\n") ? 1 : 0;
    const idx = retained.indexOf(preambleSeg);
    liveContentText = retained
      .map((s) => (s === preambleSeg ? strip.text : s.text))
      .join("");
    bannerOffset =
      retained.slice(0, idx).reduce((a, s) => a + s.text.length, 0) + strip.text.length + padBytes;
  }

  const banner = noop
    ? ""
    : renderBanner({
        batchId: opts.batchId,
        name: spec.name,
        archivedBlocks: archived.length,
        archivedBytes: archived.reduce((a, s) => a + s.text.length, 0),
        retainedBlocks,
        contentBytes: liveContentText.length,
      });
  // measured from the rendered banner itself -- NEVER by subtracting one
  // possibly-lossy length from another
  const bannerBytes = banner.length;
  const retainedText = composeRetained(retained, banner);

  /*
   * (2a) POST-COMPOSITION BYTE CONSERVATION.
   *
   * `assertSegmentPartition` runs on the SEGMENTS and cannot see composition.
   * The block-count re-parse below counts BLOCKS, not bytes, and a span excised
   * from the middle of a block does not change it. These are the checks that
   * see the bytes actually about to be written.
   */
  if (noop) {
    if (retainedText !== contentText) {
      throw new RotateError(
        EXIT.CONSERVATION,
        `POST-COMPOSITION CONSERVATION FAILED for ${spec.path}: a no-op composition ` +
          `altered the retained bytes (${contentText.length} B in, ${retainedText.length} B out)`
      );
    }
  } else {
    // (i) byte accounting, measured on the ACTUAL composed string
    const expectedBytes = liveContentText.length + padBytes + bannerBytes;
    if (retainedText.length !== expectedBytes) {
      const delta = expectedBytes - retainedText.length;
      throw new RotateError(
        EXIT.CONSERVATION,
        `POST-COMPOSITION CONSERVATION FAILED for ${spec.path}: composed ${retainedText.length} B, ` +
          `expected ${expectedBytes} B (${liveContentText.length} B live content + ${padBytes} B pad + ` +
          `${bannerBytes} B banner). ${Math.abs(delta)} B of retained content were ` +
          `${delta > 0 ? "DESTROYED by" : "invented by"} composition.`
      );
    }
    /*
     * A check (ii) `retainedText.startsWith(banner, bannerOffset)` used to sit
     * here. It was DELETED: `composeRetained` BUILDS `retainedText` by
     * concatenating that exact banner at that exact offset, so it could not come
     * out false for any input. (Its old comment gave a FALSE reason for keeping
     * it -- that (iii) subsumes it; counterexample liveContentText "AB", banner
     * "X", bannerOffset 1, retainedText "AZB" -- but a true statement about a
     * check that cannot fire is still a check that cannot fire.)
     *
     * WHAT IS LOST, NAMED: nothing that (iii) was covering. (iii) pins the
     * length AND position of the inserted span and requires every byte outside
     * it to equal `liveContentText`, so no byte OF `liveContentText` can go
     * missing whatever composition puts inside the span. Only the CONTENT of
     * that span is no longer re-checked after composition, and that is settled
     * BEFORE it by `renderBanner`'s drift check (driven by tests in both
     * directions) and after the write by the suite's external recogniser reading
     * it off disk.
     *
     * READ THAT SCOPE EXACTLY, because it is narrower than it looks and this
     * comment used to be read as more. `liveContentText` is BUILT FROM
     * `stripTrailingBanner`'s output, so an over-reaching strip produces a
     * SHORTER `liveContentText` and (iii) then dutifully confirms that the
     * shorter text was preserved. For the over-reach class, byte-loss
     * impossibility therefore rests on (iv) ALONE — not on (iii) plus (iv).
     * Measured, not argued: with (iii) disabled the over-reaching strip is still
     * refused at EXIT.CONSERVATION; with (iv) disabled it writes, at exit 0,
     * having eaten preamble bytes. That is the pair of mutations behind
     * "checks (i) and (iii) are BLIND to it — only (iv) sees it" in the suite.
     */
    // (iii) excising exactly the pad + banner reproduces the live content
    const withoutBanner =
      retainedText.slice(0, bannerOffset - padBytes) +
      retainedText.slice(bannerOffset + bannerBytes);
    if (withoutBanner !== liveContentText) {
      let at = 0;
      while (at < withoutBanner.length && withoutBanner[at] === liveContentText[at]) at++;
      throw new RotateError(
        EXIT.CONSERVATION,
        `POST-COMPOSITION CONSERVATION FAILED for ${spec.path}: removing the banner does not ` +
          `reproduce the retained content byte-exact (first divergence at byte ${at})`
      );
    }
    /*
     * (iv) the ONLY bytes composition may drop are a PRIOR BANNER'S -- and the
     * dropped region is audited BY ITS CONTENT, with a recogniser that never
     * consults findTrailingBanner or stripTrailingBanner.
     *
     * The previous form of this check compared lengths:
     *   liveContentText.length !== contentText.length - priorBannerBytes
     * That check COULD NOT FAIL. `liveContentText` is built from `strip.text`
     * and `priorBannerBytes` is `text.length - strip.text.length`, so the
     * identity holds for ANY strip, including one that over-reaches by a
     * kilobyte. It read as coverage and was worse than nothing.
     *
     * READ WHAT THIS CHECK IS FOR, because the sentence that used to close this
     * comment -- "checking WHICH BYTES were dropped is what an over-reaching
     * strip cannot satisfy" -- reads as though some INPUT could make it fire, and
     * none can.
     *
     * AT THIS COMMIT (iv) CANNOT FIRE, FOR ANY INPUT. It is analytically
     * tautological: `priorBannerBytes` is non-zero only because
     * `findTrailingBanner` already accepted that exact byte range under
     * `isRenderedBanner`, and (iv) re-runs `isRenderedBanner` over the same
     * range. Measured, not argued: instrumented at this branch and run over the
     * whole suite, the SHIPPED tool evaluated it 17 times and got `true` all 17.
     * The only `false` results in that run came from two deliberately MUTATED
     * copies of this file.
     *
     * IT IS AN EDIT-GUARD, AND THAT IS WHY IT STAYS. It re-derives `dropped`
     * INDEPENDENTLY, from `preambleSeg.text`, instead of trusting the strip's own
     * report -- so it is not tautological against a MUTATED strip, only against
     * this one. The suite carries two over-reach mutants and they are the measured
     * pair: in the one that keeps this check, this check is what refuses; in the
     * one built with this check REMOVED, the identical over-reach writes at exit 0
     * having eaten preamble bytes (see the scope note under check (iii)).
     *
     * THE CONTRAST WITH DELETED CHECK (ii) IS THE WHOLE POINT. (ii) also could
     * not fire, and was deleted; this one also cannot fire, and was kept. The
     * difference is not whether an input reaches them -- neither is reached --
     * it is what an EDIT costs. (ii) re-asserted a fact `composeRetained` had
     * just constructed by concatenation, so no edit to the strip could falsify
     * it. (iv) re-derives its subject from the source segment, so an edit to the
     * strip does falsify it. A check that cannot fire earns its place only by
     * being a live constraint on future edits; of these two, only (iv) is one.
     */
    if (priorBannerBytes > 0) {
      const dropped = preambleSeg.text.slice(preambleSeg.text.length - priorBannerBytes);
      if (!isRenderedBanner(dropped)) {
        throw new RotateError(
          EXIT.CONSERVATION,
          `POST-COMPOSITION CONSERVATION FAILED for ${spec.path}: composition dropped ` +
            `${priorBannerBytes} B from the tail of the preamble that do NOT parse as an ` +
            `archive-pointer banner this tool rendered. Those bytes are CONTENT: they reach ` +
            `neither the live file nor the archive. Refusing to write.`
        );
      }
    }
  }

  // the banner must not perturb parsing: the file we are about to write has to
  // re-parse to exactly the blocks we kept
  const rederived = segmentFile(retainedText, spec).filter((s) => s.kind === "block").length;
  if (rederived !== retainedBlocks) {
    throw new RotateError(
      EXIT.RETENTION,
      `RETENTION FAILED for ${spec.path}: the file to be written re-parses to ` +
        `${rederived} blocks, expected ${retainedBlocks}`
    );
  }

  // (3) size ceiling, measured on the BYTES ACTUALLY WRITTEN (banner included)
  // -- report and stop; NEVER auto-reduce N
  const retainedBytes = retainedText.length;
  const withinCeiling = retainedBytes <= opts.maxBytes;
  if (!withinCeiling) {
    throw new RotateError(
      EXIT.CEILING,
      `SIZE CEILING EXCEEDED for ${spec.path}: measured ${retainedBytes} B > ceiling ` +
        `${opts.maxBytes} B at keep=${opts.keep}. N was NOT auto-reduced. ` +
        `Lower it explicitly: --keep <N less than ${opts.keep}> (or raise --max-bytes deliberately).`
    );
  }

  /*
   * (4) THE SENTINEL, LAST IN THE PLAN AND FIRST IN AUTHORITY.
   *
   * It runs AFTER every conservation and ceiling check because it consumes
   * their outputs — the routing that is actually about to happen, and the exact
   * byte count that would be written. It runs BEFORE any write because a
   * refusal that arrives after the archive has been appended is not a refusal.
   *
   * `planFile` is called for EVERY file before ANY file is written, so a
   * sentinel refusal on one file stops the whole run, exactly as a conservation
   * failure does.
   */
  /*
   * THE CROSS-FILE RESOLUTION IS BUILT ONCE PER RUN AND PASSED IN, never rebuilt
   * per file: it is a property of the ROOT, and rebuilding it per file would let
   * two files in the same run disagree about who owns an identity.
   */
  const resolution = opts.resolution ?? buildIdentityIndex(root);
  const scan = scanProtectedObjects(original, spec, {
    ...resolution,
    inbound: inboundProtections(root, spec, resolution.index),
  });

  // The INDEPENDENT cross-check behind refusal condition 4. `crossMap` is built
  // by its own line scan; `segments` came from `segmentFile`. Comparing them is
  // only worth anything while they stay independent — do not "simplify" this by
  // deriving one from the other.
  const crossMap = sentinelBlockMap(original, spec);
  const planBlocks = segments.filter((s) => s.kind === "block");
  let mapAgreement = { ok: true, detail: "block count, headers and offsets agree" };
  if (crossMap.length !== planBlocks.length) {
    mapAgreement = {
      ok: false,
      detail: `${crossMap.length} blocks in the re-derived map vs ${planBlocks.length} in the plan`,
    };
  } else {
    for (let i = 0; i < crossMap.length; i++) {
      if (crossMap[i].header !== planBlocks[i].headerLine || crossMap[i].startOffset !== planBlocks[i].startOffset) {
        mapAgreement = {
          ok: false,
          detail:
            `block ${i + 1} differs — re-derived ${JSON.stringify(clip(crossMap[i].header, 60))} at byte ` +
            `${crossMap[i].startOffset}, plan ${JSON.stringify(clip(planBlocks[i].headerLine ?? "", 60))} at ` +
            `byte ${planBlocks[i].startOffset}`,
        };
        break;
      }
    }
  }

  // The RESTORATION PROOF behind refusal condition 6, re-derived here from the
  // two outputs rather than inherited from check (1d) above, so the two are
  // independent instruments and not one instrument counted twice.
  const restorationSource = contentText + archivedText;
  let restorationOk = { ok: true, detail: "retained ++ archived reconstructs the source byte-exact" };
  if (restorationSource !== original) {
    let at = 0;
    while (at < restorationSource.length && restorationSource[at] === original[at]) at++;
    restorationOk = {
      ok: false,
      detail:
        `the retained bytes followed by the archived bytes are ${restorationSource.length} B against ` +
        `${original.length} B of source, first divergence at byte ${at}`,
    };
  }

  const preRegistration = opts.preRegistration
    ? readPreRegistration(opts.preRegistration, spec, opts.keep, original)
    : null;

  const sentinel = evaluateSentinel({
    spec,
    scan,
    requestedKeep: opts.keep,
    archivedBlocks: archived.length,
    archivedBytes: archived.reduce((a, s) => a + s.text.length, 0),
    retainedBytes,
    maxBytes: opts.maxBytes,
    closeBudget: opts.closeBudget,
    apply: opts.apply === true,
    preRegistration,
    mapAgreement,
    restorationOk,
  });

  if (sentinel.verdict === "REFUSE" && !opts.sentinelReport) {
    throw new RotateError(EXIT.SENTINEL, sentinelRefusalLines(spec.path, sentinel));
  }

  return {
    spec,
    full,
    original,
    segments,
    retained,
    archived,
    retainedText,
    sentinel,
    report: {
      name: spec.name,
      sentinel,
      path: spec.path,
      delimiter: String(spec.blockDelimiter),
      batchId: opts.batchId,
      originalBytes: original.length,
      totalBlocks: blocks.length,
      /*
       * TRUE when the source holds at least one NON-WHITESPACE byte. It exists
       * only to separate two states that `totalBlocks: 0` on its own cannot:
       * a delimiter that matched nothing in a file that has content (a hazard)
       * versus an empty or whitespace-only file (benign). See
       * `delimiterMatchedNothing` and the warning it drives.
       */
      originalHasContent: /\S/.test(original),
      keep: opts.keep,
      retainedBlocks,
      archivedBlocks: archived.length,
      archivedFirstLabel: archived.length ? archived[0].label : null,
      archivedLastLabel: archived.length ? archived[archived.length - 1].label : null,
      /*
       * Two separate identities, both exact, neither derived from the other:
       *
       *   retainedContentBytes + archivedBytes == originalBytes
       *     -- every byte READ is routed to exactly one output.
       *   retainedBytes == liveContentBytes + bannerPadBytes + bannerBytes
       *     -- every byte WRITTEN is either retained content or the new banner.
       *
       * liveContentBytes == retainedContentBytes - priorBannerBytes: the only
       * retained bytes composition removes are the previous banner's.
       *
       * bannerBytes is MEASURED on the rendered banner. It is never computed by
       * subtracting one length from another -- that is how a lossy composition
       * used to hide, by under-reporting the banner by exactly what it ate.
       */
      retainedContentBytes: contentText.length,
      archivedBytes: archived.reduce((a, s) => a + s.text.length, 0),
      liveContentBytes: liveContentText.length,
      priorBannerBytes,
      bannerPadBytes: padBytes,
      bannerBytes,
      retainedBytes,
      archiveFile: `${ARCHIVE_DIR}/${spec.name}.archive.md`,
      indexFile: INDEX_REL,
      ceilingBytes: opts.maxBytes,
      withinCeiling,
      conservationOk: true,
      noop,
    },
  };
}

/* ------------------------------------------------------------------ */
/* 6. WRITING (append-only archive; verified replace of the retained)  */
/* ------------------------------------------------------------------ */

function writeVerified(fullPath, text, mustStartWith) {
  /*
   * Guard the byte domain: every char must be a single byte, or the latin1
   * encode below would silently truncate it.
   *
   * This one is NOT algebraically impossible -- `charCodeAt(i) > 0xff` is true
   * of any string carrying a char outside latin1, and JS strings carry those
   * routinely. It is unreachable only along the call paths that exist TODAY,
   * every one of which decodes with `.toString("latin1")` or passes literals
   * through `toBytes`. It becomes reachable the moment a producer decodes as
   * utf8 instead, which is the defect it is here to catch, at the last point
   * before bytes hit the disk. No test drives it, so it is stated as a guard,
   * never as a tested guarantee.
   */
  for (let i = 0; i < text.length; i++) {
    if (text.charCodeAt(i) > 0xff) {
      throw new RotateError(
        EXIT.IO,
        `BYTE-DOMAIN VIOLATION at offset ${i} while writing ${fullPath}: ` +
          `char U+${text.charCodeAt(i).toString(16).toUpperCase()} is not a single byte`
      );
    }
  }
  fs.mkdirSync(path.dirname(fullPath), { recursive: true });
  const staging = `${fullPath}.rotate-staging`;
  fs.writeFileSync(staging, Buffer.from(text, "latin1"));
  const back = fs.readFileSync(staging).toString("latin1");
  /*
   * KEPT, AND IT IS NOT A TESTED GUARANTEE.
   *
   * This guards an OUT-OF-PROCESS condition, not an in-process defect: for it to
   * fire the storage layer itself must lie -- short write, full disk reported as
   * success, silent corruption. That is a genuine external failure mode, which
   * is why it is kept where the guards that were merely algebraically impossible
   * were deleted. It is also why no test drives it: the read-back goes through
   * the same fs that just accepted the write, and this suite cannot honestly
   * fake a lying fs. It is the only check here that looks at what is ON DISK
   * rather than at what was intended. Treat it as a tripwire for a condition
   * nothing in this repo can reproduce, and never cite it as proof.
   */
  if (back !== text) {
    throw new RotateError(EXIT.IO, `WRITE VERIFICATION FAILED for ${fullPath}`);
  }
  if (mustStartWith !== undefined && !back.startsWith(mustStartWith)) {
    throw new RotateError(
      EXIT.IO,
      `APPEND-ONLY VIOLATION: existing bytes of ${fullPath} would not be preserved`
    );
  }
  fs.renameSync(staging, fullPath);
}

function applyFile(root, plan, batchId) {
  const { spec, archived, retainedText, full } = plan;
  const archiveRel = plan.report.archiveFile;
  const archiveFull = path.join(root, archiveRel);

  const existing = fs.existsSync(archiveFull)
    ? fs.readFileSync(archiveFull).toString("latin1")
    : "";
  const separator = existing === "" || existing.endsWith("\n") ? "" : "\n";
  const prefix = existing + separator;

  const first = archived[0].label;
  const last = archived[archived.length - 1].label;
  // toBytes: this header is authored as UTF-8 source text and has to enter the
  // latin1 byte domain before it can be concatenated with file content.
  let batch = toBytes(
    `<!-- rotation-batch: ${batchId} | source: ${spec.path} | blocks: ${first}..${last} ` +
      `(${archived.length}) | tool: ${TOOL_ID} -->\n\n` +
      `## ARCHIVED BATCH ${batchId} — ${spec.path} — ${archived.length} blocks ` +
      `(${first}..${last})\n\n`
  );

  const baseLine = countLines(prefix);
  const rows = [];
  for (const seg of archived) {
    const archiveLine = baseLine + countLines(batch) + 1;
    rows.push({
      sourcePath: spec.path,
      sourceLine: seg.startLine,
      header: seg.headerLine,
      archiveFile: `${spec.name}.archive.md`,
      archiveLine,
      batchId,
    });
    batch += seg.text;
  }
  if (!batch.endsWith("\n")) batch += "\n";
  batch += "\n";

  writeVerified(archiveFull, prefix + batch, existing);
  writeVerified(full, retainedText);
  return rows;
}

/*
 * THIS HEADER IS WRITTEN INTO MEMORY, so whatever it says is what a future
 * session believes. It used to end `Nothing here is ever deleted.` — an
 * unqualified permanence claim, in the one part of the record that has no
 * version-control backing, and the strongest such claim in the tool.
 *
 * It was TRUE of this tool's own writes and false as a statement about the
 * directory, so it is now split into what is guaranteed and by whom. The three
 * facts a reader needs are all here: writes are refused unless the existing
 * bytes survive (`writeVerified`'s `mustStartWith`), the directory is untracked
 * until something commits it so nothing else is holding it, and the index rows
 * are themselves clipped.
 *
 * "AT MOST ONE `??` LINE", NOT "A SINGLE" ONE. It said "a single `??` line" and
 * that is one case short: emptying the directory removes the line altogether, so
 * the count is 0 or 1, never guaranteed 1. The tripwire's own copy of this
 * observation already used the correct form. This string is only ever written
 * when the index is created for the first time, so the wording change reaches
 * FUTURE first-writes; an `INDEX.md` already on disk keeps the bytes it has, and
 * a re-run over it is a verified append that never rewrites the header.
 *
 * The suite audits EVERY string this tool writes into memory for exactly this
 * class of claim — not just the banner, which is how this one survived a round.
 */
const INDEX_HEADER =
  `# Archived Build OS memory — index\n\n` +
  `> Maps every rotated-away section to the archive file, batch and line that now\n` +
  `> hold it, so citations into rotated content stay resolvable (anything that\n` +
  `> cites \`build-os/memory/residue.md\` by line — a receipt, a packet, another\n` +
  `> repo — still resolves). Written by \`${TOOL_ID}\`.\n` +
  `>\n` +
  `> WHAT IS GUARANTEED, AND BY WHOM. Every write this tool makes to this file\n` +
  `> and to the archive files beside it is refused unless the bytes already on\n` +
  `> disk are preserved exactly, so a re-run can only add rows and a second run\n` +
  `> over the same content is a verified no-op. That is a property of THIS TOOL,\n` +
  `> not of this directory: \`build-os/memory/archive/\` is not ignored, but a file\n` +
  `> written here starts out untracked, so nothing under it has\n` +
  `> version-control backing until it is committed. Anything else that writes\n` +
  `> here can remove it. \`git status\` DOES show the directory appear, as at\n` +
  `> most one \`??\` line — but that one line reads the same whether a file inside\n` +
  `> was added, rewritten, or removed, so an overwrite in place is invisible\n` +
  `> there. Removing the whole directory is not: the \`??\` line disappears.\n` +
  `>\n` +
  `> THE ROWS BELOW ARE LOSSY. The section-header column is clipped to 160\n` +
  `> characters, so a longer heading is truncated HERE. What each row points at\n` +
  `> is not clipped: this index is a pointer, not a copy.\n\n`;

function appendIndex(root, rows, batchId) {
  const full = path.join(root, INDEX_REL);
  const existing = fs.existsSync(full) ? fs.readFileSync(full).toString("latin1") : "";
  const base = existing === "" ? toBytes(INDEX_HEADER) : existing;
  const separator = base.endsWith("\n") ? "" : "\n";

  let out = `## Batch ${batchId}\n\n`;
  out += `| source (original) | section header | archive location |\n`;
  out += `| --- | --- | --- |\n`;
  for (const r of rows) {
    const header = clip(r.header, 160).split("|").join("\\|");
    out += `| \`${r.sourcePath}:${r.sourceLine}\` | ${header} | \`${r.archiveFile}:${r.archiveLine}\` |\n`;
  }
  out += "\n";

  writeVerified(full, base + separator + out, existing === "" ? undefined : existing);
}

/* ------------------------------------------------------------------ */
/* 7. CLI                                                              */
/* ------------------------------------------------------------------ */

const USAGE = `rotate-memory.sh — rotate Build OS memory (keep newest N, archive the tail;
the only bytes consumed are a prior banner THIS TOOL generated, replaced in place)

Rotation is BY RECENCY ONLY. This tool makes no guarantee about which content
survives by meaning. Content that must never rotate belongs in a file that is
not listed in FILE_SPECS. The path designated for that is
build-os/memory/standing_gates.md, which this tool never reads, writes or
creates — put such content there rather than in the files listed below.

  --apply                 actually write. WITHOUT THIS, THE TOOL IS A DRY RUN.
  --keep N                blocks to keep live per file (default ${DEFAULT_KEEP})
  --max-bytes B           post-rotation size ceiling per file (default ${DEFAULT_MAX_BYTES})
  --file NAME             restrict to one of: ${Object.keys(FILE_SPECS).join(", ")}
  --root DIR              repo root (default: two levels above this script)
  --json                  machine-readable report on stdout

THE ROTATION SENTINEL is always on. It derives, per file,

  minimum_safe_keep = max( block position of every protected or still-open object )

resolving objects BY IDENTITY — a marker names an object, it is not the object —
and REFUSES a rotation below that floor at exit ${EXIT.SENTINEL}, before anything is written.
N is never auto-raised. A file in which it resolves zero protected objects is
UNARMED and says so on stderr.

Identity is resolved ACROSS THE GOVERNED MEMORY SET, not within one file, so a
citation of an object a sibling memory file declares resolves instead of
refusing, and that sibling's live marker protects the block that really holds
the object. An identity NO governed file declares still refuses; one that TWO
governed files declare refuses as ambiguous. The set, and the one member that is
declared but deliberately not read, are printed on every run.

  --sentinel-report       report the floor and the verdict and EXIT 0 without
                          writing. This is how you ask what the safe --keep is;
                          it implies a dry run and never refuses.
  --pre-registration F    JSON record { file, keep, sourceSha256 } authorising
                          this apply. REQUIRED for --apply over a file that
                          carries protected objects.
  --close-budget B        bytes the packet's own close must still fit after the
                          rotation (default ${DEFAULT_CLOSE_BUDGET_BYTES}, derived from this
                          repository's largest observed single-commit growth)
  -h, --help              this text
`;

export function parseArgs(argv) {
  const opts = {
    apply: false,
    keep: DEFAULT_KEEP,
    maxBytes: DEFAULT_MAX_BYTES,
    file: null,
    root: null,
    json: false,
    help: false,
    sentinelReport: false,
    preRegistration: null,
    closeBudget: DEFAULT_CLOSE_BUDGET_BYTES,
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    const need = (label) => {
      const v = argv[++i];
      if (v === undefined) throw new RotateError(EXIT.USAGE, `${label} requires a value`);
      return v;
    };
    switch (a) {
      case "--apply": opts.apply = true; break;
      case "--json": opts.json = true; break;
      case "-h": case "--help": opts.help = true; break;
      case "--sentinel-report": opts.sentinelReport = true; break;
      case "--pre-registration": opts.preRegistration = need("--pre-registration"); break;
      case "--close-budget": opts.closeBudget = Number(need("--close-budget")); break;
      case "--keep": opts.keep = Number(need("--keep")); break;
      case "--max-bytes": opts.maxBytes = Number(need("--max-bytes")); break;
      case "--file": opts.file = need("--file"); break;
      case "--root": opts.root = need("--root"); break;
      default:
        throw new RotateError(EXIT.USAGE, `unknown argument: ${a}\n\n${USAGE}`);
    }
  }
  if (!Number.isInteger(opts.keep) || opts.keep < 1) {
    throw new RotateError(EXIT.USAGE, `--keep must be an integer >= 1 (got ${opts.keep})`);
  }
  if (!Number.isInteger(opts.maxBytes) || opts.maxBytes < 1) {
    throw new RotateError(EXIT.USAGE, `--max-bytes must be an integer >= 1 (got ${opts.maxBytes})`);
  }
  if (!Number.isInteger(opts.closeBudget) || opts.closeBudget < 0) {
    throw new RotateError(EXIT.USAGE, `--close-budget must be an integer >= 0 (got ${opts.closeBudget})`);
  }
  /*
   * `--sentinel-report` IMPLIES A DRY RUN, and does so by force rather than by
   * documentation. It is the one mode that returns 0 on a verdict of REFUSE, so
   * letting it coexist with `--apply` would build a bypass: ask the question in
   * a mode that cannot refuse, and write anyway.
   */
  if (opts.sentinelReport) opts.apply = false;
  if (opts.file !== null && !(opts.file in FILE_SPECS)) {
    throw new RotateError(
      EXIT.USAGE,
      `--file must be one of: ${Object.keys(FILE_SPECS).join(", ")} (got ${opts.file})`
    );
  }
  return opts;
}

/*
 * THE ONE NO-OP THAT IS NOT BENIGN.
 *
 * `blocks: 0 total` + `already rotated (no-op)` was printed identically for
 * three unrelated states, and the reading it invites — "fine, nothing to do" —
 * is right for two of them and wrong for the third:
 *
 *   - THE DELIMITER MATCHED NOTHING in a file that HAS content. The whole file
 *     became one preamble and it will never rotate, silently, forever. This is
 *     the failure mode the FILE_SPECS comment above calls the dangerous
 *     direction.
 *   - THE FILE IS EMPTY (or whitespace only). Benign: a freshly scaffolded repo
 *     that has not written a block yet parses to zero, legitimately.
 *   - THE FILE PARSED FINE and has nothing old enough to archive. Benign, and
 *     the literal meaning of "already rotated".
 *
 * Only the first raises the warning, and it goes to STDERR so `--json` on
 * stdout stays machine-parseable. IT IS NOT AN ERROR AND DOES NOT CHANGE THE
 * EXIT CODE. An empty scaffold parsing to zero blocks is correct behaviour, and
 * this tool does not get to decide that a customer's memory format is wrong —
 * it reports what its own delimiter did and leaves the judgement to the reader.
 * `--json` carries the same signal as `totalBlocks: 0` with
 * `originalHasContent: true`.
 */
export function delimiterMatchedNothing(report) {
  return report.totalBlocks === 0 && report.originalHasContent === true;
}

function renderDelimiterWarning(r) {
  return (
    `WARNING: ${r.path}: the block delimiter ${r.delimiter} matched NOTHING, ` +
    `but the file has content (${r.originalBytes} B). Zero blocks were found, so ` +
    `NOTHING CAN EVER ROTATE OUT OF IT — this is not the same as "already ` +
    `rotated (no-op)", which is what the report above prints for it. Either this ` +
    `file uses a block convention that delimiter does not match, or the ` +
    `delimiter was narrowed. Fix FILE_SPECS in rotate-memory.mjs — do not ` +
    `rewrite your memory file to suit the tool. Exit code is unchanged: an ` +
    `empty or not-yet-written file parses to zero blocks legitimately, so this ` +
    `is a warning, not a failure.`
  );
}

function renderHuman(reports, opts) {
  const L = [];
  L.push(
    opts.apply
      ? "APPLY — rotation written."
      : "DRY-RUN (no --apply) — nothing will be written."
  );
  L.push("");
  for (const r of reports) {
    L.push(r.path);
    L.push(`  delimiter         : ${r.delimiter}`);
    L.push(
      `  blocks            : ${r.totalBlocks} total -> keep ${r.retainedBlocks} newest, ` +
        `would archive ${r.archivedBlocks}`
    );
    if (r.noop) {
      L.push(`  would archive     : nothing — already rotated (no-op)`);
    } else {
      L.push(
        `  would archive     : ${r.archivedFirstLabel}..${r.archivedLastLabel} ` +
          `(${r.archivedBytes} B) -> ${r.archiveFile}`
      );
      L.push(`  archive pointer   : ${r.bannerBytes} B banner -> ${r.indexFile}`);
    }
    L.push(
      `  live size         : ${r.originalBytes} B -> ${r.retainedBytes} B ` +
        `(ceiling ${r.ceilingBytes} B) ${r.withinCeiling ? "OK" : "OVER"}`
    );
    /*
     * WHAT LICENSES THE WORD "byte-exact" BELOW. Not arithmetic on reported
     * numbers -- that is exactly how a lossy composition once hid. Three string
     * comparisons, each run before this line is reached:
     *
     *   (1d) contentText ++ archivedText === original
     *   (2a)(iii) the bytes about to be written, with the pad and the generated
     *             banner excised, === liveContentText
     *   and liveContentText === contentText whenever priorBannerBytes is 0
     *
     * Chained, those reconstruct `retained ++ archived ++ generated banner/pad`
     * and verify it equals the original. When priorBannerBytes > 0 the second
     * identity no longer closes, so the claim is WITHDRAWN and the consumed
     * count is printed on the line above it instead.
     */
    if (r.priorBannerBytes > 0) {
      L.push(
        `  prior banner      : ${r.priorBannerBytes} B REPLACED in place — GENERATED-BANNER ` +
          `REPLACEMENT: bytes THIS TOOL generated on an earlier run, in its own anchored ` +
          `slot, reproduced by neither output`
      );
      L.push(
        `  conservation      : OK APART FROM those ${r.priorBannerBytes} B ` +
          `(${r.retainedContentBytes} B live + ${r.archivedBytes} B archived = ` +
          `${r.originalBytes} B original; of the live total, ${r.liveContentBytes} B carry ` +
          `through byte-exact and ${r.priorBannerBytes} B are the replaced banner). ` +
          `NOT byte-exact overall.`
      );
    } else {
      L.push(
        `  conservation      : OK (${r.retainedContentBytes} B live + ${r.archivedBytes} B archived ` +
          `= ${r.originalBytes} B original, byte-exact)`
      );
    }
    L.push(`  selection         : RECENCY ONLY — no content is exempt from rotation`);
    /*
     * THE SENTINEL LINES ARE PRINTED FOR EVERY PROPOSED ROTATION, ALLOWED OR
     * REFUSED. A floor that is only shown on the way to a refusal teaches
     * nobody the safe value; showing it on every run is what stops the next
     * rotation from re-deriving it by hand.
     */
    const s = r.sentinel;
    if (s) {
      L.push(
        `  sentinel          : ${s.verdict}${s.armed ? "" : " (NOT ARMED — 0 protected objects resolved)"}` +
          ` — requested_keep ${s.requested_keep}, minimum_safe_keep ${s.minimum_safe_keep}`
      );
      L.push(
        `  protected objects : ${s.protected_object_ids.length} at block(s) ` +
          `${s.protected_block_positions.join(", ") || "-"}` +
          `${s.protected_object_ids.length ? ` — ${clip(s.protected_object_ids.join(", "), 200)}` : ""}`
      );
      L.push(
        `  projection        : blocks_to_archive ${s.blocks_to_archive}, bytes_to_reclaim ` +
          `${s.bytes_to_reclaim}, post_rotation_headroom ${s.post_rotation_headroom} B ` +
          `(close budget ${s.close_budget_bytes} B)`
      );
      /*
       * THE RESOLUTION IS PRINTED ON EVERY RUN, ALLOWED OR REFUSED, for the same
       * reason the floor is: this is the half that LOWERS refusals, so leaving
       * it out would make a widened search indistinguishable from a weakened
       * guard. The withheld member is named too — an unread governed file nobody
       * is told about is a silent scope hole.
       */
      L.push(
        `  identity set      : ${s.identity_sources.map((x) => `${x.path} (${x.declarations} decl)`).join(", ") || "-"}`
      );
      for (const w of s.identity_set_withheld) {
        L.push(`  WITHHELD FROM THE RESOLVER: ${w.path} — ${w.reason}`);
      }
      for (const c of s.cross_file_resolutions) {
        L.push(
          `  cross-file        : ${c.id} (${c.classification}) named at line ${c.named_at_line} ` +
            `-> declared in ${c.declared_path} block ${c.declared_block} line ${c.declared_line}`
        );
      }
      for (const q of s.quoted_references) {
        L.push(
          `  quoted reference  : line ${q.line} (block ${q.block}) names ${q.names.join(", ")} — ` +
            `does NOT raise the floor: ${q.reason}`
        );
      }
      for (const u of s.unresolvable_identities) {
        L.push(`  UNRESOLVED IDENTITY: ${u.id} named at line ${u.named_at_line} — ${u.reason}`);
      }
      for (const a of s.ambiguous_identities) {
        L.push(`  AMBIGUOUS IDENTITY: ${a.id} claimed by ${a.claimants.join(" AND ")}`);
      }
      for (const ref of s.refusals) L.push(`  ${ref.code}: ${ref.detail}`);
    }
    L.push("");
  }
  return L.join("\n");
}

/*
 * AN UNARMED SENTINEL IS THE FAILURE MODE THIS FILE HAS ALREADY PAID FOR ONCE,
 * in `delimiterMatchedNothing`: a guard that finds nothing, reports success, and
 * is indistinguishable from a guard that found nothing to complain about. The
 * two states are separated here the same way and for the same reason, on STDERR
 * so `--json` on stdout stays machine-parseable, and WITHOUT changing the exit
 * code — a scaffolded repo whose memory has no standing region yet is a
 * legitimate unarmed file, not an error.
 */
export function sentinelNotArmed(report) {
  return report.sentinel !== undefined && report.sentinel.armed === false;
}

function renderNotArmedWarning(r) {
  return (
    `SENTINEL NOT ARMED: ${r.path}: the protection scan resolved ZERO protected objects, so ` +
    `minimum_safe_keep is 0 and NO --keep can be refused for this file on the rule's account. ` +
    `Conditions 5 (pre-registration) and 7 (close budget) are NOT applied either. That is correct ` +
    `for a freshly scaffolded or generated memory file and WRONG for a governed one: if this file ` +
    `is supposed to carry standing content, it is carrying none that the scan can see, and the ` +
    `guard is protecting nothing. Exit code is unchanged.`
  );
}

export function main(argv, io = { out: process.stdout, err: process.stderr }) {
  let opts;
  try {
    opts = parseArgs(argv);
  } catch (e) {
    io.err.write(`${e.message}\n`);
    return e.code ?? EXIT.USAGE;
  }
  if (opts.help) {
    io.out.write(USAGE);
    return EXIT.OK;
  }

  const here = path.dirname(fileURLToPath(import.meta.url));
  const root = path.resolve(opts.root ?? path.join(here, "..", ".."));
  const specs = opts.file ? [FILE_SPECS[opts.file]] : Object.values(FILE_SPECS);

  // One batch id for the whole run, fixed BEFORE planning so the planned bytes
  // (banner included) are exactly the bytes an --apply would write.
  const batchId = new Date().toISOString().replace(/\.\d+Z$/, "Z");

  // PLAN EVERYTHING FIRST. If any file fails any assertion, NOTHING is written
  // for ANY file.
  const plans = [];
  try {
    const resolution = buildIdentityIndex(root);
    for (const spec of specs) plans.push(planFile(root, spec, { ...opts, batchId, resolution }));
  } catch (e) {
    io.err.write(`${e.message}\n`);
    return e.code ?? EXIT.RETENTION;
  }

  if (opts.apply) {
    try {
      const rows = [];
      for (const plan of plans) {
        if (plan.report.noop) continue; // idempotent: already rotated
        rows.push(...applyFile(root, plan, batchId));
      }
      if (rows.length > 0) appendIndex(root, rows, batchId);
    } catch (e) {
      io.err.write(`${e.message}\n`);
      return e.code ?? EXIT.IO;
    }
  }

  const reports = plans.map((p) => p.report);
  if (opts.json) {
    io.out.write(
      `${JSON.stringify({ ok: true, mode: opts.apply ? "apply" : "dry-run", root, results: reports }, null, 2)}\n`
    );
  } else {
    io.out.write(`${renderHuman(reports, opts)}\n`);
  }

  // Written AFTER the report and on the OTHER stream, so it is the last thing a
  // human sees and never lands inside `--json` output. See
  // `delimiterMatchedNothing` for why this is a warning and not an error.
  for (const r of reports) {
    if (delimiterMatchedNothing(r)) io.err.write(`${renderDelimiterWarning(r)}\n`);
    if (sentinelNotArmed(r)) io.err.write(`${renderNotArmedWarning(r)}\n`);
  }
  return EXIT.OK;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === path.resolve(process.argv[1])) {
  process.exit(main(process.argv.slice(2)));
}
