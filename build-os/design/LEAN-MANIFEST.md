# LEAN_MANIFEST — frozen file-level design, before any implementation

**Drawn against `TARGET-OPERATING-MODEL.md`. Sized by the frozen clean baseline
(`EXP-0007/RUNNABLE-BASELINE-RESULT.md`): gap 2.44× cost / 2.12× uncached with
verification runnable; residual mechanism = the worker participating in the
control transaction.**

Governing principle: **remove the worker from the control transaction.** Keep
the intelligence; move execution of that intelligence to the substrate side of
the boundary.

Acceptance rule (operator, binding): every row names the **measured
worker-control interaction it removes** and the **substrate-side mechanism that
replaces it**. Context-only rows fail. Post-Lean compliance is checked with the
existing frozen instrument — no new measurement framework.

Priority order is the operator's, fixed from the measured mechanisms — not
intuition.

---

## L1 — Completion and concession resolve substrate-side

**Attacks (largest first): repeat `final_report` 2.4/arm vs native 0.7;
`gate_challenge_response` 1.1/arm; the residual text-only excess these drive.**

**Files:** `build-os/motion/gate-stop.mjs`, `build-os/motion/concession-gate.mjs`,
`.claude/hooks/concession-gate.sh` (call contract only).

**The two defects being relocated, named exactly:**

1. `gate-stop.mjs` freshness contract: the worker's final message must contain
   the first 40 characters of `evidence.for_conclusion`, and the worker must
   author the 8-field evidence file itself. This prose-matching contract is
   directly responsible for the observed 2–3 refusal rounds per arm — each
   costing a search round plus a fresh 2,500–4,000-char re-report.
2. The gate demands the worker prove exhaustion; the worker then reads
   `gate-stop.mjs` and `concession-gate.mjs` to learn the schema — measured as
   `gate_mechanism_diagnosis`.

**Replacement mechanism:**

- **Completion stop** (last message claims done): the driver checks ARTIFACTS —
  acceptance evidence present, verification output or explicit
  unverified-with-reason recorded, diff exists. All satisfied → exit 0. No
  prose matching, no re-report demanded, ever.
- **Concession stop** (blocked / cannot): the driver itself runs
  `enumerateCapability` plus host-profile known-refusals, counts the stream's
  actual probes (attempts, distinct capability classes, information yield of
  the last probe), and applies the operator's EV rule — *search until the
  expected value of another step falls below its cost*. Verdict CONCEDE →
  driver writes the exhaustion evidence record itself and exits 0. Verdict
  CONTINUE → the driver emits **one** instruction naming the exact untested
  commands, never "prove you are out of options".

**Preserved:** the principle "never stop while unsearched agency remains" —
relocated, not deleted. Exhaustion evidence still exists on disk with full
provenance; it is machine-authored. Acceptance is untouched.

**Risk & guard:** the original defect (premature concession) returning. Guard:
the EV rule has a floor — CONCEDE is unreachable until the stream shows probes
in ≥2 distinct capability classes; below the floor the one-instruction path
fires. The decisive test's acceptance metric catches regression.

---

## L2 — Auto-routing: the receipt mints itself

**Attacks: `routing_bookkeeping` 2.0 text-turns/arm; the write-request-and-retry
round-trips inside bookkeeping+gate 4.6 calls/arm vs native 0.0.**

**Files:** `.claude/hooks/routing-gate.sh` (mutgate branch only).
`build-os/tools/route-task.sh` and `routing-check.sh` untouched.

**The seam, named exactly:** the gate already contains the full mint path — it
mints a receipt from a worker-written `routing-request.json`
(`BOOTSTRAP-RECEIPT-MINTED`) and already runs the mode selector itself. Today it
refuses the worker's first mutation and instructs the worker to author the
request and retry. Every field of that request is derivable substrate-side.

**Replacement mechanism:** on first mutation with no open receipt, the gate
derives {task_id, description, descriptor} from the session context, the tool
call, and the selector it already runs — mints the receipt inline with
`authored_by: runtime`, logs the same ledger rows, and ALLOWS the original call
in the same invocation. The worker never writes a routing request and never
sees a routing refusal in the default path.

**Preserved:** the receipt ledger, binding recorded mode, the full audit trail —
every receipt still exists. Escalation above the selector's lowest legal mode
still requires an explicit, worker-visible routing act; auto-mint covers only
the mode the selector would have granted anyway.

