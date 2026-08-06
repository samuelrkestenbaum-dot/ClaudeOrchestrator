#!/usr/bin/env node
// PRODUCT EVIDENCE DASHBOARD — one fixture-backed customer view.
//
//   render-dashboard.mjs --out <path> [--store <dir>] [--ledger <file>]
//                        [--window <file>] [--eligibility <file>] [--json]
//   render-dashboard.mjs contract --json
//
// WHAT THIS IS. The smallest useful evidence view: what ran, how deep, how
// long, what it cost where that is knowable, how much independent checking was
// bought and whether it changed anything — and, in the same table and the same
// type size, every field this system CANNOT honestly fill today.
//
// WHAT IT IS NOT. Not an analytics platform. There is no chart, no trend, no
// score, no saving, and no benchmark. It reads what the routing layer already
// recorded and refuses to compute anything it did not measure.
//
// THE THREE BINDING RULES (each pinned by tests/dashboard_contract_tests.sh):
//
//   1. EVERY FIELD DECLARES A SOURCE AND A TIER. The tier vocabulary is the
//      provider-adapter contract's, extended to this view's inputs:
//        EXACT       counted by an instrument that observed it directly and is
//                    reproducible from the named artifact;
//        ESTIMATE    a derived proxy, labeled everywhere it appears, never
//                    billing truth, never promoted;
//        CLOSE-TIME  not observable during the run; filled afterwards from a
//                    named artifact (a receipt close-fill, provider-telemetry
//                    reconciliation, or a measured-window record);
//        UNAVAILABLE no artifact in this system records it today. Rendered
//                    `unavailable (<reason>)`, with the reason, ALWAYS.
//   2. AN UNKNOWN IS NEVER A ZERO. A missing value renders `unavailable` with
//      the reason it is missing. A measured zero and an unmeasured field are
//      different claims and this view never conflates them.
//   3. NO SILENT PROMOTION. A field whose tier is UNAVAILABLE stays unavailable
//      even if an input file volunteers a value for it. The tier is a property
//      of the SYSTEM's ability to measure, not of one file's willingness to
//      assert.
//
// ISOLATION. Reads only; writes exactly one file, the --out path; refuses to
// run without --out because there is nowhere honest to put the answer. It
// opens no experiment tree and no index build.
//
// VOCABULARY. The rendered view speaks the customer's language. Free text
// written by internal tools passes through a translation layer, then a final
// backstop that neutralises any residual internal token — a customer view that
// leaks internal words on an unusual input is a defect, not a rare case.
//
// Dependencies: node stdlib only. No network. Deterministic: same inputs,
// byte-identical output (no wall-clock field is emitted unless --now is given).

import fs from 'node:fs';
import path from 'node:path';

const VIEW_VERSION = 1;

