# Current State

> The "where are we" snapshot. The orchestrator reads this first every session.
> The archivist advances it when a packet closes. Keep it short and true.

## Project

- **What this repo is:** Build OS — a native orchestrator for Claude Code (routing
  matrix + packet loop + markdown memory) that turns a repo into a
  plan → build → prove → review → record system.
- **Primary branch / base:** `claude/add-build-os` (current integration base; no
  `main` present in this environment). Active work branch:
  `claude/project-handoff-merge-ramhds` (tip `641527f`, pushed).
- **Version:** `0.1.0` (`VERSION`), pre-1.0 — **installable, not yet API-stable**.
  Changelog: `CHANGELOG.md`. License: `LICENSE` — proprietary, All Rights Reserved,
  a deliberately conservative **placeholder**; the license model is still an open
  owner decision. **No tags exist in this repo yet.**
- **Build/test command:** `bash tests/build_os_tests.sh` (616 checks; no network; temp dirs).
  It **chains** every sibling suite in `tests/` through one `chain_suite` function and folds their
  counts into its own totals — 221 native + 61 cold-install + 73 lane-enforcement + 91 scaffold-seeding
  + 42 release-metadata + 128 speed-metrics = 616. A sibling suite present on disk but not chained is itself a failure,
  so a new suite cannot become discoverable-only. The maintenance layer also has its
  own suite, `./build-os/maintenance/run-tests.sh` (144 checks, node --test). Both are offline and
  deterministic. Pinned separately: `bash tests/release_metadata_tests.sh` (release metadata +
  a staleness guard on THIS line — if the count above goes stale again, that suite goes red).
  Cross-platform green: the P-018 200KB capture-bound test now generates its payload **in-child**
  (`MOCK_GEN_BYTES` / `MOCK_STREAM_CHUNKS`) instead of via an env var — the old env delivery
  exceeded Linux `MAX_ARG_STRLEN` (~128KB) and failed only on Linux (P-018.1, tests-only fix).
  — proportionate-routing + tool-ranking rules, the SessionStart detector (enabledPlugins/
  native vs plugin-cache candidates), installer copy parity, managed-block replacement,
  global convergence (legacy routing supersession preserving unrelated notes, + arbitrary-
  repo user-scope router resolution), plus install-global DURABLY-CONFIGURED reporting, the
  explicit 3-tier router fallback, and the canonical duplicate-MCP rule, plus P-011
  hook-dedupe (no prompt_id), skill-budget audit, honest Serena reconciliation, and
  remote/org-vs-local capability separation, plus P-013 reversible profiles and P-014
  zero-touch specialist handoff (route classification, focused no-op, ECC/zeroize handoff,
  prompt/cwd preservation, recursion guard, child-failure cleanup, timeout, single-Serena,
  dry-run) and unrelated-capability preservation across profile transitions, plus P-015
  global-install tool shipping and P-016 Ferrari hardening (capability registry,
  inline routing, privacy log, atomic lock, surface inventory, enabled-vs-installed audit).

## Where we are

- **Last closed packet:** `gravito_test_harness_stdin_hang_a` — the documented test command no
  longer hangs on an interactive terminal (receipt
  `build-os/receipts/gravito_test_harness_stdin_hang_a.md`, commit `641527f`).
  `tests/build_os_tests.sh` §2 invoked the SessionStart hook with the **caller's stdin
  inherited**; the hook reads stdin to EOF (`payload="$(cat)"`), so on a TTY the suite blocked
  forever with no output — on the exact command the README advertises. Diagnosis was
  **hook-correct / test-wrong**: the hook contract is right and is unchanged. Fixed by feeding
  the realistic SessionStart JSON payload, plus a stdin pin (§27) that is behavioural (a FIFO
  held open under `timeout`) **and** static (a scanner covering all **10** hook-invocation sites
  — 3 SessionStart + 7 UserPromptSubmit — with a minimum-site-count **vacuity floor**, because an
  earlier draft grepped only `bash "$HOOK"` and saw 3). **Before: exit 124. After: exit 0,
  281 passed / 0 failed at `641527f`** (616 now that four further sibling suites are chained).** Known limit, stated in-file: on a TTY a re-broken §2 call hangs before
  §27 is reached; check (b) is the protection and fires in CI / any non-TTY run.
