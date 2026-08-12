## B1 — server/governance/control-tower-router.ts
- pattern: TS18046 'error' is of type 'unknown'. (6 occurrences in this file)
- verification: accepted — zero errors remained in the task file, no new errors elsewhere
- provenance: sequence=B rep=2 position=1 run=B1.leanmem.r2 authored_by=harness-distiller

Worker's own report (mechanical 900-char cut):
Done. `server/governance/control-tower-router.ts` now reports **zero** typecheck errors, and the before/after diff of the full `tsc` output shows **no new error anywhere else** (the only change is the 9 errors removed).

The file actually had 9 errors, not the 6 stated in the task — the 6 `TS18046` plus three others. Since acceptance requires zero errors in the file, I fixed all nine:

**The 6 `TS18046`** (`server/governance/control-tower-router.ts:1969` and 5 siblings) — `catch (error: unknown)` followed by `error.message`. Narrowed with the idiom already used elsewhere in the codebase (`server/rewired-pages.test.ts`): `error instanceof Error ? error.message : String(error)`.

**`TS2339` at :1508** — `(ctx as unknown as Record<string, unknown>).user?.id`. That cast was the bug: it threw away the real context type, so `.user` came back as an index signature value with no `id`. `TrpcConte

## B2 — server/governance/behavioral-correctness-audit.ts
- pattern: TS18046 'error' is of type 'unknown'. (5 occurrences in this file)
- verification: accepted — zero errors remained in the task file, no new errors elsewhere
- provenance: sequence=B rep=2 position=2 run=B2.leanmem.r2 authored_by=harness-distiller

Worker's own report (mechanical 900-char cut):
Done. `server/governance/behavioral-correctness-audit.ts` reports **zero** typecheck errors, and a before/after diff of the full `tsc` output shows the only change is those 5 errors disappearing — no new error anywhere else.

All 5 `TS18046` were the same shape: `catch (error: unknown)` followed by `error.message`. In each catch block I narrowed once into a local, using the idiom already present in this codebase:

```ts
const message = error instanceof Error ? error.message : String(error);
```

- `auditScenario`'s per-message catch (`:531`) — narrowed once, used for both `description` and `actual`.
- `getClaudeAssessment`'s catch (`:593`) — narrowed after the existing `generalLog.error(...)` call, which takes the raw `unknown` and is unaffected.
- `runBehavioralAudit`'s per-scenario catch (`:621`) — narrowed once, used for `description` and `actual`.

No suppression comments, no `any`,

## B3 — server/planes/router.ts
- pattern: TS18046 'error' is of type 'unknown'. (3 occurrences in this file)
- verification: accepted — zero errors remained in the task file, no new errors elsewhere
- provenance: sequence=B rep=2 position=3 run=B3.leanmem.r2 authored_by=harness-distiller

Worker's own report (mechanical 900-char cut):
Done. `server/planes/router.ts` reports **zero** typecheck errors, and a before/after diff of the full `tsc` output shows the only change is those 3 errors disappearing — **no new error anywhere else** (1068 → 1065 total, all three removed lines belonging to the target file).

All 3 `TS18046` were the same shape: `catch (error: unknown)` followed by `error.message` in the failure-return object. Each was narrowed with the idiom already used elsewhere in this codebase:

```ts
error: error instanceof Error ? error.message : String(error)
```

- `getControlPlaneOrgs` (`:39`)
- `getDataPlaneStats` (`:69`)
- `getAuditEntries` (`:103`)

The `catch (error: unknown)` annotations are left as-is — they were already correct; only the unguarded property access was wrong. No suppression comments, no `any`, no deleted code; the returned `error` field stays a `string` in the failure branch, so the proce

## B4 — server/copilot/batch-page-updater.ts
- pattern: TS18046 'error' is of type 'unknown'. (2 occurrences in this file)
- verification: accepted — zero errors remained in the task file, no new errors elsewhere
- provenance: sequence=B rep=2 position=4 run=B4.leanmem.r2 authored_by=harness-distiller

Worker's own report (mechanical 900-char cut):
Done. `server/copilot/batch-page-updater.ts` reports **zero** typecheck errors, and the before/after diff of the full `tsc` output shows the only change is those 2 errors disappearing — **no new error anywhere else** (1068 → 1066, both removed lines belonging to the target file).

Both `TS18046` were the same shape: `catch (error: unknown)` followed by an unguarded `error.message`. Each was narrowed with the idiom already used elsewhere in this codebase:

- `generatePageUpdate`'s retry catch (`:147`) — the log interpolation now uses `error instanceof Error ? error.message : String(error)`.
- `updateSinglePage`'s catch (`:257`) — the `reason` field of the failure result uses the same narrowing, so it stays a `string` and still satisfies `PageUpdateResult.reason?: string`.

The `catch (error: unknown)` annotations were left as-is — they were already correct; only the property access was wr

## B5 — server/governance/model-router.ts
- pattern: TS18046 'error' is of type 'unknown'. (2 occurrences in this file)
- verification: accepted — zero errors remained in the task file, no new errors elsewhere
- provenance: sequence=B rep=2 position=5 run=B5.leanmem.r2 authored_by=harness-distiller

Worker's own report (mechanical 900-char cut):
Done.

**Fix** — `server/governance/model-router.ts:294` and `:320`. Both are `catch (error: unknown)` blocks that read `error.message` directly. Narrowed each with the repo's existing idiom (used in `scale-testing.ts`, `zapier-async-queue.ts`, `gravito-external-client.ts`, and others):

```ts
lastError = error instanceof Error ? error.message : String(error);
```

`lastError` is typed `string | undefined`, so both branches fit without a cast. No suppression comments, no `any`, no code removed — and `String(error)` means a thrown non-Error (a string, a rejected value) now yields a usable message instead of `undefined`.

**Verification** — `npx tsc --noEmit -p tsconfig.json`, diffed against a baseline built from the HEAD version of the file:

- `model-router.ts`: **0 errors** (was 2).
- Whole-project error count: 781 → 779. The diff of the two full compiler outputs shows exactly two remov

