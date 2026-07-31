# ONBOARDING — Build OS for a team that has never seen this repo

You are a competent engineer. Nothing below asks you to take anything on trust:
every claim on this page names the file or the command that proves it, and you
can run all of them offline in the next twenty minutes.

**What this is.** An orchestration layer for Claude Code. A `build-orchestrator`
subagent *routes* work to `builder` / `qa` / `reviewer` / `archivist` under a
declared **lane**, an explicit **tool budget**, **hard gates**, and per-project
**memory** on disk. It is a conductor, not a bundle of tools.

**What it is not.** It is not a measured speedup. This product has **no speed
claim you can currently check**, and its own instrument says so before it says
anything else — run `build-os/metrics/report-speed.sh` and read the first
paragraph. No A/B against raw Claude Code has been run; `build-os/metrics/COMPARISON_PROTOCOL.md`
specifies the 16-run experiment that would settle it and states plainly that it
has not been executed. If somebody sells you a multiplier for this, they are
contradicting the repo you are being sold.

What you *can* check today: bounded spend on small work (round budgets, declared
per lane, in a table an agent reads), gates that refuse with non-zero exit codes,
a receipt per closed packet, and numbers this system publishes about **its own
worst runs**.

---

## 1. The five lanes

A lane is **declared, not implied**: one line, before the first action, naming
the lane and its round budget. The lane fixes the gate-set *and* how much the
task is allowed to cost. The block below is copied **byte-identically** from
`build-os/memory/tool_router.md` — the file the orchestrator actually reads. (A
test in `tests/pilot_kit_tests.sh` fails if this copy and the router ever drift,
because a customer reading one thing while the agent reads another is the defect
class this repo pins everywhere else.)

<!-- PILOTKIT:LANES:START -->
Every task runs in exactly ONE declared lane. Announce it on one line before the
first action — `Lane: <lane> — <why> (budget: <rounds>)` — and run only that
lane's gates. An undeclared task defaults to the **cheapest** lane that can do
the job, never the most expensive.

| Lane | Required gates | Round budget |
|---|---|---|
| `read-only` | none — answer directly from evidence; no edits, no packet, no receipt | 1 round |
| `diagnosis` | none — investigate and report; do not implement, propose a packet instead | 1 round |
| `tiny` | builder-lite + ONE targeted check — no qa, no reviewer, no archivist, no packet, no receipt | 2 rounds max |
| `substantive` | builder → qa → reviewer → archivist | as needed |
| `architecture` | orchestrator routes first — classify, budget, delegate; no edits in this lane | as needed |

A **round** is one delegated agent pass (one builder run, one reviewer run) plus
its response. Rounds are the unit every budget above is counted in.

**External mutation stays hard-gated in EVERY lane**, `tiny` included: push,
merge to a base branch, deploy / publish / release, and secret handling always
need an explicit go from the user. "No gates" on the `tiny` row means *no review
chain* — it never means *no go needed to push*.
<!-- PILOTKIT:LANES:END -->

### What each lane costs you

| Lane | Agents invoked | Artifacts produced | Typical cost |
|---|---|---|---|
| `read-only` | none (or the orchestrator, answering directly) | none | one answer |
| `diagnosis` | none or `qa` | a report; a *proposed* packet if a fix is needed | one investigation |
| `tiny` | one builder-lite pass | the edit + one targeted check | ≤ 1 commit, 2 rounds |
| `substantive` | `builder → qa → reviewer → archivist` | packet, ≤ 2 commits, full proof, **receipt**, memory update, metrics row | the whole chain |
| `architecture` | `build-orchestrator` only | a route and a packet — **no edits** | one routing decision |

**De-escalation is free; escalation costs a stated reason.** Dropping from
`substantive` to `tiny` needs no announcement. Going up needs one, before the
next action: `Lane: tiny → substantive — reason: <a defect found | a hidden
dependency | a risk discovered>`. "It felt safer" is not a reason.

**Going over budget is itself a defect.** A `tiny` task that has consumed 2
rounds and is not done must stop and re-classify out loud. This repo's own
metrics store publishes the two times that failed — one `tiny` packet that spent
**6 rounds** against a 2-round budget, and a `substantive` one that spent **11
rounds** where the work was already sound at round 3. Run
`build-os/metrics/report-speed.sh` and read §2 and §3. A vendor whose instrument
prints its own worst runs is telling you something a testimonial cannot.

The full routing matrix — task type → authority → agents → tools → gate — is the
second table in `build-os/memory/tool_router.md`.

---

## 2. What the gates refuse

