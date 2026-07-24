# Skill Budget Policy (P-011)

Claude Code loads skill metadata (name + description) for **every enabled skill** at
startup, against a budget (~30,000 chars). Exceeding it **truncates skill discovery**, so
purpose-built tools can become invisible to routing. Observed on the host at startup:

> **Skill listing over budget: 685 skills, 171824 chars > 30000** — ~5.7× over.

## Policy: a deliberate minimal active skill set

Keep the strongest broadly-useful build capabilities; disable redundant / rarely-used
bundles. Target: total skill metadata **under budget**, with the warning gone. Do not
blindly keep redundant skills, and do not blindly delete useful ones.

**Keep (broadly-useful build capability):**
- Core Anthropic document/build skills: `docx`, `pdf`, `pptx`, `xlsx`, `dataviz`,
  `skill-creator`, `mcp-builder`, `web-artifacts-builder`, `artifact-*`.
- The **curated Trail of Bits security subset only** (per-task): `constant-time-analysis`,
  `zeroize-audit`, `supply-chain-risk-auditor`, `agentic-actions-auditor`,
  `insecure-defaults`, `static-analysis`, `variant-analysis`, `differential-review`,
  `seatbelt-sandboxer`.
- `context-mode` (context compression, pilot).

**Disable (dominant / redundant):**
- `ecc@ecc`: 363 skills and substantial overlap with GSD, Superpowers, Codex, the
  focused design/document plugins, and Build OS itself.
- Any additional "everything" / mega bundle only if a fresh debug run again exceeds
  the budget.

## Procedure

1. **Audit the dominators** (read-only, safe to run anywhere):
   `build-os/tools/skill-budget-audit.sh ~/.claude/plugins 30000`
   → ranks plugins by skill count so the biggest contributors are obvious.
2. **Disable the dominators** identified above (plugin/skill settings or
   `claude plugin disable <name>`), keeping the minimal set.
3. **Re-audit** until under budget, then start a **fresh debug session** (`claude --debug`)
   and confirm the "Skill listing over budget" warning is **gone**.

## Applied host result (P-012)

- `ecc@ecc` disabled; focused GSD, Superpowers, Codex, document/design, Context Mode,
  memory, and security capabilities retained.
- `skillListingBudgetFraction: 0.18` set at user scope.
- Fresh authenticated debug session loaded 149 directory commands, 170 plugin skills,
  and 35 bundled skills with **no skill-budget warning**, then returned the requested
  response within the configured cost cap.
- `repair-host-integrations.sh` enforces this state after future plugin updates.

## Reversible specialist profiles (P-013)

Disabled does not mean removed. Run:

- `build-os/tools/capability-profile.sh focused` — fast default.
- `build-os/tools/capability-profile.sh ecc` — restores all 372 ECC skills, 67 agents,
  hooks, and Chrome DevTools MCP for a specialist engineering session.
- `build-os/tools/capability-profile.sh zeroize` — restores the zeroization-audit skill
  and agents, swaps pinned user Serena for the plugin's bundled Serena, and prevents a
  duplicate server.
- `build-os/tools/capability-profile.sh status` — read-only current state.

Restart Claude Code after switching. The `/capability-profile` command exposes the same
workflow inside Claude.

## Zero-touch handoff (P-014)

`build-os/tools/specialist-handoff.sh` (wired into the `prompt-router.sh` prompt-entry hook)
auto-detects when a request needs ECC or zeroization and, only then, activates that profile
for a fresh non-interactive child session — ECC temporarily raises `skillListingBudgetFraction`
to 0.40 for the child — and **always restores focused (0.18) afterward**. Focused requests
incur no relaunch and no budget change, so the default session stays under budget.
