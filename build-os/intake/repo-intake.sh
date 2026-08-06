#!/usr/bin/env bash
# Gravito — second-repository intake (LANE 3).
#
# repo-intake.sh <target-repo> [--out <report-dir>] [--run-baseline]
#
# WHAT THIS IS. The procedure Gravito runs the moment it enters a repository it
# has never seen. It produces two artifacts in the report dir (a mktemp dir by
# default — the TARGET is never written unless --out points into it):
#
#   INTAKE_REPORT.md   the human-readable intake, section by section
#   intake.json        the machine-readable copy, including the task-graph seed
#
# THE HONESTY DOCTRINE, which is the whole point of this file:
#
#   * Every language/framework finding carries an explicit CONFIDENCE, and a
#     repo that matches nothing gets an explicit UNRECOGNIZED line — not a
#     silent best guess.
#   * Every command is labeled DISCOVERED (read out of a manifest the repo
#     wrote) or GUESSED (an ecosystem convention this script supplied). A guess
#     is never presented as a discovery.
#   * The baseline is OFF by default. Without --run-baseline the report says
#     BASELINE: NOT MEASURED and makes no red/green claim, because a baseline
#     nobody ran is not a baseline.
#   * Secrets-shaped files are flagged by NAME PATTERN ONLY. Their contents are
#     never read, never printed, never summarized. The report gets the path and
#     nothing else.
#   * Task-graph entries are CANDIDATES, not commitments — the operator routes.
#   * Everything the intake could NOT determine is listed under Unsupported
#     assumptions, including the standing limits of these heuristics.
#
# READS the target repo; WRITES only the report dir. No network. Baseline
# commands (opt-in) run inside the target with a timeout
# (INTAKE_BASELINE_TIMEOUT seconds, default 120) and may do whatever the
# repo's own test command does — that is why they are opt-in.
set -uo pipefail

usage(){
  echo "usage: repo-intake.sh <target-repo> [--out <report-dir>] [--run-baseline]"
}

TARGET=""
OUTDIR=""
RUN_BASELINE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --out) OUTDIR="${2:-}"; shift 2 || { usage >&2; exit 2; } ;;
    --run-baseline) RUN_BASELINE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "repo-intake.sh: unknown option: $1" >&2; usage >&2; exit 2 ;;
    *) if [ -z "$TARGET" ]; then TARGET="$1"; shift; else
         echo "repo-intake.sh: unexpected argument: $1" >&2; usage >&2; exit 2
       fi ;;
  esac
done
if [ -z "$TARGET" ] || [ ! -d "$TARGET" ]; then
  echo "repo-intake.sh: target repo dir required and must exist" >&2
  usage >&2; exit 2
fi
TARGET="$(cd "$TARGET" && pwd)"

if [ -z "$OUTDIR" ]; then
  OUTDIR="$(mktemp -d "${TMPDIR:-/tmp}/gravito-intake.XXXXXX")"
else
  mkdir -p "$OUTDIR"
fi
OUTDIR="$(cd "$OUTDIR" && pwd)"
REPORT="$OUTDIR/INTAKE_REPORT.md"
JSON="$OUTDIR/intake.json"
BTIMEOUT="${INTAKE_BASELINE_TIMEOUT:-120}"

# Scratch records the JSON assembler reads. TSV, one finding per line.
REC="$(mktemp -d)"
trap 'rm -rf "$REC"' EXIT
: > "$REC/languages.tsv";  : > "$REC/frameworks.tsv"; : > "$REC/commands.tsv"
: > "$REC/instructions.tsv"; : > "$REC/surfaces.tsv"; : > "$REC/authority.tsv"
: > "$REC/baseline.tsv"; : > "$REC/candidates.tsv"; : > "$REC/assumptions.txt"

