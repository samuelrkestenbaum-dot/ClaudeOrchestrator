# EXP-0005 — frozen task set

Selected mechanically by `select-tasks.mjs` executing `SELECTION-RULE.md`, at
seed `2543c87`. Every candidate considered, and the reason it was admitted or
excluded, is in `SELECTION.json` — 1,984 exclusions recorded, not summarised.

**12 tasks across 4 shapes**, above the registered minimum of 10.

## The set

| id | shape | target | what is wrong |
|---|---|---|---|
| T01 | behavioural | `server/agent/agent.test.ts` | `AgentPlanner should create a plan with registered artifacts` |
| T02 | behavioural | `server/agent/mcp/mcp-enforcement.test.ts` | `ToolRouter Content Classification should classify generic content correctly` |
| T03 | behavioural | `server/agent/mcp/policy-resolver.test.ts` | `PolicyResolver resolvePolicy should include forbidden phrases from business_truth.yaml` |
| T04 | type_defect | `server/agent/mcp/unified-gravito-api.ts:374` | TS2571 `Object is of type 'unknown'` |
| T05 | type_defect | `server/deployment/cms-content-layer.ts:76` | TS18047 `'db' is possibly 'null'` |
| T06 | type_defect | `server/deployment/deployment-persistence.ts:21` | TS18047 `'db' is possibly 'null'` |
| T07 | test_reliability | `server/architectural-fixes.test.ts:252` | `test.todo('should be wired into server startup …')` |
| T08 | test_reliability | `server/brand-alignment.test.ts:12` | `test.todo('leads with AI governance positioning …')` |
| T09 | test_reliability | `server/chaos-engineering.test.ts:90` | `test.todo("db.ts getDb() handles missing DATABASE_URL gracefully")` |
| T10 | suppression | `server/agent/enforced-quality-pipeline.ts:583` | `// @ts-ignore - auto-fixed` |
| T11 | suppression | `server/agent/mcp/batch-audit.ts:227` | `// @ts-ignore - auto-fixed` |
| T12 | suppression | `server/agent/mcp/claim-intent-classification.ts:430` | `// @ts-ignore — TS2339 interface drift` |

Quota held: 3 per shape (limit 3), and TS codes `TS2571`×1, `TS18047`×2 (limit
2 per code).

## Acceptance, frozen per shape, IDENTICAL in both arms

Every task additionally carries the standing prohibition, binding since
PILOT-0002 T4: **no `any` cast, `@ts-ignore`, `@ts-expect-error` or fabricated
interface used to silence rather than fix.** A false type declaration is worse
than an `any`.

**behavioural (T01–T03)** — the named test passes:
`npx vitest run <file> -t "<test name>"`.
Regression bound: the **845 stable failures do not grow**, and no test outside
the quarantined files moves from pass to fail.

**type_defect (T04–T06)** — the named error at that file and line is gone from
`npx tsc -p tsconfig.app.json --noEmit`; total error count **strictly below
754**; **zero new errors**, measured LINE-INSENSITIVELY (PILOT-0002 recorded 21
false positives from a naive sorted diff after a fix inserted lines).

**test_reliability (T07–T09)** — the `test.todo` becomes a real test that
**passes**, and its file's other results are unchanged. A `todo` deleted rather
than implemented is a **fail**.

**suppression (T10–T12)** — the directive is **removed** and `tsc` total does
not increase. Moving the suppression, or widening a type to `any` to survive its
removal, is a **fail**.

## Shape shortfall — `implementation_gap` is NOT viable here, and this is why

The rule anticipated five shapes. Only four survive.

`SELECTION-RULE.md` recorded an `implementation_gap` population of **10**. That
count is wrong, and it was wrong when it was recorded: **7 of the 10 are
governance detector documentation** — section headings inside `// ====` banners
such as

    // TODO/stub responses in API handlers
    // TODO, FIXME, HACK, governanceLog.info, @ts-ignore in production code

sitting directly above `pattern: /TODO|FIXME/i`. They describe what a scanner
looks for **elsewhere**. There is nothing in them to fix, and a benchmark task
cut from one would have measured nothing.

After restricting to the actionable `TODO:` / `TODO(ID):` form the population is
**3**, and all three were excluded for recorded reasons:

| candidate | verdict |
|---|---|
| `server/governance/structural-integrity-validator.test.ts:552` | leakage — durable state references this file |
| `server/gravito/code-action-assertions.ts:159` | leakage — durable state references this file |
| `server/routes/gravito-mcp-routes.ts:1254` | **hard exclusion — belongs to EXP-0004's frozen E1–E5 set** |

So the shape is reported absent **with its cause**, rather than padded to make
the mix look like the plan. Twelve tasks over four shapes still clears the
registered minimum and still breaks EXP-0004's monoculture, which was five
variants of one pattern.

## False positives the first selection would have admitted

Recorded because a mechanical rule is only as good as its query, and three of
these would have produced tasks with nothing to fix:

| admitted at first | why it was wrong |
|---|---|
| `* Now: converted to test.todo() since …` | a comment **describing** a todo |
| a doc line explaining `` `// @ts-nocheck` `` | a suppression **described**, not applied |
| `TODO` inside a string array of acronyms | not a comment at all |
| `should have GITHUB_APP_ID configured` | fails for a **missing secret**; the only remedy is a credential |
| `should have a valid RSA private key format` | same, but the test **name** never says so — it reads `process.env.GITHUB_APP_PRIVATE_KEY` |

The last one is why the credential filter works at **file** granularity: a
name-based filter cannot see a secret the name does not mention.

## Provenance of the E1–E5 hard exclusion

`SELECTION-RULE.md` hard-excludes EXP-0004's frozen set, but `TASK_FREEZE.md`
records **cluster IDs only** — no file paths — and EXP-0004 committed no
`candidates.json`. The exclusion therefore could not run.

The sets were re-derived by running the eligibility procedure at the seed
(`assess-repo.sh --deterministic`). This is a recomputation, **not a re-run of
EXP-0004**, and it reproduces the frozen record exactly:

| | recorded | re-derived |
|---|---|---|
| `no_parser` | 679/3390 (20.0%) | 679/3390 (20.0%) |
| tsc errors | 754 | 754 |
| CAND-0009 → E1 | 15 err / 6 files / TS2769 | identical |
| CAND-0010 → E2 | 13 err / 8 files / TS2353 | identical |
| CAND-0013 → E3 | 8 err / 8 files / TS2307 | identical |
| CAND-0016 → E4 | 6 err / 4 files / TS2554 | identical |
| CAND-0018 → E5 | 5 err / 4 files / TS7006 | identical |

**One discrepancy remains unresolved.** `TASK_FREEZE.md` prose says the backlog
held **27** candidates; this derivation yields **28**, from identical inputs and
an exclusions file that predates the freeze and has never changed. EXP-0004
committed no candidate list, so the gap is **not resolvable from frozen
evidence**, and EXP-0004 is frozen and was not touched to investigate it.

Mitigation, stated rather than assumed: the exclusion set carries the **union**
of E1–E5's 24 files **and** all 133 files of the 9 prior-pilot-excluded clusters
— 143 files. A mis-identified 28th cluster is very likely already inside that
union, and the leakage check runs on top of it.

## Behavioural pool — stable failures only

Drawn from the 845 failures that reproduced in **both** independent passes.
The 10 unstable tests, and every test in the 8 files carrying one, are excluded:
a flaky test cannot be an admissible task, because acceptance would not be
objectively determinable.

## Not frozen yet

This is the task set. The **preregistration is not frozen** and the **mapping is
not sealed** — 6 of 8 readiness items. **Nothing executes.**
