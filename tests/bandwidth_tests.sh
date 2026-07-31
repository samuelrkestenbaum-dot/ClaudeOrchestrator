#!/usr/bin/env bash
# Build OS — work-in-flight capacity (integration bandwidth) tests.
#
# WHAT THIS PINS. build-os/tools/bandwidth-check.sh is the first control in this
# repository whose function is LIMITING WHAT MAY BE ABSORBED rather than judging
# an artefact that already exists. Every other registered control answers yes/no
# about something already written; this one answers "is there room for more".
# The claims that must stay checkable:
#
#   1. EACH DIMENSION IS ENFORCED SEPARATELY. There is no composite load score.
#      A blended `I = w1*packets + w2*commits + ...` would need weights nobody
#      can justify and would hide WHICH dimension is saturated, so the tool
#      declares one ceiling per dimension and every refusal NAMES its dimension.
#   2. AUTHORITY IS PER DIMENSION AND IS EXECUTED, NOT ASSERTED. `packets` is a
#      hard invariant over the artefact and it GATES. `commits` is a chosen
#      constant from the working contract and it only ADVISES — so a suite that
#      never proved the difference would be taking the author's word for the
#      most contestable claim in the entry.
#   3. AN UNOBSERVABLE DIMENSION IS DECLINED, NEVER FAKED. `depth` — how many
#      agent stages ran in series — is transcript-only: nothing in git attests
#      to it. `write_sets` is observable from a fan-out manifest but NO ceiling
#      on concurrent write sets is declared anywhere in the working contract, so
#      enforcing one would mean inventing a constant. Both are declined, with
#      their reasons printed, and NEITHER owns a registry entry. A control that
#      claims a limit it cannot observe is worse than an absent control.
#   4. A DIMENSION THAT CANNOT BE MEASURED THIS RUN REPORTS UNOBSERVABLE. A
#      missing branch base, a base that is not a commit, and a base that is not
#      an ancestor of HEAD each produce UNOBSERVABLE rather than a number.
#   5. THE CEILING IN THE CENSUS IS THE CEILING IN THE TOOL. The registry entry
#      cites the line that defines the constant; that line is read back here and
#      compared against what the tool reports, so the two cannot drift.
#
# No network. Deterministic. Every fixture lives under $WORK; nothing outside it
# is written, and no git configuration outside $WORK is touched (`git -c` only).
# Exits non-zero if any assertion fails.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOL="$SRC/build-os/tools/bandwidth-check.sh"
REG="$SRC/build-os/registry/control_registry.txt"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# The declared dimensions, duplicated here ON PURPOSE. A suite that reads its
# expected set out of the tool it is checking cannot detect the tool quietly
# dropping a dimension or inventing one.
DIMENSIONS="packets commits write_sets depth"
ENFORCED="packets commits"
DECLINED="write_sets depth"
NDIM=0; for _d in $DIMENSIONS; do NDIM=$((NDIM+1)); done

in_list(){ local v="$1" l; for l in $2; do [ "$v" = "$l" ] && return 0; done; return 1; }

# `git -c` rather than `git config`: the identity is supplied per invocation and
# nothing outside $WORK is configured, here or anywhere else in this suite.
G(){ git -c user.name="bandwidth tests" -c user.email="bandwidth@example.invalid" \
       -c init.defaultBranch=main -c commit.gpgsign=false "$@"; }

# mkrepo <dir> <n-commits-after-base> — a scratch repo whose HEAD sits <n>
# commits after the commit whose sha is echoed on stdout.
mkrepo(){
  local d="$1" n="$2" i base
  mkdir -p "$d"
  G -C "$d" init -q >/dev/null 2>&1
  echo base > "$d/base.txt"
  G -C "$d" add -A >/dev/null 2>&1; G -C "$d" commit -qm base >/dev/null 2>&1
  base="$(G -C "$d" rev-parse HEAD)"
  for i in $(seq 1 "$n"); do
    echo "c$i" > "$d/c$i.txt"
    G -C "$d" add -A >/dev/null 2>&1; G -C "$d" commit -qm "c$i" >/dev/null 2>&1
  done
  printf '%s\n' "$base"
}

