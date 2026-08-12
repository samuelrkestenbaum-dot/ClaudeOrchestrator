# DEMO — 30 minutes, start to finish, against a sample repo

> **Start with the golden path first.** The operator front door is the
> `gravito` CLI — `gravito init` → `goal` → `run` → `review` → `stop` — and
> lives in [`ONBOARDING.md`](ONBOARDING.md), executed verbatim by
> `tests/doc_drift_tests.sh`. This demo goes DEEPER than daily use: it walks
> the orchestrator internals (lanes, packets, gates, receipts) that the CLI
> drives for you. You do not need any of it to use Gravito on a repository.

A scripted walkthrough you can run **alone, offline, on a throwaway repo**. Ten
steps, ~30 minutes. Every step below is a command you paste and an observable you
check — no slides, no narration where a command would do.

**What you need:** `bash`, `git`, `node`, `python3`, `sed`, `awk`, and a clone of
this repository. **No network.** Nothing here touches a remote, a secret, or any
repo you care about: everything lands in a fresh `mktemp -d`.

**Where the demo is honest about its limits:** two things in this system cannot
be demonstrated by a shell script — an agent *announcing its lane and obeying the
gates* (that needs a live Claude Code session), and *speed* (there is no measured
speed claim in this product; see Step 8). Both are marked below rather than
faked.

| # | Step | Minutes | What it proves |
|---|---|---|---|
| 0 | Preflight | 2 | The demo's dependencies are present; nothing else is needed |
| 1 | Prove the engine before installing it | 3 | The thing you are about to install is green, by its own suite, on your machine |
| 2 | Create a throwaway sample repo | 2 | A real git repo with a real test suite and one real defect |
| 3 | Install into it | 3 | One command, offline, idempotent, no clobbering |
| 4 | See what arrived and who owns it | 2 | The managed/yours split is a file on disk, not a promise |
| 5 | A lane on a small task | 5 | The lane table ships; the routing reminder fires; test-first goes red then green |
| 6 | A gate refuses | 4 | Four refusals with non-zero exits — and the one gate a script cannot demonstrate |
| 7 | Memory rotation | 4 | Memory that outgrows the Read limit is rotated, byte-exact, with an archive pointer |
| 8 | The metrics store records a packet | 3 | A packet becomes a row; the report leads with what it does *not* show |
| 9 | Proof, then the uninstall boundary | 2 | The layer's own suite is green; removing it leaves your memory byte-identical |

---

## Step 0 — Preflight (2 min)

**Proves:** you have everything the demo needs, and the demo knows where it is
working. Every later step uses `$CO` (this clone) and `$SAMPLE` (the throwaway
repo).

<!-- DEMO:RUN id=0 -->
```bash
export CO="${CO:-$PWD}"                          # your ClaudeOrchestrator clone
export WORK="${WORK:-$(mktemp -d)}"              # a throwaway scratch dir
export SAMPLE="${SAMPLE:-$WORK/sample-project}"  # the repo we will install into
missing=""
for t in bash git node python3 sed awk; do command -v "$t" >/dev/null 2>&1 || missing="$missing $t"; done
[ -f "$CO/install-project.sh" ] || missing="$missing (CO does not point at a ClaudeOrchestrator clone)"
[ -z "$missing" ] && echo "preflight: ok" || { echo "preflight: MISSING$missing"; false; }
echo "CO=$CO"
echo "SAMPLE=$SAMPLE"
```
<!-- DEMO:EXPECT preflight: ok -->
<!-- DEMO:EXPECT CO= -->

**Expected output**

```text
preflight: ok
CO=/path/to/ClaudeOrchestrator
SAMPLE=/tmp/tmp.XXXXXXXX/sample-project
```

If `preflight` prints `MISSING`, stop and install what it names. Everything after
this point assumes it printed `ok`.

---

## Step 1 — Prove the engine before you install it (3 min)

**Proves:** the product is green **on your machine, by its own suite**, before it
touches anything of yours. The suite is offline, deterministic, and confined to
temp directories; it chains the maintenance layer's cold-install proof and folds
those assertions into its own total.

