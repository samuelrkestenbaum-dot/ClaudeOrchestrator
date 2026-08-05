# What this baseline is, what it is not, and what remains impossible

Frozen 2026-08-05, alongside `PACKET-0045-preintegration-baseline`.

`build-os/metrics/COMPARISON_PROTOCOL.md` is **not edited by this packet** — it
is a frozen record, and two of its statements are now out of date. The
corrections are recorded **here, as later records**, which is what its own
freezing discipline requires.

---

## 1. THIS IS A SNAPSHOT, NOT THE PRE-REGISTERED EXPERIMENT

`COMPARISON_PROTOCOL.md` pre-registers a **16-run, two-arm A/B** (4 tasks × 2
arms × 2 runs), with a **human operator holding the clock**, explicitly **not an
agent**, running arms in alternating order across fresh sessions.

**This packet ran one arm, one run, on one task.** Every one of the following is
absent:

| the protocol requires | this packet had |
|---|---|
| 16 runs | **1** |
| two arms (A control, B treatment) | **one arm only** (B) |
| four tasks | **one task** (`T1`); `T2`/`T3`/`T4` not run — see §3 |
| a human operator holding the clock | **no operator**; an unattended `claude -p` |
| alternating arm order across runs | not applicable at N=1 |
| ranges reported, never point estimates | a **single point**, no range |

**The pre-registered primary endpoint — median wall-clock to an accepted result
on `T3`, arm B vs arm A — is untouched by this packet.** `T3` was not run, and
there is no arm A. Nothing here supports, refutes, or bears on a "20x" claim or
any other multiplier.

The protocol's own decision rule cannot even be applied: it turns on whether two
arms' ranges overlap, and there is one arm and no range.

**The one number this packet produced is a single observation of one task under
one configuration.** Quoting it as a comparison would be exactly the failure the
protocol was written to prevent.

### The self-measurement problem has not gone away

The protocol says plainly that "an agent measuring its own speedup is not
evidence". This baseline was produced by an agent, unattended. The mitigation
applied here is not blinding — blinding remains impossible — it is **mechanical
acceptance**: every accept/reject verdict came from a hidden oracle
(`bench/oracles/oracle.js`) that the agent under test never saw, whose
criteria were frozen into the seeded tree **before** the run, and which was
proven non-vacuous before use (see §5). That removes the agent's judgement from
the scoring. It does **not** make the agent a disinterested observer of its own
speed.

---

## 2. THE PROTOCOL'S FIRST STATED BLOCKER IS NOW FALSE

> "A Claude Code session cannot be launched from a bash test. There is no
> scriptable invocation and no API access in this environment."

**This is false as of CLI 2.1.222, and it was verified, not assumed.**
`claude -p '<prompt>' --output-format json` runs headlessly and returns a result
object carrying `duration_api_ms`, `num_turns`, `total_cost_usd`, `stop_reason`,
`permission_denials`, a `usage` block with `input_tokens`, `output_tokens`,
`cache_creation_input_tokens` and `cache_read_input_tokens`, and a per-model
`modelUsage` block with `contextWindow`. `--output-format stream-json --verbose`
additionally yields the full tool-use trace.

Everything the protocol's measurement table asks for **except** the operator
observations is therefore machine-derivable today.

## 2b. THE SECOND STATED BLOCKER IS ALSO FALSE — AND THIS ONE WAS UNTESTED UNTIL NOW

> "Agent invocations are not addressable from a harness, so the 'Build OS on' arm
> cannot be driven programmatically either."

**Also false, and now tested directly.** In a seeded repo with Build OS installed
via its own `install-project.sh`, a headless `claude -p` run **successfully
dispatched the `build-orchestrator` subagent** and returned its lane
classification. Machine evidence from the stream log: one `tool_use` with
`"name":"Agent"` and `"subagent_type":"build-orchestrator"`, `num_turns` 2,
`is_error` false.