// --------------------------------------------------------------- registry ----
// THE canonical field registry. build-os/dashboard/DASHBOARD_CONTRACT.md holds
// the same table for humans, and the suite refuses to pass if the two drift.
const FIELDS = [
  {
    id: 'task_count',
    label: 'Tasks recorded',
    tier: 'EXACT',
    source: 'one routing receipt file per routed task in the routing store',
  },
  {
    id: 'execution_depth_mix',
    label: 'Depth of execution',
    tier: 'EXACT',
    source: 'routing receipt field `selected_mode:`, rendered Direct / Light / Full',
  },
  {
    id: 'depth_changes',
    label: 'Depth changed mid-run',
    tier: 'CLOSE-TIME',
    source: 'routing receipt fields `escalation:` and `degradation_note:`, filled at close',
  },
  {
    id: 'elapsed_seconds',
    label: 'Time elapsed',
    tier: 'CLOSE-TIME',
    source: 'routing receipt field `consumed_wall_clock_s:`, filled at close',
  },
  {
    id: 'tool_actions',
    label: 'Tool actions',
    tier: 'EXACT',
    source: '`tool_event` rows in the per-task live-state file',
  },
  {
    id: 'exploratory_reads',
    label: 'Exploratory reads',
    tier: 'EXACT',
    source: '`exploratory_event` rows in the per-task live-state file',
  },
  {
    id: 'governed_changes',
    label: 'Governed changes',
    tier: 'EXACT',
    source: '`mutation_event` rows in the per-task live-state file',
  },
  {
    id: 'token_estimate',
    label: 'Estimated work volume',
    tier: 'ESTIMATE',
    source: 'sum of `chars=` on `tool_event` rows in the live-state files, divided by 4',
  },
  {
    id: 'tokens_billed',
    label: 'Billed work volume',
    tier: 'CLOSE-TIME',
    source: 'routing receipt field `consumed_total_tokens:`, reconciled from provider telemetry at close',
  },
  {
    id: 'spend_usd',
    label: 'Spend',
    tier: 'CLOSE-TIME',
    source: 'routing receipt field `consumed_cost_usd:`, reconciled from provider telemetry at close',
  },
  {
    id: 'spend_by_category',
    label: 'Spend by category',
    tier: 'CLOSE-TIME',
    source: 'the seven `attr_*:` attribution fields on the routing receipt, filled at close',
  },
  {
    id: 'verifier_use',
    label: 'Independent checking runs',
    tier: 'EXACT',
    source: '`task_dispatch` rows in the live-state files, cross-checked against receipt `consumed_subagents:`',
  },
  {
    id: 'verifier_efficacy',
    label: 'Checking that changed the outcome',
    tier: 'CLOSE-TIME',
    source: '`contribution:` rows on the routing receipt, fields `caught_defect=`, `changed_implementation=`, `changed_conclusion=`, `duplicated_work=`',
  },
  {
    id: 'blocked_unrouted_changes',
    label: 'Unrouted changes blocked',
    tier: 'EXACT',
    source: 'BLOCK-MUTATION-NO-RECEIPT and BLOCK-NO-RECEIPT rows in the activity ledger',
  },
  {
    id: 'throttle_events',
    label: 'Throttle and reassessment events',
    tier: 'EXACT',
    source: 'BLOCK-FANOUT-BUDGET, BLOCK-DEGRADED, BLOCK-PROCESS-ALLOWANCE and BLOCK-REASSESS rows in the activity ledger',
  },
  {
    id: 'durable_change_size',
    label: 'Durable change size',
    tier: 'CLOSE-TIME',
    source: 'the `close` row of a measured-window record, fields `files=` and the insertion and deletion counts, derived from git by the window recorder',
  },
  {
    id: 'eligibility_decision',
    label: 'Repository eligibility decision',
    tier: 'EXACT',
    source: 'the `verdict` field of an eligibility record produced by the repository assessment procedure, supplied with --eligibility',
  },
  {
    id: 'durable_commits',
    label: 'Durable commits',
    tier: 'UNAVAILABLE',
    source: 'the `close` row of a measured-window record is the intended source',
    reason: 'the window recorder prints the git-derived commit count to the terminal but stores the literal text derived-from-git in the commits slot, so the number is not in the record; fillable the day that recorder stores the count it already computes',
  },
  {
    id: 'context_mode',
    label: 'Context mode',
    tier: 'UNAVAILABLE',
    source: 'a context-mode record, field `mode:`, standard or compiled',
    reason: 'the producing tool ships inert and nothing in the runtime calls it, so no customer task emits a context-mode record; this renders unavailable rather than defaulting to standard, and is fillable the day the seam is wired',
  },
  {
    id: 'accepted_outcomes',
    label: 'Accepted outcomes',
    tier: 'UNAVAILABLE',
    source: 'none today; the intended source is a per-task acceptance judgment recorded by the operator at close',
    reason: 'no receipt field, ledger row or live-state row records whether a task output was accepted; acceptance has so far existed only as operator prose in a written report, which no tool can read; fillable when a per-task acceptance note is recorded at close',
  },
  {
    id: 'human_interventions',
    label: 'Human interventions',
    tier: 'UNAVAILABLE',
    source: 'none today; the intended source is a per-task intervention note in the measured-window record',
    reason: 'the activity ledger records the GATE intervening, which is not the same event as a human stopping, correcting or steering a run; counting gate blocks here would answer a different question while wearing this label',
  },
  {
    id: 'rework',
    label: 'Rework',
    tier: 'UNAVAILABLE',
    source: 'none today; the intended source is an operator judgment recorded against a prior task id',
    reason: 'nothing records whether a later change re-did an earlier accepted one, and git alone cannot separate rework from progress; inferring it from commit shape would be a guess presented as a measurement',
  },
  {
    id: 'regressions',
    label: 'Regressions',
    tier: 'UNAVAILABLE',
    source: 'none today; the intended source is a per-task test-result field filled at close',
    reason: 'no receipt field, ledger row or live-state row stores a test result, so the suite pass or fail exists only in a terminal transcript this view cannot read; fillable when a per-task test-result field is recorded at close',
  },
];

