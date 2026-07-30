# Receipts

<!-- GRAVITO:TEMPLATE (seeded by the Build OS installer; yours to edit,
     never overwritten once it exists) -->

Durable, append-only history of closed packets. The **archivist** writes one file
per packet here, named by packet id: `build-os/receipts/<id>.md` (ids look like
`P-NNN`, where `NNN` is the packet number). Receipts are never rewritten —
closing a packet adds a new file; a correction is a new receipt that references
the one it corrects.

**Starting value: no receipts yet.** This directory holds only this README until
the first packet closes. That is the honest state of a new repo, and an empty
receipts directory is a fact, not a gap to fill.

A receipt records what was *proved*, not what was intended. Numbers come from a
command that was actually run; anything not run is written as `N/A` with a
reason, never as an unqualified pass.

## Receipt template

Copy this into `build-os/receipts/<id>.md` when closing a packet:

```markdown
# Receipt — <id>: <title>

- **Date:** <YYYY-MM-DD>
- **Branch base (merge-base):** <hash / ref>

## Scope
- **In:** <what this packet covered>
- **Out (explicit):** <what was deliberately excluded>

## Commits
- <hash> <subject>
- <hash> <subject>

## QA proof
- Suite:        <cmd> → N passed, M failed, K skipped
- Regression:   <cmd/scope> → result
- Commit-1 iso: <how verified> → green/red
- Safety grep:  <hits or "none found">
- UI smoke:     pass / fail / N/A

## Review
- Verdict: pass / fix-then-pass (as fixed) / fail
- Second-eyes: <summary, or "not available">
- Product trajectory check: <note>

## Residue
- Deferred / follow-up packets: <…>
- Known risks: <…>

## Open boundaries (awaiting explicit go)
- <merge / deploy / push / secret left pending, or "none">
```
