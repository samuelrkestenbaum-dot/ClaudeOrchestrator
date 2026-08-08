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
import { continuityState } from "./continuity.mjs";
import { CLAIMS } from "./continuity-claims.mjs";

export const DECLARED_SURFACES = ["chatgpt", "claude", "manus", "surplus_recovery"];

const tsv = (p) => fs.readFileSync(p, "utf8").split("\n")
  .filter((l) => l && !l.startsWith("#")).map((l) => l.split("\t"));

/** Surface family from a surface_instance like "claude.cowork.session.ramhds". */
const familyOf = (instance) => String(instance || "").split(".")[0] || null;

/**
 * LAYER 1 of 3 — REPOSITORY SURFACE ACTIVITY.
 *
 * Answers: has this surface contributed attributable durable state to the
 * repository/memory substrate? That is a coverage/health signal.
 *
 * It is explicitly NOT the operational readiness gate, and it never was. The
 * divergence with the Operator Lab was never a contradiction — it was two
 * different questions wearing one name. Claude is repository-active AND
 * live-Operator-Lab-missing, and both statements are true simultaneously.
 *
 * The three layers, weakest to strongest:
 *   1. repository_surface_activity        — leaves organizational memory
 *   2. live_operator_lab_participation    — connected to the live control plane
 *                                            (THIS is four_surface_readiness)
 *   3. cross_surface_behavioral_continuity — knowledge transfers and changes
 *                                            what another surface DOES
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
    NOT_THE_READINESS_GATE:
      "This is a substrate-coverage/health signal, NOT four_surface_readiness. The canonical operational " +
      "readiness gate is live_operator_lab_participation. See build-os/surfaces/SEMANTICS.md.",
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
export function behavioralContinuity({ kernelDir = "build-os/kernel", claims = null } = {}) {
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

  // THE STATE IS GRADED, NOT ASSERTED. This function used to take
  // `proofs: [{ behaviour_changed: true, result_written_back: true }]` and
  // count the entries — two free booleans supplied by the party making the
  // claim, so the strongest state the substrate could report was decided by
  // whoever typed `true`. Claims now go through gradeContinuity(), which
  // downgrades any link asserted PROVEN without an evidence reference and
  // refuses a divergence claim that carries no counterfactual.
  const graded = continuityState(claims ?? CLAIMS);

  return {
    artifact: "cross_surface_behavioral_continuity",
    cross_surface_handoffs: crossPairs,
    consumption_evidence: crossPairs.length > 0,
    claims_graded: graded.claims,
    by_verdict: graded.by_verdict,
    state: graded.state,
    weakest_link_per_claim: graded.grades.map((g) => ({ claim: g.claim_id, verdict: g.verdict, weakest: g.weakest_link })),
    downgrades: graded.grades.flatMap((g) => g.downgrades),
    note:
      "Continuity requires: A writes, B consumes, B's behaviour differs against a stated counterfactual, the " +
      "result is written back attributably, and a further consumer can read it. A handoff crossing surfaces " +
      "shows state was RECEIVED; receipt is not continuity, and an assertion is not evidence.",
  };
}

// Backwards-compatible alias, deliberately NOT named readiness.
export const readiness = repositorySurfaceActivity;
