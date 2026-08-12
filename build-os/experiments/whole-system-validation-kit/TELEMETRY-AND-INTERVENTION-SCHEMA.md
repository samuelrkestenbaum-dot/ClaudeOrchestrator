# TELEMETRY & INTERVENTION SCHEMA (specification only — logger built at
# qualification, per PACKET §12 / kit checklist; this file implements nothing)

Event stream: append-only JSONL per (pair, arm); every event carries
{ts_utc, monotonic_ms, pair_id, arm, capsule_sha, session_id, worker_id,
 event_type, payload, source, schema_version}. Provenance: source ∈
{provider_api, harness, operator_logger, acceptance}; events are written by
instruments, never by the builder model. Clock rules: one host clock,
monotonic for durations, UTC for timestamps; cross-host events forbidden.
Missing data: recorded as explicit null events with reason — never imputed,
never silently absent; a cell missing primary telemetry is ITT-charged and
flagged, identically per arm.

Event types (payload fields)
- session_usage: provider-native input_tokens, output_tokens,
  cache_read_input_tokens, cache_creation_input_tokens, model_id, request_count
- timing: wall segment start/stop + classification (model_active, human_active,
  queue_idle) → active time per DESIGN rev 2 definitions
- concurrency: width in effect, worker ids live
- attempt: retry|failed_hypothesis|rework (frozen definitions, DESIGN rev 2)
- failure: timeout|crash|malformed|capability_gap (ITT) or environmental
  {reclaim|provider_outage|infra} with evidence ref (PACKET §8)
- human_action: FAQ_answer(charge=0) | intervention(minutes, transcript_ref)
  | rescue(class from frozen list → task void) | emergency_stop
- context_bytes: supplied, expanded (per capsule pointers vs actually loaded)
- verification: acceptance-script runs + verdicts; regression events with
  attribution evidence
- outcome: accepted|rejected + rubric scores + assessor arm-guess record
- overhead (arm B): setup vs ongoing {orchestration, verification_infra,
  recovery, state_maintenance}, itemized per DESIGN rev 2 / PACKET §7
Symmetry: identical schema both arms; arm-A analogues of overhead legal and
recorded (its own notes/plans upkeep) so NET/GROSS comparisons are honest.

Logger interface (future): log(event) → fsync'd JSONL; meter_start/stop(kind);
verify() replays a stream against schema + clock monotonicity and reports
gaps — verify() green is part of qualification, not of design.

## Rev 4 additions (red-team)
- session_usage adds: request_latency_ms stats; model_id per request.
- New event: infrastructure_usage — model calls by Gravito components,
  same native categories, charge_class setup|ongoing (DESIGN rev 4 §T2).
- Tamper-evidence: JSONL batches hash-chained (each batch records prior
  batch sha256); raw provider usage payloads retained; close-time manifest
  lists per-file sha256 (DESIGN rev 4 §T6).
- Time accounting emits both active-wall and aggregate-compute segments
  (DESIGN rev 4 §T1).