const FIELD_BY_ID = new Map(FIELDS.map((f) => [f.id, f]));

// ------------------------------------------------------------- vocabulary ----
// Stage 1 mirrors the customer shell's word-level translation layer. Stage 2 is
// the BACKSTOP: any internal token that survives stage 1 is neutralised rather
// than printed. Case-sensitive on the lowercase doctrine forms — a customer's
// own uppercase task id is the customer's vocabulary and passes through.
const TRANSLATIONS = [
  [/gravito_full/g, 'Full mode'],
  [/gravito_light/g, 'Light mode'],
  [/mandatory_full_regate/g, 'a required full re-check'],
  [/DC-[0-9]+/g, 'a recorded design decision'],
  [/\bpackets\b/g, 'tasks'],
  [/\bpacket\b/g, 'task'],
  [/\barchivist\b/g, 'record-keeping'],
  [/\bcensused\b/g, 'registered'],
  [/\bcensus\b/g, 'registry'],
  [/\bqa\b/g, 'verification'],
  [/\breviewer\b/g, 'review'],
  [/\bbuilder\b/g, 'implementation'],
  [/\bsubagents\b/g, 'helper agents'],
  [/\bsubagent\b/g, 'helper agent'],
  [/\bdispatches\b/g, 'helper runs'],
];
const RESIDUAL = /gravito_full|gravito_light|\bpackets?\b|\bcensus(ed)?\b|\barchivist\b|\bsubagents?\b|DC-[0-9]+/g;

function scrub(text) {
  let s = String(text == null ? '' : text);
  for (const [re, to] of TRANSLATIONS) s = s.replace(re, to);
  s = s.replace(RESIDUAL, 'an internal detail');
  return s.replace(/\s+/g, ' ').trim();
}

// ------------------------------------------------------------------ values ---
// A value object is the ONLY way a number reaches the view. `unavailable`
// carries its reason; there is no code path that turns an absent value into 0.
const value = (v, note) => ({ available: true, value: v, note: note || null });
const unavailable = (reason) => ({ available: false, value: null, reason });

const commas = (n) => String(n).replace(/\B(?=(\d{3})+(?!\d))/g, ',');

function isNum(s) { return typeof s === 'string' && /^-?[0-9]+(\.[0-9]+)?$/.test(s.trim()); }

// ------------------------------------------------------------------ inputs ---
function readLines(p) {
  try { return fs.readFileSync(p, 'utf8').split('\n'); } catch { return null; }
}

function parseReceipt(file) {
  const lines = readLines(file);
  if (lines === null) return null;
  const fields = new Map();
  const contributions = [];
  for (const line of lines) {
    if (line.startsWith('#')) continue;
    const i = line.indexOf(': ');
    if (i <= 0) continue;
    const key = line.slice(0, i);
    if (!/^[a-z_]+$/.test(key)) continue;
    const val = line.slice(i + 2);
    if (key === 'contribution') { contributions.push(val); continue; }
    if (!fields.has(key)) fields.set(key, val);
  }
  return { file, base: path.basename(file, '.md'), fields, contributions };
}

function fval(rec, key) {
  const v = rec.fields.get(key);
  return v === undefined || v === '' ? '-' : v;
}

