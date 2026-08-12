# Gravito data boundaries (R1) — what lives where, what leaves, how to remove it

**What leaves the machine:** model provider API calls only (prompts, file
contents the worker reads, tool results — to the configured Claude endpoint).
Nothing else is transmitted: no telemetry service, no analytics, no phoning
home. Telemetry default: OFF (there is no telemetry sender to turn on).

**What is stored locally, per repository (namespace-stamped):**
`.claude/` (engine: agents/commands/hooks — code, no user data) ·
`build-os/memory/` (project memory, task logs, spend-ledger.jsonl,
.project-identity stamp) · `build-os/receipts/` (install manifests, run
streams run-*.jsonl — these CONTAIN worker transcripts including file
contents the worker read; refusals.log — goal-gate refusal receipts;
residue.log — hygiene-sweep receipts) · `build-os/residue/<ts>/`
(incidental tool droppings a worker left at the repo root, moved here
reversibly by the post-run sweep — product files are never swept) ·
`build-os/packets/` (task state) ·
`gravito.goal` (the owner contract). User scope: `~/.claude`, `~/build-os`
(engine + user-level memory; namespace guard keeps project stores from
crossing repos — proven by tests/cross_repo_isolation_tests.sh).

**Metering (R0.1) — what is counted and what is NOT:** `gravito run`
parses each worker stream's provider-reported usage into
`build-os/memory/spend-ledger.jsonl` (flock-serialized, deduplicated per
stream; a stream with no result event is recorded NOT-METERED, never
estimated). The goal gate halts on this committed ledger. **NOT metered,
stated explicitly:** the operator's own interactive sessions, direct
`claude` invocations outside `gravito run`, experiment harnesses, and any
MCP-side execution. Numbers for those paths do not exist and are never
inferred.

**Tool-level enforcement boundary (R1):** file mutations
(Edit/Write/NotebookEdit/Bash) and ALL `mcp__*` tools pass the fail-closed
goal gate — MCP default-closed via the narrow read-only allowlist
(`.claude/hooks/mcp-readonly-allowlist.txt`); an undeclared MCP tool is
treated as a mutation. NOT enforced, stated plainly: a bare human shell
(no hooks run); a mutating tool wrongly added to the allowlist (the list is
the trust boundary — keep it narrow); hook internal errors fail open with a
logged trace. Targets installed before R1 must run `gravito update` to gain
matcher registration; `gravito diagnose` shows wired/UNWIRED per matcher.

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
