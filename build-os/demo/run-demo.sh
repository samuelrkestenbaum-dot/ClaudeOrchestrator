#!/usr/bin/env bash
# Gravito — DESIGN-PARTNER DEMO (ten minutes, scripted, resumable).
#
#   run-demo.sh [--auto] [--workspace DIR] [--from N] [--only N] [--resume]
#               [--list] [--keep|--no-keep]
#
# WHAT THIS IS. A walkthrough of capabilities THAT ALREADY EXIST in this
# repository, run end to end against a DEDICATED FIXTURE REPOSITORY this script
# creates under mktemp. It never runs against a customer repository, never runs
# against any experiment repository, and never pushes, publishes or deploys
# anything. Every number it shows is produced live by the tool being shown.
#
# WHAT IT WILL NOT DO. It fabricates no savings, quotes no customer, and
# presents no percentage as a measured result. The one place a percentage
# appears at all is a labelled HYPOTHESIS quoted from the A/B preregistration,
# which is explicitly unmeasured (step 10).
#
# THE TEN STEPS:
#   1  installation of the versioned runtime, plus status and version
#   2  repository intake — DISCOVERED vs GUESSED, and the unsupported assumptions
#   3  an unrouted mutation is BLOCKED, and its recovery command unblocks it
#   4  depth selection — Direct, Light, Full, and a Full deliberately WITHHELD
#   5  the customer surface — tasks and one task card, in customer words
#   6  the evidence — the routing receipt and the ledger rows for what just ran
#   7  honest degradation — a real budget breach, concealed (refused) vs declared (passes)
#   8  fresh-worker continuity — exactly what a new worker receives, with no history
#   9  capability-based compiler bypass — an ELIGIBLE index and a BYPASS verdict
#  10  the Context Compiler's honest status — implemented, inert, performance-unmeasured
#
# Artifacts land in <workspace>/artifacts/NN-*.txt so a viewer can re-read any
# step afterwards. Progress is recorded in <workspace>/state/progress.tsv, so
# --resume continues where a paused demo stopped. --from and --only re-enter an
# EXISTING workspace: steps 5-9 read state the earlier steps left behind, so
# skipping forward in a fresh workspace will not have that state to read.
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEMO_REPO="$(cd "$SELF_DIR/../.." && pwd)"

die(){ printf 'run-demo: %s\n' "$*" >&2; exit 2; }

# ------------------------------------------------------------- source root ----
# The demo drives the REAL tools. It finds the Gravito source root by looking,
# in order, at an explicit override, at its own repository, and then at a
# sibling checkout beside any ancestor of its own repository. It never guesses:
# a candidate counts only if the executables the demo actually runs are there.
valid_source(){
  [ -f "$1/build-os/runtime/gravito-runtime.sh" ] \
  && [ -f "$1/build-os/intake/repo-intake.sh" ] \
  && [ -f "$1/build-os/shell/gravito" ] \
  && [ -f "$1/build-os/tools/route-task.sh" ] \
  && [ -f "$1/build-os/compiler/capability/report.mjs" ] \
  && [ -f "$1/build-os/compiler/index/build-index.mjs" ]
}
resolve_source(){
  local c a
  if [ -n "${GRAVITO_SOURCE_ROOT:-}" ]; then
    valid_source "$GRAVITO_SOURCE_ROOT" || die "GRAVITO_SOURCE_ROOT=$GRAVITO_SOURCE_ROOT does not carry the Gravito tools this demo drives"
    ( cd "$GRAVITO_SOURCE_ROOT" && pwd ); return 0
  fi
  if valid_source "$DEMO_REPO"; then printf '%s' "$DEMO_REPO"; return 0; fi
  a="$DEMO_REPO"
  while [ "$a" != "/" ] && [ -n "$a" ]; do
    a="$(dirname "$a")"
    for c in "$a/ClaudeOrchestrator" "$a/claude-orchestrator"; do
      if valid_source "$c"; then ( cd "$c" && pwd ); return 0; fi
    done
  done
  die "cannot find the Gravito source root. Set GRAVITO_SOURCE_ROOT to the checkout that carries build-os/runtime/gravito-runtime.sh."
}

# ------------------------------------------------------------------ options ---
AUTO=0; WORKSPACE=""; FROM=1; ONLY=0; RESUME=0; LIST=0
while [ $# -gt 0 ]; do
  case "$1" in
    --auto) AUTO=1; shift ;;
    --workspace) [ $# -ge 2 ] || die "--workspace needs a directory"; WORKSPACE="$2"; shift 2 ;;
    --from) [ $# -ge 2 ] || die "--from needs a step number"; FROM="$2"; shift 2 ;;
    --only) [ $# -ge 2 ] || die "--only needs a step number"; ONLY="$2"; shift 2 ;;
    --resume) RESUME=1; shift ;;
    --list) LIST=1; shift ;;
    -h|--help) sed -n '2,40p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown option \"$1\" (try --help)" ;;
  esac