<!-- DEMO:RUN id=1 skip=recursion -->
```bash
cd "$CO" && bash tests/build_os_tests.sh 2>&1 | tail -3
```

**Expected output** — the last line is a contract: `N passed, 0 failed`, and the
suite exits non-zero if `M > 0`.

```text
==== RESULT: 657 passed, 0 failed ====
```

> **The one block in this demo that `tests/pilot_kit_tests.sh` does not execute.**
> That suite is *chained from* `tests/build_os_tests.sh`, so running this block
> from inside it would re-enter the suite that invoked it. The test asserts
> instead that the file exists and is executable, and refuses more than one such
> exemption in the whole document. Run this step yourself — it is three seconds
> of typing and half a minute of waiting, and it is the step that decides whether
> anything else here is worth your time.

The count moves as the repo grows; **`0 failed` is the part that matters.** Two
other suites exist and are worth knowing about:
`bash tests/speed_benchmark_tests.sh` pins the measurement instrument, and
`./build-os/maintenance/run-tests.sh` is the maintenance layer's own sanctioned
command (Step 9).

---

## Step 2 — Create a throwaway sample repo (2 min)

**Proves:** we are installing into a *real* git repo that already has its own
product, its own test suite, and one known defect — not into an empty directory
arranged to make the demo work.

<!-- DEMO:RUN id=2 -->
```bash
mkdir -p "$SAMPLE" && cp -R "$CO/docs/sample-project/." "$SAMPLE/"
chmod +x "$SAMPLE"/*.sh
cd "$SAMPLE" && git init -q .
git add -A && git -c user.email=pilot@example.com -c user.name=Pilot commit -qm "sample project"
git log --oneline
bash check.sh
```
<!-- DEMO:EXPECT sample project -->
<!-- DEMO:EXPECT ==== RESULT: 3 passed, 0 failed ==== -->

**Expected output**

```text
<sha> sample project
  PASS: spaces become dashes
  PASS: punctuation collapses into one dash
  PASS: input is lowercased

==== RESULT: 3 passed, 0 failed ====
```

The sample project is described in [`sample-project/README.md`](sample-project/README.md).
Its known defect: `./slugify.sh "Hello, World!"` prints `hello-world-` — a
trailing dash — and `check.sh` does not cover that case yet. Step 5 fixes it.

---

## Step 3 — Install Build OS into it (3 min)

**Proves:** installation is one offline command; it vendors the engine plus a
memory scaffold; and it is **idempotent** — a second run keeps every file you
own rather than overwriting it.

<!-- DEMO:RUN id=3 -->
```bash
"$CO/install-project.sh" "$SAMPLE"
echo "--- second run (idempotence) ---"
"$CO/install-project.sh" "$SAMPLE" | grep 'exists, kept'
```
<!-- DEMO:EXPECT + agents, commands, hooks -->
<!-- DEMO:EXPECT + build-os/memory/tool_router.md -->
<!-- DEMO:EXPECT + build-os/memory/standing_gates.md (from template) -->
<!-- DEMO:EXPECT Done. Commit .claude/ + build-os/ -->
<!-- DEMO:EXPECT = build-os/memory/tool_router.md (exists, kept) -->

**Expected output**

```text
Build OS — install into project: /tmp/.../sample-project
  + agents, commands, hooks
  + build-os/memory/tool_router.md
  + build-os/memory/current_state.md
  + build-os/memory/residue.md
  + build-os/packets/active_packet.md
  + build-os/receipts/README.md
  + build-os/maintenance/ (11 managed files)
  + build-os/memory/standing_gates.md (from template)
  + .gitignore (archive exception)
  = package.json (none; skipping the npm signpost — run ./build-os/maintenance/run-tests.sh)
  Done. Dry-run the rotation with: ./build-os/maintenance/rotate-memory.sh
  + .claude/settings.json hooks merged (session-hook=True)
  + added CLAUDE.md Build OS block
Done. Commit .claude/ + build-os/ (+ CLAUDE.md) to this repo to make it permanent.
--- second run (idempotence) ---
  = build-os/memory/tool_router.md (exists, kept)
  = build-os/memory/current_state.md (exists, kept)
  = build-os/memory/residue.md (exists, kept)
  = build-os/packets/active_packet.md (exists, kept)
  = build-os/receipts/README.md (exists, kept)
```

