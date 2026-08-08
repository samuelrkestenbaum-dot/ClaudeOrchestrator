// Validation set for the v1 catastrophic-non-action predicates.
//
// EXP-0005 is EXCLUDED from this file entirely — from both halves. A predicate
// authored after an outcome and validated on that same outcome has been fitted
// to the answer, not tested.
//
// NEGATIVE cases are historical experiments that did NOT inspire these rules.
// They are the false-positive guard: every one produced real output, so a
// non-action predicate that fires on any of them is broken.
//
// POSITIVE cases are synthetic. They are the vacuity guard: a predicate that
// never fires proves nothing by staying silent.

export const NEGATIVE = [
  {
    name: "EXP-0001 token-efficiency — 5/5 vs 5/5 acceptance",
    input: {
      experiment: "EXP-0001", per_task: [], rejected: [], admitted: 10, attempted: 10, gates_met: 1,
      by_condition: [
        { condition: "gravito_on", units: 5, accepted: 5, durable_changes: 5, total_tokens: 1_200_000 },
        { condition: "gravito_off", units: 5, accepted: 5, durable_changes: 5, total_tokens: 900_000 },
      ],
    },
  },
  {
    name: "EXP-0002 sustained-workload — 10/10 acceptance both arms",
    input: {
      experiment: "EXP-0002", per_task: [], rejected: [], admitted: 10, attempted: 10, gates_met: 1,
      by_condition: [
        { condition: "buildos", units: 5, accepted: 5, durable_changes: 5, total_tokens: 7_400_000 },
        { condition: "raw", units: 5, accepted: 5, durable_changes: 5, total_tokens: 1_900_000 },
      ],
    },
  },
  {
    name: "a genuinely poor but OPERATING condition — low acceptance, real output",
    input: {
      experiment: "SYNTH-poor-but-working", per_task: [], rejected: [], admitted: 12, attempted: 12, gates_met: 0,
      by_condition: [
        { condition: "treatment", units: 6, accepted: 1, durable_changes: 6, total_tokens: 3_000_000 },
        { condition: "control", units: 6, accepted: 5, durable_changes: 6, total_tokens: 2_000_000 },
      ],
    },
  },
  {
    name: "small sample — one accepted-zero condition below the units floor",
    input: {
      experiment: "SYNTH-underpowered", per_task: [], rejected: [], admitted: 6, attempted: 6, gates_met: 0,
      by_condition: [
        { condition: "treatment", units: 3, accepted: 0, durable_changes: 0, total_tokens: 500_000 },
        { condition: "control", units: 3, accepted: 3, durable_changes: 3, total_tokens: 400_000 },
      ],
    },
  },
  {
    name: "acceptance NOT MEASURED — nulls must not read as zero",
    input: {
      experiment: "SYNTH-unmeasured", per_task: [], rejected: [], admitted: 10, attempted: 10, gates_met: 0,
      by_condition: [
        { condition: "treatment", units: 5, accepted: null, durable_changes: null, total_tokens: 800_000 },
        { condition: "control", units: 5, accepted: null, durable_changes: null, total_tokens: 700_000 },
      ],
    },
  },
];

export const POSITIVE = [
  {
    name: "a treatment that never acted — zero accepted, zero durable, real spend",
    expect: ["total-acceptance-floor", "spend-without-durable-output"],
    input: {
      experiment: "SYNTH-never-executed", per_task: [], rejected: [], admitted: 16, attempted: 16, gates_met: 0,
      by_condition: [
        { condition: "treatment", units: 8, accepted: 0, durable_changes: 0, total_tokens: 4_000_000 },
        { condition: "control", units: 8, accepted: 7, durable_changes: 8, total_tokens: 5_000_000 },
      ],
    },
  },
  {
    name: "floor WITHOUT spend — the acceptance predicate fires, the spend one must not",
    expect: ["total-acceptance-floor"],
    input: {
      experiment: "SYNTH-floor-no-spend", per_task: [], rejected: [], admitted: 12, attempted: 12, gates_met: 0,
      by_condition: [
        { condition: "treatment", units: 6, accepted: 0, durable_changes: 0, total_tokens: 0 },
        { condition: "control", units: 6, accepted: 6, durable_changes: 6, total_tokens: 3_000_000 },
      ],
    },
  },
  {
    name: "spend with output but zero acceptance is NOT non-action — floor only",
    expect: ["total-acceptance-floor"],
    input: {
      experiment: "SYNTH-worked-all-rejected", per_task: [], rejected: [], admitted: 12, attempted: 12, gates_met: 0,
      by_condition: [
        { condition: "treatment", units: 6, accepted: 0, durable_changes: 6, total_tokens: 3_000_000 },
        { condition: "control", units: 6, accepted: 4, durable_changes: 6, total_tokens: 2_500_000 },
      ],
    },
  },
];
