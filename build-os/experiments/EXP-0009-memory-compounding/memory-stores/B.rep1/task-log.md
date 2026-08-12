## B1 — server/governance/control-tower-router.ts
- pattern: TS18046 'error' is of type 'unknown'. (6 occurrences in this file)
- verification: accepted — zero errors remained in the task file, no new errors elsewhere
- provenance: sequence=B rep=1 position=1 run=B1.leanmem.r1 authored_by=harness-distiller

Worker's own report (mechanical 900-char cut):
Done. `server/governance/control-tower-router.ts` now typechecks clean.

The file actually had **9** errors, not 6 — the 6 TS18046 plus three others — and the acceptance bar is zero for the file, so I fixed all nine:

**6× TS18046** (lines 1969, 2002, 2023, 2064, 2095, 2111) — `catch (error: unknown)` then `error.message`. Narrowed with the repo's existing idiom:
```ts
message: error instanceof Error ? error.message : String(error)
```

**TS2339 at 1508** — `(ctx as unknown as Record<string, unknown>).user?.id` made `user` opaque. The tRPC context (`TrpcContext`) already types `user: User | null`, so the cast was both unnecessary and the cause; now plain `ctx.user?.id ?? null`, matching every other call site in the file.

**TS2345 at 1916** — `prefs?.frequency` comes from a `varchar` column, so it's `string`, but `sendDigestForUser` takes `'daily' | 'weekly'`. Narrowed at runtime rather

## B2 — server/governance/behavioral-correctness-audit.ts
- pattern: TS18046 'error' is of type 'unknown'. (5 occurrences in this file)
- verification: accepted — zero errors remained in the task file, no new errors elsewhere
- provenance: sequence=B rep=1 position=2 run=B2.leanmem.r1 authored_by=harness-distiller

Worker's own report (mechanical 900-char cut):
Done. `server/governance/behavioral-correctness-audit.ts` typechecks clean.

All 5 errors were the same shape — `catch (error: unknown)` followed by `error.message`. Narrowed each with the repo's existing idiom:

- **`auditScenario`** (was lines 537, 540) — hoisted `const message = error instanceof Error ? error.message : String(error)` since the value is used twice (`description` and `actual`).
- **`getClaudeAssessment`** (was line 595) — single use, narrowed inline in the template literal.
- **`runBehavioralAudit`** (was lines 627, 630) — same hoisted-`message` treatment, two uses.

No `any`, no suppression directives, no deleted code.

Verification — `npx tsc --noEmit -p tsconfig.json`:

- Target file: **0 errors** (was 5).
- Diff of the full error set against a pre-change baseline (temporarily restored the original from HEAD to measure it): **nothing new anywhere**, and exactly those

## B3 — server/planes/router.ts
- pattern: TS18046 'error' is of type 'unknown'. (3 occurrences in this file)
- verification: accepted — zero errors remained in the task file, no new errors elsewhere
- provenance: sequence=B rep=1 position=3 run=B3.leanmem.r1 authored_by=harness-distiller

Worker's own report (mechanical 900-char cut):
Done. `server/planes/router.ts` typechecks clean.

All three errors were the same shape — `catch (error: unknown)` followed by `error.message` in the failure return. Narrowed each with the repo's existing idiom:

```ts
error: error instanceof Error ? error.message : String(error)
```

The `error` field stays a `string` in the failure branch (as the call sites already assumed), and non-`Error` throws now stringify instead of yielding `undefined` at runtime — so this is a genuine behavioral tightening, not just a compiler appeasement.

Verification — `npx tsc --noEmit -p tsconfig.json`:

- **Target file: 0 errors** (was 3).
- **No new errors anywhere.** I measured a full baseline by temporarily restoring the original file from HEAD, running the compiler, then putting the fix back. Diffing the two sorted error sets: the *only* difference is the three TS18046 lines disappearing (1068 → 1065)

## B4 — server/copilot/batch-page-updater.ts
- pattern: TS18046 'error' is of type 'unknown'. (2 occurrences in this file)
- verification: accepted — zero errors remained in the task file, no new errors elsewhere
- provenance: sequence=B rep=1 position=4 run=B4.leanmem.r1 authored_by=harness-distiller

Worker's own report (mechanical 900-char cut):
Done. `server/copilot/batch-page-updater.ts` typechecks clean.

Both errors were the same shape — `catch (error: unknown)` followed by `error.message`. Narrowed each with the repo's existing idiom:

- **`generatePageUpdate`** (line 147) — the retry log message; narrowed inline in the template literal.
- **`updateSinglePage`** (line 257) — the `reason` field of the failure result. `PageUpdateResult.reason` is `string | undefined`, and the narrowing keeps it a `string`; non-`Error` throws now stringify instead of yielding `undefined` at runtime.

No `any`, no suppression directives, no deleted code.

Verification — `npx tsc --noEmit -p tsconfig.json`:

- **Target file: 0 errors** (was 2).
- **No new errors anywhere.** I measured a real baseline: `git stash` was declined by the permission layer, so I temporarily reverted the two edits in place, ran the compiler, then restored the fix. Diffi

## B5 — server/governance/model-router.ts
- pattern: TS18046 'error' is of type 'unknown'. (2 occurrences in this file)
- verification: accepted — zero errors remained in the task file, no new errors elsewhere
- provenance: sequence=B rep=1 position=5 run=B5.leanmem.r1 authored_by=harness-distiller

Worker's own report (mechanical 900-char cut):
Done.

**Change** — `server/governance/model-router.ts:294` and `:320`, both catch blocks:

```ts
lastError = error instanceof Error ? error.message : String(error);
```

The `catch (error: unknown)` annotations were already correct; the bug was reading `.message` off the unnamed `unknown`. Narrowing with `instanceof Error` (with `String(error)` for non-Error throws) yields a `string`, which matches `lastError: string | undefined`. This matches the existing convention in the repo (e.g. `server/db.ts:129`, `server/rewired-pages.test.ts`).

**Verification** — `npx tsc --noEmit -p tsconfig.json`:
- `server/governance/model-router.ts`: **0 errors** (was 2, both TS18046).
- No new errors elsewhere. The repo has 779 pre-existing errors in unrelated files (`client/src/...`, `drizzle/schema.ts`, other `server/governance/*` files) that I did not touch; the diff is 2 lines inside two catch blocks

