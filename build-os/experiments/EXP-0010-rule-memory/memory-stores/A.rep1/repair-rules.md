## RULE TS18047 — 'db' is possibly 'null'.
- applicability: files where tsc reports `TS18047: 'db' is possibly 'null'.`
- confidence: fix of A1 (16 occurrence(s)) NOT accepted
- procedure: when `TS18047: 'db' is possibly 'null'.` fires, apply the demonstrated transform:
```diff
@@ -9,7 +9,7 @@
  */
 
 import { createLogger } from '../_core/logger';
-import { getDb } from '../db';
+import { getDb, DatabaseUnavailableError } from '../db';
 import { geometryAlertHistory, alertIncidents } from '../../drizzle/schema';
 import { eq, and, gte, lte, desc, sql, count, avg, inArray } from 'drizzle-orm';
@@ -72,6 +72,24 @@ export interface IncidentDetail extends IncidentSummary {
   }[];
 }
 
+// ─── Database Handle ──────────────────────────────────────────────
+
+/**
+ * Resolve the database handle for analytics queries.
+ *
+ * `getDb()` returns `null` when no DATABASE_URL is configured, so every query
+ * path here needs a non-null handle. Throwing keeps the unavailable-database
+ * case on the same route as any other query failure: each exported function
+ * already catches, logs, and returns its documented empty/synthetic fallback.
+ */
+async function requireDb(): Promise<NonNullable<Awaited<ReturnType<typeof getDb>>>> {
+  const db = await getDb();
+  if (!db) {
+    throw new DatabaseUnavailableError('Database unavailable: alert analytics requires a database');
+  }
+  return db;
+}
+
 // ─── Incident Grouping Config ─────────────────────────────────────
 
 /** Time window for grouping alerts into incidents (5 minutes) */
```
- provenance: sequence=A rep=1 position=1 run=A1.leanrules.r1 authored_by=harness-rule-distiller

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
@@ -374,6 +374,9 @@ export class DataRetentionService {
     // Persist to database
     try {
       const db = await getDb();
+      if (!db) {
+        throw new DatabaseUnavailableError("Database unavailable: cannot persist DSR");
+      }
       await db.insert(dataSubjectRequests).values({
         id: request.requestId,
         orgId: request.orgId,
```
- provenance: sequence=A rep=1 position=2 run=A2.leanrules.r1 authored_by=harness-rule-distiller

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
@@ -18,6 +18,9 @@ export async function persistDeploymentRecord(record: {
 }): Promise<void> {
   try {
     const db = await getDb();
+    if (!db) {
+      throw new DatabaseUnavailableError('Database unavailable: cannot persist deployment record');
+    }
     await db.insert(deploymentRecords).values({
       deploymentId: record.deploymentId,
       status: record.status,
```
- provenance: sequence=A rep=1 position=3 run=A3.leanrules.r1 authored_by=harness-rule-distiller

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
@@ -199,6 +199,9 @@ let alertIdCounter = 0;
 export async function loadConfigsFromDb(): Promise<void> {
   try {
     const db = await getDb();
+    if (!db) {
+      throw new DatabaseUnavailableError('Database unavailable: cannot load alert configs');
+    }
     const rows = await db.select().from(geometryAlertConfigs);
 
     for (const row of rows) {
```
- provenance: sequence=A rep=1 position=4 run=A4.leanrules.r1 authored_by=harness-rule-distiller

## RULE TS18047 — 'db' is possibly 'null'.
- applicability: files where tsc reports `TS18047: 'db' is possibly 'null'.`
- confidence: fix of A5 (13 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- procedure: when `TS18047: 'db' is possibly 'null'.` fires, apply the demonstrated transform:
```diff
@@ -18,7 +18,7 @@ import { adminProcedure, router } from '../_core/trpc';
 import { getDb } from '../db';
 import { geometrySessions, geometrySnapshots, geometryEvents } from '../../drizzle/schema';
 import { desc, eq, and, gte, count, avg, max, sql } from 'drizzle-orm';
-import { createSafeDefaults, preGenerationHook, postGenerationHook } from '../emotional-geometry-runtime/geometry-runtime-bridge';
+import { createSafeDefaults, preGenerationHook, postGenerationHook, type GeometryPreGenerationResult, type GeometryPostGenerationResult } from '../emotional-geometry-runtime/geometry-runtime-bridge';
 import { getGeometryMetrics, resetGeometryMetrics, recordPreHook, recordPostHook } from '../emotional-geometry-runtime/geometry-metrics';
 import { getFlags, getRuntimeMode, setGeometryFlag, setGeometryRuntimeMode, type GeometryFeatureFlags, type GeometryRuntimeMode } from '../emotional-geometry-runtime/feature-flags';
 import { advancedPreGenerationHook, advancedPostGenerationHook } from '../neurocosmology-runtime-advanced/integration-hooks';
@@ -26,6 +26,26 @@ import { getAdvancedFlagDiagnostics, getAdvancedFlags, getAdvancedRuntimeMode, s
 import { getAlertConfigs, getAlertConfig, setAlertThreshold, setAlertEnabled, setAlertCooldown, setAlertSeverity, resetAlertConfigs, getAlertHistory, getAlertHistoryFromDb, acknowledgeAlert, acknowledgeAlertPersistent, getAlertSummary, getUnacknowledgedCount, getNotificationChannels, createNotificationChannel, updateNotificationChannel, deleteNotificationChannel, evaluateAlerts, ALERT_TYPES, type AlertType, type AlertSeverity } from '../emotional-geometry-runtime/geometry-alerting';
 import { getEscalationPolicies, createEscalationPolicy, updateEscalationPolicy, deleteEscalationPolicy, getEscalationHistory, runEscalationCheck, isEscalationEngineRunning, getSSEClientCount, type EscalationPolicyConfig } from '../emotional-geometry-runtime/escalation-engine';
 import { getAlertFrequencyByType, getAlertSummaryStats, getIncidents, getIncidentDetail, resolveIncident, acknowledgeIncident } from '../emotional-geometry-runtime/alert-analytics';
+import { createInitialState, updateBaseDimensions } from '../emotional-geometry-runtime/state/EmotionalState';
+
+/**
+ * Resolve the database handle for an admin request.
+ *
+ * `getDb()` returns null when DATABASE_URL is unset, so every endpoint below
+ * that reads geometry tables needs a handle that is known to be non-null.
+ * Admin dashboards must not render zeros that look like real measurements when
+ * the database is simply absent, so an unconfigured database fails the request.
+ */
+async function requireDb() {
+  const db = await getDb();
+  if (!db) {
+    throw new TRPCError({
+      code: 'INTERNAL_SERVER_ERROR',
+      message: 'Database unavailable: geometry admin data cannot be read',
+    });
+  }
+  return db;
+}
 
 export const geometryAdminRouter = router({
   // =========================================================================
```
- provenance: sequence=A rep=1 position=5 run=A5.leanrules.r1 authored_by=harness-rule-distiller