Note what the second run did **not** say: it never re-copied a memory file. The
seed comes from `templates/build-os/**`, never from this repo's live memory — so
your scaffold does not arrive pre-loaded with somebody else's project state.

---

## Step 4 — What arrived, and who owns which file (2 min)

**Proves:** the managed/yours split is checkable on disk. Managed files carry a
`GRAVITO:MANAGED` header and are listed verbatim in a manifest; files that are
yours carry `GRAVITO:TEMPLATE` and are never overwritten once they exist.

<!-- DEMO:RUN id=4 -->
```bash
cd "$SAMPLE"
echo "managed files listed in the manifest: $(grep -c . build-os/maintenance/.gravito-managed)"
echo "files carrying a GRAVITO:MANAGED header: $(grep -rl 'GRAVITO:MANAGED' build-os | wc -l)"
echo "files marked GRAVITO:TEMPLATE (yours): $(grep -rl 'GRAVITO:TEMPLATE' build-os | wc -l)"
echo "STOP gates in your installed router: $(grep -c 'STOP' build-os/memory/tool_router.md)"
git status --short | head -4
```
<!-- DEMO:EXPECT managed files listed in the manifest: 15 -->
<!-- DEMO:EXPECT files carrying a GRAVITO:MANAGED header: 10 -->
<!-- DEMO:EXPECT files marked GRAVITO:TEMPLATE (yours): 8 -->
<!-- DEMO:EXPECT STOP gates in your installed router: 4 -->

**Expected output**

```text
managed files listed in the manifest: 15
files carrying a GRAVITO:MANAGED header: 10
files marked GRAVITO:TEMPLATE (yours): 8
STOP gates in your installed router: 4
?? .claude/
?? .gitignore
?? CLAUDE.md
?? build-os/
```

(The manifest lists 15 paths; 10 of them carry the header inline, the rest are
data files and the manifest itself. `install-maintenance.sh` is in both lists on
purpose: it is managed, and it is the file that writes the templates.)

Everything is untracked until **you** commit it. The installer never runs `git
add`, never commits, and never pushes. See
[`../build-os/maintenance/PORTING.md`](../build-os/maintenance/PORTING.md) for
the full managed/yours split and Step 9 for the uninstall boundary.

---

## Step 5 — A lane on a small task (5 min)

**Proves:** three separate things — (a) the lane table and its round budgets ship
in the router the agent reads, (b) the prompt hook fires a routing reminder on
every prompt, and (c) the `tiny` lane's actual working shape — one failing test
first, then the smallest fix, with the suite as the observable.

### 5a — The lanes that shipped

<!-- DEMO:RUN id=5a -->
```bash
sed -n '/BUILD-OS:LANES:START/,/BUILD-OS:LANES:END/p' "$CO/build-os/memory/tool_router.md" \
  | grep -E '^\| `|^\| Lane'
```
<!-- DEMO:EXPECT | `read-only` -->
<!-- DEMO:EXPECT | `tiny` | builder-lite + ONE targeted check -->
<!-- DEMO:EXPECT | `substantive` | builder → qa → reviewer → archivist | as needed | -->

**Expected output** — five lanes, each with its gate-set and its round budget:

```text
| Lane | Required gates | Round budget |
| `read-only` | none — answer directly from evidence; no edits, no packet, no receipt | 1 round |
| `diagnosis` | none — investigate and report; do not implement, propose a packet instead | 1 round |
| `tiny` | builder-lite + ONE targeted check — no qa, no reviewer, no archivist, no packet, no receipt | 2 rounds max |
| `substantive` | builder → qa → reviewer → archivist | as needed |
| `architecture` | orchestrator routes first — classify, budget, delegate; no edits in this lane | as needed |
```

### 5b — The routing reminder fires

The `UserPromptSubmit` hook runs on every prompt. Here it is, driven directly
with the same JSON payload Claude Code would give it:

<!-- DEMO:RUN id=5b -->
```bash
printf '{"session_id":"demo-1","prompt":"slugify leaves a trailing dash; fix it","cwd":"%s"}' "$SAMPLE" \
  | bash "$SAMPLE/.claude/hooks/prompt-router.sh"