- **Prior:** `gravito_productization_pa_maintenance_upstream_a` (**P-A**) — the memory
  maintenance + safety layer is upstreamed into the product (receipt
  `build-os/receipts/gravito_productization_pa_maintenance_upstream_a.md`, commits `c30f77d`
  + `5b956c0`). Ports rotation / tripwire / the sanctioned test wrapper (8 files) from a
  reference deployment into `build-os/maintenance/`, with installer wiring into **both**
  customer entry points, a `PORTING.md` manifest, a **contract-only** `standing_gates.md`
  template (the reference deployment's live hard-stop inventory was deliberately NOT ported),
  `GRAVITO:MANAGED` ownership markers + a `.gravito-managed` manifest, and a **61-test
  cold-install suite chained into the documented command** rather than left discoverable-only.
  Load-bearing adaptation: all three `FILE_SPECS` delimiters are now `^## ` (the reference
  delimiter found **zero** blocks in a scaffolded file, and a delimiter matching nothing does not
  error — it reported a no-op at exit 0, i.e. a file that silently never rotates), and a
  zero-block parse of a file that HAS content now warns on stderr instead of printing the same
  `already rotated (no-op)` line it printed for two benign states. Reviewer verdict **pass**,
  after one **fix-then-pass** round (5 items). Suites at `641527f`: **281 / 144 / 61**, all 0 fail (the 281 is now 488).
- **Prior:** P-022 — reconciliation of the post-settings-closure-audit branch
  (`claude/post-settings-closure-audit-y59p8t`) into canonical (receipt
  `build-os/receipts/P-022.md`). **Documentation-only; no behavior change; suite stays 216/216.**
  The audit branch (two commits self-labeled "P-001": `571bf05`, `e3d8b6e`) is **reconciled /
  superseded** — its behavior was already **subsumed** by P-006 (216-check suite), P-016/P-017
  (conditional inline-candidate + non-fatal-bootstrap fallback), P-019 (21st live in Cloud),
  P-020 (Serena add-if-absent), and P-021 (UI UX Pro Max absent / watch fallback), so **zero
  machinery was imported** (no `verify.sh`, no `tool_router` edit, no new test). The audit's
  "P-001" identity **collides** with canonical's existing P-001 and was **not** imported; the
  audit's proposed **Sourcegraph** directory-connector is unverified/not-connected this session
  and was **deliberately excluded** (no-route-to-unverified). Suite **216/216**.
- **Prior:** P-021 — fix-to-closure (receipt `build-os/receipts/P-021.md`). **P-020
  proven on the real `~/.claude.json`**: `register-serena` logged *already present — left untouched*,
  byte-identical no-op, one Serena, and a **live `mcp__serena__list_memories` returned `{}`
  (callable)**. **21st.dev** diagnosed as an **Anthropic-managed account connector** (not in
  `~/.claude.json`; approval-gated) — no container lever; user action = Cloud connector settings.
  **UI UX Pro Max** is a user-account skill absent from this container — user action = Cloud enable /
  provide package. **Claude Watch** has no repo lever, so shipped a **Cloud-native supervision
  fallback**: `build-os/tools/supervise.sh` (bounded polling watch → COMPLETED/TIMEOUT/USAGE; no
  plugin) + a truthful router/inline update naming it (still availability-conditional). Suite
  **216/216**.
- **Prior:** P-020 — the SessionStart bootstrap (`install-accelerators.sh`) now
  **registers the pinned Serena MCP add-if-absent**. It previously installed the Serena binary but
  never wrote the `mcpServers` entry ("installed but not registered"); it now adds the canonical
  pinned server to `~/.claude.json` **only if no `serena` entry exists** — closing the config-side
  Serena gap on a surface that lacks it, while leaving the Mac's user-scope server byte-untouched
  (single-server rule, P-008). No secret; project `.mcp.json` stays Serena-free. Suite **208/208**.
  **Honest boundary:** this closes the gap only if the surface resolves MCPs from `~/.claude.json`;
  a Claude Cloud task using Anthropic's managed connector registry (as 21st.dev does) still needs a
  Cloud-settings action. **Claude Watch** (host plugin) has no repo lever — Cloud enable is a user
  step.
- **Prior:** P-019 — cross-surface truth (receipt `build-os/receipts/P-019.md`).
  21st.dev is **verified live in Claude Cloud**: a fresh cloud Code session called
  `mcp__21st__search` and returned "Dashboard Sidebar" by `arunjdass` (id 14941) — connected AND
  callable — but Anthropic's web-connector layer **approval-gates every call** (project settings do
  not bypass it), and the API key was never placed in the plaintext cloud env. Mac-local `21st-dev`
  stays the zero-touch lane. **Two cross-surface asymmetries remain open (user/cloud-controlled,
  not repo-fixable):** Serena is active user-scope on the Mac but *installed-not-registered* on the
  Claude Cloud surface (registering it there is the user step; the repo must not add it to project
  `.mcp.json` per the single-server rule); Claude Watch v0.4.1 is host-enabled but **absent from
  Claude Cloud's live registry**. Routing already treats both as availability-conditional, so no
  false claim is made. Suite **202/202** green.
