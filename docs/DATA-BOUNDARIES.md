# Gravito data boundaries (R0) — what lives where, what leaves, how to remove it

**What leaves the machine:** model provider API calls only (prompts, file
contents the worker reads, tool results — to the configured Claude endpoint).
Nothing else is transmitted: no telemetry service, no analytics, no phoning
home. Telemetry default: OFF (there is no telemetry sender to turn on).

**What is stored locally, per repository (namespace-stamped):**
`.claude/` (engine: agents/commands/hooks — code, no user data) ·
`build-os/memory/` (project memory, task logs, spend-ledger.jsonl,
.project-identity stamp) · `build-os/receipts/` (install manifests, run
streams run-*.jsonl — these CONTAIN worker transcripts including file
contents the worker read) · `build-os/packets/` (task state) ·
`gravito.goal` (the owner contract). User scope: `~/.claude`, `~/build-os`
(engine + user-level memory; namespace guard keeps project stores from
crossing repos — proven by tests/cross_repo_isolation_tests.sh).

**Secrets:** Gravito never reads or stores secrets by design; preflight
refuses repos with obvious secret files at root; the publish gate blocks
pushes without explicit authorization; run streams can still capture any
secret a WORKER reads — do not point workers at secret material, and purge
streams that captured any.

**Retention:** everything above persists until removed; nothing expires
silently. Leases and goals expire by contract ([starts, expires)) but their
FILES remain as records.

**Removal semantics:** `gravito uninstall DIR --force` removes engine files,
KEEPS user data. `gravito purge DIR --force` removes ALL Gravito state from
the repo (.claude/, build-os/, gravito.goal) and never touches product
files — proven in tests/lifecycle_tests.sh. User scope removal: delete
~/build-os and Gravito entries in ~/.claude (documented, not scripted in R0).

**OFF by default:** experimental geometry/math, unvalidated intelligence
features, and all performance claims — none ship active in R0.
