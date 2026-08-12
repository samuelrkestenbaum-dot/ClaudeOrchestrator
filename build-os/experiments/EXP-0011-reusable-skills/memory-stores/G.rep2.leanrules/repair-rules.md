## RULE TS2305+TS2339 — Module '"../../shared/governance-types"' has no exported member 'AuthorityAuditEntry'.
- applicability: files where tsc reports any of: TS2305, TS2339 (subsystem server/governance/)
- confidence: fix of G1 (32 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- toolseq: Read>Bash>Read>Bash>Read>Bash>Read>Edit>Bash
- procedure: when these codes fire, apply the demonstrated transform:
```diff
@@ -27,21 +27,27 @@ import { getExternalTransportStatus, getTransportMetrics, exportPrometheusMetric
 import { getAuthorityMetrics, getAuthorityLayerHealth, getAuthorityAuditTrail } from './gravito-authority-layer';
 import { getExternalGravitoHealth } from './gravito-external-client';
 import { getPreApprovalMetrics, REGULATED_SURFACES } from './regulated-surface-preapproval';
-import { getSyncWrapperMetrics } from './mcp-sync-wrapper';
+import { getSyncWrapperMetrics, listJobs } from './mcp-sync-wrapper';
 import { getAuthorityAuditEntries, getAuthorityAuditStats } from '../db';
 import { getGovernanceUptimeMetrics, getInlineMetrics, getCircuitBreakerState, getAuthorityAuditSummary } from './co-processor/gravito-inline-client';
-import type { AuthorityAuditEntry, TransportMetrics, ExternalGravitoHealth, SyncWrapperMetrics, AuthorityLayerHealth, InlineMetrics, AuthorityAuditSummaryEntry } from '../../shared/governance-types';
+import type { AuthorityAuditEntry } from '../../shared/governance-types';
 
 // ============================================================================
 // PANEL 1: TRANSPORT HEALTH
 // ============================================================================
 
+/** Upper bound on jobs the sync wrapper keeps in its active-job table. */
+const MAX_TRACKED_JOBS = 100;
+
 const transportHealthProcedure = adminProcedure.query(async () => {
   const status = getExternalTransportStatus();
   const metrics = getTransportMetrics();
   const externalHealth = getExternalGravitoHealth();
   const syncMetrics = getSyncWrapperMetrics();
 
+  // The transport tracks successes and failures separately; total is their sum.
+  const totalTransportCalls = metrics.successesTotal + metrics.failuresTotal;
+
   return {
     // Current state
     transport: {
@@ -55,39 +61,41 @@ const transportHealthProcedure = adminProcedure.query(async () => {
 
     // Performance metrics
     performance: {
-      totalCalls: metrics.totalCalls,
-      successCount: metrics.successCount,
-      failureCount: metrics.failureCount,
-      successRate: metrics.totalCalls > 0
-        ? Math.round((metrics.successCount / metrics.totalCalls) * 10000) / 100
+      totalCalls: totalTransportCalls,
+      successCount: metrics.successesTotal,
+      failureCount: metrics.failuresTotal,
+      successRate: totalTransportCalls > 0
+        ? Math.round((metrics.successesTotal / totalTransportCalls) * 10000) / 100
         : 0,
       latency: {
         p50: metrics.latencyP50Ms,
         p95: metrics.latencyP95Ms,
         p99: metrics.latencyP99Ms,
       },
-      transportSwitches: metrics.transportSwitches,
+      transportSwitches: metrics.transportSwitchCount,
     },
 
     // External client health
     externalClient: {
       circuitBreakerState: externalHealth.circuitBreakerState,
       totalCalls: externalHealth.totalCalls,
-      successRate: externalHealth.successRate,
+      successRate: externalHealth.totalCalls > 0
```
- provenance: sequence=G rep=2 position=1 run=G1.leanrules.r2 authored_by=harness-rule-distiller

## RULE TS18046 — 'e' is of type 'unknown'.
- applicability: files where tsc reports any of: TS18046 (subsystem server/governance/)
- confidence: fix of G2 (31 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- toolseq: Read>Bash>Edit>Bash>Edit>Bash
- procedure: when these codes fire, apply the demonstrated transform:
```diff
@@ -24,6 +24,10 @@ interface ProofResult {
 
 const results: ProofResult[] = [];
 
+function errorMessage(e: unknown): string {
+  return e instanceof Error ? e.message : String(e);
+}
+
 function record(category: string, claim: string, passed: boolean, evidence: string, details?: any) {
   results.push({ category, claim, passed, evidence, details });
 }
@@ -50,7 +54,7 @@ async function runAudit() {
       missing.length === 0 ? `Found all: ${required.join(', ')}` : `Missing: ${missing.join(', ')}`,
       { allExports: exports });
   } catch (e: unknown) {
-    record('IMPORTS', 'meaning-interpreter.ts is importable', false, `Import failed: ${e.message}`);
+    record('IMPORTS', 'meaning-interpreter.ts is importable', false, `Import failed: ${errorMessage(e)}`);
   }
 
   // 1b. Human Interaction Model
```
- provenance: sequence=G rep=2 position=2 run=G2.leanrules.r2 authored_by=harness-rule-distiller

