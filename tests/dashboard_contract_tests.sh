#!/usr/bin/env bash
# Dashboard-contract + onboarding-honesty test suite.
#
# Proves seven things and refuses to pass without them:
#
#   1. every field in DASHBOARD_CONTRACT.md declares a SOURCE and a TIER, and
#      every UNAVAILABLE field declares a REASON;
#   2. the renderer's embedded field registry and the markdown table are the
#      SAME table (drift between the spec and the code is a defect, not a
#      documentation lag);
#   3. the renderer honours tiers — an ESTIMATE renders with its label, an
#      UNAVAILABLE renders `unavailable (<reason>)` and NEVER as 0, and an
#      UNAVAILABLE field stays unavailable even when an input file supplies a
#      value for it (no silent tier promotion);
#   4. the renderer runs against this repository's own real routing store
#      without error (SKIPPED, loudly, when no such store exists here);
#   5. --json emits valid JSON carrying a tier per field;
#   6. the customer view leaks no internal vocabulary;
#   7. the renderer writes nothing outside --out, and no onboarding or
#      dashboard file claims external validation or a fabricated saving.
#
# Deliberately does NOT invoke tests/build_os_tests.sh, and touches nothing
# under build-os/experiments/ or build-os/compiler/.
#
# Dependencies: bash, node (stdlib only), coreutils. No network.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DASH="$ROOT/build-os/dashboard"
ONB="$ROOT/build-os/onboarding"
CONTRACT="$DASH/DASHBOARD_CONTRACT.md"
RENDER="$DASH/render-dashboard.mjs"
FIX="$DASH/fixtures"

PASS=0; FAIL=0; SKIP=0
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dashboard-tests.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

