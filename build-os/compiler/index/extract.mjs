// Context Compiler / SEAM 1 — symbol and import extraction.
//
// HONESTY FIRST (SEAM 1 binding rule). NOTHING in this file is an AST. There is
// no TypeScript compiler, no tree-sitter, no language server. What there IS:
//
//   * a real character scanner (`scanCLike`) that tracks line comments, block
//     comments, single/double/template strings, and regex literals, and emits
//     two same-length masked views of the source — one with comments removed
//     (strings intact, because import specifiers live inside strings) and one
//     with comments AND string contents removed (for declaration matching).
//     This is what makes `// import { ghost } from './ghost'` invisible and
//     `const re = /it's/` harmless. It is tokenizer-ish, not a parser.
//   * line-oriented regexes run over those masked views.
//
// Consequences, stated rather than hidden: class methods, object-literal
// members, destructured bindings, overload signatures, ambient declarations in
// .d.ts, multi-line `export { ... }` lists, and anything produced by a macro or
// decorator are NOT extracted. Every file this module touches is therefore
// marked `partial: true` in the index. When a real AST backend replaces this,
// `partial` becomes false and the honesty flag stops lying in our favour.

// Characters after which a '/' begins a regex literal rather than a division.
const REGEX_OK = new Set(['', '(', ',', '=', ':', '[', '!', '&', '|', '?', '{',
  '}', ';', '+', '-', '*', '%', '~', '^', '<', '>', '\n']);

// Scan C-like source (JS, TS, Go) once, producing two equal-length views.
//   noComments : comments blanked, string literals intact
//   code       : comments blanked AND string contents blanked
// Newlines are preserved in both, so line numbers survive masking.
export function scanCLike(src) {
  const n = src.length;
  const noC = new Array(n);
  const code = new Array(n);
  let i = 0;
  let lastSig = '';
  const put = (idx, a, b) => { noC[idx] = a; code[idx] = b; };
  const blank = (idx) => { const ch = src[idx] === '\n' ? '\n' : ' '; put(idx, ch, ch); };

  while (i < n) {
    const c = src[i];
    const d = i + 1 < n ? src[i + 1] : '';

    if (c === '/' && d === '/') {
      while (i < n && src[i] !== '\n') { blank(i); i++; }
      continue;
    }
    if (c === '/' && d === '*') {
      const end = src.indexOf('*/', i + 2);
      const stop = end === -1 ? n : end + 2;
      while (i < stop) { blank(i); i++; }
      continue;
    }
    if (c === '"' || c === "'" || c === '`') {
      put(i, c, c); i++;
      while (i < n) {
        const ch = src[i];
        if (ch === '\\') {
          put(i, ch, ' '); i++;
          if (i < n) { const e = src[i]; put(i, e, e === '\n' ? '\n' : ' '); i++; }
          continue;
        }
        if (ch === c) { put(i, ch, ch); i++; break; }
        if (ch === '\n' && c !== '`') { put(i, '\n', '\n'); i++; break; } // unterminated
        put(i, ch, ch === '\n' ? '\n' : ' '); i++;
      }
      lastSig = c;
      continue;
    }
    if (c === '/' && REGEX_OK.has(lastSig)) {
      let j = i + 1; let closed = false; let inClass = false;
      while (j < n) {
        const ch = src[j];
        if (ch === '\\') { j += 2; continue; }
        if (ch === '\n') break;
        if (ch === '[') inClass = true;
        else if (ch === ']') inClass = false;
        else if (ch === '/' && !inClass) { closed = true; j++; break; }
        j++;
      }
      if (closed) {
        while (j < n && /[a-z]/.test(src[j])) j++; // flags
        while (i < j) { put(i, src[i], ' '); i++; }
        lastSig = '/';
        continue;
      }
      // Not a regex after all — fall through and treat as an ordinary char.
    }
    put(i, c, c);
    if (!/\s/.test(c)) lastSig = c;
    i++;
  }
  return { noComments: noC.join(''), code: code.join('') };
}

const uniqSorted = (a) => [...new Set(a)].sort();

