#!/usr/bin/env node
// EXP-0013 measured-topology CONTRACT (no execution here — building the
// schedule and validating its constraints; launching workers requires the
// separate spend authorization).
//
// Constraints (each violation is a typed refusal):
//   - one worker lane per disjoint SEQUENCE;
//   - positions within a sequence STRICTLY SERIAL (memory accumulates);
//   - both arms of one pair NEVER concurrent (and executed back-to-back in
//     the precommitted randomized order);
//   - isolated paths per sequence: worktree, baseline cache, tmpdir,
//     results dir, ledger, prompt namespace — all distinct.

export function buildSchedule({ sequences, positions, armOrder }) {
  // armOrder: {seqId: {position: ['lean_rules','lean_skills'] | reversed}} — precommitted.
  const lanes = {};
  for (const seq of sequences) {
    lanes[seq] = [];
    for (const pos of positions) {
      const order = armOrder?.[seq]?.[pos];
      if (!order || order.length !== 2) return { ok: false, reason: `no precommitted arm order for ${seq}.p${pos}` };
      for (const arm of order) lanes[seq].push({ seq, pos, arm });
    }
  }
  return { ok: true, lanes, concurrency: Object.keys(lanes).length };
}

export function validateExecutionLog(log) {
  // log: [{seq,pos,arm,start,end}] — verifies the constraints held.
  for (const a of log) for (const b of log) {
    if (a === b) continue;
    const overlap = a.start < b.end && b.start < a.end;
    if (!overlap) continue;
    if (a.seq === b.seq) return { ok: false, reason: `SERIAL VIOLATION: ${a.seq} ran p${a.pos}/${a.arm} and p${b.pos}/${b.arm} concurrently` };
    // cross-sequence overlap is the permitted concurrency (one lane each)
  }
  for (const a of log) for (const b of log) {
    if (a !== b && a.seq === b.seq && a.pos === b.pos && a.arm !== b.arm) {
      const overlap = a.start < b.end && b.start < a.end;
      if (overlap) return { ok: false, reason: `PAIR VIOLATION: both arms of ${a.seq}.p${a.pos} concurrent` };
    }
  }
  return { ok: true };
}

export function isolationManifest(root, sequences) {
  const m = {};
  for (const seq of sequences) m[seq] = {
    worktree: `${root}/${seq}/worktree`, baseline: `${root}/${seq}/baseline-cache`,
    tmp: `${root}/${seq}/tmp`, results: `${root}/${seq}/results`,
    ledger: `${root}/${seq}/results/spend-ledger.jsonl`, prompt_ns: `exp0013-${seq}`,
  };
  const all = Object.values(m).flatMap((x) => Object.values(x));
  if (new Set(all).size !== all.length) return { ok: false, reason: "isolation path collision" };
  return { ok: true, manifest: m };
}
