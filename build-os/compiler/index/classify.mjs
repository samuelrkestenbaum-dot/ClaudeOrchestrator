// Context Compiler / SEAM 1 — language and kind classification.
//
// Both classifiers are PATH-AND-NAME heuristics. They read no file content, so
// they are cheap, deterministic, and reusable across incremental builds (same
// path + same blob => same classification). They are also, being heuristics,
// wrong sometimes: a `config/` directory full of real source is misfiled, and a
// hand-written file inside `dist/` is called generated. The index says which
// rule fired only implicitly (via `kind`); the honest reading of `kind` is "a
// path-shaped guess", not "a verified fact".

// ---------------------------------------------------------------------------
// LANGUAGE. Extension -> language id. An unknown extension is NOT reported as
// some default language: the lowercased extension itself becomes the id, so the
// index never claims to know a language it does not. No extension at all falls
// back to a small filename table, then to "unknown".
// ---------------------------------------------------------------------------
const LANG_BY_EXT = {
  ts: 'typescript', tsx: 'typescript', mts: 'typescript', cts: 'typescript',
  js: 'javascript', jsx: 'javascript', mjs: 'javascript', cjs: 'javascript',
  py: 'python', pyi: 'python',
  go: 'go',
  rs: 'rust',
  sh: 'shell', bash: 'shell', zsh: 'shell',
  md: 'markdown', mdx: 'markdown', rst: 'rst', adoc: 'asciidoc',
  json: 'json', yml: 'yaml', yaml: 'yaml', toml: 'toml', ini: 'ini', cfg: 'ini',
  txt: 'text',
  html: 'html', htm: 'html', css: 'css', scss: 'css', sass: 'css',
  sql: 'sql', rb: 'ruby', java: 'java', kt: 'kotlin', swift: 'swift',
  c: 'c', h: 'c', cc: 'cpp', cpp: 'cpp', hpp: 'cpp', cxx: 'cpp',
};

const LANG_BY_NAME = {
  makefile: 'make', dockerfile: 'docker', rakefile: 'ruby', gemfile: 'ruby',
  'go.mod': 'gomod', 'go.sum': 'gosum', license: 'text',
};

export function basename(p) { const s = p.lastIndexOf('/'); return s === -1 ? p : p.slice(s + 1); }
export function dirname(p) { const s = p.lastIndexOf('/'); return s === -1 ? '' : p.slice(0, s); }
export function ext(p) {
  const b = basename(p); const d = b.lastIndexOf('.');
  return d <= 0 ? '' : b.slice(d + 1).toLowerCase();
}

export function langOf(path) {
  const e = ext(path);
  if (e) return LANG_BY_EXT[e] || e;
  const b = basename(path).toLowerCase();
  return LANG_BY_NAME[b] || 'unknown';
}

// ---------------------------------------------------------------------------
// KIND. Evaluated in this fixed order — generated, test, config, doc, source —
// because the categories overlap and the first match must be the most specific
// claim. `dist/foo.test.js` is GENERATED, not test: what it is built from
// matters more than what it is named.
//
//   generated : lives under a build/vendor/cache directory (node_modules, dist,
//               build, out, target, vendor, coverage, .next, __pycache__,
//               generated, gen, .venv), or is named like machine output
//               (*.min.js, *-lock.json, *.lock, *.generated.*, *_pb2.py,
//               *.pb.go, *.snap).
//   test      : lives under a test directory (test, tests, __tests__, spec, e2e,
//               testdata), or is named like a test (foo.test.ts, foo_spec.rb,
//               test_foo.py, foo_test.go).
//   config    : a known configuration filename or extension (package.json,
//               tsconfig*.json, *.config.*, dotfile rc files, Makefile,
//               Dockerfile, *.yml/*.yaml/*.toml/*.ini/*.cfg, go.mod, Cargo.toml,
//               requirements.txt), or lives under config/, .github/, .circleci/.
//   doc       : a documentation extension (md, mdx, rst, adoc, txt), or lives
//               under docs/ or doc/.
//   source    : everything else. This is the residual bucket, not a positive
//               finding.
// ---------------------------------------------------------------------------
const GENERATED_DIRS = new Set(['node_modules', 'dist', 'build', 'out', 'target',
  'vendor', 'coverage', '.next', '__pycache__', 'generated', 'gen', '.venv', 'venv']);
const TEST_DIRS = new Set(['test', 'tests', '__tests__', 'spec', 'e2e', 'testdata']);
const CONFIG_DIRS = new Set(['config', '.github', '.circleci', '.config']);
const DOC_DIRS = new Set(['docs', 'doc']);
const DOC_EXTS = new Set(['md', 'mdx', 'rst', 'adoc', 'txt']);
const CONFIG_EXTS = new Set(['yml', 'yaml', 'toml', 'ini', 'cfg']);
const CONFIG_NAMES = new Set(['package.json', 'go.mod', 'go.sum', 'cargo.toml',
  'requirements.txt', 'pyproject.toml', 'makefile', 'dockerfile', '.gitignore',
  '.gitattributes', '.editorconfig', 'setup.cfg', 'setup.py']);

const GENERATED_NAME = [
  /\.min\.(js|css)$/i, /-lock\.json$/i, /\.lock$/i, /\.generated\./i,
  /_pb2\.pyi?$/i, /\.pb\.go$/i, /\.snap$/i, /\.map$/i,
];
const TEST_NAME = [
  /[._-](test|spec)\.[a-z0-9]+$/i, /^test_[^/]*\.py$/i, /_test\.(go|py|rb|ts|js)$/i,
  /^Test[A-Z][^/]*\.java$/,
];

export function kindOf(path) {
  const parts = path.split('/');
  const dirs = parts.slice(0, -1);
  const b = basename(path);
  const lower = b.toLowerCase();
  const e = ext(path);

  if (dirs.some((d) => GENERATED_DIRS.has(d))) return 'generated';
  if (GENERATED_NAME.some((re) => re.test(b))) return 'generated';

  if (dirs.some((d) => TEST_DIRS.has(d))) return 'test';
  if (TEST_NAME.some((re) => re.test(b))) return 'test';

  if (CONFIG_NAMES.has(lower)) return 'config';
  if (CONFIG_EXTS.has(e)) return 'config';
  if (/^tsconfig.*\.json$/i.test(b) || /\.config\.[a-z]+$/i.test(b)) return 'config';
  if (/^\.[a-z]+(rc|ignore)(\.[a-z]+)?$/i.test(b) || /^\.env/i.test(b)) return 'config';
  if (dirs.some((d) => CONFIG_DIRS.has(d))) return 'config';

  if (DOC_EXTS.has(e)) return 'doc';
  if (dirs.some((d) => DOC_DIRS.has(d))) return 'doc';

  return 'source';
}

// The basename "stem" used by the tests_covering basename heuristic.
// foo.test.ts -> foo | test_foo.py -> foo | foo_test.go -> foo | foo.ts -> foo
export function stemOf(path) {
  let s = basename(path);
  const d = s.lastIndexOf('.');
  if (d > 0) s = s.slice(0, d);
  s = s.replace(/[._-](test|spec)$/i, '');
  s = s.replace(/^test[_-]/i, '');
  s = s.replace(/[_-]test$/i, '');
  return s;
}
