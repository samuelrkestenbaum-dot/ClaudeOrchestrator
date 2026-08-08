// FOUR-SURFACE READINESS — measured from the kernel ledger, never asserted.
//
// Two states, deliberately separate, because they answer different questions:
//
//   readiness_gate                    — do all declared surface families WRITE
//                                       durable state inside the window?
//   cross_surface_behavioral_continuity
//                                     — did a surface CONSUME state produced
//                                       elsewhere and BEHAVE DIFFERENTLY as a
//                                       result, with the result written back?
//
// The second is the one that matters. Heartbeat rows are cheap; a surface that
// writes but never acts on what another surface wrote is not part of a shared
// organizational brain, it is a logger. A gate that cannot tell those apart
// would report success for the wrong system.

import fs from "node:fs";
import path from "node:path";

export const DECLARED_SURFACES = ["chatgpt", "claude", "manus", "surplus_recovery"];

const tsv = (p) => fs.readFileSync(p, "utf8").split("\n")
  .filter((l) => l && !l.startsWith("#")).map((l) => l.split("\t"));

/** Surface family from a surface_instance like "claude.cowork.session.ramhds". */
const familyOf = (instance) => String(instance || "").split(".")[0] || null;

/**
 * NAME CORRECTED. This function measures REPOSITORY SURFACE ACTIVITY: which
 * declared families appear as writers in the committed kernel ledger. It was
 * briefly labelled `four_surface_readiness`, and that label is now known to be
 * wrong, because a second machine-readable authority — the live Operator Lab
 * `check_substrate_readiness` — reports a different answer for what was
 * presented as the same state.
 *
 * Two measurements that disagree cannot both be canonical. Until the divergence
 * is resolved (see build-os/surfaces/DIVERGENCE.md) this one answers only:
 * "who has written into the repository ledger", which is NOT the same question
 * as "who is participating in the live substrate right now".
 */
export function repositorySurfaceActivity({ kernelDir = "build-os/kernel", windowDays = 7, now = null } = {}) {
  const evPath = path.join(kernelDir, "memory_events.tsv");
  const rows = tsv(evPath).filter((r) => r.length > 6 && /^EVT-/.test(r[0]));

  // `now` MUST be supplied or derived from the data — never from the clock, so
  // the gate is reproducible and cannot silently change verdict between runs.
  const stamps = rows.map((r) => Date.parse(r[2])).filter((n) => Number.isFinite(n));
  const latest = stamps.length ? Math.max(...stamps) : null;
  const anchor = now ? Date.parse(now) : latest;
  const cutoff = anchor === null ? null : anchor - windowDays * 86400_000;

  const perSurface = {};
  for (const s of DECLARED_SURFACES) perSurface[s] = { writes_total: 0, writes_in_window: 0, event_types: new Set(), last_write: null };

  for (const r of rows) {
    const fam = familyOf(r[5]);
    if (!perSurface[fam]) continue;                    // undeclared surfaces are ignored, not invented
    const t = Date.parse(r[2]);
    perSurface[fam].writes_total++;
    perSurface[fam].event_types.add(r[1]);
    if (!perSurface[fam].last_write || t > Date.parse(perSurface[fam].last_write)) perSurface[fam].last_write = r[2];
    if (cutoff !== null && Number.isFinite(t) && t >= cutoff) perSurface[fam].writes_in_window++;
  }

  const surfaces = Object.fromEntries(Object.entries(perSurface).map(([k, v]) => [k, {
    writes_total: v.writes_total,
    writes_in_window: v.writes_in_window,
    distinct_event_types: v.event_types.size,
    last_write: v.last_write,
    // A surface with zero rows was never exercised. That is UNTESTED, which is
    // not the same as a surface that was exercised and stopped writing.
    status: v.writes_total === 0 ? "untested" : (v.writes_in_window > 0 ? "active" : "stale"),
  }]));

  const active = DECLARED_SURFACES.filter((s) => surfaces[s].status === "active");
  const gate = active.length === DECLARED_SURFACES.length ? "PASS" : "FAIL";

  return {
    artifact: "repository_surface_activity",
    NOT_CANONICAL_READINESS:
      "This is one of two disagreeing authorities. It is NOT four_surface_readiness. " +
      "See build-os/surfaces/DIVERGENCE.md before quoting this verdict as readiness.",
    window_days: windowDays,
    window_anchor: anchor ? new Date(anchor).toISOString() : null,
    anchor_source: now ? "supplied" : "latest event in ledger (NOT wall clock — the gate must be reproducible)",
    declared: DECLARED_SURFACES,
    surfaces,
    active,
    activity_gate: gate,
    gate_reason: gate === "PASS" ? "all declared surface families wrote inside the window"
      : `only ${active.length} of ${DECLARED_SURFACES.length} declared families wrote inside the window: ` +
        DECLARED_SURFACES.map((s) => `${s}=${surfaces[s].status}`).join(", "),
  };
}

/**
 * The stronger state. Requires a demonstrated loop:
 *   surface A writes -> surface B reads it -> B's behaviour differs -> result
 *   written back and attributable.
 *
 * Writes alone never satisfy this, however many there are.
 */
export function behavioralContinuity({ kernelDir = "build-os/kernel", proofs = [] } = {}) {
  const handoffPath = path.join(kernelDir, "memory_handoffs.tsv");
  let handoffs = [];
  try { handoffs = tsv(handoffPath).filter((r) => r.length > 3 && /^HOF-/.test(r[0])); } catch { handoffs = []; }

  // A handoff that was created by one surface and ACCEPTED by another is the
  // weakest credible evidence of consumption. It is still not behaviour change.
  const evRows = tsv(path.join(kernelDir, "memory_events.tsv")).filter((r) => r.length > 6);
  const created = evRows.filter((r) => r[1] === "HandoffCreated");
  const accepted = evRows.filter((r) => r[1] === "HandoffAccepted");
  const crossPairs = [];
  for (const c of created) {
    for (const a of accepted) {
      if (c[13] && c[13] === a[13] && familyOf(c[5]) !== familyOf(a[5])) {
        crossPairs.push({ handoff: c[13], from: familyOf(c[5]), to: familyOf(a[5]) });
      }
    }
  }

  const demonstrated = proofs.filter((p) => p.behaviour_changed === true && p.result_written_back === true);

  return {
    artifact: "cross_surface_behavioral_continuity",
    cross_surface_handoffs: crossPairs,
    consumption_evidence: crossPairs.length > 0,
    behaviour_change_proofs: demonstrated.length,
    state: demonstrated.length > 0 ? "DEMONSTRATED"
      : (crossPairs.length > 0 ? "CONSUMPTION_ONLY" : "NOT_DEMONSTRATED"),
    note:
      crossPairs.length > 0 && demonstrated.length === 0
        ? "A handoff crossed surfaces, which shows state was RECEIVED. It does not show the receiving surface " +
          "behaved differently because of it. Receipt is not continuity."
        : "Continuity requires: A writes, B consumes, B's behaviour differs, and the result is written back attributably.",
  };
}

// Backwards-compatible alias, deliberately NOT named readiness.
export const readiness = repositorySurfaceActivity;
