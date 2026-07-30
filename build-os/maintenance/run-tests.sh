#!/usr/bin/env bash
# GRAVITO:MANAGED — shipped by build-os/maintenance/install-maintenance.sh.
# Edits made in an installed repo are REPLACED on the next install.
#
#
# run-tests.sh -- THE SANCTIONED WAY TO RUN build-os/maintenance/'s tests.
#
#   ./build-os/maintenance/run-tests.sh
#   ./build-os/maintenance/run-tests.sh --test-concurrency=1
#
# Anything after the script name is passed to node as an option, before the
# suite files.
#
# ---------------------------------------------------------------------------
# THE GUARANTEE, STATED EXACTLY. NOTHING OUTSIDE THIS SENTENCE IS CLAIMED.
# ---------------------------------------------------------------------------
#
#   A run under `./build-os/maintenance/run-tests.sh` cannot report success
#   after moving the real tree between the two shell fingerprints, provided the
#   `sha256sum`/`shasum` resolved at startup is the real one and no write is
#   scheduled to land after node exits.
#
# It is bounded on purpose. It says nothing about PREVENTING a write, nothing
# about any other invocation, and nothing about damage that lands outside the
# window between the two fingerprints. The paths it does NOT cover, named --
# these four, and no others:
#
#   - a hostile `sha256sum`/`shasum` ALREADY ON PATH AT INVOCATION. The hasher is
#     resolved once, at startup, through PATH, and every later use goes through
#     the captured path; `command -v` reads the same PATH, so resolution cannot
#     outrank a PATH that was already hostile when you typed the command. Note
#     what this does NOT include, because it is a real narrowing and was
#     measured: a hasher planted DURING the run no longer works at all.
#   - a write scheduled to land AFTER node exits (see the detached-child note
#     below). The delay is chosen by whoever wrote the line, so no later
#     fingerprint closes it.
#   - a bare `node --test`, in every form. It takes no preload and takes no
#     outer fingerprint. The in-process tripwire's coverage scan runs there only
#     after some file has already imported it, and its source mask has now been
#     defeated three times; treat that path as UNGUARDED rather than as
#     "detects, late".
#   - hostile tampering with this shell itself -- a test body that kills the
#     wrapper before the second fingerprint is taken, or that otherwise subverts
#     the shell the fingerprints run in. Every one of those has to be written to
#     attack this file specifically.
#
# (A test body that damages the real tree and restores it BYTE-FOR-BYTE before
# the run ends is deliberately not in that list: byte-identical restoration is
# indistinguishable from no damage by content hash, and is also not damage.)
#
# ---------------------------------------------------------------------------
# WHAT "CONTAINED" MEANS HERE, AND WHAT IT DOES NOT
# ---------------------------------------------------------------------------
# Containment here is discoverability plus out-of-process detection via the
# sanctioned wrapper, not enforcement: nothing prevents a hand-run bare
# `node --test`, which takes no preload and no outer fingerprint.
#
# DISCOVERABILITY IS CONDITIONAL ON THE REPO HAVING A package.json, and this
# layer installs into repos that may have none (it is not a Node project layer).
# WHERE ONE EXISTS, the installer adds `test:build-os-memory`, whose body is
# exactly this file's invocation, so the command is findable from the repo root
# rather than only by already knowing its path. That script's name, its body, and
# the absence of any package script running a bare runner against build-os/ are
# pinned by rotate-memory.rootscan.test.mjs -- which, when there is no
# package.json, pins instead that this file is executable and named in
# build-os/maintenance/PORTING.md. A package entry is a signpost, and a signpost
# detects nothing: the four uncovered paths listed above are exactly as long a
# list as they were before it existed, and one less signpost is not one more
# hole.
#
# ---------------------------------------------------------------------------
# WHY A WRAPPER AND NOT "run the files"
# ---------------------------------------------------------------------------
# These tests exercise a tool that REWRITES BUILD OS MEMORY, so the thing that
# has to be true of the suite is not "it passes" but "it cannot quietly rewrite
# the real tree". Two mechanisms live here, and neither can live in a test file:
#
#   1. THE PRELOAD.  `--import <the tripwire>` loads the real-memory tripwire
#      BEFORE any test file's module graph is touched, in the runner and in every
#      test child. Without it, "the tripwire is the first import of every suite
#      file" is a claim about how the imports are SPELLED, and it was defeated by
#      a single leading space:
#
#          ␠␠import "./payload.mjs";
#          import "./real-memory-tripwire.mjs";
#
#      The payload ran first, the tripwire baselined the already-damaged tree,
#      and -- measured in the reference deployment, at the commit before this
#      change --
#      `node --test --test-concurrency=1 build-os/maintenance/*.test.mjs`
#      reported a full green run (0 fail / exit 0) with all three real memory
#      files destroyed and a real archive created. The preload does not care what
#      column an import is written at, and does not care whether the test file
#      has any imports at all. With it, those shapes give 0 pass / EXIT 1 AND AN
#      UNTOUCHED TREE, because the tripwire's coverage scan now runs before any
#      test file is loaded -- the failure count is simply one per suite file in
#      this directory, the offending file included, so it moves with the
#      directory rather than meaning anything on its own. RE-MEASURED IN THIS
#      PORT, in a fresh install into a blank repo: 0 pass / 3 fail / exit 1 for a
#      planted file with no static imports at all, tree untouched. That is why
#      this script, and not `node --test`, is the documented command in every
#      file header here.
#
#   2. THE OUTER FINGERPRINT.  The four watched real memory files -- the three
#      the rotation tool rewrites, plus the never-rotated
#      `build-os/memory/standing_gates.md` -- and the real archive
#      directory are hashed before and after the node run, IN THIS SHELL. The
#      tripwire's own check is a `process.on("exit")` handler, and an exit
#      handler is last-registered-wins: a test body can set `process.exitCode`
#      back to 0 from a later handler, or call `removeAllListeners("exit")` and
#      delete it. Both were demonstrated in the reference deployment; both leave
#      a damaged tree at exit 0 under a bare `node --test`, and one of them was
#      measured there as a fully green node run exiting 0 -- and this wrapper
#      exiting 1.
#
# WHAT THIS DOES NOT COVER, enumerated rather than implied away. A test body that
#
#   1. KILLS THIS SHELL, so the second fingerprint is never taken.
#
#   2. RESTORES THE TREE BYTE-FOR-BYTE before the run ends, which is not damage.
#
#   3. PLANTS AN EXECUTABLE NAMED `sha256sum` (or `cut`, or `find`, or `sort`)
#      EARLIER ON PATH THAN THE REAL ONE. Two of the four legs of that attack are
#      gone and the other two are bounded; the residual is stated rather than the
#      fix overstated:
#        - `cut` is no longer on the path at all. The hash field is taken with a
#          bash parameter expansion, so a planted `cut` has nothing to defeat.
#          The guarantee sentence above no longer names it: a clause naming a
#          tool this script does not run is not a bound, it is noise.
#        - `sha256sum`/`shasum`, `find` and `sort` are resolved ONCE, before the
#          run, and every later use goes through the captured path (absolute,
#          for any PATH entry that is itself absolute). A hasher planted DURING
#          the run -- by a test body writing an executable into a PATH directory
#          -- no longer gets used. MEASURED, on a clone, with an empty directory
#          prepended to PATH and a planted suite file that drops a marker-writing
#          `sha256sum` into it while the suite is running: at this commit the
#          marker is NEVER written; at the commit before it, it is. A hasher
#          already on PATH when you typed the command still wins, because the
#          resolution itself goes through PATH. That case is NOT closed, and it
#          is the ONLY hasher case that is not -- which is why the guarantee
#          sentence says "resolved at startup" rather than naming the tools flat.
#        - a subverted `find`/`sort` is FAIL-CLOSED for the whole-suite case:
#          the same two resolved binaries build the suite list below, so a
#          `find` that returns nothing makes this script exit 6 with no tests
#          run rather than fingerprint a tree it cannot see. MEASURED, with a
#          `find` on PATH that prints nothing and exits 0: exit 6, "no
#          *.test.mjs found ... refusing to pass vacuously". What that argument
#          does NOT cover is a `find` that answers the suite query truthfully
#          and the archive query falsely. Even then it is confined to the
#          ARCHIVE half: the four watched files are hashed by the loop above
#          it, which uses neither tool.
#
#   4. SCHEDULES A WRITE THAT LANDS AFTER NODE EXITS. Measured on a clone of the
#      reference deployment, with a planted suite file whose body is
#        `spawn(node, ["-e", "setTimeout(destroy_all_three, 20000)"],
#               { detached: true, stdio: "ignore" }).unref()`:
#      0 fail, node exits 0, AFTER is taken while the tree is still
#      intact, this script exits 0 -- and all three real memory files are
#      destroyed twenty seconds later, with `git status` then showing them
#      modified but the run long since reported green.
#      THE SAME OPEN PATH REACHES THE GATES FILE, AND BEING WATCHED IS NOT BEING
#      PROTECTED: the newly watched, never-rotated
#      `build-os/memory/standing_gates.md` is as exposed to a write that lands
#      after node exits as the three rotating files are -- measured this pass, a
#      late-sorting planted file scheduling a detached write 6 s out damaged the
#      gates file with the suite at 0 fails, node and this script both exiting 0,
#      and no fingerprint diff printed -- so the "all three" figure above
#      describes the payload that was measured (`destroy_all_three`), not the
#      extent of this case.
#      TWO THINGS BOUND IT, and neither closes it:
#        - the write has to land INSIDE the window to be caught, and the rule for
#          that is NOT "the delay must outlast the run". This comment used to
#          imply it was, by comparing one 6 s delay against a ~8 s suite. The rule
#          is per-payload and schedule-dependent: the write is caught iff
#          (the moment the payload file runs) + (the delay) < (node's exit).
#          MEASURED: the SAME 6 s delay against the SAME suite was caught when the
#          planted file sorted EARLY in the run, and escaped green when it sorted
#          LATE -- the suite's total duration never entered into it. The delay and
#          the filename are both chosen by whoever wrote the line, so THIS CASE
#          REMAINS OPEN; nothing here narrows it to "long delays only".
#        - an UNDETACHED unawaited spawn is caught, because node waits for the
#          child before it exits and AFTER is therefore taken after the write.
#          Measured: exit 1.
#      Detaching defeats the window itself, so a third fingerprint taken later
#      would only move the number. Not covered, and not coverable here.
#
# Cases 1, 3 and 4 need a body written to attack this file specifically. That is
# a different threat model from the accidental line these mechanisms exist for,
# and it is not claimed as closed.
#
# NEITHER MECHANISM PREVENTS A WRITE. The tripwire hashes, it does not intercept;
# this wrapper compares, it does not sandbox. What the preload prevents is a test
# file running before the tripwire is armed. What the two hashing checks give is
# the guarantee sentence at the top of this file -- and only that.
#
# THE TWO LINES THAT TURN DETECTION INTO A FAILED RUN are the tripwire's
# `process.exitCode = 1` and the `[ "${BEFORE}" != "${AFTER}" ]` comparison at
# the foot of this script. Both were unpinned by any test while their detection
# halves were well covered -- so neutering either was invisible to a green
# suite. Both are pinned now: the comparison statically, by
# `rotate-memory.rootscan.test.mjs`, and `process.exitCode = 1` by an executed
# mutation driver in `rotate-memory.test.mjs`.
#
# THEY ARE MUTUALLY REDUNDANT, MEASURED. On a clone, with a planted suite file
# that damages a real memory file from an `exit` handler and then calls
# `removeAllListeners("exit")` and sets `process.exitCode = 0`: both lines
# present -> exit 1 with this script's fingerprint diff printed; the tripwire's
# `process.exitCode = 1` deleted -> exit 1, still from this script's diff; this
# script's comparison deleted -> exit 1, from node's own status instead. No
# SINGLE edit to either line yields green-with-damage. Editing both does, and
# neither line prevents the write.
#
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
ARCHIVE_DIR="${REPO_ROOT}/build-os/memory/archive"

