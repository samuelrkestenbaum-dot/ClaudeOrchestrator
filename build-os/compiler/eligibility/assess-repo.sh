#!/usr/bin/env bash
# POST-PILOT ELIGIBILITY WORKFLOW — one bounded procedure, seven recorded steps.
#
#   assess-repo.sh --repo <path> --out <dir> [--errors <file>]
#                  [--exclusions <file>] [--deterministic]
#                  [--indexer <path>] [--reporter <path>]
#
# WHAT THIS ANSWERS. AB_PREREGISTRATION AMENDMENT 1 makes repository signal a
# PRECONDITION for EXP-0004: "no_parser share of files admitted-as-candidates
# must be below 50%, measured by `build-index.mjs stats` and RECORDED in the run
# record before arm A begins." This is the procedure that produces that record —
# once, from one pinned commit, with the arithmetic shown — and then either
# hands back a candidate backlog or STOPS.
#
# THE SEVEN STEPS, in order, each written to procedure.tsv as it runs:
#   1 pin-commit         record HEAD and verify the tree is clean (refuse if not)
#   2 index-commit       build the SEAM 1 index of exactly that commit
#   3 capability-report  run the capability reporter over that index
#   4 record-evidence    write ELIGIBILITY.md + eligibility.json
#   5 apply-rule         apply AMENDMENT 1 mechanically, from the reporter's verdict
#   6 stop-if-ineligible halt here when the precondition fails
#   7 emit-backlog       candidates, minus every prior-pilot task
#
# WHY STEP 1 REFUSES A DIRTY TREE. The indexer reads WORKTREE bytes, not the
# blobs of the commit it names. An assessment run over uncommitted changes would
# print a commit sha it did not actually measure, and nobody could reproduce the
# verdict from that sha. Refusing is cheaper than a number that cannot be
# re-derived.
#
# READ-ONLY TOWARD THE TARGET — ABSOLUTELY, NOT BY CONVENTION. PILOT-0002 is
# frozen and has not yet run; a tool that so much as touched its repository
# would put that freeze in question. So:
#   * every artifact goes to --out, and --out INSIDE the target is refused;
#   * every git invocation is a read (rev-parse / status / and, inside the
#     indexer, ls-files and log). There is no checkout here, nothing is set
#     aside, nothing is discarded, nothing is written back;
#   * GIT_OPTIONAL_LOCKS=0 and --no-optional-locks are set so that even git's
#     own opportunistic index refresh cannot write inside the target;
#   * tests/eligibility_workflow_tests.sh hashes every file under a fixture
#     target (including .git) before and after a full run and requires
#     byte-identity, and greps this source for mutating verbs.
# If the target must change for this tool to work, the tool is wrong.
#
# NOT WIRED INTO ANY LIVE PATH. This is an operator-invoked assessment. It calls
# the indexer and the capability reporter as CLIs and changes neither, so what
# the compiler emits during EXP-0004 is unaffected — the stop condition about
# wiring the compiler into a live routing path mid-registration stays clear.
#
# EXIT CODES
#   0  ELIGIBLE      — record written, candidate backlog emitted
#   1  NOT-ELIGIBLE  — record written, task selection STOPS. A legitimate outcome.
#   2  refused before any verdict — bad arguments, unusable target, dirty tree
#   3  refused because the instruments disagree — a defect; no verdict issued
#
# Dependencies: bash, git, node stdlib. No network.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INDEXER="$HERE/../index/build-index.mjs"
REPORTER="$HERE/../capability/report.mjs"
RECORDER="$HERE/record-eligibility.mjs"
EMITTER="$HERE/emit-backlog.mjs"
EXCLUSIONS="$HERE/prior-pilot-exclusions.txt"

usage() {
  cat >&2 <<'EOF'
usage: assess-repo.sh --repo <path> --out <dir> [--errors <file>]
                      [--exclusions <file>] [--deterministic]
                      [--indexer <path>] [--reporter <path>]

  --repo         the repository to assess. READ ONLY: nothing is ever written
                 inside it, and a dirty tree is refused rather than tidied.
  --out          where every artifact goes. Must be OUTSIDE --repo and empty.
  --errors       a tsc-style error list, already produced by the project's own
                 build. Without it no candidate backlog can be generated, and
                 the backlog says so rather than printing an empty list.
  --exclusions   prior-pilot exclusion list (default: prior-pilot-exclusions.txt
                 beside this script).
  --deterministic  zero the wall-clock fields so two runs of one commit are
                 byte-identical.
  --indexer / --reporter
                 override the tools invoked. These exist so the test suite can
                 substitute a deliberately broken instrument and prove this
                 procedure refuses a disagreement instead of picking a winner.
EOF
}

