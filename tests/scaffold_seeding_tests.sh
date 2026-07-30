#!/usr/bin/env bash
# Build OS — SCAFFOLD SEEDING tests.
#
#   bash tests/scaffold_seeding_tests.sh
#
# Deterministic, offline, temp-dirs-only. Every proof below scaffolds into a
# BLANK git repo created here and never writes to this repo, ~/.claude, or any
# real memory.
#
# WHAT IT PROVES, and each one is executed rather than described:
#   1. the customer-facing scaffolds seed from templates/, structurally
#   2. a fresh scaffold contains NONE of this installation's connector names,
#      project narrative, or receipt ids — with a VACUITY GUARD, so a scan that
#      finds no files to read fails instead of passing empty
#   3. the seeded router is BYTE-IDENTICAL to the shipped template (which is
#      what says it did not come from live memory)
#   4. the worked example ships beside the installer, names only fictional
#      tools, and is NEVER copied into a customer's live router path
#   5. never-clobber still holds: a pre-existing customer file is untouched
#   6. the seeded scaffold still yields the block counts the maintenance layer
#      is coupled to (3 / 3 / 5 under `^## `)
#   7. THE LEAK CANARY: a fake connector planted in a TEMP COPY of this repo's
#      live memory does not reach the customer scaffold. This is the assertion
#      that would have caught the original defect.
#   8. the four-installer audit is pinned: which installers seed memory, and
#      from where.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TPL="$SRC/templates/build-os"
PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if ! command -v git >/dev/null 2>&1; then
  echo "git is required for these tests but was not found on PATH" >&2
  exit 6
fi

# The five files the customer-facing scaffolds seed. Paths are relative to the
# destination repo AND to templates/ — the template tree mirrors the layout.
SEEDED=(
  "build-os/memory/tool_router.md"
  "build-os/memory/current_state.md"
  "build-os/memory/residue.md"
  "build-os/packets/active_packet.md"
  "build-os/receipts/README.md"
)

# Terms that must never appear in a customer's seeded memory. Matched as
# CASE-INSENSITIVE SUBSTRINGS (the strict reading: "clay" inside a word still
# counts), because the point is that none of this vocabulary reaches a stranger's
# repo at all.
#
# `Gravito` is on the list, but the GRAVITO:TEMPLATE / GRAVITO:TEMPLATE-EXAMPLE
# markers are the established "this seeds a customer-owned file" convention
# (see build-os/maintenance/templates/standing_gates.md) and DO ship. The scan
# therefore blanks exactly those two tokens first and then requires zero
# remaining occurrences — so the marker is allowed and the narrative is not.
FORBIDDEN=(
  "Apollo" "Clay" "HubSpot" "Supabase" "Slack" "Notion" "Stripe" "Higgsfield"
  "Netlify" "Docusign" "Otter" "Zapier" "Hugging Face" "pooler" "empathiq"
  "Gravito" "ClaudeOrchestrator" "Perplexity" "Firecrawl"
)

# Narrative shapes, as regular expressions: a receipt id, a real work-branch
# name, and a packet-close line that names an id. A template may carry the LABEL
# "Last closed packet:" (it does, with the value "none"); what it must never
# carry is a closed packet's identity.
FORBIDDEN_RE=(
  '\bP-[0-9]{3}\b'
  'claude/[a-z0-9][a-z0-9-]*'
  'Last closed packet:\*\* *[A-Z]'
)

blank_repo(){
  local d="$WORK/$1"
  mkdir -p "$d"
  git -C "$d" init -q
  printf '# customer app\n' > "$d/README.md"
  echo "$d"
}

# Concatenate the seeded files of a scaffold, with the sanctioned markers
# blanked. `count_seeded` is separate and runs in the CALLER's shell, because a
# counter incremented inside a command substitution never reaches the caller —
# which is exactly how a vacuity guard goes blind.
scan_text(){
  local dir="$1" f
  for f in "${SEEDED[@]}"; do
    [ -f "$dir/$f" ] || continue
    sed -e 's/GRAVITO:TEMPLATE-EXAMPLE//g' -e 's/GRAVITO:TEMPLATE//g' "$dir/$f"
  done
}
count_seeded(){
  local dir="$1" f n=0
  for f in "${SEEDED[@]}"; do [ -f "$dir/$f" ] && n=$((n+1)); done
  echo "$n"
}