# mkpacket <file> <n-ids> <branch-base-line-or-NONE>
mkpacket(){
  local f="$1" n="$2" bb="$3" i
  { echo "# Active Packet"; echo
    for i in $(seq 1 "$n"); do echo "- **Packet id:** \`fixture_packet_$i\`"; done
    echo
    if [ "$bb" != "NONE" ]; then
      echo "## Branch base"; echo
      echo "$bb"; echo
    fi
    echo "## Plan"; echo; echo "1. one commit."
  } > "$f"
}

run(){ "$TOOL" "$@" > "$WORK/out.txt" 2> "$WORK/err.txt"; echo $?; }
out(){ cat "$WORK/out.txt" "$WORK/err.txt"; }
# The status word this run gave one dimension, or the empty string.
verdict(){ awk -v d="$1" '$1=="bandwidth:" && $2==d {print $3; exit}' "$WORK/out.txt" "$WORK/err.txt"; }
dump(){ sed 's/^/      | /' "$WORK/out.txt" "$WORK/err.txt" | head -12; }

echo "== 1. The tool exists and is a real, self-describing script =="
[ -f "$TOOL" ] && ok "build-os/tools/bandwidth-check.sh exists" || no "the bandwidth tool is missing"
[ -x "$TOOL" ] && ok "the tool is executable" || no "the tool is not executable"
head -1 "$TOOL" | grep -qE '^#!' && ok "the tool carries a shebang" || no "the tool has no shebang"
RC="$(run dimensions)"
[ "$RC" = "0" ] && ok "\`dimensions\` describes the capacity model and exits 0" \
                || { no "\`dimensions\` exited $RC"; dump; }

echo "== 2. EACH DIMENSION IS DECLARED SEPARATELY — there is no composite load score =="
# The anti-pattern this refuses: one blended number whose weights are
# unjustifiable and which hides which dimension is saturated.
run dimensions >/dev/null
awk '$1=="dimension:"{print $2}' "$WORK/out.txt" | sort > "$WORK/dims.txt"
NSEEN="$(grep -c . "$WORK/dims.txt" || true)"; NSEEN="${NSEEN:-0}"
[ "$NSEEN" = "$NDIM" ] \
  && ok "the tool declares exactly $NDIM dimensions, one line each" \
  || { no "the tool declares $NSEEN dimension line(s), expected $NDIM"; dump; }
MISSD=""
for d in $DIMENSIONS; do grep -qxF "$d" "$WORK/dims.txt" || MISSD="$MISSD $d"; done
[ -z "$MISSD" ] && ok "every declared dimension is named: $DIMENSIONS" \
                || no "dimension(s) never declared:$MISSD"
[ "$(sort -u "$WORK/dims.txt" | grep -c . || true)" = "$NSEEN" ] \
  && ok "no dimension is declared twice" || no "a dimension is declared more than once"
grep -qiE 'composite|weighted (sum|score)|blended|overall load score' "$WORK/out.txt" \
  && no "the tool advertises a composite/blended load score — the exact anti-pattern this design refuses" \
  || ok "no composite, weighted or blended score is offered anywhere in the model"
NENF="$(awk '$1=="dimension:" && /enforced/{n++} END{print n+0}' "$WORK/out.txt")"
NDEC="$(awk '$1=="dimension:" && /declined/{n++} END{print n+0}' "$WORK/out.txt")"
[ "$NENF" = "2" ] && ok "exactly 2 dimensions are enforced (packets, commits)" \
                  || { no "$NENF dimension(s) claim to be enforced, expected 2"; dump; }
[ "$NDEC" = "2" ] && ok "exactly 2 dimensions are declined (write_sets, depth)" \
                  || { no "$NDEC dimension(s) are declined, expected 2"; dump; }

echo "== 3. GREEN — one packet, one commit: inside every enforced ceiling =="
OK1="$WORK/ok1"; BASE1="$(mkrepo "$OK1" 1)"
mkpacket "$OK1/packet.md" 1 "- \`main\` at \`$BASE1\`; verified before building."
RC="$(run check --repo "$OK1" --packet "$OK1/packet.md")"
[ "$RC" = "0" ] && ok "a packet inside every enforced ceiling exits 0" \
                || { no "a compliant packet exited $RC"; dump; }
