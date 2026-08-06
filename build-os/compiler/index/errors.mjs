// Context Compiler / SEAM 1 — build-error clustering.
//
// Input is an existing tsc-style error list, produced by the project's own
// compiler and handed to the indexer with --errors. The indexer NEVER runs a
// build itself: measuring is the caller's job, and an index that has not been
// given errors reports `errors_measured: false` with `error_count: null` on
// every file rather than implying a clean tree.
//
// Line format accepted:  path(line,col): error TS2304: Cannot find name 'foo'.
// A clustering signature is the error code plus its message with quoted
// operands and bare integers normalized away, so "Cannot find name 'foo'" and
// "Cannot find name 'bar'" are ONE cluster of two, which is the shape a worker
// needs ("this repo has one missing-name problem in two files"), not three
// unrelated strings.

const LINE_RE = /^(.*?)\((\d+),(\d+)\):\s*(?:error|warning)\s+([A-Za-z]+[0-9]+):\s*(.*)$/;

function normalizePath(p, repoRoot) {
  let s = p.trim().replace(/\\/g, '/');
  if (repoRoot && s.startsWith(repoRoot + '/')) s = s.slice(repoRoot.length + 1);
  return s.replace(/^\.\//, '');
}

export function signatureOf(code, message) {
  const norm = message
    .replace(/'[^']*'/g, "'<S>'")
    .replace(/"[^"]*"/g, '"<S>"')
    .replace(/\b\d+\b/g, '<N>')
    .trim();
  return `${code}: ${norm}`;
}

// Returns { measured: true, perFile: Map<path, count>, clusters: [...] }.
// clusters are sorted by count DESC then signature ASC — deterministic, and
// ordered the way a reader wants them (biggest problem first).
export function parseErrors(text, repoRoot) {
  const perFile = new Map();
  const bySig = new Map();
  for (const rawLine of text.split('\n')) {
    const m = LINE_RE.exec(rawLine.trim());
    if (!m) continue;
    const path = normalizePath(m[1], repoRoot);
    const code = m[4];
    const sig = signatureOf(code, m[5]);
    perFile.set(path, (perFile.get(path) || 0) + 1);
    if (!bySig.has(sig)) bySig.set(sig, { signature: sig, count: 0, files: new Set() });
    const c = bySig.get(sig);
    c.count += 1;
    c.files.add(path);
  }
  const clusters = [...bySig.values()]
    .map((c) => ({ signature: c.signature, count: c.count, files: [...c.files].sort() }))
    .sort((a, b) => (b.count - a.count) || (a.signature < b.signature ? -1 : a.signature > b.signature ? 1 : 0));
  return { measured: true, perFile, clusters };
}
