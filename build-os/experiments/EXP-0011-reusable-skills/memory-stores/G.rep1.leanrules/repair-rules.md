## RULE TS2305+TS2339 — Module '"../../shared/governance-types"' has no exported member 'AuthorityAuditEntry'.
- applicability: files where tsc reports any of: TS2305, TS2339 (subsystem server/governance/)
- confidence: fix of G1 (32 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- toolseq: Bash>Read>Bash>Read>Edit>Read>Edit>Bash>Edit>Bash>Edit>Bash
- procedure: when these codes fire, apply the demonstrated transform:
```diff
@@ -25,12 +25,47 @@ import { z } from 'zod';
 import { router, adminProcedure, protectedProcedure } from '../_core/trpc';
 import { getExternalTransportStatus, getTransportMetrics, exportPrometheusMetrics } from './production-transport-selector';
 import { getAuthorityMetrics, getAuthorityLayerHealth, getAuthorityAuditTrail } from './gravito-authority-layer';
+import type { AuthorityLayerHealth } from './gravito-authority-layer';
 import { getExternalGravitoHealth } from './gravito-external-client';
 import { getPreApprovalMetrics, REGULATED_SURFACES } from './regulated-surface-preapproval';
-import { getSyncWrapperMetrics } from './mcp-sync-wrapper';
+import { getSyncWrapperMetrics, listJobs } from './mcp-sync-wrapper';
 import { getAuthorityAuditEntries, getAuthorityAuditStats } from '../db';
 import { getGovernanceUptimeMetrics, getInlineMetrics, getCircuitBreakerState, getAuthorityAuditSummary } from './co-processor/gravito-inline-client';
-import type { AuthorityAuditEntry, TransportMetrics, ExternalGravitoHealth, SyncWrapperMetrics, AuthorityLayerHealth, InlineMetrics, AuthorityAuditSummaryEntry } from '../../shared/governance-types';
+import type { AuthorityAuditEntry } from '../../shared/governance-types';
+
+// ============================================================================
+// DERIVATIONS
+//
+// The panels below report a few figures that no subsystem stores directly.
+// They are derived here, once, so every procedure reports them identically.
+// ============================================================================
+
+/** Upper bound on the sync wrapper's live job ring, so the scan sees all of it. */
+const ACTIVE_JOB_SCAN_LIMIT = 1000;
+
+/** Percentage (0–100, two decimals) of `part` out of `total`; 0 when total is 0. */
+function ratePercent(part: number, total: number): number {
+  return total > 0 ? Math.round((part / total) * 10000) / 100 : 0;
+}
+
+/**
@@ -42,6 +77,9 @@ const transportHealthProcedure = adminProcedure.query(async () => {
   const externalHealth = getExternalGravitoHealth();
   const syncMetrics = getSyncWrapperMetrics();
 
+  // The selector counts successes and failures separately; calls is their sum.
+  const totalCalls = metrics.successesTotal + metrics.failuresTotal;
+
   return {
     // Current state
     transport: {
```
- provenance: sequence=G rep=1 position=1 run=G1.leanrules.r1 authored_by=harness-rule-distiller

## RULE TS18046 — 'e' is of type 'unknown'.
- applicability: files where tsc reports any of: TS18046 (subsystem server/governance/)
- confidence: fix of G2 (31 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- toolseq: Read>Bash>Edit>Bash
- procedure: when these codes fire, apply the demonstrated transform:
```diff
@@ -24,6 +24,11 @@ interface ProofResult {
 
 const results: ProofResult[] = [];
 
+/** Narrows a caught `unknown` to a printable message. */
+function errorMessage(e: unknown): string {
+  return e instanceof Error ? e.message : String(e);
+}
+
 function record(category: string, claim: string, passed: boolean, evidence: string, details?: any) {
   results.push({ category, claim, passed, evidence, details });
 }
@@ -50,7 +55,7 @@ async function runAudit() {
       missing.length === 0 ? `Found all: ${required.join(', ')}` : `Missing: ${missing.join(', ')}`,
       { allExports: exports });
   } catch (e: unknown) {
-    record('IMPORTS', 'meaning-interpreter.ts is importable', false, `Import failed: ${e.message}`);
+    record('IMPORTS', 'meaning-interpreter.ts is importable', false, `Import failed: ${errorMessage(e)}`);
   }
 
   // 1b. Human Interaction Model
```
- provenance: sequence=G rep=1 position=2 run=G2.leanrules.r1 authored_by=harness-rule-distiller

## RULE TS2305+TS2322+TS2339+TS2353+TS2454+TS2488+TS2554+TS2739+TS2769+TS7006 — Module '"./types"' has no exported member 'BusinessTruth'.
- applicability: files where tsc reports any of: TS2305, TS2322, TS2339, TS2353, TS2454, TS2488, TS2554, TS2739, TS2769, TS7006 (subsystem server/governance/)
- confidence: fix of G3 (24 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- toolseq: Read>Bash>Read>Bash>Read>Bash>Read>Bash>Edit>Bash>Write>Bash>Read
- procedure: when these codes fire, apply the demonstrated transform:
```diff
@@ -21,14 +21,17 @@ import type {
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
+import type {
+  ReviewContentOutput,
+  SurfaceType as ShieldSurfaceType,
+} from '../../agent/mcp/gravito-mcp-server';
 import { gatedRemediateSweepResults } from './gravito-gate';
 import { evaluateCompletenessGate } from './completeness-gate';
 import { getBusinessTruthContext } from '../../services/truth-context-provider';
@@ -68,7 +71,7 @@ export async function runDiscovery(customerId: string, config: DiscoveryConfigDa
     customerId,
     adapterType: config.adapters.map(a => a.type).join(','),
     status: 'running',
-    startedAt: new Date(startTime),
+    startedAt: startTime,
   });
 
   // Run each enabled adapter
```
- provenance: sequence=G rep=1 position=3 run=G3.leanrules.r1 authored_by=harness-rule-distiller

## RULE TS18046+TS18047+TS2339+TS2365 — 'v' is of type 'unknown'.
- applicability: files where tsc reports any of: TS18046, TS18047, TS2339, TS2365 (subsystem server/governance/)
- confidence: fix of G4 (18 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- toolseq: Bash>Read>Edit>Bash
- procedure: when these codes fire, apply the demonstrated transform:
```diff
@@ -71,6 +71,27 @@ export interface PolicyTestResult {
   error?: string;
 }
 
+/** Shape of one entry in a `violation_codes.<severity>` list of a policy YAML. */
+interface ViolationCodeEntry {
+  code: string;
+  description: string;
+  action: string;
+}
+
+/** Narrows an untrusted YAML node to a well-formed violation code entry. */
+function isViolationCodeEntry(value: unknown): value is ViolationCodeEntry {
+  if (typeof value !== "object" || value === null) return false;
+  const entry = value as Record<string, unknown>;
+  return typeof entry.code === "string"
+    && typeof entry.description === "string"
+    && typeof entry.action === "string";
+}
+
+/** Narrows a caught `unknown` to a printable message. */
+function errorMessage(e: unknown): string {
+  return e instanceof Error ? e.message : String(e);
+}
+
 // In-memory policy store (in production, would be git-backed)
 const policyVersions: Map<string, PolicyVersion> = new Map();
 let currentVersion: string | null = null;
@@ -174,7 +195,10 @@ export function loadPolicyFromFile(filePath: string): PolicyVersion | null {
     // Extract violation codes as rules
     if (parsed.violation_codes) {
       for (const [severity, violations] of Object.entries(parsed.violation_codes)) {
-        for (const v of violations as unknown[]) {
+        const entries = Array.isArray(violations)
+          ? violations.filter(isViolationCodeEntry)
+          : [];
+        for (const v of entries) {
           rules.push({
             id: v.code,
             name: v.code,
```
- provenance: sequence=G rep=1 position=4 run=G4.leanrules.r1 authored_by=harness-rule-distiller

## RULE TS2339 — Property 'proposal' does not exist on type 'Result'.
- applicability: files where tsc reports any of: TS2339 (subsystem server/governance/)
- confidence: fix of G5 (17 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- toolseq: Read>Edit>Bash>Edit>Bash>Edit>Bash
- procedure: when these codes fire, apply the demonstrated transform:
```diff
@@ -8,7 +8,7 @@ async function check(name: string, fn: () => Promise<void> | void) {
   try { await fn(); console.log(`  ✓ ${name}`); }
   catch (e) { failed++; console.error(`  ✗ ${name}\n      ${(e as Error).message}`); }
 }
-function assert(cond: unknown, msg: string) { if (!cond) throw new Error(msg); }
+function assert(cond: unknown, msg: string): asserts cond { if (!cond) throw new Error(msg); }
 function eq<T>(a: T, b: T, msg: string) { if (a !== b) throw new Error(`${msg}: expected ${JSON.stringify(b)}, got ${JSON.stringify(a)}`); }
 
 (async () => {
```
- provenance: sequence=G rep=1 position=5 run=G5.leanrules.r1 authored_by=harness-rule-distiller