[ "$(verdict packets)" = "OK" ] && ok "packets: OK (1 in flight, ceiling 1)" \
                                || { no "packets verdict was '$(verdict packets)', expected OK"; dump; }
[ "$(verdict commits)" = "OK" ] && ok "commits: OK (1 commit against the declared base)" \
                                || { no "commits verdict was '$(verdict commits)', expected OK"; dump; }

echo "== 4. RED — a second packet in flight is REFUSED, and the refusal NAMES the dimension =="
# The whole argument for separate ceilings: the operator is told which capacity
# is saturated, not handed a number that has gone up.
TWO="$WORK/two"; BASE2="$(mkrepo "$TWO" 1)"
mkpacket "$TWO/packet.md" 2 "- \`main\` at \`$BASE2\`; verified before building."
RC="$(run check --repo "$TWO" --packet "$TWO/packet.md")"
[ "$RC" = "2" ] && ok "RED: two packets in flight is REFUSED (exit 2)" \
                || { no "RED FAILED: two packets in flight exited $RC"; dump; }
[ "$(verdict packets)" = "EXCEEDED" ] \
  && ok "RED: the exceeded dimension is reported as EXCEEDED, by name" \
  || { no "RED FAILED: packets verdict was '$(verdict packets)'"; dump; }
out | grep -qE 'REFUSED.*packets' \
  && ok "RED: the refusal line names 'packets' — the saturated dimension, not a score" \
  || { no "RED FAILED: the refusal does not name the dimension that caused it"; dump; }
[ "$(verdict commits)" = "OK" ] \
  && ok "RED: the unsaturated dimension still reports its own verdict (dimensions do not collapse)" \
  || { no "RED FAILED: commits reported '$(verdict commits)' when only packets was over"; dump; }

echo "== 5. RED — the commit ceiling is EXCEEDED and it ADVISES; it does not gate =="
# The most contestable claim in the census entry, executed rather than asserted:
# 2 commits per packet is a constant chosen by the working contract, a class-C
# heuristic, and a heuristic does not become a gate by being useful.
OVER="$WORK/over"; BASE3="$(mkrepo "$OVER" 3)"
mkpacket "$OVER/packet.md" 1 "- \`main\` at \`$BASE3\`; verified before building."
RC="$(run check --repo "$OVER" --packet "$OVER/packet.md")"
[ "$(verdict commits)" = "EXCEEDED" ] \
  && ok "RED: 3 commits against a ceiling of 2 is reported EXCEEDED, by name" \
  || { no "RED FAILED: commits verdict was '$(verdict commits)' at 3 commits"; dump; }
[ "$RC" = "0" ] \
  && ok "the commit ceiling ADVISES: it reports the breach and exits 0, as its class-C licence allows" \
  || { no "the commit ceiling exited $RC — it is gating on a heuristic constant without declaring it"; dump; }
out | grep -qiE 'advis' \
  && ok "the commit dimension states its authority (advisory) where the operator reads it" \
  || { no "the commit dimension does not state that it only advises"; dump; }

echo "== 6. UNOBSERVABLE is reported, never faked =="
# Three ways the commit count cannot be established. Each must yield
# UNOBSERVABLE with its reason, and none may invent a number.
NOBB="$WORK/nobb"; mkrepo "$NOBB" 1 >/dev/null
mkpacket "$NOBB/packet.md" 1 NONE
RC="$(run check --repo "$NOBB" --packet "$NOBB/packet.md")"
{ [ "$(verdict commits)" = "UNOBSERVABLE" ] && [ "$RC" = "0" ]; } \
  && ok "a packet declaring no branch base yields commits UNOBSERVABLE (exit 0), not a fabricated count" \
  || { no "a packet with no branch base gave '$(verdict commits)' at exit $RC"; dump; }
out | grep -qi 'branch base' \
  && ok "the UNOBSERVABLE verdict states WHY it could not be measured" \
  || { no "UNOBSERVABLE is reported with no reason"; dump; }
