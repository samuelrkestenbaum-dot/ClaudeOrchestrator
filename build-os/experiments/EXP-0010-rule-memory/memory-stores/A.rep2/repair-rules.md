## RULE TS18047 — 'db' is possibly 'null'.
- applicability: files where tsc reports `TS18047: 'db' is possibly 'null'.`
- confidence: fix of A1 (16 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- procedure: when `TS18047: 'db' is possibly 'null'.` fires, apply the demonstrated transform:
```diff
@@ -9,7 +9,7 @@
  */
 
 import { createLogger } from '../_core/logger';
-import { getDb } from '../db';
+import { getDb, DatabaseUnavailableError } from '../db';
 import { geometryAlertHistory, alertIncidents } from '../../drizzle/schema';
 import { eq, and, gte, lte, desc, sql, count, avg, inArray } from 'drizzle-orm';
@@ -88,6 +88,7 @@ export async function getAlertFrequencyByType(options: {
 }): Promise<AlertTrend[]> {
   try {
     const db = await getDb();
+    if (!db) throw new DatabaseUnavailableError('Database unavailable: cannot read alert frequency');
     const since = Date.now() - options.days * 24 * 60 * 60 * 1000;
 
     // Query raw data from alert history
```
- provenance: sequence=A rep=2 position=1 run=A1.leanrules.r2 authored_by=harness-rule-distiller

## RULE TS18047 — 'db' is possibly 'null'.
- applicability: files where tsc reports `TS18047: 'db' is possibly 'null'.`
- confidence: fix of A2 (16 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- procedure: when `TS18047: 'db' is possibly 'null'.` fires, apply the demonstrated transform:
```diff
@@ -12,7 +12,7 @@
  */
 
 import crypto from "crypto";
-import { getDb } from "../db";
+import { getDb, DatabaseUnavailableError } from "../db";
 import { eq, and } from "drizzle-orm";
 import {
   dataSubjectRequests,
@@ -374,6 +374,7 @@ export class DataRetentionService {
     // Persist to database
     try {
       const db = await getDb();
+      if (!db) throw new DatabaseUnavailableError("Database unavailable: cannot persist data subject request");
       await db.insert(dataSubjectRequests).values({
         id: request.requestId,
         orgId: request.orgId,
```
- provenance: sequence=A rep=2 position=2 run=A2.leanrules.r2 authored_by=harness-rule-distiller

## RULE TS18047 — 'db' is possibly 'null'.
- applicability: files where tsc reports `TS18047: 'db' is possibly 'null'.`
- confidence: fix of A3 (14 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- procedure: when `TS18047: 'db' is possibly 'null'.` fires, apply the demonstrated transform:
```diff
@@ -1,4 +1,4 @@
-import { getDb } from '../db';
+import { getDb, DatabaseUnavailableError } from '../db';
 import { createLogger } from '../_core/logger';
 
 const logger = createLogger('database', { component: 'DeploymentPersistence' });
@@ -18,6 +18,7 @@ export async function persistDeploymentRecord(record: {
 }): Promise<void> {
   try {
     const db = await getDb();
+    if (!db) throw new DatabaseUnavailableError('Database unavailable: cannot persist deployment record');
     await db.insert(deploymentRecords).values({
       deploymentId: record.deploymentId,
       status: record.status,
```
- provenance: sequence=A rep=2 position=3 run=A3.leanrules.r2 authored_by=harness-rule-distiller

## RULE TS18047 — 'db' is possibly 'null'.
- applicability: files where tsc reports `TS18047: 'db' is possibly 'null'.`
- confidence: fix of A4 (14 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- procedure: when `TS18047: 'db' is possibly 'null'.` fires, apply the demonstrated transform:
```diff
@@ -24,7 +24,7 @@
 
 import { createLogger } from '../_core/logger';
 import { notifyOwner } from '../_core/notification';
-import { getDb } from '../db';
+import { getDb, DatabaseUnavailableError } from '../db';
 import { geometryEvents, geometryAlertConfigs, geometryAlertHistory, notificationChannels } from '../../drizzle/schema';
 import { eq, desc, and, sql } from 'drizzle-orm';
 import { groupAlertIntoIncident } from './alert-analytics';
@@ -199,6 +199,7 @@ let alertIdCounter = 0;
 export async function loadConfigsFromDb(): Promise<void> {
   try {
     const db = await getDb();
+    if (!db) throw new DatabaseUnavailableError('Database unavailable: cannot load alert configs');
     const rows = await db.select().from(geometryAlertConfigs);
 
     for (const row of rows) {
```
- provenance: sequence=A rep=2 position=4 run=A4.leanrules.r2 authored_by=harness-rule-distiller

## RULE TS18047 — 'db' is possibly 'null'.
- applicability: files where tsc reports `TS18047: 'db' is possibly 'null'.`
- confidence: fix of A5 (13 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- procedure: when `TS18047: 'db' is possibly 'null'.` fires, apply the demonstrated transform:
```diff
@@ -18,7 +18,8 @@ import { adminProcedure, router } from '../_core/trpc';
 import { getDb } from '../db';
 import { geometrySessions, geometrySnapshots, geometryEvents } from '../../drizzle/schema';
 import { desc, eq, and, gte, count, avg, max, sql } from 'drizzle-orm';
-import { createSafeDefaults, preGenerationHook, postGenerationHook } from '../emotional-geometry-runtime/geometry-runtime-bridge';
+import { createSafeDefaults, preGenerationHook, postGenerationHook, type GeometryPreGenerationResult, type GeometryPostGenerationResult } from '../emotional-geometry-runtime/geometry-runtime-bridge';
+import { createInitialState, updateBaseDimensions, type CanonicalEmotionalState } from '../emotional-geometry-runtime/state/EmotionalState';
 import { getGeometryMetrics, resetGeometryMetrics, recordPreHook, recordPostHook } from '../emotional-geometry-runtime/geometry-metrics';
 import { getFlags, getRuntimeMode, setGeometryFlag, setGeometryRuntimeMode, type GeometryFeatureFlags, type GeometryRuntimeMode } from '../emotional-geometry-runtime/feature-flags';
 import { advancedPreGenerationHook, advancedPostGenerationHook } from '../neurocosmology-runtime-advanced/integration-hooks';
@@ -27,6 +28,44 @@ import { getAlertConfigs, getAlertConfig, setAlertThreshold, setAlertEnabled, se
 import { getEscalationPolicies, createEscalationPolicy, updateEscalationPolicy, deleteEscalationPolicy, getEscalationHistory, runEscalationCheck, isEscalationEngineRunning, getSSEClientCount, type EscalationPolicyConfig } from '../emotional-geometry-runtime/escalation-engine';
 import { getAlertFrequencyByType, getAlertSummaryStats, getIncidents, getIncidentDetail, resolveIncident, acknowledgeIncident } from '../emotional-geometry-runtime/alert-analytics';
 
+/**
+ * Resolve the database handle for the geometry dashboard.
+ *
+ * `getDb()` returns `null` when no DATABASE_URL is configured. Every procedure
+ * below reads persisted geometry history, so there is no meaningful degraded
+ * answer — surface the missing dependency as a 503 instead of letting a null
+ * handle reach a query builder.
+ */
+async function requireDb(): Promise<NonNullable<Awaited<ReturnType<typeof getDb>>>> {
+  const db = await getDb();
+  if (!db) {
+    throw new TRPCError({
+      code: 'SERVICE_UNAVAILABLE',
+      message: 'Database unavailable: geometry admin data requires a configured database',
+    });
+  }
+  return db;
+}
+
+/**
+ * Lift a flat geometry state snapshot into the canonical emotional state the
+ * neurocosmology hooks expect. Mirrors the mapping used by the governed
+ * generation pipeline so diagnostics exercise the same shape as production.
+ */
+function buildCanonicalState(
+  snapshot: Record<string, number> | undefined,
```
- provenance: sequence=A rep=2 position=5 run=A5.leanrules.r2 authored_by=harness-rule-distiller