```
<!-- DEMO:EXPECT Routing reminder: classify weight + authority -->
<!-- DEMO:EXPECT STOP at merge/deploy/secret/push boundaries. -->

**Expected output** (one line, wrapped here):

```text
Routing reminder: classify weight + authority; read the project router or
~/build-os/memory/tool_router.md. Read-only answers and diagnosis may run direct;
tiny reversible edits use builder-lite + a targeted check. Use build-orchestrator
for architecture/planning, substantive builds, ambiguous scope, or gates. Declare
the smallest Tool Budget; STOP at merge/deploy/secret/push boundaries.
```

### 5c — Requires a live Claude Code session

**This block is not runnable from a shell and the demo does not pretend
otherwise.** In a real session, the agent reads that reminder, reads the router,
and announces one line before its first action:

<!-- DEMO:MANUAL reason=requires-a-live-claude-code-session -->
```bash
# In a Claude Code session opened in $SAMPLE, ask:
#   "slugify leaves a trailing dash on 'Hello, World!' — fix it"
# The observable is the announcement, before any edit:
#   Lane: tiny — one-line sed fix in slugify.sh, 1 targeted check (budget: 2 rounds)
#   Tools: [Read, Edit, Bash] — builder-lite, no qa/reviewer/archivist for a tiny edit
```

A shell script can prove the lane table shipped and the reminder fires; **only a
live session can show an agent obeying them.** Judge that part by watching one
real task in your own repo during week one — [`PILOT.md`](PILOT.md) makes it
criterion R1.

### 5d — The `tiny` lane's actual shape: red, then green

Test first. Add the failing assertion, watch it fail, then make the smallest fix.

<!-- DEMO:RUN id=5d rc=1 -->
```bash
cd "$SAMPLE"
python3 - check.sh <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
anchor = 'eq "ALL CAPS"       "all-caps"        "input is lowercased"\n'
add    = 'eq "Hello, World!"  "hello-world"     "trailing punctuation leaves no trailing dash"\n'
assert anchor in s and add not in s, "anchor missing, or the assertion is already there"
open(p, 'w').write(s.replace(anchor, anchor + add))
print("added 1 failing assertion to check.sh")
PY
bash check.sh
```
<!-- DEMO:EXPECT added 1 failing assertion to check.sh -->
<!-- DEMO:EXPECT FAIL: trailing punctuation leaves no trailing dash — got "hello-world-", expected "hello-world" -->
<!-- DEMO:EXPECT ==== RESULT: 3 passed, 1 failed ==== -->

**Expected output** — red, for the right reason, and the suite exits `1`:

```text
added 1 failing assertion to check.sh
  PASS: spaces become dashes
  PASS: punctuation collapses into one dash
  PASS: input is lowercased
  FAIL: trailing punctuation leaves no trailing dash — got "hello-world-", expected "hello-world"

==== RESULT: 3 passed, 1 failed ====
```

Now the fix — one line, in scope, trivially reversible, which is exactly what
makes the task `tiny`:

<!-- DEMO:RUN id=5e -->
```bash
cd "$SAMPLE"
python3 - slugify.sh <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
old = "    | sed -e 's/[^a-z0-9]\\{1,\\}/-/g'\n"
new = "    | sed -e 's/[^a-z0-9]\\{1,\\}/-/g' -e 's/^-//' -e 's/-$//'\n"
assert old in s, "anchor line not found in slugify.sh"
open(p, 'w').write(s.replace(old, new))
print("patched slugify.sh: strip leading/trailing dashes")
PY
bash check.sh
```
<!-- DEMO:EXPECT patched slugify.sh: strip leading/trailing dashes -->
<!-- DEMO:EXPECT ==== RESULT: 4 passed, 0 failed ==== -->

**Expected output**

```text
patched slugify.sh: strip leading/trailing dashes
  PASS: spaces become dashes
  PASS: punctuation collapses into one dash
  PASS: input is lowercased
  PASS: trailing punctuation leaves no trailing dash

