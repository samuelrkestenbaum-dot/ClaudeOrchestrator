# Residue

> What was deferred, left behind, or noted as risk — the stuff that didn't fit in
> the last packet but must not be forgotten. The orchestrator reads this to avoid
> dropping threads; the archivist appends/clears it on close.

## Deferred (follow-up packets)

- **Enable + record deferred connectors** → authorize Stripe and Cloudflare
  Developer Platform, and toggle on Google Calendar / Google Drive / Microsoft 365
  in-chat; then add them to the *Installed connectors* table. (P-001 left these
  out per user instruction.)
- **Session-MCP router rows** → consider first-class *task-type* rows for GitHub
  and Claude Code Remote (currently listed only in the Installed connectors table).
- **current_state build/test facts** → fill in if/when a real test harness is added.

## Known risks / debt

- The *Installed plugins / connectors* tables are a point-in-time snapshot
  (2026-07). They will drift as the environment changes — re-verify via
  `ListConnectors` / `ListPlugins` / `ListSkills` rather than trusting the list.
- Plugin capability descriptions in the router are inferred from plugin names
  (`ListPlugins` returned no per-plugin descriptions); refine if the plugins
  expose richer metadata.

## Open boundaries (awaiting explicit go)

- No merge to base, no PR opened. Feature-branch push proceeds under the session's
  branch delivery contract. No secrets touched.

---
_Append-only working notes._
