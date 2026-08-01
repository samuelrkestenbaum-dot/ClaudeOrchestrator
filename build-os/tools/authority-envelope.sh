#!/usr/bin/env bash
# Build OS — the authority envelope validator: who granted what, to whom, on
# what basis, in what deployment mode, and until when.
#
# THE GAP THIS CLOSES. `MISMATCHES.md` states — fourteen times — that
# re-authorising a control is a governance action belonging to the operator.
# THE OPERATOR HAD NO MECHANISM TO PERFORM ONE. No artefact in this repository
# let a human write "this control may exercise this authority, on this basis,
# until this date, and here is where it lands when the lease ends". The rule
# existed and the act it named did not. `build-os/registry/authority_envelopes.txt`
# is the artefact; this file validates it, composes it against the licence
# table, and reports. IT GRANTS NOTHING.
#
# THE THIRD AXIS, AND WHY IT IS THE WHOLE REASON THIS EXISTS. `class` asks what
# KIND of thing is being checked. `empirical_status` asks whether the check
# WORKS. Neither asks the question an operator must actually answer before
# switching something on: WHAT HAPPENS TO THE OUTPUT? A control whose ranking
# nothing consumes and a control whose ranking silently reorders the work queue
# are indistinguishable on both existing axes, and they are not the same risk.
# `deployment_mode` is what separates PERMISSION TO RANK from PERMISSION TO
# CHOOSE from PERMISSION TO ACT:
#
#   shadow              -> observe   its output MAY be watched, and it causes NO
#                                    OPERATIONAL CONSEQUENCE. The rung is defined
#                                    by CONSEQUENCE, not by consumption. This row
#                                    used to be written as a non-consumption
#                                    clause, which — with `none` written the same
#                                    way — is precisely what made the evidence
#                                    axis's `refuted` cap unreachable for every
#                                    wired-in control.
#   human_confirmed     -> advise    a person sits between signal and
#                                    consequence. `advise` and not `rank` by the
#                                    ladder's OWN definition of `rank` — the
#                                    rung that orders work or selects between
#                                    options WITH NO HUMAN IN THE LOOP. A mode
#                                    whose entire content is "a human confirms"
#                                    cannot license the rung that means "no
#                                    human confirms".
#   bounded_autonomous  -> rank      acts without a person, inside declared
#                                    bounds. It may order and select; it may not
#                                    `gate`, because `gate` is the UNBOUNDED stop
#                                    and "bounded" is the refusal of exactly that.
#   autonomous          -> execute   no additional cap. It caps at the TOP rung
#                                    because this row's justification has only
#                                    ever been its POSITION — "no additional cap"
#                                    — and never the token it happened to name.
#                                    When `execute` was added above `gate`,
#                                    holding this row at `gate` would have turned
#                                    a documented NON-cap into a real cap on the
#                                    whole pre-existing census. It grants nobody
#                                    `execute`: the composition is a MINIMUM and
#                                    no class licenses that rung.
#
# COMPOSITION GAINS A THIRD MIN TERM:
#
#   L_effective = MIN(L_class, L_evidence, L_deployment)
#
# Three independent NECESSARY conditions, so a minimum and not an average:
# being the right kind of thing does not make a broken check work, a working
# check does not make a chosen threshold an invariant, and neither of them makes
# it safe for the output to act without a person. There is NO composite score —
# the weights would be underivable and one number hides which term is saturated
# — so all three terms are printed separately on every finding and every finding
# names the term that binds it.
#
# THE DEFAULT IS `autonomous`, AND THE DEFENCE MATTERS MORE THAN THE VALUE.
# Every control registered before this axis existed carries no deployment mode.
# `autonomous` — no additional cap — is the ONLY default that leaves the existing
# finding set exactly where the operator put it. Any other default silently
# demotes the entire census in one commit, which is precisely the
# self-re-authorisation this machinery exists to prevent. A permissive default is
# normally the wrong instinct; here the conservative direction is "change
# nothing", not "cap everything". THE COST, stated rather than implied away: the
# axis is OPT-IN and is inert until an operator writes a record. Nothing here can
# discover a deployment mode; it can only record that a human declared one.
#
# ---------------------------------------------------------------------------
# THE OPEN QUESTION THIS TOOL RECORDS AND DOES NOT ANSWER.
#
# The sanctioned S1 launch declaration is `controlClass: heuristic_policy` /
# `empiricalStatus: untested` / `runtimeAuthority: rank` / `deploymentMode:
# shadow`. AS LITERALLY SPECIFIED, MIN() CANNOT PRODUCE `rank` FOR IT.
# `heuristic_policy` is Class C; `README.md` §3 licenses Class C at `advise`;
# the ladder is none < observe < advise < rank < gate < execute, so `rank` is strictly
# above L_class and the minimum can never exceed `advise` whatever the other two
# terms say. Two readings, and they claim different things:
#
#   READING 1 — S1 ships with `authority_mismatch: declared`, the fifteenth.
#   Honest, mechanical, and exactly consistent with the fourteen already in
#   MISMATCHES.md. Nothing new is required of the ladder.
#
#   READING 2 — `shadow` means the ranking HAS NO CONSEQUENCE, so
#   `runtime_authority` is measuring the wrong property for a shadow-mode
#   control: the ladder conflates SIGNAL STRENGTH with WHETHER ANYTHING CONSUMES
#   THE SIGNAL, and a control that ranks into a void is not exercising `rank` in
#   the sense the ladder means.
#
# BOTH ARE RECORDED. NEITHER IS ADOPTED. Reading 2 is architecturally
# interesting and may well be right, but choosing it here would REDEFINE THE
# LADDER — a governance change, not a build decision — so `shadow` still caps at
# `observe` in the axis below and S1 as declared would still be out of licence.
# This is the same treatment the evidence-matrix packet gave the S1 collision it
# found: record it, do not quietly fix it. THE OPERATOR DECIDES.
#
# THE OPERATOR SINCE DECIDED SOMETHING ADJACENT, AND IT IS NOT READING 2. The
# ladder now measures CONSEQUENCE rather than CONSUMPTION at its bottom rung:
# `observe` means the output MAY be recorded and consumed FOR VISIBILITY and
# causes NO OPERATIONAL CONSEQUENCE. It was formerly defined by NON-CONSUMPTION
# — as measuring and recording with nothing reading the result — which, with
# `none` ALSO defined by non-consumption, left the ladder no rung meaning "it is
# read, but it may cause nothing", so
# the evidence axis's `refuted -> observe` cap was foreclosed for 67 of 81
# controls and 0 sat there. A sixth rung `execute` (the output may DIRECTLY
# CAUSE MUTATION) now sits above `gate`, so "may prohibit" and "may change the
# world" are no longer the same claim.
#
# THAT IS STILL NOT READING 2. `shadow` continues to cap at `observe`; what
# changed is what `observe` MEANS, not where any mode caps. No class licenses
# `execute` and no control was moved onto it. Whether Class A should license
# `execute`, and which currently-`gate` controls actually perform writes, are
# recorded for the operator and NOT answered here.
#
# THE ONE PENDING EXTENSION, NOW RESOLVED. The operator ruled that `untested`
# (has not yet produced live outputs against real tasks) and `unvalidated` (has
# operated, but lacks sufficient outcome evidence) are meaningfully different.
# `gravito_p2_claim_scoped_evidence_a` IMPLEMENTED IT: the evidence axis carries
# six tokens and `untested` caps at `observe`, the lowest rung that is still a
# legal destination. The refusal it used to trigger is UNCHANGED — any token
# this matrix has no cap for still takes `evidence.derivation_nonvacuity` to
# exit 2 — so recognising one token did not open a fall-through. And the cap was
# chosen in the direction that costs: it makes the S1 declaration below MORE out
# of licence, not less, which is the test of whether a token was added to the
# ontology or fitted to a case.
#
# ---------------------------------------------------------------------------
# WHY THIS IS A NEW FILE AND NOT AN EXTENSION OF evidence-policy.sh. Judged, not
# assumed, and the argument cuts both ways so both halves are stated.
#
# AGAINST a new file: the composition rule now lives in two places, and two
# implementations of one minimum can drift.
#
# FOR a new file, and decisive: `evidence-policy.sh` derives EVERYTHING from the
# census and stores nothing — its suite checks, as a property, that NO CONTROL ID
# APPEARS IN ITS SOURCE, because a hand-maintained list decays the way
# `PACKET_FILES` and MISMATCHES.md §10's file/lines table both did. An envelope
# store is the OPPOSITE OBJECT: a hand-written record that names control ids on
# purpose, because a grant is a human decision about a specific control and
# cannot be derived from anything. Putting a hand-written grant store inside the
# file whose whole claim is "nothing here is hand-maintained" would make that
# claim false in the same commit that states it. The two also carry different
# lifetimes: the matrix is recomputed every run and the store is edited by a
# person and then left alone.
#
# THE DRIFT IS HANDLED BY RECONCILIATION RATHER THAN BY SHARED CODE, which is
# the house pattern: `evidence-policy.sh` sources its third axis from THIS TOOL
# (`authority-envelope.sh modes`) rather than growing a second parser for this
# schema, and the ladder both print is reconciled by the suites — the same device
# `tests/evidence_policy_tests.sh` §4 uses to stop the class axis drifting from
# README §3.
#
# IT ADVISES. `check` EXITS 0 WHATEVER IT FINDS. Three reasons, all of which
# belong in the registry entry as well:
#   1. It is CHOSEN POLICY, not a definition. Where `shadow` caps is a
#      judgement, defensible and still a judgement.
#   2. A VALIDATOR THAT GATED WOULD BE ENFORCING A GOVERNANCE SCHEME OVER AN
#      EMPTY SET. There are zero live grants. Gating on a scheme nothing uses is
#      vacuous authority — it could only ever fire on the operator's own first
#      attempt to use the mechanism, which is the worst possible moment to
#      refuse.
#   3. Precedent, endorsed on review: new Class-C controls ship at `advise`;
#      promotion is a separate governance action — which is what this whole
#      packet is about.
#
# THE ONE THING IT DOES REFUSE, mirroring `evidence.derivation_nonvacuity`: a
# derivation it cannot trust. An absent store, an unparseable store, a record
# missing a required field, a duplicate envelope id, a `granted_authority` off
# the ladder, a malformed or backwards date, a field the schema has no slot for,
# or AN UNKNOWN `deployment_mode`. The last is the sharpest: an unrecognised
# deployment mode must NEVER fall through to permissive, because that is exactly
# how a matrix stops discriminating while still printing green.
#
# ZERO GRANTS IS THE CORRECT STATE, NOT THE SHELFWARE STATE, and this is the one
# place the census's vacuity rule is deliberately NOT copied. `scan-controls.sh`
# refuses a registry declaring zero controls because an empty census is an
# unclassified system wearing a registry. An empty ENVELOPE store means the
# opposite and better thing: nothing has been re-authorised. So zero records is
# reported and exits 0. An ABSENT store still refuses — absent is not empty.
#
# ---------------------------------------------------------------------------
# THE LEASE TERM IS ENFORCED. IT USED NOT TO BE, AND THAT WAS NOT A SMALL GAP.
# ---------------------------------------------------------------------------
# This file format-checked `starts` and `expires` as YYYY-MM-DD and ordered them,
# and then NEVER CONSULTED THE CLOCK. `date` appeared in no tool in this
# repository. An envelope SEVEN MONTHS DEAD reported:
#
#   authority-envelope: 1 live grant(s) …
#   envelope: WITHIN-LICENCE … l-deployment=execute l-effective=gate binding-axis=none
#
# The word "live" printed about a dead grant, and `l-deployment=execute` — the
# strongest deployment cap in the system — computed from a lease that had ended.
# THE SYMMETRIC CASE WAS CONFIRMED BY EXECUTION, NOT INFERRED: the same record
# moved to a window five months in the FUTURE produced BYTE-IDENTICAL output. The
# window was decorative at BOTH ends. Time was missing from the minimum in
# precisely the way `untested` was missing from `EVIDENCE_AXIS` one packet ago —
# the same defect class, one axis over.
#
# THE DEFECT IS NOT "EXPIRED GRANTS OVER-PERMIT", and framing it that way builds
# the wrong test. It is: AN EXPIRED GRANT KEEPS APPLYING, IN WHICHEVER DIRECTION
# IT POINTED. Both directions are wrong and only one is visible:
#
#   RESTRICTIVE stale mode — VISIBLE. A dead `shadow` lease dragged a control
#     licensed `gate` on both live axes down to `observe`, and
#     `evidence-policy.sh check` named `axis=deployment`: the binding term was a
#     lease that ended seven months earlier.
#   PERMISSIVE stale mode — INVISIBLE. An ungranted control already defaults to
#     `autonomous`/`execute`, so a permissive expired grant is byte-identical in
#     the matrix's output to no grant at all. A test written only against this
#     direction passes vacuously against a fixed tool AND an unfixed one.
#
# THE RULE. An envelope is LIVE when `starts <= now < expires`, and contributes
# NO GRANT otherwise. THE INTERVAL IS HALF-OPEN, and that is a choice with a
# reason: `expires` is the moment the lease ENDS rather than the last day it
# covers, so `[starts, expires)` has positive length exactly when `expires >
# starts` — the ordering rule the schema already enforces — and no lease is
# accidentally extended by a day at its most sensitive boundary. Out-of-window
# records are reported in TWO states, because they are two different facts about
# a grant and a reader must not have to guess which:
#
#   LAPSED         `expires` has passed. The lease ended. It is over.
#   NOT-YET-LIVE   `starts` has not arrived. The lease exists and has not opened.
#
# Neither is `WITHIN-LICENCE`, neither is counted in the live total, and neither
# reaches `mode_projection()` — which is the site that matters, because
# `evidence-policy.sh` consumes that projection as a MIN term and a stale mode
# leaving through it reaches the matrix whatever this file's report says.
#
# THE CLOCK IS OWNED HERE, EXACTLY ONCE, AND IS OVERRIDABLE. `authority-envelope.sh
# now` is the one place in this repository that asks what day it is; every other
# tool that needs a date SOURCES it from here, the same way `claim-evidence.sh`
# sources its caps from `evidence-policy.sh matrix`. A second private `date` call
# is how one tool honours an override and another quietly does not. `BUILD_OS_NOW`
# overrides it so fixtures can pin a date and the suites do not rot in 2027, and
# A MALFORMED OVERRIDE REFUSES rather than falling back to today — an unreadable
# clock must never default to the permissive answer. WHEN THE OVERRIDE IS IN
# FORCE THE OUTPUT SAYS SO, on every command that reasons from a date: an
# override that could silently un-expire a grant would be worse than no override
# at all.
#
# WHAT IT DOES NOT DO. It grants nothing, it writes nothing anywhere, and it
# takes every field AT THE ISSUER'S WORD. It observes DECLARED deployment, not
# deployment: a record saying `shadow` is believed. Nothing here inspects a
# running system, verifies that a consumer exists, checks that a human really
# confirms, or notices a lease whose stated rollback was never implemented. What
# it now DOES do is refuse to compose a lease that is not in force; what it still
# cannot do is tell whether the lease was ever honoured while it was.
#
# THE DIRECTION OF THE INSTRUMENT: AN ENVELOPE CAN ONLY LOWER `L_effective`.
# Stated here because it is the single easiest thing to assume backwards. The
# composition is a MINIMUM, so the deployment term can only pull the result DOWN.
# AN ENVELOPE CAN NEVER RAISE A CONTROL ABOVE `L_class` OR `L_evidence`. The
# default `autonomous` caps at `execute`, the top of the ladder and therefore no
# cap at all, and every other mode is strictly below it — so the only effect an
# operator can have on `L_effective` by writing a record is to REDUCE it.
#
# That is deliberate, and it is the property most worth keeping: this validator
# refuses to launder a Class-C control into a `gate` even when the operator signs
# the grant. Granting `gate` to `adoption.lane_size_check` (Class C,
# `calibrated,red_driven`, exercising `gate`) reports
#   OVER-GRANTED … granted=gate l-class=advise l-evidence=gate
#                  l-deployment=gate l-effective=advise binding-axis=class
# and evidence-policy.sh still reports that control OUT-OF-LICENCE, its finding
# byte-identical to the run with no store at all.
#
# THE CONSEQUENCE FOR THE NEXT STEP, so nobody plans around a mechanism that does
# not do this. "The operator had no mechanism to re-authorise a control, and this
# is it" invites the reading that the fourteen `authority_mismatch: declared`
# controls can be cleared by writing fourteen envelopes. THEY CANNOT. This tool
# RECORDS a grant and COMPOSES it; it does not LEGITIMISE one. Applying the
# registry's promotion and demotion rules to those fourteen needs a class change,
# a change in `empirical_status`, a change to the licence table itself, or an
# instrument that does not exist yet — a governance act on the FIRST TWO axes. An
# envelope is where such an act is recorded and bounded, not the authority that
# performs it.
#
# Local only. Reads files and prints. Writes nothing, anywhere.
#
# Usage:
#   authority-envelope.sh schema
#   authority-envelope.sh now
#   authority-envelope.sh check [--repo DIR] [--store FILE] [--registry FILE]
#   authority-envelope.sh modes [--repo DIR] [--store FILE]
# Env:
#   BUILD_OS_NOW=YYYY-MM-DD  pin the clock. Announced in the output whenever it
#                            is set; refused, never ignored, when malformed.
# Exit: 0 the derivation ran (WHATEVER it found — this advises);
#       2 the invocation is malformed, or the store could not be trusted.
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SELF_DIR/../.." && pwd)"
STORE=""
REGISTRY=""

