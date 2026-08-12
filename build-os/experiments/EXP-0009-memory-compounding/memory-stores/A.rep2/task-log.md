## A1 — server/emotional-geometry-runtime/alert-analytics.ts
- pattern: TS18047 'db' is possibly 'null'. (16 occurrences in this file)
- verification: accepted — zero errors remained in the task file, no new errors elsewhere
- provenance: sequence=A rep=2 position=1 run=A1.leanmem.r2 authored_by=harness-distiller

Worker's own report (mechanical 900-char cut):
Done. `npx tsc --noEmit -p tsconfig.json` now reports **zero errors** for `server/emotional-geometry-runtime/alert-analytics.ts`, and a before/after diff of the full error set shows **no new errors in any other file** (781 → 764 errors repo-wide; the 17 removed are exactly this file's).

What I changed:

**`server/emotional-geometry-runtime/alert-analytics.ts`** — `getDb()` returns `DrizzleDb | null` (`server/db.ts:144-146`, null when `DATABASE_URL` is unset). Each of the seven exported functions used it without a guard. I added a null check to each, following the pattern already used in the sibling `escalation-engine.ts:125-128` (`log.warn` + return the function's documented fallback):

- `getAlertFrequencyByType` → `[]`
- `getAlertSummaryStats` → zeroed stats
- `groupAlertIntoIncident` → synthetic `inc_nodb_*` id, matching its existing "so the alert isn't lost" contract
- `getIncidents

## A2 — server/infrastructure/data-retention.ts
- pattern: TS18047 'db' is possibly 'null'. (16 occurrences in this file)
- verification: accepted — zero errors remained in the task file, no new errors elsewhere
- provenance: sequence=A rep=2 position=2 run=A2.leanmem.r2 authored_by=harness-distiller

Worker's own report (mechanical 900-char cut):
Done.

`npx tsc --noEmit -p tsconfig.json` reports **zero errors** for `server/infrastructure/data-retention.ts`, and a before/after diff of the full sorted error set shows **16 errors removed and none added anywhere** (781 → 765 repo-wide; the 16 removed are exactly this file's).

**What I changed** — `getDb()` returns `DrizzleDb | null` (`server/db.ts:144-146`, null when `DATABASE_URL` is unset). Four call sites used it unguarded. Each already sits inside a `try`/`catch` that treats DB unavailability as recoverable, so each guard follows that site's own documented fallback:

- `createDSR` (~line 376) — logs `DSR_DB_UNAVAILABLE`, skips the insert, keeps the existing in-memory fallback that the `catch` comment already promises.
- `processExportRequest` (~line 470) — logs `DSR_EXPORT_DB_PARTIAL` (same action code the `catch` uses) and exports in-memory records only; the four DB result arr

## A3 — server/deployment/deployment-persistence.ts
- pattern: TS18047 'db' is possibly 'null'. (14 occurrences in this file)
- verification: accepted — zero errors remained in the task file, no new errors elsewhere
- provenance: sequence=A rep=2 position=3 run=A3.leanmem.r2 authored_by=harness-distiller

Worker's own report (mechanical 900-char cut):
Done.

`npx tsc --noEmit -p tsconfig.json` now reports **zero errors** for `server/deployment/deployment-persistence.ts`, and a before/after diff of the full sorted error set shows **14 errors removed and none added anywhere** (1068 → 1054 repo-wide; the 14 removed are exactly this file's).

**What was wrong:** `getDb()` (`server/db.ts:144-146`) returns `DrizzleDb | null` — null when `DATABASE_URL` is unset, which is a supported configuration, not an error. All 11 exported functions here awaited it and used the result unguarded.

**The fix:** a null guard at each call site, returning that function's own already-documented fallback — every one of these functions already sits inside a `try`/`catch` that treats DB unavailability as recoverable, so the guard just makes the no-DB path explicit instead of routing it through a `TypeError`:

- The four persist functions (`persistDeploymentRecord

## A4 — server/emotional-geometry-runtime/geometry-alerting.ts
- pattern: TS18047 'db' is possibly 'null'. (14 occurrences in this file)
- verification: accepted — zero errors remained in the task file, no new errors elsewhere
- provenance: sequence=A rep=2 position=4 run=A4.leanmem.r2 authored_by=harness-distiller

Worker's own report (mechanical 900-char cut):
Done.

`npx tsc --noEmit -p tsconfig.json` reports **zero errors** for `server/emotional-geometry-runtime/geometry-alerting.ts`. A before/after diff of the full sorted error set shows **15 errors removed, none added anywhere** (781 → 766 repo-wide; the 15 removed are exactly this file's).

**The errors were two kinds, not one.** Alongside the 14 TS18047, line 33 had a TS2345 — `createLogger('geometry-alerting')` used a domain missing from the `LogDomain` union. Since acceptance requires zero errors for the file, I fixed both.

**TS2345** — added `'geometry-alerting'` to the `LogDomain` union in `server/_core/logger.ts:225`. A sibling file works around this with `as LogDomain` (`auto-surface-registration.ts:36`); widening the union is the actual fix and can't break other callers.

**TS18047** — `getDb()` returns `DrizzleDb | null` (`server/db.ts:144-146`, null when `DATABASE_URL` is unset

## A5 — server/router-groups/geometry-admin-router.ts
- pattern: TS18047 'db' is possibly 'null'. (13 occurrences in this file)
- verification: accepted — zero errors remained in the task file, no new errors elsewhere
- provenance: sequence=A rep=2 position=5 run=A5.leanmem.r2 authored_by=harness-distiller

Worker's own report (mechanical 900-char cut):
Done. `npx tsc --noEmit -p tsconfig.json` now reports **zero errors** for `server/router-groups/geometry-admin-router.ts`.

## What I found

The file actually had **24** errors, not 13. The 13 `TS18047` were the headline, but the acceptance bar is zero errors for the file, so I fixed all of them.

## The fixes

**The 13 `TS18047` ('db' is possibly 'null')** — `getDb()` returns `null` when `DATABASE_URL` is unset. Added the repo's existing guard after each of the 7 `await getDb()` call sites:
```ts
if (!db) throw new TRPCError({ code: 'INTERNAL_SERVER_ERROR', message: 'Database unavailable' });
```
(same pattern as `server/governance/tenant-analytics-router.ts`).

**The other 11:**
- `createLogger('geometry-admin-router')` — registered the domain in the `LogDomain` union in `server/_core/logger.ts:224`. This is the only other file I touched; it follows the precedent of commit `b6ade3d` ("

