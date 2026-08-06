#!/usr/bin/env node
// Context Compiler — the content-addressed artifact registry (SEAM 2).
//
// WHY A REGISTRY AT ALL. A capsule must be able to say "the baseline output is
// THIS, and here is its digest" without pasting a 40 KB log into the prompt.
// SEAM 2's `artifact_refs` is that indirection: `{ id, sha256, summary, bytes }`.
// A reference is only worth having if the thing it points at can be proven
// unchanged, so the id IS the sha256 — a tampered object no longer hashes to
// its own name, and `verify` is what notices.
//
// LAYOUT (a directory, not a database — single store, no daemon, no index server):
//   <registry>/objects/<sha256>   the bytes, exactly as put
//   <registry>/index.tsv          id, bytes, created_at, summary   (4 fields)
//
// DEDUPE is a consequence of content addressing rather than a feature: two
// files with identical bytes hash to one name and occupy one object. The first
// summary recorded wins; a later put of the same bytes does not rewrite it,
// because rewriting would make the index non-append-only for no gain.
//
// COMMANDS
//   put <file> --registry <dir> [--summary <line>] [--now <iso>]   -> prints <id>
//   get <id>   --registry <dir>                                    -> raw bytes
//   ref <id>   --registry <dir>                                    -> SEAM 2 artifact_ref JSON
//   verify     --registry <dir>                                    -> census; exit 1 if corrupt
//
// Exit codes: 0 ok, 1 verification failure or missing object, 2 usage error.
// Node stdlib only. No network.
import { createHash } from "node:crypto";
import {
  readFileSync, writeFileSync, appendFileSync, existsSync, mkdirSync, readdirSync,
} from "node:fs";
import { join } from "node:path";

const INDEX_HEADER = ["id", "bytes", "created_at", "summary"].join("\t");

// TSV is only safe if no field can carry a delimiter. Escaping (rather than
// stripping) keeps the payload readable while making it inert.
export const tsvSafe = (s) =>
  String(s ?? "")
    .replace(/\\/g, "\\\\")
    .replace(/\t/g, "\\t")
    .replace(/\r/g, "\\r")
    .replace(/\n/g, "\\n");

export const sha256 = (buf) => createHash("sha256").update(buf).digest("hex");

const objectsDir = (registry) => join(registry, "objects");
const indexPath = (registry) => join(registry, "index.tsv");

const ensureRegistry = (registry) => {
  mkdirSync(objectsDir(registry), { recursive: true });
  if (!existsSync(indexPath(registry))) writeFileSync(indexPath(registry), INDEX_HEADER + "\n");
};

export const readIndex = (registry) => {
  const p = indexPath(registry);
  if (!existsSync(p)) return [];
  return readFileSync(p, "utf8")
    .split("\n")
    .filter((l) => l.length > 0 && !l.startsWith("id\t"))
    .map((l) => {
      const [id, bytes, created_at, summary] = l.split("\t");
      return { id, bytes: Number(bytes), created_at, summary };
    });
};

// A summary is one line. If the caller does not supply one, derive it from the
// content's first non-empty line — a derived summary is still honest, and an
// absent one would make every ref look alike.
const deriveSummary = (buf) => {
  const first = buf.toString("utf8").split("\n").find((l) => l.trim().length > 0);
  if (!first) return "(empty artifact)";
  const t = first.trim();
  return t.length > 120 ? t.slice(0, 117) + "..." : t;
};

export const putBuffer = (registry, buf, summary, now) => {
  ensureRegistry(registry);
  const id = sha256(buf);
  const objPath = join(objectsDir(registry), id);
  const deduped = existsSync(objPath);
  if (!deduped) {
    writeFileSync(objPath, buf);
    const row = [id, String(buf.length), now, tsvSafe(summary ?? deriveSummary(buf))].join("\t");
    appendFileSync(indexPath(registry), row + "\n");
  }
  return { id, bytes: buf.length, deduped };
};

export const getArtifact = (registry, id) => {
  const objPath = join(objectsDir(registry), id);
  if (!/^[0-9a-f]{64}$/.test(String(id)) || !existsSync(objPath)) return null;
  return readFileSync(objPath);
};

export const refFor = (registry, id) => {
  const buf = getArtifact(registry, id);
  if (buf === null) return null;
  const row = readIndex(registry).find((r) => r.id === id);
  // `id` and `sha256` are equal BY CONSTRUCTION here: the store is content
  // addressed, so the name is the digest. SEAM 2 keeps both fields because a
  // future named-artifact store may separate them; this one does not pretend to.
  return {
    id,
    sha256: id,
    summary: row ? row.summary : deriveSummary(buf),
    bytes: buf.length,
  };
};

export const verifyRegistry = (registry) => {
  const dir = objectsDir(registry);
  const names = existsSync(dir) ? readdirSync(dir).sort() : [];
  const corrupt = [];
  let ok = 0;
  for (const name of names) {
    const actual = sha256(readFileSync(join(dir, name)));
    if (actual === name) ok += 1;
    else corrupt.push({ id: name, actual });
  }
  const missing = readIndex(registry)
    .map((r) => r.id)
    .filter((id) => !names.includes(id));
  return { ok, corrupt, missing, total: names.length };
};

// --- CLI ---------------------------------------------------------------------
const flag = (argv, name, dflt = null) => {
  const i = argv.indexOf(`--${name}`);
  return i >= 0 && i + 1 < argv.length ? argv[i + 1] : dflt;
};

const main = (argv) => {
  const cmd = argv[0];
  const registry = flag(argv, "registry");
  if (!cmd || !registry) {
    process.stderr.write(
      "usage: artifacts.mjs <put <file>|get <id>|ref <id>|verify> --registry <dir> [--summary <line>] [--now <iso>]\n",
    );
    return 2;
  }
  const now = flag(argv, "now", new Date().toISOString());

  if (cmd === "put") {
    const file = argv[1];
    if (!file || !existsSync(file)) {
      process.stderr.write(`artifacts: no such file: ${file}\n`);
      return 2;
    }
    const { id } = putBuffer(registry, readFileSync(file), flag(argv, "summary"), now);
    process.stdout.write(id + "\n");
    return 0;
  }

  if (cmd === "get") {
    const buf = getArtifact(registry, argv[1]);
    if (buf === null) {
      process.stderr.write(`artifacts: unknown id: ${argv[1]}\n`);
      return 1;
    }
    process.stdout.write(buf);
    return 0;
  }

  if (cmd === "ref") {
    const ref = refFor(registry, argv[1]);
    if (ref === null) {
      process.stderr.write(`artifacts: unknown id: ${argv[1]}\n`);
      return 1;
    }
    process.stdout.write(JSON.stringify(ref, null, 2) + "\n");
    return 0;
  }

  if (cmd === "verify") {
    const r = verifyRegistry(registry);
    process.stdout.write(`registry: ${registry}\n`);
    process.stdout.write(`ok: ${r.ok}\n`);
    process.stdout.write(`corrupt: ${r.corrupt.length}\n`);
    process.stdout.write(`missing: ${r.missing.length}\n`);
    for (const c of r.corrupt)
      process.stdout.write(`  CORRUPT ${c.id} hashes to ${c.actual}\n`);
    for (const m of r.missing) process.stdout.write(`  MISSING ${m}\n`);
    return r.corrupt.length + r.missing.length > 0 ? 1 : 0;
  }

  process.stderr.write(`artifacts: unknown command: ${cmd}\n`);
  return 2;
};

if (import.meta.url === `file://${process.argv[1]}`) process.exit(main(process.argv.slice(2)));