**A measurement trap worth recording.** The dispatch tool is named **`Agent`** in
CLI 2.1.222, **not `Task`**. This harness's first version grepped for `"Task"`
and reported **0 dispatches for a run that had in fact dispatched a subagent**.
That is a harness bug that would have "confirmed" the protocol's blocker by
measuring the wrong string — an instrument agreeing with a stale document because
it was looking for the wrong name. Both names are now matched, and
`subagent_type` is captured independently as a second, name-agnostic witness.

**Therefore: neither of the two reasons `COMPARISON_PROTOCOL.md` gives for not
running the experiment still holds.** The experiment is now blocked only by
operator time and by §3, not by the environment.

---

## 3. WHAT COULD NOT BE RUN, AND WHY — `T2`, `T3`, `T4` ARE `IMPOSSIBLE`

**Three of the four corpus tasks were not run, and produced no rows.** This is a
capability limit, not a scheduling choice.

**The agent under test cannot execute the project's test command.**

- `--permission-mode bypassPermissions` (and `--dangerously-skip-permissions`) is
  **refused outright** when the CLI runs as root: *"cannot be used with root/sudo
  privileges for security reasons"*. Verified — exit 1 in 0.91 s.
- `--permission-mode acceptEdits` works for `Read`/`Write`/`Edit`/`Glob`/`Grep`,
  but the **`Bash` tool is denied** under it. Verified directly, with the denial
  captured in the result JSON's `permission_denials` array.
- Widening this with `--allowedTools Bash` is **blocked at the caller** by the
  environment's auto-mode classifier. That is a permission boundary, and it was
  **not worked around** — the classifier's own guidance is to stop and let the
  user decide, and that is what happened.

The corpus's own clauses for these three tasks require suite execution:

| task | the clause that cannot be satisfied |
|---|---|
| `T2` | "write the failing test first, **confirm it fails for the right reason**… **confirm it passes**" |
| `T3` | "**Done when:** the suite is green" |
| `T4` | "**Done when:** the merge is clean and the single post-merge verification is green" |

An agent that cannot run the suite cannot perform any of those. It could still
*write* plausible code, and a run doing so would have emitted a wall-clock, a
token count and a cost that **look** like corpus results and are not, because the
task performed would not be the task the corpus specifies.

**This is enforced in the harness, not left to discipline.** `run-corpus.sh`
refuses to invoke `T2`/`T3`/`T4` while the Bash tool is unavailable, and prints
`status: IMPOSSIBLE — NOT RUN, NO NUMBERS PRODUCED`. A rule that has to be
remembered is a rule that gets skipped on the day somebody wants a number.

**Corroborating evidence from the one task that did run.** The `T1` run's own
`permission_denials` array contains **3 denied `Bash` calls** — the agent tried
three times to run `node test/run.js` and could not. `T1` completed correctly
anyway *because `T1` is the one corpus task that requires no test execution.*
That is not a lucky escape; it is why `T1` is the only honest run available here.

**What this costs.** `T3` is the protocol's **primary endpoint**. It is precisely
the task that cannot be run. The tasks that survive are the cheapest and least
informative, which is the opposite of the sampling one would choose.

---

## 4. THE ONE EXECUTED RESULT, WITH ITS CAVEATS ATTACHED

`T1`, run 1, arm B (Build OS installed via `install-project.sh`), unattended,
CLI 2.1.222, models `claude-sonnet-5` + `claude-haiku-4-5`, context window
1,000,000. Seed pinned at `tree_digest_sha256`
`bb52f7b5ebbfc918b005a17a594279557a6249f8a94ba9163dcd70d9462614c2`.