Two kinds of gate. Know which is which, because they fail differently.

### Hard gates — refused in every lane, enforced by instruction + your permission system

- **No push. No merge to a base branch. No deploy / publish / release. No secret
  handling.** Not without an explicit go from you, in *every* lane, `tiny`
  included. Four rows of `build-os/memory/tool_router.md` say **STOP** in their
  gate column (`grep -c 'STOP' build-os/memory/tool_router.md` → `4`), and
  `CLAUDE.md` repeats it as a hard gate.
- **Design / UI work is frontend only** — a UI packet does not reach into
  backend/runtime logic.
- **Marketing / media work happens only inside marketing/media packets** — it
  does not touch product code.
- **Parallel work is legal only with all three of:** a disjoint file-ownership
  manifest, a merge plan, and the merger owning the hot files (test suites,
  `build-os/memory/*`, version/changelog). Overlapping work goes to isolated
  worktrees plus a merge pass.

Be clear-eyed about the enforcement mechanism: these are **instructions the agent
reads plus the permission prompts your Claude Code configuration raises.** They
are not a filesystem lock, and no shell script can demonstrate an agent obeying
them. That is why [`PILOT.md`](PILOT.md) makes "zero ungated external mutations"
criterion **R2**, measured against your own git history, and why the failure
threshold there is one.

### Executable gates — they exit non-zero and you can run them right now

| Gate | Refuses | Try it |
|---|---|---|
| Unknown lane | a metrics row in a lane the router does not define | `build-os/metrics/record-packet.sh --store /tmp/x.tsv --packet p --lane turbo --evidence estimate --note "not a real lane"` |
| No attribution | a row with no evidence class or a note under 12 characters | same, with `--note "fast"` |
| Contradicts git | a row whose files/insertions/deletions disagree with the commits it names | `build-os/metrics/record-packet.sh --verify-git` |
| Unverifiable commit | a row naming a commit this repository does not contain — an *unmade* check, not a passed one | `build-os/metrics/record-packet.sh --verify-git` |
| Double counting | a second row for a `packet_id` already recorded | re-record any existing packet |
| Vacuous green | a report rendered from zero rows, and a verifier that verified zero rows | `build-os/metrics/report-speed.sh --store <header-only file>` |
| Unmeasured zero | totalling a column nobody measured to `0` instead of `-` | read the TOTAL row of any report |
| Memory damage | a maintenance test run that moved your real memory cannot report success | `./build-os/maintenance/run-tests.sh` |
| Non-conserving rotation | a rotation whose retained + archived bytes are not the original, byte for byte | `./build-os/maintenance/rotate-memory.sh` |

[`DEMO.md`](DEMO.md) Step 6 runs four of these end to end with their exit codes.

---

## 3. Receipts — what they are and why they exist

A **receipt** is one markdown file per closed packet, written by the archivist at
close, at `build-os/receipts/<id>.md`. It records: the packet's scope (**in** and
**explicitly out**), the branch base (`git merge-base`), the commits, the QA
proof with **exact counts**, the Commit-1-isolation result, the safety grep, the
reviewer's verdict, and what was deliberately deferred. The template is at the
top of `build-os/receipts/README.md`; this repository carries 24 of them.

Receipts exist because **a claim with no artifact behind it decays into a
memory**. Three concrete jobs:

1. **They make a closed packet auditable by someone who was not there.** Six
   weeks later, "did we test the uninstall boundary?" is answered by a file, not
   by recollection.
2. **They are the unit the metrics store is keyed to.** One packet, one receipt,
   one row — and the recorder refuses a second row for the same `packet_id`,
   because a double-counted row is internally consistent and therefore the
   hardest kind of wrong number to notice.
3. **They are falsifiable.** A receipt names commits; `git show --numstat` either
   agrees or does not. An overclaiming receipt is a defect this system already
   has a name for, and `record-packet.sh --verify-git` is the check that catches
   its numeric half.

**Only the `substantive` lane produces a receipt.** `read-only`, `diagnosis` and
`tiny` close with the answer or the edit — no packet, no receipt, no
qa/reviewer/archivist. If you find receipts being written for one-line fixes,
your team is over-orchestrating; that is a lane problem, not a receipt problem.

---

## 4. The sanctioned test command (and why `node --test` is unguarded)

```bash
bash tests/build_os_tests.sh              # this repo's suite; chains the maintenance cold-install proof
./build-os/maintenance/run-tests.sh       # THE sanctioned command for the maintenance layer
```