function loadReceipts(store) {
  let names = [];
  try {
    names = fs.readdirSync(store).filter((n) => n.endsWith('.md')).sort();
  } catch { return null; }
  const out = [];
  for (const n of names) {
    const r = parseReceipt(path.join(store, n));
    if (r && r.fields.has('task_id')) out.push(r);
  }
  return out;
}

function loadState(store, base) {
  const lines = readLines(path.join(store, 'live_state', `${base}.tsv`));
  if (lines === null) return null;
  const rows = [];
  for (const line of lines) {
    if (!line || line.startsWith('#')) continue;
    const p = line.split('\t');
    if (p.length < 2 || p[1] === 'label') continue;
    rows.push({ ts: p[0], kind: p[1], detail: p[2] || '' });
  }
  return rows;
}

function loadLedger(file) {
  const lines = readLines(file);
  if (lines === null) return null;
  const rows = [];
  for (const line of lines) {
    if (!line || line.startsWith('#')) continue;
    const p = line.split('\t');
    if (p.length < 4) continue;
    rows.push({ ts: p[0], task: p[1], depth: p[2], decision: p[3], detail: p[4] || '' });
  }
  return rows;
}

function loadWindow(file) {
  const lines = readLines(file);
  if (lines === null) return null;
  const rows = lines.filter(Boolean).map((l) => l.split('\t'));
  return rows;
}

function loadJson(file) {
  try { return JSON.parse(fs.readFileSync(file, 'utf8')); } catch { return null; }
}

// ------------------------------------------------------------------ derive ---
const MODE_WORD = { direct: 'Direct', gravito_light: 'Light', gravito_full: 'Full' };
const modeWord = (m) => MODE_WORD[m] || (m === '-' ? 'not recorded' : 'unrecognised');

