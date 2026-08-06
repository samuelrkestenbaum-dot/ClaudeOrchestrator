// Build OS — Context Compiler, SEAM 6: the SHARED trigger vocabulary.
//
// One definition of the six triggers, their order, their scope derivation, and
// the sensitive-path patterns — imported by assess.mjs, route-verifier.mjs and
// contribution-log.mjs so the three cannot drift apart. A forked vocabulary is
// how an efficacy table starts counting two different things under one name.
//
// WHY SEAM 6 EXISTS (executed evidence, not preference):
//   EXP-0002 measured Gravito ON at 3.96x the tokens of OFF, driven by
//   uncontrolled Full-mode fan-out. PILOT-0001 dispatched one Full verifier; it
//   examined six risk areas, found the implementation clean, and changed
//   nothing — confidence delivered, no unique implementation value, full cost.
//   Therefore: verification is EARNED by a named trigger, never automatic, and
//   every dispatch records WHICH trigger bought it.
//
// Pure. No clock, no randomness, no I/O, no dependencies outside node builtins.

// The six SEAM 6 triggers, in the order SEAM 6 states them. This array is the
// canonical order for every emitted object and every report.
export const TRIGGER_ORDER = [
  'incomplete_tests',
  'security_surface',
  'low_confidence',
  'diff_over_risk_threshold',
  'ambiguous_baseline',
  'prior_failed_attempt',
];

// The routing receipt's contribution vocabulary, mirrored exactly (see
// build-os/tools/route-task.sh). y / n / - only: "-" is an honest admission,
// never a zero. routing_contract.md — refusal is for CONTRADICTION, not absence.
export const CONTRIBUTION_FIELDS = [
  'changed_implementation',
  'changed_conclusion',
  'caught_defect',
  'duplicated_work',
];
export const YND = ['y', 'n', '-'];

// Authority ladder. mode-select.mjs emits direct|gravito_light|gravito_full;
// SEAM 2's capsule spells the same three direct|light|full. Both spellings are
// accepted and normalised — an unrecognised mode is refused, never treated as
// permissive.
export const MODE_ALIASES = {
  direct: 'direct',
  light: 'gravito_light',
  gravito_light: 'gravito_light',
  full: 'gravito_full',
  gravito_full: 'gravito_full',
};
export const MODE_RANK = { direct: 0, gravito_light: 1, gravito_full: 2 };

// A verifier dispatch is authority-bearing work. `none` costs nothing and needs
// nothing; a targeted verifier needs at least light; a full verifier needs full.
export const DECISION_REQUIRES = { none: 'direct', targeted: 'gravito_light', full: 'gravito_full' };

// Security / authority-sensitive path patterns. EVERY pattern carries WHY it is
// sensitive, and that reason is emitted with the match — a path flagged without
// a stated reason is an unfalsifiable flag.
export const SENSITIVE_PATTERNS = [
  {
    id: 'routing_authority',
    re: /(^|\/)build-os\/tools\/(route-task\.sh|routing-check\.sh|mode-select\.mjs)$/,
    why: 'the binding routing verdict path — routing_contract.md makes the recorded mode binding, so these files decide what other work is allowed to do',
  },
  {
    id: 'dispatch_config',
    re: /(^|\/)\.claude\/(agents|hooks|settings)/,
    why: 'dispatch and permission configuration — changes here alter what every later agent is permitted to do',
  },
  {
    id: 'credential_bearing',
    re: /(^|\/)(\.env(\..*)?|.*(secret|credential|password|passwd|api[_-]?key|private[_-]?key).*)$|\.(pem|key|p12|pfx)$/i,
    why: 'credential-bearing: the file may hold or shape access to secrets',
  },
  {
    id: 'authn_authz_logic',
    re: /(^|\/)(auth|authn|authz|login|logout|session|permission|permissions|acl|rbac|token)[^/]*\.(m?js|ts|tsx|py|sh|go|rb|java|rs)$/i,
    why: 'authentication / authorization logic — a defect here is a privilege defect, not a feature defect',
  },
  {
    id: 'ci_execution',
    re: /(^|\/)\.github\/workflows\//,
    why: 'CI executes with repository credentials; a workflow change is an execution-authority change',
  },
];

export function matchSensitive(path) {
  const hits = [];
  for (const p of SENSITIVE_PATTERNS) {
    if (p.re.test(path)) hits.push({ path, pattern_id: p.id, pattern_why: p.why });
  }
  return hits;
}

// ---------------------------------------------------------------------------
// THRESHOLD DERIVATION — no magic constants. Each threshold states its origin
// and, for the line threshold, whether it was MEASURED or is an unmeasured
// declared default. A default that poses as a calibrated value is exactly the
// dishonesty this seam exists to prevent.
// ---------------------------------------------------------------------------