==== RESULT: 4 passed, 0 failed ====
```

That is one `tiny` packet, start to finish, inside its 2-round budget: one
builder pass, one targeted check, no qa, no reviewer, no receipt.

---

## Step 6 — A gate refuses (4 min)

**Proves:** the gates are executable refusals with non-zero exit codes, not
advice. Four of them run here. The fifth — the one that matters most — cannot be
demonstrated by a script, and this step says so instead of staging it.

### 6a — A lane the router does not define

<!-- DEMO:RUN id=6a -->
```bash
"$CO/build-os/metrics/record-packet.sh" --store "$WORK/gate.tsv" \
  --packet demo_gate --lane turbo --evidence estimate \
  --note "a lane nobody defined, recorded as if it were real"
echo "exit=$?"
```
<!-- DEMO:EXPECT lane "turbo" is not one of: read-only diagnosis tiny substantive architecture agent-swarm -->
<!-- DEMO:EXPECT exit=2 -->

**Expected output**

```text
record-packet: record invalid: lane "turbo" is not one of: read-only diagnosis tiny substantive architecture agent-swarm
exit=2
```

### 6b — A report over an empty store

An empty table with a clean exit looks like proof. It is refused, loudly:

<!-- DEMO:RUN id=6b -->
```bash
"$CO/build-os/metrics/record-packet.sh" --header > "$WORK/empty.tsv"
"$CO/build-os/metrics/report-speed.sh" --store "$WORK/empty.tsv"
echo "exit=$?"
```
<!-- DEMO:EXPECT REFUSED -->
<!-- DEMO:EXPECT has 0 rows -->
<!-- DEMO:EXPECT exit=2 -->

**Expected output**

```text
report-speed: REFUSED — /tmp/.../empty.tsv has 0 rows.
A report over an empty store is not a green report; it is an unmeasured system
wearing a table. Record at least one packet before asking for a number.
exit=2
```

### 6c — A number that contradicts your own git history

This is the refusal to try on a skeptic: record one row whose figures come
straight from `git show --numstat`, then one that inflates them, and let the
verifier arbitrate against your repository.

<!-- DEMO:RUN id=6c -->
```bash
cd "$SAMPLE"
SHA="$(git rev-parse --short HEAD)"
read -r I D F <<<"$(git show --numstat --format='' HEAD \
  | awk -F'\t' 'NF>=3{i+=$1; d+=$2; f++} END{print i+0, d+0, f+0}')"
"$CO/build-os/metrics/record-packet.sh" --store "$WORK/git.tsv" --packet sample_true \
  --lane tiny --files "$F" --insertions "$I" --deletions "$D" --commits "$SHA" \
  --evidence git --note "figures taken straight from git show --numstat on this repo"
"$CO/build-os/metrics/record-packet.sh" --store "$WORK/git.tsv" --packet sample_inflated \
  --lane tiny --files "$F" --insertions 900 --deletions "$D" --commits "$SHA" \
  --evidence git --note "deliberately contradicts git so the verifier has something to catch"
"$CO/build-os/metrics/record-packet.sh" --store "$WORK/git.tsv" --verify-git --repo "$SAMPLE"
echo "exit=$?"
```
<!-- DEMO:EXPECT VERIFIED  sample_true -->
<!-- DEMO:EXPECT MISMATCH  sample_inflated -->
<!-- DEMO:EXPECT row(s) contradict git -->
<!-- DEMO:EXPECT exit=2 -->

**Expected output** — one row verifies, one is caught, and the exit code carries
the finding (a skeptic checks `$?`):

```text
recorded: sample_true (tiny lane) -> /tmp/.../git.tsv
recorded: sample_inflated (tiny lane) -> /tmp/.../git.tsv
  VERIFIED  sample_true  <sha>  files=3 insertions=61 deletions=0
  MISMATCH  sample_inflated  <sha>  insertions: row says 900, git says 61.