# The four real files this script fingerprints, repo-relative: the three
# rotate-memory.mjs rewrites in place, PLUS build-os/memory/standing_gates.md,
# which it must never touch. The gates file is here because being outside the
# rotation tool's blast radius is protection from THE TOOL only -- it was watched
# by neither this list nor the tripwire's, so a test body that rewrote the
# authority for hard stops exited 0 in silence. Pinned equal to the tripwire's
# REAL_MEMORY_FILES by rotate-memory.rootscan.test.mjs.
WATCHED=(
  "build-os/memory/current_state.md"
  "build-os/memory/residue.md"
  "build-os/packets/active_packet.md"
  "build-os/memory/standing_gates.md"
)

if ! command -v node >/dev/null 2>&1; then
  echo "run-tests: node is required but was not found on PATH" >&2
  exit 6
fi
if [ ! -f "${SCRIPT_DIR}/real-memory-tripwire.mjs" ]; then
  echo "run-tests: the real-memory tripwire is missing; refusing to run unarmed" >&2
  exit 6
fi

# EVERY EXTERNAL TOOL THIS SCRIPT USES IS RESOLVED ONCE, HERE, and every later
# use goes through the captured path rather than through PATH. A test body that
# writes an executable named `sha256sum` into a PATH directory DURING the run
# therefore changes nothing. A PATH that was already hostile when you invoked
# this script is a different case and is not closed -- `command -v` reads the
# same PATH. See item 3 of the header.
#
# `cut` was removed rather than resolved: the hash field is taken with `${h%% *}`,
# which is bash itself.
HASHER=()
if _h="$(command -v sha256sum 2>/dev/null)"; then
  HASHER=("${_h}")