done

STEP_NAMES=(
  "Installation — the versioned runtime installs itself into a repository"
  "Repository intake — DISCOVERED vs GUESSED, and what it could NOT determine"
  "Unrouted mutation is blocked — with the recovery command that unblocks it"
  "Depth selection — Direct, Light, Full, and a Full honestly withheld"
  "The customer surface — what a customer sees, in customer words"
  "Evidence — the routing receipt and the ledger rows for what just ran"
  "Honest degradation — a real breach: concealed is refused, declared passes"
  "Fresh-worker continuity — exactly what a new worker receives, no history"
  "Compiler bypass by capability — an ELIGIBLE index and a BYPASS verdict"
  "The Context Compiler's honest status — implemented, inert, unmeasured"
)

if [ "$LIST" = "1" ]; then
  printf 'Gravito design-partner demo — ten steps:\n\n'
  i=1
  for n in "${STEP_NAMES[@]}"; do printf '%2s. %s\n' "$i" "$n"; i=$((i+1)); done
  printf '\nRun unattended with: run-demo.sh --auto\n'
  exit 0
fi

SRC="$(resolve_source)" || exit 2

# ----------------------------------------------------------------- preflight --
MISSING=""
for t in bash node git jq python3 sha256sum awk sed find mktemp; do
  command -v "$t" >/dev/null 2>&1 || MISSING="$MISSING $t"
done
[ -z "$MISSING" ] || die "missing required tools:$MISSING. The demo drives real tools and will not simulate them."

# ----------------------------------------------------------------- workspace --
if [ -z "$WORKSPACE" ]; then
  WORKSPACE="$(mktemp -d "${TMPDIR:-/tmp}/gravito-demo.XXXXXX")"
else
  mkdir -p "$WORKSPACE" || die "cannot create workspace $WORKSPACE"
fi
WORKSPACE="$(cd "$WORKSPACE" && pwd)"
A="$WORKSPACE/artifacts"
STATE="$WORKSPACE/state"
FIX="$WORKSPACE/fixture"                 # the TS/JS demo repository
FIX_SH="$WORKSPACE/fixture-ops-scripts"  # a deliberately shell-heavy repository
FIX_UD="$WORKSPACE/fixture-undocumented" # a repository that wrote no test command
CUSTVIEW="$WORKSPACE/customer-view"      # a copy of the evidence, customer-worded path
STORE="$FIX/build-os/packets/routing"
PROGRESS="$STATE/progress.tsv"
mkdir -p "$A" "$STATE"

GITC=(-c user.email=demo@fixture.invalid -c user.name="Gravito Demo Fixture")

