## RULE TS2304+TS2322+TS2339+TS2345+TS2353+TS2538+TS2552 — Argument of type 'string' is not assignable to parameter of type 'Surface'.
- applicability: files where tsc reports any of: TS2304, TS2322, TS2339, TS2345, TS2353, TS2538, TS2552 (subsystem server/mcp/)
- confidence: fix of M1 (29 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- toolseq: Bash>Read>Bash>Read>Bash>Edit>Bash>Edit>Bash
- procedure: when these codes fire, apply the demonstrated transform:
```diff
@@ -79,6 +79,7 @@ import {
 } from '../governance/content-intelligence';
 
 import { mcpError, mcpSuccess, classifyError, type MCPErrorCode } from './mcp-error-contract';
+import type { Surface } from './fail-closed-gate';
 import { validateToolInput, coerceToolInput } from './tool-input-validator';
 import {
   optimizeModelRoute as routingSelectModel,
@@ -218,6 +219,52 @@ async function safeTool(fn: () => Promise<MCPContent>, toolName?: string): Promi
   }
 }
 
+// ============================================================================
+// HELPERS: narrow untyped JSON-RPC arguments at the trust boundary
+// ============================================================================
+
+/** `value || fallback` for arguments that must reach a `string` parameter. */
+function asString(value: unknown, fallback: string): string {
+  return typeof value === 'string' && value.length > 0 ? value : fallback;
+}
+
+/** Keeps a string argument, or drops it so the callee's own default applies. */
+function asOptionalString(value: unknown): string | undefined {
+  return typeof value === 'string' ? value : undefined;
+}
+
+/** Keeps only the string entries of an array argument; `[]` for anything else. */
+function asStringArray(value: unknown): string[] {
+  return Array.isArray(value) ? value.filter((item): item is string => typeof item === 'string') : [];
+}
+
+function isRecord(value: unknown): value is Record<string, unknown> {
+  return typeof value === 'object' && value !== null && !Array.isArray(value);
+}
+
+/** `value || {}` for arguments that must reach a `Record<string, unknown>` parameter. */
+function asRecord(value: unknown): Record<string, unknown> {
+  return isRecord(value) ? value : {};
```
- provenance: sequence=M rep=1 position=1 run=M1.leanrules.r1 authored_by=harness-rule-distiller

## RULE TS2322+TS2339+TS2345+TS2349+TS2571 — Argument of type 'Record<string, unknown>' is not assignable to parameter of type 'ZodType<any, unknown, $ZodTypeInternals<any, unknown>>'.
- applicability: files where tsc reports any of: TS2322, TS2339, TS2345, TS2349, TS2571 (subsystem server/mcp/)
- confidence: fix of M2 (20 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- toolseq: Bash>Read>Bash>Read>Bash>Read>Edit>Bash>Edit>Bash>Edit>Bash
- procedure: when these codes fire, apply the demonstrated transform:
```diff
@@ -162,6 +162,46 @@ import { generalLog } from '../_core/logger';
 import { unsafeCast } from '../../shared/type-bridge';
 import { authenticateMCP, extractApiKey, validateApiKey, AUTH_METADATA } from './mcp-auth';
 
+// ============================================================================
+// TYPED READERS FOR LOOSELY-STRUCTURED INPUT
+// JSON-RPC params, MCP tool arguments and HTTP headers all arrive untyped.
+// These readers narrow a single field to the primitive the caller needs and
+// return undefined when the field is absent or of the wrong shape, so callers
+// can supply a default with `??` instead of asserting a type.
+// ============================================================================
+
+/** Read a non-empty string field from an untyped object. */
+function readStringField(source: unknown, key: string): string | undefined {
+  if (typeof source !== 'object' || source === null) return undefined;
+  const value = (source as Record<string, unknown>)[key];
+  return typeof value === 'string' && value.length > 0 ? value : undefined;
+}
+
+/** Read a finite number field from an untyped object. */
+function readNumberField(source: unknown, key: string): number | undefined {
+  if (typeof source !== 'object' || source === null) return undefined;
+  const value = (source as Record<string, unknown>)[key];
+  return typeof value === 'number' && Number.isFinite(value) ? value : undefined;
+}
+
+/** Read a request header as a single non-empty string (Express may give an array). */
+function readHeaderString(req: Request, name: string): string | undefined {
+  const value = req.headers[name];
+  if (typeof value === 'string') return value.length > 0 ? value : undefined;
@@ -1154,7 +1194,7 @@ mcpRouter.post('/', async (req: Request, res: Response) => {
           tools: ALL_TOOLS.map(tool => ({
             name: tool.name,
             description: tool.description,
-            inputSchema: typeof ((tool.inputSchema as unknown as Record<string, unknown>))?._def === 'object' ? zodToJsonSchema((tool.inputSchema as unknown as Record<string, unknown>)) : tool.inputSchema,
+            inputSchema: isZodSchema(tool.inputSchema) ? zodToJsonSchema(tool.inputSchema) : tool.inputSchema,
           })),
         };
         break;
```
- provenance: sequence=M rep=1 position=2 run=M2.leanrules.r1 authored_by=harness-rule-distiller

## RULE TS2305+TS2339+TS2344+TS2345+TS2352+TS2353+TS2554 — Module '"./async-job-queue"' has no exported member 'JobStatus'.
- applicability: files where tsc reports any of: TS2305, TS2339, TS2344, TS2345, TS2352, TS2353, TS2554 (subsystem server/mcp/)
- confidence: fix of M3 (9 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- toolseq: Bash>Read>Bash>Edit>Read>Edit>Bash
- procedure: when these codes fire, apply the demonstrated transform:
```diff
@@ -36,7 +36,7 @@ import { recordAudit } from './mcp-audit-trail';
 import {
   shouldUseAsync, createAsyncJob, markRunning, completeAsyncJob,
   failAsyncJob, getJob, buildJobResponse, getAsyncQueueStats,
-  listJobs, cancelJob, getEstimatedDuration, JobStatus,
+  listJobs, cancelJob, getEstimatedDuration, type AsyncJobStatus,
 } from './async-job-queue';
 import {
   extractCorrelationId, buildCorrelationContext, getCorrelationHeaders,
@@ -198,10 +198,10 @@ function zodToJsonSchema(schema: z.ZodType<unknown>): Record<string, unknown> {
   if (schema instanceof z.ZodNumber) return { type: 'number', description };
   if (schema instanceof z.ZodBoolean) return { type: 'boolean', description };
   if (schema instanceof z.ZodArray) {
-    return { type: 'array', items: zodToJsonSchema((schema as z.ZodArray<ZodTypeAny>)._def.type), description };
+    return { type: 'array', items: zodToJsonSchema(schema.element as z.ZodType<unknown>), description };
   }
   if (schema instanceof z.ZodEnum) {
-    return { type: 'string', enum: (schema as z.ZodEnum<[string, ...string[]]>)._def.values, description };
+    return { type: 'string', enum: schema.options, description };
   }
   if (schema instanceof z.ZodDefault) {
     const inner = zodToJsonSchema((schema as z.ZodDefault<ZodTypeAny>)._def.innerType);
```
- provenance: sequence=M rep=1 position=3 run=M3.leanrules.r1 authored_by=harness-rule-distiller

## RULE TS2339 — Property '_def' does not exist on type '{}'.
- applicability: files where tsc reports any of: TS2339 (subsystem server/mcp/)
- confidence: fix of M4 (7 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- toolseq: Read>Bash>Edit>Bash
- procedure: when these codes fire, apply the demonstrated transform:
```diff
@@ -53,27 +53,48 @@ interface ToolFieldMap {
 
 const fieldMapCache = new Map<string, ToolFieldMap>();
 
+/** The object shape a Zod object schema exposes, in either of its two forms. */
+type ZodShape = Record<string, unknown>;
+
+/**
+ * Minimal structural view of the Zod internals this module probes.
+ * Zod's public types don't expose `_def.shape` uniformly across versions, so we
+ * describe only the two access paths used here rather than depending on them.
+ */
+interface ZodSchemaLike {
+  _def: { shape?: ZodShape | (() => ZodShape) };
+  shape?: ZodShape;
+}
+
+function isZodSchemaLike(value: unknown): value is ZodSchemaLike {
+  return (
+    typeof value === 'object' &&
+    value !== null &&
+    '_def' in value &&
+    Boolean(value._def)
+  );
+}
+
 function buildFieldMapCache(): void {
   if (fieldMapCache.size > 0) return;
 
   for (const tool of GRAVITO_TOOLS) {
```
- provenance: sequence=M rep=1 position=4 run=M4.leanrules.r1 authored_by=harness-rule-distiller

## RULE TS2305+TS2339+TS2345 — Module '"./tool-executor"' has no exported member 'ToolExecutionOptions'.
- applicability: files where tsc reports any of: TS2305, TS2339, TS2345 (subsystem server/mcp/)
- confidence: fix of M5 (6 occurrence(s)) ACCEPTED — zero errors remained in the task file, no new errors elsewhere
- toolseq: Bash>Read>Bash>Edit>Bash
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
- provenance: sequence=M rep=1 position=5 run=M5.leanrules.r1 authored_by=harness-rule-distiller