refuse(){ printf 'authority-envelope: REFUSED — %s\n' "$*" >&2; exit 2; }

# --- the third axis, defined exactly once ------------------------------------
# The ladder is the registry's own and is printed rather than assumed, so a
# reader never has to trust that this file and README §3 agree about the order.
LADDER="none observe advise rank gate execute"
DEPLOYMENT_AXIS="shadow:observe human_confirmed:advise bounded_autonomous:rank autonomous:execute"
# THE DEFAULT. `autonomous`, i.e. no additional cap. Defended at length in the
# header: it is the only value that leaves 78 pre-existing controls where the
# operator put them.
DEPLOYMENT_DEFAULT="autonomous"
# THE SCHEMA — fourteen required fields, in record order. `envelope` is the id
# line and opens a record.
SCHEMA_FIELDS="envelope issuer actor control scope granted_authority evidence_basis deployment_mode starts expires revocation reason human_confirmation rollback_behavior"
# The class axis, copied from README §3 exactly as evidence-policy.sh copies it.
CLASS_AXIS="A:gate B:rank C:advise D:observe R:observe"
EVIDENCE_AXIS="untested:observe unvalidated:advise red_driven:gate field_observed:gate calibrated:gate refuted:observe"

rank_of(){ case "$1" in none) echo 0 ;; observe) echo 1 ;; advise) echo 2 ;; rank) echo 3 ;; gate) echo 4 ;; execute) echo 5 ;; *) echo -1 ;; esac; }
name_of(){ case "$1" in 0) echo none ;; 1) echo observe ;; 2) echo advise ;; 3) echo rank ;; 4) echo gate ;; 5) echo execute ;; *) echo '?' ;; esac; }
axis_cap(){ # <axis-string> <key> -> licensed authority, or the empty string
  local a
  for a in $1; do case "$a" in "$2":*) printf '%s' "${a#*:}"; return 0 ;; esac; done
  return 1
}
in_list(){ local v="$1" l; for l in $2; do [ "$v" = "$l" ] && return 0; done; return 1; }

