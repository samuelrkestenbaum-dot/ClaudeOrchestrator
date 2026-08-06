# Tool Router

The routing matrix. The **build-orchestrator** reads this on every invocation,
matches the task to a row, and declares its Tool Budget from it. If no row
matches, it routes from embedded defaults and says so.

## Lanes — declare one out loud, before acting

A lane is **declared, not implied**. Proportionality that lives only in prose
gets ignored; this table is the gate-set, and the round budget is the contract.

<!-- BUILD-OS:LANES:START — canonical; keep byte-identical in build-os/memory/tool_router.md and .claude/agents/build-orchestrator.md -->
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
<!-- BUILD-OS:LANES:END -->

### Changing lane mid-flight

<!-- BUILD-OS:ESCALATION:START — canonical; keep byte-identical in build-os/memory/tool_router.md and .claude/agents/build-orchestrator.md -->
**Escalation costs something; de-escalation is free.** The asymmetry is the
point: the cheap direction must be frictionless, the expensive direction paid
for out loud.

- **Down is free.** `substantive → tiny → diagnosis → read-only` needs no
  justification, no announcement, no permission. Drop gates the moment the work
  turns out smaller than it looked.
- **Up costs a stated reason.** Before the next action, announce
  `Lane: tiny → substantive — reason: <a defect found | a hidden dependency | a risk discovered>`.
  "It felt safer" is not a reason. An escalation with no named cause is itself the defect.
- **Over-budget is a defect, not a detail.** If a `tiny` task has consumed 2 rounds and is not done,
  stop and re-classify with a stated reason. Do not quietly keep going.
  A `tiny` task silently spending a third, fourth, or eleventh round is the exact
  failure this rule exists to catch — say it out loud instead of continuing.
<!-- BUILD-OS:ESCALATION:END -->

### A declared lane is **checkable**, not merely stated

The lane you declare is cross-examined against git by
`build-os/metrics/check-adoption.sh`, which runs at close. This exists because
declaring `tiny` waives **qa, the reviewer, the archivist, the receipt and the
metrics row** — five gates turned off by one self-asserted word. Until that word
could be contradicted by evidence, the whole enforcement chain rested on the
honesty of the agent it was meant to check.

**Only lanes that waive gates are size-checked.** `read-only`, `diagnosis` and
`tiny` are. `substantive`, `architecture` and `agent-swarm` have **no upper
bound at all** — they already pay for the full chain, so their size is not
evidence against them.

<!-- BUILD-OS:LANE-SIZE:START — canonical; the same two numbers are compiled into build-os/metrics/check-adoption.sh and pinned literally by tests/lane_declaration_tests.sh. Drift between the three is a defect. -->
| Constant | Value | Derivation (from `build-os/metrics/packet_metrics.tsv`) |
|---|---|---|
| `LANE_TINY_MAX_FILES` | `13` | **median** `files` over the 4 size-measurable non-waived-lane rows — {7, 8, 18, 32} → (8+18)/2 |
| `LANE_TINY_MAX_CHURN` | `2213` | **median** `insertions + deletions` over the same 4 rows — {852, 2005, 2422, 9818} → (2005+2422)/2 = 2213.5, floored |
<!-- BUILD-OS:LANE-SIZE:END -->

A waived-lane declaration is **contradicted** when git says the packet touched
at least that many files **or** churned at least that many lines. The two
signals fire independently.

**Why the median and not the minimum.** The smallest packet this repo ever ran
`substantive` was 7 files / 852 lines; the largest thing it ever ran `tiny` was
1 file / 116 lines. There is a wide empty band between the two populations, and
the line is drawn at the **far** side of it. That is a deliberate trade:
**specificity over sensitivity.** A check that flags legitimate work is switched
off inside a week, and a switched-off check is worse than none because it leaves
the belief that it is running. So a `tiny` mis-declared over 8 files / 2005
lines **passes** — half the calibration set survives being relabelled. What does
not survive is the egregious case: a "tiny" that rewrote 30 files or churned
2000+ lines.

**Some `tiny` work has no commit at all** — a read-only answer, a diagnosis, an
edit not yet committed. Those are unmeasurable and pass. An absent diff is not
evidence of a large one.

**The escape hatch, and its price.** A mechanical rename across 40 files is
genuinely `tiny` in judgment. Record it — never argue with the threshold and
never raise it:

