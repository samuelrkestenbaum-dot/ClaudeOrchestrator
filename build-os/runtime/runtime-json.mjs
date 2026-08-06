#!/usr/bin/env node
// Gravito runtime — JSON helper for gravito-runtime.sh.
// All structured-data operations live here so the bash driver never parses
// JSON with grep/sed. No dependencies beyond node stdlib.
//
// The runtime DEFINITION (which files ship, where they land, whether the
// installer prepends an installed-copy header, the settings.json hook entries
// to merge, the .gitignore lines) is authored here; MANIFEST.json is the
// versioned release artifact = definition + computed sha256s + version.
import { createHash } from "node:crypto";
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { join } from "node:path";

const DEFINITION = {
  name: "gravito-runtime",
  description:
    "Versioned Gravito routing runtime: the five executables and three " +
    "contracts proven in the empathiq pilot install, plus the settings.json " +
    "hook wiring and .gitignore stanza — installable without manual copying.",
  files: [
    { source: ".claude/hooks/routing-gate.sh",        install: ".claude/hooks/routing-gate.sh",        mode: "executable", header: false },
    { source: "build-os/tools/route-task.sh",         install: "build-os/tools/route-task.sh",         mode: "executable", header: false },
    { source: "build-os/tools/mode-select.mjs",       install: "build-os/tools/mode-select.mjs",       mode: "executable", header: false },
    { source: "build-os/tools/routing-check.sh",      install: "build-os/tools/routing-check.sh",      mode: "executable", header: false },
    { source: "build-os/tools/record-degradation.sh", install: "build-os/tools/record-degradation.sh", mode: "executable", header: false },
    { source: "build-os/memory/routing_contract.md",          install: "build-os/memory/routing_contract.md",          mode: "contract", header: true },
    { source: "build-os/memory/routing_contract_live.md",     install: "build-os/memory/routing_contract_live.md",     mode: "contract", header: true },
    { source: "build-os/memory/provider_adapter_contract.md", install: "build-os/memory/provider_adapter_contract.md", mode: "contract", header: true },
  ],
  // The exact hook entries the empathiq install wired into .claude/settings.json.
  // Merged additively; uninstall removes ONLY deep-equal copies of these.
  settings_hooks: {
    PreToolUse: [
      { matcher: "Task|Agent",                 hooks: [{ type: "command", command: "$CLAUDE_PROJECT_DIR/.claude/hooks/routing-gate.sh gate" }] },
      { matcher: "Edit|Write|NotebookEdit|Bash", hooks: [{ type: "command", command: "$CLAUDE_PROJECT_DIR/.claude/hooks/routing-gate.sh mutgate" }] },
      { matcher: "*",                          hooks: [{ type: "command", command: "$CLAUDE_PROJECT_DIR/.claude/hooks/routing-gate.sh count" }] },
    ],
    PostToolUse: [
      { matcher: "*", hooks: [{ type: "command", command: "$CLAUDE_PROJECT_DIR/.claude/hooks/routing-gate.sh post" }] },
    ],
  },
  // The empathiq .gitignore stanza: receipts are TRACKED evidence; only the
  // high-churn live ledgers stay untracked.
  gitignore: [
    "# Gravito routing store: receipts (build-os/packets/routing/*.md) are TRACKED —",
    "# in a product install the receipts ARE the evidence. Only the high-churn live",
    "# ledgers stay untracked (append-only per-session logs, one row per tool event).",
    "build-os/packets/routing/live_gate_log.tsv",
    "build-os/packets/routing/live_state/",
  ],
};

const sha256 = (p) => createHash("sha256").update(readFileSync(p)).digest("hex");
const readJson = (p) => JSON.parse(readFileSync(p, "utf8"));
const writeJson = (p, o) => writeFileSync(p, JSON.stringify(o, null, 2) + "\n");
const sortKeys = (o) => {
  if (Array.isArray(o)) return o.map(sortKeys);
  if (o && typeof o === "object")
    return Object.fromEntries(Object.keys(o).sort().map((k) => [k, sortKeys(o[k])]));
  return o;
};
const canon = (o) => JSON.stringify(sortKeys(o));
const die = (m) => { process.stderr.write(`runtime-json: ${m}\n`); process.exit(1); };
const readStdin = () => { try { return readFileSync(0, "utf8"); } catch { return ""; } };

const [cmd, ...args] = process.argv.slice(2);