refuse2() { printf 'assess-repo: REFUSED: %s\n' "$1" >&2; exit 2; }

REPO=""; OUTDIR=""; ERRORS=""; DET=""; EXCL_ARG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --repo)        REPO="${2-}"; shift 2 || true ;;
    --out)         OUTDIR="${2-}"; shift 2 || true ;;
    --errors)      ERRORS="${2-}"; shift 2 || true ;;
    --exclusions)  EXCL_ARG="${2-}"; shift 2 || true ;;
    --indexer)     INDEXER="${2-}"; shift 2 || true ;;
    --reporter)    REPORTER="${2-}"; shift 2 || true ;;
    --deterministic) DET=1; shift ;;
    -h|--help)     usage; exit 0 ;;
    *) usage; refuse2 "unknown argument: $1" ;;
  esac
done

[ -n "$REPO" ]   || { usage; refuse2 "--repo is required"; }
[ -n "$OUTDIR" ] || { usage; refuse2 "--out is required"; }
[ -n "$EXCL_ARG" ] && EXCLUSIONS="$EXCL_ARG"

command -v node >/dev/null 2>&1 || refuse2 "node is required"
command -v git  >/dev/null 2>&1 || refuse2 "git is required"
for f in "$INDEXER" "$REPORTER" "$RECORDER" "$EMITTER" "$EXCLUSIONS"; do
  [ -f "$f" ] || refuse2 "missing required file: $f"
done

# Every git read below is opportunistic-lock free, so git cannot refresh (and
# therefore cannot write) the target's index on our behalf.
GIT_OPTIONAL_LOCKS=0
export GIT_OPTIONAL_LOCKS
git_ro() { git --no-optional-locks -C "$REPO" "$@"; }

[ -d "$REPO" ] || refuse2 "not a directory: $REPO"
REPO="$(cd "$REPO" && pwd)"
git_ro rev-parse --git-dir >/dev/null 2>&1 || refuse2 "not a git repository: $REPO"