function compute(inputs) {
  const { store, receipts, ledger, ledgerPath, windowRows, windowPath, eligibility, eligibilityPath } = inputs;
  const out = new Map();
  const put = (id, v) => out.set(id, v);

  // ---- tasks
  if (receipts === null) {
    put('task_count', unavailable(`no routing store could be read at ${store}; nothing has been recorded here yet`));
  } else if (receipts.length === 0) {
    put('task_count', unavailable(`the routing store at ${store} holds no receipts yet; recording starts with the first routed task after install`));
  } else {
    put('task_count', value(receipts.length));
  }

  const R = receipts || [];
  const tasks = R.map((r) => {
    const state = loadState(store, r.base);
    const count = (kind) => (state === null ? null : state.filter((x) => x.kind === kind).length);
    let proxy = null;
    if (state !== null) {
      proxy = 0;
      for (const row of state) {
        if (row.kind !== 'tool_event') continue;
        const m = /chars=([0-9]+)/.exec(row.detail);
        if (m) proxy += Number(m[1]);
      }
      proxy = Math.floor(proxy / 4);
    }
    const executed = fval(r, 'executed_mode');
    return {
      id: fval(r, 'task_id'),
      started: fval(r, 'issued_at'),
      selected: fval(r, 'selected_mode'),
      executed,
      status: executed === '-' ? 'in progress' : 'complete',
      elapsed: fval(r, 'consumed_wall_clock_s'),
      tokens: fval(r, 'consumed_total_tokens'),
      cost: fval(r, 'consumed_cost_usd'),
      subagents: fval(r, 'consumed_subagents'),
      escalation: fval(r, 'escalation'),
      degradation: fval(r, 'degradation_note'),
      attr: ['attr_task_execution', 'attr_context_retrieval', 'attr_subagent_execution',
        'attr_verification', 'attr_review', 'attr_governance_process', 'attr_experiment_audit']
        .map((k) => [k, fval(r, k)]),
      contributions: r.contributions,
      hasState: state !== null,
      toolEvents: count('tool_event'),
      exploratory: count('exploratory_event'),
      mutations: count('mutation_event'),
      dispatches: count('task_dispatch'),
      proxy,
    };
  });

  // ---- depth mix
  if (tasks.length === 0) {
    put('execution_depth_mix', unavailable('no routed task has been recorded here yet, so there is no depth to report'));
  } else {
    const mix = new Map();
    for (const t of tasks) {
      const w = modeWord(t.selected);
      mix.set(w, (mix.get(w) || 0) + 1);
    }
    put('execution_depth_mix', value([...mix.entries()].sort((a, b) => b[1] - a[1] || (a[0] < b[0] ? -1 : 1))
      .map(([w, n]) => `${n} ${w}`).join(', ')));
  }

  // ---- depth changes (close-time)
  const closed = tasks.filter((t) => t.status === 'complete');
  if (closed.length === 0) {
    put('depth_changes', unavailable('no task has been closed yet, and depth changes are recorded at close'));
  } else {
    const changed = closed.filter((t) => t.escalation !== '-' || t.degradation !== '-').length;
    put('depth_changes', value(`${changed} of ${closed.length} closed tasks`));
  }

  // ---- elapsed
  const elapsed = closed.map((t) => t.elapsed).filter(isNum).map(Number);
  if (elapsed.length === 0) {
    put('elapsed_seconds', unavailable('no closed task recorded an elapsed time; a dash in that field is an honest admission and is never read as zero'));
  } else {
    const total = elapsed.reduce((a, b) => a + b, 0);
    put('elapsed_seconds', value(`${commas(total)} s across ${elapsed.length} of ${closed.length} closed tasks`));
  }

  // ---- live-state counts
  const stated = tasks.filter((t) => t.hasState);
  const noState = 'no live activity record exists for any task here; recording starts with the first governed session after install';
  const sum = (k) => stated.reduce((a, t) => a + (t[k] || 0), 0);
  if (stated.length === 0) {
    put('tool_actions', unavailable(noState));
    put('exploratory_reads', unavailable(noState));
    put('governed_changes', unavailable(noState));
    put('token_estimate', unavailable(noState));
    put('verifier_use', unavailable(noState));
  } else {
    put('tool_actions', value(commas(sum('toolEvents'))));
    put('exploratory_reads', value(commas(sum('exploratory'))));
    put('governed_changes', value(commas(sum('mutations'))));
    put('token_estimate', value(`~${commas(sum('proxy'))} tokens`));
    const declared = closed.map((t) => t.subagents).filter(isNum).map(Number).reduce((a, b) => a + b, 0);
    const counted = sum('dispatches');
    put('verifier_use', value(`${counted} counted live`,
      declared === counted ? null : `${declared} declared at close — the two counts disagree, and neither is silently preferred`));
  }

  // ---- billed tokens / spend / attribution
  const billed = closed.map((t) => t.tokens).filter(isNum).map(Number);
  put('tokens_billed', billed.length
    ? value(`${commas(billed.reduce((a, b) => a + b, 0))} tokens across ${billed.length} of ${closed.length} closed tasks`)
    : unavailable('no closed task carries a billed token count; live token counts are not visible to the gate in interactive sessions and reconcile only where the surface reports them at close'));

  const spend = closed.map((t) => t.cost).filter(isNum).map(Number);
  put('spend_usd', spend.length
    ? value(`$${spend.reduce((a, b) => a + b, 0).toFixed(2)} across ${spend.length} of ${closed.length} closed tasks`)
    : unavailable('no closed task carries a reconciled spend figure; spend is not visible during an interactive run and is never estimated into this field'));

  const attrRows = [];
  for (const t of closed) {
    for (const [k, v] of t.attr) if (isNum(v)) attrRows.push([k, Number(v)]);
  }
  if (attrRows.length === 0) {
    put('spend_by_category', unavailable('no closed task filled any attribution layer; every layer reads as an honest dash rather than a zero nobody measured'));
  } else {
    const agg = new Map();
    for (const [k, v] of attrRows) agg.set(k, (agg.get(k) || 0) + v);
    const LABEL = {
      attr_task_execution: 'doing the work',
      attr_context_retrieval: 'reading context',
      attr_subagent_execution: 'helper work',
      attr_verification: 'checking the work',
      attr_review: 'independent review',
      attr_governance_process: 'process overhead',
      attr_experiment_audit: 'audit',
    };
    put('spend_by_category', value([...agg.entries()].map(([k, v]) => `${LABEL[k] || k} ${commas(v)}`).join('; ')));
  }

  // ---- verifier efficacy
  const contribs = closed.flatMap((t) => t.contributions);
  if (contribs.length === 0) {
    put('verifier_efficacy', unavailable('no closed task carries a contribution row, so nothing records whether independent checking changed anything; a run with no checking has nothing to report here and a run with checking and no rows is a gap, not a zero'));
  } else {
    const yes = (re) => contribs.filter((c) => re.test(c)).length;
    const caught = yes(/caught_defect=y/);
    const changedImpl = yes(/changed_implementation=y/);
    const changedConcl = yes(/changed_conclusion=y/);
    const dup = yes(/duplicated_work=y/);
    put('verifier_efficacy', value(
      `${caught} caught a defect, ${changedImpl} changed the implementation, ${changedConcl} changed the conclusion, ${dup} duplicated work, out of ${contribs.length} checking runs`,
      'a run that caught nothing is recorded as catching nothing; that is the point of the row',
    ));
  }

  // ---- ledger
  if (ledger === null) {
    const why = `no activity ledger exists at ${ledgerPath}; the gate records activity from the next governed session onward`;
    put('blocked_unrouted_changes', unavailable(why));
    put('throttle_events', unavailable(why));
  } else {
    const blocked = ledger.filter((r) => r.decision === 'BLOCK-MUTATION-NO-RECEIPT' || r.decision === 'BLOCK-NO-RECEIPT').length;
    const throttles = ledger.filter((r) => ['BLOCK-FANOUT-BUDGET', 'BLOCK-DEGRADED', 'BLOCK-PROCESS-ALLOWANCE', 'BLOCK-REASSESS'].includes(r.decision)).length;
    put('blocked_unrouted_changes', value(commas(blocked), `out of ${commas(ledger.length)} recorded gate decisions`));
    put('throttle_events', value(commas(throttles), `out of ${commas(ledger.length)} recorded gate decisions`));
  }

  // ---- measured window
  if (windowRows === null) {
    put('durable_change_size', unavailable(`no measured-window record was readable at ${windowPath || 'any path — none was supplied with --window'}; durable change size is derived from git only when a window is opened and closed around the work`));
  } else {
    const close = windowRows.find((r) => r[0] === 'close');
    const m = close ? /files=(\S+)\s+\+(\S+)\s+-(\S+)/.exec(close[3] || '') : null;
    if (!m || m[1] === '-') {
      put('durable_change_size', unavailable('the measured window is open, or its close row carries no git-derived change size; an unclosed window has no durable output to report'));
    } else {
      put('durable_change_size', value(`${m[1]} files, +${m[2]} / -${m[3]} lines`));
    }
  }

  // ---- eligibility
  if (eligibility === null) {
    put('eligibility_decision', unavailable(`no eligibility record was readable at ${eligibilityPath || 'any path — none was supplied with --eligibility'}; run the repository assessment and pass its record with --eligibility`));
  } else {
    const verdict = eligibility.verdict || (eligibility.eligibility && eligibility.eligibility.verdict);
    put('eligibility_decision', verdict
      ? value(scrub(verdict), eligibility.recommended_use_state ? `recommended use state: ${scrub(eligibility.recommended_use_state)}` : null)
      : unavailable('the supplied eligibility record carries no verdict field, so no decision can be shown; a record without a verdict is not a pass'));
  }

  return { fields: out, tasks };
}