```
LANE-OVERRIDE: mechanical rename across 40 files, no behaviour change, suite untouched
```

in the receipt **or** in the metrics row's `note`. It must name the **measured
file count**, so it can only be written by someone who looked at the real size —
a boilerplate override copied from another packet is rejected. Every honoured
override prints `LANE-OVERRIDDEN` on every run and is enumerable with
`grep -rn LANE-OVERRIDE build-os/`. There is no silent pass, and a malformed
override **fails** rather than degrading into one.

**Do not clear a failure by moving a threshold.** The numbers are pinned
literally in `tests/lane_declaration_tests.sh`; changing them costs a reviewed
edit to three files at once. The guard also prints the store's *currently*
recomputed medians beside the enforced ones so drift is visible — but it never
auto-follows them, because a threshold that tracks the store is
attacker-controlled: record a few large packets and the `tiny` ceiling rises to
meet them.

**What this does NOT catch, said plainly.** `gravito_test_harness_stdin_hang_a`
is recorded `lane=tiny rounds=6` against a 2-round budget — this system's worst
compliance record. Its *size* is 1 file / 116 lines, which is genuinely tiny, so
this check passes it and should. That failure was a **budget** breach, not a
mis-declaration. Different defect, different guard; **the round-budget guard is
not built.** Rounds are transcript-only today and nothing git-observable attests
to them, so no check here can enforce the 2-round budget.

> Columns: **Task type** · **Authority** · **Route (agents)** · **Tools** ·
> **Gate / stop**

| Task type | Authority | Route (agents) | Tools | Gate / stop |
|---|---|---|---|---|
| Read-only answer / question — lane `read-only` | build | build-orchestrator *or direct* (no builder chain) | Read, Grep, Glob | answer only; no edits, no packet, no qa/reviewer/archivist; 1 round |
| Diagnosis / triage (no edits) — lane `diagnosis` | build | qa *or direct* (no builder chain) | Read, Grep, Glob, Bash (read-only) | report findings only; if a fix is needed, propose a packet — don't implement here; 1 round |
| Tiny reversible local edit — lane `tiny` | build | builder-lite (single agent, direct) | Read, Grep, Glob, Edit, Write, Bash | in-scope, local, trivially reversible; ≤1 commit; **no qa/reviewer/archivist/packet/receipt**; **2 rounds max** — over budget, stop and re-classify with a reason |
| Build / feature / bugfix — lane `substantive` | build | builder → qa → reviewer → archivist | Read, Grep, Glob, Edit, Write, Bash | ≤2 commits; Commit-1 green in isolation; no push/merge |
| Architecture / "what's next" / planning — lane `architecture` | build | build-orchestrator only (no edits) | Read, Grep, Glob, Bash | route to a packet, don't implement |
| Design / UI | design-ui (frontend only) | builder (frontend scope) → qa (UI smoke) → reviewer → archivist | Read, Grep, Glob, Edit, Write, Bash | frontend files only; no backend/runtime reach-in |
| Marketing / media | marketing-media | builder (marketing/media packet scope) → reviewer → archivist | Read, Grep, Glob, Edit, Write, Bash | only inside marketing/media packets; no product code |
| Agent swarm / parallel work (default for ≥2 independent items) | agent-swarm | build-orchestrator fan-out → per-task builders → reviewer (merge) → archivist | Read, Grep, Glob, Edit, Write, Bash | parallelizable work only; **disjoint file-ownership manifest + merge plan + merger owns hot files** — see *Fan-out (parallel) protocol* |
| QA / proof / regression | build | qa | Read, Grep, Glob, Bash | report exact counts; RED blocks close |
| Review / second-eyes | build | reviewer | Read, Grep, Glob, Bash | no edits; verdict only |
| Close / receipt / memory | build | archivist | Read, Write, Bash | touches `build-os/` only |
| Infra / deploy / release | infra-deploy | build-orchestrator (gate) | Read, Grep, Glob, Bash | **STOP** — deploy/merge/secret need explicit go |
| Secrets / credentials | infra-deploy | build-orchestrator (gate) | Read, Bash | **STOP** — never read/write/rotate without explicit go |
| Push / merge to base | infra-deploy | build-orchestrator (gate) | Bash | **STOP** — never push/merge without explicit go |

## Embedded defaults (no matching row)

