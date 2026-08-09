#!/usr/bin/env bash
# CONTENT ANCHORS vs LINE NUMBERS.
#
# The migration is only worth its cost if it separates two things a line number
# cannot: text moving because something ELSE changed, and text moving because
# the EVIDENCE changed. So the load-bearing pair here is
#
#   insert above a citation  -> anchored SURVIVES, positional BREAKS
#   edit the cited line      -> anchored goes STALE
#
# Both directions are exercised against fixtures, never the real registry: a
# suite that proves an invariant by mutating the tree it audits has changed the
# thing it was measuring.
set -uo pipefail
cd "$(dirname "$0")/.."
SRC="$PWD"
P=0; F=0
ok(){ P=$((P+1)); echo "  ok   $1"; }
no(){ F=$((F+1)); echo "  FAIL $1"; }
t(){ [ "$2" = "$3" ] && ok "$1" || no "$1 (got '$2' want '$3')"; }

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
R="$WORK/repo"; mkdir -p "$R/build-os/registry" "$R/src"

# A cited file: one distinctive line, plus a duplicated line to test ambiguity.
cat > "$R/src/thing.sh" <<'EOF'
#!/usr/bin/env bash
[ "$count" -ge 3 ] && exit 0 || exit 2
echo same
echo same
EOF

