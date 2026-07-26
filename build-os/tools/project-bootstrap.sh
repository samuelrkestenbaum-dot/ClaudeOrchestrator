#!/usr/bin/env bash
# Build OS — project-agnostic bootstrap installer (P-023).
#
# Attaching ClaudeOrchestrator to ANY Claude Code project must install and activate the
# COMPLETE orchestration runtime, with no project-specific instructions. This script is the
# single entry point that does it: it is invoked from the SessionStart hook (the mechanism
# Claude Code actually executes), determines the effective project repository, and installs
# or updates the runtime idempotently and transactionally.
#
# Installs (MANAGED — refreshed from canonical every time they drift):
#   .claude/agents/*.md, .claude/commands/*.md, .claude/hooks/*.sh,
#   build-os/tools/*.sh (capability-profile.sh, supervise.sh, specialist-handoff.sh, ...),
#   build-os/memory/tool_router.md, build-os/memory/skill_budget.md,
#   build-os/global-claude-md.md, the managed CLAUDE.md block, and the .claude/settings.json
#   SessionStart + UserPromptSubmit wiring (merged idempotently, managed keys only).
#
# NEVER overwrites (PRESERVED — seeded only when absent):
#   build-os/memory/current_state.md, build-os/memory/residue.md, build-os/packets/**,
#   build-os/receipts/**, project .mcp.json, non-managed CLAUDE.md content, unrelated
#   settings keys, product files, branches, stashes.
#
# Safety: a mkdir-atomic lock (fail-closed BUSY), a transactional promote with automatic
# rollback to the prior installation on failure, a content-hash + source-SHA cache that skips
# redundant work, and an installation manifest for drift detection.
#
# Usage:
#   project-bootstrap.sh [--target DIR] [--force] [--verify] [--dry-run] [--quiet]
# Exit codes: 0 ok/cached · 3 install failed (rolled back) · 4 BUSY (lock) · 2 usage
set -uo pipefail

BUILD_OS_RUNTIME_VERSION="1.0.0"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$(cd "$HERE/../.." && pwd)"          # ClaudeOrchestrator repo root (canonical source)

TARGET=""; FORCE=0; VERIFY=0; DRYRUN=0; QUIET=0
while [ $# -gt 0 ]; do
  case "$1" in
    --target)  TARGET="${2:-}"; shift 2 ;;
    --force)   FORCE=1; shift ;;
    --verify)  VERIFY=1; shift ;;
    --dry-run) DRYRUN=1; shift ;;
    --quiet)   QUIET=1; shift ;;
    -h|--help) echo "Usage: $0 [--target DIR] [--force] [--verify] [--dry-run] [--quiet]"; exit 0 ;;
    *)         shift ;;
  esac
done

# Effective project repository: explicit target > Claude Code's project dir > cwd.
TARGET="${TARGET:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"
mkdir -p "$TARGET" 2>/dev/null || true
TARGET="$(cd "$TARGET" 2>/dev/null && pwd)" || { echo "[bootstrap] ERROR: unusable target" >&2; exit 2; }

say() { [ "$QUIET" = 1 ] || printf '%s\n' "$*"; }

MANIFEST="$TARGET/build-os/.install-manifest.json"
LOCK="$TARGET/build-os/.bootstrap.lock"
LOCK_WAIT="${BUILD_OS_BOOTSTRAP_LOCK_WAIT:-15}"

canonical_sha() { ( cd "$SRC" && git rev-parse HEAD 2>/dev/null ) || echo "unknown"; }