GHOSTB="$WORK/ghostb"; mkrepo "$GHOSTB" 1 >/dev/null
mkpacket "$GHOSTB/packet.md" 1 "- \`main\` at \`deadbee\`; verified before building."
run check --repo "$GHOSTB" --packet "$GHOSTB/packet.md" >/dev/null
[ "$(verdict commits)" = "UNOBSERVABLE" ] \
  && ok "a declared base that is not a commit in this repository yields UNOBSERVABLE" \
  || { no "a nonexistent base gave '$(verdict commits)'"; dump; }
FORK="$WORK/fork"; mkrepo "$FORK" 1 >/dev/null
FOREIGN="$WORK/foreign"; FSHA="$(mkrepo "$FOREIGN" 2)"
FTIP="$(G -C "$FOREIGN" rev-parse HEAD)"
G -C "$FORK" fetch -q "$FOREIGN" HEAD >/dev/null 2>&1
mkpacket "$FORK/packet.md" 1 "- \`main\` at \`$FTIP\`; verified before building."
run check --repo "$FORK" --packet "$FORK/packet.md" >/dev/null
[ "$(verdict commits)" = "UNOBSERVABLE" ] \
  && ok "a declared base that is not an ancestor of HEAD yields UNOBSERVABLE, not a negative or absolute count" \
  || { no "a non-ancestor base gave '$(verdict commits)'"; dump; }
MISSING="$WORK/missing"; mkrepo "$MISSING" 1 >/dev/null
run check --repo "$MISSING" --packet "$MISSING/nosuchfile.md" >/dev/null
[ "$(verdict packets)" = "UNOBSERVABLE" ] \
  && ok "an absent packet file yields packets UNOBSERVABLE — the gate does not fire on evidence it does not have" \
  || { no "an absent packet file gave packets '$(verdict packets)'"; dump; }

echo "== 7. The DECLINED dimensions are declined WITH REASONS, and no ceiling is invented =="
run check --repo "$OK1" --packet "$OK1/packet.md" >/dev/null
for d in $DECLINED; do
  [ "$(verdict "$d")" = "DECLINED" ] \
    && ok "$d is reported DECLINED, not silently omitted and not silently passed" \
    || { no "$d reported '$(verdict "$d")' instead of DECLINED"; dump; }
done
awk '$1=="bandwidth:" && $2=="depth"' "$WORK/out.txt" | grep -qi 'transcript' \
  && ok "depth is declined for the stated reason: rounds are transcript-only, nothing in git attests to a serial stage" \
  || { no "depth is declined without naming the transcript-only reason"; dump; }
awk '$1=="bandwidth:" && $2=="write_sets"' "$WORK/out.txt" | grep -qiE 'no ceiling|ceiling is declared' \
  && ok "write_sets is declined because NO ceiling on concurrent write sets is declared — inventing one is the anti-pattern" \
  || { no "write_sets is declined without naming the missing-ceiling reason"; dump; }
DECBAD=0
for d in $DECLINED; do
  awk -v d="$d" '$1=="bandwidth:" && $2==d' "$WORK/out.txt" | grep -qE 'ceiling [0-9]' \
    && { DECBAD=$((DECBAD+1)); echo "      | $d prints a numeric ceiling it declined to enforce"; }
done
[ "$DECBAD" -eq 0 ] \
  && ok "no declined dimension prints a numeric ceiling — a limit it cannot enforce is not asserted" \
  || no "$DECBAD declined dimension(s) print a ceiling anyway"

echo "== 8. The declined dimensions own NO registry entry =="
# A control that claims a limit it cannot observe is worse than an absent
# control, so the census must not contain one.
grep -oE '^control: bandwidth\.[a-z_]+' "$REG" | sed 's/^control: //' | sort > "$WORK/bwids.txt"
NBW="$(grep -c . "$WORK/bwids.txt" || true)"; NBW="${NBW:-0}"
[ "$NBW" = "2" ] \
  && ok "the census registers exactly 2 bandwidth controls — one per ENFORCED dimension" \
  || { no "the census registers $NBW bandwidth control(s), expected 2"; sed 's/^/      | /' "$WORK/bwids.txt"; }
grep -qE 'depth|write_set' "$WORK/bwids.txt" \
  && no "a declined dimension owns a registry entry — the census claims a limit nothing observes" \
  || ok "no declined dimension owns a registry entry (nothing named depth or write_set)"