echo "== 1. The customer scaffolds seed from templates/, not from live memory =="
for t in "${SEEDED[@]}"; do
  [ -f "$TPL/${t#build-os/}" ] && ok "template shipped: templates/$t" || no "template MISSING: templates/$t"
done
[ -f "$TPL/memory/tool_router.example.md" ] \
  && ok "template shipped: templates/build-os/memory/tool_router.example.md" \
  || no "template MISSING: the worked example router"
for inst in init-build-os.sh install-project.sh; do
  # The COPY SITE itself, not a comment: every `cp` whose destination is the
  # scaffolded path must take its source from the template tree.
  BAD="$(grep -nE 'cp +"\$(SRC|TEMPLATES)[^"]*" +"\$DEST/\$rel"' "$SRC/$inst" | grep -v 'TEMPLATES/\$rel\|SRC/templates/\$rel')"
  if [ -n "$BAD" ]; then
    no "$inst copies the scaffold from a non-template source: $(printf '%s' "$BAD" | head -1)"
  else
    ok "$inst's scaffold copy site reads from the template tree only"
  fi
  grep -qE 'cp "\$(TEMPLATES|SRC/templates)/\$rel"' "$SRC/$inst" \
    && ok "$inst seeds from templates/" || no "$inst has no templates/ copy site"
done

echo "== 2. Fresh init-build-os.sh into a blank repo: no operational state leaks =="
R1="$(blank_repo repo1)"
( cd "$R1" && "$SRC/init-build-os.sh" ) > "$WORK/install1.log" 2>&1
I1=$?
[ $I1 -eq 0 ] && ok "init-build-os.sh exits 0 in a blank repo" || no "init-build-os.sh exited $I1: $(tail -3 "$WORK/install1.log")"
for f in "${SEEDED[@]}"; do
  [ -f "$R1/$f" ] && ok "seeded: $f" || no "not seeded: $f"
done

SCAN1="$(scan_text "$R1")"
N1="$(count_seeded "$R1")"
# VACUITY GUARD — a scan with nothing to read must fail, not pass quietly.
if [ "$N1" -eq "${#SEEDED[@]}" ]; then
  ok "forbidden-term scan read all ${#SEEDED[@]} seeded files (not vacuous)"
else
  no "VACUOUS SCAN: read $N1 of ${#SEEDED[@]} seeded files — every clean verdict below is meaningless"
fi
[ -n "$SCAN1" ] && ok "scanned content is non-empty" || no "VACUOUS SCAN: seeded files are all empty"

for term in "${FORBIDDEN[@]}"; do
  if printf '%s' "$SCAN1" | grep -qiF -- "$term"; then
    no "LEAK: seeded memory contains '$term'"
  else
    ok "absent from seeded memory: '$term'"
  fi
done
for re in "${FORBIDDEN_RE[@]}"; do
  if printf '%s' "$SCAN1" | grep -qE -- "$re"; then
    no "LEAK: seeded memory matches /$re/ ($(printf '%s' "$SCAN1" | grep -oE -- "$re" | sort -u | head -3 | tr '\n' ' '))"
  else
    ok "absent from seeded memory: /$re/"
  fi
done
# The receipts directory ships a README and nothing else — no closed-packet history.
RCOUNT="$(find "$R1/build-os/receipts" -maxdepth 1 -type f | wc -l | tr -d ' ')"
[ "$RCOUNT" = "1" ] && ok "receipts/ ships only its README (no inherited receipts)" || no "receipts/ contains $RCOUNT files"

echo "== 3. The seeded files are byte-identical to the shipped templates =="
for f in "${SEEDED[@]}"; do
  if cmp -s "$TPL/${f#build-os/}" "$R1/$f"; then
    ok "byte-identical to template: $f"
  else
    no "seeded copy differs from its template (so it came from somewhere else): $f"
  fi
done

echo "== 4. The worked example teaches, and is never seeded =="
EX="$TPL/memory/tool_router.example.md"
for tool in "acme-tickets" "example-db" "widget-deploy"; do
  grep -qF -- "$tool" "$EX" && ok "example router names the fictional tool '$tool'" || no "example router lacks '$tool'"
done
grep -qiE "never copied|not (your|seeded)" "$EX" && ok "example router says in its own header that it is not seeded" || no "example router does not disclaim itself"
grep -qE '\*\*STOP\*\*' "$EX" && ok "example router shows an external-mutation STOP row" || no "example router has no STOP row"
grep -qiE "gated write" "$EX" && ok "example router shows a gated-write row" || no "example router has no gated-write row"
grep -qiE "read-only" "$EX" && ok "example router shows a read-only row" || no "example router has no read-only row"
[ ! -e "$R1/build-os/memory/tool_router.example.md" ] \
  && ok "the example is NOT copied into the customer's memory dir" \
  || no "the example router was seeded into the customer's live memory"
for tool in "acme-tickets" "example-db" "widget-deploy"; do
  grep -qF -- "$tool" "$R1/build-os/memory/tool_router.md" \
    && no "the fictional tool '$tool' bled into the customer's live router" \
    || ok "fictional tool '$tool' stays out of the live router"
done
# The live template must ship an EMPTY external table — a row here is a tool the
# customer does not have.
if grep -qE '^\| *(Web research|Send mail|Media generation|Browser)' "$TPL/memory/tool_router.md"; then
  no "the shipped router template still carries connector rows"
else
  ok "the shipped router template carries zero connector rows"
fi
grep -qiE "add a row when you connect a tool" "$TPL/memory/tool_router.md" \
  && ok "the router template tells the customer to add a row per connected tool" \
  || no "the router template lacks the extend instruction"
for marker_file in "${SEEDED[@]}"; do
  grep -qF "GRAVITO:TEMPLATE" "$R1/$marker_file" \
    && ok "carries the GRAVITO:TEMPLATE marker: $marker_file" \
    || no "no GRAVITO:TEMPLATE marker in: $marker_file"
done

echo "== 5. Never-clobber: a pre-existing customer file is untouched =="
R2="$(blank_repo repo2)"
mkdir -p "$R2/build-os/memory" "$R2/build-os/packets" "$R2/build-os/receipts"
i=0
for f in "${SEEDED[@]}"; do
  i=$((i+1))
  printf '# CUSTOMER FILE %s\n\n## Mine\n\nDo not touch. %s\n' "$i" "$f" > "$R2/$f"
  sha256sum < "$R2/$f" > "$WORK/pre.$i"
done
( cd "$R2" && "$SRC/init-build-os.sh" ) > "$WORK/install2.log" 2>&1
i=0
for f in "${SEEDED[@]}"; do
  i=$((i+1))
  if [ "$(sha256sum < "$R2/$f")" = "$(cat "$WORK/pre.$i")" ]; then
    ok "customer file preserved byte-identical: $f"
  else
    no "customer file was CLOBBERED: $f"
  fi
done

echo "== 6. Block-count coupling with the maintenance layer (^## on the rotating files) =="
# rotate-memory.mjs's FILE_SPECS segments these three files on `^## `, and its
# real-content proof needs >= 3 blocks in every one of them. The scaffold has
# always supplied 3 / 3 / 5; the clean templates must still.
ROT="$SRC/build-os/maintenance/rotate-memory.mjs"
if [ -f "$ROT" ] && [ "$(grep -c 'blockDelimiter: /\^## /' "$ROT")" = "3" ]; then
  ok "FILE_SPECS still uses ^##  as the delimiter for all three rotating files"
else
  no "FILE_SPECS delimiters changed — this coupling must be re-measured"
fi
count_blocks(){ grep -c '^## ' "$1" 2>/dev/null || echo 0; }
CS="$(count_blocks "$R1/build-os/memory/current_state.md")"
RS="$(count_blocks "$R1/build-os/memory/residue.md")"
AP="$(count_blocks "$R1/build-os/packets/active_packet.md")"
[ "$CS" = "3" ] && ok "current_state.md yields 3 blocks" || no "current_state.md yields $CS blocks (want 3)"
[ "$RS" = "3" ] && ok "residue.md yields 3 blocks" || no "residue.md yields $RS blocks (want 3)"
[ "$AP" = "5" ] && ok "active_packet.md yields 5 blocks" || no "active_packet.md yields $AP blocks (want 5)"
SMALLEST="$CS"; [ "$RS" -lt "$SMALLEST" ] && SMALLEST="$RS"; [ "$AP" -lt "$SMALLEST" ] && SMALLEST="$AP"
[ "$SMALLEST" -ge 3 ] \
  && ok "every rotating file clears the two-pass floor (smallest = $SMALLEST >= 3)" \
  || no "smallest rotating-file block count is $SMALLEST — the maintenance suite's real-content proof needs >= 3"
# A hard stop stated only in a rotating template would have to be mirrored
# verbatim into standing_gates.md; the templates avoid the token entirely.
if grep -l "HARD STOP" "$R1/build-os/memory/current_state.md" "$R1/build-os/memory/residue.md" "$R1/build-os/packets/active_packet.md" >/dev/null 2>&1; then
  no "a seeded rotating file states a HARD STOP — the mirror rule requires it in standing_gates.md"
else
  ok "no seeded rotating file states a HARD STOP (nothing to mirror)"
fi

echo "== 7. install-project.sh seeds the same clean scaffold =="
R3="$(blank_repo repo3)"
"$SRC/install-project.sh" --no-session-hook "$R3" > "$WORK/installp.log" 2>&1
IP=$?
[ $IP -eq 0 ] && ok "install-project.sh exits 0 in a blank repo" || no "install-project.sh exited $IP: $(tail -3 "$WORK/installp.log")"
SCAN3="$(scan_text "$R3")"
N3="$(count_seeded "$R3")"
[ "$N3" -eq "${#SEEDED[@]}" ] && ok "install-project scan is not vacuous ($N3 files)" || no "VACUOUS SCAN over install-project scaffold ($N3 files)"
P_LEAKS=""
for term in "${FORBIDDEN[@]}"; do
  printf '%s' "$SCAN3" | grep -qiF -- "$term" && P_LEAKS="$P_LEAKS $term"
done
for re in "${FORBIDDEN_RE[@]}"; do
  printf '%s' "$SCAN3" | grep -qE -- "$re" && P_LEAKS="$P_LEAKS /$re/"
done
[ -z "$P_LEAKS" ] && ok "install-project scaffold contains none of the forbidden terms" || no "install-project scaffold leaks:$P_LEAKS"
CLEAN=1
for f in "${SEEDED[@]}"; do cmp -s "$TPL/${f#build-os/}" "$R3/$f" || CLEAN=0; done
[ "$CLEAN" = 1 ] && ok "install-project seeds all five files byte-identical to the templates" || no "install-project seeded a file that is not the template"

echo "== 8. THE LEAK CANARY: poisoned live memory must not reach a customer =="
COPY="$WORK/repocopy"
mkdir -p "$COPY"
cp -a "$SRC/." "$COPY/" 2>/dev/null
rm -rf "$COPY/.git"
case "$COPY" in "$WORK"/*) ok "the canary is planted in a temp copy, never in this repo" ;;
  *) no "refusing to plant a canary outside the temp dir"; COPY="" ;;
esac
if [ -n "$COPY" ]; then
  CANARY="CANARY-CONNECTOR-9f3c1a-DO-NOT-SHIP"
  # Record the real files' hashes so a stray write to them cannot go unnoticed.
  REAL_BEFORE="$WORK/real.before"; : > "$REAL_BEFORE"
  for f in "${SEEDED[@]}"; do [ -f "$SRC/$f" ] && sha256sum "$SRC/$f" >> "$REAL_BEFORE"; done
  PLANTED=0
  for f in "${SEEDED[@]}"; do
    if [ -f "$COPY/$f" ]; then
      printf '\n| %s | %s MCP | builder | write access, no gate |\n' "$CANARY" "$CANARY" >> "$COPY/$f"
      PLANTED=$((PLANTED+1))
    fi
  done
  [ "$PLANTED" -ge 1 ] \
    && ok "planted the canary in $PLANTED live memory file(s) of the copy" \
    || no "VACUOUS CANARY: nothing was planted, so the test below proves nothing"
  grep -qF "$CANARY" "$COPY/build-os/memory/tool_router.md" \
    && ok "the copy's live tool_router.md really does carry the canary" \
    || no "VACUOUS CANARY: the copy's live router does not carry the canary"

  R4="$(blank_repo repo4)"
  ( cd "$R4" && "$COPY/init-build-os.sh" ) > "$WORK/install4.log" 2>&1
  I4=$?
  [ $I4 -eq 0 ] && ok "init-build-os.sh from the poisoned copy exits 0" || no "poisoned-copy install exited $I4: $(tail -3 "$WORK/install4.log")"
  CSCAN="$(scan_text "$R4")"
  N4="$(count_seeded "$R4")"
  [ "$N4" -eq "${#SEEDED[@]}" ] && ok "canary scan is not vacuous ($N4 files)" || no "VACUOUS canary scan ($N4 files)"
  if printf '%s' "$CSCAN" | grep -qF "$CANARY"; then
    no "LEAK: the canary planted in live memory reached the customer scaffold"
  else
    ok "the canary planted in live memory did NOT reach the customer scaffold"
  fi

  R5="$(blank_repo repo5)"
  "$COPY/install-project.sh" --no-session-hook "$R5" > "$WORK/install5.log" 2>&1
  CSCAN2="$(scan_text "$R5")"
  N5="$(count_seeded "$R5")"
  [ "$N5" -eq "${#SEEDED[@]}" ] && ok "install-project canary scan is not vacuous ($N5 files)" || no "VACUOUS install-project canary scan ($N5 files)"
  if printf '%s' "$CSCAN2" | grep -qF "$CANARY"; then
    no "LEAK: the canary reached the install-project.sh scaffold"
  else
    ok "the canary did NOT reach the install-project.sh scaffold"
  fi

  REAL_AFTER="$WORK/real.after"; : > "$REAL_AFTER"
  for f in "${SEEDED[@]}"; do [ -f "$SRC/$f" ] && sha256sum "$SRC/$f" >> "$REAL_AFTER"; done
  if diff -q "$REAL_BEFORE" "$REAL_AFTER" >/dev/null 2>&1; then
    ok "this repo's own live memory files are byte-identical after the canary run"
  else
    no "THIS REPO'S LIVE MEMORY CHANGED during the canary test"
  fi
fi

echo "== 9. Four-installer audit, pinned =="
# init-build-os.sh and install-project.sh seed the five memory files (from
# templates/, asserted above). connect-project.sh seeds none of them.
# install-global.sh writes ONE of them to USER scope, and it now seeds from the
# template too: the two byte-identity pins in tests/build_os_tests.sh were
# repointed at $SEED_ROUTER in the same change, closing the user-scope instance
# of this leak class. All three seeding paths are template-sourced.
grep -qE 'build-os/(memory|packets|receipts)/' "$SRC/connect-project.sh" \
  && no "connect-project.sh now touches memory files — it must not" \
  || ok "connect-project.sh seeds no memory files (bootstrap hook only)"
if grep -q 'cp "$SRC/templates/build-os/memory/tool_router.md" "$USER_BUILD_OS/memory/tool_router.md"' "$SRC/install-global.sh"; then
  ok "install-global.sh seeds the user-scope router from the template (no operator inventory)"
else
  no "LEAK: install-global.sh no longer seeds the user-scope router from templates/"
fi
grep -q 'cp "$SRC/build-os/memory/tool_router.md"' "$SRC/install-global.sh" \
  && no "LEAK: install-global.sh still copies this repo's LIVE router somewhere" \
  || ok "install-global.sh copies the live router nowhere"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
