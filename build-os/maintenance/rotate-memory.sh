#!/usr/bin/env bash
# GRAVITO:MANAGED — shipped by build-os/maintenance/install-maintenance.sh.
# Edits made in an installed repo are REPLACED on the next install.
#
#
# rotate-memory.sh — ROTATION (not truncation) of Build OS memory.
#
# Build OS memory grows monotonically: every closed packet appends. Past the
# agent's 256 KB Read limit a memory file stops being readable at all, so a
# session starts unable to read its own state. This tool keeps the newest N
# blocks live and moves the tail into an append-only archive, BEFORE that
# happens. It is preventative, and says nothing about how big your files are
# today — run it with no arguments and it will tell you (dry run is the default).
#
# (In the reference deployment at commit `cb2bb7d` all three hot files HAD
# crossed that limit, which is why this exists. That is history, not a claim
# about this repo.)
#
# IT PERFORMS GENERATED-BANNER REPLACEMENT -- deliberately not phrased as "it
# deletes nothing". Exactly one class of byte reaches neither output, and it is
# named rather than glossed: a prior ARCHIVE-POINTER BANNER -- bytes this tool
# itself generated on an earlier run, in its own anchored slot at the preamble
# tail -- is REPLACED in place. The report prints the count ("prior banner : N B
# REPLACED in place") and withdraws the byte-exact claim on such a run. When that
# count is 0, every byte of the original is accounted for by exactly one output.
#
#   ./build-os/maintenance/rotate-memory.sh              # DRY RUN (the default)
#   ./build-os/maintenance/rotate-memory.sh --apply      # actually write
#   ./build-os/maintenance/rotate-memory.sh --help
#
# SELECTION IS BY RECENCY ONLY:
#   The newest N blocks per file stay live; everything older is archived. There
#   is no protected section and no guarantee about which content survives BY
#   MEANING -- a standing gate sitting in the archive region is archived like
#   anything else. Content that must never rotate belongs in a file this tool
#   does not know about, i.e. one absent from FILE_SPECS in the .mjs. The path
#   designated for that is build-os/memory/standing_gates.md, which this tool
#   never reads, writes or creates.
#
# WHAT COUNTS AS A BLOCK IS THE SCAFFOLD'S FORMAT:
#   FILE_SPECS' delimiters are coupled to the memory format the Gravito
#   installers write. A delimiter that matches nothing yields a REPORTED NO-OP
#   at exit 0, not an error -- so if you have rewritten your memory files in
#   another convention, read the FILE_SPECS comment in the .mjs before trusting
#   a zero. You are told: zero blocks in a file that HAS non-whitespace content
#   raises a WARNING ON STDERR naming the file and the delimiter that matched
#   nothing. The exit code is deliberately unchanged -- an empty or
#   not-yet-written memory file parses to zero blocks legitimately, and failing
#   a run on that would be wrong. An empty file therefore stays quiet.
#   `--json` reports `totalBlocks` and `originalHasContent` per file; 0 with
#   `true` is the same tell, machine-readable.
#
# WHY build-os/maintenance/ AND NOT build-os/tools/:
#   build-os/tools/ is the Build OS bootstrap's managed set (supervise,
#   capability-profile, specialist-handoff, ...). A script placed there is
#   ambiguous in ownership and would be overwritten the day canonical ships the
#   same name. This tool is repo maintenance, so it lives in its own directory.
#
# WHY THE LOGIC IS IN rotate-memory.mjs:
#   This tool rewrites the project's memory, so byte-exactness is the whole
#   product. The implementation runs the content through a latin1 byte pipeline
#   where one character is exactly one byte, which shell word-splitting and
#   command substitution cannot express safely (both mangle trailing newlines).
#   This file is the stable entry point and argument surface; the .mjs beside it
#   is the verified implementation. Run this one.
#
# SAFETY:
#   - dry-run is the DEFAULT; writing requires an explicit --apply
#   - segment-partition conservation runs before any write, for every file; if
#     any file fails it, NOTHING is written for ANY file
#   - a routing-reconstruction check requires the retained bytes followed by the
#     archived bytes to BE the original file, so an interleaved cut is refused
#   - a second, post-composition byte check compares the exact string about to
#     be written against an independently derived expectation, so composition
#     cannot lose a byte of retained content silently
#   - the bytes composition drops are audited BY CONTENT: they must parse as a
#     banner this tool generated, so a marker-wrapped note somebody hand-wrote
#     into a preamble is preserved instead of being consumed as if it were one
#   - the archive is append-only, one file per source, and is never rewritten
#   - a post-rotation size ceiling breach exits non-zero and NEVER auto-reduces N
#   - every rotated file carries a fixed-SHAPE, bounded archive-pointer banner
#     naming the batch, the counts and the exact archive paths, so a shortened
#     file cannot be mistaken for the whole record. Not fixed-SIZE: the banner
#     interpolates decimal counts, so its byte length moves with their digits
#     (503-513 B measured)
#   - that banner is REPLACED, not accumulated, on every apply -- WHILE IT STILL
#     SITS IN ITS ANCHORED SLOT at the tail of the preamble. The strip is
#     positional, so a later edit can displace it without altering a byte of it
#     (insert a block immediately after the end-marker and the blank line the
#     banner owns is consumed). The tool then REFUSES to strip it rather than
#     risk eating content, and writes its banner beside the displaced one.
#     Measured cost: ONE orphaned banner (~505 B) PER DISPLACING EDIT, and
#     rotation alone never adds another -- no source bytes are lost, the new
#     banner is anchored correctly and is replaced normally from then on, so
#     repeated rotation is bounded at two banners and does not reach three. The
#     orphan's real harm is not its size but that it keeps STALE counts while
#     still reading as authoritative
#
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v node >/dev/null 2>&1; then
  echo "rotate-memory: node is required but was not found on PATH" >&2
  exit 6
fi

exec node "${SCRIPT_DIR}/rotate-memory.mjs" "$@"
