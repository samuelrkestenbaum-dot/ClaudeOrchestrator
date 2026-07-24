#!/usr/bin/env bash
# Reconcile known Claude host integration conflicts after plugin installs/updates.
set -uo pipefail

CLAUDE_DIR="${CLAUDE_USER_DIR:-$HOME/.claude}"

python3 - "$CLAUDE_DIR" <<'PY'
from pathlib import Path
import json
import re
import shutil
import sys

root = Path(sys.argv[1])

def backup(path: Path) -> None:
    target = path.with_name(path.name + ".build-os.bak")
    if path.exists() and not target.exists():
        shutil.copy2(path, target)

# claude-mem 13.8.1 can print its own ready envelope and then echo a second JSON
# object. Claude concatenates them and reports a SessionStart parse error.
for path in [
    root / "plugins/cache/thedotmack/claude-mem/13.8.1/hooks/hooks.json",
    root / "plugins/marketplaces/thedotmack/plugin/hooks/hooks.json",
]:
    if not path.exists():
        continue
    text = path.read_text()
    fixed = text.replace(
        "; echo '{\\\"continue\\\":true,\\\"suppressOutput\\\":true}'",
        "",
    )
    if fixed != text:
        backup(path)
        path.write_text(fixed)

# claude-subconscious 2.1.1 groups two JSON-emitting SessionStart commands in a
# single hook group. Split them so Claude parses each output independently.
for path in [
    root / "plugins/cache/claude-subconscious/claude-subconscious/2.1.1/hooks/hooks.json",
    root / "plugins/marketplaces/claude-subconscious/hooks/hooks.json",
]:
    if not path.exists():
        continue
    try:
        data = json.loads(path.read_text())
    except Exception:
        continue
    groups = data.get("hooks", {}).get("SessionStart")
    if not isinstance(groups, list):
        continue
    changed = False
    repaired = []
    for group in groups:
        hooks = group.get("hooks", []) if isinstance(group, dict) else []
        commands = [str(h.get("command", "")) for h in hooks if isinstance(h, dict)]
        if (
            len(hooks) > 1
            and any("session_start.ts" in command for command in commands)
            and any("sync_letta_memory.ts" in command for command in commands)
        ):
            for hook in hooks:
                split = {key: value for key, value in group.items() if key != "hooks"}
                split["hooks"] = [hook]
                repaired.append(split)
            changed = True
        else:
            repaired.append(group)
    if changed:
        backup(path)
        data["hooks"]["SessionStart"] = repaired
        path.write_text(json.dumps(data, indent=2) + "\n")

# Claude loads all native agent descriptions into its registry. Preserve every
# instruction body while bounding only frontmatter descriptions.
agents = root / "agents"
backup_dir = root / "backups/agent-descriptions-precompact"
managed_agents = {
    "archivist.md",
    "build-orchestrator.md",
    "builder.md",
    "qa.md",
    "reviewer.md",
}
for path in agents.glob("*.md") if agents.is_dir() else []:
    if path.name in managed_agents:
        continue
    text = path.read_text(errors="ignore")
    if not text.startswith("---\n"):
        continue
    end = text.find("\n---", 4)
    if end < 0:
        continue
    frontmatter = text[4:end]
    match = re.search(
        r"(?ms)^description:\s*(.*?)(?=^[A-Za-z_][A-Za-z0-9_-]*:\s|\Z)",
        frontmatter,
    )
    if not match:
        continue
    pieces = []
    for line in match.group(1).splitlines():
        line = re.sub(r"^\s*(?:>|-)?\s*", "", line).strip().strip("\"'")
        if line and line not in {"|", "|-", ">", ">-"}:
            pieces.append(line)
    description = re.sub(r"\s+", " ", " ".join(pieces)).strip()
    if len(description) > 78:
        description = description[:75].rsplit(" ", 1)[0] + "..."
    replacement = "description: " + json.dumps(description, ensure_ascii=False) + "\n"
    updated_frontmatter = (
        frontmatter[: match.start()] + replacement + frontmatter[match.end() :]
    )
    updated = "---\n" + updated_frontmatter + "---" + text[end + 4 :]
    if updated != text:
        backup_dir.mkdir(parents=True, exist_ok=True)
        backup_path = backup_dir / path.name
        if not backup_path.exists():
            shutil.copy2(path, backup_path)
        path.write_text(updated)
PY

echo "  + host plugin hooks and agent registry reconciled"