lang(){ printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$REC/languages.tsv"; }
fw(){   printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$REC/frameworks.tsv"; }
cmdrec(){ printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" >> "$REC/commands.tsv"; }
instr(){ printf '%s\t%s\n' "$1" "$2" >> "$REC/instructions.tsv"; }
surf(){ printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$REC/surfaces.tsv"; }
auth(){ printf '%s\t%s\n' "$1" "$2" >> "$REC/authority.tsv"; }
assume(){ printf '%s\n' "$1" >> "$REC/assumptions.txt"; }
cand(){ printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$REC/candidates.tsv"; }

# ------------------------------------------- language & framework detection --
# Best-effort by manifest presence. Manifest presence = HIGH confidence for the
# language; a dependency NAME in that manifest = MEDIUM for a framework hint.
if [ -f "$TARGET/package.json" ]; then
  PKG_PARSED=1
  # Parse with python3 (already a repo-wide dependency of the installers).
  # Emits: SCRIPT<TAB>name  and  DEP<TAB>name  lines; PARSE-ERROR on bad JSON.
  if ! python3 - "$TARGET/package.json" > "$REC/pkg.tsv" 2>/dev/null <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
for name in (data.get("scripts") or {}):
    print("SCRIPT\t%s" % name)
for key in ("dependencies", "devDependencies"):
    for name in (data.get(key) or {}):
        print("DEP\t%s" % name)
PY
  then
    PKG_PARSED=0
  fi
  if [ "$PKG_PARSED" -eq 1 ]; then
    lang "node" "package.json present" "HIGH"
    for hint in react vue next express vitest jest; do
      if grep -qx "DEP	$hint" "$REC/pkg.tsv"; then
        fw "$hint" "\"$hint\" named as a dependency in package.json" "MEDIUM"
      fi
    done
    grep -qx "SCRIPT	test" "$REC/pkg.tsv" \
      && cmdrec "test" "npm test" "DISCOVERED" "package.json scripts.test"
    grep -qx "SCRIPT	build" "$REC/pkg.tsv" \
      && cmdrec "build" "npm run build" "DISCOVERED" "package.json scripts.build"
    grep -qx "SCRIPT	lint" "$REC/pkg.tsv" \
      && cmdrec "lint" "npm run lint" "DISCOVERED" "package.json scripts.lint"
    grep -qx "SCRIPT	typecheck" "$REC/pkg.tsv" \
      && cmdrec "typecheck" "npm run typecheck" "DISCOVERED" "package.json scripts.typecheck"
    if ! grep -qx "SCRIPT	test" "$REC/pkg.tsv"; then
      if grep -qx "DEP	vitest" "$REC/pkg.tsv"; then
        cmdrec "test" "npx vitest run" "GUESSED" "vitest is a dependency but no scripts.test exists"
      elif grep -qx "DEP	jest" "$REC/pkg.tsv"; then
        cmdrec "test" "npx jest" "GUESSED" "jest is a dependency but no scripts.test exists"
      fi
    fi
  else
    lang "node" "package.json present but UNPARSEABLE as JSON" "LOW"
    assume "package.json exists but could not be parsed; node scripts and dependencies are unknown"
  fi
fi
if [ -f "$TARGET/pyproject.toml" ] || [ -f "$TARGET/requirements.txt" ] || [ -f "$TARGET/setup.py" ]; then
  PYEV="pyproject.toml"
  [ -f "$TARGET/pyproject.toml" ] || { [ -f "$TARGET/requirements.txt" ] && PYEV="requirements.txt"; } || PYEV="setup.py"
  lang "python" "$PYEV present" "HIGH"
  cmdrec "test" "pytest" "GUESSED" "pytest convention for python projects; not read from any manifest"
fi
if [ -f "$TARGET/go.mod" ]; then
  lang "go" "go.mod present" "HIGH"
  cmdrec "test" "go test ./..." "GUESSED" "go toolchain convention"
  cmdrec "build" "go build ./..." "GUESSED" "go toolchain convention"
fi
if [ -f "$TARGET/Cargo.toml" ]; then
  lang "rust" "Cargo.toml present" "HIGH"
  cmdrec "test" "cargo test" "GUESSED" "cargo convention"
  cmdrec "build" "cargo build" "GUESSED" "cargo convention"
fi
if [ -f "$TARGET/Gemfile" ]; then
  lang "ruby" "Gemfile present" "HIGH"
  cmdrec "test" "bundle exec rake test" "GUESSED" "rake convention; Rakefile not verified"
fi
if [ -f "$TARGET/pom.xml" ]; then
  lang "java (maven)" "pom.xml present" "HIGH"
  cmdrec "test" "mvn -q test" "GUESSED" "maven convention"
fi
if [ -f "$TARGET/build.gradle" ] || [ -f "$TARGET/build.gradle.kts" ] || [ -f "$TARGET/gradlew" ]; then
  lang "java/kotlin (gradle)" "gradle build file present" "HIGH"
  cmdrec "test" "./gradlew test" "GUESSED" "gradle convention"
fi

UNRECOGNIZED=0
if [ ! -s "$REC/languages.tsv" ]; then
  UNRECOGNIZED=1
  assume "language could not be determined — no recognized manifest (package.json, pyproject.toml, requirements.txt, setup.py, go.mod, Cargo.toml, Gemfile, pom.xml, gradle) was found"
  cand "identify-stack" "identify the stack manually" "no recognized manifest; a human or a deeper probe must name the language before any build task is cut"
fi

# --------------------------------------------------- repo-local instructions --
if [ -f "$TARGET/CLAUDE.md" ]; then instr "CLAUDE.md" "present"; else instr "CLAUDE.md" "absent"; fi
if [ -d "$TARGET/.claude" ]; then
  instr ".claude/" "present"
  if [ -f "$TARGET/.claude/settings.json" ]; then instr ".claude/settings.json" "present"; else instr ".claude/settings.json" "absent"; fi
  if [ -d "$TARGET/.claude/hooks" ]; then
    NHOOKS="$(find "$TARGET/.claude/hooks" -maxdepth 1 -name '*.sh' -type f 2>/dev/null | grep -c . || true)"
    instr ".claude/hooks/" "present (${NHOOKS} hook script(s))"
  else
    instr ".claude/hooks/" "absent"
  fi
else
  instr ".claude/" "absent"
fi
CONTRIB="$(find "$TARGET" -maxdepth 1 -iname 'CONTRIBUTING*' -type f 2>/dev/null)"
if [ -n "$CONTRIB" ]; then instr "CONTRIBUTING" "present"; else instr "CONTRIBUTING" "absent"; fi
READMEF="$(find "$TARGET" -maxdepth 1 -iname 'README*' -type f 2>/dev/null | sort | sed -n '1p')"
if [ -n "$READMEF" ]; then
  if grep -Eiq '^#+ +.*(build|test|install|develop|getting started)' "$READMEF"; then
    instr "README build/test sections" "present (headings mention build/test/install)"
  else
    instr "README build/test sections" "README exists but no build/test headings found"
  fi
else
  instr "README build/test sections" "no README"
fi

# ------------------------------------------------------ mutation-surface map --
# Top-level directories, classified by NAME heuristic only. The heuristic is
# stated on every row so a reader can reject it.
while IFS= read -r d; do
  b="$(basename "$d")"
  case "$b" in
    .git) continue ;;
    test|tests|spec|__tests__|e2e) surf "$b/" "test" "conventional test-directory name" ;;
    src|lib|app|cmd|pkg|internal|source) surf "$b/" "source" "conventional source-directory name" ;;
    docs|doc) surf "$b/" "docs" "conventional docs-directory name" ;;
    .github|.claude|config|conf|.circleci|.vscode) surf "$b/" "config" "conventional config-directory name" ;;
    node_modules|dist|build|out|target|vendor|coverage|.venv|venv|__pycache__) surf "$b/" "generated" "conventional generated/vendored-directory name" ;;
    migrations|migrate|db) surf "$b/" "migration" "conventional migration-directory name"
       auth "$b/" "migration dir — schema changes are load-bearing" ;;
    infra|terraform|deploy|k8s|kubernetes|helm|ansible|charts) surf "$b/" "infra" "conventional infra-directory name"
       auth "$b/" "infra/deploy dir — changes here reach past the repo" ;;
    *) surf "$b/" "unknown" "no naming convention matched"
       cand "explore-$b" "explore unrecognized area: $b/" "top-level dir matched no classification heuristic; walk it before assuming anything" ;;
  esac