// --- JavaScript / TypeScript ------------------------------------------------
const JS_DECL = /^(\s*)(?:export\s+)?(?:default\s+)?(?:declare\s+)?(?:abstract\s+)?(?:async\s+)?(function\s*\*?|class|interface|type|const\s+enum|enum|const|let|var)\s+([A-Za-z_$][A-Za-z0-9_$]*)/;
const JS_EXPORT_LIST = /^\s*export\s+(?:type\s+)?\{([^}]*)\}/;
const JS_IMPORT_PATTERNS = [
  /(?:^|[^\w$.])import\s+(?:[^'"();]*?\bfrom\s+)?['"]([^'"]+)['"]/g,
  /(?:^|[^\w$.])export\s+[^'"();]*?\bfrom\s+['"]([^'"]+)['"]/g,
  /\brequire\s*\(\s*['"]([^'"]+)['"]\s*\)/g,
  /\bimport\s*\(\s*['"]([^'"]+)['"]\s*\)/g,
];

function extractJsTs(src) {
  const { noComments, code } = scanCLike(src);
  const decls = [];
  const lines = code.split('\n');
  for (let n = 0; n < lines.length; n++) {
    const line = lines[n];
    const m = JS_DECL.exec(line);
    if (m) {
      const [, indent, kw, name] = m;
      const exported = /^\s*export\b/.test(line);
      // const/let/var are only taken at top level or when explicitly exported;
      // otherwise every local binding in every function body becomes a "symbol".
      const isBinding = /^(const|let|var)$/.test(kw);
      if (!isBinding || indent === '' || exported) decls.push({ name, line: n + 1 });
    }
    const el = JS_EXPORT_LIST.exec(line);
    if (el) {
      for (const part of el[1].split(',')) {
        const pm = /^\s*([A-Za-z_$][\w$]*)(?:\s+as\s+([A-Za-z_$][\w$]*))?\s*$/.exec(part);
        if (!pm) continue;
        const name = pm[2] || pm[1];
        if (name !== 'default') decls.push({ name, line: n + 1 });
      }
    }
  }
  const raw = [];
  for (const re of JS_IMPORT_PATTERNS) {
    re.lastIndex = 0;
    let m;
    while ((m = re.exec(noComments)) !== null) raw.push(m[1]);
  }
  return { decls, rawImports: uniqSorted(raw), parser: 'js-ts-regex-v0' };
}

// --- Python -----------------------------------------------------------------
// Mask comments and string contents (including triple-quoted blocks), then run
// line regexes. Decorators, dynamic definitions and __all__ are not read.
function maskPy(src) {
  const n = src.length;
  const out = new Array(n);
  let i = 0;
  const blank = (idx) => { out[idx] = src[idx] === '\n' ? '\n' : ' '; };
  while (i < n) {
    const c = src[i];
    if (c === '#') { while (i < n && src[i] !== '\n') { blank(i); i++; } continue; }
    const tri = src.startsWith("'''", i) ? "'''" : (src.startsWith('"""', i) ? '"""' : null);
    if (tri) {
      blank(i); blank(i + 1); blank(i + 2); i += 3;
      while (i < n && !src.startsWith(tri, i)) { blank(i); i++; }
      for (let k = 0; k < 3 && i < n; k++) { blank(i); i++; }
      continue;
    }
    if (c === "'" || c === '"') {
      blank(i); i++;
      while (i < n && src[i] !== c && src[i] !== '\n') {
        if (src[i] === '\\') { blank(i); i++; }
        if (i < n) { blank(i); i++; }
      }
      if (i < n && src[i] === c) { blank(i); i++; }
      continue;
    }
    out[i] = c; i++;
  }
  return out.join('');
}

function extractPython(src) {
  const code = maskPy(src);
  const lines = code.split('\n');
  const decls = [];
  const raw = [];
  for (let n = 0; n < lines.length; n++) {
    const line = lines[n];
    let m;
    if ((m = /^(\s*)(?:async\s+)?def\s+([A-Za-z_]\w*)/.exec(line))) decls.push({ name: m[2], line: n + 1 });
    else if ((m = /^(\s*)class\s+([A-Za-z_]\w*)/.exec(line))) decls.push({ name: m[2], line: n + 1 });
    else if ((m = /^([A-Z_][A-Z0-9_]*)\s*(?::[^=]+)?=(?!=)/.exec(line))) decls.push({ name: m[1], line: n + 1 });
    if ((m = /^\s*from\s+([\w.]+)\s+import\b/.exec(line))) raw.push(m[1]);
    else if ((m = /^\s*import\s+(.+)$/.exec(line))) {
      for (const part of m[1].split(',')) {
        const name = part.trim().split(/\s+as\s+/)[0].trim();
        if (/^[\w.]+$/.test(name)) raw.push(name);
      }
    }
  }
  return { decls, rawImports: uniqSorted(raw), parser: 'python-lines-v0' };
}

// --- Go ---------------------------------------------------------------------
function extractGo(src) {
  const { noComments, code } = scanCLike(src);
  const lines = code.split('\n');
  const decls = [];
  for (let n = 0; n < lines.length; n++) {
    const line = lines[n];
    let m;
    if ((m = /^func\s+\([^)]*\)\s+([A-Za-z_]\w*)/.exec(line))) decls.push({ name: m[1], line: n + 1 });
    else if ((m = /^func\s+([A-Za-z_]\w*)/.exec(line))) decls.push({ name: m[1], line: n + 1 });
    else if ((m = /^type\s+([A-Za-z_]\w*)/.exec(line))) decls.push({ name: m[1], line: n + 1 });
    else if ((m = /^(?:var|const)\s+([A-Za-z_]\w*)/.exec(line))) decls.push({ name: m[1], line: n + 1 });
  }
  const raw = [];
  const nlines = noComments.split('\n');
  let inBlock = false;
  for (const line of nlines) {
    if (/^\s*import\s*\(/.test(line)) { inBlock = true; continue; }
    if (inBlock) {
      if (/^\s*\)/.test(line)) { inBlock = false; continue; }
      const m = /"([^"]+)"/.exec(line);
      if (m) raw.push(m[1]);
      continue;
    }
    const m = /^\s*import\s+(?:[\w.]+\s+)?"([^"]+)"/.exec(line);
    if (m) raw.push(m[1]);
  }
  return { decls, rawImports: uniqSorted(raw), parser: 'go-lines-v0' };
}