verify-git: 1 ok, 1 mismatched, 0 unverifiable (repo /tmp/.../sample-project)
record-packet: REFUSED — 1 row(s) contradict git.
exit=2
```

### 6d — A second row for the same packet

Double-counting is the hardest kind of wrong number to notice, because a
double-counted row is internally consistent and every self-check still passes. So
it is refused at the door:

<!-- DEMO:RUN id=6d -->
```bash
"$CO/build-os/metrics/record-packet.sh" --store "$WORK/git.tsv" --packet sample_true \
  --lane tiny --evidence estimate --note "the same packet, recorded a second time"
echo "exit=$?"
```
<!-- DEMO:EXPECT is already recorded in -->
<!-- DEMO:EXPECT exit=2 -->

**Expected output**

```text
record-packet: packet_id "sample_true" is already recorded in /tmp/.../git.tsv — one row per packet. […]
exit=2
```

### 6e — The gate a script cannot demonstrate

**No external mutation without an explicit go** — no push, no merge to a base
branch, no deploy/publish/release, no secret handling — in **every** lane,
`tiny` included. That gate is enforced by two things, neither of which is a
shell script: the agent's own instructions (which ship in the files you just
installed) and your Claude Code permission system.

What a script *can* prove is that the instruction shipped and says so:

<!-- DEMO:RUN id=6f -->
```bash
cd "$SAMPLE"
grep -A1 'No external mutation without explicit go' CLAUDE.md
grep -o 'External mutation stays hard-gated in EVERY lane[^,]*' "$CO/build-os/memory/tool_router.md"
```
<!-- DEMO:EXPECT never push, merge, deploy, -->
<!-- DEMO:EXPECT publish, or touch secrets without an explicit go from the user. -->
<!-- DEMO:EXPECT External mutation stays hard-gated in EVERY lane -->

**Expected output**

```text
- **No external mutation without explicit go** — never push, merge, deploy,
  publish, or touch secrets without an explicit go from the user.
External mutation stays hard-gated in EVERY lane**
```

The router says the rest of that sentence out loud, and it is the line most
often misread: *"`tiny` included: push, merge to a base branch, deploy / publish
/ release, and secret handling always need an explicit go from the user. 'No
gates' on the `tiny` row means no review chain — it never means no go needed to
push."*

**Judge the rest by observation, not by demo.** In week one, count the number of
pushes, merges, deploys and secret reads that happened without you saying go. The
target is exactly zero and any occurrence is a pilot failure —
[`PILOT.md`](PILOT.md) criterion R2, with a runnable check.

---

## Step 7 — Memory rotation (4 min)

**Proves:** Build OS memory grows every time a packet closes; past ~256 KB an
agent cannot read a memory file at all and starts blind. Rotation keeps the
newest N blocks live and moves the tail to an append-only archive, verifying
byte-exact conservation *before* it writes anything.

First, simulate four closed packets appending to memory:

<!-- DEMO:RUN id=7a -->
```bash
cd "$SAMPLE"
for i in 1 2 3 4; do
  printf '\n## Packet P-00%s — closed\n\nA closed packet appended one block to memory.\n' "$i" \
    >> build-os/memory/current_state.md
done
cksum build-os/memory/standing_gates.md > "$WORK/gates.before"
grep -c '^## ' build-os/memory/current_state.md
```
<!-- DEMO:EXPECT 7 -->

**Expected output** — seven blocks live in `current_state.md`:

```text
7
```

Now the **dry run**, which is the default. It plans the rotation and writes
nothing:

<!-- DEMO:RUN id=7b -->
```bash
cd "$SAMPLE"
./build-os/maintenance/rotate-memory.sh --file current_state --keep 3
```
<!-- DEMO:EXPECT DRY-RUN (no --apply) — nothing will be written. -->
<!-- DEMO:EXPECT blocks            : 7 total -> keep 3 newest, would archive 4 -->
<!-- DEMO:EXPECT byte-exact -->
<!-- DEMO:EXPECT selection         : RECENCY ONLY -->

**Expected output**

```text
DRY-RUN (no --apply) — nothing will be written.

