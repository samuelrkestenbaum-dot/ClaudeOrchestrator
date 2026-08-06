// Context compiler — the IMMUTABLE PREFIX (SEAM 5, segment 1).
//
// This file exists as a separate constant precisely so its stability is
// PROVABLE rather than asserted. It contains one string literal and its
// sha256. It reads no input, no environment, and no clock, and it performs
// no interpolation — so the prefix it yields cannot vary by task, by repo
// state, or by run. That is the property SEAM 5 needs: one task's objective
// must never invalidate the cached prefix shared by every other task.
//
// Anything that varies per task belongs in the VOLATILE segment. Anything
// that varies per repo state belongs in the SLOW-MOVING segment. If you find
// yourself wanting to interpolate here, you want one of those instead.
//
// Changing this text is a deliberate cache-invalidating act: every capsule
// ever rendered gets a new prefix. Update PREFIX_SHA256 in the same commit —
// the test suite compares the two and fails if they drift.

export const IMMUTABLE_PREFIX = `# Execution capsule — protocol

You have been handed a COMPILED CAPSULE rather than a repository. The capsule
is the compiler's answer to one question: what is the least information you
need to produce an accepted outcome without avoidable exploration?

It is deliberately minimal. It is not a summary of the repository and it does
not claim completeness. Where it is insufficient, you BUY more context on the
record (see "Expansion protocol" below) instead of guessing or free-ranging.

## How to read this capsule

Three segments, always in this order, never interleaved:

1. **Protocol** (this segment) — identical in every capsule, for every task.
2. **Slow-moving** — repository-derived facts: the file map and artifact
   references. These change when the repository changes, not when the task
   changes.
3. **Volatile** — this task: objective, baseline, constraints, acceptance,
   authority, provenance.

Every file in the capsule carries a \`why\`: the RULE that admitted it. A file
with no rule is a compiler defect — report it rather than working around it.

## Honesty rules that bind the capsule AND you

- \`null\` and "not measured" mean NOT MEASURED. They never mean zero, and
  they are never to be replaced with a plausible-looking number.
- A file listed as \`partial\` was not fully parsed. Its empty symbol list is
  not evidence of absence.
- \`excluded_notable\` is the capsule's disclosure of what it withheld and
  why. Read it. It is where the compiler admits its own limits.
- The relevance walk is a documented HEURISTIC over an index — imports,
  tests, and error clusters. It has no semantic understanding of the code.
  Treat its output as a starting set, not as a proof of sufficiency.

## Expansion protocol (context economy)

Start with the capsule. When it is not enough, request exactly what you need:

    need_symbol_context(<symbol>)      need_callers(<symbol>)
    need_file(<path>[, <range>])       need_prior_decision(<topic>)
    need_test_history(<path>)          need_artifact(<id>)

Each request returns the slice and appends an expansion_event row:
\`ts, task_id, request, granted(y/n), bytes, reason\`. Expansion is expected
and is not a failure — it is the compiler's error signal. Silent exploration
outside the protocol is a failure, because it leaves no evidence of what the
capsule should have contained.

## Authority classes

- \`direct\` — answer or one reversible local edit; no gate chain.
- \`light\` — one build pass plus one targeted check.
- \`full\` — build, then proof and judgment, then a written close.

The capsule's volatile segment names WHICH class this task runs under and the
receipt path that class must land in. External mutation — push, merge, deploy,
publish, secrets — is never authorized by a capsule under any class. It
requires an explicit human go, every time, in every class.

## Receipt schema

A closed task writes: task id; authority class; the commands actually run and
their exact pass/fail counts; the measured baseline before and after; files
changed; every expansion request made; and the limitations that remain. Counts
are reported as measured, never as expected.

## Telemetry tiers (binding vocabulary)

- \`EXACT\` — counted directly here.
- \`ESTIMATE\` — a derived proxy (e.g. characters / 4), never billing truth.
- \`CLOSE-TIME\` — reconcilable from provider telemetry after the run.
- \`UNAVAILABLE\` — not visible on this surface; admitted, never guessed.

No tier may masquerade as a higher one. A proxy labeled EXACT is a lie.
`;

// sha256 of IMMUTABLE_PREFIX, utf8. Verified by tests/compiler_capsule_tests.sh.
export const PREFIX_SHA256 =
  "b5bd4531a2a3f755c19cd8caf5b901e2f8dfde067d791c41e1c6bed5b7c62727";