# --- THE CLOCK, owned here and sourced by everything else ---------------------
# The one place in this repository that asks what day it is. Every other tool
# that needs a date runs `authority-envelope.sh now` rather than calling `date`,
# for the same reason `claim-evidence.sh` sources its caps from
# `evidence-policy.sh matrix`: a second private clock is how an override is
# honoured in one place and silently ignored in another.
CLOCK_VAR="BUILD_OS_NOW"
DATE_RE='^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$'
# SHAPE IS NOT VALIDITY, and this file learned that the expensive way. `DATE_RE`
# and the `case` in `clock()` matched four-two-two and nothing else, so
# `2026-13-45` was a date as far as every check here was concerned. Two things
# followed, and the quiet one is the reason this exists:
#
#   LOUD   `BUILD_OS_NOW=2025-13-01` was accepted as a clock. Dates here are
#          compared as STRINGS, and "2025-13-01" sorts after every real 2025
#          date, so a lapsed lease read live again. That case announces itself:
#          the override is printed with its provenance on every run.
#   QUIET  a store record carrying `expires: 2026-13-45` passed the schema and
#          was counted a LIVE grant under the plain system clock. Nothing is
#          overridden and nothing is announced. AN INVALID LEASE READ CLEAN,
#          which is the exact failure the window enforcement was added to end.
#
# `date -d` is not used: it is a GNU extension and every other derivation in this
# file is POSIX shell. The calendar is arithmetic, so it is done as arithmetic —
# including the Gregorian leap rule, because February is where an off-by-one in a
# lease term hides.
valid_date(){ # <YYYY-MM-DD> -> 0 if it is a real calendar date
  case "$1" in [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;; *) return 1 ;; esac
  local y="${1%%-*}" rest="${1#*-}" m d dim
  m="${rest%%-*}"; d="${rest##*-}"
  y=$((10#$y)); m=$((10#$m)); d=$((10#$d))
  [ "$m" -ge 1 ] && [ "$m" -le 12 ] || return 1
  [ "$d" -ge 1 ] || return 1
  case "$m" in
    1|3|5|7|8|10|12) dim=31 ;;
    4|6|9|11)        dim=30 ;;
    2) if { [ $((y % 4)) -eq 0 ] && [ $((y % 100)) -ne 0 ]; } || [ $((y % 400)) -eq 0 ]
       then dim=29; else dim=28; fi ;;
    *) return 1 ;;
  esac
  [ "$d" -le "$dim" ]
}
NOW=""; NOW_SOURCE=""
clock(){
  [ -n "$NOW" ] && return 0
  if [ -n "${BUILD_OS_NOW:-}" ]; then
    NOW="$BUILD_OS_NOW"
    NOW_SOURCE="$CLOCK_VAR — OVERRIDDEN, not this machine's clock"
    # A MALFORMED OVERRIDE REFUSES. Falling back to today would make an
    # unreadable clock resolve to the permissive answer, which is the one thing
    # every derivation in this file is written against.
    valid_date "$NOW" \
      || refuse "$CLOCK_VAR is \"$NOW\", which is not a real YYYY-MM-DD calendar date. An unreadable clock must never fall back to today: every lease term in the store would then be judged against a date nobody chose. A date that is merely SHAPED right is worse than a malformed one — dates here are compared as strings, so a month 13 sorts after every real date in its year and silently un-expires every lease that ended in it."
  else
    NOW="$(date +%Y-%m-%d 2>/dev/null)"
    NOW_SOURCE="system clock"
    valid_date "$NOW" \
      || refuse "the system clock produced \"$NOW\", which is not a real YYYY-MM-DD calendar date. Without a date no lease term can be evaluated, and evaluating none would mean composing every expired grant as if it were live."
  fi
}
# THE WINDOW STATES. Three, and the two out-of-window ones are DISTINCT: a lease
# that has ended and a lease that has not opened are different facts about a
# grant, and collapsing them makes a reader guess which. The interval is
# HALF-OPEN — live iff `starts <= now < expires` — so `expires` is the moment the
# lease ends rather than the last day it covers.
WINDOW_STATES="live lapsed not_yet_live"
window_state(){ # <starts> <expires> -> live | lapsed | not_yet_live
  clock
  if [ "$NOW" \< "$1" ]; then printf 'not_yet_live'
  elif [ "$2" \< "$NOW" ] || [ "$2" = "$NOW" ]; then printf 'lapsed'
  else printf 'live'
  fi
}
window_verdict(){ # <window-state> -> the word printed on a report line
  case "$1" in lapsed) printf 'LAPSED' ;; not_yet_live) printf 'NOT-YET-LIVE' ;; *) printf 'LIVE' ;; esac
}
# Printed by every command that reasons from a date. An override that could
# silently un-expire a grant would be worse than having no override at all.
clock_line(){ clock; printf 'clock: now=%s source=%s\n' "$NOW" "$NOW_SOURCE"; }