// --- Rust -------------------------------------------------------------------
// Rust gets a naive comment strip rather than scanCLike: lifetimes ('a) look
// exactly like an opening string quote to a C-like scanner, which would corrupt
// the mask. Naive stripping means a `use` inside a string is over-reported.
function stripRustComments(src) {
  return src
    .replace(/\/\*[\s\S]*?\*\//g, (m) => m.replace(/[^\n]/g, ' '))
    .split('\n').map((l) => l.replace(/\/\/.*$/, '')).join('\n');
}

function extractRust(src) {
  const lines = stripRustComments(src).split('\n');
  const decls = [];
  const raw = [];
  for (let n = 0; n < lines.length; n++) {
    const line = lines[n];
    let m;
    if ((m = /^\s*(?:pub(?:\s*\([^)]*\))?\s+)?(?:default\s+)?(?:async\s+)?(?:unsafe\s+)?(?:extern\s+"[^"]*"\s+)?fn\s+([A-Za-z_]\w*)/.exec(line))) {
      decls.push({ name: m[1], line: n + 1 });
    } else if ((m = /^\s*(?:pub(?:\s*\([^)]*\))?\s+)?(?:struct|enum|trait|union|type|mod|static|const)\s+([A-Za-z_]\w*)/.exec(line))) {
      decls.push({ name: m[1], line: n + 1 });
    }
    if ((m = /^\s*(?:pub\s+)?use\s+([^;]+);/.exec(line))) raw.push(m[1].trim());
  }
  return { decls, rawImports: uniqSorted(raw), parser: 'rust-lines-v0' };
}

// --- dispatch ---------------------------------------------------------------
// A language with no extractor gets symbols: [] AND parser: 'none' AND
// partial: true. SEAM 1 forbids the silent empty.
export function extractFor(lang, src) {
  switch (lang) {
    case 'javascript':
    case 'typescript': return extractJsTs(src);
    case 'python': return extractPython(src);
    case 'go': return extractGo(src);
    case 'rust': return extractRust(src);
    default: return { decls: [], rawImports: [], parser: 'none' };
  }
}

// Whole-word token set for the referenced_in heuristic.
export function tokensOf(src) {
  const set = new Set();
  const re = /[A-Za-z_$][A-Za-z0-9_$]*/g;
  let m;
  while ((m = re.exec(src)) !== null) set.add(m[0]);
  return set;
}
