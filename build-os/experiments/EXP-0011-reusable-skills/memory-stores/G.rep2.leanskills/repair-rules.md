## RULE TS2305+TS2339 — Module '"../../shared/governance-types"' has no exported member 'AuthorityAuditEntry'.
- applicability: files where tsc reports any of: TS2305, TS2339 (subsystem server/governance/)
- confidence: fix of G1 (32 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- toolseq: Bash>Read>Bash>Read>Bash>Read>Edit>Bash>Edit>Read>Edit>Bash
- procedure: when these codes fire, apply the demonstrated transform:
```diff
@@ -27,10 +27,36 @@ import { getExternalTransportStatus, getTransportMetrics, exportPrometheusMetric
 import { getAuthorityMetrics, getAuthorityLayerHealth, getAuthorityAuditTrail } from './gravito-authority-layer';
 import { getExternalGravitoHealth } from './gravito-external-client';
 import { getPreApprovalMetrics, REGULATED_SURFACES } from './regulated-surface-preapproval';
-import { getSyncWrapperMetrics } from './mcp-sync-wrapper';
+import { getSyncWrapperMetrics, listJobs } from './mcp-sync-wrapper';
 import { getAuthorityAuditEntries, getAuthorityAuditStats } from '../db';
 import { getGovernanceUptimeMetrics, getInlineMetrics, getCircuitBreakerState, getAuthorityAuditSummary } from './co-processor/gravito-inline-client';
-import type { AuthorityAuditEntry, TransportMetrics, ExternalGravitoHealth, SyncWrapperMetrics, AuthorityLayerHealth, InlineMetrics, AuthorityAuditSummaryEntry } from '../../shared/governance-types';
+import type { TransportMetrics } from './production-transport-selector';
+import type { AuthorityLayerHealth } from './gravito-authority-layer';
+import type { GravitoExternalHealthMetrics } from './gravito-external-client';
+import type { SyncWrapperMetrics } from './mcp-sync-wrapper';
+import type { GovernanceAuthorityAuditRow } from '../../drizzle/schema';
+
+// ============================================================================
+// SHARED DERIVATIONS
+// ============================================================================
+
+/**
+ * The authority layer reports an overall status plus the external client's own
+ * health; the dashboard shows three booleans. Internal governance runs
+ * in-process, so it is reachable whenever the layer itself is not unavailable.
+ */
+function describeAuthorityReachability(health: AuthorityLayerHealth): {
+  enabled: boolean;
+  externalReachable: boolean;
+  internalReachable: boolean;
+} {
+  const operational = health.status !== 'unavailable';
@@ -38,9 +64,15 @@ import type { AuthorityAuditEntry, TransportMetrics, ExternalGravitoHealth, Sync
 
 const transportHealthProcedure = adminProcedure.query(async () => {
   const status = getExternalTransportStatus();
-  const metrics = getTransportMetrics();
-  const externalHealth = getExternalGravitoHealth();
-  const syncMetrics = getSyncWrapperMetrics();
+  const metrics: TransportMetrics = getTransportMetrics();
+  const externalHealth: GravitoExternalHealthMetrics = getExternalGravitoHealth();
+  const syncMetrics: SyncWrapperMetrics = getSyncWrapperMetrics();
+
+  // TransportMetrics counts successes and failures separately; the dashboard
+  // reports the combined call volume.
+  const transportCalls = metrics.successesTotal + metrics.failuresTotal;
+  // Jobs still running (not completed / failed / cancelled / timed out).
+  const activeJobs = listJobs({ statusFilter: 'running', limit: 1000 }).length;
 
   return {
     // Current state
```
- provenance: sequence=G rep=2 position=1 run=G1.leanskills.r2 authored_by=harness-rule-distiller

## RULE TS18046 — 'e' is of type 'unknown'.
- applicability: files where tsc reports any of: TS18046 (subsystem server/governance/)
- confidence: fix of G2 (31 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- toolseq: Bash>Read>Skill>Bash>Edit>Bash>Read
- procedure: when these codes fire, apply the demonstrated transform:
```diff
@@ -28,6 +28,15 @@ function record(category: string, claim: string, passed: boolean, evidence: stri
   results.push({ category, claim, passed, evidence, details });
 }
 
+/**
+ * Catch clauses bind `unknown` — a thrown value is not guaranteed to be an
+ * Error. The audit only ever reports the message as evidence, so narrow to
+ * Error and fall back to the value's own string form.
+ */
+function errorMessage(e: unknown): string {
+  return e instanceof Error ? e.message : String(e);
+}
+
 async function runAudit() {
   governanceLog.info('═══════════════════════════════════════════════════════════════');
   governanceLog.info('  STRUCTURAL PROOF AUDIT v2 — EVERY CLAIM TESTED WITH EXECUTION');
@@ -50,7 +59,7 @@ async function runAudit() {
       missing.length === 0 ? `Found all: ${required.join(', ')}` : `Missing: ${missing.join(', ')}`,
       { allExports: exports });
   } catch (e: unknown) {
-    record('IMPORTS', 'meaning-interpreter.ts is importable', false, `Import failed: ${e.message}`);
+    record('IMPORTS', 'meaning-interpreter.ts is importable', false, `Import failed: ${errorMessage(e)}`);
   }
 
   // 1b. Human Interaction Model
```
- provenance: sequence=G rep=2 position=2 run=G2.leanskills.r2 authored_by=harness-rule-distiller

## RULE TS2305+TS2322+TS2339+TS2353+TS2454+TS2488+TS2554+TS2739+TS2769+TS7006 — Module '"./types"' has no exported member 'BusinessTruth'.
- applicability: files where tsc reports any of: TS2305, TS2322, TS2339, TS2353, TS2454, TS2488, TS2554, TS2739, TS2769, TS7006 (subsystem server/governance/)
- confidence: fix of G3 (24 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- toolseq: Read>Bash>Skill>Bash>Read>Bash>Edit>Bash
- procedure: when these codes fire, apply the demonstrated transform:
```diff
@@ -21,14 +21,13 @@ import type {
   DiscoveryConfigData,
   SweepEvaluation,
   SweepResult,
+  SweepTriggerType,
   ChangeDetectionResult,
   DiscoveredSurfaceData,
   AdapterConfig,
   SurfaceType,
-  BusinessTruth,
 } from './types';
 import { DiscoveryStatus } from './types';
-import { remediateSweepResults } from './remediation';
 import { gatedRemediateSweepResults } from './gravito-gate';
 import { evaluateCompletenessGate } from './completeness-gate';
 import { getBusinessTruthContext } from '../../services/truth-context-provider';
@@ -68,7 +67,9 @@ export async function runDiscovery(customerId: string, config: DiscoveryConfigDa
     customerId,
     adapterType: config.adapters.map(a => a.type).join(','),
     status: 'running',
-    startedAt: new Date(startTime),
+    // discovery_runs.startedAt / .completedAt are bigint epoch-millis columns,
+    // not timestamps — store the raw millisecond value.
+    startedAt: startTime,
   });
 
   // Run each enabled adapter
```
- provenance: sequence=G rep=2 position=3 run=G3.leanskills.r2 authored_by=harness-rule-distiller