CMD="${1:-}"
[ $# -gt 0 ] && shift
case "$CMD" in
  schema|check|modes|now) ;;
  -h|--help|help) sed -n '2,296p' "${BASH_SOURCE[0]}"; exit 0 ;;
  "") refuse "no command — expected one of: schema, now, check, modes" ;;
  *)  refuse "unknown command \"$CMD\" — expected one of: schema, now, check, modes" ;;
esac

while [ $# -gt 0 ]; do
  case "$1" in
    --repo)     [ $# -ge 2 ] || refuse "--repo needs a value";     REPO="$2"; shift 2 ;;
    --store)    [ $# -ge 2 ] || refuse "--store needs a value";    STORE="$2"; shift 2 ;;
    --registry) [ $# -ge 2 ] || refuse "--registry needs a value"; REGISTRY="$2"; shift 2 ;;
    -h|--help)  sed -n '2,296p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) refuse "unknown option \"$1\"" ;;
  esac
done

# ------------------------------------------------------------------ now ------
# The clock as a first-class command, so that every other tool can source a date
# instead of computing one. It prints the date AND its provenance, because a date
# with no provenance is a date a reader cannot audit.
if [ "$CMD" = "now" ]; then
  clock
  printf 'now: %s\n' "$NOW"
  printf 'source: %s\n' "$NOW_SOURCE"
  printf 'override: set %s=YYYY-MM-DD to pin the clock. It is ANNOUNCED wherever it is used and REFUSED when malformed — an override that could silently un-expire a grant would be worse than no override at all.\n' "$CLOCK_VAR"
  printf 'owner: this is the ONLY clock in the repository. Every other tool that needs a date runs this command rather than calling `date`, because a second private clock is how an override is honoured in one place and ignored in another.\n'
  exit 0