# ------------------------------------------------------------------ display ---
rule(){ printf '%s\n' "--------------------------------------------------------------------------"; }
say(){ printf '%s\n' "$*"; }
pause(){
  [ "$AUTO" = "1" ] && return 0
  printf '\n    [enter] continue · [q] stop here (the workspace is kept; --resume returns) '
  local ans=""
  if [ -r /dev/tty ]; then IFS= read -r ans < /dev/tty || ans=""; else IFS= read -r ans || ans=""; fi
  case "$ans" in q|Q) printf '\nstopped at the operator'"'"'s request. Resume with:\n  %s --workspace %s --resume\n' "$0" "$WORKSPACE"; exit 0 ;; esac
}
done_step(){ printf '%s\tdone\t%s\n' "$1" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$PROGRESS"; }
is_done(){ [ -f "$PROGRESS" ] && awk -F'\t' -v n="$1" '$1==n && $2=="done"{f=1} END{exit !f}' "$PROGRESS"; }

run_step(){ # <n> <function>
  local n="$1" fn="$2"
  if [ "$ONLY" != "0" ] && [ "$ONLY" != "$n" ]; then return 0; fi
  if [ "$n" -lt "$FROM" ]; then return 0; fi
  if [ "$RESUME" = "1" ] && is_done "$n"; then
    say "SKIP step $n (already done in this workspace) — ${STEP_NAMES[$((n-1))]}"
    return 0
  fi
  printf '\n'; rule
  printf 'STEP %s of 10 — %s\n' "$n" "${STEP_NAMES[$((n-1))]}"
  rule
  "$fn" || die "step $n failed"
  done_step "$n"
  pause
}

# ------------------------------------------------------------------ fixtures --
# A small, realistic TS/JS project with two tests and ONE GENUINE DEFECT: the
# cent-rounding helper uses Math.round on a float product, so 1.005 rounds to
# 1.00. That is a real bug, not a planted string.
make_fixture(){
  [ -d "$FIX/.git" ] && return 0
  mkdir -p "$FIX/src" "$FIX/tests"
  cat > "$FIX/package.json" <<'EOF'
{
  "name": "acme-cart",
  "version": "0.2.0",
  "private": true,
  "type": "module",
  "scripts": {
    "test": "node tests/run.mjs",
    "build": "node tools/build.mjs"
  },
  "devDependencies": {
    "vitest": "^1.6.0"
  }
}
EOF
  cat > "$FIX/README.md" <<'EOF'
# acme-cart

Cart pricing helpers for the Acme storefront.

## Build and test

    npm test
EOF
  cat > "$FIX/src/money.js" <<'EOF'
// Money helpers. Everything here is in major units (e.g. dollars), rounded to
// cents at the boundary.

export function roundCents(amount) {
  // DEFECT: Math.round over a binary float product is not half-up in decimal.
  // roundCents(1.005) returns 1 because 1.005 * 100 === 100.49999999999999.
  return Math.round(amount * 100) / 100;
}

export function applyRate(amount, rate) {
  return roundCents(amount * rate);
}
EOF
  cat > "$FIX/src/cart.js" <<'EOF'
import { roundCents, applyRate } from './money.js';

export function subtotal(lines) {
  let total = 0;
  for (const line of lines) total += line.price * line.qty;
  return roundCents(total);
}

export function totalWithTax(lines, taxRate) {
  const base = subtotal(lines);
  return roundCents(base + applyRate(base, taxRate));
}
EOF
  cat > "$FIX/src/pricing.ts" <<'EOF'
export interface CartLine {
  sku: string;
  price: number;
  qty: number;
}

export interface PricedCart {
  lines: CartLine[];
  taxRate: number;
}

export function lineCount(cart: PricedCart): number {
  return cart.lines.length;
}
EOF
  cat > "$FIX/src/index.ts" <<'EOF'
export type { CartLine, PricedCart } from './pricing.ts';
export { lineCount } from './pricing.ts';
EOF
  cat > "$FIX/tests/cart.test.mjs" <<'EOF'
import { subtotal, totalWithTax } from '../src/cart.js';

export function cases() {
  return [
    ['subtotal adds lines', subtotal([{ price: 2.5, qty: 2 }, { price: 1.25, qty: 4 }]), 10],
    ['tax is applied on top', totalWithTax([{ price: 10, qty: 1 }], 0.1), 11],
  ];
}
EOF
  cat > "$FIX/tests/run.mjs" <<'EOF'
import { roundCents } from '../src/money.js';
import { cases } from './cart.test.mjs';

let failed = 0;
function check(name, got, want) {
  if (got === want) { console.log(`ok   ${name}`); return; }
  console.log(`FAIL ${name}: got ${got}, wanted ${want}`);
  failed += 1;
}

for (const [name, got, want] of cases()) check(name, got, want);
check('cents round half up', roundCents(1.005), 1.01);

console.log(failed === 0 ? 'PASS' : `FAIL (${failed} failing test)`);
process.exit(failed === 0 ? 0 : 1);
EOF
  git -C "$FIX" init -q
  git -C "$FIX" "${GITC[@]}" add -A
  git -C "$FIX" "${GITC[@]}" commit -qm "acme-cart: cart pricing helpers"

  # A deliberately shell-heavy repository: the indexer has no shell extractor,
  # so this is the honest BYPASS case in step 9.
  mkdir -p "$FIX_SH/bin" "$FIX_SH/lib"
  cat > "$FIX_SH/README.md" <<'EOF'
# ops-scripts
Deployment and rotation scripts. Shell only, on purpose.
EOF
  for f in bin/deploy.sh bin/rotate-logs.sh lib/common.sh lib/checks.sh; do
    mkdir -p "$FIX_SH/$(dirname "$f")"
    printf '#!/usr/bin/env bash\nset -euo pipefail\n\nmain(){\n  echo "%s"\n}\nmain "$@"\n' "$f" > "$FIX_SH/$f"
  done
  git -C "$FIX_SH" init -q
  git -C "$FIX_SH" "${GITC[@]}" add -A
  git -C "$FIX_SH" "${GITC[@]}" commit -qm "ops-scripts: deployment shell"

  # A repository that never wrote down how to test itself: the honest GUESSED
  # case in step 2.
  mkdir -p "$FIX_UD/src"
  cat > "$FIX_UD/package.json" <<'EOF'
{
  "name": "undocumented-service",
  "private": true,
  "type": "module",
  "devDependencies": { "vitest": "^1.6.0" }
}
EOF
  printf 'export const ping = () => "pong";\n' > "$FIX_UD/src/ping.js"
  git -C "$FIX_UD" init -q
  git -C "$FIX_UD" "${GITC[@]}" add -A
  git -C "$FIX_UD" "${GITC[@]}" commit -qm "undocumented-service"
  return 0
}

# The 13-field descriptors, written honestly for each task. mode-select.mjs
# refuses a partial descriptor, so every field is answered.
D_DIRECT='{"expected_files_changed":1,"requires_tests":false,"expected_session_count":1,"prior_context_required":false,"handoff_required":false,"consequence_level":"low","irreversible_or_external_mutation":false,"high_blast_radius":false,"unclear_acceptance_criteria":false,"security_or_compliance_consequence":false,"parallel_workstreams_benefit":false,"high_rework_history":false,"nondeterministic_verification":false}'
D_LIGHT='{"expected_files_changed":3,"requires_tests":true,"expected_session_count":1,"prior_context_required":true,"handoff_required":false,"consequence_level":"medium","irreversible_or_external_mutation":false,"high_blast_radius":false,"unclear_acceptance_criteria":false,"security_or_compliance_consequence":false,"parallel_workstreams_benefit":false,"high_rework_history":false,"nondeterministic_verification":false}'
D_FULL='{"expected_files_changed":6,"requires_tests":true,"expected_session_count":2,"prior_context_required":true,"handoff_required":true,"consequence_level":"high","irreversible_or_external_mutation":false,"high_blast_radius":true,"unclear_acceptance_criteria":false,"security_or_compliance_consequence":true,"parallel_workstreams_benefit":true,"high_rework_history":false,"nondeterministic_verification":false}'
D_WITHHELD='{"expected_files_changed":5,"requires_tests":true,"expected_session_count":1,"prior_context_required":true,"handoff_required":false,"consequence_level":"medium","irreversible_or_external_mutation":false,"high_blast_radius":false,"unclear_acceptance_criteria":false,"security_or_compliance_consequence":false,"parallel_workstreams_benefit":false,"high_rework_history":false,"nondeterministic_verification":false}'

hook_event(){ # <tool_name> <json-fragment-for-tool_input>
  printf '{"session_id":"demo","tool_name":"%s","tool_input":%s}' "$1" "$2"
}

# ================================================================== step 1 ====
step1(){
  {
    say "The runtime is versioned and self-checking: it refuses to ship content"
    say "that no longer matches its own manifest."
    say ""
    bash "$SRC/build-os/runtime/gravito-runtime.sh" version | sed -n '1p;$p'
    say ""
    say "Installing into the fixture repository at:"
    say "  $FIX"
    say ""
    bash "$SRC/build-os/runtime/gravito-runtime.sh" install "$FIX"
    say ""
    say "Status after install (per-file: current / drifted-local / upgrade-available):"
    bash "$SRC/build-os/runtime/gravito-runtime.sh" status "$FIX"
    say ""
    say "The install is no-overwrite and idempotent, it records an install receipt,"
    say "and 'rollback' restores the most recent backup. Nothing outside the named"
    say "target repository was touched."
  } > "$A/01-installation.txt" 2>&1
  cat "$A/01-installation.txt"
}

# ================================================================== step 2 ====
step2(){
  local outdir="$A/intake-acme" outdir2="$A/intake-undocumented"
  {
    say "Intake is what Gravito runs the first time it enters a repository it has"
    say "never seen. Watch the labels, not the findings."
    say ""
    bash "$SRC/build-os/intake/repo-intake.sh" "$FIX" --out "$outdir"
    say ""
    say "== Command discovery (from the report) =="
    sed -n '/^## Command discovery/,/^## Repo-local instructions/p' "$outdir/INTAKE_REPORT.md" | sed '$d'
    say "== Baseline =="
    sed -n '/^## Baseline/,/^## Task graph seed/p' "$outdir/INTAKE_REPORT.md" | sed '$d'
    say "== Unsupported assumptions — what intake could NOT determine =="
    sed -n '/^## Unsupported assumptions/,$p' "$outdir/INTAKE_REPORT.md"
    say ""
    say "A GUESSED command, from a second repository that never wrote down how to"
    say "test itself — the guess is labelled a guess, never promoted to a discovery:"
    bash "$SRC/build-os/intake/repo-intake.sh" "$FIX_UD" --out "$outdir2" >/dev/null 2>&1
    sed -n '/^## Command discovery/,/^## Repo-local instructions/p' "$outdir2/INTAKE_REPORT.md" | sed '$d'
    say ""
    say "The fixture has a real failing test. Intake did NOT run it — the baseline is"
    say "off by default, so the report says NOT MEASURED rather than guessing green."
    say "Running the repository's own test command by hand, live:"
    ( cd "$FIX" && node tests/run.mjs ); say "  exit code: $? (the cent-rounding defect is genuine)"
  } > "$A/02-intake.txt" 2>&1
  cp "$outdir/INTAKE_REPORT.md" "$A/02-INTAKE_REPORT.md"
  cat "$A/02-intake.txt"
}

# ================================================================== step 3 ====
step3(){
  local ev rc1 rc2 blocked="$A/.block.txt"
  ev="$(hook_event Write '{"file_path":"'"$FIX"'/src/money.js","content":"export function roundCents(a){return Math.round(a*100)/100;}"}')"
  {
    say "A worker tries to edit src/money.js with no routing decision on record."
    say "The installed hook is the same file the runtime just installed:"
    say "  $FIX/.claude/hooks/routing-gate.sh"
    say ""
    printf '%s' "$ev" | CLAUDE_PROJECT_DIR="$FIX" bash "$FIX/.claude/hooks/routing-gate.sh" mutgate > "$blocked" 2>&1
    rc1=$?
    cat "$blocked"
    say "BLOCKED-EXIT: $rc1   (exit 2 is the platform's block signal; stderr is what the model sees)"
    say ""
    say "The refusal carries its own recovery. Running exactly that command:"
    bash "$FIX/build-os/tools/route-task.sh" \
      --task-id fix-cent-rounding \
      --description "fix the cent-rounding defect in src/money.js" \
      --descriptor "$D_DIRECT"
    say ""
    say "Retrying the identical edit:"
    printf '%s' "$ev" | CLAUDE_PROJECT_DIR="$FIX" bash "$FIX/.claude/hooks/routing-gate.sh" mutgate
    rc2=$?
    say "RECOVERED-EXIT: $rc2   (admitted, and recorded in the ledger)"
    say ""
    say "Honest bound, volunteered: this is NOT a sandbox. It disciplines honest"
    say "work and leaves an audit trail; the platform's permission system is the"
    say "real fence. Hooks also load at SESSION START, so the session that installs"
    say "them is not governed by them — the next one is."
  } > "$A/03-blocked-and-recovered.txt" 2>&1
  rm -f "$blocked"
  cat "$A/03-blocked-and-recovered.txt"
}

# ================================================================== step 4 ====
step4(){
  {
    say "Three honest descriptors, three depths. The selector is mechanical: it"
    say "reads thirteen declared fields and refuses a partial descriptor."
    say ""
    say "(a) rename a local variable — one file, no tests, low consequence"
    printf '    selected: '; node "$FIX/build-os/tools/mode-select.mjs" "$D_DIRECT"
    bash "$FIX/build-os/tools/route-task.sh" --task-id rename-a-local-variable \
      --description "rename a local variable in src/cart.js" --descriptor "$D_DIRECT" | sed 's/^/    /'
    say ""
    say "(b) add a currency formatter — three files, needs tests, medium consequence"
    printf '    selected: '; node "$FIX/build-os/tools/mode-select.mjs" "$D_LIGHT"
    bash "$FIX/build-os/tools/route-task.sh" --task-id add-a-currency-formatter \
      --description "add a currency formatter used by the cart" --descriptor "$D_LIGHT" | sed 's/^/    /'
    say ""
    say "(c) harden checkout pricing — six files, two sessions, a handoff, high"
    say "    consequence, wide blast radius, security consequence declared true"
    printf '    selected: '; node "$FIX/build-os/tools/mode-select.mjs" "$D_FULL"
    bash "$FIX/build-os/tools/route-task.sh" --task-id harden-checkout-pricing \
      --description "harden checkout pricing across the cart and tax path" --descriptor "$D_FULL" | sed 's/^/    /'
    say ""
    say "NOT A RIGGED DEMO. A descriptor that is merely COMPLEX does not earn Full."
    say "Five files, but every value factor answered false:"
    printf '    selected: '; node "$FIX/build-os/tools/mode-select.mjs" "$D_WITHHELD" 2>"$A/.withheld.txt"
    say "    the selector's own reasoning, printed not swallowed:"
    sed 's/^/      /' "$A/.withheld.txt"
    rm -f "$A/.withheld.txt"
    say ""
    say "Complexity alone is not evidence that the expensive depth buys anything."
    say "That rule came from a measured 3.9x overrun on a correctly-complex task."
  } > "$A/04-depth-selection.txt" 2>&1
  cat "$A/04-depth-selection.txt"
}

# ================================================================== step 5 ====
step5(){
  rm -rf "$CUSTVIEW"; mkdir -p "$CUSTVIEW"
  cp -a "$STORE/." "$CUSTVIEW/" 2>/dev/null || true
  say "The customer surface is read-only and speaks customer words: Direct / Light"
  say "/ Full, helper agents, budgets, evidence. No task ids from the doctrine, no"
  say "internal role names, no counts nobody measured."
  say ""
  say "NAMED LIMITATION, not hidden: the default store path still contains an"
  say "internal word in its directory name, so the demo points the read-only shell"
  say "at a copy of the same evidence under a customer-worded path:"
  say "  $CUSTVIEW"
  say "Renaming the store itself is outstanding work, not a solved problem."
  say ""
  {
    bash "$SRC/build-os/shell/gravito" tasks --dir "$CUSTVIEW"
    printf '\n'
    bash "$SRC/build-os/shell/gravito" task harden-checkout-pricing --dir "$CUSTVIEW"
    printf '\n'
    bash "$SRC/build-os/shell/gravito" task fix-cent-rounding --dir "$CUSTVIEW"
  } > "$A/05-customer-display.txt" 2>&1
  cat "$A/05-customer-display.txt"
  say ""
  say "Two cards on purpose. The first has no live record yet and says UNAVAILABLE"
  say "rather than 0; the second, the task from step 3, carries the counts the hook"
  say "actually took. An unknown is never rendered as a measured zero."
}

# ================================================================== step 6 ====
step6(){
  local rec
  rec="$(find "$STORE" -maxdepth 1 -name 'routing-fix-cent-rounding-*.md' | sort | tail -n1)"
  {
    say "Everything the previous steps claimed is a file you can read."
    say ""
    say "== The routing receipt issued during the block recovery =="
    say "   $rec"
    grep -vE '^#' "$rec" | sed -n '1,14p'
    say ""
    say "== The activity ledger — one append-only row per gate decision =="
    say "   $STORE/live_gate_log.tsv"
    cat "$STORE/live_gate_log.tsv"
    say ""
    say "== The per-task live record (counts are DERIVED by counting rows) =="
    find "$STORE/live_state" -name '*.tsv' -exec basename {} \; | sort | sed 's/^/   /'
    say ""
    say "Read the label rows in a live record and you will see each count carry its"
    say "tier: EXACT where a hook counted it, ESTIMATE for the character-based token"
    say "proxy, and unavailable_live for tokens and spend, which are not visible to"
    say "a shell mid-session and are never invented."
  } > "$A/06-evidence.txt" 2>&1
  cat "$A/06-evidence.txt"
}

# ================================================================== step 7 ====
step7(){
  local rec base sf n_task open_base
  # A strictly later receipt stamp than anything issued above: the live gate
  # governs the NEWEST open receipt, and the demo will not guess which that is.
  sleep 1
  bash "$SRC/build-os/tools/route-task.sh" --task-id wide-fanout-refactor \
    --description "split the pricing module across the cart and tax path" \
    --descriptor "$D_FULL" --out "$STORE" > "$A/.route7.txt" 2>&1 || { cat "$A/.route7.txt"; return 1; }
  rec="$(find "$STORE" -maxdepth 1 -name 'routing-wide-fanout-refactor-*.md' | sort | tail -n1)"
  base="$(basename "$rec")"
  open_base="$(CLAUDE_PROJECT_DIR="$FIX" bash "$FIX/.claude/hooks/routing-gate.sh" status | sed -n 's/^routing-gate: status receipt=//p')"
  [ "$open_base" = "$base" ] || die "the open receipt is $open_base, not $base — refusing to demonstrate a breach against the wrong receipt"
  sf="$STORE/live_state/$(basename "$rec" .md).tsv"
  {
    cat "$A/.route7.txt"
    say ""
    say "Budget for Full: 3 helper agents. We now attempt FOUR — a real fan-out"
    say "breach, driven through the same installed hook."
    local i rc
    for i in 1 2 3 4; do
      printf '%s' "$(hook_event Task '{"subagent_type":"explorer","prompt":"survey the pricing call sites"}')" \
        | CLAUDE_PROJECT_DIR="$FIX" bash "$FIX/.claude/hooks/routing-gate.sh" gate > "$A/.g.txt" 2>&1
      rc=$?
      if [ "$rc" -eq 0 ]; then say "  dispatch $i: ADMITTED (exit 0)"; else
        say "  dispatch $i: REFUSED (exit $rc) —"; sed 's/^/    /' "$A/.g.txt"
      fi
    done
    rm -f "$A/.g.txt"
    say ""
    say "The brake fired BEFORE the spend, and stamped the degradation itself:"
    grep '^degradation_note:' "$rec" | sed 's/^/  /'
    n_task="$(awk -F'\t' '$2=="task_dispatch"{n++} END{print n+0}' "$sf")"
    say "  helper runs actually admitted (EXACT, counted from the live record): $n_task"
    say ""
    say "== CLOSE A: the same run, written dishonestly =="
    say "Four helper runs claimed against a budget of three, degradation left blank."
    mkdir -p "$WORKSPACE/concealed-close"
    sed -e 's/^degradation_note: .*/degradation_note: -/' \
        -e 's/^executed_mode: -/executed_mode: gravito_full/' \
        -e 's/^consumed_subagents: -/consumed_subagents: 4/' \
        "$rec" > "$WORKSPACE/concealed-close/$base"
    bash "$FIX/build-os/tools/routing-check.sh" check --receipt "$WORKSPACE/concealed-close/$base" 2>&1 | sed 's/^/  /'
    local rcc=${PIPESTATUS[0]}
    say "CONCEALED-CLOSE-EXIT: $rcc"
    say ""
    say "== CLOSE B: the same run, written honestly =="
    say "Three helper runs — the number the hook counted — and the degradation the"
    say "brake recorded, left in place."
    sed -i -e 's/^executed_mode: -/executed_mode: gravito_full/' \
           -e "s/^consumed_subagents: -/consumed_subagents: $n_task/" "$rec"
    bash "$FIX/build-os/tools/routing-check.sh" check --receipt "$rec" 2>&1 | sed 's/^/  /'
    local rcd=${PIPESTATUS[0]}
    say "DECLARED-CLOSE-EXIT: $rcd"
    say ""
    say "A breach is survivable. Concealing one is not. Note the close-time gate"
    say "also reports the contribution rows as non-contributing rather than hiding"
    say "them: an admission passes, silence does not."
    say ""
    say "== And in customer words =="
    rm -rf "$CUSTVIEW"; mkdir -p "$CUSTVIEW"; cp -a "$STORE/." "$CUSTVIEW/" 2>/dev/null || true
    bash "$SRC/build-os/shell/gravito" task wide-fanout-refactor --dir "$CUSTVIEW" \
      | sed -n '/THROTTLE/,/^$/p'
  } > "$A/07-degradation.txt" 2>&1
  rm -f "$A/.route7.txt"
  cat "$A/07-degradation.txt"
}

# ================================================================== step 8 ====
step8(){
  local rec
  rec="$(find "$STORE" -maxdepth 1 -name 'routing-wide-fanout-refactor-*.md' | sort | tail -n1)"
  {
    say "WHAT A FRESH WORKER RECEIVES — NO CONVERSATION HISTORY, NO TRANSCRIPT."
    say "Everything below is on disk. A worker started cold, with no memory of this"
    say "session, gets exactly this and nothing else."
    say ""
    say "=== 1. THE ROUTING RECEIPT (the decision, its budgets, and how it closed) ==="
    grep -vE '^#' "$rec"
    say ""
    say "=== 2. THE INTAKE REPORT (the repository, with its labels intact) ==="
    sed -n '1,12p' "$A/02-INTAKE_REPORT.md"
    say "    ... (full report at $A/02-INTAKE_REPORT.md)"
    sed -n '/^## Unsupported assumptions/,$p' "$A/02-INTAKE_REPORT.md"
    say ""
    say "=== 3. THE ACTIVITY LEDGER ROWS FOR THIS TASK ==="
    awk -F'\t' '$2=="wide-fanout-refactor"' "$STORE/live_gate_log.tsv"
    say ""
    say "=== 4. THE COMMANDS THAT RE-DERIVE ALL OF IT ==="
    say "    build-os/tools/routing-check.sh check --dir <store>"
    say "    build-os/shell/gravito tasks --dir <store>"
    say "    build-os/intake/repo-intake.sh <repo> --out <dir>"
    say ""
    say "That is the continuity claim, and it is a modest one: the durable record"
    say "carries the DECISION, the BUDGETS, the COUNTS and the OUTCOME. It does not"
    say "carry intent nobody wrote down. Anything the previous worker only thought"
    say "is gone, and the record says so rather than implying otherwise."
  } > "$A/08-fresh-worker-handoff.txt" 2>&1
  cat "$A/08-fresh-worker-handoff.txt"
}

# ================================================================== step 9 ====
step9(){
  local idx_ts="$A/index-acme-cart.json" idx_sh="$A/index-ops-scripts.json"
  {
    say "The compiler refuses to pretend it understands a repository it cannot read."
    say "The reporter measures the SIGNAL QUALITY of the index behind a capsule and"
    say "is willing to conclude: do not use a capsule here at all."
    say ""
    say "== A: the TS/JS fixture (an index with real extractor coverage) =="
    node "$SRC/build-os/compiler/index/build-index.mjs" build "$FIX" --out "$idx_ts" --deterministic 2>&1 | sed 's/^/  /'
    node "$SRC/build-os/compiler/capability/report.mjs" report --index "$idx_ts" \
      | sed -n '/== PARSER COVERAGE ==/,/^$/p;/== RECOMMENDED USE STATE/,/^$/p;/^VERDICT:/p'
    say ""
    say "== B: the shell-heavy fixture (no shell extractor exists in v0) =="
    node "$SRC/build-os/compiler/index/build-index.mjs" build "$FIX_SH" --out "$idx_sh" --deterministic 2>&1 | sed 's/^/  /'
    node "$SRC/build-os/compiler/capability/report.mjs" report --index "$idx_sh" \
      | sed -n '/== PARSER COVERAGE ==/,/^$/p;/== RECOMMENDED USE STATE/,/^$/p;/^VERDICT:/p'
    node "$SRC/build-os/compiler/capability/report.mjs" report --index "$idx_sh" \
      | sed -n '/STRUCTURAL SIGNAL IS INSUFFICIENT/,/outcome 4/p' | sed 's/^/  /'
    say ""
    say "Both states are reachable, and which one you get is a measurement, not a"
    say "preference. The index describes TRACKED files only — untracked debris is"
    say "absent by construction, not by omission."
  } > "$A/09-compiler-verdicts.txt" 2>&1
  cat "$A/09-compiler-verdicts.txt"
}

# ================================================================= step 10 ====
step10(){
  local exp="$SRC/build-os/experiments/EXP-0004-context-compiler" nres
  nres="$(find "$exp" -type f \( -iname '*result*' -o -iname '*run-record*' \) 2>/dev/null | grep -c . || true)"
  {
    say "The last thing to say about the Context Compiler is what is NOT known."
    say ""
    say "  STATUS: IMPLEMENTED, INERT, PERFORMANCE-UNMEASURED."
    say ""
    say "IMPLEMENTED — these files exist and run:"
    for f in compiler/index/build-index.mjs compiler/capability/report.mjs \
             compiler/SEAMS.md compiler/AB_PREREGISTRATION.md; do
      [ -e "$SRC/build-os/$f" ] && say "    build-os/$f"
    done
    say ""
    say "INERT — by construction, and in its own words:"
    grep -n 'v0 ships INERT' "$SRC/build-os/compiler/SEAMS.md" | sed 's/^/    SEAMS.md:/'
    sed -n '6,8p' "$SRC/build-os/compiler/capability/report.mjs" | sed 's|^// *|    report.mjs: |'
    say "    Nothing in the live routing path calls it. That is deliberate: wiring it"
    say "    mid-preregistration would confound the very run it exists to protect."
    say ""
    say "PERFORMANCE-UNMEASURED — the claim under test, QUOTED rather than restated,"
    say "so the demo cannot quietly upgrade a hypothesis into a result:"
    sed -n "/^The operator's base-case/,/target moved afterward/p" \
      "$SRC/build-os/compiler/AB_PREREGISTRATION.md" | sed 's/^/    | /'
    say ""
    say "    Result records found under $exp: $nres"
    say "    NO A/B RESULT EXISTS YET. Nothing in this demo, and nothing in this"
    say "    repository, has measured those numbers. The preregistration fixes the"
    say "    conclusion vocabulary in advance and makes 'context compilation harmful'"
    say "    exactly as reachable as 'context compilation supported'."
    say ""
    say "If a design partner remembers one sentence from this demo, it should be"
    say "that one: the honest status is recorded before the result, not after it."
  } > "$A/10-compiler-status.txt" 2>&1
  cat "$A/10-compiler-status.txt"
}

# ==================================================================== main ====
printf 'GRAVITO — DESIGN-PARTNER DEMO\n'
printf 'source root: %s\n' "$SRC"
printf 'workspace:   %s\n' "$WORKSPACE"
printf 'fixture:     %s  (created by this script; no customer repository is touched)\n' "$FIX"
[ "$AUTO" = "1" ] && printf 'mode:        --auto (unattended; no pauses)\n'
make_fixture || die "could not create the fixture repository"

run_step 1  step1
run_step 2  step2
run_step 3  step3
run_step 4  step4
run_step 5  step5
run_step 6  step6
run_step 7  step7
run_step 8  step8
run_step 9  step9
run_step 10 step10

printf '\n'
rule
printf 'DEMO COMPLETE — artifacts in %s\n' "$A"
printf 'Every figure shown was produced live by the tool being shown. No savings\n'
printf 'figure, no customer evidence, and no measured performance claim was made.\n'
rule
exit 0