switch (cmd) {
  case "regen": {
    // regen <canonRoot> <version> — print a release manifest with computed shas.
    const [root, version] = args;
    if (!root || !version) die("usage: regen <canonRoot> <version>");
    const manifest = {
      name: DEFINITION.name,
      version,
      description: DEFINITION.description,
      generated: new Date().toISOString().slice(0, 10),
      files: DEFINITION.files.map((f) => ({ ...f, sha256: sha256(join(root, f.source)) })),
      settings_hooks: DEFINITION.settings_hooks,
      gitignore: DEFINITION.gitignore,
    };
    process.stdout.write(JSON.stringify(manifest, null, 2) + "\n");
    break;
  }

  case "get": {
    // get <manifest.json> <key> — print a top-level scalar field.
    const [p, key] = args;
    const v = readJson(p)[key];
    if (v === undefined) die(`no key ${key} in ${p}`);
    process.stdout.write(String(v) + "\n");
    break;
  }

  case "files": {
    // files <manifest.json> — TSV: source, install, mode, header, sha256
    for (const f of readJson(args[0]).files)
      process.stdout.write([f.source, f.install, f.mode, f.header ? "1" : "0", f.sha256].join("\t") + "\n");
    break;
  }

  case "gitignore": {
    for (const line of readJson(args[0]).gitignore) process.stdout.write(line + "\n");
    break;
  }

  case "merge-settings": {
    // merge-settings <manifest.json> <settings.json> — additive, never clobbers.
    const [mp, sp] = args;
    const ours = readJson(mp).settings_hooks;
    const settings = existsSync(sp) ? readJson(sp) : {};
    settings.hooks = settings.hooks || {};
    let added = 0;
    for (const [event, entries] of Object.entries(ours)) {
      const arr = (settings.hooks[event] = settings.hooks[event] || []);
      for (const entry of entries) {
        if (!arr.some((e) => canon(e) === canon(entry))) { arr.push(entry); added++; }
      }
    }
    writeJson(sp, settings);
    process.stdout.write(`merged ${added} hook entries\n`);
    break;
  }

  case "unmerge-settings": {
    // unmerge-settings <manifest.json> <settings.json> — remove ONLY deep-equal
    // copies of our entries; everything customer-owned stays byte-meaning intact.
    const [mp, sp] = args;
    if (!existsSync(sp)) { process.stdout.write("removed 0 hook entries\n"); break; }
    const ours = Object.values(readJson(mp).settings_hooks).flat().map(canon);
    const settings = readJson(sp);
    let removed = 0;
    if (settings.hooks && typeof settings.hooks === "object") {
      for (const event of Object.keys(settings.hooks)) {
        const arr = settings.hooks[event];
        if (!Array.isArray(arr)) continue;
        const kept = arr.filter((e) => !ours.includes(canon(e)));
        removed += arr.length - kept.length;
        if (kept.length) settings.hooks[event] = kept;
        else delete settings.hooks[event];
      }
      if (Object.keys(settings.hooks).length === 0) delete settings.hooks;
    }
    writeJson(sp, settings);
    process.stdout.write(`removed ${removed} hook entries\n`);
    break;
  }

  case "strip-gitignore": {
    // strip-gitignore <manifest.json> <.gitignore> — drop exact matches of our lines.
    const [mp, gp] = args;
    if (!existsSync(gp)) break;
    const ours = new Set(readJson(mp).gitignore);
    const kept = readFileSync(gp, "utf8").split("\n").filter((l) => !ours.has(l));
    writeFileSync(gp, kept.join("\n"));
    break;
  }

  case "installed-write": {
    // installed-write <out.json> <version> <commit> <branch> <date>
    // stdin TSV rows: install, mode, header, installed_sha256, source_sha256
    const [out, version, commit, branch, date] = args;
    const files = readStdin().split("\n").filter(Boolean).map((row) => {
      const [install, mode, header, installed_sha256, source_sha256] = row.split("\t");
      return { install, mode, header: header === "1", installed_sha256, source_sha256 };
    });
    writeJson(out, { name: DEFINITION.name, version, source_commit: commit, source_branch: branch, date, files });
    break;
  }

  case "installed-files": {
    // installed-files <INSTALLED_VERSION.json> — TSV rows back out.
    for (const f of readJson(args[0]).files)
      process.stdout.write([f.install, f.mode, f.header ? "1" : "0", f.installed_sha256, f.source_sha256].join("\t") + "\n");
    break;
  }

  case "receipt": {
    // receipt <out.json> <action> <runtime_version> <from> <to> <commit> <branch> <date>
    // stdin TSV rows: fileAction, path  (become the receipt's files[] entries)
    const [out, action, version, from, to, commit, branch, date] = args;
    const files = readStdin().split("\n").filter(Boolean).map((row) => {
      const [act, path, ...rest] = row.split("\t");
      const r = { action: act, path };
      if (rest[0]) r.note = rest[0];
      return r;
    });
    writeJson(out, {
      receipt: action, runtime: DEFINITION.name, runtime_version: version,
      from_version: from, to_version: to, source_commit: commit,
      source_branch: branch, date, files,
    });
    break;
  }

  default:
    die(`unknown command: ${cmd ?? "(none)"}`);
}
