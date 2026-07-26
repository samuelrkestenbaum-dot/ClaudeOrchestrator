# Residue

> What was deferred, left behind, or noted as risk — the stuff that didn't fit in
> the last packet but must not be forgotten. The orchestrator reads this to avoid
> dropping threads; the archivist appends/clears it on close.

## Deferred (follow-up packets)

- **Fresh-session activation test passed (P-009):** authenticated prompt, Build OS
  startup signal, hook parsing, and MCP health all pass.
- **Serena (resolved, P-012):** `zeroize-audit` is disabled and one user-scope Serena MCP
  is pinned to official commit `68884f1`; fresh MCP connection PASS with no duplicate.
- **Claude HUD** → `claude-hud@claude-hud` v0.6.0 installed + enabled at host user scope;
  security + function PASS. ACTIVE pends fresh-session render test (TTY).
- **Context Mode** → `context-mode@context-mode` v1.0.169 installed + enabled at host
  user scope; benchmark PASS. **Routing limited to non-secret pilot** (not wired into any
  project `.mcp.json`); awaiting go to widen. Non-secret repos only; never route
  secrets/customer-data/logs through it.
- **Trail of Bits** → **ACTIVE**; 8 focused plugins enabled (advisory/read-only);
  `zeroize-audit` disabled to remove its unpinned Serena; **not vendored** (CC BY-SA).
- **GH Action opt-in** → `claude-code-action` / `claude-code-security-review` are
  repo-scoped templates; install into a **named** target repo only with explicit go +
  the required secret (`ANTHROPIC_API_KEY` / `CLAUDE_API_KEY`).
- Carried from P-001: authorize Stripe + Cloudflare, enable Google/Microsoft
  connectors; session-MCP router rows for GitHub + Claude Code Remote.
- **Cross-surface asymmetry (P-019/P-020):** two capabilities are active on the Mac but not
  symmetric on the Claude Cloud surface, which caps cross-surface orchestration below 10/10.
  **Serena** — active user-scope MCP on the Mac (pinned `68884f1`); *installed but not registered*
  on Claude Cloud. **P-020 closed the repo-addressable half:** `install-accelerators.sh` now
  registers the pinned Serena into `~/.claude.json` **add-if-absent** (no duplicate on the Mac; no
  secret; project `.mcp.json` still Serena-free per the single-server rule, P-008). Remaining
  boundary: this only helps if the surface reads `~/.claude.json`; a Cloud task on Anthropic's
  managed connector registry (as 21st.dev) still needs a Cloud-settings action. **Claude Watch** —
  host plugin v0.4.1 enabled; absent from Claude Cloud's live registry; **no repo lever** —
  install/enable it on the Cloud surface (a `claude plugin` / Cloud-UI step). Routing already
  treats both as availability-conditional, so nothing overclaims.
- **Fix-to-closure (P-021):** P-020 proven on the real `~/.claude.json` (byte-identical no-op log +
  live `mcp__serena__list_memories` call). **21st.dev** = Anthropic-managed **account connector**
  (approval-gated; no container/repo lever) — user action is Cloud connector settings; the per-call
  approval is not weakened. **UI UX Pro Max** = user-account skill absent from this container (no
  source to vendor) — user action is a Cloud enable / provide the package. **Claude Watch** = host
  plugin absent in Cloud with no repo lever → shipped a **Cloud-native supervision fallback**
  `build-os/tools/supervise.sh` (bounded polling watch; COMPLETED/TIMEOUT/USAGE; no plugin; pair with
  `send_later` for cross-turn) and updated routing truthfully. So the `claude-watch` ROUTE is fully
  functional even where the plugin is absent; the 21st + UI UX Pro Max capabilities themselves remain
  account/Cloud-side, degrading truthfully to their named fallbacks.
- **Audit-branch reconciliation (P-022):** the remote audit branch
  `claude/post-settings-closure-audit-y59p8t` is now **superseded** by canonical — its behavior was
  fully **subsumed** (P-006 216-check suite; P-016/P-017 conditional-inline + non-fatal-bootstrap
  fallback; P-019 21st-live; P-020 Serena add-if-absent; P-021 UI-UX-Pro-Max-absent / watch
  fallback), so P-022 imported **zero machinery** (no `verify.sh`, no `tool_router` edit, no new
  test) and its colliding "P-001" identity was not imported. The local branch and tracking ref
  were removed first; the managed Cloud Code proxy denied remote ref deletion with HTTP 403.
  The superseded remote branch was then deleted through the authenticated GitHub web UI and
  its absence was verified after a full page refresh. Canonical remained untouched.