- Route from the requested outcome, using the smallest safe lane (declare it):
  - `read-only` answer / explanation → direct; `Read, Grep, Glob`; 1 round
  - `diagnosis` / triage → direct or `qa`; read-only tools; report, do not fix; 1 round
  - `tiny` reversible local edit → `builder-lite` + one targeted check; 2 rounds max
  - `substantive` feature / bugfix / multi-file build → `builder → qa → reviewer
    → archivist`
  - `architecture`, ambiguous scope, or gated work → `build-orchestrator`
- Stop before external mutation. Announce
  `Orchestrator: ON — routing from embedded`.

## How to extend

Add a row per new task type. Keep the **Gate / stop** column honest — every row
that can cross a merge/deploy/secret/push boundary must say **STOP** there.

## Fan-out (parallel) protocol

<!-- BUILD-OS:FANOUT:START — canonical; keep byte-identical in build-os/memory/tool_router.md and .claude/agents/build-orchestrator.md -->
**Parallel by default.** When 2 or more work items are independent, fan out rather than sequence.
Serial-by-default is the single largest speed loss in this system: sequencing
independent work is a decision that has to be justified, not the resting state.

A fan-out is legal only with **all three** of:

1. **Disjoint file-ownership manifest** — every agent's writable set, written
   down and non-overlapping. If two agents could write the same file, it is not
   a fan-out. Anything unlisted is not writable by that agent.
2. **Merge plan** — states who merges (a named agent or the orchestrator) and
   the single verification that runs once after the merge. Fixed before the
   fan-out starts, not improvised after the diffs land.
3. **Merger owns the hot files** — shared surfaces belong to the merger, never
   to a fan-out agent: the test suite(s), `build-os/memory/*`, packets and
   receipts, version / changelog files, lockfiles.

For genuinely overlapping work, do not fan out into one tree: give each agent an
isolated git worktree and add an explicit merge pass, closing with that same
single post-merge verification.
<!-- BUILD-OS:FANOUT:END -->

### Worked example (three-agent fan-out on this repo)

Three independent items — a maintenance-layer fix, an installer/template change,
and a lane-enforcement change — fanned out with the manifest below:

| Agent | Writable set (exclusive) | Forbidden |
|---|---|---|
| Agent A — lanes | `.claude/agents/*.md`, `.claude/commands/*.md`, `build-os/memory/tool_router.md`, `CLAUDE.md`, `build-os/global-claude-md.md`, new `tests/lane_enforcement_tests.sh` | installers, templates, `VERSION`, other test suites |
| Agent B — installers | `init-build-os.sh`, `install-project.sh`, `templates/*`, `VERSION`, `CHANGELOG.md` | agents, router, memory, other suites |
| Agent C — maintenance | `build-os/maintenance/*`, `tests/build_os_maintenance_tests.sh` | agents, router, installers |

Merge plan: **the orchestrator merges**, in the order A → B → C, and owns every
hot file (`build-os/memory/current_state.md`, `build-os/memory/residue.md`, packets,
receipts, `tests/build_os_tests.sh`). Fan-out agents leave work **uncommitted**;
the orchestrator commits. Single post-merge verification: `bash
tests/build_os_tests.sh && bash tests/lane_enforcement_tests.sh && bash
tests/build_os_maintenance_tests.sh`, each reporting its own `==== RESULT: N
passed, M failed ====` line.

### The merge is the serial fraction — run it with `swarm-merge.sh`

Every fan-out above ended with a **hand merge**: staging disjoint sets, wiring
the hot files, running one verification. That is serial work bolted to the end of
parallel work, and it **grows with width** — the one term that must not.
`build-os/tools/swarm-merge.sh` takes the ownership manifest and mechanises the
part of it that is mechanical:

| Step | Command | When |
|---|---|---|
| Disjointness + hot-file reservation | `swarm-merge.sh validate --manifest M --repo .` | **before any agent runs** |
| Each agent's real diff vs its declared set | `swarm-merge.sh verify --manifest M --repo .` | after the diffs land |
| Stage per-agent sets, run ONE verification | `swarm-merge.sh merge --manifest M --repo . [--commit MSG]` | at the merge |

The **manifest format** (see `build-os/tools/fanout_manifest.example`, which is
the worked example above written out in full):

```
merger      orchestrator
verify      bash tests/build_os_tests.sh
agent       A-lanes [evidence=<path list or git worktree>]
own         A-lanes .claude/agents/*.md
merger-own  build-os/receipts/**
hot         <extra merger-reserved glob>
hot-release <glob> <agent> <reason of >= 30 chars>
```