ok(){   PASS=$((PASS+1)); printf '  PASS  %s\n' "$1"; }
no(){   FAIL=$((FAIL+1)); printf '  FAIL  %s\n' "$1"; [ $# -gt 1 ] && printf '        %s\n' "$2"; }
skip(){ SKIP=$((SKIP+1)); printf '  SKIP  %s\n' "$1"; [ $# -gt 1 ] && printf '        %s\n' "$2"; }
sect(){ printf '\n== %s ==\n' "$1"; }

# ---------------------------------------------------------------- 0. present --
sect "0. artifacts exist"

for f in "$CONTRACT" "$RENDER"; do
  if [ -s "$f" ]; then ok "exists and is non-empty: ${f#"$ROOT"/}"
  else no "missing or empty: ${f#"$ROOT"/}"; fi
done

ONBOARDING_FILES=(
  ELIGIBILITY_QUESTIONNAIRE.md DATA_HANDLING.md INSTALL_PREREQUISITES.md
  READ_ONLY_PREFLIGHT.md SUPPORTED_STACKS.md UNSUPPORTED_DISCLOSURE.md
  AUTHORITY_WORKSHEET.md BASELINE_CAPTURE.md SUCCESS_METRIC_TEMPLATE.md
  UNINSTALL_ROLLBACK.md
)
missing_onb=0
for f in "${ONBOARDING_FILES[@]}"; do
  [ -s "$ONB/$f" ] || { missing_onb=$((missing_onb+1)); printf '        missing: %s\n' "$f"; }
done
if [ "$missing_onb" -eq 0 ]; then ok "all ${#ONBOARDING_FILES[@]} onboarding artifacts exist and are non-empty"
else no "$missing_onb of ${#ONBOARDING_FILES[@]} onboarding artifacts missing or empty"; fi

# ------------------------------------------------------- 1. contract table ----
sect "1. the contract table declares source + tier (+ reason where UNAVAILABLE)"

# Table rows look like:  | `field_id` | source | TIER | reason
parse_rows(){
  awk -F'|' '
    /^\| *`[a-z0-9_]+` *\|/ {
      gsub(/^[ \t]+|[ \t]+$/, "", $2); gsub(/`/, "", $2);
      gsub(/^[ \t]+|[ \t]+$/, "", $3);
      gsub(/^[ \t]+|[ \t]+$/, "", $4);
      gsub(/^[ \t]+|[ \t]+$/, "", $5);
      printf "%s\t%s\t%s\t%s\n", $2, $3, $4, $5;
    }' "$CONTRACT"
}

if [ -s "$CONTRACT" ]; then
  ROWS="$(parse_rows)"
  NROWS="$(printf '%s' "$ROWS" | grep -c . || true)"
else
  ROWS=""; NROWS=0
fi

if [ "$NROWS" -ge 12 ]; then ok "contract declares $NROWS fields (>=12)"
else no "contract declares only $NROWS field rows (expected >=12)"; fi

bad_src=0; bad_tier=0; bad_reason=0
while IFS=$'\t' read -r id src tier reason; do
  [ -n "$id" ] || continue
  [ -n "$src" ] || { bad_src=$((bad_src+1)); printf '        no source: %s\n' "$id"; }
  case "$tier" in
    EXACT|ESTIMATE|CLOSE-TIME|UNAVAILABLE) ;;
    *) bad_tier=$((bad_tier+1)); printf '        bad tier %s: %s\n' "${tier:-<empty>}" "$id" ;;
  esac
  if [ "$tier" = "UNAVAILABLE" ]; then
    case "$reason" in
      ""|"-"|"—") bad_reason=$((bad_reason+1)); printf '        UNAVAILABLE with no reason: %s\n' "$id" ;;
    esac
  fi
done <<< "$ROWS"

if [ "$NROWS" -eq 0 ]; then
  no "cannot check sources/tiers/reasons: the contract table has no field rows"
else
  [ "$bad_src"    -eq 0 ] && ok "every contract field declares a source" \
                          || no "$bad_src contract field(s) declare no source"
  [ "$bad_tier"   -eq 0 ] && ok "every contract field declares a tier in {EXACT,ESTIMATE,CLOSE-TIME,UNAVAILABLE}" \
                          || no "$bad_tier contract field(s) declare no legal tier"
  [ "$bad_reason" -eq 0 ] && ok "every UNAVAILABLE field declares a reason" \
                          || no "$bad_reason UNAVAILABLE field(s) declare no reason"
  # An all-EXACT table would be a table that never admits a gap; the contract's
  # whole point is that it does.
  if printf '%s\n' "$ROWS" | cut -f3 | grep -qx 'UNAVAILABLE'; then
    ok "the contract admits at least one UNAVAILABLE field rather than pretending completeness"
  else
    no "the contract declares no UNAVAILABLE field — a system this incomplete cannot honestly have none"
  fi
fi

# --------------------------------------------- 2. registry / table agreement --
sect "2. the renderer's registry and the contract table are the same table"

if [ -s "$RENDER" ] && node "$RENDER" contract --json > "$TMP/registry.json" 2>"$TMP/registry.err"; then
  node -e '
    const fs = require("node:fs");
    const reg = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    const rows = fs.readFileSync(process.argv[2], "utf8").split("\n").filter(Boolean)
      .map((l) => l.split("\t"));
    const byId = new Map(reg.fields.map((f) => [f.id, f]));
    const problems = [];
    for (const [id, src, tier] of rows) {
      const f = byId.get(id);
      if (!f) { problems.push(`contract row ${id} is absent from the renderer registry`); continue; }
      if (f.tier !== tier) problems.push(`${id}: contract tier ${tier} vs registry tier ${f.tier}`);
      if (f.source !== src) problems.push(`${id}: source text differs between contract and registry`);
      byId.delete(id);
    }
    for (const id of byId.keys()) problems.push(`registry field ${id} is absent from the contract table`);
    if (problems.length) { console.error(problems.join("\n")); process.exit(1); }
  ' "$TMP/registry.json" <(printf '%s\n' "$ROWS") 2>"$TMP/agree.err" \
    && ok "registry and contract table agree field-for-field (ids, sources, tiers)" \
    || no "registry and contract table disagree" "$(head -5 "$TMP/agree.err")"
else
  no "renderer cannot emit its field registry (contract --json)" "$(head -3 "$TMP/registry.err" 2>/dev/null)"
fi

# ------------------------------------------------------- 3. fixture render ----
sect "3. the renderer honours tiers on a fixture-backed customer view"

FIXOUT="$TMP/view.txt"
FIXJSON="$TMP/view.json"
render_fixture(){ # $1 out, extra args...
  local out="$1"; shift
  node "$RENDER" \
    --store "$FIX/routing" \
    --ledger "$FIX/routing/live_gate_log.tsv" \
    --window "$FIX/window/WINDOW.tsv" \
    --eligibility "$FIX/eligibility.json" \
    --out "$out" "$@" >"$TMP/render.log" 2>&1
}

if render_fixture "$FIXOUT"; then ok "renders the fixture store without error"
else no "fixture render failed" "$(head -5 "$TMP/render.log")"; fi

if [ -s "$FIXOUT" ]; then ok "fixture render wrote a non-empty view to --out"
else no "fixture render produced no --out content"; fi

# 3a. an ESTIMATE renders WITH its label.
if grep -q 'ESTIMATE' "$FIXOUT" && grep -qE 'Estimated work volume.*ESTIMATE' "$FIXOUT"; then
  ok "an ESTIMATE value renders carrying its ESTIMATE label"
else
  no "no ESTIMATE-labeled value found in the rendered view"
fi

# 3b. UNAVAILABLE renders with a reason and NEVER as 0.
check_unavailable(){ # $1 human label
  local line
  line="$(grep -m1 -F "$1" "$FIXOUT" || true)"
  if [ -z "$line" ]; then no "UNAVAILABLE field not rendered at all: $1"; return; fi
  local val="${line#*:}"
  val="$(printf '%s' "$val" | sed -E 's/^[[:space:]]+//')"
  case "$val" in
    unavailable\ \(*\)*) ;;
    *) no "UNAVAILABLE field '$1' did not render as 'unavailable (<reason>)'" "$line"; return ;;
  esac
  # the reason must be non-trivial, and the value must not be a bare zero
  local reason="${val#unavailable (}"; reason="${reason%%)*}"
  if [ "${#reason}" -lt 20 ]; then no "UNAVAILABLE field '$1' rendered a trivially short reason" "$line"; return; fi
  case "$val" in
    0|0.0|0*[!a-z]*) : ;;
  esac
  if printf '%s' "$val" | grep -qE '^0([^0-9]|$)'; then
    no "UNAVAILABLE field '$1' rendered as 0" "$line"; return
  fi
  ok "UNAVAILABLE renders as 'unavailable (<reason>)', never 0: $1"
}
if [ -s "$FIXOUT" ]; then
  check_unavailable "Accepted outcomes"
  check_unavailable "Human interventions"
  check_unavailable "Rework"
  check_unavailable "Regressions"
  check_unavailable "Context mode"
else
  no "cannot check UNAVAILABLE rendering: no view produced"
fi

# 3c. no silent tier promotion: the fixture receipts deliberately CONTAIN
#     accepted/human_interventions/regressions values. An UNAVAILABLE field must
#     ignore them rather than quietly promote itself to EXACT.
if [ -s "$FIXOUT" ]; then
  if grep -q 'accepted: yes' "$FIX/routing/"*.md 2>/dev/null; then
    if grep -m1 -F "Accepted outcomes" "$FIXOUT" | grep -q 'unavailable ('; then
      ok "an UNAVAILABLE field is not promoted by an input file that supplies a value"
    else
      no "an input value silently promoted an UNAVAILABLE field"
    fi
  else
    no "fixture is missing the tier-promotion bait (accepted: yes) — the test cannot prove the property"
  fi
fi

# ------------------------------------------------------------ 4. real store ---
sect "4. renders this repository's own real routing store"

REAL_STORE="${GRAVITO_STORE:-$ROOT/build-os/packets/routing}"
REAL_N=0
[ -d "$REAL_STORE" ] && REAL_N="$(find "$REAL_STORE" -maxdepth 1 -type f -name '*.md' 2>/dev/null | grep -c . || true)"
if [ "${REAL_N:-0}" -gt 0 ]; then
  if node "$RENDER" --store "$REAL_STORE" --out "$TMP/real.txt" >"$TMP/real.log" 2>&1 && [ -s "$TMP/real.txt" ]; then
    ok "rendered $REAL_N real routing receipt(s) from $REAL_STORE without error"
  else
    no "real-receipt render failed" "$(head -5 "$TMP/real.log")"
  fi
  if node "$RENDER" --store "$REAL_STORE" --json --out "$TMP/real.json" >/dev/null 2>&1 \
     && node -e 'JSON.parse(require("node:fs").readFileSync(process.argv[1],"utf8"))' "$TMP/real.json"; then
    ok "real-receipt --json output is valid JSON"
  else
    no "real-receipt --json output is not valid JSON"
  fi
else
  skip "no routing store in this checkout ($REAL_STORE)" \
       "set GRAVITO_STORE=<dir with routing receipts> to exercise the real-store path"
  skip "real-receipt --json validity (same reason)" ""
fi

# an EMPTY store must render honestly, not as a wall of zeros
mkdir -p "$TMP/emptystore"
if node "$RENDER" --store "$TMP/emptystore" --out "$TMP/empty.txt" >"$TMP/empty.log" 2>&1; then
  if grep -q 'unavailable (' "$TMP/empty.txt" && ! grep -qE '^[[:space:]]+[A-Z][^:]*:[[:space:]]+0$' "$TMP/empty.txt"; then
    ok "an empty store renders unavailable-with-reason, never a wall of zeros"
  else
    no "an empty store rendered zeros instead of unavailable-with-reason"
  fi
else
  no "renderer errored on an empty store instead of rendering honestly" "$(head -3 "$TMP/empty.log")"
fi

# ------------------------------------------------------------- 5. json seam ---
sect "5. --json validity and per-field tiers"

if render_fixture "$FIXJSON" --json; then
  if node -e '
    const fs = require("node:fs");
    const v = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    const tiers = new Set(["EXACT","ESTIMATE","CLOSE-TIME","UNAVAILABLE"]);
    if (!Array.isArray(v.fields) || v.fields.length < 12) throw new Error("fields array missing or too short");
    for (const f of v.fields) {
      if (!tiers.has(f.tier)) throw new Error(`field ${f.id} has no legal tier`);
      if (f.tier === "UNAVAILABLE") {
        if (f.value !== null) throw new Error(`UNAVAILABLE field ${f.id} carries a value`);
        if (!f.reason || f.reason.length < 20) throw new Error(`UNAVAILABLE field ${f.id} carries no reason`);
      }
      if (f.value === null && !f.reason) throw new Error(`field ${f.id} is null with no reason`);
    }
  ' "$FIXJSON" 2>"$TMP/json.err"; then
    ok "--json is valid JSON and every field carries a legal tier (nulls carry reasons)"
  else
    no "--json failed its schema check" "$(head -3 "$TMP/json.err")"
  fi
else
  no "--json render failed" "$(head -5 "$TMP/render.log")"
fi

# ------------------------------------------------------- 6. vocabulary leak ---
sect "6. the customer view leaks no internal vocabulary"

# Case-sensitive on the lowercase doctrine forms, exactly as the customer-shell
# vocabulary contract (build-os/shell/gravito) defines it: a customer's own
# uppercase task id is the CUSTOMER's vocabulary and passes through untouched.
#
# ONE narrow exemption, applied as a SUBSTRING substitution rather than a line
# skip: the on-disk path of the routing store is a path the customer has to be
# able to type, not prose. Replacing exactly that substring means any other
# occurrence of the same word on the same line is still caught.
LEAK_WORDS='\bpacket\b|\bpackets\b|\bcensus\b|\bcensused\b|\barchivist\b|gravito_full|gravito_light|DC-[0-9]+'
scrub_paths(){ sed 's|build-os/packets/routing|<the routing store>|g' "$1"; }
leaks=0
for f in "$FIXOUT" "$FIXJSON" "$TMP/real.txt"; do
  [ -s "$f" ] || continue
  if scrub_paths "$f" | grep -nE "$LEAK_WORDS" >"$TMP/leak.txt" 2>/dev/null; then
    leaks=$((leaks+1)); printf '        leak in %s:\n' "$(basename "$f")"; head -3 "$TMP/leak.txt" | sed 's/^/          /'
  fi
done
[ "$leaks" -eq 0 ] && ok "no internal vocabulary in any rendered customer view" \
                   || no "$leaks rendered view(s) leak internal vocabulary"

# ------------------------------------------------------------ 7. isolation ----
sect "7. the renderer writes nothing outside --out"

if [ ! -s "$RENDER" ]; then
  no "cannot check isolation: the renderer does not exist"
else
  STAMP="$TMP/stamp"; : > "$STAMP"
  sleep 1
  SANDBOX="$TMP/sandbox"; mkdir -p "$SANDBOX"
  node "$RENDER" --store "$FIX/routing" --out "$SANDBOX/out.txt" >/dev/null 2>&1
  CHANGED="$(find "$ROOT" -path "$ROOT/.git" -prune -o -newer "$STAMP" -type f -print 2>/dev/null | head -20)"
  if [ -z "$CHANGED" ]; then ok "no file inside the repository was created or modified by a render"
  else no "the renderer touched repository files" "$(printf '%s' "$CHANGED" | head -3)"; fi

  STRAY="$(find "$SANDBOX" -type f ! -name 'out.txt' | head -5)"
  if [ -z "$STRAY" ] && [ -s "$SANDBOX/out.txt" ]; then
    ok "the renderer wrote exactly one file, its --out path"
  else
    no "the renderer wrote files beside --out, or wrote nothing at all" "${STRAY:-no out.txt produced}"
  fi

  if grep -qE 'build-os/(experiments|compiler)' "$RENDER"; then
    no "the renderer references build-os/experiments or build-os/compiler"
  else
    ok "the renderer never names build-os/experiments or build-os/compiler"
  fi

  if node "$RENDER" --store "$FIX/routing" >/dev/null 2>&1; then
    no "the renderer ran without --out (it must refuse: there is nowhere honest to write)"
  else
    ok "the renderer refuses to run without --out"
  fi
fi

# --------------------------------------------------- 8. no overclaiming ------
sect "8. no onboarding or dashboard file claims external validation"

OVERCLAIM='customers report|proven [0-9]+%|validated by|independently validated|externally validated|trusted by [0-9]|case stud(y|ies) show|industry-leading|[0-9]+% (faster|cheaper|savings)|guaranteed (savings|roi)|our customers'
over=0
NFILES="$(find "$ONB" "$DASH" -type f \( -name '*.md' -o -name '*.mjs' \) 2>/dev/null | grep -c . || true)"
if [ "${NFILES:-0}" -lt 11 ]; then
  no "expected >=11 onboarding+dashboard files to sweep, found ${NFILES:-0}"
else
  ok "swept $NFILES onboarding and dashboard files for overclaiming"
fi
while IFS= read -r f; do
  if grep -nEi "$OVERCLAIM" "$f" >"$TMP/over.txt" 2>/dev/null; then
    # A DENIAL of external validation is the opposite of a claim; allow lines
    # that negate it explicitly (e.g. "no external customer has ... validated").
    if grep -vEi '\b(no|not|never|nobody|zero|has not|have not|cannot)\b' "$TMP/over.txt" | grep -q .; then
      over=$((over+1)); printf '        overclaim in %s:\n' "${f#"$ROOT"/}"
      grep -vEi '\b(no|not|never|nobody|zero|has not|have not|cannot)\b' "$TMP/over.txt" | head -2 | sed 's/^/          /'
    fi
  fi
done < <(find "$ONB" "$DASH" -type f \( -name '*.md' -o -name '*.mjs' \) 2>/dev/null | sort)
[ "$over" -eq 0 ] && ok "no onboarding or dashboard file claims external validation or a fabricated saving" \
                  || no "$over file(s) claim external validation or a fabricated saving"

# every onboarding file must be honest that evidence to date is internal
if grep -rqi 'internal' "$ONB/UNSUPPORTED_DISCLOSURE.md" 2>/dev/null; then
  ok "the unsupported disclosure states the evidence position"
else
  no "UNSUPPORTED_DISCLOSURE.md does not state that evidence to date is internal"
fi

# ------------------------------------------------------------------ summary ---
printf '\n----------------------------------------------------------\n'
printf 'TESTS: %d passed, %d failed, %d skipped\n' "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
