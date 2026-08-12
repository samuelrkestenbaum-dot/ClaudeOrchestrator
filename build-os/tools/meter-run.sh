#!/usr/bin/env bash
# R0.1 §2 — the ONE metering writer. Reads a session stream's result event
# (provider-native categories), appends ONE ledger line under an exclusive
# flock, and dedupes by stream name so a retry/recovery re-meter can never
# double count. Values the stream does not carry are written null-as-absent,
# never inferred. Nested workers are covered by construction: Claude Code's
# session result usage aggregates the whole session including subagents, and
# each ledger entry corresponds to exactly one top-level session stream.
#   meter-run.sh <stream.jsonl> <repo> <elapsed-seconds>
set -euo pipefail
S="$1"; D="$2"; SECS="${3:-0}"
LEDGER="$D/build-os/memory/spend-ledger.jsonl"
mkdir -p "$(dirname "$LEDGER")"
NAME="$(basename "$S")"
exec 9>>"$LEDGER.lock"
flock 9
grep -qF "\"stream\": \"$NAME\"" "$LEDGER" 2>/dev/null && { echo "meter: $NAME already in ledger — skipped (no double count)"; exit 0; }
python3 - "$S" "$NAME" "$SECS" >> "$LEDGER" <<'PY'
import json, sys
stream, name, secs = sys.argv[1], sys.argv[2], int(float(sys.argv[3]))
tok = usd = None
try:
    for line in open(stream):
        try: e = json.loads(line)
        except Exception: continue
        if e.get("type") == "result":
            u = e.get("usage") or {}
            tok = sum((u.get(k) or 0) for k in ("input_tokens","output_tokens","cache_creation_input_tokens","cache_read_input_tokens"))
            usd = e.get("total_cost_usd")
            cats = {k: u.get(k) for k in ("input_tokens","output_tokens","cache_creation_input_tokens","cache_read_input_tokens")}
except FileNotFoundError:
    cats = {}
rec = {"tokens": tok if tok is not None else 0,
       "usd": round(usd, 4) if usd is not None else 0,
       "minutes": max(1, round(secs/60)) if secs else 0,
       "stream": name, "provenance": "provider-result-event" if tok is not None else "NOT-METERED-stream-had-no-result",
       "categories": cats if tok is not None else "NOT METERED"}
print(json.dumps(rec))
PY
echo "meter: appended $NAME"