fi

# --------------------------------------------------------------- schema ------
if [ "$CMD" = "schema" ]; then
  printf 'ladder: %s\n' "$LADDER"
  printf 'axis: deployment %s\n' "$DEPLOYMENT_AXIS"
  printf 'default: deployment_mode %s — a control with no envelope declares no deployment mode, so it takes NO ADDITIONAL CAP. Any other default would silently demote every control registered before this axis existed, which is the self-re-authorisation the envelope exists to prevent; here "changes nothing" is the conservative direction, not "cap everything".\n' "$DEPLOYMENT_DEFAULT"
  printf 'composition: L_effective = MIN(L_class, L_evidence, L_deployment) over the ladder above — a grant may reach what ALL THREE terms allow, and no further\n'
  printf 'no-composite: the three terms are reported separately on every finding and are never blended into one number; every finding names the term that binds it\n'
  printf 'ordering: the four modes are strictly increasing — shadow < human_confirmed < bounded_autonomous < autonomous — which is what separates permission to RANK from permission to CHOOSE from permission to ACT\n'
  printf 'authority: this validator ADVISES. check exits 0 whatever it finds. It GRANTS NOTHING: writing a grant is a governance act taken by the operator in the store, never by a tool.\n'
  printf 'empty-store: ZERO live grants is the CORRECT state and exits 0 — an empty envelope store means nothing has been re-authorised. An ABSENT store REFUSES, because absent is not empty.\n'
  printf 'resolved: untested — IMPLEMENTED at `observe` by gravito_p2_claim_scoped_evidence_a. The operator ruled `untested` (has not yet produced live outputs against real tasks) and `unvalidated` (has operated, but lacks sufficient outcome evidence) meaningfully different; `untested` is now ON the evidence axis with a cap row at `observe`, the lowest rung that is still a legal destination. The refusal is UNCHANGED: any token the matrix has no cap for still exits 2, so recognising one token opened no fall-through. It caps in the direction that costs — the S1 declaration below is now MORE out of licence, not less.\n'
  printf 'open-question: the sanctioned S1 declaration (heuristic_policy / untested / rank / shadow) cannot be produced by MIN() — Class C licenses `advise` and `rank` is strictly above it. Reading 1: S1 ships with authority_mismatch: declared, the fifteenth. Reading 2: `shadow` means the ranking has no consequence, so runtime_authority measures the wrong property and the ladder conflates signal strength with whether anything consumes the signal. BOTH RECORDED, NEITHER ADOPTED — choosing would redefine the ladder, which is the operator’s decision.\n'
  printf 'field: envelope — the grant id. Unique: a lease nobody can name uniquely is a lease nobody can revoke.\n'
  printf 'field: issuer — the HUMAN who granted it. Not an agent; the point of the artefact is that a person decided.\n'
  printf 'field: actor — which agent, role or caller may exercise the grant.\n'
  printf 'field: control — the control id the grant applies to. A stable id, never a file:line.\n'
  printf 'field: scope — where the grant applies, and where it does not.\n'
  printf 'field: granted_authority — what the actor may DO: a rung on the ladder above.\n'
  printf 'field: evidence_basis — the evidence relied on, in prose. The token lives on the evidence axis; this is where a human says what they actually looked at.\n'
  printf 'field: deployment_mode — one of the four modes above. The field that makes this artefact worth having.\n'
  printf 'date-validity: every `starts`, `expires` and clock value must be a REAL CALENDAR DATE, not merely a date-shaped string. Month 01-12, day valid for that month, Gregorian leap rule applied to February. SHAPE IS NOT VALIDITY: dates here are compared as strings, so an impossible month sorts after every real date in its year — `2026-13-45` used to pass the schema and be counted a LIVE grant, which is an invalid lease reading clean.\n'
  printf 'field: starts — YYYY-MM-DD. When the lease opens. ENFORCED against the clock: before it, the record is NOT-YET-LIVE and contributes no grant.\n'
  printf 'field: expires — YYYY-MM-DD, strictly after starts. LEASES END: an authority granted with no end date is a permanent re-authorisation with a date on it. ENFORCED against the clock: on or after it, the record is LAPSED and contributes no grant.\n'
  printf 'field: revocation — how the grant is revoked before expiry, and by whom.\n'
  printf 'field: reason — why it was granted. The sentence a reviewer reads.\n'
  printf 'field: human_confirmation — the confirmation a human must give before the actor acts.\n'
  printf 'field: rollback_behavior — the DEMOTION: where the control lands when the lease ends, and what undoes anything done while it was open.\n'
  for m in shadow human_confirmed bounded_autonomous autonomous; do
    printf 'mode: %-19s caps at %-8s\n' "$m" "$(axis_cap "$DEPLOYMENT_AXIS" "$m")"
  done
  printf 'window: %s — a record is LIVE iff `starts <= now < expires`. The interval is HALF-OPEN so that `expires` is the moment the lease ENDS rather than the last day it covers, which is also what makes the schema'"'"'s `expires > starts` rule equivalent to "the window has positive length".\n' "$WINDOW_STATES"
  printf 'window-state: live         WITHIN-LICENCE or OVER-GRANTED — the lease is in force, and only these records are composed, counted or projected\n'
  printf 'window-state: lapsed       LAPSED — `expires` has passed. It CONTRIBUTES NO GRANT: it is not counted live, and `modes` does not project it.\n'
  printf 'window-state: not_yet_live NOT-YET-LIVE — `starts` has not arrived. A distinct state from LAPSED, because a lease that has not opened and a lease that ended are different facts about a grant.\n'
  printf 'window-direction: an out-of-window grant is dropped in BOTH directions, not only the permissive one. A stale RESTRICTIVE mode drags a fully licensed control down through the MIN term and is VISIBLE; a stale PERMISSIVE one is INVISIBLE, because an ungranted control already takes the default `%s`. Only the restrictive case can be told apart from no grant at all, which is why it is the fixture with discriminating power.\n' "$DEPLOYMENT_DEFAULT"
  clock_line
  exit 0
