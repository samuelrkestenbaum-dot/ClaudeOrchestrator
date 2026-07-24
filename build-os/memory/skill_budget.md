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
- The rest of the `trailofbits/skills` marketplace — it ships ~40 plugins; only the 9
  curated security plugins above are used, so the other ~31 dominate the budget.
- Any "everything" / mega bundles and skills that duplicate a kept capability.

## Procedure

1. **Audit the dominators** (read-only, safe to run anywhere):
   `build-os/tools/skill-budget-audit.sh ~/.claude/plugins 30000`
   → ranks plugins by skill count so the biggest contributors are obvious.
2. **Disable the dominators** identified above (plugin/skill settings or
   `claude plugin disable <name>`), keeping the minimal set.
3. **Re-audit** until under budget, then start a **fresh debug session** (`claude --debug`)
   and confirm the "Skill listing over budget" warning is **gone**.

> **Boundary (user step):** steps 2–3 run on the host and require a working local Claude
> CLI. The local CLI OAuth is currently **expired**, so applying the trim and the
> fresh-debug verification are user actions — this repo supplies the audit tool + policy,
> not a credentialed host change.