grep -qF "owning_module: build-os/tools/bandwidth-check.sh" "$REG" \
  && ok "the tool owns at least one registry entry (it can exit non-zero, so it is a control surface)" \
  || no "the bandwidth tool exits non-zero and owns no registry entry"
# Both fields are collected and the record is judged AT ITS END. `runtime_authority`
# precedes `owning_module` inside a record, so a one-pass scan that decides when it
# sees the authority is reading the PREVIOUS record's module — the off-by-one the
# registry suite's section 8 header warns about, reproduced here once already.
awk '/^control: /{c=$2; m=0; g=0}
     /^owning_module: build-os\/tools\/bandwidth-check\.sh$/{m=1}
     /^runtime_authority: gate$/{g=1}
     /^$/{if(m&&g)print c; c=""; m=0; g=0}
     END{if(m&&g)print c}' "$REG" | grep -q . \
  && ok "the surface owns a \`gate\` entry, as the anti-shelfware scan requires of anything that can stop a run" \
  || no "the tool can exit 2 but no entry records it at authority gate"

echo "== 9. THE CEILING IN THE CENSUS IS THE CEILING IN THE TOOL =="
# The lanedecl.threshold_pinning device: the registry cites the line that
# DEFINES the constant, that line is read back, and the two must agree. A
# constant stated in two places cannot drift silently; one stated in one place
# and described in another can.
CREF="$(awk '/^control: /{c=$2} c=="bandwidth.packet_commit_ceiling" && /^evidence_refs: /{sub(/^evidence_refs: /,""); print; exit}' "$REG" \
        | tr ';' '\n' | grep -F 'bandwidth-check.sh' | head -1 | tr -d ' ')"
[ -n "$CREF" ] \
  && ok "the commit-ceiling entry cites a line of the tool as its evidence" \
  || no "the commit-ceiling entry cites no line of build-os/tools/bandwidth-check.sh"
CLINE="$(sed -n "${CREF##*:}p" "$SRC/${CREF%:*}" 2>/dev/null)"
CITED="$(printf '%s' "$CLINE" | grep -oE '[0-9]+' | head -1)"
run dimensions >/dev/null
REPORTED="$(awk '$1=="dimension:" && $2=="commits"{for(i=1;i<=NF;i++) if($i ~ /^ceiling=/){sub(/^ceiling=/,"",$i); print $i; exit}}' "$WORK/out.txt")"
{ [ -n "$CITED" ] && [ "$CITED" = "$REPORTED" ]; } \
  && ok "the cited constant ($CITED) equals the ceiling the tool reports ($REPORTED) — census and tool cannot drift" \
  || no "the cited constant '$CITED' and the reported ceiling '$REPORTED' disagree"

echo "== 10. Usage errors refuse rather than guessing =="
RC="$(run)"
[ "$RC" = "2" ] && ok "no command is REFUSED (exit 2), not treated as a silent check" \
                || { no "no command exited $RC"; dump; }
RC="$(run wibble)"
[ "$RC" = "2" ] && ok "an unknown command is REFUSED (exit 2)" || { no "an unknown command exited $RC"; dump; }
RC="$(run check --repo "$WORK/nope")"
[ "$RC" = "2" ] && ok "a --repo that is not a directory is REFUSED" || { no "a bad --repo exited $RC"; dump; }

echo "== 11. This suite is chained, and is not vacuous about itself =="
grep -qF 'chain_suite "tests/bandwidth_tests.sh"' "$SRC/tests/build_os_tests.sh" \
  && ok "this suite is chained from tests/build_os_tests.sh (not discoverable-only)" \
  || no "this suite is present but never chained from tests/build_os_tests.sh"
# A DERIVED floor: more assertions than the model has dimensions. It states no
# numeric literal, so it does not join the tests.nonvacuity_minimums family that
# tests/control_registry_tests.sh §21 polices.
[ "$PASS" -gt "$NDIM" ] \
  && ok "this suite ran $PASS assertions, more than the $NDIM dimensions it pins" \
  || no "this suite ran only $PASS assertions against $NDIM dimensions"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
