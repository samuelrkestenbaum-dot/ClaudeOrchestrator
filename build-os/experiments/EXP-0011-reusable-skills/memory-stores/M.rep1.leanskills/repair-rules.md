## RULE TS2304+TS2322+TS2339+TS2345+TS2353+TS2538+TS2552 — Argument of type 'string' is not assignable to parameter of type 'Surface'.
- applicability: files where tsc reports any of: TS2304, TS2322, TS2339, TS2345, TS2353, TS2538, TS2552 (subsystem server/mcp/)
- confidence: fix of M1 (29 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- toolseq: Bash>Read>Bash>Edit>Bash>Edit>Bash
- procedure: when these codes fire, apply the demonstrated transform:
```diff
@@ -78,6 +78,7 @@ import {
   runFullContentIntelligenceAudit,
 } from '../governance/content-intelligence';
 
+import type { Surface } from './fail-closed-gate';
 import { mcpError, mcpSuccess, classifyError, type MCPErrorCode } from './mcp-error-contract';
 import { validateToolInput, coerceToolInput } from './tool-input-validator';
 import {
@@ -191,6 +192,11 @@ export interface ExecutionContext {
    * receipt's tenant binding to `authenticated_tenant`.
    */
   authenticatedTenant?: { tenantId: string; source: string };
+  /**
+   * Caller identity used as the control-plane `agentId` when the transport
+   * resolved one. Optional: callers that omit it fall back to `mcp-caller`.
+   */
+  userId?: string;
 }
 
 // Tool arguments arrive as parsed JSON from JSON-RPC — untyped at the boundary.
```
- provenance: sequence=M rep=1 position=1 run=M1.leanskills.r1 authored_by=harness-rule-distiller

## RULE TS2322+TS2339+TS2345+TS2349+TS2571 — Argument of type 'Record<string, unknown>' is not assignable to parameter of type 'ZodType<any, unknown, $ZodTypeInternals<any, unknown>>'.
- applicability: files where tsc reports any of: TS2322, TS2339, TS2345, TS2349, TS2571 (subsystem server/mcp/)
- confidence: fix of M2 (20 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- toolseq: Bash>Skill>Bash>Read>Bash>Write>Bash>Write>Bash>Write>Bash>Edit>Read>Edit>Read>Edit>Read>Edit>Bash>Read>Edit>Bash
- procedure: when these codes fire, apply the demonstrated transform:
```diff
@@ -985,6 +985,36 @@ const ToolCallRequestSchema = z.object({
   arguments: z.record(z.string(), z.any()).optional(),
 });
 
+/**
+ * Shape of `params` on a JSON-RPC `tools/call` request. The body arrives
+ * untyped from the transport; naming the shape here is what lets the tool
+ * dispatch read `arguments` as a record of unknown values instead of
+ * degrading every field it touches.
+ */
+interface JsonRpcToolCallParams {
+  name?: string;
+  arguments?: Record<string, unknown>;
+}
+
+/**
+ * Request fields attached by the MCP authentication layer. Express's own
+ * `Request` cannot know about them, so they are declared alongside the
+ * handler that reads them (same idiom as `mcp-auth`'s `apiKey` attachment).
+ */
+type AuthenticatedMcpRequest = Request & {
+  apiKey?: string;
+  authMethod?: string;
+  authUserId?: number;
+};
+
+/**
+ * Read a request/argument value that is only usable when it is a non-empty
+ * string, preserving the `||` fallback chains at the transport boundary.
+ */
@@ -1154,7 +1184,7 @@ mcpRouter.post('/', async (req: Request, res: Response) => {
           tools: ALL_TOOLS.map(tool => ({
             name: tool.name,
             description: tool.description,
-            inputSchema: typeof ((tool.inputSchema as unknown as Record<string, unknown>))?._def === 'object' ? zodToJsonSchema((tool.inputSchema as unknown as Record<string, unknown>)) : tool.inputSchema,
+            inputSchema: isZodSchema(tool.inputSchema) ? zodToJsonSchema(tool.inputSchema) : tool.inputSchema,
           })),
         };
         break;
```
- provenance: sequence=M rep=1 position=2 run=M2.leanskills.r1 authored_by=harness-rule-distiller

## RULE TS2305+TS2339+TS2344+TS2345+TS2352+TS2353+TS2554 — Module '"./async-job-queue"' has no exported member 'JobStatus'.
- applicability: files where tsc reports any of: TS2305, TS2339, TS2344, TS2345, TS2352, TS2353, TS2554 (subsystem server/mcp/)
- confidence: fix of M3 (9 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- toolseq: Bash>Read>Skill>Bash>Edit>Bash>Write>Bash
- procedure: when these codes fire, apply the demonstrated transform:
```diff
@@ -36,8 +36,9 @@ import { recordAudit } from './mcp-audit-trail';
 import {
   shouldUseAsync, createAsyncJob, markRunning, completeAsyncJob,
   failAsyncJob, getJob, buildJobResponse, getAsyncQueueStats,
-  listJobs, cancelJob, getEstimatedDuration, JobStatus,
+  listJobs, cancelJob, getEstimatedDuration,
 } from './async-job-queue';
+import type { AsyncJobStatus } from './async-job-queue';
 import {
   extractCorrelationId, buildCorrelationContext, getCorrelationHeaders,
   enrichMCPResponse, classify503Cause, build503Response,
@@ -198,10 +199,10 @@ function zodToJsonSchema(schema: z.ZodType<unknown>): Record<string, unknown> {
   if (schema instanceof z.ZodNumber) return { type: 'number', description };
   if (schema instanceof z.ZodBoolean) return { type: 'boolean', description };
   if (schema instanceof z.ZodArray) {
-    return { type: 'array', items: zodToJsonSchema((schema as z.ZodArray<ZodTypeAny>)._def.type), description };
+    return { type: 'array', items: zodToJsonSchema((schema as z.ZodArray<ZodTypeAny>).element), description };
   }
   if (schema instanceof z.ZodEnum) {
-    return { type: 'string', enum: (schema as z.ZodEnum<[string, ...string[]]>)._def.values, description };
+    return { type: 'string', enum: schema.options, description };
   }
   if (schema instanceof z.ZodDefault) {
     const inner = zodToJsonSchema((schema as z.ZodDefault<ZodTypeAny>)._def.innerType);
```
- provenance: sequence=M rep=1 position=3 run=M3.leanskills.r1 authored_by=harness-rule-distiller

## RULE TS2339 — Property '_def' does not exist on type '{}'.
- applicability: files where tsc reports any of: TS2339 (subsystem server/mcp/)
- confidence: fix of M4 (7 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- toolseq: Read>Bash>Skill>Bash>Read>Bash>Edit>Bash
- procedure: when these codes fire, apply the demonstrated transform:
```diff
@@ -16,6 +16,8 @@
  * This is a pure function transform — no side effects, no state.
  */
 
+import { z } from 'zod';
+
 import { GRAVITO_TOOLS } from '../agent/mcp/gravito-mcp-server';
 
 // ============================================================================
@@ -58,27 +60,18 @@ function buildFieldMapCache(): void {
 
   for (const tool of GRAVITO_TOOLS) {
     const shortName = tool.name.replace('gravito.', '');
-    const inputSchema = tool.inputSchema as unknown;
-    
-    if (!inputSchema || !inputSchema._def) {
-      // Not a Zod schema — skip
-      continue;
-    }
+    const inputSchema = tool.inputSchema;
 
-    // Extract field names from Zod schema shape
-    let shape: Record<string, unknown> = {};
-    try {
-      if (inputSchema.shape) {
-        shape = inputSchema.shape;
-      } else if (inputSchema._def?.shape) {
-        shape = typeof inputSchema._def.shape === 'function' 
-          ? inputSchema._def.shape() 
-          : inputSchema._def.shape;
-      }
-    } catch {
+    // Only object schemas carry a named field shape. Anything else — a bare
+    // scalar schema, or a definition that never went through Zod — has no
+    // field names to alias, so there is nothing to map.
+    if (!(inputSchema instanceof z.ZodObject)) {
       continue;
     }
 
```
- provenance: sequence=M rep=1 position=4 run=M4.leanskills.r1 authored_by=harness-rule-distiller

## RULE TS2305+TS2339+TS2345 — Module '"./tool-executor"' has no exported member 'ToolExecutionOptions'.
- applicability: files where tsc reports any of: TS2305, TS2339, TS2345 (subsystem server/mcp/)
- confidence: fix of M5 (6 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- toolseq: Bash>Read>Skill>Bash>Edit>Bash>Edit>Bash
- procedure: when these codes fire, apply the demonstrated transform:
```diff
@@ -27,7 +27,7 @@ import {
   type AsyncJob,
   type CreateJobOptions,
 } from './async-job-queue';
-import { executeTool, type ToolExecutionOptions } from './tool-executor';
+import { executeTool, type ExecutionContext } from './tool-executor';
 
 const log = createLogger('mcp-sync-wrapper');
@@ -88,12 +88,13 @@ export async function mcpGovernedCall(
     try {
       log.info(`[${correlationId}] Attempting sync execution for ${toolName} (estimated: ${estimatedDuration}ms)`);
       
-      const result = await executeTool(toolName, payload, {
+      const ctx: ExecutionContext = {
         apiKey: jobOptions.apiKey,
         clientIp: jobOptions.clientIp,
         userAgent: jobOptions.userAgent,
         correlationId,
-      } as ToolExecutionOptions);
+      };
+      const result = await executeTool(toolName, payload, ctx);
 
       const elapsedMs = Date.now() - startTime;
       log.info(`[${correlationId}] Sync execution completed in ${elapsedMs}ms`);
```
- provenance: sequence=M rep=1 position=5 run=M5.leanskills.r1 authored_by=harness-rule-distiller