**Risk & guard:** silent escalation. Guard: `routing-check.sh` still refuses
silent escalation at close (unchanged), and auto-mint is capped at the
selector's lowest legal mode by construction.

---

## L3 — Refusals carry resolved state, never homework

**Attacks: `gate_mechanism_diagnosis` 2.2/arm starved and still present
runnable; the share of `capability_search` caused by a wrong default.**

**Files:** message text in `.claude/hooks/routing-gate.sh` and
`build-os/motion/gate-stop.mjs`; one behavioural fix in
`build-os/motion/capability-map.mjs`.

**The defect, named exactly:** `enumerateCapability(evidence?.capability ||
"operator_lab_write", ...)` — when the capability field is absent, the gate
answers about Operator Lab and offers a ChatGPT bridge irrelevant to the task.
Every measured arm that hit this spent a diagnosis loop discovering the citation
was a fallback misfire.

**Replacement mechanism:** unknown or absent capability → the message says "no
registered holder for <capability>; treated as absent from the system" — never a
default enumeration of a different capability. Every DENY message carries four
things: what is denied, why (one line), what the substrate already did about
it, and the single next action. Message contract: no gate message may reference
an internal file without also stating that file's resolved outcome — enforced by
a test that greps emitted messages, not sources.

**Preserved:** full internal logging, unchanged.

**Risk & guard:** message drift back toward homework. Guard: the
message-contract test plus `gate_mechanism_diagnosis` in the decisive test —
its target is 0.0/arm.

---

## L4 — Compiled task state instead of ceremony instructions

**Attacks: residual `capability_search` (uncertainty about what is available);
opening protocol overhead. Explicit non-target: narration — measured at 1% of
excess; a narration suppressor is measurably not worth building.**

**Files:** `CLAUDE.md` worker-facing sections;
`.claude/hooks/session-start-build-os.sh` (emit derived state).

**Replacement mechanism:** the worker receives derived CERTAINTY, per the TOM's
300–800-token compiled shape: "routing is automatic — your first edit opens a
receipt"; "verification: `<command>` — executable on this host: yes/no";
"authority: product files editable; build-os is machine-managed". This ADDS
resolved state; it does not subtract text. EXP-0007 variant B is the standing
proof that subtraction causes compensatory search (0.1 → 11.3 searches/arm),
and B's mechanism is this manifest's primary regression risk.

**Preserved:** doctrine reachable in full for the rare case that needs it.

**Risk & guard:** under-specified state → B-style hunting. Guard:
`capability_search` and `gravito_search` in the decisive test must not exceed
the current baseline; any rise refutes the compiled state as insufficient.

---

## Declared worker-visible interface after Lean (complete list)

1. The task prompt plus the compiled state block (L4).
2. Gate messages conforming to the L3 contract.
3. **Nothing else.** No worker-authored `routing-request.json`, no
   worker-authored `exhaustion/current.json`, no schema the worker must learn,
   no gate source the worker must read.

Runtime files (receipts, exhaustion evidence, ledgers) all still exist —
machine-authored, with provenance marking them so.

## Non-goals, per the freeze and the measurements

No narration suppressor (1%). No new controllers. No changes to acceptance,
verification commands, memory, evidence handling, or authority semantics. No
prompt-shrinking for its own sake.

## The decisive test (fixed by operator, apparatus already frozen)

**Native vs Current Gravito vs Lean Gravito**, same runnable environment, same
preflight prover, same classifier. Judged simultaneously on:

- **Economics:** cost / uncached tokens / turns materially toward native
  (current: 2.44× / 2.12× / 1.6×).
- **TOM compliance:** `final_report` → ~1/arm; visible control round-trips → ~0;
  `gate_mechanism_diagnosis` → 0; `capability_search` ≤ native + 1;
  acceptance intact (currently 47/47).

Cost improving while Claude still administers Gravito is not the TOM.
Interactions collapsing while cost holds means a deeper tax — and that result
is informative, not a failure of the test.

## Implementation sequencing

One packet per row, L1 → L4, each with its own regression demonstration
(mutation-tested: the old behaviour shown firing on the old code, absent on the
new). The `lean` treatment enters the harness as a config administered from the
lean tree — the same variant mechanism EXP-0007 already uses — so Current and
Lean are administered by identical machinery.
