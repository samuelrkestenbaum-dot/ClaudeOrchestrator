# EXP-0013 — RELEASE-CANDIDATE AUDIT (publication-candidate + synthetic escrow rehearsal)

## VERDICT: READY_FOR_SCOPED_PUBLICATION_AUTHORIZATION

READY means exactly one thing: the audited commit range may be pushed. It
does not authorize or imply escrow execution, real authorization-object
creation, provider calls, spend, measured execution, analysis, or Stage B.

The audit found one LAUNCH-FATAL defect and two lesser defects in the
previous candidate; all fixed under disclosed AMENDMENT v5 + two justified
fix commits. The release range grew accordingly and is re-verified end to
end, including from a fresh clone with no access to this container's
working state.

## 1. Release manifest (reconstructed from the repository)

Remote `origin/claude/project-handoff-merge-ramhds` = `607c0bd` (fetched
read-only, verified). Local chain: linear, no merges, PURE fast-forward
(merge-base = remote tip), 0 behind. Ordered range (oldest first):
`dfb70a2` fixture leg → `77d514d` freeze v1 → `59f9906` readiness harness →
`29ae7b7` readiness verdict + evidence → `f5503e6` AMENDMENT v3 →
`562fff4` pre-spend audit verdict → `e30fc15` AMENDMENT v4 (incident
closure) → `123ab36` incident-closure verdict → `132e64a` AMENDMENT v5
(release-audit corrections) → 2 disclosed fix commits (self-matching
scanner pattern; scan-vs-own-history exclusion) → final tip carrying this
document. 64+ additions, 2 in-scope modifications outside EXP-0013 paths
(planner seam, registry entry), no gitlinks/submodules/renames/mode
changes/large binaries (largest file: the 158KB corpus baseline), no
tags/LFS involved (the push names one branch only; the local v0.1.0 tag is
NOT part of it). Tree and index clean; nothing unstaged is required.

## 2. Secret audit — findings and classification

Scanned: full range patch history + final tree, patterns + semantic reads.
- API keys/tokens/credentials: NONE (self-escaped scanner; its own
  historical pattern text excluded and disclosed).
- REAL sealed salts (read from the live sealed store, values never
  printed): ABSENT from all range history.
- Sealed mapping plaintext / escrow ciphertext / publish-authorization /
  spend ledgers / env snapshots / core dumps / logs: none committed. The
  real publish-authorization file is gitignored, local, and STALE
  (tip-bound to the previous push — it cannot authorize this range).
- **FIXED (was committed): container temp paths + session-derived paths**
  inside 5 tsc messages of the corpus baseline and in rehearsal digest
  cwds — normalized to `<TREE>` / `<ISO>` (v5). Release suite now enforces
  their absence.
- Intentional, retained: the incident record quotes its own local log path
  and session id as forensic evidence.
- Proprietary task data: only the authorized pinned empathiq compiler
  output; no raw model transcripts beyond declared fixtures.

## 3. Reproducibility from committed state (fresh clone, isolated)

`git clone` of committed state only (gitignored/untracked absent —
verified): Freeze v1 (10 artifacts) and v5 (59 artifacts + 38 install-
closure tree files + inventories + modes) verify; fixture 22/22, readiness
33/33, red-team 27/27, capability 20/20; launch-minus-one rehearsal runs to
the NO_PROVIDER_CALL barrier with the PATH tripwire untripped; all ten
request digests reproduce with IDENTICAL stdin/cell/model/cwd digests —
only argv_sha256 differs, via the per-cell `--session-id` UUID, a declared
nonce (the semantic request identity is the stdin digest, which the
authorization allowlists bind). Registry probe sees pinned 2.1.231 and
refuses drift. Declared-external dependencies only: the pinned
empathiq-website source + node_modules, node v22.22.2, the sealed stores
(outside repo by design), tsc 5.9.3. One-byte and added-file tampers are
typed refusals on a disposable copy (red-team R1, re-run in clone).

## 4. Freeze v5 semantic coverage

v4 already covered corpus/prompts/planner/UCDL/model-config/controller/
call-site/registry/ledgers/commitments/stopping rules/analysis/views/
suites. The audit found the WORKER-ENVIRONMENT INSTALL CLOSURE outside it:
gravito init installs .claude agents/commands/hooks + allowlist +
settings-merge, goal-check/route-task/mode-select, templates seeds, and
the maintenance layer into the measured worktree — bytes that shape worker
sessions. v5 freezes install-project.sh, init-build-os.sh and the five
trees recursively (per-file sha + mode; unexpected/missing tree files are
typed refusals). No remaining dynamic-load path escapes the manifest: the
harness has no dynamic import(), no env-var module loading, and every
executable it runs is registry-listed and frozen.

## 5. Incident-closure audit (independent re-check)

Local telemetry re-read: 2 input / 44,779 cache-creation / 128 output
tokens, model `claude-sonnet-5`, timestamps as recorded; cost labeled
UNKNOWN_NONZERO with the ~$0.27 figure explicitly a list-price estimate,
not evidence. No reply byte exists outside the incident record (grep over
the full range). Session/env inheritance scrubbed at both the registry and
the call site. Exactly one provider-call-site module; zero harness
importers; arbitrary CLI positional argv (including the incident's own
`config get`) refuses BEFORE spawn; synthetic and real authorization paths
are mutually uncrossable; measured-call counter: no spend ledger exists
anywhere in the repository — zero measured calls ever.

## 6. Synthetic escrow rehearsal (synthetic mapping + passphrase only)