build-os/memory/current_state.md
  delimiter         : /^## /
  blocks            : 7 total -> keep 3 newest, would archive 4
  would archive     : block_4..block_7 (299 B) -> build-os/memory/archive/current_state.archive.md
  archive pointer   : 506 B banner -> build-os/memory/archive/INDEX.md
  live size         : 1965 B -> 2172 B (ceiling 204800 B) OK
  conservation      : OK (1666 B live + 299 B archived = 1965 B original, byte-exact)
  selection         : RECENCY ONLY — no content is exempt from rotation
```

Then the same command with `--apply`:

<!-- DEMO:RUN id=7c -->
```bash
cd "$SAMPLE"
./build-os/maintenance/rotate-memory.sh --file current_state --keep 3 --apply | head -2
ls build-os/memory/archive/
grep -c 'rotate-memory:archive-pointer' build-os/memory/current_state.md
cksum build-os/memory/standing_gates.md > "$WORK/gates.after"
cmp -s "$WORK/gates.before" "$WORK/gates.after" \
  && echo "standing_gates.md: byte-identical (never rotated)" \
  || echo "standing_gates.md: CHANGED — this must never happen"
```
<!-- DEMO:EXPECT APPLY — rotation written. -->
<!-- DEMO:EXPECT INDEX.md -->
<!-- DEMO:EXPECT current_state.archive.md -->
<!-- DEMO:EXPECT standing_gates.md: byte-identical (never rotated) -->

**Expected output**

```text
APPLY — rotation written.

INDEX.md
current_state.archive.md
2
standing_gates.md: byte-identical (never rotated)
```

Two things worth reading in the shortened file (`head -30
build-os/memory/current_state.md`): the archive-pointer banner saying **"THIS
FILE IS NOT THE WHOLE RECORD"** with the exact archive paths, and the fact that
`standing_gates.md` was not touched. Rotation is **by recency only** — it makes
no guarantee about what survives *by meaning*, which is why anything that must
never rotate belongs in `standing_gates.md`, a file the tool never reads, writes
or creates.

---

## Step 8 — The metrics store records a packet (3 min)

**Proves:** a closed packet becomes one validated, attributed row in an
append-only local store, and the report over that store leads with what it does
**not** show.

<!-- DEMO:RUN id=8 -->
```bash
cd "$SAMPLE"
mkdir -p build-os/metrics
"$CO/build-os/metrics/record-packet.sh" --store build-os/metrics/packet_metrics.tsv \
  --packet demo_slugify_trailing_dash --lane tiny --rounds 1 --agents 1 \
  --files 2 --insertions 2 --deletions 1 --tests-added 1 --defects-gated 1 \
  --evidence transcript \
  --note "demo packet; rounds and agents are from the session, diffs are uncommitted"
"$CO/build-os/metrics/record-packet.sh" --store build-os/metrics/packet_metrics.tsv --validate
"$CO/build-os/metrics/report-speed.sh" --store build-os/metrics/packet_metrics.tsv | sed -n '1,14p'
```
<!-- DEMO:EXPECT recorded: demo_slugify_trailing_dash (tiny lane) -->
<!-- DEMO:EXPECT validate: 1 rows, 0 invalid -->
<!-- DEMO:EXPECT FINDING, before any number below. -->
<!-- DEMO:EXPECT This report does not show that Build OS is faster than anything. -->

**Expected output**

```text
recorded: demo_slugify_trailing_dash (tiny lane) -> build-os/metrics/packet_metrics.tsv
validate: 1 rows, 0 invalid (build-os/metrics/packet_metrics.tsv)
# Build OS — packet speed report

- **Store:** `build-os/metrics/packet_metrics.tsv` — append-only TSV, local, operator-owned, no telemetry.
- **Rows in store:** 1
- **Rows rendered:** 1
- **Generated:** <date> by `build-os/metrics/report-speed.sh`

