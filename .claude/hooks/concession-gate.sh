#!/usr/bin/env bash
# STOP-HOOK: the enforcement surface for capability exhaustion.
#
# This is the piece that was missing. The doctrine existed; nothing sat between
# a worker's `blocked` conclusion and the operator. A Stop hook CAN refuse to
# let the turn end (exit 2 feeds stderr back to the model), which makes it the
# only place a stopping rule can actually be load-bearing.
#
# It reads the transcript's final assistant message, and if that message
# concedes without recorded exhaustion evidence, it BLOCKS the stop and tells
# the worker to run the cross-surface enumeration first.
set -uo pipefail
ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
GATE="$ROOT/build-os/motion/gate-stop.mjs"
[ -f "$GATE" ] || exit 0
command -v node >/dev/null 2>&1 || exit 0
# stdin carries the Stop event JSON, including transcript_path.
# stderr is NOT suppressed: on a refusal it carries the entire recovery
# instruction back to the model. Swallowing it would refuse the stop without
# telling the worker why or what to do — a capability the worker cannot
# discover at the moment of refusal is functionally absent.
node "$GATE"