// ---------------------------------------------------------------- assemble ---
function assemble(computed) {
  return FIELDS.map((f) => {
    // RULE 3: an UNAVAILABLE field is unavailable regardless of what any input
    // volunteered. The lookup below never even runs for it.
    if (f.tier === 'UNAVAILABLE') {
      return { id: f.id, label: f.label, tier: f.tier, source: f.source, value: null, reason: f.reason };
    }
    const v = computed.fields.get(f.id);
    if (!v || v.available !== true) {
      return {
        id: f.id, label: f.label, tier: f.tier, source: f.source, value: null,
        reason: (v && v.reason) || 'no source artifact for this field was present in the inputs supplied',
      };
    }
    return {
      id: f.id, label: f.label, tier: f.tier, source: f.source,
      value: v.value, note: v.note || undefined,
    };
  });
}

const TIER_SUFFIX = {
  EXACT: '[EXACT]',
  ESTIMATE: '[ESTIMATE — a proxy from tool-input size, never billing truth]',
  'CLOSE-TIME': '[CLOSE-TIME — filled after the run, not during it]',
};

function displayOf(f) {
  if (f.value === null) return `unavailable (${f.reason})`;
  const suffix = TIER_SUFFIX[f.tier] || '';
  const note = f.note ? ` — ${f.note}` : '';
  return `${f.value}${note} ${suffix}`.trim();
}