elif _h="$(command -v shasum 2>/dev/null)"; then
  HASHER=("${_h}" -a 256)
fi
FIND_BIN="$(command -v find 2>/dev/null)" || FIND_BIN=""
SORT_BIN="$(command -v sort 2>/dev/null)" || SORT_BIN=""

fingerprint() {
  if [ ${#HASHER[@]} -eq 0 ]; then
    echo "OUTER-FINGERPRINT-UNAVAILABLE"
    return 0
  fi
  local rel f h
  for rel in "${WATCHED[@]}"; do
    f="${REPO_ROOT}/${rel}"
    if [ -f "${f}" ]; then
      h="$("${HASHER[@]}" < "${f}")"
      printf '%s %s\n' "${rel}" "${h%% *}"
    else
      printf '%s ABSENT\n' "${rel}"
    fi
  done
  if [ -d "${ARCHIVE_DIR}" ]; then
    "${FIND_BIN}" "${ARCHIVE_DIR}" -type f -print0 | LC_ALL=C "${SORT_BIN}" -z |
      while IFS= read -r -d '' f; do
        h="$("${HASHER[@]}" < "${f}")"
        printf '%s %s\n' "${f#"${REPO_ROOT}/"}" "${h%% *}"
      done
  else
    printf '%s ABSENT\n' "build-os/memory/archive/"
  fi
}

if [ -z "${FIND_BIN}" ] || [ -z "${SORT_BIN}" ]; then
  echo "run-tests: find and sort are required, both to discover the suite files and to" >&2
  echo "           fingerprint the real archive. Refusing to run a suite this script" >&2
  echo "           cannot enumerate." >&2
  exit 6
fi

if [ ${#HASHER[@]} -eq 0 ]; then
  echo "run-tests: neither sha256sum nor shasum was found; the OUTER real-memory" >&2
  echo "           fingerprint is unavailable on this machine. The in-process" >&2
  echo "           tripwire still runs; the two hostile-handler shapes named in" >&2
  echo "           this script's header are NOT covered on this path." >&2
fi

# every *.test.mjs beside this script, recursively -- the same walk the tripwire's
# own coverage scan does, so a file in a subdirectory is run as well as reported
SUITE=()
while IFS= read -r -d '' f; do
  SUITE+=("${f}")
done < <("${FIND_BIN}" "${SCRIPT_DIR}" -type f -name '*.test.mjs' -print0 | LC_ALL=C "${SORT_BIN}" -z)

if [ ${#SUITE[@]} -eq 0 ]; then
  echo "run-tests: no *.test.mjs found beside ${SCRIPT_DIR} -- refusing to pass vacuously" >&2
  exit 6
fi

BEFORE="$(fingerprint)"

node --import "${SCRIPT_DIR}/real-memory-tripwire.mjs" --test "$@" "${SUITE[@]}"
status=$?

AFTER="$(fingerprint)"

if [ "${BEFORE}" != "${AFTER}" ]; then
  {
    echo ""
    echo "=== REAL BUILD OS MEMORY WAS MUTATED BY THIS TEST RUN ==="
    echo "Detected OUTSIDE node, by comparing sha256 fingerprints taken before and"
    echo "after the run. node itself exited ${status}; this comparison is made and"
    echo "reported whatever that was, and nothing inside node can unwind it."
    echo ""
    diff <(printf '%s\n' "${BEFORE}") <(printf '%s\n' "${AFTER}") || true
    echo ""
    echo "\`git status\` DOES show the archive appear (one \`??\` line on the directory), but"
    echo "that one line reads the same however its contents changed, and nothing under it"
    echo "has version-control backing until it is committed. The fingerprints above, not"
    echo "git, are what detected this."
    echo "Restore from git and find the invocation that reached the real root."
  } >&2
  exit 1
fi

exit ${status}
