## A1 — server/emotional-geometry-runtime/alert-analytics.ts
- pattern: TS18047 'db' is possibly 'null'. (16 occurrences in this file)
- verification: accepted — zero errors remained in the task file, no new errors elsewhere
- provenance: sequence=A rep=1 position=1 run=A1.leanmem.r1 authored_by=harness-distiller

Worker's own report (mechanical 900-char cut):
Done. Zero errors in the target file, with no new errors anywhere in the repo.

**What was wrong:** `getDb()` returns `Awaited<...> | null` — it returns `null` when `ENV.databaseUrl` is unset. Every one of the 7 DB-using functions in the file used the handle immediately without checking, giving 16 `TS18047` hits.

**The fix** (`server/emotional-geometry-runtime/alert-analytics.ts`) — a null guard after each `const db = await getDb()`:

```ts
const db = await getDb();
if (!db) throw new DatabaseUnavailableError('Database unavailable: cannot read incidents');
```

This narrows `db` to non-null for the rest of each function and follows the codebase's own precedent — `withTransaction` in `server/db.ts:181` throws the same `DatabaseUnavailableError` for the same condition. Each of these functions already wraps its body in `try/catch` with a degraded fallback (`[]`, zeroed stats, `null`, `fals

## A2 — server/infrastructure/data-retention.ts
- pattern: TS18047 'db' is possibly 'null'. (16 occurrences in this file)
- verification: accepted — zero errors remained in the task file, no new errors elsewhere
- provenance: sequence=A rep=1 position=2 run=A2.leanmem.r1 authored_by=harness-distiller

Worker's own report (mechanical 900-char cut):
Done. `server/infrastructure/data-retention.ts` typechecks clean, with no new errors anywhere.

**The cause:** `getDb()` (`server/db.ts:144`) returns `... | null` — it yields `null` when the DB config is missing. Four functions in this file used the handle immediately without checking, producing 16 `TS18047` hits.

**The fix** — a null guard after each `const db = await getDb()`:

```ts
const db = await getDb();
if (!db) throw new DatabaseUnavailableError("Database unavailable: cannot persist data subject request");
```

This narrows `db` to non-null for the rest of each block and follows the codebase's own precedent: `withTransaction` at `server/db.ts:181` throws the same `DatabaseUnavailableError` for the same condition. Each of the four call sites already sits inside a `try/catch` with a degraded fallback (in-memory-only DSR storage, partial export, logged deletion failure, logged upd

## A3 — server/deployment/deployment-persistence.ts
- pattern: TS18047 'db' is possibly 'null'. (14 occurrences in this file)
- verification: accepted — zero errors remained in the task file, no new errors elsewhere
- provenance: sequence=A rep=1 position=3 run=A3.leanmem.r1 authored_by=harness-distiller

Worker's own report (mechanical 900-char cut):
Done. `server/deployment/deployment-persistence.ts` typechecks clean — the 14 `TS18047` errors are gone and no new error appeared anywhere (total repo errors went 781 → 767, exactly the 14 removed; the pre-existing errors in the consumer files `deployment-router.ts` / `autonomous-experiment-monitor.ts` are unrelated and unchanged).

**The cause:** `getDb()` (`server/db.ts:144`) returns `... | null` — it yields `null` when `ENV.databaseUrl` is unset. All 11 functions in this file used the handle immediately without checking.

**The fix** — a null guard after each `const db = await getDb()`:

```ts
const db = await getDb();
if (!db) throw new DatabaseUnavailableError('Database unavailable: cannot persist deployment record');
```

This narrows `db` to non-null for the rest of each function and follows the codebase's own precedent — `withTransaction` at `server/db.ts:181` throws the same `Da

## A4 — server/emotional-geometry-runtime/geometry-alerting.ts
- pattern: TS18047 'db' is possibly 'null'. (14 occurrences in this file)
- verification: accepted — zero errors remained in the task file, no new errors elsewhere
- provenance: sequence=A rep=1 position=4 run=A4.leanmem.r1 authored_by=harness-distiller

Worker's own report (mechanical 900-char cut):
Done. `server/emotional-geometry-runtime/geometry-alerting.ts` typechecks clean, and no new error appeared anywhere (781 → 766 repo-wide, exactly the 15 removed from the target file — verified by a set-diff of the before/after error lists, not just the count).

The file had **two** distinct problems, not just the 14 TS18047s the brief mentioned:

**1. TS18047 ×14 — `db` possibly null (12 call sites).** `getDb()` (`server/db.ts:144`) returns `null` when `ENV.databaseUrl` is unset. Every DB-using function here dereferenced the handle immediately. Fix — a null guard after each `const db = await getDb()`:

```ts
const db = await getDb();
if (!db) throw new DatabaseUnavailableError('Database unavailable: cannot load alert configs');
```

This narrows `db` for the rest of each block and matches the codebase's own precedent (`withTransaction`, `server/db.ts:181`, throws the same error for the s

## A5 — server/router-groups/geometry-admin-router.ts
- pattern: TS18047 'db' is possibly 'null'. (13 occurrences in this file)
- verification: accepted — zero errors remained in the task file, no new errors elsewhere
- provenance: sequence=A rep=1 position=5 run=A5.leanmem.r1 authored_by=harness-distiller

Worker's own report (mechanical 900-char cut):
Done. `server/router-groups/geometry-admin-router.ts` now reports zero errors.

## What I found

The brief mentioned 13 `TS18047` errors, but the acceptance bar is *zero* errors for the file — and the file actually had **24**. The other 11 were real type defects masking real runtime bugs, so I fixed all 24.

## The fixes

**The 13 `TS18047` (`'db' is possibly 'null'`)** — `getDb()` returns `null` when `DATABASE_URL` is unconfigured. Nine `const db = await getDb()` sites fed that straight into query builders. Added a `requireDb()` helper that throws a `TRPCError` when the handle is null, and pointed all nine sites at it. Every procedure here is DB-backed with no meaningful degraded answer, so surfacing it as a tRPC error is the honest narrowing.

**The other 11** were genuine bugs, not just type noise:

- `recordPostHook(loopDetected, computeTimeMs)` had its **arguments transposed** — the