// ------------------------------------------------------------------ render ---
const PAD = Math.max(...FIELDS.map((f) => f.label.length)) + 1;

function renderText(fields, tasks, inputs) {
  const L = [];
  L.push('YOUR EVIDENCE VIEW — what ran, how deep, what it cost, and what is not known');
  L.push('');
  L.push('Every line carries its tier. An unknown is shown as unavailable WITH THE');
  L.push('REASON it is unknown — never as a zero, because a measured zero and an');
  L.push('unmeasured field are different claims.');
  L.push('');
  L.push('== SUMMARY ==');
  for (const f of fields) {
    L.push(`  ${f.label.padEnd(PAD)}: ${displayOf(f)}`);
  }

  L.push('');
  L.push('== TASKS ==');
  if (tasks.length === 0) {
    L.push('  no routed task has been recorded here yet.');
  } else {
    L.push(`  ${'TASK'.padEnd(46)} ${'DEPTH'.padEnd(7)} ${'STATUS'.padEnd(12)} ${'TIME'.padEnd(12)} CHANGES`);
    for (const t of tasks.slice(0, 40)) {
      const time = isNum(t.elapsed) ? `${t.elapsed} s` : 'unavailable';
      const changes = t.hasState ? String(t.mutations) : 'unavailable';
      L.push(`  ${scrub(t.id).slice(0, 46).padEnd(46)} ${modeWord(t.selected).padEnd(7)} ${t.status.padEnd(12)} ${time.padEnd(12)} ${changes}`);
    }
    if (tasks.length > 40) L.push(`  (showing the first 40 of ${tasks.length})`);
  }

  const notes = tasks.filter((t) => t.degradation !== '-').map((t) => `${scrub(t.id)}: ${scrub(t.degradation)}`);
  L.push('');
  L.push('== NOTES RECORDED DURING RUNS ==');
  if (notes.length === 0) L.push('  none recorded.');
  else for (const n of notes.slice(0, 10)) L.push(`  - ${n}`);

  L.push('');
  L.push('== EVIDENCE YOU CAN INSPECT YOURSELF ==');
  L.push(`  routing store:      ${inputs.store}`);
  L.push(`  activity ledger:    ${inputs.ledger === null ? `${inputs.ledgerPath} (absent)` : inputs.ledgerPath}`);
  L.push(`  measured window:    ${inputs.windowRows === null ? `${inputs.windowPath || 'not supplied'} (absent)` : inputs.windowPath}`);
  L.push(`  eligibility record: ${inputs.eligibility === null ? `${inputs.eligibilityPath || 'not supplied'} (absent)` : inputs.eligibilityPath}`);

  L.push('');
  L.push('== WHAT THIS VIEW DOES NOT CLAIM ==');
  L.push('  It reports what this installation recorded. It contains no benchmark, no');
  L.push('  saving, no trend and no comparison against any other team or tool, because');
  L.push('  none of those has been measured. Fields marked unavailable are gaps in what');
  L.push('  the system can observe today, stated so you can price them yourself.');
  return `${L.join('\n')}\n`;
}