- **Project-agnostic bootstrap (P-023):** `build-os/tools/project-bootstrap.sh` + the SessionStart
  hook make attachment to an arbitrary project zero-instruction. **MANAGED vs PRESERVED is the rule
  to remember:** `tool_router.md` is **MANAGED** and refreshed on **every** bootstrap, so any
  project-specific routing must live in `current_state.md` / `residue.md` or the user-scope router
  (per the 3-tier fallback) — otherwise it is overwritten. `current_state.md`, `residue.md`,
  `packets/`, `receipts/`, product files, non-managed `CLAUDE.md` content, and unrelated
  `settings.json` keys are preserved. Documented in `README.md` — **that README change is still
  uncommitted in the working tree** at close.

## Known risks / debt

- **Ephemerality → solved via committed bootstrap (P-004):** the remote container is
  ephemeral, so durability = the committed `install-accelerators.sh` (wired into
  SessionStart, idempotent/non-fatal) + `.mcp.json` + `templates/repomix.config.json`.
  Repomix/ccusage are now installed on both the host Mac and the env, but stay **DURABLY
  CONFIGURED** until a fresh Claude Code session test (earlier `ACTIVE (env-scoped)`
  reconciled down — a login shell is not a fresh session). Re-verify at session start
  against the five-state taxonomy.
- **Node compatibility (resolved 2026-07-24):** host default is **Node 22.23.1**.
  Repomix 1.17.0 and ccusage 20.0.18 resolve from the Node 22 bin, and Context Mode
  MCP health connects under Node 22.
- **SessionStart runs background installs (P-004):** the hook launches
  `install-accelerators.sh` detached; first session on a fresh container does network
  installs (fast-skip thereafter). Non-fatal by design — never breaks a session.
- **Version pins are point-in-time (2026-07):** `serena-agent` bootstrap-pinned to commit
  `68884f1` (live host Serena is plugin-bundled/unpinned — deviation), `repomix@1.17.0`,
  `ccusage@20.0.18`, `context-mode@1.0.169`, `claude-hud` v0.6.0. Re-pin on upgrade.
- **Skill budget (resolved, P-012):** ECC's 363-skill mega-bundle is disabled and
  `skillListingBudgetFraction` is 0.18. Fresh authenticated debug loaded 149 directory
  commands, 170 plugin skills, and 35 bundled skills with no truncation warning.
- **Remote/org vs local-verified (P-011):** the 9 claude.ai plugins + 13 connectors are
  **org-level** (claude.ai app registry), NOT in the local `claude plugin` registry; router
  now separates them and applies no-route-to-unverified. Verify live per surface before routing.
- **`enabledPlugins` schema (P-006):** the SessionStart detector parses `enabledPlugins`
  from settings defensively (dict-of-lists, dict-of-bools, or list). If a future Claude
  Code version changes that shape, update the parser + the detector test. Cache entries
  under `~/.claude/plugins/**` are reported as *candidates* only — live verification
  (ListPlugins/ListConnectors/ListSkills or an `mcp__*` call) is required before ACTIVE.
- **Legacy convergence heuristic (P-007):** `install-global.sh` supersedes known legacy
  Build OS/Ruflo routing content (heading/body signatures incl. `stack-capability-map`)
  while preserving unrelated user notes, and syncs the current router to
  `~/build-os/memory/tool_router.md` (overridable via `BUILD_OS_USER_DIR`). Conservative by
  design; extend the signatures + test if a new legacy shape appears on the host.
- **Installation vs configuration vs activation:** `install-global.sh` remains a configuration act; P-010 separately verified a fresh authenticated session.
- **Parallel-work reconciliation (P-007):** the split-brain fix was implemented on the host
  Mac (`Converge global orchestrator routing`) and pushed to this branch; a duplicate
  in-container implementation was discarded in favour of the validated host version, and
  this packet added only the missing Build OS closure (receipt + memory).
- **Config ≠ activation:** installer output intentionally does not claim activation; P-010 supplies the independent activation evidence.
- **Canonical MCP rule (P-008):** one live server per job; prefer a pinned/user-configured
  server over a plugin-bundled copy over an unpinned `@latest`; do not double-launch Serena
  or run Chrome DevTools MCP beside another devtools server for the same task. Encoded in
  `tool_router.md` under *Canonical MCP servers*; extend the named examples as new
  duplicate-prone servers appear.