The exact operator command was exercised end-to-end in a disposable
worktree via its pipe adapter (the interactive path uses raw-mode TTY
reads — no echo, no readline control sequences; the v5 fix replaced the
broken readline prompt). Proven: ciphertext-only artifact (no salts, no
orders, no labels); passphrase never in output/argv/env/process listing
(stdin-only by construction); silent byte-identical decryptability proof;
wrong passphrase, corrupted GCM tag, and weak passphrase are typed
refusals; RECOVERY AFTER SOURCE LOSS — with the synthetic sealed directory
deleted, both primary and rerun mappings restore from ciphertext alone;
view generation has no code path touching the escrow artifact. Honest
limitation: on modern journaling/copy-on-write filesystems, deleting
plaintext temp files does not guarantee physical erasure; the CLI keeps
plaintext only in 0600 tmp files for the seconds of the round-trip and in
process memory, which is the practical best available here.

## 7. Owner handoff quality

OWNER-GUIDE.md (new, plain language, no conversation context assumed)
covers: why publication precedes everything; exactly what is and is not
pushed; that pushing runs nothing and spends nothing; post-push
verification; how to run escrow locally with echo disabled and why the
passphrase must never be pasted into Claude/chat; what the passphrase
protects and the consequence of losing it (precommitment proof only — the
study stays analyzable); retention duty; how to verify escrow success
without revealing the mapping; that committing the ciphertext needs its
own scoped authorization; the exact later spend decision (10 planned / 16
max calls, $100 ceiling, serial, 1200s per call, all stop rules); and how
to abort safely at every stage.

## 8. Publication gate dry run (synthetic, disposable, nothing left active)

Old remote tip validated = `607c0bd`. Publish checker: REFUSES with no
authorization; ACCEPTS a synthetic tip-bound authorization in a disposable
worktree (never the real tree — verified the real gitignored authorization
is stale and untouched). Fast-forward proven; one branch on one remote; no
tags/submodules/LFS. If the remote moves before authorization: the
old-tip precondition fails, the push is refused, and the range is
re-audited against the true remote state — never forced.

## 9. Full release-candidate battery (exact counts)

Active tree: fixture 22/22 · readiness 33/33 · red-team 27/27 ·
capability 20/20 · **release 22/22 (new)** · planner 25/25 ·
control_primitives 47/47 · neurocosmology_invariant 21/21 ·
context_delivery 12/12 · goal_enforcement 34/34 · lifecycle 35/35 ·
doc_drift 10/10 · cross_repo_isolation 14/14 · authority_envelope 126/126
= **448 passed, 0 failed**. Fresh clone: freeze v1 + v5 verified,
fixture 22 + readiness 33 + red-team 27 + capability 20 = 102/102, plus
the barrier rehearsal. Sealed EXP-0004/5/9/10/11 byte-identical; v1
verifies live; v2/v3/v4 manifests preserved as history inside v5.

## A. Scoped push authorization template (the only action READY covers)

> Explicit owner authorization: push exactly the audited local commit
> range 607c0bd..<TIP> (<N> commits, new tip <TIP>, repository
> samuelrkestenbaum-dot/ClaudeOrchestrator, branch
> claude/project-handoff-merge-ramhds), fast-forward only, exactly one
> push, no tags; record the scoped authorization in the publish-check
> schema; verify the expected old remote tip 607c0bd immediately before
> pushing and refuse if it differs.

(<TIP>/<N> are read from the local chain at authorization time; the
release report message quotes the exact current values.)

## B. Post-push verification checklist

1. `git fetch origin claude/project-handoff-merge-ramhds` (independent).
2. Remote tip equals <TIP>; `git rev-list --count` divergence = 0/0.
3. Working tree and index clean.
4. In a fresh checkout of the pushed tip: `freeze.mjs verify` and
   `freeze5.mjs verify` both green against remote bytes.
5. Confirm no tag was pushed and no other branch/remote changed.

## C. Owner escrow handoff (LOCAL, after publication — no secret in chat, ever)

Per OWNER-GUIDE.md §4: run `node build-os/experiments/
EXP-0013-delivery-confirmatory/harness/escrow-cli.mjs create` on this
machine; type the passphrase twice (echo disabled; never in chat, files,
or history); record the printed ciphertext digest; store the passphrase
outside this container until reveal + audit close. **STOP before
committing corpus/mapping-escrow.json — that commit requires its own
scoped authorization quoting the digest.**

## D. Stage-A spend authorization template — REFERENCE ONLY, NOT AUTHORIZED

> [NOT AUTHORIZED — reproduced for reference] Explicit owner spend
> authorization for EXP-0013 Stage A: PREREQUISITES — publication verified
> per B; mapping escrow completed per C with custody confirmed. Run the
> measured study exactly as frozen under FREEZE-MANIFEST-v5.json (digest
> quoted at authorization time from the pushed bytes), primary arm-order
> commitment 3f3725a5…e2e1df9 and rerun-order commitment 94cb25b3…: model
> claude-opus-5 (allowed ids claude-opus-5 / claude-opus-5-YYYYMMDD;
> id gate aborts after the first telemetry-bearing call on mismatch, call
> 1 charged), 10 planned calls (2 neutral seeds + 8 measured), hard max 16
> calls via the ledger counter, SERIAL topology, 1200s per-cell ceiling,
> hard $100 ceiling via reserve-at-$6 accounting where unknown cost is
> never zero. Stop immediately on: unintended-empty delivery (stage void),
> second seed failure in a sequence, second infrastructure-invalid cell,
> rerun-budget exhaustion, model-id mismatch, ledger/freeze/commitment
> verification failure, or ceiling projection breach. No interim outcome
> reads; analysis via frozen analysis.mjs only after completion; reveal is
> a separate one-way step. Covers no push, no PR, no merge, no deploy, no
> production change, no Stage B.