fi

# ------------------------------------------------------------- the store -----
[ -d "$REPO" ] || refuse "--repo is not a directory: $REPO"
[ -n "$STORE" ] || STORE="$REPO/build-os/registry/authority_envelopes.txt"
[ -f "$STORE" ] || refuse "no envelope store at $STORE. An ABSENT store is not an EMPTY one: reading a missing file as \"no grants\" gives the permissive answer to a question that was never asked."

# Flatten the store to id<TAB>field<TAB>value, refusing anything the schema has
# no slot for. Every refusal below is a state in which the derivation cannot be
# trusted, and a derivation that cannot be trusted must never report a licence.
FLAT="$(mktemp)"; trap 'rm -f "$FLAT"' EXIT
LN=0; CUR=""; MALFORMED=""
while IFS= read -r line || [ -n "$line" ]; do
  LN=$((LN+1))
  line="${line%$'\r'}"
  case "$line" in ''|'#'*) continue ;; esac
  case "$line" in
    "envelope: "*)
      CUR="${line#envelope: }"
      [ -n "$CUR" ] || { MALFORMED="$MALFORMED line $LN: an \"envelope:\" record with no id;"; continue; }
      printf '%s\t%s\t%s\n' "$CUR" "envelope" "$CUR" >> "$FLAT" ;;
    *": "*)
      key="${line%%: *}"; val="${line#*: }"
      if ! in_list "$key" "$SCHEMA_FIELDS"; then
        MALFORMED="$MALFORMED line $LN: field \"$key\" has no slot in the envelope schema (the schema is snake_case: \`deployment_mode\`, not \`deploymentMode\`; run \`authority-envelope.sh schema\` for the full list);"
      elif [ -z "$CUR" ]; then
        MALFORMED="$MALFORMED line $LN: field \"$key\" appears before any \"envelope:\" record;"
      else
        printf '%s\t%s\t%s\n' "$CUR" "$key" "$val" >> "$FLAT"
      fi ;;
    *)
      MALFORMED="$MALFORMED line $LN: not a \"field: value\" line and not a comment;" ;;
  esac
done < "$STORE"
[ -n "$MALFORMED" ] && refuse "$STORE is malformed. A grant store an agent cannot read line by line is not greppable, which is the whole reason for this format: ${MALFORMED%;}"

IDS="$(awk -F'\t' '$2=="envelope"{print $3}' "$FLAT")"
NENV="$(printf '%s\n' "$IDS" | grep -c . || true)"; NENV="${NENV:-0}"
DUPS="$(printf '%s\n' "$IDS" | grep -v '^$' | sort | uniq -d)"
[ -n "$DUPS" ] && refuse "duplicate envelope id(s): $(printf '%s' "$DUPS" | tr '\n' ' ')— an id names the thing a revocation revokes, so two records sharing one id is a lease nobody can end."

get(){ awk -F'\t' -v i="$1" -v f="$2" '$1==i && $2==f {print $3; exit}' "$FLAT"; }