- **Zero-touch handoff — tested vs live (P-014):** `specialist-handoff.sh` is fully
  regression-tested with a mock `claude` + real `capability-profile.sh` against temp homes
  (classification, focused no-op, ECC/zeroize handoff, prompt/cwd preservation, recursion
  guard, child-failure cleanup, timeout, single-Serena, dry-run). A **live** host handoff
  additionally needs the real authenticated `claude` CLI; the local CLI OAuth is expired, so
  a live child relaunch is a user step. The prompt-hook path resolves the handoff script from
  repo-relative / `$CLAUDE_PROJECT_DIR` / `~/build-os` and is non-fatal if absent.
- **Global install now ships the handoff tools (P-015):** the live-install audit found
  `install-global.sh` created only `~/build-os/memory` and never copied
  `specialist-handoff.sh` / `capability-profile.sh`, so the *globally installed*
  `prompt-router.sh` (whose only global-scope candidate is `~/build-os/tools/specialist-handoff.sh`)
  produced just the routing reminder — no handoff. Fixed: the installer now
  `mkdir -p ~/build-os/tools` and copies the tools dir with exec bits preserved. Test section 16
  installs into temp homes and proves the installed hook resolves + runs the handoff end-to-end.
- **Ferrari hardening (P-016) — 7 audit fixes, all regression-tested (186/0):**
  (1) **Capability registry** — the classifier is now precedence-ordered, per-family task
  rules (not one opaque regex); broad ECC/Everything-Claude-Code families (Rust ownership/unsafe,
  Go concurrency, PostgreSQL schema/query, autonomous-agent harness/evals, architecture, browser)
  route `ecc`; crypto tokens retained; lightweight tasks stay `focused`. Extend by editing one
  `CAP_*` family or adding a family + a line in `classify()`.
  (2) **Inline routes** — `21st`/`agent-reach`/`claude-watch`/`ui-ux-pro-max` emit a REQUIRED
  current-surface directive, never switch profiles, never launch a child; the prompt hook's
  wrapper message is route-accurate (child vs inline).
  (3) **Zeroize NL** — expanded coverage (keys-remain-in-memory, cleared-from-registers/stack);
  still highest precedence.
  (4) **Privacy** — the audit log stores only timestamp/route/result/exit/event-id, is `0600`,
  and tightens a pre-existing 0644; old plaintext prompts are NOT read/migrated (a pre-existing
  0644 leak line is left in place but the mode is tightened — re-verify no legacy log holds
  prompts on the host if that matters).
  (5) **Atomic lock** — `mkdir`-based, `HANDOFF_LOCK` (default `~/.claude/build-os-handoff.lock`),
  `HANDOFF_LOCK_WAIT` (30s), `HANDOFF_LOCK_STALE` (1800s). Stale detection is primarily PID-liveness
  (`kill -0`) + an age fallback; a wrapped-around PID could in theory look alive (single-user host
  risk, bounded by the age cap). Fail-closed BUSY exit 75.
  (6) **Surface inventory** — router separates account-level cloud alias `21st` from Mac-local
  alias `21st-dev`; no cross-surface ACTIVE claim. A fresh cloud Code session successfully
  called `mcp__21st__search` and returned Dashboard Sidebar (id 14941), with Anthropic's
  mandatory web-connector approval prompt.
  (7) **skill-budget-audit** — enabled-aware `--claude-dir` mode reports installed inventory vs
  startup-enabled (via `enabledPlugins` + `installed_plugins.json` installPath, de-duped); only
  the enabled set is budget-checked. `installed_plugins.json` lives at
  `<dir>/plugins/installed_plugins.json`. **Correction (live-host):** the real file stores each
  `plugins[name]` as a **LIST** of install records `[{scope,user,installPath,...}]`, not a single
  dict — the first cut parsed that as 0/0. The parser now accepts list/dict/string schemas via
  `choose_install_path()` (prefers the current user-scope record, then any on-disk installPath,
  then the latest named path; one path per plugin). If a host adds yet another shape, extend that
  helper + the §21 fixture.