Three things worth knowing before trusting it:

- **Hot files are reserved to the merger by default** — `build-os/memory/**`,
  packets, receipts, metrics, `VERSION`, `CHANGELOG.md`, lockfiles, and whatever
  suite the `verify` command names. A fan-out agent claiming one is rejected by
  name and path. `hot-release` releases exactly one claim to exactly one agent
  for a stated reason, because the real fan-out above legitimately owned
  `VERSION`, `CHANGELOG.md` and the router; a rule that rejects the fan-out that
  actually happened is a rule that gets switched off.
- **Isolation is a shared tree by default.** Worktrees buy per-agent attribution
  and cost a checkout each; disjoint sets rarely need them. Without an
  `evidence=` source an out-of-set write is still caught **by path**, but it is
  reported `UNATTRIBUTED` rather than pinned on an agent the tool cannot
  identify.
- **It refuses rather than guesses.** Two claimants for one real path, an
  unmerged conflict, a rename, a non-empty index, an unstaged remainder, or a red
  verification each stop the merge with the index restored exactly as found.
  Nothing is committed unless `--commit` is passed, and nothing is ever pushed.

It cannot spawn the fan-out — bash cannot dispatch agents. Cutting the packets,
writing the manifest, authoring the merger's own hot-file edits and taking the
commit decision stay with the orchestrator.

## Proportionate routing (don't over-orchestrate)

Match the route to the task's real weight — the declared **lane** *is* that
match. The full `builder → qa → reviewer → archivist` chain belongs to the
`substantive` lane only; it is **not** the default for everything:

- **Read-only answers / questions** → answer directly (or via build-orchestrator);
  Read/Grep/Glob only; no packet, no builder chain.
- **Diagnosis / triage (no edits)** → investigate and report (qa or direct);
  read-only Bash allowed; if a fix is warranted, *propose a packet* instead of
  implementing inline.
- **Tiny reversible local edit** → a single builder-lite pass and ONE targeted
  check; ≤1 commit; **2 rounds max**; no qa, no reviewer, no archivist, no
  packet, no receipt.

**Escalate, never silently expand.** The moment a "tiny" edit needs new files,
touches shared/runtime logic, or stops being trivially reversible, stop and
re-route to the full **Build / feature / bugfix** row — announcing the lane
change and its reason (see *Changing lane mid-flight* above). Re-routing
*downward* to a cheaper lane needs no announcement at all.

## Standing lessons (load-bearing — earned, not assumed)

**A test title is a CONTRACT OVER ITS ASSERTIONS, not a statement of intent.**
If a title names a property, an assertion must **fail** when that property is
broken. A title that claims more than the body proves is the same defect class as
an overclaiming receipt — it manufactures confidence that no evidence supports.
Check it the only way that works: break the property and confirm a test dies.

**A green suite is not proof that a guarantee is enforced.** A passing test says
the code does something; only a **failing mutant** says the code is what makes it
so. Before claiming an invariant is enforced, mutate it and watch a test die. If
nothing dies, the invariant is either unenforced or untested — say which.

**Prefer a deny-list to an allow-list for "is this input trusted".** When a
vocabulary is expected to grow, an allow-list silently demotes every future member
to untrusted, which fails *closed on paper* but breaks the feature in a way no
current test can catch. A deny-list is safe **only** if a structural guard rejects
unrecognized values first — so state the ordering and test it.

**When a mutation cannot be killed, say so and narrow the claim.** Some properties
are guaranteed by construction (an upstream encoding, a type, an unreachable
branch) and no test can fail on them. Do not manufacture a test that appears to
cover it. Prove the unreachability, narrow the title to what *is* asserted, and
record the reasoning.

## Tool selection ranking (overlapping tools)

When more than one capability could do the job, pick with this ranking (earlier
wins):

1. **Exact task match** — the tool purpose-built for this exact job.
2. **Project-local instruction** — what this repo's config / router / CLAUDE.md says.
3. **Enabled / live evidence** — verified live via a registry/tool call, not a
   cache entry (see *Availability = live proof* below).
4. **Least privilege** — the read-only / narrowest-scope option that still works.
5. **Lowest orchestration overhead** — fewest agents/steps for the same result.
6. **Freshest verified result** — most recently confirmed working.