# --- schema validation, record by record. Every failure REFUSES --------------
BAD=""
while IFS= read -r id; do
  [ -n "$id" ] || continue
  for f in $SCHEMA_FIELDS; do
    v="$(get "$id" "$f")"
    [ -n "$v" ] || BAD="$BAD $id: no \"$f\" — a partially declared grant is an undeclared one, and the fields nobody filled in are exactly the ones a grant is judged on;"
  done
  dm="$(get "$id" deployment_mode)"
  if ! axis_cap "$DEPLOYMENT_AXIS" "$dm" >/dev/null; then
    BAD="$BAD $id: deployment_mode \"$dm\" has no cap on the deployment axis. Accepted, and only these: shadow, human_confirmed, bounded_autonomous, autonomous. An unrecognised deployment mode must NEVER fall through to permissive;"
  fi
  ga="$(get "$id" granted_authority)"
  if [ "$(rank_of "$ga")" -lt 0 ]; then
    BAD="$BAD $id: granted_authority \"$ga\" is not a rung of the ladder ($LADDER);"
  fi
  st="$(get "$id" starts)"; ex="$(get "$id" expires)"
  # A REAL DATE, not merely a date-shaped string. `2026-13-45` used to pass here
  # and be counted a LIVE grant: shape was checked, the calendar never was.
  valid_date "$st" || BAD="$BAD $id: starts \"$st\" is not a real YYYY-MM-DD calendar date;"
  valid_date "$ex" || BAD="$BAD $id: expires \"$ex\" is not a real YYYY-MM-DD calendar date;"
  case "$st$ex" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
      if ! [ "$ex" \> "$st" ]; then
        BAD="$BAD $id: expires ($ex) does not follow starts ($st) — a lease that never opens is not a lease;"
      fi ;;
  esac
done < <(printf '%s\n' "$IDS")
[ -n "$BAD" ] && refuse "$STORE carries $(printf '%s' "$BAD" | tr ';' '\n' | grep -c .) malformed grant(s), named here rather than skipped:${BAD%;}"

# --- the lease term, evaluated exactly once, at the top level -----------------
# THE PARTITION EVERYTHING BELOW READS. `clock` is resolved HERE rather than
# inside the loops, because a refusal raised inside a command substitution would
# exit the subshell and leave the caller composing against a clock that failed.
# LIVE_IDS is what the report counts and what `modes` projects; the other two are
# reported and contribute nothing.
clock
LIVE_IDS=""; LAPSED_IDS=""; NOTYET_IDS=""
while IFS= read -r id; do
  [ -n "$id" ] || continue
  case "$(window_state "$(get "$id" starts)" "$(get "$id" expires)")" in
    lapsed)       LAPSED_IDS="$LAPSED_IDS$id"$'\n' ;;
    not_yet_live) NOTYET_IDS="$NOTYET_IDS$id"$'\n' ;;
    *)            LIVE_IDS="$LIVE_IDS$id"$'\n' ;;
  esac
done < <(printf '%s\n' "$IDS")
NLIVE="$(printf   '%s' "$LIVE_IDS"   | grep -c . || true)"; NLIVE="${NLIVE:-0}"
NLAPSED="$(printf '%s' "$LAPSED_IDS" | grep -c . || true)"; NLAPSED="${NLAPSED:-0}"
NNOTYET="$(printf '%s' "$NOTYET_IDS" | grep -c . || true)"; NNOTYET="${NNOTYET:-0}"

# ------------------------------------------------------------------ modes ----
# The machine projection the evidence matrix consumes, so that ONE parser owns
# this schema. Where two envelopes name one control, the MINIMUM mode governs —
# the same "weakest component wins" rule the comma-composite `empirical_status`
# already uses, and for the same reason: the conservative reading is the one an
# operator can defend.
#
# IT PROJECTS LIVE_IDS AND NOT IDS, AND THAT IS THE SITE THAT MATTERS. This
# projection is what `evidence-policy.sh` consumes as a MIN term, so an
# out-of-window mode that leaked through here would reach the licence matrix
# whatever the report above said about it — a defect with the report cleaned up
# and the composition still wrong.
mode_projection(){
  local id c m best bestr r
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    printf '%s\t%s\n' "$(get "$id" control)" "$(get "$id" deployment_mode)"
  done < <(printf '%s\n' "$LIVE_IDS") | sort -u > "$FLAT.pairs"
  cut -f1 "$FLAT.pairs" | sort -u | while IFS= read -r c; do
    [ -n "$c" ] || continue
    best=""; bestr=99
    while IFS= read -r m; do
      r="$(rank_of "$(axis_cap "$DEPLOYMENT_AXIS" "$m")")"
      if [ "$r" -lt "$bestr" ]; then bestr="$r"; best="$m"; fi
    done < <(awk -F'\t' -v k="$c" '$1==k{print $2}' "$FLAT.pairs")
    printf '%s\t%s\n' "$c" "$best"
  done
}

if [ "$CMD" = "modes" ]; then
  [ "$NLIVE" -eq 0 ] && exit 0
  mode_projection
  exit 0
fi

# ------------------------------------------------------------------ check ----
[ -n "$REGISTRY" ] || REGISTRY="$REPO/build-os/registry/control_registry.txt"
[ -f "$REGISTRY" ] || refuse "no control registry at $REGISTRY. A grant's licence is composed against the census's class and empirical_status, and an absent census is not a permissive one."

clock_line
printf 'authority-envelope: %s live grant(s) in %s\n' "$NLIVE" "$STORE"
if [ "$NLAPSED" -gt 0 ] || [ "$NNOTYET" -gt 0 ]; then
  printf 'authority-envelope: and %s record(s) OUT OF WINDOW — %s LAPSED, %s NOT-YET-LIVE — of %s total. An out-of-window record CONTRIBUTES NO GRANT: it is not counted live, it is not composed, and `modes` does not project it into the licence matrix.\n' \
    "$((NLAPSED + NNOTYET))" "$NLAPSED" "$NNOTYET" "$NENV"
