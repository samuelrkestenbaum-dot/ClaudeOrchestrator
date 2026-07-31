---
description: Close the active packet — write a receipt and update Build OS memory via the archivist.
argument-hint: "[optional packet id]"
---

Close the active build packet by recording it durably.

**Substantive lane only.** Receipts exist for `substantive` packets. If the work
was `read-only`, `diagnosis`, or `tiny`, there is no packet to close and no
receipt to write — say so and stop rather than manufacturing one.

Use the **archivist** subagent to:

1. Gather the packet facts: id, title, what changed, the qa proof block (exact
   counts), the reviewer verdict, the commits (`git show --stat`), and the branch
   base.
2. Write `build-os/receipts/<id>.md` with scope, commits, QA proof,
   reviewer verdict + Codex note, residue, and any open merge/deploy/push
   boundaries awaiting explicit go.
3. **Record the packet** with `build-os/metrics/record-packet.sh` — one row per
   packet, diff figures taken from `git show --numstat`, every unmeasured cell
   left as `-` (never 0), and a note that says which figures are git-verifiable.
   If the row names more than one commit, the receipt must also carry the
   disjoint file-ownership manifest (one commit per packet where the merge
   allows it; where it does not, attribution stays recoverable by path).
4. **Verify the close** with `build-os/metrics/check-adoption.sh`, which
   reconciles receipts against the store and must exit 0. A receipt with no row
   — or a row of dashes appended to silence it — fails. Do not clear a failure
   by widening `build-os/metrics/adoption_boundaries.tsv`; that boundary is
   pinned by `tests/metrics_adoption_tests.sh`.
5. Update `build-os/memory/current_state.md`, `build-os/memory/residue.md`, and
   `build-os/packets/active_packet.md` (mark the packet closed; stage the next if
   known).

The archivist only touches files under `build-os/`. It does not push, merge, or
deploy. Report the receipt path, the metrics row appended, the
`check-adoption.sh` result, and the memory files updated.

Packet (optional): $ARGUMENTS
