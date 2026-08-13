#!/usr/bin/env bash
# Deterministic NO-SPEND fake worker: emits a stream-json shaped transcript
# with a provider-native result event, so metering/telemetry paths qualify
# without model spend. Args: <outfile> [--no-result to simulate abort]
set -u
OUT="$1"; NORESULT="${2:-}"
printf '{"type":"system","subtype":"init"}\n' > "$OUT"
printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Edit"}]}}\n' >> "$OUT"
if [ "$NORESULT" != "--no-result" ]; then
  printf '{"type":"result","usage":{"input_tokens":10,"output_tokens":500,"cache_creation_input_tokens":100,"cache_read_input_tokens":2000},"total_cost_usd":0.001,"num_turns":2}\n' >> "$OUT"
fi