| field | value | how derived |
|---|---|---|
| wall-clock | **29.87 s** (0.50 min) | harness clock around the invocation |
| `duration_api_ms` | 24,041 | CLI result JSON |
| model calls (`num_turns`) | **10** | CLI result JSON |
| cost | **USD 0.2130072** | CLI result JSON |
| input tokens | 14 | CLI result JSON |
| output tokens | 1,544 | CLI result JSON |
| cache-creation tokens | 17,037 | CLI result JSON |
| cache-read tokens | 289,864 | CLI result JSON |
| context window | 1,000,000 | `modelUsage` |
| `time_to_first_correct_change` | **20.37 s** | hidden oracle polled against a tree copy every 5 s |
| subagent dispatches | **0** | stream log, `Agent\|Task` matched |
| files / insertions / deletions | 1 / 1 / 1 | reconstructed from the preserved stream log |
| accepted | **yes** | hidden oracle |
| `human_interventions` | **`-`** | no operator was present to observe any |
| `rework` | **`-`** | not decidable from the final tree; the agent's own account would be a self-report |
| `defects_escaped` | **`-`** | counted only while someone keeps looking; nobody did |

**`time_to_first_correct_change` has a 5-second resolution.** 20.37 s means
"accepted at or before 20.37 s and after 15.37 s". It is an upper bound with a
known granularity, not a precise instant.

**`rounds = 0` and `agents = 0` are measurements, not blanks.** Zero subagent
dispatches were observed. For a `tiny`-lane task that is the *correct* behaviour
— the lane forbids the review chain — so this is Build OS behaving to
specification, not Build OS failing to engage.

**One observation is not a result.** No median, no range, no comparison. The
protocol's own instruction is to report ranges and never point estimates; at
N=1 there is no range, and this figure should be quoted only as "the single
pre-integration observation", never as "the pre-integration speed".

---

## 5. WHY THE ACCEPTANCE CRITERIA CAN BE TRUSTED

`COMPARISON_PROTOCOL.md` constant #5 requires the acceptance criterion to be
defined **before** any run and applied by the same checker to both arms. Here:

- criteria were frozen into the seeded tree (`SPEC-T3.md`'s worked examples,
  `TASKS-T4.md`'s manifest) and into `oracles/oracle.js` **before** any run;
- the oracles are **never copied into the seeded tree** and never named in a task
  prompt, so the agent cannot read or optimise against them;
- the same oracle applies unchanged to both arms — arm-surface paths
  (`.claude/`, `build-os/`, `CLAUDE.md`) are excluded from file-change counts, so
  installing the treatment does not itself alter the score.

**The oracles were proven non-vacuous before use.** An oracle that always accepts
or always rejects would be worse than none:

| check | result |
|---|---|
| all four reject the pristine seed | **REJECT ×4**, each for its own correct reason |
| `T1` accepts a corrected comment (in a `T1`-only tree) | **ACCEPT** |
| `T1` rejects a tree whose pass count moved | **REJECT** |
| `T2` accepts a real fix + a genuinely failing-first test | **ACCEPT** |
| `T2` rejects a test that asserts the buggy value | **REJECT** |
| `T2` rejects a real fix whose added test **passes pre-fix** | **REJECT** |
| `T3` accepts a spec-conformant implementation | **ACCEPT** |
| `T4` accepts three conformant items with the manifest respected | **ACCEPT** |

`T2`'s pre-fix differential is **executed, not asserted**: the candidate's test
directory is transplanted onto the still-buggy source and the suite must fail
there. That is the only way to know the added test would actually have caught the
defect.

---

## 6. LIMITS THE PROTOCOL ALREADY NAMED, WHICH THIS PACKET DOES NOT FIX

Carried forward, unchanged, because none of them were addressed:

- **No blinding is possible**, and the operator here was an agent rather than the
  product's author — which changes who the interested party is, not whether there
  is one.
- **No general multiplier.** One repository, one model, one configuration.
- **No causal attribution to the orchestrator specifically.** Arm B differs from
  arm A by the entire Build OS surface at once.
- **No long-horizon quality measurement.** `defects_escaped` is `-` here for the
  same reason it is `-` in all 27 retrospective rows.
- **The corpus's own blind spot stands:** `task_corpus.md` says it measures
  *building* while the product sells *judgment*, and it has no task for the
  `read-only` or `diagnosis` lanes, no task requiring a defect to be *found*, no
  read-a-lot/write-a-little task, and no task whose right answer is "don't build
  it". Freezing instances for `T1`–`T4` does not narrow that gap by one inch.