In a repo that has a `package.json`, the installer also adds
`npm run test:build-os-memory`, whose body is exactly that second invocation.
Every suite in this project ends with the same contract line —
`==== RESULT: N passed, M failed ====` — and exits non-zero when `M > 0`.

**Why the wrapper and not a bare `node --test`.** The maintenance suite exercises
a tool whose whole job is rewriting your Build OS memory. So the thing that must
be true is not "the tests pass" but "the tests cannot quietly rewrite your real
memory". The wrapper buys exactly one guarantee, stated in its own header:

> A run under `./build-os/maintenance/run-tests.sh` cannot report success after
> moving the real tree between the two shell fingerprints, provided the
> `sha256sum`/`shasum` resolved at startup is the real one and no write is
> scheduled to land after node exits.

It fingerprints your real memory before and after and preloads an in-process
tripwire. **A bare `node --test` takes no preload and no outer fingerprint** —
the wrapper's header calls that path **UNGUARDED**, in every form, rather than
"detects, late", because the in-process tripwire only runs there after something
has already imported it and its source mask has been defeated three times.

Read that header before relying on any of it: it also names the three *other*
paths the guarantee does not cover (a hostile hasher already on `PATH` at
invocation, a write scheduled to land after node exits, and hostile tampering
with the wrapper shell itself). A bounded guarantee that names its own holes is
worth more than an unbounded one that does not.

**Containment here is detection, not prevention.** Nothing stops you hand-running
`node --test`. Don't.

---

## 5. What lives in `build-os/`, and which files are yours

```
build-os/memory/       tool_router.md, current_state.md, residue.md,
                       standing_gates.md (never rotated), archive/ (rotated tail)
build-os/packets/      active_packet.md — the one packet in flight
build-os/receipts/     one receipt per closed packet
build-os/maintenance/  rotation + the real-memory tripwire + the sanctioned test
                       wrapper  (see build-os/maintenance/PORTING.md)
build-os/metrics/      the packet metrics store, recorder and report
build-os/tools/        capability-profile.sh, supervise.sh, and friends
```

The first four arrive in your repo when you install. **`build-os/metrics/` and
`build-os/tools/` do not** — today they live only in the ClaudeOrchestrator clone, and
`install-project.sh` does not vendor them. Call them by path from your clone
(§6 shows how). Check it yourself: `grep -c metrics install-project.sh` → `0`.

Three ownership classes, and every one of them is checkable on disk:

| Class | Marker | Rule |
|---|---|---|
| **Managed** | a `GRAVITO:MANAGED` header, and the path is listed in `build-os/maintenance/.gravito-managed` | **Replaced on every re-install.** Do not edit in place — your edit will be silently reverted the next time somebody upgrades. |
| **Yours** | a `GRAVITO:TEMPLATE` header | **Seeded once, when absent; never overwritten.** Edit freely. This is your router, your state, your standing gates. |
| **Yours, unmarked** | everything under `build-os/memory/archive/`, plus your receipts and packets | Written by the tools, never rewritten by an installer. |

The authoritative managed list is the file, not this table:
`build-os/maintenance/.gravito-managed` carries all 15 paths verbatim so that an
uninstall never has to be reconstructed from documentation. **Uninstall is:
delete exactly those paths.** Nothing under `build-os/memory/` is removed —
including `standing_gates.md` and the archive, which holds the only copy of
anything already rotated out. Removing the layer does **not** un-rotate memory.
That boundary is proven by an executed test, not asserted:
`tests/build_os_maintenance_tests.sh` installs the layer into a blank repo,
removes the managed list, and asserts your files are byte-identical to what they
were before — and it is chained from `tests/build_os_tests.sh` so it cannot be
forgotten. [`DEMO.md`](DEMO.md) Step 9 runs it in front of you.

### Two things to know about memory before you rely on it

- **Rotation is by RECENCY ONLY.** The newest N blocks stay live, the tail is
  moved to an append-only archive with byte-exact conservation checked before any
  write. It makes **no guarantee about what survives by meaning**. Anything that
  must never rotate belongs in `build-os/memory/standing_gates.md`, which the
  rotation tool never reads, writes or creates.
- **A dry run is the default.** `./build-os/maintenance/rotate-memory.sh` plans
  and prints; `--apply` writes. A rotated file carries a banner saying **"THIS
  FILE IS NOT THE WHOLE RECORD"** with the exact archive paths, so a shortened
  file can never be mistaken for the whole history.

---

## 6. The metrics store, and how to read it honestly

`build-os/metrics/packet_metrics.tsv` is a 16-column, tab-separated,
**append-only** file on your disk. One row per closed packet, appended by the
archivist at close — not by the builder mid-flight, because at close every column
is knowable at once and the store has no supersede mechanism.

