# Gravito design-partner pilot package v0 (LANE 6 — non-outreach assets)

STATUS: package assets only. NO outreach begins from this document.
Pricing and partner selection are OPERATOR DECISIONS, marked below.

## 1. One-page explanation (the page a partner reads first)

Gravito is an operating layer for AI-assisted software work. Installed
in your repository, it decides how much intelligence, context, review,
authority, and cost each task deserves — then enforces that decision
mechanically while the work happens. Every change routes at entry
(a one-command, seconds-long step); cheap tasks run thin, complex tasks
earn deeper verification; unrouted changes are blocked with a recovery
command; everything leaves receipts. What you get: more accepted work
per unit of AI spend, fewer runaway sessions, an audit trail your
reviewers can actually read, and continuity between sessions — the
repository remembers, not the chat window.
Evidence so far (internal, honestly labeled): a five-task pilot on a
real product repository — 5/5 accepted, four durable commits, ~44
measured minutes, zero human interventions, at most 2 displayed points
of weekly model-plan movement across the surrounding session window; and
a fresh zero-context session governed natively by the installed gate
(blocked → routed → admitted, ledger-proven). Not yet: external
customer proof — that is what the design-partner pilot is for.

## 2. Ten-minute demonstration script

1. (1 min) Show a governed repo: `gravito explain` — what routes, what
   blocks, where evidence lives.
2. (2 min) Live block: fresh session attempts an edit → refused with
   recovery text; run the one command; edit admitted. Show the ledger.
3. (2 min) `gravito tasks` / `gravito task <id>` — a real task card:
   mode, why, budget, activity, result, evidence.
4. (2 min) Routing depth: a trivial fix routed Direct vs a compliance
   change routed Full with an independent verification agent — show the
   contribution row, including a NEGATIVE one ("caught nothing — and
   said so").
5. (2 min) The economics view: the pilot measurement method (meter
   readings at window edges, accepted output per point).
6. (1 min) Honest bounds: not a sandbox; hooks per-session; what stays
   protocol. Questions.

## 3. Installation guide

Points at the installed-repo INSTALL.md (one page) + the versioned
runtime (`gravito-runtime.sh install <repo>` once Lane 1 lands):
install → initialize → show version → upgrade explicitly → roll back
safely. Partner prerequisite: Claude Code with hooks enabled; other
providers are declared honestly (see §6 limitations).

## 4. Security and data handling

- Gravito's gate runs LOCALLY in your repo as shell hooks; it makes no
  network calls and phones nothing home (verifiable: the installed
  files are plain text, ~1,900 lines total).
- It reads tool-call metadata (command text, file paths) to classify;
  it stores receipts and event ledgers IN YOUR REPO under build-os/.
  Nothing leaves your infrastructure via Gravito.
- Secrets: the gate never reads or prints secret values; intake flags
  secret-SHAPED file paths by name only.
- The AI provider's own data handling is governed by YOUR provider
  agreement, not altered by Gravito.
- Not a sandbox: the platform permission system remains the security
  boundary; Gravito is discipline + audit for honest agents.

## 5. Authority model

Depths: Direct (thin), Light (durable context, parent-only), Full
(subagents within budget, contribution accounting). Escalation requires
evidence; de-escalation is free. External mutation (push, merge,
deploy, secrets, spend, outreach) ALWAYS requires your explicit go —
the gate cannot and does not self-authorize outward actions. Operator
override exists (ROUTING_GATE_DISABLE=1) and is always logged.

## 6. Pilot scope, method, and metrics

- Scope: one or two repositories, fixed period (suggest 2–4 weeks),
  service-assisted (we operate alongside your team).
- Baseline methodology: pre-pilot week measured WITHOUT Gravito on the
  same task mix where possible (accepted tasks, elapsed, interventions,
  rework, provider spend); then the governed period, same measures,
  meter readings at task-window edges (the PILOT-0002 protocol).
- Success metrics (agreed before start): accepted-task rate, durable
  commits, human-intervention count, rework rate, provider-spend per
  accepted task, audit completeness (receipts per mutation), and your
  team's own acceptance judgment.
- Evidence report: the pilot ends with a written report in the
  PILOT-0001 form — including whatever is unflattering.

## 7. Pricing structure — PROVISIONAL, NON-BINDING

Operator-set draft, explicitly provisional pending the clean-window
economic pilot and the unfamiliar-repository proof:

- **Assisted pilot — $25,000-$50,000, 4-6 weeks**, one or two
  repositories: installation, baseline measurement, governed AI
  execution, weekly evidence report, accepted-output and intervention
  tracking, final economic assessment.
- **Enterprise pilot — $50,000-$100,000**: broader scope with security
  review, several teams, or custom integrations.

EVERY figure above is PROVISIONAL and non-binding. It is priced against
internal evidence only (PILOT-0001, plus the native-governance proof);
no external customer has yet run Gravito, and no controlled economic
result exists. The numbers are expected to move once the clean-window
pilot and an unfamiliar-repository pilot produce measured cost-per-
accepted-outcome evidence. Nothing here constitutes an offer.

## 8. Customer responsibilities

Provide repo access + CI conventions; name an approver for external
mutations; take the two meter readings per measured window; attend a
weekly 30-min review; judge acceptance honestly.

## 9. Limitations (stated up front, in the package)

Claude-hooks is the only verified adapter today; Codex/OpenAI is
declared interface-unverified until a real call succeeds. Live token
counts are not visible in interactive sessions (event counts are exact;
costs reconcile at close). The Bash classifier is a heuristic honest
agents follow and audit catches — not a sandbox. Evidence to date is
internal; this pilot exists to create the first external evidence.
