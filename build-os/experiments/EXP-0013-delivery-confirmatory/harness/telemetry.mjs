#!/usr/bin/env node
// EXP-0013 telemetry: parse one worker stream-json transcript into provider-
// native economics with TYPED failure semantics. Missing telemetry is
// NOT_METERED — never inferred, never defaulted. Every anomaly is a named
// reason; an anomalous cell is infrastructure-invalid, not silently kept.
//
//   NOT_METERED_NO_RESULT_EVENT   — stream ended without a result event
//   MALFORMED_RESULT_EVENT        — result event present but unparseable/missing usage
//   DUPLICATE_RESULT_EVENT        — more than one result event in one stream
//   STALE_STREAM_SESSION_MISMATCH — init session_id differs from the launched one
//   MODEL_ID_MISSING              — provider-native model id absent from stream
//   MODEL_ID_NOT_ALLOWED          — provider-native id outside the preregistered set

export function parseStream(text, { expectedSessionId = null, allowedModelIds = null } = {}) {
  const reasons = [];
  const events = [];
  let malformedLines = 0;
  for (const raw of String(text).split("\n").filter(Boolean)) {
    try { events.push(JSON.parse(raw)); } catch { malformedLines++; }
  }
  const init = events.find((e) => e.type === "system" && e.subtype === "init");
  if (expectedSessionId && init?.session_id && init.session_id !== expectedSessionId)
    reasons.push("STALE_STREAM_SESSION_MISMATCH");

  const results = events.filter((e) => e.type === "result");
  if (results.length === 0) reasons.push("NOT_METERED_NO_RESULT_EVENT");
  if (results.length > 1) reasons.push("DUPLICATE_RESULT_EVENT");

  // Provider-native model id: system init `model`, else result modelUsage keys.
  const modelIds = new Set();
  if (init?.model) modelIds.add(String(init.model));
  for (const r of results) for (const k of Object.keys(r.modelUsage ?? {})) modelIds.add(k);
  if (allowedModelIds) {
    // Entries starting with "^" are anchored regex patterns (the exact dated
    // provider id is knowable only from the first result event — the set is
    // preregistered as patterns, membership checked after call 1, and any
    // mismatch aborts the study before a second call is made).
    const allowed = (id) => allowedModelIds.some((a) => (a.startsWith("^") ? new RegExp(a).test(id) : a === id));
    if (modelIds.size === 0) reasons.push("MODEL_ID_MISSING");
    for (const id of modelIds) if (!allowed(id)) reasons.push(`MODEL_ID_NOT_ALLOWED:${id}`);
  }

  let economics = null;
  if (results.length === 1) {
    const u = results[0].usage;
    if (!u || u.output_tokens == null || u.input_tokens == null) reasons.push("MALFORMED_RESULT_EVENT");
    else economics = {
      uncached_input_tokens: u.input_tokens,
      output_tokens: u.output_tokens,
      cache_read_input_tokens: u.cache_read_input_tokens ?? null,
      cache_creation_input_tokens: u.cache_creation_input_tokens ?? null,
      total_cost_usd: results[0].total_cost_usd ?? null,
      num_turns: results[0].num_turns ?? null,
      primary_metric_tokens: u.output_tokens + u.input_tokens, // output + UNCACHED input (provider-native fields)
    };
  }
  return {
    metered: reasons.length === 0 && economics !== null,
    economics, reasons, malformed_lines: malformedLines,
    provider_model_ids: [...modelIds],
    tool_calls: events.flatMap((e) => (e?.message?.content || []).filter((c) => c?.type === "tool_use")).length,
  };
}