- **Local. No telemetry.** `record-packet.sh` and `report-speed.sh` contain no
  network calls of any kind, and `tests/speed_benchmark_tests.sh` greps them to
  keep it that way. The store is yours; git is the only thing that moves it.
- **`-` means unmeasured and never means zero.** The recorder will not default a
  number to `0`, and a column no row measured totals to `-` in the report.
  `defects_escaped` is `-` across this project's entire seeded corpus, because no
  post-close defect audit has ever been run here. That is an admission, not a
  clean record.
- **Evidence classes are ranked:** `git` (reproducible from the repository) >
  `mixed` > `transcript` (real, but not re-derivable) > `estimate` (a judgement,
  and it says so). Every row must carry a note of at least 12 characters, and a
  `git`/`mixed` row that names no commit is refused.
- **Read §3's denominator before quoting §3's percentage.** The seeded corpus is
  4 rows and the round-budget compliance rate currently has a denominator of
  **1**. The report prints that denominator next to the percentage on purpose.
- **§5 is a within-Build-OS parallel-vs-serial upper bound with no control arm** —
  it is not a comparison against working without this system, and it is not
  measured against anything outside one transcript. Do not lift that number into
  a slide.

One operational note for a pilot: `build-os/metrics/` currently lives in **this**
repository and is **not** vendored into your repo by `install-project.sh`. Call
the scripts by path from your clone with `--store` pointed at your repo, exactly
as [`DEMO.md`](DEMO.md) Step 8 does.

---

## 7. Installing it

| You want | Command | Notes |
|---|---|---|
| This one repo | `/path/to/ClaudeOrchestrator/install-project.sh /path/to/your/repo` | vendors the engine + scaffolds `build-os/`; **zero network**; idempotent |
| Every project on a machine | `/path/to/ClaudeOrchestrator/install-global.sh` | writes `~/.claude/`; merges settings, never clobbers |
| Memory scaffold only | `cd /your/repo && /path/to/ClaudeOrchestrator/init-build-os.sh` | for a machine that already has the engine globally |
| Web / remote sessions | `/path/to/ClaudeOrchestrator/connect-project.sh /path/to/your/repo` | commits a SessionStart bootstrap; **needs `github.com` egress** |

The full matrix, including what happens in a locked-down network, is
[`../INSTALL.md`](../INSTALL.md). All installers are idempotent and merge rather
than overwrite; none of them runs `git add`, commits, or pushes.

**Don't double-install.** Project scope *and* global scope in the same repo makes
the SessionStart and prompt reminders print twice.

---

## 8. Your first day, in order

1. Run [`DEMO.md`](DEMO.md) end to end against the sample project — 30 minutes,
   offline, throwaway. Do this before you install anything into a repo you care
   about.
2. Install into one real, non-critical repo. Commit `.claude/`, `build-os/` and
   the `CLAUDE.md` block yourself; the installer deliberately does not.
3. Fill in `build-os/memory/current_state.md` with the project's basics. Your
   `build-os/memory/tool_router.md` ships with **zero** connector rows on purpose
   — add a row when *you* connect a tool. A row naming a capability you do not
   have is worse than no row.
4. Put anything that must never rotate into `build-os/memory/standing_gates.md`.
5. Run one task per lane and watch the announcements: a question (`read-only`), a
   one-line fix (`tiny`), a real feature (`substantive`). Note what each cost in
   rounds.
6. Set up the week-one rubric in [`PILOT.md`](PILOT.md) *before* you start, and
   take its R2 baseline snapshot on day one — a criterion adopted after seeing
   the results is not a criterion.

## 9. Ten minutes of checking, if you only do one thing

| Claim you have been told | Command that settles it |
|---|---|
| "The suite is green" | `bash tests/build_os_tests.sh` — read the final `RESULT` line |
| "It's faster" | `build-os/metrics/report-speed.sh` — its first paragraph says it cannot show that; then `build-os/metrics/COMPARISON_PROTOCOL.md` |
| "The gates refuse things" | [`DEMO.md`](DEMO.md) Step 6 — four refusals, four non-zero exits |
| "Memory rotation is safe" | `./build-os/maintenance/rotate-memory.sh` — dry run is the default; read the conservation line |
| "Uninstall is clean" | [`DEMO.md`](DEMO.md) Step 9, or `tests/build_os_maintenance_tests.sh` |
| "The docs match the code" | `bash tests/pilot_kit_tests.sh` — runs this kit's own commands and fails on drift |