done < <(find "$TARGET" -mindepth 1 -maxdepth 1 -type d | sort)

# CI configs — authority-sensitive by definition (they run with deploy power).
if [ -d "$TARGET/.github/workflows" ]; then
  while IFS= read -r wf; do
    auth ".github/workflows/$(basename "$wf")" "CI/deploy configuration (flagged by NAME pattern only)"
  done < <(find "$TARGET/.github/workflows" -maxdepth 1 -type f | sort)
fi
for ci in .gitlab-ci.yml Jenkinsfile .travis.yml; do
  [ -f "$TARGET/$ci" ] && auth "$ci" "CI configuration (flagged by NAME pattern only)"
done
[ -d "$TARGET/.circleci" ] && auth ".circleci/" "CI configuration dir (flagged by NAME pattern only)"

# Secrets-shaped files — NAME PATTERN ONLY. The find below matches names and
# never opens a file; nothing after it opens one either. The VALUE never
# enters this process.
while IFS= read -r sf; do
  rel="${sf#"$TARGET"/}"
  auth "$rel" "secrets-shaped file NAME (path reported by name only; contents never read)"
done < <(find "$TARGET" -maxdepth 2 -type f \
           \( -name '.env' -o -name '.env.*' -o -name '*secret*' -o -name '*credential*' \
              -o -name '*.pem' -o -name '*.key' -o -name 'id_rsa*' -o -name '*.p12' \
              -o -name '*.keystore' \) 2>/dev/null | sort)