Use **one primary capability** per job. Add a second only when it has a
**distinct, necessary** role (e.g. Serena for symbols *and* Repomix for a handoff
snapshot) — not as redundant overlap.

### Availability = live proof, not cache

A plugin / skill / MCP appearing in a **filesystem cache** (`~/.claude/plugins/**`)
is a **candidate**, not proof it is active. Before routing to it or calling it
ACTIVE, confirm with a **live** signal: `ListPlugins` / `ListConnectors` /
`ListSkills`, the `enabledPlugins` set in settings, or a real `mcp__<server>__*`
tool call. The SessionStart inventory labels cache entries as *candidates* for
exactly this reason.

### Canonical MCP servers (one live server per job, no duplicate launches)

Run **one canonical live server per job** — never two servers that do the same
thing. When duplicates exist, prefer in this order:

1. a **pinned, user-configured** server (explicit version in `.mcp.json` /
   `~/.claude.json` / settings), over
2. a **plugin-bundled** copy, over
3. an unpinned **`@latest`** invocation.

Concretely: do **not** launch a second **Serena** when one is already live, and do
**not** run **Chrome DevTools MCP** alongside another browser/devtools server for
the same task. Pick the single pinned/user-configured instance and route all of
that job's calls through it. Redundant launches waste resources, split state, and
make "which one answered?" ambiguous. If two are already running, use the pinned/
user-configured one and note the duplicate.

## External tool routing (use when connected)

Route to these **only when connected** in the current environment; otherwise fall
back to native tools and name the missing capability in the Tool Budget. These
rows are **preferences, not a whitelist** — the orchestrator also uses any *other*
capability already connected in the session (skills, slash commands, subagents,
MCP servers) that fits the task. The SessionStart hook surfaces the live
inventory; default to "it's probably connected — check," not "it's absent."
⚠️ The tool/repo handles below are common names — if you ever *install* something
new, **verify the exact package/repo first**; ecosystem names are easy to mistype.

> **Preference vs. verified.** The table below is a *preference map* and may name tools
> that are **not** installed here. Two verified categories differ: **local Claude Code
> plugins** (in `claude plugin list` — see *Build accelerators*) and **remote/org
> claude.ai capabilities** (in the app's ListConnectors/ListPlugins — see *Remote / org
> capabilities* below), which are **not** in the local CLI registry. **No-route-to-
> unverified:** route to a capability only after confirming it is live in the CURRENT
> surface; fall back to native tools (saying so) when it is absent.

| Task type | Preferred external tool(s) | Used by | Gate |
|---|---|---|---|
| Web research / live docs | Perplexity MCP, native WebSearch/WebFetch | build-orchestrator, builder | read-only — normal budget |
| Site scrape → context | Firecrawl MCP (`firecrawl-mcp-server`) | builder, build-orchestrator | read-only — normal budget |
| Browser / UI QA / screenshots | Playwright MCP (`@playwright/mcp`), Chrome DevTools MCP (`chrome-devtools-mcp`) | qa | read-only drive; no prod actions |
| Second-eyes code review | **NONE AVAILABLE — review is SAME-MODEL.** Codex (`codex` CLI / Codex-for-Claude-Code plugin) is the intended provider and is still **unusable — but the REASON CHANGED at `gravito_preintegration_baseline_a` (2026-08-05), and the old evidence is now FALSE**. The binary is PRESENT: `which codex` exits **0** at `/opt/node22/bin/codex`, `codex --version` = `codex-cli 0.146.0` (no plugin directory, still). What blocks it is no longer ABSENCE but REACHABILITY: `OPENAI_API_KEY` is UNSET **and** the agent proxy returns **`403` CONNECT — `connect_rejected — policy denial`** for `api.openai.com:443`, on both HTTPS and websocket transports. **So provisioning the key is NECESSARY BUT NOT SUFFICIENT: the network policy must also allow the host — two changes, not one. This gates Phase D.** No closed packet has yet had a second-eyes provider, checked at each of the last **35** packets. **That figure is now DERIVED, not remembered:** `scan-controls.sh counts` record `DC-0001` binds this sentence to the receipt store that produces it (one receipt per closed packet, none of them with a second-eyes provider), and refuses at exit 2 the moment the two disagree. It carried **"nine"** against a live nineteen until that binding existed — a stale restatement in the very file that tracks review discipline, understating the gap by more than half. Until a second provider is live, the reviewer states "second eyes: NONE, single-model" in its verdict — it does not silently omit the line. | reviewer | read-only — normal budget |
| Repo → LLM context pack | RepoMix (`repomix`) | build-orchestrator, builder | read-only — normal budget |
| Parallel multi-agent work | Claude Squad / parallel sub-agents | build-orchestrator (agent-swarm) | **merge plan required** |
| Send mail / message / SaaS write | Gmail, Slack, Notion, HubSpot, Supabase MCP (write ops) | builder | **STOP** — external mutation, explicit go |
| Design / UI polish | `design` plugin (claude.ai org — verify per surface) — UI/UX, design-system | builder (design-ui) | frontend only |
| Media generation | Higgsfield (installed connector) / Glif / Remotion | builder (marketing-media) | marketing/media packets only |