# --out is resolved BEFORE anything is created, so the inside-the-target check
# can never be reached by a directory this tool already made.
OUT_PARENT="$(dirname "$OUTDIR")"
[ -d "$OUT_PARENT" ] || refuse2 "the parent directory of --out does not exist: $OUT_PARENT"
OUT_PARENT="$(cd "$OUT_PARENT" && pwd)"
OUTDIR="$OUT_PARENT/$(basename "$OUTDIR")"
case "$OUTDIR/" in
  "$REPO"/*) refuse2 "--out is inside the target repository ($OUTDIR).
  This tool never writes inside the target — that is the whole point of it, and
  a frozen pilot repository is the reason. Choose an --out elsewhere." ;;
esac
if [ -e "$OUTDIR" ]; then
  [ -d "$OUTDIR" ] || refuse2 "--out exists and is not a directory: $OUTDIR"
  if [ -n "$(ls -A "$OUTDIR" 2>/dev/null)" ]; then
    refuse2 "--out is not empty: $OUTDIR
  Refusing to write beside stale artifacts from an earlier run: a leftover
  candidates.json or ELIGIBILITY.md would be read as this run's evidence."
  fi
fi
mkdir -p "$OUTDIR" || refuse2 "cannot create --out: $OUTDIR"
[ -n "$ERRORS" ] && { [ -f "$ERRORS" ] || refuse2 "--errors file does not exist: $ERRORS"; }

PROC="$OUTDIR/procedure.tsv"
: >"$PROC"
step() { printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" >>"$PROC"; }
jfield() {
  node -e 'const fs=require("node:fs");let j;try{j=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));}catch{process.exit(0);}
  let v=j;for(const k of process.argv[2].split(".")){v=(v===undefined||v===null)?undefined:v[k];}
  process.stdout.write(v===undefined?"":String(v));' "$1" "$2"
}

# --------------------------------------------------------------------------
# STEP 1 — pin the exact commit, and prove the tree matches it.
# --------------------------------------------------------------------------
COMMIT="$(git_ro rev-parse HEAD 2>/dev/null)"
if [ -z "$COMMIT" ]; then
  step 1 pin-commit refused "no HEAD (unborn branch)"
  refuse2 "the target repository has no HEAD to pin: $REPO
  There is nothing to attribute a verdict to."
fi
PORCELAIN="$(git_ro status --porcelain 2>/dev/null)"
if [ -n "$PORCELAIN" ]; then
  step 1 pin-commit refused "tree is not clean at $COMMIT"
  {
    printf 'assess-repo: REFUSED: the target repository'"'"'s tree is not clean.\n'
    printf '  would-be pinned commit: %s\n' "$COMMIT"
    printf '  but these paths do not match it:\n'
    printf '%s\n' "$PORCELAIN" | sed 's/^/    /'
    cat <<'EOF'
  An eligibility verdict computed against an uncommitted tree is not reproducible.
  The indexer reads worktree bytes, not the blobs of the commit it names, so the
  record would carry a sha that does not contain what was measured, and nobody
  could re-derive the verdict from it later — least of all the operator deciding
  whether a preregistered precondition was really met.
  Resolve the tree yourself and re-run. This tool will not resolve it for you:
  writing inside the target is exactly what it is built never to do.
EOF
  } >&2
  exit 2
fi
step 1 pin-commit ok "$COMMIT (tree clean)"

# --------------------------------------------------------------------------
# STEP 2 — index that exact commit. Output goes to --out; the target is only read.
# --------------------------------------------------------------------------
IDX="$OUTDIR/index.json"
IDXARGS=(build "$REPO" --out "$IDX")
[ -n "$ERRORS" ] && IDXARGS+=(--errors "$ERRORS")
[ -n "$DET" ] && IDXARGS+=(--deterministic)
if ! node "$INDEXER" "${IDXARGS[@]}" 2>"$OUTDIR/index-build.log"; then
  step 2 index-commit failed "the indexer exited non-zero (see index-build.log)"
  sed 's/^/    /' "$OUTDIR/index-build.log" >&2
  refuse2 "could not index $REPO at $COMMIT"
fi
if ! node "$INDEXER" stats "$IDX" >"$OUTDIR/index-stats.txt" 2>>"$OUTDIR/index-build.log"; then
  step 2 index-commit failed "build-index.mjs stats exited non-zero"
  refuse2 "could not read stats from the index just built"
fi
N_FILES="$(sed -n 's/^files_indexed: \([0-9]*\)$/\1/p' "$OUTDIR/index-stats.txt")"
step 2 index-commit ok "index.json (${N_FILES:-?} files), index-stats.txt"

# --------------------------------------------------------------------------
# STEP 3 — the capability reporter, over that index. NO --capsule: before task
# selection there is no capsule, so the admitted-candidate set is the whole
# index and the amendment's number is the whole-repository number.
# --------------------------------------------------------------------------
if ! node "$REPORTER" report --index "$IDX" --json >"$OUTDIR/capability-report.json"; then
  step 3 capability-report failed "the reporter exited non-zero (--json)"
  refuse2 "the capability reporter failed on $IDX"
fi
if ! node "$REPORTER" report --index "$IDX" >"$OUTDIR/capability-report.txt"; then
  step 3 capability-report failed "the reporter exited non-zero (text)"
  refuse2 "the capability reporter failed on $IDX"
fi
step 3 capability-report ok "capability-report.json, capability-report.txt (no --capsule: whole index)"

# --------------------------------------------------------------------------
# STEPS 4 and 5 — record the evidence, then apply the rule mechanically.
# The recorder owns both, and appends its own two rows to procedure.tsv.
# --------------------------------------------------------------------------
RECARGS=(--report-json "$OUTDIR/capability-report.json"
         --report-text "$OUTDIR/capability-report.txt"
         --stats "$OUTDIR/index-stats.txt"
         --repo "$REPO" --commit "$COMMIT" --out "$OUTDIR" --procedure "$PROC")
[ -n "$ERRORS" ] && RECARGS+=(--errors "$ERRORS")
[ -n "$DET" ] && RECARGS+=(--deterministic)
node "$RECORDER" "${RECARGS[@]}"
RRC=$?

NP_TEXT="$(jfield "$OUTDIR/eligibility.json" no_parser_share.text)"
STATE="$(jfield "$OUTDIR/eligibility.json" recommended_use_state)"

if [ "$RRC" = "3" ]; then
  step 6 stop-on-defect refused "instruments disagree; no verdict issued"
  {
    echo 'assess-repo: REFUSED (exit 3) — no eligibility verdict was issued.'
    echo '  The evidence, including the disagreement itself, is recorded in'
    echo "  $OUTDIR/ELIGIBILITY.md. No candidate backlog was emitted."
  } >&2
  exit 3
fi
if [ "$RRC" != "0" ] && [ "$RRC" != "1" ]; then
  step 6 stop-on-defect failed "the recorder exited $RRC"
  refuse2 "the eligibility recorder exited $RRC"
fi

# --------------------------------------------------------------------------
# STEP 6 — STOP if ineligible. This branch is an OUTCOME, not an obstacle.
# --------------------------------------------------------------------------
if [ "$RRC" = "1" ]; then
  step 6 stop-if-ineligible stopped "NOT-ELIGIBLE at $COMMIT; no backlog emitted"
  {
    echo "assess-repo: NOT-ELIGIBLE — $REPO at $COMMIT"
    echo "  no_parser: ${NP_TEXT:-unavailable}   recommended use state: ${STATE:-unavailable}"
    echo "  AMENDMENT 1's precondition is not met, so:"
    echo '  * task selection MUST NOT proceed. Do not pick, cut, or freeze any EXP-0004'
    echo '    task from this repository at this commit.'
    echo '  * bypass the compiler for this repository. Let the worker read and search it'
    echo '    the ordinary way; that is the recommended use state the reporter derived.'
    echo '  * this is a legitimate outcome, not a failure to work around. The amendment'
    echo '    exists because a capsule built from an unparsed index is'
    echo '    small-because-uninformed, and an A/B run here would measure a compiler'
    echo '    operating nearly blind. Lowering the threshold, re-scoping the file set'
    echo '    until it passes, or running anyway are all ways of losing the experiment.'
    echo '    The honest alternatives are: exclude this repository; or (explicit'
    echo '    operator decision) run it and register `result confounded`; or BUILD the'
    echo '    signal — the amendment says adding a shell extractor to the indexer would'
    echo '    satisfy the check, and calls that a build decision, not an amendment.'
    echo "  The full record is $OUTDIR/ELIGIBILITY.md."
  } >&2
  exit 1
fi

# --------------------------------------------------------------------------
# STEP 7 — the candidate backlog, minus every prior-pilot task.
# --------------------------------------------------------------------------
step 6 stop-if-ineligible passed "ELIGIBLE at $COMMIT; procedure continues"
BLARGS=(--index "$IDX" --exclusions "$EXCLUSIONS" --out "$OUTDIR" --repo "$REPO" --commit "$COMMIT")
[ -n "$DET" ] && BLARGS+=(--deterministic)
if ! node "$EMITTER" "${BLARGS[@]}"; then
  step 7 emit-backlog failed "the backlog emitter exited non-zero"
  refuse2 "the candidate backlog could not be emitted (the eligibility record stands)"
fi
N_CAND="$(jfield "$OUTDIR/candidates.json" candidate_count)"
N_EXCL="$(jfield "$OUTDIR/candidates.json" excluded_count)"
step 7 emit-backlog ok "candidates.json, CANDIDATES.md (${N_CAND:-?} candidates, ${N_EXCL:-?} excluded)"
{
  echo "assess-repo: ELIGIBLE — $REPO at $COMMIT"
  echo "  no_parser: ${NP_TEXT:-unavailable}   recommended use state: ${STATE:-unavailable}"
  echo "  record:  $OUTDIR/ELIGIBILITY.md"
  echo "  backlog: $OUTDIR/CANDIDATES.md — ${N_CAND:-?} CANDIDATE(S), ${N_EXCL:-?} excluded as"
  echo '  prior-pilot work. These are candidates FOR selection, not a selection:'
  echo '  choosing and freezing the EXP-0004 task set is a separate, operator-gated step.'
} >&2
exit 0