function renderJson(fields, tasks, inputs) {
  return `${JSON.stringify({
    view_version: VIEW_VERSION,
    tier_vocabulary: {
      EXACT: 'counted by an instrument that observed it directly; reproducible from the named artifact',
      ESTIMATE: 'a derived proxy, labeled everywhere it appears, never billing truth',
      'CLOSE-TIME': 'not observable during the run; filled afterwards from a named artifact',
      UNAVAILABLE: 'no artifact in this system records it today; rendered with a reason, never as 0',
    },
    inputs: {
      routing_store: inputs.store,
      activity_ledger: inputs.ledger === null ? null : inputs.ledgerPath,
      measured_window: inputs.windowRows === null ? null : inputs.windowPath,
      eligibility_record: inputs.eligibility === null ? null : inputs.eligibilityPath,
    },
    fields: fields.map((f) => ({ ...f, display: displayOf(f) })),
    tasks: tasks.map((t) => ({
      id: scrub(t.id),
      started: t.started === '-' ? null : t.started,
      depth: modeWord(t.selected),
      status: t.status,
      elapsed_seconds: isNum(t.elapsed) ? Number(t.elapsed) : null,
      governed_changes: t.hasState ? t.mutations : null,
      independent_checking_runs: t.hasState ? t.dispatches : null,
    })),
  }, null, 2)}\n`;
}

// -------------------------------------------------------------------- main ---
function die(msg) {
  process.stderr.write(`render-dashboard: ${msg}\n`);
  process.exit(2);
}

const USAGE = `usage: render-dashboard.mjs --out <path> [--store <dir>] [--ledger <file>]
                            [--window <file>] [--eligibility <file>] [--json]
       render-dashboard.mjs contract --json
`;

function main(argv) {
  if (argv[0] === 'contract') {
    process.stdout.write(`${JSON.stringify({ contract_version: VIEW_VERSION, fields: FIELDS }, null, 2)}\n`);
    return 0;
  }
  const here = path.dirname(new URL(import.meta.url).pathname);
  const repoRoot = path.resolve(here, '..', '..');
  let store = path.join(repoRoot, 'build-os', 'packets', 'routing');
  let out = null; let ledgerPath = null; let windowPath = null; let eligibilityPath = null;
  let asJson = false;

  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--out') { out = argv[++i]; if (!out) die('--out needs a path'); }
    else if (a === '--store') { store = argv[++i]; if (!store) die('--store needs a directory'); }
    else if (a === '--ledger') { ledgerPath = argv[++i]; if (!ledgerPath) die('--ledger needs a file'); }
    else if (a === '--window') { windowPath = argv[++i]; if (!windowPath) die('--window needs a file'); }
    else if (a === '--eligibility') { eligibilityPath = argv[++i]; if (!eligibilityPath) die('--eligibility needs a file'); }
    else if (a === '--json') asJson = true;
    else if (a === '-h' || a === '--help') { process.stdout.write(USAGE); return 0; }
    else die(`unknown argument: ${a}\n${USAGE}`);
  }
  if (out === null) die(`--out is required: this tool writes exactly one file and nowhere else\n${USAGE}`);

  store = path.resolve(store);
  if (ledgerPath === null) ledgerPath = path.join(store, 'live_gate_log.tsv');

  const inputs = {
    store,
    receipts: loadReceipts(store),
    ledgerPath,
    ledger: loadLedger(ledgerPath),
    windowPath,
    windowRows: windowPath ? loadWindow(windowPath) : null,
    eligibilityPath,
    eligibility: eligibilityPath ? loadJson(eligibilityPath) : null,
  };

  const computed = compute(inputs);
  const fields = assemble(computed);
  const body = asJson
    ? renderJson(fields, computed.tasks, inputs)
    : renderText(fields, computed.tasks, inputs);

  fs.writeFileSync(out, body);
  process.stdout.write(`render-dashboard: wrote ${out} (${computed.tasks.length} task(s), ${fields.filter((f) => f.value === null).length} of ${fields.length} fields unavailable)\n`);
  return 0;
}

process.exit(main(process.argv.slice(2)));