- **Prior:** P-018 (terminal-marker integrity: only a single valid final-line marker is
  COMPLETED; bounded capture via a 0700 temp dir + streaming limiter; signal reaping) and **P-018.1**
  (Linux portability of the 200KB capture-bound test — payload now generated in-child, not via an
  env var that exceeded Linux `MAX_ARG_STRLEN`). Suite 198 → 200 → **202**.
- **Prior:** P-017 — post-release adversarial correction (7 runtime defects;
  host-implemented on the Mac as `ac500c6`, adopted here; suite 198/0):
  1. **Failure propagation** — `prompt-router.sh` preserves the real `detect` exit and only
     an explicit `COMPLETED` suppresses parent work; otherwise it says the handoff was not
     confirmed complete and the focused parent must continue / obtain input.
  2. **Semantic completion** — the child must end with a terminal marker
     `[BUILD_OS_STATUS: COMPLETED|NEEDS_INPUT|BLOCKED|FAILED]`; exit 0 alone is not "done" —
     missing/malformed status is **UNCONFIRMED** (exit 76), never OK.
  3. **Prompt privacy** — the task travels over **stdin**, never argv (so it can't leak via `ps`).
  4. **Lock safety** — no recursive deletion: `lock_path_safe` rejects `/`, `.`, `..`, `$HOME`
     and symlinks; `safe_release_lock` unlinks only the `pid` file then `rmdir`s.
  5. **Inline availability is conditional** — routes emit an INLINE CANDIDATE (verify the tool
     is connected/callable on this surface; else use a built-in/local fallback and state the
     limitation) — never "REQUIRED use X" and never claim availability from install alone.
  6. **Budget accuracy** — the audit separates enabled **full-body inventory** from startup
     metadata and reports the metadata status as **UNKNOWN from files alone** (full SKILL.md
     bodies are inventory, not measured startup metadata) — no false within/over certainty.
  7. **Signals + bounded output** — INT/TERM restores focused, releases the lock, and exits;
     the child is killed (verified) and captured output is bounded + visibly truncated.
  `tests/build_os_tests.sh` — 198/198 green. (A parallel cloud implementation was discarded in
  favour of the validated host version, per the P-007 split-brain precedent; this packet adds
  the missing Build OS memory closure.)
- **Prior:** P-016 — final Ferrari hardening (7 audit fixes):
  1. **Capability registry** replaces the opaque regex — precedence-ordered, per-family
     task rules. Broad ECC (Everything Claude Code) tasks now route `ecc`: Rust
     ownership/unsafe, Go concurrency/debug, PostgreSQL schema/query, autonomous-agent
     harness/evals, architecture + browser specialists (crypto tokens retained). Ordinary
     lightweight tasks stay `focused` (no relaunch).
  2. **Inline routes** — `classify` returns `21st`/`agent-reach`/`claude-watch`/`ui-ux-pro-max`;
     `detect` emits a REQUIRED current-surface directive with NO capability-profile switch and
     NO child; the prompt hook no longer falsely claims a child handled an inline route.
  3. **Zeroize NL coverage** expanded (keys-remain-in-memory, cleared-from-registers/stack);
     zeroize keeps highest precedence.
  4. **Privacy** — the handoff audit log records only timestamp/route/result/exit/event-id
     (never prompt text or cwd), is created/chmodded `0600`, and tightens a pre-existing 0644.
  5. **Concurrency** — a portable `mkdir`-atomic lock wraps profile activation + child +
     restore; configurable wait; fail-closed BUSY (no mutation, no child) on contention; safe
     stale-lock break; released on EXIT/INT/TERM; focused restoration preserved.
  6. **Surface-aware inventory** — router distinguishes Claude Desktop connector verification
     from the local Claude CLI (21st.dev Desktop-verified, absent from `claude mcp list`;
     Agent Reach native skill; UI UX Pro Max v2.11.0; Claude Watch v0.4.1); no cross-surface
     ACTIVE claim; stale "host-reported" language removed.
  7. **skill-budget-audit** now reports installed inventory separately from the startup-enabled
     set (via `enabledPlugins` + `installed_plugins.json` installPath, de-duped) and only
     checks the enabled set against budget — a disabled mega-bundle no longer reads OVER BUDGET.
     **Correction:** the real `installed_plugins.json` stores each plugin as a **LIST** of
     install records; the parser now handles list/dict/string schemas (prefers the user-scope
     record) so the host audit is nonzero — was falsely 0/0.
  `tests/build_os_tests.sh` — 189/189 green (RED 148/38 → GREEN 186/0; +3 list-schema checks → 189/0).
- **Prior:** P-015 — global install ships the specialist handoff tools (installed hook resolves
  + runs the handoff end-to-end). P-014 — zero-touch specialist orchestration.
- **Now:** none active.
- **Next (candidates):** decide Context Mode routing enablement (stays non-secret pilot);
  name a target repo + approve
  a secret for the GH Actions; authorize/enable the deferred connectors.

## Stable facts (slow-changing)

- **Remote / org — claude.ai (2026-07; NOT the local CLI plugin registry):** 9 org plugins
  (`design`, `data`, `productivity`, `brand-voice`, `marketing`, `sales`, `small-business`,
  `legal`, `cowork-plugin-management`); 13 connectors (Apollo.io, Clay, Docusign, Gmail,
  Higgsfield, HubSpot, Hugging Face, Netlify, Notion, Otter.ai, Slack, Supabase, Zapier) +
  2 session MCPs (GitHub, Claude Code Remote). These are org-level (claude.ai app registry),
  distinct from the locally-installed CLI plugins; verify live per surface before routing
  (no-route-to-unverified). See `tool_router.md` → *Remote / org capabilities*.
- **Installed but NOT live:** Stripe, Cloudflare Developer Platform (need auth);
  Google Calendar, Google Drive, Microsoft 365 (toggled off in-chat).
- **Source of truth for capabilities:** the live registries — `ListConnectors`,
  `ListPlugins`, `ListSkills` — reconciled into `tool_router.md` (Installed
  plugins / connectors) and `INTEGRATIONS.md`. Re-verify when the env changes.
- **Build accelerators (P-012 live evidence):** Build OS routing, Serena, Repomix,
  ccusage, and Context Mode are ACTIVE. Host — Serena is one user-scope MCP pinned to
  official commit `68884f1`; Repomix 1.17.0 + ccusage 20.0.18
  (`/Users/samsmac/.nvm/versions/node/v22.23.1/bin`). Enabled at host user scope via the
  `claude plugin` CLI (`claude plugin list` confirms): `claude-hud` v0.6.0,
  `context-mode` v1.0.169 (routing limited to non-secret pilot), and 8 focused Trail of
  Bits plugins (`constant-time-analysis`, `supply-chain-risk-auditor`,
  `agentic-actions-auditor`, `insecure-defaults`, `static-analysis`, `variant-analysis`,
  `differential-review`, `seatbelt-sandboxer`). `zeroize-audit` and ECC are disabled;
  the former prevents an unpinned duplicate Serena and the latter removes 363 redundant
  skills. A fresh authenticated prompt completed with no skill-budget warning. Claude HUD remains enabled but its visual
  statusline is not independently claimed. Node compatibility resolved: host default is
  Node 22.23.1; Repomix, ccusage, and Context Mode run/connect under Node 22. GitHub
  Actions = repo-scoped templates (uninstalled; no secrets). Gates in `tool_router.md` +
  `INTEGRATIONS.md` §8. One orchestrator (Build OS) — no competing framework.
- **Status-semantics rule:** never call npx/uvx success in an ephemeral container
  "installed" unless persistent host state **and** a fresh-session activation test
  are both verified. Installation · configuration · activation · authentication ·
  repository rollout are five distinct states.
- **Discovery-first rule:** every build discovers live capabilities, then selects
  the smallest correct toolset; Serena is primary for symbol-level work in large/
  unfamiliar repos before broad file reads.
- **Zero-touch specialist handoff (P-014→P-017):** `build-os/tools/specialist-handoff.sh` + the
  `prompt-router.sh` hook classify via a maintainable **capability registry** (precedence
  zeroize > ecc > inline > focused). focused → no relaunch; ecc/zeroize → an automatic bounded
  child under a **safe atomic lock** (path-validated `lock_path_safe`, non-recursive
  unlink+`rmdir`, fail-closed BUSY, safe stale break; released + focused restored on
  EXIT/INT/TERM, child killed). The task travels on **stdin** (never argv) and the child must end
  with a terminal marker `[BUILD_OS_STATUS: COMPLETED|NEEDS_INPUT|BLOCKED|FAILED]`; the hook
  suppresses parent work **only** on explicit COMPLETED — exit-0-without-marker is UNCONFIRMED
  (exit 76), and the parent is told to continue/obtain input otherwise. Output is bounded +
  visibly truncated. The audit log is **privacy-safe** (route/result/exit/event-id; `0600`; never
  prompt/cwd). `install-global.sh` ships both tool scripts into `~/build-os/tools` (P-015).
  **Inline routes** (`21st`, `agent-reach`, `claude-watch`, `ui-ux-pro-max`) emit a **conditional**
  INLINE CANDIDATE (verify live on this surface, else built-in/local fallback + state the limit —
  never claim use from install alone); no profile switch, no child. Surface-aware: 21st.dev is
  verified live as cloud alias `21st` and Mac-local alias `21st-dev`; Anthropic's cloud
  web-connector layer still requires per-call user approval and does not honor project
  permission allowlists for this gate. Agent Reach = native skill;
  UI UX Pro Max v2.11.0 + Claude Watch v0.4.1 = enabled Claude Code skills/plugins. No
  cross-surface ACTIVE claim.
- **Gates hold:** external mutation (push/merge/deploy/secret/send/SaaS-write),
  plus DDL / remote-DB writes / payments / flags / canaries / telemetry / OAuth,
  are each a separate STOP for explicit go. Repo-scoped GH Actions never go global.

---
_Updated by the archivist on close._