fi
# Reported before the live findings, so a reader meets the records that are NOT
# in force before the ones that are. Each names the term that put it out of the
# window, because "this lease is not in force" is unactionable without the date
# that decided it.
while IFS= read -r id; do
  [ -n "$id" ] || continue
  printf 'envelope: LAPSED %s control=%s granted=%s expires=%s now=%s — the lease ENDED. It contributes no grant: not counted live, not composed, not projected. Nothing about the control changed when it lapsed; it returned to its registered authority, which is what `rollback_behavior` describes.\n' \
    "$id" "$(get "$id" control)" "$(get "$id" granted_authority)" "$(get "$id" expires)" "$NOW"
done < <(printf '%s' "$LAPSED_IDS")
while IFS= read -r id; do
  [ -n "$id" ] || continue
  printf 'envelope: NOT-YET-LIVE %s control=%s granted=%s starts=%s now=%s — the lease has NOT OPENED. A distinct state from LAPSED: this grant is scheduled and has never been in force, and it contributes no grant until it opens.\n' \
    "$id" "$(get "$id" control)" "$(get "$id" granted_authority)" "$(get "$id" starts)" "$NOW"
done < <(printf '%s' "$NOTYET_IDS")
if [ "$NLIVE" -eq 0 ]; then
  if [ "$NENV" -eq 0 ]; then
    printf 'authority-envelope: ZERO live grants is the CORRECT state, not the shelfware state — an empty envelope store means nothing has been re-authorised. (An ABSENT store would refuse: absent is not empty.)\n'
  else
    printf 'authority-envelope: ZERO live grants — every one of the %s record(s) in this store is outside its lease term. A record that is not in force is not a grant, and the correct reading is that nothing is re-authorised right now, not that the store is empty.\n' "$NENV"
  fi
  printf 'authority-envelope: the deployment axis is therefore INERT on this census — every control takes the default `%s`, which adds no cap, so L_effective = MIN(L_class, L_evidence) exactly as before.\n' "$DEPLOYMENT_DEFAULT"
  printf 'authority-envelope: this validator GRANTS NOTHING. Writing a grant is a governance act taken by the operator in %s, never by a tool.\n' "$STORE"
  exit 0
fi

NOVER=0
while IFS= read -r id; do
  [ -n "$id" ] || continue
  ctl="$(get "$id" control)"
  ga="$(get "$id" granted_authority)"
  dm="$(get "$id" deployment_mode)"
  cls="$(awk -v i="$ctl" '/^control: /{c=$2} c==i && /^class: /{print $2; exit}' "$REGISTRY")"
  emp="$(awk -v i="$ctl" '/^control: /{c=$2} c==i && /^empirical_status: /{sub(/^empirical_status: /,""); print; exit}' "$REGISTRY")"
  ccap="$(axis_cap "$CLASS_AXIS" "$cls" || true)"
  cr="$(rank_of "${ccap:-}")"
  er=99; ecap=""
  for t in $(printf '%s' "$emp" | tr ',' ' '); do
    tc="$(axis_cap "$EVIDENCE_AXIS" "$t" || true)"
    tr="$(rank_of "${tc:-}")"
    if [ "$tr" -ge 0 ] && [ "$tr" -lt "$er" ]; then er="$tr"; ecap="$tc"; fi
  done
  dcap="$(axis_cap "$DEPLOYMENT_AXIS" "$dm")"; dr="$(rank_of "$dcap")"
  gr="$(rank_of "$ga")"
  # UNKNOWN CONTROL. Named, never skipped: a grant for a control the census does
  # not classify is a grant nobody can compose, and reporting it as fine would
  # be the permissive fall-through this file refuses everywhere else.
  if [ "$cr" -lt 0 ] || [ "$er" -ge 99 ]; then
    printf 'envelope: UNCOMPOSABLE %s control=%s — the census classifies no control by that id, so L_class and L_evidence cannot be computed. A grant nobody can compose is a grant nobody can check.\n' "$id" "$ctl"
    NOVER=$((NOVER+1))
    continue
  fi
  lr="$cr"; [ "$er" -lt "$lr" ] && lr="$er"; [ "$dr" -lt "$lr" ] && lr="$dr"
  if [ "$gr" -gt "$lr" ]; then
    NOVER=$((NOVER+1))
    ax=""
    [ "$gr" -gt "$cr" ] && ax="${ax:+$ax+}class"
    [ "$gr" -gt "$er" ] && ax="${ax:+$ax+}evidence"
    [ "$gr" -gt "$dr" ] && ax="${ax:+$ax+}deployment"
    printf 'envelope: OVER-GRANTED %s control=%s granted=%s l-class=%s l-evidence=%s l-deployment=%s l-effective=%s deployment-mode=%s binding-axis=%s\n' \
      "$id" "$ctl" "$ga" "$(name_of "$cr")" "$(name_of "$er")" "$(name_of "$dr")" "$(name_of "$lr")" "$dm" "$ax"
  else
    printf 'envelope: WITHIN-LICENCE %s control=%s granted=%s l-class=%s l-evidence=%s l-deployment=%s l-effective=%s deployment-mode=%s binding-axis=none\n' \
      "$id" "$ctl" "$ga" "$(name_of "$cr")" "$(name_of "$er")" "$(name_of "$dr")" "$(name_of "$lr")" "$dm"
  fi
done < <(printf '%s' "$LIVE_IDS")

# THE DENOMINATOR IS THE LIVE SET, not the record count. "0 of 1 grant(s) reach
# beyond L_effective" was printed about a store whose only lease had ended seven
# months earlier; a summary whose denominator counts dead leases is a summary
# that cannot be read.
printf 'authority-envelope: %s of %s LIVE grant(s) reach beyond L_effective = MIN(L_class, L_evidence, L_deployment) — the three terms are reported separately on every line and never blended\n' \
  "$NOVER" "$NLIVE"
printf 'authority-envelope: ADVISORY. This is a chosen policy, not a definition: it reports and exits 0. It GRANTS NOTHING and revokes nothing; both are governance acts for the operator.\n'
exit 0