- **Post-release adversarial correction (P-017 — host-implemented `ac500c6`, adopted; 198/0):**
  (1) `prompt-router.sh` preserves the real `detect` exit and suppresses parent work only after an
  explicit `COMPLETED`. (2) The child must end with `[BUILD_OS_STATUS: COMPLETED|NEEDS_INPUT|
  BLOCKED|FAILED]`; exit-0-without-a-valid-marker → **UNCONFIRMED (exit 76)**, never OK. (3) Task
  travels on **stdin**, not argv. (4) **Lock safety:** `lock_path_safe` rejects `/`, `.`, `..`,
  `$HOME`, and symlinks; `safe_release_lock` unlinks only the `pid` file then `rmdir`s — no
  recursive deletion. (5) Inline routes are **conditional** INLINE CANDIDATEs (verify live on this
  surface, else built-in/local fallback + state the limit; never claim from install alone).
  (6) The budget report separates enabled **full-body inventory** from startup metadata and marks
  the metadata status **UNKNOWN from files alone** (no false within/over certainty). (7) INT/TERM
  restores focused + releases the lock + exits; the child is killed (verified) and output is
  bounded + visibly truncated.
  **Split-brain note:** the cloud session implemented the same packet in parallel; the validated
  host version (`ac500c6`) was adopted and the parallel cloud commits were discarded (recoverable
  via reflog), per the P-007 precedent. This closure adds the memory the host commit omitted.
  **Residual limitations:** a live authenticated child needs a signed-in `claude` CLI (local OAuth
  expired; proofs use a mock); the terminal-marker contract depends on the child cooperating (a
  non-cooperating child → UNCONFIRMED, the safe default); stale-lock PID-liveness can be fooled by
  PID reuse (bounded by the age cap; single-user host); output is truncated for display after
  capture (host env kills the child promptly, so unbounded accumulation was not observed).
- **Host specialist capabilities (P-014):** 21st.dev verified live in-session (read-only
  `get_usage`); `agent-reach` skill present in-session; Claude Watch + UI UX Pro Max are
  host-reported (installed/uploaded per user) and **not independently verifiable here** — no
  ACTIVE claim. All are preserved across profile transitions and routed in `tool_router.md`
  → *Host specialist capabilities*.
- **Side-branch duplication (P-022):** audit-style side branches can duplicate canonical
  machinery (e.g. a parallel `verify.sh` structural suite + a colliding "P-001" identity) if not
  reconciled promptly; reconcile such branches into canonical **before divergence grows**.
- **Bootstrap honesty boundary (P-023):** agent **callability** was proven only by **real agent
  invocations in that session** (orchestrator → builder → qa → reviewer → archivist). The bootstrap
  itself can verify **discoverability from files only**, and the ON/DEGRADED startup line says so
  explicitly ("file presence is discoverability, not proof of callability"). Never upgrade a
  DEGRADED/ON file-presence report into an activation claim.
- **Single-reviewer pass (P-023):** **Codex second-eyes is NOT available on this surface** (no
  `codex` on `PATH`), so P-023 closed on one reviewer. Reviewer returned **FIX-THEN-PASS** with 4
  defects, all fixed: (1) permanent false `DRIFT` on a vendored copy (`SRC == TARGET` now reports
  provenance), (2) unchecked truncate-then-write of `settings.json`/`CLAUDE.md` (now atomic
  temp + `os.replace`, status-checked, rollback on failure), (3) unchecked `mktemp -d` that could
  write at filesystem root (now fails closed), (4) a vacuous rollback assertion (now seeds a local
  edit so it can fail). Re-run an independent second-eyes pass on this surface once `codex` exists.
- Snapshot leakage: Repomix output can embed code — the hardened config excludes
  secrets/env/deps/build, but **sharing a snapshot externally is a STOP**.

## Open boundaries (awaiting explicit go)

- **No secrets touched, no OAuth authorized, no accounts connected.** Stripe /
  Cloudflare still unauthenticated; GH Action API keys not added.
- Build OS, pinned Serena, Repomix, ccusage, Context Mode, and 8 focused Trail of Bits
  plugins pass current live checks. Claude HUD enabled; visual TTY render unverified.
- Context Mode enabled on host but routing **limited to non-secret pilot** — awaiting go
  to widen.
- Trail of Bits (CC BY-SA) enabled at host user scope, **not vendored** into this repo.
- Production boundaries default-OFF: secrets, OAuth, DDL, remote-DB writes,
  payments, flags, canaries, telemetry, deploys, merges, external sends — each a
  separate explicit approval.
- Feature-branch push only (`claude/orchestrator-tools-list-e0mdaz`); no PR/merge.

---
_Append-only working notes._
