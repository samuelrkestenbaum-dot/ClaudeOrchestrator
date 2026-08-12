# Non-blocking experiment isolation — implementation-ready design (writing-only)

*Goal: future experiments must never block Gravito product development on
the same machine. Cross-references: build-os/experiments/EXP-0012-parallel-
infra/ (worker trees, DAG scheduler, calibration gate — built, unvalidated)
and docs/R0-PROGRAM-PLAN.md PKT-R0-1 (project namespaces — planned). This
document ACHIEVES NOTHING by existing; §9 classifies current state and §8
lists what must be executed. Environment fact stated honestly: the current
program runs experiments in a reclaimable cloud container, where THIS
serial-monopoly problem lives today; the Mac hosts the Core worktree (#40).*

## 1. Two isolation grades

- **Evidence isolation** (correctness / token / acceptance studies):
  requires only STATE separation — no shared trees, stores, caches, locks,
  env, or credentials between experiment and product work. Token counts and
  acceptance verdicts are computed by the provider and the adjudicator from
  content; a busy CPU does not change them. Ordinary work MAY coexist.
- **Performance isolation** (elapsed/latency/throughput claims): requires
  RESOURCE separation too — CPU, disk I/O, thermal headroom, provider
  quota, network. Ordinary work on the same host contends for exactly the
  measured quantity, so coexistence silently biases the clock. Ordinary
  work may NOT coexist unless the contention guard proves the envelope.
  This is why EXP-0011 rightly monopolized the machine once speed became a
  registered dimension — and why that must never be the default again.

## 2. Boundary inventory (what must be separated, per grade)

| Boundary | Evidence grade | Performance grade |
|---|---|---|
| filesystem/worktrees | per-experiment trees (EXP-0012 provisionTree) | same + separate volume or host |
| Gravito memory/receipts/skills/task state | R0 namespaces; experiments NEVER share product namespaces | same |
| caches (build, node_modules, model context) | read-only sharing allowed if content-addressed | no shared writable caches; provider cache asymmetry recorded |
| env/process tree | scrubbedEnv (exists); own process group; no inherited fds | same + no co-resident heavy processes |
| CPU/memory | none required | reserved cores/quota (cgroup/taskpolicy) or separate host; frequency/thermal logged |
| disk I/O | none required | separate device or idle-disk requirement |
| ports/network | unique ports; no shared proxies mutating state | same + latency baseline recorded |
| provider quota/rate limits, model accounts | shared account acceptable; request tagging per lane | dedicated account/key or reserved quota window |
| credentials | experiment-scoped, least-privilege | same |
| clocks | one host clock, monotonic durations | same + NTP state recorded |
| telemetry | per-lane streams, tamper-evident (hash-chained, per validation kit) | same |

## 3. Practical architecture (Mac + optional separate host)

Compared: (a) process-level limits (nice/taskpolicy/cgroup) — smallest,
weakest; no thermal/quota isolation; (b) containers/VMs — state isolation
good, but NOT assumed installed, and container isolation alone does NOT
prove performance isolation (shared kernel, shared thermal envelope,
shared provider quota); (c) physically separate runner — strongest, costs
hardware/ops. **Recommendation (smallest reliable):** two-lane design —
- **Lane E (evidence)** runs ON the dev machine: EXP-0012 worker trees +
  R0 namespaces + scrubbed env + per-lane provider tagging. Product work
  continues normally.
- **Lane P (performance)** runs on a SEPARATE RUNNER (a second machine, or
  this cloud container class reserved exclusively) OR in a reserved window
  on the dev machine with the admission controller enforcing exclusivity.
  Never "container on the busy laptop".

## 4. Contention guard and admission controller

Extends EXP-0012's live-lock refusal into a controller: (i) PREFLIGHT
BASELINE — idle CPU %, load, free mem, disk latency probe, provider
round-trip sample recorded before admission; (ii) ADMISSION — a manifest of
allowed concurrent workloads per grade (Lane E: product work allowed;
Lane P: none but the study); refusal with named reason otherwise; (iii)
RUNTIME ANOMALY DETECTION — load/thermal/latency sampled per arm; breach ⇒
the affected cells are AUTOMATICALLY INVALIDATED AND MARKED (never
silently re-run — re-runs happen only under the study's own preregistered
rules, and the invalidation event is part of the record); (iv) RECEIPTS —
baseline, admission decision, samples, and invalidations hash-chained per
the validation kit's telemetry rules.

## 5. Calibration protocol (before any parallel timing claim)

EXP-0012 calibrate.mjs is the seed; extend to: serial control vs isolated
concurrent execution at the candidate width ON THE CANDIDATE LANE, with
recorded CPU frequency/thermal state (powermetrics/sysfs where available),
disk latency probes interleaved, provider latency distribution per request,
and quota-interference check (burst at width W must not trip rate limits —
a single 429 fails the calibration). Pass rule stays the precommitted one
(median deltas + rank-sum); calibration receipts stored with the study.

## 6. Scheduling policy

Product work has PRIORITY. Long performance studies book a reserved window
or the separate runner, declared in advance with an owner-visible end
time. Correctness studies may run alongside product work only after Lane E
qualification passes once on this host. Pause/resume: experiments
checkpoint ONLY at cell boundaries (an arm is never paused mid-flight —
partial arms are invalidated, preserved, and re-run per their study's
rules), so pausing to yield to product work cannot bias a registered cell;
the pause itself is a receipt.

## 7. Operator experience

One command (`gravito lab status` — R0 status surface sibling): SAFE-FOR-
PRODUCT-WORK: yes/no + WHY (lane, grade, reservation window) · experiment
id/grade/progress · resources reserved · contamination status (guard
verdicts, invalidation count) · exact stop command and what stopping costs
(which cells invalidate). Text output; no UI.

## 8. Implementation packets (after EXP-0011; coordinated with R0 — no duplication)

- **PKT-ISO-1 (with PKT-R0-1):** lane-aware namespaces — experiment
  namespaces disjoint from product namespaces by construction. Evidence:
  leakage tests from R0 extended with one experiment fixture.
- **PKT-ISO-2:** admission controller + preflight baseline + receipts
  (wraps EXP-0012's guard). Evidence: refusal + admission transcripts on
  disposable fixtures; anomaly injection invalidates and marks a cell.
- **PKT-ISO-3:** Lane-E qualification on this host (evidence-grade studies
  alongside scripted product-work load; token/acceptance results must be
  bit-identical to a quiet-host control run). Evidence: the comparison.
- **PKT-ISO-4:** Lane-P provisioning decision (owner: separate runner vs
  reserved windows) + extended calibration per §5. Evidence: calibration
  receipts pass at the chosen width.
- **PKT-ISO-5:** `gravito lab status` surface. Evidence: scripted session
  matches receipts.

## 9. Current state, classified honestly — and the migration rule

Today: NOTHING above is achieved by this document. Built-but-unvalidated:
EXP-0012 trees/DAG/calibration (code only). Planned: R0 namespaces.
Practiced informally: scrubbed env, per-experiment trees, the live-lock
refusal (fired once, real). Absent: admission controller, baselines,
anomaly detection, lane qualification, Lane-P provisioning, lab status.
Everything in §8 requires execution after lock release.

**Migration rule (owner-directed):** EXP-0011 is the FINAL serial study
permitted to monopolize the development environment. Any future exception
requires explicit owner approval naming the decision value that justifies
the monopoly.