# ------------------------------------------------------------------ baseline --
BASELINE_MEASURED=0
if [ "$RUN_BASELINE" -eq 1 ]; then
  mkdir -p "$OUTDIR/baseline"
  BN=0
  while IFS=$'\t' read -r purpose cmd prov ev; do
    case "$purpose" in test|typecheck) ;; *) continue ;; esac
    BN=$((BN+1))
    ( cd "$TARGET" && timeout "$BTIMEOUT" bash -c "$cmd" ) \
        > "$OUTDIR/baseline/cmd-$BN.log" 2>&1
    rc=$?
    status="GREEN"; [ "$rc" -ne 0 ] && status="RED"
    note=""
    [ "$rc" -eq 124 ] && note=" (timed out after ${BTIMEOUT}s)"
    printf '%s\t%s\t%s\t%s\t%s\n' "$cmd" "$rc" "$status" "$prov" "$note" >> "$REC/baseline.tsv"
    if [ "$status" = "RED" ]; then
      cand "fix-baseline-$BN" "fix failing baseline command: $cmd" "exit $rc at intake$note; a red baseline is the first honest task"
    fi
  done < "$REC/commands.tsv"
  if [ "$BN" -gt 0 ]; then
    BASELINE_MEASURED=1
  else
    assume "no test/typecheck command was discovered or guessable, so --run-baseline had nothing to run"
  fi
else
  assume "baseline not measured — --run-baseline was not passed; no red/green status is known"
  cand "measure-baseline" "measure the baseline" "re-run intake with --run-baseline so red/green is a measurement, not a hope"
fi

# ------------------------------------------------- standing honest limits ---
GUESSED_N="$(grep -c '	GUESSED	' "$REC/commands.tsv" || true)"
[ "${GUESSED_N:-0}" -gt 0 ] \
  && assume "$GUESSED_N command(s) are GUESSED from ecosystem convention and were not verified against any manifest"
assume "framework hints come from a small fixed list (react/vue/next/express/vitest/jest); anything else goes undetected"
assume "monorepo/workspace layouts are not analyzed; only the repo root's manifests were consulted"
assume "directory classification is a name heuristic; a misnamed directory will be misclassified"
assume "authority-sensitive flags are name-pattern matches, not a security audit; absence of a flag is not clearance"

# ------------------------------------------------------------------- report --
{
  echo "# Intake report — $TARGET"
  echo
  echo "Generated by build-os/intake/repo-intake.sh on $(date -u +%Y-%m-%dT%H:%M:%SZ)."
  echo "Heuristic intake: every finding carries provenance (DISCOVERED/GUESSED)"
  echo "and confidence; everything undetermined is listed under Unsupported"
  echo "assumptions rather than silently guessed."
  echo
  echo "## Language & framework detection"
  if [ "$UNRECOGNIZED" -eq 1 ]; then
    echo "- UNRECOGNIZED: no known language/framework manifest found [CONFIDENCE: NONE]"
  else
    while IFS=$'\t' read -r l ev conf; do
      echo "- language: $l — evidence: $ev [CONFIDENCE: $conf]"
    done < "$REC/languages.tsv"
    while IFS=$'\t' read -r f ev conf; do
      echo "- framework hint: $f — evidence: $ev [CONFIDENCE: $conf]"
    done < "$REC/frameworks.tsv"
  fi
  echo
  echo "## Command discovery"
  if [ -s "$REC/commands.tsv" ]; then
    while IFS=$'\t' read -r purpose cmd prov ev; do
      echo "- $purpose: $cmd [$prov — $ev]"
    done < "$REC/commands.tsv"
  else
    echo "- none: no commands discovered or guessable"
  fi
  echo "DISCOVERED = read from a manifest the repo wrote. GUESSED = ecosystem"
  echo "convention supplied by this script; a guess is never a discovery."
  echo
  echo "## Repo-local instructions"
  while IFS=$'\t' read -r item status; do
    echo "- $item: $status"
  done < "$REC/instructions.tsv"
  echo
  echo "## Mutation-surface map"
  if [ -s "$REC/surfaces.tsv" ]; then
    while IFS=$'\t' read -r p cls h; do
      echo "- $p — $cls (heuristic: $h)"
    done < "$REC/surfaces.tsv"
  else
    echo "- no top-level directories found"
  fi
  echo
  if [ -s "$REC/authority.tsv" ]; then
    while IFS=$'\t' read -r p why; do
      echo "- AUTHORITY-SENSITIVE: $p — $why"
    done < "$REC/authority.tsv"
    echo
    echo "Authority-sensitive flags are NAME matches only; secret-shaped files"
    echo "are reported as paths and their contents never read."
  else
    echo "- no authority-sensitive areas flagged (name-pattern scan; absence is not clearance)"
  fi
  echo
  echo "## Baseline"
  if [ "$BASELINE_MEASURED" -eq 1 ]; then
    NB="$(grep -c . "$REC/baseline.tsv" || true)"
    echo "BASELINE: MEASURED — $NB command(s), timeout ${BTIMEOUT}s each. Logs in baseline/."
    while IFS=$'\t' read -r cmd rc status prov note; do
      echo "- $cmd — exit $rc — $status [$prov]$note"
    done < "$REC/baseline.tsv"
  else
    echo "BASELINE: NOT MEASURED — --run-baseline was not passed; no red/green claim is made."
  fi
  echo
  echo "## Task graph seed"
  echo "Candidate first tasks (CANDIDATES, not commitments — the operator routes);"
  echo "machine-readable copy in intake.json:"
  if [ -s "$REC/candidates.tsv" ]; then
    while IFS=$'\t' read -r id title why; do
      echo "- [$id] $title — $why"
    done < "$REC/candidates.tsv"
  else
    echo "- none emitted"
  fi
  echo
  echo "## Unsupported assumptions"
  echo "What this intake could NOT determine, stated rather than papered over:"
  while IFS= read -r a; do
    echo "- $a"
  done < "$REC/assumptions.txt"
} > "$REPORT"

