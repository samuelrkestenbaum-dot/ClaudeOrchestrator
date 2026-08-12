## RULE TS18046 — 'error' is of type 'unknown'.
- applicability: files where tsc reports `TS18046: 'error' is of type 'unknown'.`
- confidence: fix of B1 (6 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- procedure: when `TS18046: 'error' is of type 'unknown'.` fires, apply the demonstrated transform:
```diff
@@ -1505,7 +1505,7 @@ export const controlTowerRouter = router({
     }))
     .mutation(async ({ input, ctx }) => {
       // Resolve user plan for gating
-      const userId = (ctx as unknown as Record<string, unknown>).user?.id ?? null;
+      const userId = ctx.user?.id ?? null;
       const planKey = await getUserPlanKey(userId);
       const gates = getFeatureGates(planKey);
       const usage = userId ? await getScanUsageInfo(userId) : null;
@@ -1912,7 +1912,8 @@ export const controlTowerRouter = router({
       const userId = ctx.user?.id;
       if (!userId) throw new TRPCError({ code: 'UNAUTHORIZED' });
       const prefs = await getDigestPreferences(userId);
-      const frequency = prefs?.frequency || 'weekly';
+      // The stored frequency is a free-form varchar; narrow it to the supported literals.
+      const frequency: 'daily' | 'weekly' = prefs?.frequency === 'daily' ? 'daily' : 'weekly';
       return sendDigestForUser(userId, frequency);
     }),
```
- provenance: sequence=B rep=1 position=1 run=B1.leanrules.r1 authored_by=harness-rule-distiller

## RULE TS18046 — 'error' is of type 'unknown'.
- applicability: files where tsc reports `TS18046: 'error' is of type 'unknown'.`
- confidence: fix of B2 (5 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- procedure: when `TS18046: 'error' is of type 'unknown'.` fires, apply the demonstrated transform:
```diff
@@ -529,15 +529,16 @@ async function auditScenario(scenario: AuditScenario): Promise<AuditFinding[]> {
 
       previousState = state;
     } catch (error: unknown) {
+      const err = error instanceof Error ? error : new Error(String(error));
       findings.push({
         id: `${findingPrefix}-error`,
         category: 'edge_cases',
         severity: 'critical',
         title: `Runtime error on message`,
-        description: `processMessage() threw: ${error.message}`,
+        description: `processMessage() threw: ${err.message}`,
         scenario: scenario.name,
         expected: 'No errors',
-        actual: error.message,
+        actual: err.message,
         recommendation: `Add error handling for this scenario.`,
         codeLocation: 'server/nervous-system/dynamics/runtime.ts:processMessage()',
       });
@@ -591,8 +592,9 @@ Be specific and actionable. Reference specific findings by category.`
 
     return response.content[0].type === 'text' ? response.content[0].text : 'Assessment unavailable';
   } catch (error: unknown) {
-    generalLog.error('[BehavioralAudit] Claude assessment failed:', error);
-    return `Assessment unavailable: ${error.message}`;
+    const err = error instanceof Error ? error : new Error(String(error));
+    generalLog.error('[BehavioralAudit] Claude assessment failed:', err);
+    return `Assessment unavailable: ${err.message}`;
   }
 }
```
- provenance: sequence=B rep=1 position=2 run=B2.leanrules.r1 authored_by=harness-rule-distiller

## RULE TS18046 — 'error' is of type 'unknown'.
- applicability: files where tsc reports `TS18046: 'error' is of type 'unknown'.`
- confidence: fix of B3 (3 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- procedure: when `TS18046: 'error' is of type 'unknown'.` fires, apply the demonstrated transform:
```diff
@@ -36,7 +36,7 @@ export const planesRouter = router({
         return {
           success: false,
           data: null,
-          error: error.message
+          error: error instanceof Error ? error.message : String(error)
         };
       }
     }),
@@ -66,7 +66,7 @@ export const planesRouter = router({
         return {
           success: false,
           data: null,
-          error: error.message
+          error: error instanceof Error ? error.message : String(error)
         };
       }
     }),
```
- provenance: sequence=B rep=1 position=3 run=B3.leanrules.r1 authored_by=harness-rule-distiller

## RULE TS18046 — 'error' is of type 'unknown'.
- applicability: files where tsc reports `TS18046: 'error' is of type 'unknown'.`
- confidence: fix of B4 (2 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- procedure: when `TS18046: 'error' is of type 'unknown'.` fires, apply the demonstrated transform:
```diff
@@ -144,7 +144,7 @@ If the page is already well-aligned, return it with minimal changes.`;
       // If no code block, return the raw text (might be direct code)
       return text.trim();
     } catch (error: unknown) {
-      generalLog.info(`[BatchUpdater] Attempt ${attempt}/${maxRetries} failed for ${pagePath}: ${error.message}`);
+      generalLog.info(`[BatchUpdater] Attempt ${attempt}/${maxRetries} failed for ${pagePath}: ${error instanceof Error ? error.message : String(error)}`);
       if (attempt < maxRetries) {
         // Wait before retry with exponential backoff
         await new Promise(resolve => setTimeout(resolve, 2000 * attempt));
@@ -254,7 +254,7 @@ export async function updateSinglePage(
     return {
       pagePath,
       status: 'failed',
-      reason: error.message
+      reason: error instanceof Error ? error.message : String(error)
     };
   }
 }
```
- provenance: sequence=B rep=1 position=4 run=B4.leanrules.r1 authored_by=harness-rule-distiller

## RULE TS18046 — 'error' is of type 'unknown'.
- applicability: files where tsc reports `TS18046: 'error' is of type 'unknown'.`
- confidence: fix of B5 (2 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- procedure: when `TS18046: 'error' is of type 'unknown'.` fires, apply the demonstrated transform:
```diff
@@ -291,7 +291,7 @@ export async function routeModelInvocation<T>(
         latencyMs,
       };
     } catch (error: unknown) {
-      lastError = error.message;
+      lastError = error instanceof Error ? error.message : String(error);
       recordModelResult(primaryModel.id, false, Date.now() - startTime);
     }
   }
@@ -317,7 +317,7 @@ export async function routeModelInvocation<T>(
         latencyMs,
       };
     } catch (error: unknown) {
-      lastError = error.message;
+      lastError = error instanceof Error ? error.message : String(error);
       recordModelResult(fallbackModel.id, false, Date.now() - startTime);
     }
```
- provenance: sequence=B rep=1 position=5 run=B5.leanrules.r1 authored_by=harness-rule-distiller

