## RULE TS2305+TS2339 — Module '"../../shared/governance-types"' has no exported member 'AuthorityAuditEntry'.
- applicability: files where tsc reports any of: TS2305, TS2339 (subsystem server/governance/)
- confidence: fix of G1 (32 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- toolseq: Bash>Read>Bash>Edit>Bash
- procedure: when these codes fire, apply the demonstrated transform:
```diff
@@ -24,13 +24,13 @@
 import { z } from 'zod';
 import { router, adminProcedure, protectedProcedure } from '../_core/trpc';
 import { getExternalTransportStatus, getTransportMetrics, exportPrometheusMetrics } from './production-transport-selector';
-import { getAuthorityMetrics, getAuthorityLayerHealth, getAuthorityAuditTrail } from './gravito-authority-layer';
+import { getAuthorityMetrics, getAuthorityLayerHealth, getAuthorityConfig } from './gravito-authority-layer';
 import { getExternalGravitoHealth } from './gravito-external-client';
 import { getPreApprovalMetrics, REGULATED_SURFACES } from './regulated-surface-preapproval';
 import { getSyncWrapperMetrics } from './mcp-sync-wrapper';
 import { getAuthorityAuditEntries, getAuthorityAuditStats } from '../db';
 import { getGovernanceUptimeMetrics, getInlineMetrics, getCircuitBreakerState, getAuthorityAuditSummary } from './co-processor/gravito-inline-client';
-import type { AuthorityAuditEntry, TransportMetrics, ExternalGravitoHealth, SyncWrapperMetrics, AuthorityLayerHealth, InlineMetrics, AuthorityAuditSummaryEntry } from '../../shared/governance-types';
+import type { AuthorityAuditEntry } from '../../shared/governance-types';
 
 // ============================================================================
 // PANEL 1: TRANSPORT HEALTH
@@ -42,6 +42,9 @@ const transportHealthProcedure = adminProcedure.query(async () => {
   const externalHealth = getExternalGravitoHealth();
   const syncMetrics = getSyncWrapperMetrics();
 
+  // Transport metrics count successes and failures separately; total is their sum.
+  const transportCalls = metrics.successesTotal + metrics.failuresTotal;
+
   return {
     // Current state
     transport: {
```
- provenance: sequence=G rep=1 position=1 run=G1.leanskills.r1 authored_by=harness-rule-distiller

## RULE TS18046 — 'e' is of type 'unknown'.
- applicability: files where tsc reports any of: TS18046 (subsystem server/governance/)
- confidence: fix of G2 (31 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- toolseq: Skill>Bash>Read>Bash>Edit>Bash>Edit>Bash
- procedure: when these codes fire, apply the demonstrated transform:
```diff
@@ -28,6 +28,11 @@ function record(category: string, claim: string, passed: boolean, evidence: stri
   results.push({ category, claim, passed, evidence, details });
 }
 
+// Caught values are `unknown`; narrow to a printable message for the evidence string.
+function errorMessage(e: unknown): string {
+  return e instanceof Error ? e.message : String(e);
+}
+
 async function runAudit() {
   governanceLog.info('═══════════════════════════════════════════════════════════════');
   governanceLog.info('  STRUCTURAL PROOF AUDIT v2 — EVERY CLAIM TESTED WITH EXECUTION');
@@ -50,7 +55,7 @@ async function runAudit() {
       missing.length === 0 ? `Found all: ${required.join(', ')}` : `Missing: ${missing.join(', ')}`,
       { allExports: exports });
   } catch (e: unknown) {
-    record('IMPORTS', 'meaning-interpreter.ts is importable', false, `Import failed: ${e.message}`);
+    record('IMPORTS', 'meaning-interpreter.ts is importable', false, `Import failed: ${errorMessage(e)}`);
   }
 
   // 1b. Human Interaction Model
```
- provenance: sequence=G rep=1 position=2 run=G2.leanskills.r1 authored_by=harness-rule-distiller

## RULE TS2305+TS2322+TS2339+TS2353+TS2454+TS2488+TS2554+TS2739+TS2769+TS7006 — Module '"./types"' has no exported member 'BusinessTruth'.
- applicability: files where tsc reports any of: TS2305, TS2322, TS2339, TS2353, TS2454, TS2488, TS2554, TS2739, TS2769, TS7006 (subsystem server/governance/)
- confidence: fix of G3 (24 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- toolseq: Skill>Bash>Read>Bash>Edit>Bash>Read
- procedure: when these codes fire, apply the demonstrated transform:
```diff
@@ -25,10 +25,8 @@ import type {
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
@@ -68,7 +66,8 @@ export async function runDiscovery(customerId: string, config: DiscoveryConfigDa
     customerId,
     adapterType: config.adapters.map(a => a.type).join(','),
     status: 'running',
-    startedAt: new Date(startTime),
+    // discovery_runs.startedAt / .completedAt are bigint epoch-millis columns, not timestamps.
+    startedAt: startTime,
   });
 
   // Run each enabled adapter
```
- provenance: sequence=G rep=1 position=3 run=G3.leanskills.r1 authored_by=harness-rule-distiller

## RULE TS18046+TS18047+TS2339+TS2365 — 'v' is of type 'unknown'.
- applicability: files where tsc reports any of: TS18046, TS18047, TS2339, TS2365 (subsystem server/governance/)
- confidence: fix of G4 (18 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- toolseq: Bash>Read>Skill>Bash>Edit>Bash
- procedure: when these codes fire, apply the demonstrated transform:
```diff
@@ -75,6 +75,24 @@ export interface PolicyTestResult {
 const policyVersions: Map<string, PolicyVersion> = new Map();
 let currentVersion: string | null = null;
 
+// Shape of a `violation_codes` entry as authored in the policy YAML.
+interface RawViolationEntry {
+  code: string;
+  description: string;
+  action?: string;
+}
+
+function isRawViolationEntry(value: unknown): value is RawViolationEntry {
+  if (typeof value !== "object" || value === null) return false;
+  const entry = value as Record<string, unknown>;
+  return typeof entry.code === "string" && typeof entry.description === "string";
+}
+
+// Caught values are `unknown`; narrow to a printable message.
+function errorMessage(e: unknown): string {
+  return e instanceof Error ? e.message : String(e);
+}
+
 /**
  * Generate cryptographic signature for policy
  */
@@ -175,6 +193,8 @@ export function loadPolicyFromFile(filePath: string): PolicyVersion | null {
     if (parsed.violation_codes) {
       for (const [severity, violations] of Object.entries(parsed.violation_codes)) {
         for (const v of violations as unknown[]) {
+          // Entries without a code and description cannot form a rule.
+          if (!isRawViolationEntry(v)) continue;
           rules.push({
             id: v.code,
             name: v.code,
```
- provenance: sequence=G rep=1 position=4 run=G4.leanskills.r1 authored_by=harness-rule-distiller

## RULE TS2339 — Property 'proposal' does not exist on type 'Result'.
- applicability: files where tsc reports any of: TS2339 (subsystem server/governance/)
- confidence: fix of G5 (17 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- toolseq: Skill>Bash>Read>Bash>Edit>Bash
- procedure: when these codes fire, apply the demonstrated transform:
```diff
@@ -8,7 +8,9 @@ async function check(name: string, fn: () => Promise<void> | void) {
   try { await fn(); console.log(`  ✓ ${name}`); }
   catch (e) { failed++; console.error(`  ✗ ${name}\n      ${(e as Error).message}`); }
 }
-function assert(cond: unknown, msg: string) { if (!cond) throw new Error(msg); }
+// An assertion signature, so `assert(p.ok, …)` narrows Result to its Success arm
+// for the rest of the block — the same way `if (!p.ok) throw` would.
+function assert(cond: unknown, msg: string): asserts cond { if (!cond) throw new Error(msg); }
 function eq<T>(a: T, b: T, msg: string) { if (a !== b) throw new Error(`${msg}: expected ${JSON.stringify(b)}, got ${JSON.stringify(a)}`); }
 
 (async () => {
```
- provenance: sequence=G rep=1 position=5 run=G5.leanskills.r1 authored_by=harness-rule-distiller