# --------------------------------------------------------------- intake.json --
python3 - "$REC" "$JSON" "$TARGET" "$BASELINE_MEASURED" "$BTIMEOUT" <<'PY'
import json, sys, datetime
rec, out, target, measured, btimeout = sys.argv[1:6]

def rows(name, ncols):
    result = []
    try:
        with open("%s/%s" % (rec, name)) as f:
            for line in f:
                line = line.rstrip("\n")
                if not line:
                    continue
                parts = line.split("\t")
                parts += [""] * (ncols - len(parts))
                result.append(parts[:ncols])
    except FileNotFoundError:
        pass
    return result

doc = {
    "schema": "gravito.intake/v1",
    "target": target,
    "generated_at": datetime.datetime.now(datetime.timezone.utc)
        .strftime("%Y-%m-%dT%H:%M:%SZ"),
    "honesty": ("heuristic intake; DISCOVERED vs GUESSED and the confidence "
                "labels are load-bearing, and unsupported_assumptions lists "
                "what was NOT determined"),
    "languages": [
        {"language": l, "evidence": e, "confidence": c}
        for l, e, c in rows("languages.tsv", 3)],
    "frameworks": [
        {"framework": f, "evidence": e, "confidence": c}
        for f, e, c in rows("frameworks.tsv", 3)],
    "commands": [
        {"purpose": p, "command": c, "provenance": pr, "evidence": e}
        for p, c, pr, e in rows("commands.tsv", 4)],
    "instructions": [
        {"item": i, "status": s} for i, s in rows("instructions.tsv", 2)],
    "surfaces": [
        {"path": p, "class": c, "heuristic": h}
        for p, c, h in rows("surfaces.tsv", 3)],
    "authority_sensitive": [
        {"path": p, "reason": r} for p, r in rows("authority.tsv", 2)],
    "baseline": {
        "measured": measured == "1",
        "timeout_seconds": int(btimeout),
        "results": [
            {"command": c, "exit": int(rc), "status": s, "provenance": pr,
             "note": n.strip()}
            for c, rc, s, pr, n in rows("baseline.tsv", 5)],
    },
    "candidates": [
        {"id": i, "title": t, "rationale": r, "status": "CANDIDATE"}
        for i, t, r in rows("candidates.tsv", 3)],
    "unsupported_assumptions": [
        r[0] for r in rows("assumptions.txt", 1)],
}
with open(out, "w") as f:
    json.dump(doc, f, indent=2)
    f.write("\n")
PY

echo "INTAKE: report written to $OUTDIR"
echo "  - $REPORT"
echo "  - $JSON"
if [ "$BASELINE_MEASURED" -eq 0 ]; then
  echo "  baseline NOT measured (pass --run-baseline to execute test/typecheck commands)"
fi
echo "INTAKE COMPLETE: $TARGET"