anchor_of(){ node -e '
import("./build-os/registry/anchor-resolve.mjs").then(m=>{
  const a=m.anchorFor(process.argv[1],process.argv[2],Number(process.argv[3]));
  console.log(a.ok?a.ref:("REFUSED:"+a.reason));});' "$R" "$1" "$2"; }
resolve(){ node build-os/registry/anchor-resolve.mjs "$R" "$1" | cut -f2; }
resolved_line(){ node build-os/registry/anchor-resolve.mjs "$R" "$1" | cut -f3; }

echo "== the anchor is computed from CONTENT, and ambiguity is refused =="
A="$(anchor_of src/thing.sh 2)"
case "$A" in src/thing.sh#c:*) ok "line 2 anchors to a content hash: ${A#src/thing.sh}" ;; *) no "line 2 did not anchor ($A)" ;; esac
t "a line whose content appears twice is REFUSED, not resolved to the first" "$(anchor_of src/thing.sh 3)" "REFUSED:AMBIGUOUS_CONTENT"
t "  and so is its twin, symmetrically" "$(anchor_of src/thing.sh 4)" "REFUSED:AMBIGUOUS_CONTENT"
t "a line past the end is refused" "$(anchor_of src/thing.sh 99)" "REFUSED:OUT_OF_RANGE"

echo "== THE POINT: irrelevant movement must NOT invalidate the citation =="
t "the anchor resolves before any edit" "$(resolve "$A")" "RESOLVED"
t "  to line 2" "$(resolved_line "$A")" "2"
# Insert well ABOVE the cited line — the evidence itself is untouched.
printf '# a new banner comment\n# and another\n# and a third\n' > "$WORK/pre"
cat "$WORK/pre" "$R/src/thing.sh" > "$WORK/t" && mv "$WORK/t" "$R/src/thing.sh"
t "after inserting 3 lines above it, the anchor STILL RESOLVES" "$(resolve "$A")" "RESOLVED"
t "  and reports the NEW line number, having followed the content" "$(resolved_line "$A")" "5"
# The contrast that justifies the migration: the positional form is now wrong.
OLDLINE=2
t "  meanwhile the positional ref src/thing.sh:2 now points at a DIFFERENT line" \
  "$(sed -n "${OLDLINE}p" "$R/src/thing.sh")" "# and another"

echo "== and RELEVANT change must invalidate it, loudly =="
sed -i 's/\[ "\$count" -ge 3 \]/[ "$count" -ge 4 ]/' "$R/src/thing.sh"
t "editing the CITED line itself makes the anchor STALE" "$(resolve "$A")" "STALE"
# Staleness is the anchor working. A positional ref would have kept resolving
# to a line that no longer says what was cited, and reported nothing at all.
t "  a positional ref would still 'resolve' to that changed line, silently" \
  "$(sed -n '5p' "$R/src/thing.sh" | grep -c 'ge 4')" "1"

echo "== a deleted cited line is STALE, not silently re-pointed =="
B="$(anchor_of src/thing.sh 1)"
sed -i '1d' "$R/src/thing.sh"
t "removing the cited line makes its anchor STALE" "$(resolve "$B")" "STALE"

echo "== ambiguity introduced LATER is caught, not resolved arbitrarily =="
cat > "$R/src/dup.sh" <<'EOF'
unique marker line
EOF
C="$(anchor_of src/dup.sh 1)"
t "the unique line resolves" "$(resolve "$C")" "RESOLVED"
echo "unique marker line" >> "$R/src/dup.sh"
t "  once a second copy exists, the anchor reports AMBIGUOUS rather than picking one" "$(resolve "$C")" "AMBIGUOUS"

echo "== the migration converts FORM, never authorization =="
cat > "$R/build-os/registry/reg.txt" <<'EOF'
id: demo.control
evidence_refs: src/thing.sh:2; src/thing.sh:3
notes: -
EOF
cp "$R/src/thing.sh" "$WORK/keep"; printf '#!/usr/bin/env bash\n[ "$count" -ge 3 ] && exit 0 || exit 2\necho same\necho same\n' > "$R/src/thing.sh"
OUT="$(node build-os/registry/migrate-anchors.mjs --registry "$R/build-os/registry/reg.txt" --repo "$R" --ledger "$R/ledger.tsv" --stamp 2026-08-09 --apply)"
t "one ref migrated" "$(printf '%s' "$OUT" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(JSON.parse(s).migrated))')" "1"
t "  and the ambiguous one refused" "$(printf '%s' "$OUT" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(JSON.parse(s).refused))')" "1"
grep -q 'src/thing.sh#c:' "$R/build-os/registry/reg.txt" \
  && ok "the registry now carries the anchored form" || no "the registry was not rewritten"
grep -q 'src/thing.sh:3' "$R/build-os/registry/reg.txt" \
  && ok "the REFUSED ref stays POSITIONAL — visible as backlog, not laundered into a confident anchor" \
  || no "the refused ref was silently converted"
# THE RULE THE OPERATOR SET. A script may convert a citation's form; it may not
# decide the citation is correct. Every ledger row must say so.
t "NO ledger row claims review" "$(awk -F'\t' '$8=="true"' "$R/ledger.tsv" | wc -l | tr -d ' ')" "0"
grep -q "mechanical_migration" "$R/ledger.tsv" \
  && ok "provenance is recorded as mechanical_migration on the converted row" || no "provenance missing"
awk -F'\t' '$4=="MIGRATED" && $2!="-" && $3!="-"' "$R/ledger.tsv" | grep -q . \
  && ok "the ledger records the old ref AND the new ref, so the mapping is reversible" || no "no old->new mapping recorded"
awk -F'\t' '$4=="MIGRATED" && $7!="-" && $7!=""' "$R/ledger.tsv" | grep -q . \
  && ok "...and the literal cited content, so a STALE anchor is diagnosable rather than opaque" || no "content not preserved"

echo "== the real registry after migration =="
t "no positional ref remains that could have been anchored" \
  "$(node build-os/registry/migrate-anchors.mjs --registry build-os/registry/control_registry.txt --repo "$SRC" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(JSON.parse(s).migrated))')" "0"
t "  every remaining positional ref is a RECORDED refusal, not an oversight" \
  "$(node build-os/registry/migrate-anchors.mjs --registry build-os/registry/control_registry.txt --repo "$SRC" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const j=JSON.parse(s);console.log(String(j.refused>0&&Object.keys(j.refusal_reasons).length>0))})')" "true"
grep -c 'anchor_migration\|mechanical_migration' build-os/registry/anchor_migration.tsv >/dev/null \
  && ok "the migration ledger is committed alongside the registry it explains" || no "no ledger"

echo "==== RESULT: $P passed, $F failed ===="
[ "$F" -eq 0 ]