> **FINDING, before any number below.**
>
> **This report does not show that Build OS is faster than anything.**
> …
```

**Read that finding, because it is the product's honest position.** There is no
baseline arm in this store — no run of the same work with Build OS switched off —
and none can be produced from a bash harness, so nothing here is a comparison
against anything. `build-os/metrics/COMPARISON_PROTOCOL.md` specifies the 16-run
A/B that would settle it and states plainly that it has not been run.

Two notes for reading your own store later:

- **`-` means unmeasured and never means zero.** `defects_escaped` is `-` across
  this project's whole seeded corpus, because no post-close defect audit has
  ever been run here. A column nobody measured totals to `-`, not to `0`.
- **The store is local.** No telemetry, no phone-home; the recorder and the
  reporter contain no network calls, and a test greps them to keep it that way.

The instrument (`build-os/metrics/`) currently lives in this repository and is
**not** vendored into a target repo by `install-project.sh` — that is why every
command in this step calls it by `$CO` path with `--store` pointed at the sample
repo.

---

## Step 9 — Proof, then the uninstall boundary (2 min)

**Proves:** the maintenance layer has its own sanctioned suite, and removing the
layer leaves everything that is yours byte-identical.

<!-- DEMO:RUN id=9a -->
```bash
cd "$SAMPLE"
./build-os/maintenance/run-tests.sh 2>&1 | grep -E '^# (tests|pass|fail) '
```
<!-- DEMO:EXPECT # fail 0 -->

**Expected output**

```text
# tests 144
# pass 144
# fail 0
```

Run it by that path, **not** with a bare `node --test`: the wrapper preloads a
real-memory tripwire and fingerprints your real memory on both sides of the run,
so a run that moved your memory cannot report success. A bare `node --test` takes
no preload and no fingerprint; the wrapper's own header calls that path
**UNGUARDED** and names the three other paths it does not cover.

Now the uninstall boundary — delete exactly the managed list and check what
survives:

<!-- DEMO:RUN id=9b -->
```bash
cd "$SAMPLE"
find build-os/memory -type f | sort | xargs cksum > "$WORK/mem.before"
while IFS= read -r p; do [ -n "$p" ] && rm -f "$SAMPLE/$p"; done < build-os/maintenance/.gravito-managed
echo "files left in build-os/maintenance: $(find build-os/maintenance -type f | wc -l)"
find build-os/memory -type f | sort | xargs cksum > "$WORK/mem.after"
cmp -s "$WORK/mem.before" "$WORK/mem.after" \
  && echo "build-os/memory: byte-identical after uninstall" \
  || echo "build-os/memory: CHANGED — the uninstall boundary leaked"
```
<!-- DEMO:EXPECT files left in build-os/maintenance: 0 -->
<!-- DEMO:EXPECT build-os/memory: byte-identical after uninstall -->

**Expected output**

```text
files left in build-os/maintenance: 0
build-os/memory: byte-identical after uninstall
```

Nothing under `build-os/memory/` is removed — including `standing_gates.md` and
`build-os/memory/archive/`, which holds the only copy of anything already
rotated out. **Removing the layer does not un-rotate memory.** Re-run
`install-project.sh` to put it back.

---

## Clean up

<!-- DEMO:MANUAL reason=destructive-cleanup-run-it-yourself-when-done -->
```bash
# Everything the demo created is under $WORK. When you are done:
rm -rf "$WORK"
```

## What you just saw, and what you did not

**Saw, as executed commands:** a green suite before install; an offline,
idempotent install into a real repo; the lane table and round budgets that ship;
the routing reminder firing; a test-first `tiny` fix going red then green; four
gates refusing with non-zero exits; byte-exact memory rotation with an archive
pointer; a packet recorded, validated and reported; the layer's own suite green;
and an uninstall that left every file you own byte-identical.

**Did not see, and could not:** an agent announcing its lane and obeying the
gates in a live session (Step 5c), the external-mutation gate actually stopping a
push (Step 6e), and **any speed result at all** (Step 8). The first two are
week-one observations in [`PILOT.md`](PILOT.md). The third is not a demo gap —
it is the state of the evidence: this product has no measured speed claim, and
the report says so before it says anything else.

Next: [`ONBOARDING.md`](ONBOARDING.md) for what the pieces mean, and
[`PILOT.md`](PILOT.md) for how to decide whether week one worked.