// Cited, not invented: mode-select.mjs rule 1 defines "multi-step in the file
// sense" as expected_files_changed >= 4. That is this repo's only EXECUTED
// definition of a diff large enough to change how work is routed, so the risk
// threshold reuses it rather than minting a second, disagreeing number.
export const FILES_THRESHOLD = 4;
export const FILES_THRESHOLD_DERIVATION =
  'cited from build-os/tools/mode-select.mjs rule 1 ("multi-step in the file sense: expected_files_changed >= 4"), the repo\'s one executed definition of a multi-step diff; reused rather than re-invented so two thresholds cannot disagree';

// The fallback scale for lines-per-file when the index carries no line counts.
// It is NOT measured and NOT learned; it is labelled so at every emission.
export const DECLARED_LINES_PER_FILE = 50;

// Lower median (element (n-1)>>1 of the ascending sort) — chosen because it is
// integer-valued and order-stable, so the threshold is byte-reproducible.
function lowerMedian(sorted) {
  return sorted[(sorted.length - 1) >> 1];
}

export function deriveThresholds(index) {
  const files = (index && index.files) || {};
  const lens = [];
  for (const p of Object.keys(files).sort()) {
    const f = files[p];
    if (f && f.kind === 'source' && Number.isInteger(f.lines) && f.lines > 0) lens.push(f.lines);
  }
  lens.sort((a, b) => a - b);

  let unit, calibration, derivation;
  if (lens.length > 0) {
    unit = lowerMedian(lens);
    calibration = 'measured_from_index';
    derivation =
      'files_threshold (' + FILES_THRESHOLD + ') x the lower median source-file length in the index (' +
      unit + ' lines, n=' + lens.length + '): the diff is "large" once it is the size of a multi-step change across typical files of THIS repository';
  } else {
    unit = DECLARED_LINES_PER_FILE;
    calibration = 'unmeasured_declared_default';
    derivation =
      'files_threshold (' + FILES_THRESHOLD + ') x a DECLARED default of ' + unit +
      ' lines/file, because the index carries no line counts to measure from. This scale is not measured and not learned; it is a placeholder whose authority is exactly zero, labelled so no consumer can mistake it for calibration';
  }

  return {
    files: { value: FILES_THRESHOLD, derivation: FILES_THRESHOLD_DERIVATION, calibration: 'cited_from_mode_select' },
    lines: { value: FILES_THRESHOLD * unit, lines_per_file_unit: unit, derivation, calibration },
  };
}

// ---------------------------------------------------------------------------
// SCOPE DERIVATION — what a verifier should EXAMINE follows from WHICH trigger
// fired. Targeting is what makes an earned verification cheap: a security
// trigger scopes to the sensitive files, not to the whole diff.
//
// `unscopable_by_file` is the honest exception: an ambiguous baseline cannot be
// narrowed by file, because the thing in doubt is what "changed" even means for
// this task. The router reads that flag rather than guessing.
// ---------------------------------------------------------------------------
export const SCOPE_KIND = {
  incomplete_tests: 'files_lacking_coverage',
  security_surface: 'sensitive_files',
  low_confidence: 'worker_reported_scope',
  diff_over_risk_threshold: 'whole_diff',
  ambiguous_baseline: 'baseline_and_whole_diff',
  prior_failed_attempt: 'whole_diff_and_prior_failure',
};

export const UNSCOPABLE_BY_FILE = {
  incomplete_tests: false,
  security_surface: false,
  low_confidence: false,
  diff_over_risk_threshold: false,
  ambiguous_baseline: true,
  prior_failed_attempt: false,
};

// The examination question a verifier is actually sent with. One per fired
// trigger — so a targeted verifier has a bounded question list rather than an
// invitation to re-read the repository (PILOT-0001's six-area sweep).
export const TRIGGER_QUESTION = {
  incomplete_tests:
    'incomplete_tests: for each changed source file with no covering test, does the change behave as claimed, and what is the smallest test that would have caught a regression?',
  security_surface:
    'security_surface: on the sensitive files ONLY, does the change alter who may do what — authority, credentials, permissions or execution scope — and is that alteration intended?',
  low_confidence:
    'low_confidence: the worker reported low confidence in its own outcome; on the files it changed, which specific claim is the one it could not stand behind?',
  diff_over_risk_threshold:
    'diff_over_risk_threshold: the diff exceeds the derived risk threshold; is it one coherent change, or several that should have been separate packets?',
  ambiguous_baseline:
    'ambiguous_baseline: the pre-change baseline was not cleanly measured, so improvement cannot be attributed; what IS the measured state now, and what can honestly be claimed against it?',
  prior_failed_attempt:
    'prior_failed_attempt: a previous attempt on this task failed; does this attempt actually avoid that failure mode, or does it reproduce it in a new place?',
};

export function isYnd(v) {
  return typeof v === 'string' && YND.includes(v);
}

// Deterministic sorted unique string list.
export function sortedUnique(list) {
  return Array.from(new Set(list)).sort();
}
