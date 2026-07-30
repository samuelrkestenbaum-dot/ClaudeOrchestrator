# Tool Router — WORKED EXAMPLE (not your router)

<!-- GRAVITO:TEMPLATE-EXAMPLE — teaching artifact only.
     THIS FILE IS NEVER COPIED INTO A REPO'S build-os/memory/. The installer
     seeds build-os/memory/tool_router.md from
     templates/build-os/memory/tool_router.md, which ships with ZERO connector
     rows. Every capability named below is FICTIONAL and exists to show the
     shape of a row, not to suggest a tool you should have. -->

**Read this, then write your own rows in
`build-os/memory/tool_router.md`.** Nothing here is seeded anywhere. Every tool
named below is made up — `acme-tickets`, `example-db`, `widget-deploy` and
`fable-render` are not real packages, and a router that still names them has
been copied rather than filled in.

The point of the example is the **Gate / stop** column. Three rows, three
escalating authorities:

| # | Row kind | What the gate must say |
|---|---|---|
| 1 | read-only | normal budget — nothing to gate |
| 2 | gated write | scoped, reversible, announced **before** the write |
| 3 | external mutation | **STOP** — needs an explicit go from the user |

## Example rows

| Task type | Preferred external tool(s) | Used by | Gate |
|---|---|---|---|
| Look up a customer ticket / support history | `acme-tickets` MCP (`acme-tickets-mcp`, read scopes only) | build-orchestrator, qa | read-only — normal budget; never posts a reply |
| Read app schema / run a SELECT against staging | `example-db` MCP (`example-db-mcp`, staging profile) | builder, qa | read-only — normal budget; **production profile is a different row and is not routed here** |
| Write a migration / seed rows in staging | `example-db` MCP (staging profile, write scopes) | builder | **GATED WRITE** — staging only, migration file committed first, announced in the Tool Budget before the call; never production |
| Ship a build to the public site | `widget-deploy` CLI (`widget-deploy`) | build-orchestrator (gate) | **STOP** — external mutation; needs an explicit go from the user, every time |
| Render a promo clip from a storyboard | `fable-render` MCP (`fable-render-mcp`) | builder (marketing-media) | marketing/media packets only; never touches product code |

## Why each row is written that way

### 1. Read-only row — `acme-tickets`

The gate is "normal budget" **and a sentence about what it cannot do**
("never posts a reply"). A read-only capability that also has a write verb is
not a read-only row; split it into two rows, as `example-db` is split above.

### 2. Gated-write row — `example-db`

Two rows for one server, because *authority*, not *vendor*, is what a row
routes. The staging read row and the staging write row have different gates, and
production is deliberately absent: there is no row for it, so the orchestrator
cannot match it and must stop and ask. **Absence is a gate.**

The write row states three things the orchestrator can check before acting:
scope (staging), reversibility (a committed migration file), and announcement
(named in the Tool Budget *before* the call).

### 3. External-mutation row — `widget-deploy`

The gate column is **STOP**, the route is the orchestrator rather than the
builder, and "every time" is written down so a previous go is not read as a
standing one. Any row that can push, merge, deploy, publish, or touch secrets
looks like this one.

## Copy the shape, not the rows

When you connect a real tool:

1. Copy the **shape** of the row closest to it in authority.
2. Replace the fictional handle with the capability's **registered** name.
3. Rewrite the gate in terms of *your* environment — what it may touch, what it
   may never touch, and whether it needs an explicit go.
4. Delete nothing from your core lanes; they describe Build OS, not your tools.