# Managed file list (relative paths), computed from the canonical source.
managed_files() {
  ( cd "$SRC" 2>/dev/null || return 0
    ls .claude/agents/*.md .claude/commands/*.md .claude/hooks/*.sh \
       build-os/tools/*.sh 2>/dev/null
    for extra in build-os/memory/tool_router.md build-os/memory/skill_budget.md \
                 build-os/global-claude-md.md; do
      [ -f "$extra" ] && printf '%s\n' "$extra"
    done )
}

# Files seeded only when absent — project-specific state is never overwritten.
PRESERVED_SEEDS="build-os/memory/current_state.md build-os/memory/residue.md
build-os/packets/active_packet.md build-os/receipts/README.md"

# ── verify / health ───────────────────────────────────────────────────────────
# Availability is judged from what is installed AND (for agents) discoverable. File
# presence is NOT proof an agent is callable — the live check is the session's agent
# runtime; this reports discoverability and says so honestly.
REQUIRED_AGENTS="build-orchestrator builder qa reviewer archivist"
do_verify() {
  local missing="" a inst_sha canon
  canon="$(canonical_sha)"
  inst_sha="$(python3 - "$MANIFEST" <<'PY' 2>/dev/null || echo none
import json,sys
try: print(json.load(open(sys.argv[1])).get("source_sha","none"))
except Exception: print("none")
PY
)"
  local base="$TARGET"
  for a in $REQUIRED_AGENTS; do
    [ -f "$base/.claude/agents/$a.md" ] || missing="$missing $a"
  done
  local tools_ok=1 t
  for t in specialist-handoff.sh capability-profile.sh supervise.sh; do
    [ -f "$base/build-os/tools/$t" ] || tools_ok=0
  done
  if [ -z "$missing" ] && [ "$tools_ok" = 1 ]; then
    say "Orchestrator: ON — Build OS runtime v${BUILD_OS_RUNTIME_VERSION} installed."
  else
    say "Orchestrator: DEGRADED — the installed runtime is incomplete."
  fi
  # DRIFT is only meaningful when this copy of the script IS the canonical source (i.e. the
  # attached ClaudeOrchestrator checkout). A project's own vendored copy has SRC == TARGET, so
  # canonical_sha() would return the PROJECT's HEAD and every session would report a permanent
  # false DRIFT with a remedy that is a no-op. Report provenance instead in that case.
  if [ "$SRC" = "$TARGET" ]; then
    say "  installed source SHA: ${inst_sha:0:12} (vendored copy — canonical drift is checked by the attached ClaudeOrchestrator)"
  else
    say "  canonical source SHA: ${canon:0:12}   installed source SHA: ${inst_sha:0:12}"
    if [ "$inst_sha" != "none" ] && [ "$inst_sha" != "$canon" ]; then
      say "  DRIFT: installed runtime differs from canonical — re-run the bootstrap."
    fi
  fi
  if [ -z "$missing" ]; then
    say "  agents discoverable (5/5): $REQUIRED_AGENTS"
  else
    say "  agents MISSING:$missing  (actionable gap — re-attach ClaudeOrchestrator or re-run the bootstrap)"
  fi
  say "  local tools: $( [ "$tools_ok" = 1 ] && echo 'specialist-handoff, capability-profile, supervise (present)' || echo 'INCOMPLETE — re-run the bootstrap' )"
  say "  NOTE: file presence is discoverability, not proof of callability — verify a live agent/tool call before routing."
  [ -z "$missing" ] && [ "$tools_ok" = 1 ] && return 0 || return 1
}

if [ "$VERIFY" = 1 ]; then do_verify; exit $?; fi

# Installing into the canonical source repo itself is a no-op.
if [ "$SRC" = "$TARGET" ]; then
  say "[bootstrap] target is the ClaudeOrchestrator source repo — nothing to install."
  exit 0
fi
command -v python3 >/dev/null 2>&1 || { say "[bootstrap] python3 unavailable — skipped (non-fatal)."; exit 0; }

# ── cache: skip when the canonical SHA and every managed hash already match ───
if [ "$FORCE" != 1 ] && [ -f "$MANIFEST" ]; then
  if python3 - "$MANIFEST" "$SRC" "$TARGET" "$(canonical_sha)" <<'PY' >/dev/null 2>&1
import hashlib, json, os, sys
man_p, src, dst, canon = sys.argv[1:5]
man = json.load(open(man_p))
if man.get("source_sha") != canon: raise SystemExit(1)
def h(p):
    with open(p,"rb") as f: return hashlib.sha256(f.read()).hexdigest()
for rel, want in (man.get("files") or {}).items():
    d = os.path.join(dst, rel)
    s = os.path.join(src, rel)
    if not os.path.exists(d) or not os.path.exists(s): raise SystemExit(1)
    if h(d) != want or h(s) != want: raise SystemExit(1)
raise SystemExit(0)
PY
  then
    say "[bootstrap] runtime already up to date (canonical $(canonical_sha | cut -c1-12)) — skipped, no files copied."
    exit 0
  fi
fi

[ "$DRYRUN" = 1 ] && { say "[bootstrap] dry-run: would install/update the runtime into $TARGET"; exit 0; }

# ── lock (mkdir-atomic; fail closed; never recursive-delete an arbitrary path) ─
mkdir -p "$TARGET/build-os" 2>/dev/null || true
waited=0
while ! mkdir "$LOCK" 2>/dev/null; do
  pid="$(cat "$LOCK/pid" 2>/dev/null || echo)"
  if [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null; then
    rm -f "$LOCK/pid" 2>/dev/null; rmdir "$LOCK" 2>/dev/null; continue   # stale holder
  fi
  if [ "$waited" -ge "$LOCK_WAIT" ]; then
    say "[bootstrap] RESULT: BUSY — another bootstrap holds the install lock (waited ${LOCK_WAIT}s). Nothing was installed." >&2
    exit 4
  fi
  sleep 1; waited=$((waited + 1))
done
printf '%s\n' "$$" > "$LOCK/pid" 2>/dev/null || true
release_lock() { rm -f "$LOCK/pid" 2>/dev/null; rmdir "$LOCK" 2>/dev/null; }

# An unchecked mktemp would leave STAGE empty and turn every "$STAGE/$rel" write into a
# filesystem-ROOT write. Fail closed instead.
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/build-os-stage.XXXXXX")" || STAGE=""
if [ -z "$STAGE" ] || [ ! -d "$STAGE" ]; then
  say "[bootstrap] ERROR: could not create a staging directory; nothing was installed." >&2
  rm -f "$LOCK/pid" 2>/dev/null; rmdir "$LOCK" 2>/dev/null
  exit 3
fi
BACKUP="$TARGET/build-os/.install-backup"
cleanup() { rm -rf "$STAGE" 2>/dev/null; release_lock; }
trap 'cleanup' EXIT
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

FILES="$(managed_files)"

# 1) stage
for rel in $FILES; do
  mkdir -p "$STAGE/$(dirname "$rel")"
  cp "$SRC/$rel" "$STAGE/$rel" || { say "[bootstrap] ERROR staging $rel" >&2; exit 3; }
done

# 2) back up the prior installation (only managed paths)
rm -rf "$BACKUP" 2>/dev/null; mkdir -p "$BACKUP"
for rel in $FILES; do
  if [ -f "$TARGET/$rel" ]; then
    mkdir -p "$BACKUP/$(dirname "$rel")"; cp -p "$TARGET/$rel" "$BACKUP/$rel"
  fi
done
[ -f "$TARGET/CLAUDE.md" ] && cp -p "$TARGET/CLAUDE.md" "$BACKUP/CLAUDE.md.proj" 2>/dev/null
[ -f "$TARGET/.claude/settings.json" ] && { mkdir -p "$BACKUP/.claude"; cp -p "$TARGET/.claude/settings.json" "$BACKUP/.claude/settings.json"; }

rollback() {
  local rel
  for rel in $FILES; do
    if [ -f "$BACKUP/$rel" ]; then mkdir -p "$TARGET/$(dirname "$rel")"; cp -p "$BACKUP/$rel" "$TARGET/$rel"
    else rm -f "$TARGET/$rel" 2>/dev/null; fi
  done
  [ -f "$BACKUP/CLAUDE.md.proj" ] && cp -p "$BACKUP/CLAUDE.md.proj" "$TARGET/CLAUDE.md"
  [ -f "$BACKUP/.claude/settings.json" ] && cp -p "$BACKUP/.claude/settings.json" "$TARGET/.claude/settings.json"
  say "[bootstrap] ROLLBACK: install failed — restored the prior installation from backup." >&2
}

# 3) promote (atomic per file: write beside, then mv)
mkdir -p "$TARGET/.claude/agents" "$TARGET/.claude/commands" "$TARGET/.claude/hooks" \
         "$TARGET/build-os/tools" "$TARGET/build-os/memory" "$TARGET/build-os/packets" \
         "$TARGET/build-os/receipts"
promoted_ok=1
for rel in $FILES; do
  mkdir -p "$TARGET/$(dirname "$rel")"
  if cp "$STAGE/$rel" "$TARGET/$rel.bootstrap-tmp" 2>/dev/null && mv -f "$TARGET/$rel.bootstrap-tmp" "$TARGET/$rel" 2>/dev/null; then
    case "$rel" in *.sh) chmod +x "$TARGET/$rel" 2>/dev/null;; esac
  else
    rm -f "$TARGET/$rel.bootstrap-tmp" 2>/dev/null; promoted_ok=0; break
  fi
done

# 4) validate the promoted installation (fault injection point for tests)
validate_ok=1
[ "$promoted_ok" = 1 ] || validate_ok=0
if [ "$validate_ok" = 1 ]; then
  for a in $REQUIRED_AGENTS; do [ -f "$TARGET/.claude/agents/$a.md" ] || validate_ok=0; done
  for t in specialist-handoff.sh capability-profile.sh supervise.sh; do
    [ -x "$TARGET/build-os/tools/$t" ] || validate_ok=0
  done
fi
[ "${BUILD_OS_BOOTSTRAP_FAIL:-}" = "validate" ] && validate_ok=0

if [ "$validate_ok" != 1 ]; then
  rollback
  exit 3
fi

# 5) seed preserved files ONLY when absent (never clobber project state)
preserved_list=""
for rel in $PRESERVED_SEEDS; do
  if [ -e "$TARGET/$rel" ]; then
    preserved_list="$preserved_list $rel"
  elif [ -f "$SRC/$rel" ]; then
    mkdir -p "$TARGET/$(dirname "$rel")"; cp "$SRC/$rel" "$TARGET/$rel"
  fi
done

# 6) settings merge (idempotent; only the two managed hook entries) + managed CLAUDE.md block.
#    Both are written ATOMICALLY (temp + os.replace) and their exit status is CHECKED — a
#    truncate-then-write that failed here would otherwise corrupt a project's settings/CLAUDE.md
#    while the script still reported success and then discarded the backup.
if ! python3 - "$TARGET/.claude/settings.json" <<'PY'
import json, os, sys
path = sys.argv[1]
try:
    with open(path) as f: data = json.load(f)
    if not isinstance(data, dict): data = {}
except (FileNotFoundError, json.JSONDecodeError):
    data = {}
hooks = data.setdefault("hooks", {})
def ensure(event, script):
    cmd = "$CLAUDE_PROJECT_DIR/.claude/hooks/%s" % script
    groups = hooks.setdefault(event, [])
    for g in groups:
        for h in g.get("hooks", []):
            if str(h.get("command", "")).endswith(script): return
    groups.append({"hooks": [{"type": "command", "command": cmd}]})
ensure("SessionStart", "session-start-build-os.sh")
ensure("UserPromptSubmit", "prompt-router.sh")
os.makedirs(os.path.dirname(path), exist_ok=True)
tmp = path + ".bootstrap-tmp"
with open(tmp, "w") as f:
    json.dump(data, f, indent=2); f.write("\n")
os.replace(tmp, path)
PY
then
  say "[bootstrap] ERROR: settings.json merge failed." >&2
  rollback; exit 3
fi

if ! python3 - "$TARGET/CLAUDE.md" "$SRC/build-os/global-claude-md.md" "project-bootstrap.sh" <<'PY'
import os, re, sys
claude_md, block_src, manager = sys.argv[1:4]
start = "<!-- BUILD-OS:START (managed by %s) -->" % manager
end = "<!-- BUILD-OS:END -->"
body = open(block_src).read().rstrip("\n") if os.path.exists(block_src) else "# Build OS"
managed = "%s\n%s\n%s" % (start, body, end)
existing = open(claude_md).read() if os.path.exists(claude_md) else ""
cleaned = re.sub(r"\n*<!-- BUILD-OS:START.*?-->.*?<!-- BUILD-OS:END -->\n*", "\n",
                 existing, flags=re.DOTALL).rstrip("\n")
tmp = claude_md + ".bootstrap-tmp"
with open(tmp, "w") as f:
    f.write((cleaned + "\n\n" + managed + "\n") if cleaned else managed + "\n")
os.replace(tmp, claude_md)
PY
then
  say "[bootstrap] ERROR: CLAUDE.md managed-block update failed." >&2
  rollback; exit 3
fi

# 7) installation manifest (drift detection + provenance)
python3 - "$MANIFEST" "$SRC" "$TARGET" "$(canonical_sha)" "$BUILD_OS_RUNTIME_VERSION" \
         "$REQUIRED_AGENTS" "$preserved_list" <<'PY'
import hashlib, json, os, sys, datetime
man_p, src, dst, canon, ver, agents, preserved = sys.argv[1:8]
def h(p):
    with open(p,"rb") as f: return hashlib.sha256(f.read()).hexdigest()
files = {}
for sub in (".claude/agents", ".claude/commands", ".claude/hooks", "build-os/tools"):
    d = os.path.join(dst, sub)
    if os.path.isdir(d):
        for fn in sorted(os.listdir(d)):
            fp = os.path.join(d, fn)
            if os.path.isfile(fp): files[os.path.join(sub, fn)] = h(fp)
for extra in ("build-os/memory/tool_router.md", "build-os/memory/skill_budget.md",
              "build-os/global-claude-md.md"):
    fp = os.path.join(dst, extra)
    if os.path.isfile(fp): files[extra] = h(fp)
tools = sorted(fn for fn in files if fn.startswith("build-os/tools/"))
man = {
    "runtime_version": ver,
    "source_sha": canon,
    "source_repo": "ClaudeOrchestrator",
    "installed_at": datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0).isoformat(),
    "agents": sorted(agents.split()),
    "tools": [os.path.basename(t) for t in tools],
    "files": files,
    "preserved": sorted(preserved.split()),
    "note": "files = sha256 of the MANAGED installation. preserved = project-specific files intentionally left untouched.",
}
os.makedirs(os.path.dirname(man_p), exist_ok=True)
with open(man_p, "w") as f: json.dump(man, f, indent=2); f.write("\n")
PY

rm -rf "$BACKUP" 2>/dev/null
say "[bootstrap] installed/updated the Build OS runtime into $TARGET (canonical $(canonical_sha | cut -c1-12), v$BUILD_OS_RUNTIME_VERSION)"
[ -n "$preserved_list" ] && say "[bootstrap] preserved project-specific files:$preserved_list"
exit 0