### Remote / org capabilities — claude.ai (NOT in the local Claude Code plugin registry)

⚠️ **Remote/org, not local-CLI-verified.** These are **claude.ai org-level** plugins,
confirmed only via the claude.ai app's `ListPlugins` — they do **NOT** appear in the local
Claude Code plugin registry (`claude plugin list`) and are **not** the locally-installed
CLI plugins (the Trail of Bits curated set, `claude-hud`, `context-mode` — see *Build
accelerators*). **No-route-to-unverified:** route to one of these only after confirming it
is live in the CURRENT surface (an `mcp__*`/tool call or the app's live registry) — org-level
enablement is not proof it is reachable from a local Claude Code CLI session. Mutations
(send/file/publish/remote-DB-write) are a **STOP** for explicit go.

| Plugin | Build capability | Authority | Gate / stop |
|---|---|---|---|
| `design` | UI/UX, design-system, visual polish | **design-ui — frontend only** | frontend files only; no backend/runtime reach-in |
| `data` | Spreadsheets, analysis, data shaping/viz | build | read/analyze normal; **STOP** on remote-DB writes |
| `productivity` | Docs, tasks, notes, scheduling workflows | build | read normal; **STOP** on external send/write |
| `brand-voice` | Voice/tone, de-slop AI-sounding copy | marketing-media | marketing/media packets only |
| `marketing` | Copy, SEO, CRO, email, social | marketing-media | marketing/media packets only |
| `sales` | Outreach, CRM workflows, pipeline | build (business) | read normal; **STOP** on send/CRM write |
| `small-business` | Ops: invoicing, CRM, contracts admin | build (business) | read normal; **STOP** on external file/send |
| `legal` | Contracts, review, legal docs | build (business) | read normal; **STOP** on e-sign/file/send |
| `cowork-plugin-management` | Meta: install/enable/manage plugins | meta | plugin-management only; no product code |

### Remote / org connectors — claude.ai (verify per surface)

⚠️ **Remote/org, not local-CLI-verified.** These MCP connectors are **claude.ai org-level**,
confirmed via the app's `ListConnectors` — availability is **per surface**; they are not
guaranteed reachable from a local Claude Code CLI session and do not appear in the local
plugin registry. Apply **no-route-to-unverified**: confirm the connector is live in the
current surface before routing. Read is normal budget; **write ops are a STOP**.

| Connector | Use | Gate / stop |
|---|---|---|
| GitHub *(session MCP)* | Repos, PRs, issues, Actions/CI, code search | push/merge/PR = **STOP** |
| Supabase | Postgres DB, migrations, edge functions | migration/SQL write = **STOP** |
| Netlify | Deploy/manage sites | deploy/update = **STOP** |
| Hugging Face | Models / datasets / spaces | read-only |
| Higgsfield | Image/video/audio/3D/media generation | generate/publish = marketing-media packet + cost |
| Zapier | Bridge to 9,000+ apps | write actions = **STOP** |
| Gmail · Slack · Notion · HubSpot | Mail · chat · docs · CRM | send/write = **STOP** |
| Apollo.io · Clay | Lead gen / enrichment / outreach | send/campaign/write = **STOP** |
| Docusign | E-signature envelopes, agreements | send/create envelope = **STOP** |
| Otter.ai | Meeting transcripts | read-only |
| Claude Code Remote *(session MCP)* | Triggers, PR subscribe, add_repo, sessions | schedule/subscribe = normal; repo/session mutation = judgment |

> **Not live (out of scope until enabled):** Stripe & Cloudflare Developer
> Platform (installed, need auth), Google Calendar / Google Drive / Microsoft 365
> (installed, toggled off in-chat). Don't route to these until they're authorized
> / enabled.

### Build accelerators (verified 2026-07 — see receipt P-002)

**Discovery-first tool selection (do this every build).** (1) *Discover* live
capabilities — `ListConnectors` / `ListPlugins` / `ListSkills`, the SessionStart
inventory, and the tables in this file. (2) Select the **smallest correct
toolset** for the task. (3) In large or unfamiliar repos, prefer **symbol-level**
navigation (Serena) over broad file reads. Never claim an unavailable tool is
installed — if it's not in the live inventory, say so and fall back.

One orchestrator only (Build OS): these accelerators are *instruments*, not
competing agent frameworks. None of them makes build decisions or crosses a
production boundary on its own.

**Status semantics — use these exact labels everywhere** (tool_router, INTEGRATIONS,
memory, residue, receipts):

- **ACTIVE** — available and verified in a *newly started normal* Claude Code session.
- **DURABLY CONFIGURED** — committed config can reconstruct the tool, but it is *not
  active until restart/approval*.
- **RUNNABLE ON DEMAND** — verified via npx/uvx in *this ephemeral container*; this is
  **NOT** a persistent install on the user's Mac or globally in Claude Desktop.
- **DOCUMENTED/OPT-IN** — recipe / routing guidance only; not installed.
- **NOT INSTALLED/BLOCKED** — unavailable, ambiguous, or intentionally withheld.

**Anti-overstatement rule.** Never call npx/uvx success in an ephemeral container
"installed." Use "installed" **only** when *both* persistent host state *and* a
fresh-session activation test are verified. Keep **installation · configuration ·
activation · authentication · repository rollout** as five distinct states.

> **Provisioning status (P-012 — live host convergence).** A fresh authenticated prompt
> returned successfully with one startup signal, one routing reminder, no hook parse
> failure, and no skill-listing truncation. `ecc@ecc` is disabled; the focused skill
> stack remains enabled. Serena is one pinned user-scope MCP at official commit
> `68884f1`; `zeroize-audit` is disabled so its unpinned bundled server cannot duplicate
> it. Node 22.23.1 satisfies the Node tools; Claude HUD's visual TTY render is unverified.

| Accelerator | Route to it when… | Status (P-012 live evidence) | Gate / stop |
|---|---|---|---|
| **Serena** — MCP | Primary for symbol-level work in large or unfamiliar repos | **ACTIVE** — one user-scope `serena` server pinned to official commit `68884f1`; fresh MCP connection PASS; unpinned plugin copy disabled | local LSP only; edits flow through builder; keep ONE instance |
| **Repomix** — `repomix@1.17.0` | Explicit snapshots / handoffs only | **ACTIVE** — Node 22 host executable and fresh session PASS | hardened config; external sharing = **STOP** |
| **ccusage** — `ccusage@20.0.18` | Usage / cost visibility | **ACTIVE** — Node 22 host executable and fresh session PASS | visibility-only |
| **Claude HUD** | Operator visibility | **DURABLY CONFIGURED** — v0.6.0 enabled; visual TTY render unverified | visibility-only |
| **Trail of Bits skills** | Relevant security work only | **ACTIVE** — 8 focused plugins enabled; `zeroize-audit` disabled because its bundled MCP was unpinned | activate per task |
| **Context Mode** | Long sessions — pilot only | **ACTIVE** — v1.0.169 connected; benchmark PASS | non-secret repos only |
| **claude-code-action** | Repo-scoped GitHub assistance | **DOCUMENTED/OPT-IN** | named repo + secret + explicit go |
| **claude-code-security-review** | Repo-scoped PR security review | **DOCUMENTED/OPT-IN** | named repo + secret + explicit go |

### Specialist capability profiles

The focused profile is the fast default, not a permanent capability deletion. Before
work that materially benefits from ECC-only language/framework reviewers, browser QA,
networking, production operations, or its specialist agents, offer or invoke the `ecc`
profile for the next fresh session. Before an explicit compiler/assembly zeroization
audit, use the `zeroize` profile. Return to `focused` afterward:

`build-os/tools/capability-profile.sh {focused|ecc|zeroize|status}`

Each profile keeps exactly one Serena MCP. Never enable ECC and zeroize indiscriminately
for ordinary work; profile switching should follow exact task match and lowest overhead.

> **Repo-scoped ≠ global.** `claude-code-action` and `claude-code-security-review`
> are per-repository GitHub Action templates, **not** global plugins — never add
> them to arbitrary product repos. Minimum-permission, advisory-first install
> recipes live in `INTEGRATIONS.md` §8.

### Host specialist capabilities (P-014, surface-verified P-016 — don't duplicate)

Extra capabilities present on the host, **preserved across all profile transitions**
(the capability-profile switcher only toggles ECC / zeroize-audit / Serena — never
these). These are **INLINE current-surface routes**: the prompt hook emits a REQUIRED
directive to use them here — it never switches capability profiles and never launches a
child for them. **Verification is surface-specific** — a capability confirmed in **Claude
Desktop** (the connector/app registry) is *not* the same as one visible to the local
**Claude Code CLI** (`claude mcp list` / native skills). Confirm live in the current
surface before routing (no-route-to-unverified); never disable, duplicate, or claim a
cross-surface ACTIVE state.

| Task type | Route to (inline) | Surface & verification (2026-07) |
|---|---|---|
| UI / component discovery | **21st.dev** MCP (`mcp__21st__*` cloud; `mcp__21st-dev__*` local) | Verified live in Claude Desktop cloud Code and Mac-local Claude Code. The account connector securely holds cloud credentials, but Anthropic requires a per-call approval for web-connector tools; never bypass that with a broad wildcard or a plaintext cloud environment secret. |
| External-platform reachability / web research | **Agent Reach** (`agent-reach` skill) | **Native skill present** in Claude Code (skill registry) |
| Long-running supervision | **Claude Watch** v0.4.1 → Cloud-native fallback | **Enabled plugin on the Mac**; **absent from Claude Cloud's live registry** → when Claude Watch is not callable on the surface, use the Cloud-native supervision lane: `build-os/tools/supervise.sh` (bounded in-turn watch, no plugin) + the session scheduling primitive (`send_later` / scheduled re-check) for cross-turn supervision |
| UI/UX design work | **UI UX Pro Max** v2.11.0 | **Enabled; native skill present** (Claude Code) |

Surface note: 21st.dev uses different aliases by surface: account-level cloud connector `21st`
and Mac-local MCP `21st-dev`. Resolve the live registry name before calling and do not infer one
surface's health from the other. Cloud web-connector approval is an Anthropic UI gate, not a
project-permission setting. The other three are Claude Code skills/plugins.

**Inline directives are CONDITIONAL (P-017).** The prompt hook never claims one of these tools
was used. For each inline route it emits an **INLINE CANDIDATE**: *first verify the named tool is
connected and callable on THIS execution surface; if available, use it; if unavailable or
disconnected, continue with the closest built-in/local fallback and state that limitation — do
NOT claim a capability is available merely because it is installed.* No cross-surface shell probe
is invented; availability is judged on the surface actually handling the request.

### Skills & slash commands (the `/` menu)

Skills and slash commands are **first-class routing targets**, not just MCP/CLI
tools. The SessionStart inventory lists available skills and commands (user +
project + plugin scope). When one is purpose-built for the task — e.g.
`/deep-research`, `/security-review`, `/code-review`, design or content skills —
the orchestrator **prefers it over native tools** and **names it for the main
session to invoke** (the orchestrator subagent itself holds only Read/Grep/Glob/
Bash, so it routes rather than executing the skill). Gates still apply.

### Auto-detect connected MCPs

The SessionStart hook lists configured MCP servers (read from `.mcp.json`,
`~/.claude.json`, and settings) **plus** available skills, slash commands, and
subagents. In-session, MCP tools appear as `mcp__<server>__<tool>`. The
orchestrator routes a task to a mapped capability **only if it is present**, and
otherwise falls back to native tools and declares the gap. See `INTEGRATIONS.md`
for the full ecosystem map and how to wire more in.

The hook's inventory can lag or truncate — for the authoritative live set, query
the registries directly: **`ListConnectors`** (MCP connectors: `connected` +
`enabledInChat`), **`ListPlugins`** (enabled plugins), and **`ListSkills`**. The
*Remote / org capabilities* tables above were reconciled from those (claude.ai app)
registries — they are org-level, **not** the local `claude plugin` registry. Re-verify
per surface when the environment changes rather than trusting a stale list, and never
route to a capability not confirmed live in the current surface.
