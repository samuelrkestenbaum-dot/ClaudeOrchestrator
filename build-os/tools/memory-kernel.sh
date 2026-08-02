#!/usr/bin/env bash
# Build OS — cross-surface memory kernel (v0). The governed adapter, the
# deterministic context compiler, the projection generator and the validator.
#
# WHAT THIS EXISTS AGAINST. Project state today lives in a transcript. A second
# surface — a different provider, a different model, a different session — can
# only pick the work up if a human copies that transcript across, and a copied
# transcript carries no versions, no authority, no evidence and no way to tell an
# observation from an inference. This module records the state as TYPED,
# VERSIONED, NAMESPACED OBJECTS and hands it over as a package that binds to
# exact source versions, so the receiving surface acts on state rather than on
# prose somebody pasted.
#
# THE ONE INVARIANT WORTH THE WHOLE MODULE. A context package that PARSES but
# refers to the WRONG VERSIONS is REFUSED. `resolvability is not identity` is the
# defect class this tree has now found in twelve substrates; a package whose
# every id resolves while its versions have moved on is exactly that class
# wearing a memory layer's clothes. `read-context-package --as-current` refuses
# it. It does not warn, and it does not silently recompile.
#
# WHAT WRITES, AND WHAT DOES NOT. Six subcommands append to the stores under
# build-os/kernel/ — record-namespace, record-actor, record-artifact,
# record-object, record-event, create-handoff, acknowledge-handoff,
# compile-context. They are censused as ONE mutation surface
# (MUT-0010-memory-kernel-store-append, control memory.kernel_store_append) and
# every one of them is APPEND-ONLY: no subcommand rewrites or deletes a row that
# is already stored. validate, read-context-package, export-handoff, project,
# parse-projection and reconcile WRITE NOTHING, ANYWHERE, except where an
# explicit --out names a file outside the stores.
#
# NO NETWORK. Deterministic. Local only.
#
# Usage:
#   memory-kernel.sh validate              [--kernel DIR] [--repo DIR]
#   memory-kernel.sh record-namespace      --id NS --type T --owner ACT --label L [--parent NS]
#   memory-kernel.sh record-actor          --id ACT --actor-type T --role R --surface-family F
#                                          --surface-instance I --namespace NS [--provider P] [--model M] [--session S]
#   memory-kernel.sh record-artifact       --id ART --namespace NS --kind K --path P --anchor ANC --actor ACT
#   memory-kernel.sh record-object         --object-id OBJ --type T --namespace NS --actor ACT --surface S
#                                          --expected-version N --truth-state T [--status S] [--authority A]
#                                          [--evidence L] [--source-refs L] [--supersedes X] [--confidence C]
#                                          [--sensitivity S] [--retention R] [--payload REF] [--on-conflict refuse|record]
#   memory-kernel.sh record-event          --type T --actor ACT --surface S --namespace NS --object OBJ
#                                          --object-version N [--causation EVT] [--correlation C] [--authority A]
#                                          [--evidence L] [--payload REF]
#   memory-kernel.sh record-relationship   --id REL --source OBJ --type T --target OBJ --namespace NS
#                                          --actor ACT [--valid-from D] [--valid-until D] [--evidence L]
#   memory-kernel.sh create-handoff        --id HOF --from-actor ACT --from-surface S --to-role R --namespace NS
#                                          --objective TXT --completed IDS --current-state IDS --open-questions IDS
#                                          --evidence IDS --authority IDS --next-action TXT --acceptance TXT
#   memory-kernel.sh acknowledge-handoff   --handoff HOF --actor ACT --surface S
#   memory-kernel.sh compile-context       --id CTX --namespace NS --actor ACT --surface S --objective TXT
#                                          --budget N [--must-include IDS]
#   memory-kernel.sh read-context-package  --package CTX [--as-current]
#   memory-kernel.sh export-handoff        --handoff HOF --package CTX [--out FILE]
#   memory-kernel.sh project               --object OBJ --actor ACT --surface S [--out FILE]
#   memory-kernel.sh parse-projection      --file FILE
#   memory-kernel.sh reconcile             [--kernel DIR]
#
# Exit: 0 accepted/reconciled, 2 REFUSED (a violation, or a read it cannot trust).
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SELF_DIR/../.." && pwd)"
KDIR="$REPO/build-os/kernel"
KDIR_SET=0
TAB=$'\t'
NOW=""

CMD="${1:-}"
[ $# -gt 0 ] && shift

# THE REFUSAL CHANNEL. Every refusal carries a TOKEN as its first word, so a
# caller and a test can tell the refusals apart without matching prose. Prose
# changes; tokens are the interface.
refuse(){ printf 'memory-kernel: REFUSED — %s\n' "$*" >&2; exit 2; }
usage_die(){ printf 'memory-kernel: %s\n' "$*" >&2; exit 2; }

case "$CMD" in
  validate|record-namespace|record-actor|record-artifact|record-object|record-event|record-relationship|\
  create-handoff|acknowledge-handoff|compile-context|read-context-package|export-handoff|project|\
  parse-projection|reconcile) ;;
  "") usage_die "no subcommand. A bare invocation decides nothing — see the usage block at the top of this file." ;;
  *)  usage_die "unknown subcommand \"$CMD\"" ;;
esac

# ---------------------------------------------------------------- options ----
O_ID=""; O_TYPE=""; O_NS=""; O_PARENT=""; O_OWNER=""; O_LABEL=""; O_ACTOR=""; O_SURFACE=""
O_ROLE=""; O_SFAM=""; O_SINST=""; O_PROVIDER="-"; O_MODEL="-"; O_SESSION="-"; O_ATYPE=""
O_KIND=""; O_PATH=""; O_ANCHOR=""; O_OBJECT=""; O_EXPECTED=""; O_TRUTH=""; O_STATUS=""
O_AUTH="-"; O_EVID="-"; O_SRC="-"; O_SUPERSEDES="-"; O_CONF="-"; O_SENS="internal"
O_RET="project"; O_PAYLOAD="-"; O_CONFLICT="refuse"; O_OBJVER=""; O_CAUSE="-"; O_CORR="-"
O_SOURCE=""; O_TARGET=""; O_FROM=""; O_UNTIL="-"; O_TOROLE=""; O_OBJECTIVE=""
O_COMPLETED="-"; O_CURRENT="-"; O_OPENQ="-"; O_AUTHS="-"; O_NEXT=""; O_ACCEPT=""
O_HANDOFF=""; O_BUDGET=""; O_MUST="-"; O_PACKAGE=""; O_ASCURRENT=0; O_OUT=""; O_FILE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --kernel)           [ $# -ge 2 ] || usage_die "--kernel needs a value"; KDIR="$2"; KDIR_SET=1; shift 2 ;;
    --repo)             [ $# -ge 2 ] || usage_die "--repo needs a value"; REPO="$2"; shift 2 ;;
    --at)               [ $# -ge 2 ] || usage_die "--at needs a value"; NOW="$2"; shift 2 ;;
    --id)               [ $# -ge 2 ] || usage_die "--id needs a value"; O_ID="$2"; shift 2 ;;
    --type)             [ $# -ge 2 ] || usage_die "--type needs a value"; O_TYPE="$2"; shift 2 ;;
    --namespace)        [ $# -ge 2 ] || usage_die "--namespace needs a value"; O_NS="$2"; shift 2 ;;
    --parent)           [ $# -ge 2 ] || usage_die "--parent needs a value"; O_PARENT="$2"; shift 2 ;;
    --owner)            [ $# -ge 2 ] || usage_die "--owner needs a value"; O_OWNER="$2"; shift 2 ;;
    --label)            [ $# -ge 2 ] || usage_die "--label needs a value"; O_LABEL="$2"; shift 2 ;;
    --actor)            [ $# -ge 2 ] || usage_die "--actor needs a value"; O_ACTOR="$2"; shift 2 ;;
    --surface)          [ $# -ge 2 ] || usage_die "--surface needs a value"; O_SURFACE="$2"; shift 2 ;;
    --actor-type)       [ $# -ge 2 ] || usage_die "--actor-type needs a value"; O_ATYPE="$2"; shift 2 ;;
    --role)             [ $# -ge 2 ] || usage_die "--role needs a value"; O_ROLE="$2"; shift 2 ;;
    --surface-family)   [ $# -ge 2 ] || usage_die "--surface-family needs a value"; O_SFAM="$2"; shift 2 ;;
    --surface-instance) [ $# -ge 2 ] || usage_die "--surface-instance needs a value"; O_SINST="$2"; shift 2 ;;
    --provider)         [ $# -ge 2 ] || usage_die "--provider needs a value"; O_PROVIDER="$2"; shift 2 ;;
    --model)            [ $# -ge 2 ] || usage_die "--model needs a value"; O_MODEL="$2"; shift 2 ;;
    --session)          [ $# -ge 2 ] || usage_die "--session needs a value"; O_SESSION="$2"; shift 2 ;;
    --kind)             [ $# -ge 2 ] || usage_die "--kind needs a value"; O_KIND="$2"; shift 2 ;;
    --path)             [ $# -ge 2 ] || usage_die "--path needs a value"; O_PATH="$2"; shift 2 ;;
    --anchor)           [ $# -ge 2 ] || usage_die "--anchor needs a value"; O_ANCHOR="$2"; shift 2 ;;
    --object-id)        [ $# -ge 2 ] || usage_die "--object-id needs a value"; O_ID="$2"; shift 2 ;;
    --object)           [ $# -ge 2 ] || usage_die "--object needs a value"; O_OBJECT="$2"; shift 2 ;;
    --object-version)   [ $# -ge 2 ] || usage_die "--object-version needs a value"; O_OBJVER="$2"; shift 2 ;;
    --expected-version) [ $# -ge 2 ] || usage_die "--expected-version needs a value"; O_EXPECTED="$2"; shift 2 ;;
    --truth-state)      [ $# -ge 2 ] || usage_die "--truth-state needs a value"; O_TRUTH="$2"; shift 2 ;;
    --status)           [ $# -ge 2 ] || usage_die "--status needs a value"; O_STATUS="$2"; shift 2 ;;
    --authority)        [ $# -ge 2 ] || usage_die "--authority needs a value"; O_AUTH="$2"; shift 2 ;;
    --evidence)         [ $# -ge 2 ] || usage_die "--evidence needs a value"; O_EVID="$2"; shift 2 ;;
    --source-refs)      [ $# -ge 2 ] || usage_die "--source-refs needs a value"; O_SRC="$2"; shift 2 ;;
    --supersedes)       [ $# -ge 2 ] || usage_die "--supersedes needs a value"; O_SUPERSEDES="$2"; shift 2 ;;
    --confidence)       [ $# -ge 2 ] || usage_die "--confidence needs a value"; O_CONF="$2"; shift 2 ;;
    --sensitivity)      [ $# -ge 2 ] || usage_die "--sensitivity needs a value"; O_SENS="$2"; shift 2 ;;
    --retention)        [ $# -ge 2 ] || usage_die "--retention needs a value"; O_RET="$2"; shift 2 ;;
    --payload)          [ $# -ge 2 ] || usage_die "--payload needs a value"; O_PAYLOAD="$2"; shift 2 ;;
    --on-conflict)      [ $# -ge 2 ] || usage_die "--on-conflict needs a value"; O_CONFLICT="$2"; shift 2 ;;
    --causation)        [ $# -ge 2 ] || usage_die "--causation needs a value"; O_CAUSE="$2"; shift 2 ;;
    --correlation)      [ $# -ge 2 ] || usage_die "--correlation needs a value"; O_CORR="$2"; shift 2 ;;
    --source)           [ $# -ge 2 ] || usage_die "--source needs a value"; O_SOURCE="$2"; shift 2 ;;
    --target)           [ $# -ge 2 ] || usage_die "--target needs a value"; O_TARGET="$2"; shift 2 ;;
    --valid-from)       [ $# -ge 2 ] || usage_die "--valid-from needs a value"; O_FROM="$2"; shift 2 ;;
    --valid-until)      [ $# -ge 2 ] || usage_die "--valid-until needs a value"; O_UNTIL="$2"; shift 2 ;;
    --from-actor)       [ $# -ge 2 ] || usage_die "--from-actor needs a value"; O_ACTOR="$2"; shift 2 ;;
    --from-surface)     [ $# -ge 2 ] || usage_die "--from-surface needs a value"; O_SURFACE="$2"; shift 2 ;;
    --to-role)          [ $# -ge 2 ] || usage_die "--to-role needs a value"; O_TOROLE="$2"; shift 2 ;;
    --objective)        [ $# -ge 2 ] || usage_die "--objective needs a value"; O_OBJECTIVE="$2"; shift 2 ;;
    --completed)        [ $# -ge 2 ] || usage_die "--completed needs a value"; O_COMPLETED="$2"; shift 2 ;;
    --current-state)    [ $# -ge 2 ] || usage_die "--current-state needs a value"; O_CURRENT="$2"; shift 2 ;;
    --open-questions)   [ $# -ge 2 ] || usage_die "--open-questions needs a value"; O_OPENQ="$2"; shift 2 ;;
    --authority-refs)   [ $# -ge 2 ] || usage_die "--authority-refs needs a value"; O_AUTHS="$2"; shift 2 ;;
    --next-action)      [ $# -ge 2 ] || usage_die "--next-action needs a value"; O_NEXT="$2"; shift 2 ;;
    --acceptance)       [ $# -ge 2 ] || usage_die "--acceptance needs a value"; O_ACCEPT="$2"; shift 2 ;;
    --handoff)          [ $# -ge 2 ] || usage_die "--handoff needs a value"; O_HANDOFF="$2"; shift 2 ;;
    --budget)           [ $# -ge 2 ] || usage_die "--budget needs a value"; O_BUDGET="$2"; shift 2 ;;
    --must-include)     [ $# -ge 2 ] || usage_die "--must-include needs a value"; O_MUST="$2"; shift 2 ;;
    --package)          [ $# -ge 2 ] || usage_die "--package needs a value"; O_PACKAGE="$2"; shift 2 ;;
    --as-current)       O_ASCURRENT=1; shift ;;
    --out)              [ $# -ge 2 ] || usage_die "--out needs a value"; O_OUT="$2"; shift 2 ;;
    --file)             [ $# -ge 2 ] || usage_die "--file needs a value"; O_FILE="$2"; shift 2 ;;
    *) usage_die "unknown option \"$1\"" ;;
  esac
done

# ---------------------------------------------------------------- the enums --
# Declared here and NOWHERE ELSE in this module. An enum written twice is an enum
# that widens in one place and not the other.
NS_TYPES="organization workspace project repository branch packet execution"
ACTOR_TYPES="human ai_agent automation"
OBJ_TYPES="goal plan task decision finding control evidence receipt ranking outcome handoff context_package"
OBJ_STATUS="active sealed open closed superseded retired"
EVENT_TYPES="ObjectCreated ObjectVersioned FindingRecorded EvidenceAttached DecisionSealed DecisionSelected PacketStarted PacketClosed RankingCreated OutcomeRecorded HandoffCreated HandoffAccepted ContextCompiled"
REL_TYPES="depends_on blocks addresses supports contradicts supersedes produces consumes selected_from ranked_in resulted_in governed_by authorized_by derived_from handed_off_to"
TRUTH_STATES="observed reported inferred decided verified refuted unknown"
EVIDENCE_BACKED="observed verified refuted"
ARTIFACT_KINDS="repo_file anchor_site export projection"
SENSITIVITIES="public internal restricted secret_ref"
RETENTIONS="ephemeral packet project permanent"
HANDOFF_STATUS="created accepted refused expired"
SCHEMA_VERSION="1"

# THE STORES, and their field orders. One canonical representation per store.
NS_F="namespace_id parent_namespace_id namespace_type owner_id created_at status label"
AC_F="actor_id actor_type logical_role surface_family surface_instance provider model session_id namespace_id"
OB_F="object_id object_type schema_version namespace_id version status created_at updated_at created_by updated_by owner_id authority_ref evidence_refs source_refs supersedes confidence sensitivity retention_class truth_state content_hash payload_ref"
EV_F="event_id event_type occurred_at recorded_at actor_id surface_id namespace_id object_id object_version causation_id correlation_id authority_ref evidence_refs payload_ref integrity_hash"
RL_F="relationship_id source_object_id relationship_type target_object_id namespace_id valid_from valid_until created_by evidence_refs"
AR_F="artifact_id namespace_id artifact_kind path anchor_ref content_hash created_at created_by"
HO_F="handoff_id from_actor_id from_surface_id to_role namespace_id objective completed_object_ids current_state_object_ids open_question_ids evidence_refs authority_refs required_next_action acceptance_criteria created_at status accepted_by accepted_at"
CP_F="context_package_id compiled_at namespace_id actor_id surface_id objective source_object_ids source_object_versions included_relationship_ids included_event_ids omitted_object_ids omission_reasons authority_state contradictions token_or_size_budget content_hash"

# `--repo` without `--kernel` retargets the stores too: a kernel is a property of
# the repository it describes, and resolving artifacts against one tree while
# reading objects from another would produce evidence that resolves in a
# repository nobody asked about.
[ "$KDIR_SET" = "1" ] || KDIR="$REPO/build-os/kernel"

F_NS="$KDIR/namespaces.tsv";            F_AC="$KDIR/actors.tsv"
F_OB="$KDIR/memory_objects.tsv";        F_EV="$KDIR/memory_events.tsv"
F_RL="$KDIR/memory_relationships.tsv";  F_AR="$KDIR/memory_artifacts.tsv"
F_HO="$KDIR/memory_handoffs.tsv";       F_CP="$KDIR/memory_context_packages.tsv"
EXPORTS="$KDIR/exports"

# --------------------------------------------------------------- primitives --
in_list(){ case " $2 " in *" $1 "*) return 0 ;; esac; return 1; }

# ROW ACCESS. Every count in this module is a ROW count taken with `grep -c` on
# an id prefix, never `wc -l`: a final row with no trailing newline is a row, and
# a line count would lose it. `|| true` because grep exits 1 on no match and this
# file runs under `set -e`-adjacent discipline everywhere else.
rows(){ grep -h "^$2" "$1" 2>/dev/null || true; }
nrows(){ local n; n="$(grep -c "^$2" "$1" 2>/dev/null || true)"; printf '%s' "${n:-0}"; }
fld(){ printf '%s' "$1" | cut -f"$2"; }
# The row whose field 1 equals an id, or non-zero. Anchored on the TAB so
# `OBJ-0001` cannot be matched by `OBJ-00010`.
row_by_id(){ local r; r="$(grep -m1 "^$2${TAB}" "$1" 2>/dev/null || true)"; [ -n "$r" ] || return 1; printf '%s' "$r"; }

HASHER=()
if _h="$(command -v sha256sum 2>/dev/null)"; then HASHER=("${_h}")
elif _h="$(command -v shasum 2>/dev/null)"; then HASHER=("${_h}" -a 256)
fi
sha(){ # <string> -> 64 hex chars
  [ ${#HASHER[@]} -gt 0 ] || refuse "HASH-UNAVAILABLE neither sha256sum nor shasum is on this machine. Content hashes are the identity of every object and package here; computing them with something weaker would produce a store that LOOKS bound to its sources and is not."
  printf '%s' "$1" | "${HASHER[@]}" | cut -d' ' -f1
}

now(){ [ -n "$NOW" ] && { printf '%s' "$NOW"; return; }; date -u +%Y-%m-%dT%H:%M:%SZ; }

# NO RAW CREDENTIAL MAY ENTER THE STORES. Security v0 says secrets are
# REFERENCES ONLY, and a rule that is only written down is not a rule. The
# patterns are deliberately narrow and named: this catches the shapes that are
# unambiguously credentials, and it does not pretend to catch a password that
# looks like a word.
SECRET_RE='(sk-[A-Za-z0-9]{16,}|ghp_[A-Za-z0-9]{16,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|xox[baprs]-[A-Za-z0-9-]{10,})'
no_secret(){ # <field-name> <value>
  case "$2" in *[!\ ]*) ;; *) return 0 ;; esac
  if printf '%s' "$2" | grep -qE "$SECRET_RE"; then
    refuse "SECRET-INLINE the field \"$1\" carries what looks like a raw credential. Memory objects and context packages hold REFERENCES to secrets and never the secrets themselves; a credential written here would be copied into every projection and every export."
  fi
}
# A tab or a newline inside a value would silently create or merge fields.
no_sep(){ case "$2" in *"$TAB"*) refuse "KERNEL-SCHEMA the field \"$1\" contains a TAB. The separator cannot appear inside a value — a row with an extra field is a row that parses as something else." ;; esac; }

req(){ [ -n "$2" ] || usage_die "$1 is required for \`$CMD\`"; }

# ------------------------------------------------------------- the closure ---
# NAMESPACE ISOLATION. `closure(N)` is N plus every descendant of N. It is the
# ONLY visibility rule in this module: an actor declared in N may act in
# closure(N) and nowhere else, and a read that reaches sideways is REFUSED
# rather than filtered — a silent filter and an empty result are
# indistinguishable to the caller, and a memory layer that cannot tell them
# apart is one that leaks by looking empty.
ns_parent(){ local r; r="$(row_by_id "$F_NS" "$1")" || return 1; fld "$r" 2; }
ns_closure(){ # <namespace-id> -> that namespace and every descendant, one per line
  local frontier="$1" next seen="" n p r
  while [ -n "$frontier" ]; do
    next=""
    for n in $frontier; do
      case " $seen " in *" $n "*) continue ;; esac
      seen="$seen $n"; printf '%s\n' "$n"
      while IFS= read -r r; do
        [ -n "$r" ] || continue
        p="$(fld "$r" 2)"; [ "$p" = "$n" ] || continue
        next="$next $(fld "$r" 1)"
      done < <(rows "$F_NS" "NS-")
    done
    frontier="$next"
  done
}
ns_in_closure(){ # <candidate> <root>
  local c; while IFS= read -r c; do [ "$c" = "$1" ] && return 0; done < <(ns_closure "$2"); return 1
}
actor_row(){ row_by_id "$F_AC" "$1"; }

# EVERY read and EVERY write identifies actor, surface and namespace. This is the
# one gate they all pass through, so there is no path that forgets one.
authorise(){ # <actor-id> <surface-id> <namespace-id>
  local ar afs ans
  ar="$(actor_row "$1")" || refuse "ACTOR-UNKNOWN \"$1\" is not a declared actor. An unattributed write has nobody to hold responsible for it."
  afs="$(fld "$ar" 5)"; ans="$(fld "$ar" 9)"
  [ "$2" = "$afs" ] || refuse "SURFACE-IDENTITY actor $1 declares surface_instance \"$afs\" and this call claims \"$2\". A logical role may not borrow an execution surface it never ran on — that is the whole reason the two are separate fields."
  row_by_id "$F_NS" "$3" >/dev/null || refuse "NAMESPACE-UNKNOWN \"$3\" is not a declared namespace."
  ns_in_closure "$3" "$ans" || refuse "NAMESPACE-REFUSED actor $1 is declared in $ans and this call targets $3, which is not $ans or a descendant of it. Cross-namespace access is refused by default; widening it is a governance act and not a caller's."
}

# ------------------------------------------------------------ object access --
# THE CURRENT VERSION of an object is the highest version row it owns. The store
# is append-only by version: a correction is a NEW ROW, never an edit, so the
# history of what the system believed is recoverable and a version number cannot
# be reused to mean two different things.
obj_versions(){ rows "$F_OB" "$1${TAB}" | cut -f5 | sort -n; }
obj_current_version(){ local v; v="$(obj_versions "$1" | tail -1)"; printf '%s' "${v:-0}"; }
obj_row_at(){ # <object-id> <version>
  local r; while IFS= read -r r; do [ "$(fld "$r" 5)" = "$2" ] && { printf '%s' "$r"; return 0; }; done < <(rows "$F_OB" "$1${TAB}"); return 1
}
obj_current_row(){ obj_row_at "$1" "$(obj_current_version "$1")"; }

# The content hash covers every envelope field EXCEPT the hash itself. Recomputed
# on read, so a hand-edited row is detectable without a second store to compare
# against.
obj_hash_input(){ # <row>
  local r="$1" i out=""
  for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 21; do out="$out|$(fld "$r" "$i")"; done
  printf '%s' "$out"
}
ev_hash_input(){ # <row> <prev-integrity-hash>
  local r="$1" i out="$2"
  for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14; do out="$out|$(fld "$r" "$i")"; done
  printf '%s' "$out"
}

next_id(){ # <file> <prefix> -> the next free NNNN id in that store
  local n last
  last="$(rows "$1" "$2" | cut -f1 | sed "s/^$2//" | sort -n | tail -1)"
  # `10#` FORCES BASE TEN. Ids are zero-padded, and bash reads a leading zero as
  # octal: `$((0008+1))` is not 9, it is a fatal parse error, and the id that
  # follows it would have been written empty.
  n=$(( 10#${last:-0} + 1 ))
  printf '%s%04d' "$2" "$n"
}

# --------------------------------------------------------- evidence refs -----
# An evidence reference is an ARTIFACT ID, and an artifact resolves BY CONTENT
# through the anchor scheme PACKET-0029 shipped — never by line number. This is
# the single most important reason no canonical store under build-os/kernel/
# RECORDS a `path:line` token: an anchored citation survives the line moving, and
# this tree's most-recurring defect class is the one that does not. The generated
# export does PRINT `path:line#ANCHOR`, and that is the distinction rather than an
# exception — a position the resolver returned at generation time is a navigation
# hint, and a position written into a store is an identity that decays.
SCANC="$REPO/build-os/registry/scan-controls.sh"
art_resolves(){ # <artifact-id> -> 0 and prints "path:line", or non-zero and prints why
  local ar path anc out
  ar="$(row_by_id "$F_AR" "$1")" || { printf 'no artifact record %s' "$1"; return 1; }
  path="$(fld "$ar" 4)"; anc="$(fld "$ar" 5)"
  [ -f "$REPO/$path" ] || { printf 'artifact %s names %s, which is not a file in this tree' "$1" "$path"; return 1; }
  if [ "$anc" = "-" ]; then printf '%s:-' "$path"; return 0; fi
  [ -x "$SCANC" ] || { printf 'the anchor resolver is not executable, so %s cannot be resolved by content' "$anc"; return 1; }
  out="$(bash "$SCANC" anchors --ref "$anc" 2>&1)"
  case "$out" in
    *"status: RESOLVED"*)
      # The RESOLVER RETURNS A POSITION; it is never given one. This is the
      # PACKET-0029 projection line — `path:line#ANCHOR` — and the line number in
      # it is a return value, not an identity.
      printf '%s' "$(printf '%s\n' "$out" | sed -n 's/^projection: //p' | head -1)"; return 0 ;;
  esac
  printf 'anchor %s does not resolve by content: %s' "$anc" "$(printf '%s\n' "$out" | tail -1)"; return 1
}
# A list field holds `;`-separated members, and `-` means EMPTY. Returning the
# dash as if it were a member is how an absent evidence list becomes a citation
# to an artifact called "-".
evid_list(){ [ "$1" = "-" ] && return 0; printf '%s' "$1" | tr ';' '\n' | grep -v '^$' || true; }

# =============================================================== validate ====
# WHAT `validate` IS FOR. Every other subcommand refuses a bad write at the door.
# This one re-reads the whole store set and refuses a store that has been
# CORRUPTED AROUND the writer — a row hand-edited in an editor, an event
# unchained, a package whose recorded hash no longer describes its own contents.
# The writer's checks protect the future; this protects the past.
validate(){
  local V=0 r id i f nf seen="" prev="" want
  viol(){ V=$((V+1)); printf '  %s\n' "$*"; }

  for f in "$F_NS" "$F_AC" "$F_OB" "$F_EV" "$F_RL" "$F_AR" "$F_HO" "$F_CP"; do
    [ -f "$f" ] || refuse "KERNEL-STORE-MISSING $f. An absent store is not an empty one, and validating what is left would certify a kernel with a hole in it."
  done

  # --- namespaces: a tree, not a graph, and rooted.
  local nroots=0
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    nf="$(printf '%s' "$r" | awk -F'\t' '{print NF}')"
    [ "$nf" = "7" ] || { viol "KERNEL-SCHEMA namespace row carries $nf field(s), not 7: $(fld "$r" 1)"; continue; }
    id="$(fld "$r" 1)"
    in_list "$(fld "$r" 3)" "$NS_TYPES" || viol "KERNEL-SCHEMA $id declares namespace_type \"$(fld "$r" 3)\", which is not one of: $NS_TYPES"
    if [ "$(fld "$r" 2)" = "-" ]; then nroots=$((nroots+1))
    else row_by_id "$F_NS" "$(fld "$r" 2)" >/dev/null || viol "NAMESPACE-UNKNOWN $id names parent $(fld "$r" 2), which is not declared"; fi
  done < <(rows "$F_NS" "NS-")
  [ "$nroots" = "1" ] || viol "KERNEL-SCHEMA the namespace store has $nroots root(s). Exactly one organization root makes the closure computable; zero or two do not."

  # --- actors: every actor lands in a declared namespace, and no two actors
  # share one execution surface instance. A surface that names two actors
  # identifies neither, which is the anchor scheme's rule 2 in another store.
  local sinsts=""
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    nf="$(printf '%s' "$r" | awk -F'\t' '{print NF}')"
    [ "$nf" = "9" ] || { viol "KERNEL-SCHEMA actor row carries $nf field(s), not 9: $(fld "$r" 1)"; continue; }
    id="$(fld "$r" 1)"
    in_list "$(fld "$r" 2)" "$ACTOR_TYPES" || viol "KERNEL-SCHEMA $id declares actor_type \"$(fld "$r" 2)\", which is not one of: $ACTOR_TYPES"
    row_by_id "$F_NS" "$(fld "$r" 9)" >/dev/null || viol "NAMESPACE-UNKNOWN actor $id is declared in $(fld "$r" 9), which is not a namespace"
    [ "$(fld "$r" 3)" = "$(fld "$r" 5)" ] && viol "ACTOR-IDENTITY $id uses one token for both its logical_role and its surface_instance. Responsibility and execution are different things and this store keeps them apart."
    in_list "$(fld "$r" 5)" "$sinsts" && viol "SURFACE-IDENTITY surface_instance $(fld "$r" 5) is claimed by more than one actor"
    sinsts="$sinsts $(fld "$r" 5)"
  done < <(rows "$F_AC" "ACT-")

  # --- artifacts: every one resolves in the CURRENT tree, by content.
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    nf="$(printf '%s' "$r" | awk -F'\t' '{print NF}')"
    [ "$nf" = "8" ] || { viol "KERNEL-SCHEMA artifact row carries $nf field(s), not 8: $(fld "$r" 1)"; continue; }
    id="$(fld "$r" 1)"
    in_list "$(fld "$r" 3)" "$ARTIFACT_KINDS" || viol "KERNEL-SCHEMA $id declares artifact_kind \"$(fld "$r" 3)\", not one of: $ARTIFACT_KINDS"
    art_resolves "$id" >/dev/null || viol "EVIDENCE-UNRESOLVED $id — $(art_resolves "$id")"
  done < <(rows "$F_AR" "ART-")

  # --- objects: version integrity, truth-state backing, and the two shapes of
  # duplicate writable truth.
  local payloads=""
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    nf="$(printf '%s' "$r" | awk -F'\t' '{print NF}')"
    [ "$nf" = "21" ] || { viol "KERNEL-SCHEMA object row carries $nf field(s), not 21: $(fld "$r" 1)"; continue; }
    id="$(fld "$r" 1)"; local ver; ver="$(fld "$r" 5)"
    in_list "$(fld "$r" 2)" "$OBJ_TYPES"      || viol "KERNEL-SCHEMA $id@$ver declares object_type \"$(fld "$r" 2)\", not one of: $OBJ_TYPES"
    in_list "$(fld "$r" 6)" "$OBJ_STATUS"     || viol "KERNEL-SCHEMA $id@$ver declares status \"$(fld "$r" 6)\", not one of: $OBJ_STATUS"
    in_list "$(fld "$r" 19)" "$TRUTH_STATES"  || viol "KERNEL-SCHEMA $id@$ver declares truth_state \"$(fld "$r" 19)\", not one of: $TRUTH_STATES"
    in_list "$(fld "$r" 17)" "$SENSITIVITIES" || viol "KERNEL-SCHEMA $id@$ver declares sensitivity \"$(fld "$r" 17)\", not one of: $SENSITIVITIES"
    in_list "$(fld "$r" 18)" "$RETENTIONS"    || viol "KERNEL-SCHEMA $id@$ver declares retention_class \"$(fld "$r" 18)\", not one of: $RETENTIONS"
    row_by_id "$F_NS" "$(fld "$r" 4)" >/dev/null || viol "NAMESPACE-UNKNOWN $id@$ver lives in $(fld "$r" 4), which is not a namespace"
    [ "$(sha "$(obj_hash_input "$r")")" = "$(fld "$r" 20)" ] \
      || viol "OBJECT-HASH $id@$ver carries a content_hash that does not describe its own fields. The row has been edited outside the writer."
    # TRUTH STATE IS NOT EVIDENCE. observed/verified/refuted are claims about the
    # world and must cite something in it; inferred and reported are claims about
    # a model and must not be dressed as observations.
    if in_list "$(fld "$r" 19)" "$EVIDENCE_BACKED"; then
      [ "$(fld "$r" 13)" = "-" ] && viol "TRUTH-STATE-UNBACKED $id@$ver claims truth_state \"$(fld "$r" 19)\" with no evidence_refs. A model-generated inference recorded as an observation is the failure this field exists to prevent."
    fi
    [ "$(fld "$r" 19)" = "decided" ] && [ "$(fld "$r" 12)" = "-" ] \
      && viol "AUTHORITY-MISSING $id@$ver claims truth_state \"decided\" with no authority_ref. A decision nobody authorised is an opinion."
    for i in $(evid_list "$(fld "$r" 13)"); do
      art_resolves "$i" >/dev/null || viol "EVIDENCE-UNRESOLVED $id@$ver cites $i — $(art_resolves "$i")"
    done
    # DUPLICATE WRITABLE TRUTH, both shapes.
    local pr; pr="$(fld "$r" 21)"
    case "$pr" in
      "$KDIR/exports/"*|build-os/kernel/exports/*) viol "DUPLICATE-WRITABLE-TRUTH $id@$ver stores its canonical payload at $pr, inside the generated projection tree. Canonical truth may not live inside its own shadow." ;;
    esac
    if [ "$pr" != "-" ]; then
      case " $payloads " in *" $pr=$id "*) : ;; *" $pr="*) viol "DUPLICATE-WRITABLE-TRUTH payload_ref $pr is claimed by more than one object. Two objects that own one payload are two editable copies of one fact." ;; esac
      payloads="$payloads $pr=$id"
    fi
  done < <(rows "$F_OB" "OBJ-")

  # Version sequences: 1..N with no gap, no repeat, and a supersedes that points
  # backwards rather than at itself.
  for id in $(rows "$F_OB" "OBJ-" | cut -f1 | sort -u); do
    want=1
    for i in $(obj_versions "$id"); do
      [ "$i" = "$want" ] || { viol "VERSION-NONMONOTONIC $id has version $i where $want was due. Versions are a sequence and a gap or a repeat means a correction went unrecorded."; break; }
      want=$((want+1))
    done
  done

  # --- events: append-only, proved by a digest chain rather than asserted.
  prev=""
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    nf="$(printf '%s' "$r" | awk -F'\t' '{print NF}')"
    [ "$nf" = "15" ] || { viol "KERNEL-SCHEMA event row carries $nf field(s), not 15: $(fld "$r" 1)"; continue; }
    id="$(fld "$r" 1)"
    in_list "$(fld "$r" 2)" "$EVENT_TYPES" || viol "KERNEL-SCHEMA $id declares event_type \"$(fld "$r" 2)\", not one of: $EVENT_TYPES"
    in_list "$id" "$seen" && viol "EVENT-APPEND-ONLY $id occurs more than once. An event id is written once and never again."
    seen="$seen $id"
    want="$(sha "$(ev_hash_input "$r" "$prev")")"
    if [ "$want" != "$(fld "$r" 15)" ]; then
      viol "EVENT-APPEND-ONLY $id breaks the integrity chain. Its digest does not follow from its own fields and the digest of the event before it, so a row has been edited, inserted or removed."
    fi
    prev="$(fld "$r" 15)"
    [ "$(fld "$r" 8)" = "-" ] || obj_row_at "$(fld "$r" 8)" "$(fld "$r" 9)" >/dev/null \
      || viol "EVENT-DANGLING $id names $(fld "$r" 8)@$(fld "$r" 9), which the object store does not carry at that version"
    [ "$(fld "$r" 10)" = "-" ] || row_by_id "$F_EV" "$(fld "$r" 10)" >/dev/null \
      || viol "CAUSAL-CHAIN-BROKEN $id names causation_id $(fld "$r" 10), which is not an event"
  done < <(rows "$F_EV" "EVT-")

  # --- relationships
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    nf="$(printf '%s' "$r" | awk -F'\t' '{print NF}')"
    [ "$nf" = "9" ] || { viol "KERNEL-SCHEMA relationship row carries $nf field(s), not 9: $(fld "$r" 1)"; continue; }
    id="$(fld "$r" 1)"
    in_list "$(fld "$r" 3)" "$REL_TYPES" || viol "KERNEL-SCHEMA $id declares relationship_type \"$(fld "$r" 3)\", not one of: $REL_TYPES"
    obj_current_row "$(fld "$r" 2)" >/dev/null || viol "RELATIONSHIP-DANGLING $id sources from $(fld "$r" 2), which is not an object"
    obj_current_row "$(fld "$r" 4)" >/dev/null || viol "RELATIONSHIP-DANGLING $id targets $(fld "$r" 4), which is not an object"
  done < <(rows "$F_RL" "REL-")

  # --- handoffs: every referenced object must resolve, or the receiving surface
  # is handed a list of names it cannot act on.
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    nf="$(printf '%s' "$r" | awk -F'\t' '{print NF}')"
    [ "$nf" = "17" ] || { viol "KERNEL-SCHEMA handoff row carries $nf field(s), not 17: $(fld "$r" 1)"; continue; }
    id="$(fld "$r" 1)"
    in_list "$(fld "$r" 15)" "$HANDOFF_STATUS" || viol "KERNEL-SCHEMA $id declares status \"$(fld "$r" 15)\", not one of: $HANDOFF_STATUS"
    for i in 7 8 9; do
      for f in $(evid_list "$(fld "$r" $i)"); do
        obj_current_row "$f" >/dev/null || viol "HANDOFF-UNRESOLVED $id references object $f, which the store does not carry"
      done
    done
    for f in $(evid_list "$(fld "$r" 10)"); do
      art_resolves "$f" >/dev/null || viol "EVIDENCE-UNRESOLVED handoff $id cites $f — $(art_resolves "$f")"
    done
    # A handoff with no HandoffCreated event never happened as far as the ledger
    # is concerned, and a ledger with a hole in it is not a causal chain.
    local hev; hev="$(rows "$F_EV" "EVT-" | awk -F'\t' -v h="$id" '$2=="HandoffCreated" && $14==h {print $1}')"
    [ -n "$hev" ] || viol "CAUSAL-CHAIN-BROKEN $id exists in the handoff store with no HandoffCreated event naming it."
  done < <(rows "$F_HO" "HOF-")

  # --- context packages: identity, and the stale/current distinction.
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    nf="$(printf '%s' "$r" | awk -F'\t' '{print NF}')"
    [ "$nf" = "16" ] || { viol "KERNEL-SCHEMA context package row carries $nf field(s), not 16: $(fld "$r" 1)"; continue; }
    id="$(fld "$r" 1)"
    [ "$(sha "$(cp_hash_input "$r")")" = "$(fld "$r" 16)" ] \
      || viol "PACKAGE-IDENTITY $id carries a content_hash that does not describe its own fields. The row was edited without recomputing its hash — this catches a careless edit and NOT a writer, because the hash is unkeyed and can be recomputed by anyone who can write the row. The check that catches a re-signed edit is PACKAGE-UNANCHORED below."
    # ...and THAT is the check that makes the row's hash mean anything, because it
    # compares it against the digest-chained ledger rather than against itself.
    local why; if why="$(pkg_anchor_fault "$r")"; then viol "PACKAGE-UNANCHORED $why"; fi
    local ids vers n1 n2
    ids="$(fld "$r" 7)"; vers="$(fld "$r" 8)"
    n1="$(evid_list "$ids" | grep -c . || true)"; n2="$(evid_list "$vers" | grep -c . || true)"
    [ "$n1" = "$n2" ] || viol "PACKAGE-IDENTITY $id binds $n1 object(s) to $n2 version(s). An unpaired binding names an object at no version, which is the resolvability-is-not-identity defect exactly."
    # Omissions must carry reasons, one for one.
    n1="$(evid_list "$(fld "$r" 11)" | grep -c . || true)"; n2="$(evid_list "$(fld "$r" 12)" | grep -c . || true)"
    [ "$n1" = "$n2" ] || viol "OMISSION-UNEXPLAINED $id omits $n1 object(s) and states $n2 reason(s). An omission with no reason is indistinguishable from an object the compiler never saw."
  done < <(rows "$F_CP" "CTX-")

  printf 'memory-kernel: %s namespace(s), %s actor(s), %s artifact(s), %s object row(s), %s event(s), %s relationship(s), %s handoff(s), %s context package(s)\n' \
    "$(nrows "$F_NS" "NS-")" "$(nrows "$F_AC" "ACT-")" "$(nrows "$F_AR" "ART-")" "$(nrows "$F_OB" "OBJ-")" \
    "$(nrows "$F_EV" "EVT-")" "$(nrows "$F_RL" "REL-")" "$(nrows "$F_HO" "HOF-")" "$(nrows "$F_CP" "CTX-")"
  if [ "$V" -gt 0 ]; then
    printf 'memory-kernel: REFUSED — %s violation(s) across the kernel stores.\n' "$V" >&2
    exit 2
  fi
  printf 'memory-kernel: stores reconciled — 0 violations\n'
}

cp_hash_input(){ # <context-package-row>
  local r="$1" i out=""
  for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do out="$out|$(fld "$r" "$i")"; done
  printf '%s' "$out"
}

# WHAT THE SELF-HASH DOES NOT DO. `cp_hash_input` covers the package's OWN fields
# and is UNKEYED, so anyone who can write the store can edit a field and re-sign
# the row. That check catches a careless edit; it is not tamper evidence against a
# writer, and a perimeter claimed wider than it is, is worse than an admitted gap.
# THE TAMPER EVIDENCE IS THE LEDGER. `compile-context` writes the package's
# content_hash into the ContextCompiled event as `<package-id>@<hash>`, and the
# event ledger is digest-chained: moving that hash means re-chaining every event
# after it. This returns the hash the ledger recorded, or empty when the ledger
# carries no anchor for the package at all.
pkg_ledger_hash(){ # <context-package-id> -> the anchored hash, or empty
  rows "$F_EV" "EVT-" | awk -F'\t' -v p="$1" \
    '$2=="ContextCompiled" && index($14, p "@")==1 {print substr($14, length(p)+2)}' | tail -1
}
# The one place the anchor is checked, so `validate` and the read path cannot
# drift apart on what "anchored" means. Prints why on failure.
pkg_anchor_fault(){ # <context-package-row> -> 0 and prints a reason, or 1
  local id lh; id="$(fld "$1" 1)"; lh="$(pkg_ledger_hash "$id")"
  if [ -z "$lh" ]; then
    printf '%s carries no package content_hash in any ContextCompiled event, so nothing anchors this row to the chained ledger and its self-hash can be re-signed by anyone who can write the store' "$id"; return 0
  fi
  if [ "$lh" != "$(fld "$1" 16)" ]; then
    printf '%s hashes to %s and the ContextCompiled event recorded %s. The row has been edited AND re-signed: the self-hash agrees with the edit, and the digest-chained ledger does not' "$id" "$(fld "$1" 16)" "$lh"; return 0
  fi
  return 1
}

# ============================================================ the writers ====
# EVERY WRITE IS AN APPEND, and every append is preceded by the same three
# checks: the actor exists, the surface is the actor's own, and the namespace is
# inside the actor's closure. There is no path into these stores that skips
# `authorise`.
append_row(){ printf '%s\n' "$2" >> "$1"; }

emit_event(){ # <type> <actor> <surface> <ns> <object> <objver> <causation> <correlation> <authority> <evidence> <payload>
  local eid ts prev row ih
  eid="$(next_id "$F_EV" "EVT-")"; ts="$(now)"
  prev="$(rows "$F_EV" "EVT-" | tail -1 | cut -f15)"
  row="$eid${TAB}$1${TAB}$ts${TAB}$ts${TAB}$2${TAB}$3${TAB}$4${TAB}$5${TAB}$6${TAB}$7${TAB}$8${TAB}$9${TAB}${10}${TAB}${11}"
  ih="$(sha "$(ev_hash_input "$row" "$prev")")"
  append_row "$F_EV" "$row${TAB}$ih"
  printf '%s %s' "$eid" "$ih"
}

do_record_namespace(){
  req --id "$O_ID"; req --type "$O_TYPE"; req --owner "$O_OWNER"; req --label "$O_LABEL"
  in_list "$O_TYPE" "$NS_TYPES" || refuse "KERNEL-SCHEMA namespace_type \"$O_TYPE\" is not one of: $NS_TYPES"
  row_by_id "$F_NS" "$O_ID" >/dev/null && refuse "KERNEL-APPEND-ONLY namespace $O_ID already exists. This store is appended to, never rewritten."
  [ "${O_PARENT:--}" = "-" ] || row_by_id "$F_NS" "$O_PARENT" >/dev/null || refuse "NAMESPACE-UNKNOWN parent \"$O_PARENT\" is not declared."
  no_sep label "$O_LABEL"; no_secret label "$O_LABEL"
  append_row "$F_NS" "$O_ID${TAB}${O_PARENT:--}${TAB}$O_TYPE${TAB}$O_OWNER${TAB}$(now)${TAB}active${TAB}$O_LABEL"
  printf 'RECEIPT: memory-kernel record-namespace\n  namespace: %s (%s) parent=%s owner=%s\n  store: namespaces.tsv (append)\n' \
    "$O_ID" "$O_TYPE" "${O_PARENT:--}" "$O_OWNER"
}

do_record_actor(){
  req --id "$O_ID"; req --actor-type "$O_ATYPE"; req --role "$O_ROLE"; req --surface-family "$O_SFAM"
  req --surface-instance "$O_SINST"; req --namespace "$O_NS"
  in_list "$O_ATYPE" "$ACTOR_TYPES" || refuse "KERNEL-SCHEMA actor_type \"$O_ATYPE\" is not one of: $ACTOR_TYPES"
  row_by_id "$F_AC" "$O_ID" >/dev/null && refuse "KERNEL-APPEND-ONLY actor $O_ID already exists."
  row_by_id "$F_NS" "$O_NS" >/dev/null || refuse "NAMESPACE-UNKNOWN \"$O_NS\" is not a declared namespace."
  [ "$O_ROLE" = "$O_SINST" ] && refuse "ACTOR-IDENTITY the logical_role and the surface_instance are the same token. Responsibility and execution are different things; collapsing them is how an audit loses the ability to say which surface ran a role."
  no_secret session "$O_SESSION"
  append_row "$F_AC" "$O_ID${TAB}$O_ATYPE${TAB}$O_ROLE${TAB}$O_SFAM${TAB}$O_SINST${TAB}$O_PROVIDER${TAB}$O_MODEL${TAB}$O_SESSION${TAB}$O_NS"
  printf 'RECEIPT: memory-kernel record-actor\n  actor: %s role=%s surface=%s/%s provider=%s model=%s namespace=%s\n  store: actors.tsv (append)\n' \
    "$O_ID" "$O_ROLE" "$O_SFAM" "$O_SINST" "$O_PROVIDER" "$O_MODEL" "$O_NS"
}

do_record_artifact(){
  req --id "$O_ID"; req --namespace "$O_NS"; req --kind "$O_KIND"; req --path "$O_PATH"; req --actor "$O_ACTOR"
  in_list "$O_KIND" "$ARTIFACT_KINDS" || refuse "KERNEL-SCHEMA artifact_kind \"$O_KIND\" is not one of: $ARTIFACT_KINDS"
  row_by_id "$F_AR" "$O_ID" >/dev/null && refuse "KERNEL-APPEND-ONLY artifact $O_ID already exists."
  [ -f "$REPO/$O_PATH" ] || refuse "EVIDENCE-UNRESOLVED $O_PATH is not a file in this tree. An artifact record for a file that does not exist is a citation to nothing."
  append_row "$F_AR" "$O_ID${TAB}$O_NS${TAB}$O_KIND${TAB}$O_PATH${TAB}${O_ANCHOR:--}${TAB}-${TAB}$(now)${TAB}$O_ACTOR"
  local where; where="$(art_resolves "$O_ID")" || refuse "EVIDENCE-UNRESOLVED $O_ID — $where"
  printf 'RECEIPT: memory-kernel record-artifact\n  artifact: %s kind=%s anchor=%s\n  resolves: %s\n  store: memory_artifacts.tsv (append)\n' \
    "$O_ID" "$O_KIND" "${O_ANCHOR:--}" "$where"
}

do_record_object(){
  req --object-id "$O_ID"; req --type "$O_TYPE"; req --namespace "$O_NS"; req --actor "$O_ACTOR"
  req --surface "$O_SURFACE"; req --expected-version "$O_EXPECTED"; req --truth-state "$O_TRUTH"
  authorise "$O_ACTOR" "$O_SURFACE" "$O_NS"
  in_list "$O_TYPE" "$OBJ_TYPES"    || refuse "KERNEL-SCHEMA object_type \"$O_TYPE\" is not one of: $OBJ_TYPES"
  in_list "$O_TRUTH" "$TRUTH_STATES"|| refuse "KERNEL-SCHEMA truth_state \"$O_TRUTH\" is not one of: $TRUTH_STATES"
  [ -n "$O_STATUS" ] || O_STATUS="active"
  in_list "$O_STATUS" "$OBJ_STATUS" || refuse "KERNEL-SCHEMA status \"$O_STATUS\" is not one of: $OBJ_STATUS"
  in_list "$O_SENS" "$SENSITIVITIES"|| refuse "KERNEL-SCHEMA sensitivity \"$O_SENS\" is not one of: $SENSITIVITIES"
  in_list "$O_RET" "$RETENTIONS"    || refuse "KERNEL-SCHEMA retention_class \"$O_RET\" is not one of: $RETENTIONS"
  printf '%s' "$O_EXPECTED" | grep -qE '^[0-9]+$' || refuse "KERNEL-SCHEMA --expected-version \"$O_EXPECTED\" is not a number. Optimistic concurrency needs a number to compare, and a caller that cannot state which version it read has not read one."
  local f; for f in payload_ref evidence_refs source_refs authority_ref; do :; done
  no_secret payload_ref "$O_PAYLOAD"; no_secret evidence_refs "$O_EVID"; no_secret source_refs "$O_SRC"; no_secret authority_ref "$O_AUTH"
  no_sep payload_ref "$O_PAYLOAD"
  case "$O_PAYLOAD" in build-os/kernel/exports/*) refuse "DUPLICATE-WRITABLE-TRUTH the payload_ref points into build-os/kernel/exports/, which is generated. Canonical truth may not be stored inside its own projection — that is DEFECT-0003 with a new filename." ;; esac
  [ "$O_SENS" = "secret_ref" ] && case "$O_PAYLOAD" in secretref:*) ;; *) refuse "SECRET-INLINE sensitivity secret_ref requires a payload_ref of the form secretref:<name>. A secret is held by reference or it is not held here at all." ;; esac

  # TRUTH STATE IS NOT EVIDENCE, enforced at the door as well as in validate.
  if in_list "$O_TRUTH" "$EVIDENCE_BACKED" && [ "$O_EVID" = "-" ]; then
    refuse "TRUTH-STATE-UNBACKED truth_state \"$O_TRUTH\" is a claim about the world and this write cites nothing in it. Record it as \`inferred\` or \`reported\` — a model-generated inference is allowed into memory, and it is not allowed in as an observation."
  fi
  [ "$O_TRUTH" = "decided" ] && [ "$O_AUTH" = "-" ] && refuse "AUTHORITY-MISSING truth_state \"decided\" requires --authority. A decision nobody authorised is an opinion."
  for f in $(evid_list "$O_EVID"); do
    local why; why="$(art_resolves "$f")" || refuse "EVIDENCE-UNRESOLVED $why"
  done

  # OPTIMISTIC CONCURRENCY. A stale expected_version is a LOUD refusal by
  # default, or — with --on-conflict record — a typed conflict object plus its
  # event. What it is never is a silent last-write-wins.
  local cur; cur="$(obj_current_version "$O_ID")"
  if [ "$O_EXPECTED" != "$cur" ]; then
    if [ "$O_CONFLICT" = "record" ]; then
      local cid crow chash ev
      cid="$(next_id "$F_OB" "OBJ-")"
      crow="$cid${TAB}finding${TAB}$SCHEMA_VERSION${TAB}$O_NS${TAB}1${TAB}open${TAB}$(now)${TAB}$(now)${TAB}$O_ACTOR${TAB}$O_ACTOR${TAB}$O_ACTOR${TAB}${O_AUTH}${TAB}-${TAB}$O_ID@$O_EXPECTED;$O_ID@$cur${TAB}-${TAB}-${TAB}internal${TAB}project${TAB}reported${TAB}HASH${TAB}conflict:expected_version=$O_EXPECTED,current_version=$cur,object=$O_ID"
      chash="$(sha "$(obj_hash_input "$crow")")"
      crow="$(printf '%s' "$crow" | awk -F'\t' -v h="$chash" 'BEGIN{OFS="\t"}{$20=h; print}')"
      append_row "$F_OB" "$crow"
      ev="$(emit_event FindingRecorded "$O_ACTOR" "$O_SURFACE" "$O_NS" "$cid" 1 - - "$O_AUTH" - "conflict")"
      printf 'RECEIPT: memory-kernel record-object — RECONCILIATION RECORDED, NOTHING OVERWRITTEN\n  conflict: %s expected version %s, store holds %s\n  finding: %s@1 (type=finding, truth_state=reported)\n  event: %s\n  store: memory_objects.tsv, memory_events.tsv (append)\n' \
        "$O_ID" "$O_EXPECTED" "$cur" "$cid" "$ev"
      exit 0
    fi
    refuse "VERSION-STALE $O_ID is at version $cur and this write expected $O_EXPECTED. The write is REFUSED and nothing was stored: a last-write-wins here would destroy the version the caller never read. Re-read the object, or pass --on-conflict record to store the conflict as a finding."
  fi

  local nv row hash created ev etype
  nv=$((cur+1))
  created="$(now)"
  if [ "$cur" != "0" ]; then created="$(fld "$(obj_row_at "$O_ID" 1)" 7)"; etype="ObjectVersioned"; else etype="ObjectCreated"; fi
  row="$O_ID${TAB}$O_TYPE${TAB}$SCHEMA_VERSION${TAB}$O_NS${TAB}$nv${TAB}$O_STATUS${TAB}$created${TAB}$(now)${TAB}$O_ACTOR${TAB}$O_ACTOR${TAB}$O_ACTOR${TAB}$O_AUTH${TAB}$O_EVID${TAB}$O_SRC${TAB}$O_SUPERSEDES${TAB}$O_CONF${TAB}$O_SENS${TAB}$O_RET${TAB}$O_TRUTH${TAB}PLACEHOLDER${TAB}$O_PAYLOAD"
  hash="$(sha "$(obj_hash_input "$row")")"
  row="$(printf '%s' "$row" | awk -F'\t' -v h="$hash" 'BEGIN{OFS="\t"}{$20=h; print}')"
  append_row "$F_OB" "$row"
  ev="$(emit_event "$etype" "$O_ACTOR" "$O_SURFACE" "$O_NS" "$O_ID" "$nv" "$O_CAUSE" "$O_CORR" "$O_AUTH" "$O_EVID" "$O_PAYLOAD")"
  printf 'RECEIPT: memory-kernel record-object\n  actor: %s  surface: %s  namespace: %s\n  object: %s@%s  type=%s  status=%s  truth_state=%s\n  authority: %s  evidence: %s\n  expected_version: %s -> written_version: %s\n  content_hash: %s\n  event: %s %s\n  store: memory_objects.tsv, memory_events.tsv (append)\n' \
    "$O_ACTOR" "$O_SURFACE" "$O_NS" "$O_ID" "$nv" "$O_TYPE" "$O_STATUS" "$O_TRUTH" "$O_AUTH" "$O_EVID" "$O_EXPECTED" "$nv" "$hash" "$etype" "$ev"
}

do_record_event(){
  req --type "$O_TYPE"; req --actor "$O_ACTOR"; req --surface "$O_SURFACE"; req --namespace "$O_NS"
  authorise "$O_ACTOR" "$O_SURFACE" "$O_NS"
  in_list "$O_TYPE" "$EVENT_TYPES" || refuse "KERNEL-SCHEMA event_type \"$O_TYPE\" is not one of: $EVENT_TYPES"
  [ -n "$O_OBJECT" ] || O_OBJECT="-"; [ -n "$O_OBJVER" ] || O_OBJVER="-"
  if [ "$O_OBJECT" != "-" ]; then
    obj_row_at "$O_OBJECT" "$O_OBJVER" >/dev/null || refuse "EVENT-DANGLING $O_OBJECT@$O_OBJVER is not in the object store. An event about a version that does not exist records nothing."
  fi
  [ "$O_CAUSE" = "-" ] || row_by_id "$F_EV" "$O_CAUSE" >/dev/null || refuse "CAUSAL-CHAIN-BROKEN causation_id $O_CAUSE is not an event."
  no_secret payload_ref "$O_PAYLOAD"
  local ev; ev="$(emit_event "$O_TYPE" "$O_ACTOR" "$O_SURFACE" "$O_NS" "$O_OBJECT" "$O_OBJVER" "$O_CAUSE" "$O_CORR" "$O_AUTH" "$O_EVID" "$O_PAYLOAD")"
  printf 'RECEIPT: memory-kernel record-event\n  actor: %s  surface: %s  namespace: %s\n  event: %s %s  object=%s@%s  causation=%s\n  store: memory_events.tsv (append)\n' \
    "$O_ACTOR" "$O_SURFACE" "$O_NS" "$O_TYPE" "$ev" "$O_OBJECT" "$O_OBJVER" "$O_CAUSE"
}

do_record_relationship(){
  req --id "$O_ID"; req --source "$O_SOURCE"; req --type "$O_TYPE"; req --target "$O_TARGET"
  req --namespace "$O_NS"; req --actor "$O_ACTOR"
  in_list "$O_TYPE" "$REL_TYPES" || refuse "KERNEL-SCHEMA relationship_type \"$O_TYPE\" is not one of: $REL_TYPES"
  row_by_id "$F_RL" "$O_ID" >/dev/null && refuse "KERNEL-APPEND-ONLY relationship $O_ID already exists."
  obj_current_row "$O_SOURCE" >/dev/null || refuse "RELATIONSHIP-DANGLING source $O_SOURCE is not an object."
  obj_current_row "$O_TARGET" >/dev/null || refuse "RELATIONSHIP-DANGLING target $O_TARGET is not an object."
  local sns tns; sns="$(fld "$(obj_current_row "$O_SOURCE")" 4)"; tns="$(fld "$(obj_current_row "$O_TARGET")" 4)"
  ns_in_closure "$tns" "$O_NS" && ns_in_closure "$sns" "$O_NS" \
    || refuse "NAMESPACE-REFUSED a relationship may not span outside the closure of $O_NS (source is in $sns, target in $tns). An edge across a namespace boundary is a read across it by another name."
  append_row "$F_RL" "$O_ID${TAB}$O_SOURCE${TAB}$O_TYPE${TAB}$O_TARGET${TAB}$O_NS${TAB}${O_FROM:-$(now)}${TAB}$O_UNTIL${TAB}$O_ACTOR${TAB}$O_EVID"
  printf 'RECEIPT: memory-kernel record-relationship\n  relationship: %s  %s -%s-> %s  namespace=%s\n  store: memory_relationships.tsv (append)\n' \
    "$O_ID" "$O_SOURCE" "$O_TYPE" "$O_TARGET" "$O_NS"
}

do_create_handoff(){
  req --id "$O_ID"; req --from-actor "$O_ACTOR"; req --from-surface "$O_SURFACE"; req --to-role "$O_TOROLE"
  req --namespace "$O_NS"; req --objective "$O_OBJECTIVE"; req --next-action "$O_NEXT"; req --acceptance "$O_ACCEPT"
  authorise "$O_ACTOR" "$O_SURFACE" "$O_NS"
  row_by_id "$F_HO" "$O_ID" >/dev/null && refuse "KERNEL-APPEND-ONLY handoff $O_ID already exists."
  local f i
  for i in "$O_COMPLETED" "$O_CURRENT" "$O_OPENQ"; do
    for f in $(evid_list "$i"); do
      obj_current_row "$f" >/dev/null || refuse "HANDOFF-UNRESOLVED $f is not an object in this store. A handoff that names an object the receiver cannot resolve is a transcript with extra steps."
      ns_in_closure "$(fld "$(obj_current_row "$f")" 4)" "$O_NS" || refuse "NAMESPACE-REFUSED $f lives outside the closure of $O_NS and may not be handed across."
    done
  done
  for f in $(evid_list "$O_EVID"); do local why; why="$(art_resolves "$f")" || refuse "EVIDENCE-UNRESOLVED $why"; done
  no_secret objective "$O_OBJECTIVE"; no_sep objective "$O_OBJECTIVE"
  no_secret required_next_action "$O_NEXT"; no_sep required_next_action "$O_NEXT"
  no_sep acceptance_criteria "$O_ACCEPT"
  append_row "$F_HO" "$O_ID${TAB}$O_ACTOR${TAB}$O_SURFACE${TAB}$O_TOROLE${TAB}$O_NS${TAB}$O_OBJECTIVE${TAB}$O_COMPLETED${TAB}$O_CURRENT${TAB}$O_OPENQ${TAB}$O_EVID${TAB}$O_AUTHS${TAB}$O_NEXT${TAB}$O_ACCEPT${TAB}$(now)${TAB}created${TAB}-${TAB}-"
  local ev; ev="$(emit_event HandoffCreated "$O_ACTOR" "$O_SURFACE" "$O_NS" - - "$O_CAUSE" "$O_CORR" "$O_AUTHS" "$O_EVID" "$O_ID")"
  printf 'RECEIPT: memory-kernel create-handoff\n  handoff: %s  from=%s@%s  to_role=%s  namespace=%s\n  completed: %s\n  current_state: %s\n  open_questions: %s\n  evidence: %s  authority: %s\n  event: HandoffCreated %s\n  store: memory_handoffs.tsv, memory_events.tsv (append)\n' \
    "$O_ID" "$O_ACTOR" "$O_SURFACE" "$O_TOROLE" "$O_NS" "$O_COMPLETED" "$O_CURRENT" "$O_OPENQ" "$O_EVID" "$O_AUTHS" "$ev"
}

do_acknowledge_handoff(){
  req --handoff "$O_HANDOFF"; req --actor "$O_ACTOR"; req --surface "$O_SURFACE"
  local hr ns; hr="$(row_by_id "$F_HO" "$O_HANDOFF")" || refuse "HANDOFF-UNKNOWN $O_HANDOFF is not a handoff."
  ns="$(fld "$hr" 5)"
  authorise "$O_ACTOR" "$O_SURFACE" "$ns"
  local ar; ar="$(actor_row "$O_ACTOR")"
  [ "$(fld "$ar" 3)" = "$(fld "$hr" 4)" ] || refuse "HANDOFF-ROLE $O_HANDOFF is addressed to role $(fld "$hr" 4) and $O_ACTOR carries role $(fld "$ar" 3). A handoff is accepted by the role it names or by nobody."
  # THE ACCEPTANCE IS AN EVENT, NOT AN EDIT. The handoff row is never rewritten:
  # the store is append-only and the ledger is what carries state changes, so a
  # correction can only ever be a LATER event.
  local ev; ev="$(emit_event HandoffAccepted "$O_ACTOR" "$O_SURFACE" "$ns" - - - - "$(fld "$hr" 11)" "$(fld "$hr" 10)" "$O_HANDOFF")"
  printf 'RECEIPT: memory-kernel acknowledge-handoff\n  handoff: %s accepted by %s (%s) on surface %s\n  status: the handoff ROW is unchanged — acceptance is recorded as event %s, because this store is append-only and a status field rewritten in place would erase the fact that it was ever open\n  store: memory_events.tsv (append)\n' \
    "$O_HANDOFF" "$O_ACTOR" "$(fld "$ar" 3)" "$O_SURFACE" "$ev"
}

# ======================================================= the context compiler =
# DETERMINISTIC, AND NOT LEARNED. The retrieval order is fixed in this function
# and nothing fits it: mandatory ID-based inclusion, then one hop of relationship
# expansion, then evidence and authority relevance, then recency. There is no
# embedding, no similarity, no score and no model anywhere in this path — a
# learned ranker would be a policy holding authority over what a second surface
# is allowed to see, and v0 grants it none.
do_compile_context(){
  req --id "$O_ID"; req --namespace "$O_NS"; req --actor "$O_ACTOR"; req --surface "$O_SURFACE"
  req --objective "$O_OBJECTIVE"; req --budget "$O_BUDGET"
  authorise "$O_ACTOR" "$O_SURFACE" "$O_NS"
  row_by_id "$F_CP" "$O_ID" >/dev/null && refuse "KERNEL-APPEND-ONLY context package $O_ID already exists. A package is immutable; a new compilation gets a new id."
  printf '%s' "$O_BUDGET" | grep -qE '^[0-9]+$' || refuse "KERNEL-SCHEMA --budget \"$O_BUDGET\" is not a number."
  no_sep objective "$O_OBJECTIVE"; no_secret objective "$O_OBJECTIVE"

  local scope id r t st ns
  scope="$(ns_closure "$O_NS" | tr '\n' ' ')"

  # TIER 0 — everything outside the closure is not considered at all, and the
  # package records HOW MANY were refused rather than naming them. Naming them
  # would leak the existence of a sibling project's objects into a package that
  # crosses surfaces, which is the leak the boundary exists to prevent.
  local in_scope="" out_of_scope=0
  for id in $(rows "$F_OB" "OBJ-" | cut -f1 | sort -u); do
    r="$(obj_current_row "$id")" || continue
    ns="$(fld "$r" 4)"
    if in_list "$ns" "$scope"; then in_scope="$in_scope $id"; else out_of_scope=$((out_of_scope+1)); fi
  done

  # TIER 1 — MANDATORY. Named ids, every live control, every sealed decision,
  # every active goal. Mandatory means mandatory: if the budget cannot hold them
  # the compilation is REFUSED rather than trimmed, because a package that
  # silently dropped a control is a package that reports a system with no rules.
  local mandatory=""
  for id in $(evid_list "$O_MUST"); do
    in_list "$id" "$in_scope" || refuse "NAMESPACE-REFUSED --must-include names $id, which is not inside the closure of $O_NS."
    in_list "$id" "$mandatory" || mandatory="$mandatory $id"
  done
  for id in $in_scope; do
    r="$(obj_current_row "$id")"; t="$(fld "$r" 2)"; st="$(fld "$r" 6)"
    case "$t:$st" in
      control:active|goal:active|decision:sealed) in_list "$id" "$mandatory" || mandatory="$mandatory $id" ;;
    esac
  done
  # ...and THE MOST RECENT HANDOFF in this closure, by every object it names.
  # A package compiled for a receiving surface that omitted the handoff it is
  # answering would be a package about the wrong conversation. `tail -1` is the
  # most recent because this store is append-only and therefore in write order.
  local lasth i
  lasth="$(rows "$F_HO" "HOF-" | awk -F'\t' -v s=" $scope " 'index(s, " " $5 " ")' | tail -1)"
  if [ -n "$lasth" ]; then
    for i in 7 8 9; do
      for id in $(evid_list "$(fld "$lasth" $i)"); do
        in_list "$id" "$in_scope" || continue
        in_list "$id" "$mandatory" || mandatory="$mandatory $id"
      done
    done
  fi

  # TIER 2 — one hop of DIRECT relationship expansion from the mandatory seeds,
  # in relationship-id order, and only while the edge is valid.
  local expanded="" rel today; today="$(now)"
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    local s tg vu; s="$(fld "$r" 2)"; tg="$(fld "$r" 4)"; vu="$(fld "$r" 7)"
    [ "$vu" = "-" ] || [ "$vu" \> "$today" ] || continue
    if in_list "$s" "$mandatory"; then in_list "$tg" "$mandatory$expanded" || expanded="$expanded $tg"; fi
    if in_list "$tg" "$mandatory"; then in_list "$s" "$mandatory$expanded" || expanded="$expanded $s"; fi
  done < <(rows "$F_RL" "REL-" | sort)

  # TIER 3 — evidence and authority relevance: an object that is itself evidence
  # or a receipt cited by something already included.
  local relevant=""
  for id in $in_scope; do
    in_list "$id" "$mandatory$expanded" && continue
    r="$(obj_current_row "$id")"; t="$(fld "$r" 2)"
    case "$t" in evidence|receipt) relevant="$relevant $id" ;; esac
  done

  # TIER 4 — recency, by updated_at then id, so the order is total and stable.
  local recent=""
  recent="$(for id in $in_scope; do
      in_list "$id" "$mandatory$expanded$relevant" && continue
      r="$(obj_current_row "$id")"; printf '%s\t%s\n' "$(fld "$r" 8)" "$id"
    done | sort -r | cut -f2 | tr '\n' ' ')"

  # VALIDITY. A superseded or retired object is omitted with the id that replaced
  # it, never silently dropped.
  local ordered="" included="" omitted="" reasons="" rank=0
  for id in $mandatory $expanded $relevant $recent; do in_list "$id" "$ordered" || ordered="$ordered $id"; done
  local nmand=0; for id in $mandatory; do nmand=$((nmand+1)); done
  [ "$O_BUDGET" -ge "$nmand" ] || refuse "BUDGET-BELOW-MANDATORY the budget is $O_BUDGET and mandatory inclusion alone needs $nmand. Trimming a control or a sealed decision to fit would hand the receiving surface a description of a system with no rules in it."

  local nincl=0
  for id in $ordered; do
    r="$(obj_current_row "$id")"; st="$(fld "$r" 6)"
    if [ "$st" = "superseded" ] || [ "$st" = "retired" ]; then
      omitted="$omitted;$id"; reasons="$reasons;$id=not-current(status=$st,superseded_by=$(fld "$r" 15))"; continue
    fi
    rank=$((rank+1))
    if [ "$nincl" -lt "$O_BUDGET" ]; then included="$included;$id"; nincl=$((nincl+1))
    else omitted="$omitted;$id"; reasons="$reasons;$id=budget-exceeded(rank=$rank,budget=$O_BUDGET)"; fi
  done
  included="${included#;}"; omitted="${omitted#;}"; reasons="${reasons#;}"
  [ -n "$omitted" ] || { omitted="-"; reasons="-"; }

  # The binding: ids AND versions, positionally paired. This pair IS the identity
  # of the package, and the whole staleness rule reads it.
  local vers="" rels="" evs="" auth="" contras=""
  for id in $(printf '%s' "$included" | tr ';' ' '); do vers="$vers;$(obj_current_version "$id")"; done
  vers="${vers#;}"
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    local s tg; s="$(fld "$r" 2)"; tg="$(fld "$r" 4)"
    case ";$included;" in *";$s;"*) ;; *) continue ;; esac
    case ";$included;" in *";$tg;"*) ;; *) continue ;; esac
    rels="$rels;$(fld "$r" 1)"
    [ "$(fld "$r" 3)" = "contradicts" ] && contras="$contras;$(fld "$r" 1):$s-contradicts-$tg"
  done < <(rows "$F_RL" "REL-" | sort)
  rels="${rels#;}"; [ -n "$rels" ] || rels="-"
  contras="${contras#;}"; [ -n "$contras" ] || contras="none-detected"
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    local o; o="$(fld "$r" 8)"; [ "$o" = "-" ] && continue
    case ";$included;" in *";$o;"*) evs="$evs;$(fld "$r" 1)" ;; esac
  done < <(rows "$F_EV" "EVT-")
  evs="${evs#;}"; [ -n "$evs" ] || evs="-"
  for id in $(printf '%s' "$included" | tr ';' ' '); do
    local a; a="$(fld "$(obj_current_row "$id")" 12)"; [ "$a" = "-" ] && continue
    case ";$auth;" in *";$a;"*) ;; *) auth="$auth;$a" ;; esac
  done
  auth="${auth#;}"; [ -n "$auth" ] || auth="none-cited"
  auth="scope=$O_NS;closure=$(printf '%s' "$scope" | tr ' ' ',' | sed 's/,$//');out_of_closure_refused=$out_of_scope;effective=$auth"

  local row hash ev
  row="$O_ID${TAB}$(now)${TAB}$O_NS${TAB}$O_ACTOR${TAB}$O_SURFACE${TAB}$O_OBJECTIVE${TAB}$included${TAB}$vers${TAB}$rels${TAB}$evs${TAB}$omitted${TAB}$reasons${TAB}$auth${TAB}$contras${TAB}$O_BUDGET"
  hash="$(sha "$(cp_hash_input "$row")")"
  append_row "$F_CP" "$row${TAB}$hash"
  # THE PACKAGE HASH GOES INTO THE LEDGER, not only into the package's own row. A
  # row that signs itself with an unkeyed digest can be edited and re-signed by
  # anyone who can write the file; the ledger is digest-chained, so moving this
  # value means re-chaining every event after it. `<package-id>@<hash>` keeps the
  # id at the front so the payload is still matchable by package.
  ev="$(emit_event ContextCompiled "$O_ACTOR" "$O_SURFACE" "$O_NS" - - - - "-" - "$O_ID@$hash")"
  printf 'RECEIPT: memory-kernel compile-context\n  package: %s  namespace=%s  actor=%s  surface=%s  budget=%s\n  objective: %s\n  included: %s\n  versions: %s\n  omitted: %s\n  omission_reasons: %s\n  authority_state: %s\n  contradictions: %s\n  content_hash: %s\n  event: ContextCompiled %s\n  store: memory_context_packages.tsv, memory_events.tsv (append)\n' \
    "$O_ID" "$O_NS" "$O_ACTOR" "$O_SURFACE" "$O_BUDGET" "$O_OBJECTIVE" "$included" "$vers" "$omitted" "$reasons" "$auth" "$contras" "$hash" "$ev"
}

# ================================================ the staleness determination =
# THE INVARIANT THIS WHOLE MODULE IS FOR. A package binds (object, version)
# pairs. `pkg_state` compares every pair against the CURRENT version and returns
# CURRENT or STALE with the drifted pairs named. `--as-current` turns STALE into
# a refusal, because a stale package REPRESENTED AS CURRENT is a description of a
# system that no longer exists, handed to a surface that has no way to tell.
pkg_state(){ # <package-row> -> prints "CURRENT" or "STALE <drift...>"
  local r="$1" ids vers i n id v cur drift=""
  ids="$(fld "$r" 7)"; vers="$(fld "$r" 8)"
  n=1
  for id in $(printf '%s' "$ids" | tr ';' ' '); do
    v="$(printf '%s' "$vers" | cut -d';' -f"$n")"; n=$((n+1))
    cur="$(obj_current_version "$id")"
    [ "$cur" = "0" ] && { drift="$drift $id@$v->ABSENT"; continue; }
    [ "$cur" = "$v" ] || drift="$drift $id@$v->now@$cur"
  done
  if [ -n "$drift" ]; then printf 'STALE%s' "$drift"; else printf 'CURRENT'; fi
}

do_read_context_package(){
  req --package "$O_PACKAGE"
  local r state
  r="$(row_by_id "$F_CP" "$O_PACKAGE")" || refuse "PACKAGE-UNKNOWN $O_PACKAGE is not a context package."
  [ "$(sha "$(cp_hash_input "$r")")" = "$(fld "$r" 16)" ] \
    || refuse "PACKAGE-IDENTITY $O_PACKAGE does not hash to its own recorded content_hash. The row was edited without recomputing the hash. THIS CHECK DETECTS A CARELESS EDIT AND NOT A WRITER: the hash is unkeyed, so anyone who can write this store can edit a field and re-sign the row, and PACKAGE-UNANCHORED is the check that catches that."
  local why; if why="$(pkg_anchor_fault "$r")"; then
    refuse "PACKAGE-UNANCHORED $why. Nothing it says about its sources can be trusted."
  fi
  state="$(pkg_state "$r")"
  case "$state" in
    STALE*)
      if [ "$O_ASCURRENT" = "1" ]; then
        refuse "PACKAGE-STALE $O_PACKAGE binds source versions that are no longer current and was read with --as-current:${state#STALE}. It PARSES, every id in it RESOLVES, and it describes a state the project has left — resolvability is not identity. Compile a new package; this one may be read as history and not as the present."
      fi ;;
  esac
  printf 'context_package: %s\n' "$O_PACKAGE"
  printf 'state: %s\n' "$state"
  printf 'compiled_at: %s\nnamespace: %s\nactor: %s\nsurface: %s\n' "$(fld "$r" 2)" "$(fld "$r" 3)" "$(fld "$r" 4)" "$(fld "$r" 5)"
  printf 'objective: %s\n' "$(fld "$r" 6)"
  printf 'source_object_ids: %s\nsource_object_versions: %s\n' "$(fld "$r" 7)" "$(fld "$r" 8)"
  printf 'included_relationship_ids: %s\nincluded_event_ids: %s\n' "$(fld "$r" 9)" "$(fld "$r" 10)"
  printf 'omitted_object_ids: %s\nomission_reasons: %s\n' "$(fld "$r" 11)" "$(fld "$r" 12)"
  printf 'authority_state: %s\ncontradictions: %s\n' "$(fld "$r" 13)" "$(fld "$r" 14)"
  printf 'token_or_size_budget: %s\ncontent_hash: %s\n' "$(fld "$r" 15)" "$(fld "$r" 16)"
}

# ================================================== projections and exports ===
# A PROJECTION IS GENERATED, NEVER EDITED. Every projection ends in a canonical
# footer naming the object, its version, its namespace and its content hash, and
# `parse-projection` reads that footer back. `reconcile` regenerates every
# committed export and refuses any that differs. That is the whole mechanism by
# which the human-readable copy stays a copy.
CANON_MARK="<!-- gravito-canonical:"

project_object(){ # <object-id>
  local r id ver
  r="$(obj_current_row "$1")" || refuse "OBJECT-UNKNOWN $1 is not an object."
  id="$(fld "$r" 1)"; ver="$(fld "$r" 5)"
  printf '### %s@%s — %s (%s)\n\n' "$id" "$ver" "$(fld "$r" 2)" "$(fld "$r" 6)"
  printf -- '- **truth state:** `%s`\n' "$(fld "$r" 19)"
  printf -- '- **namespace:** `%s`\n' "$(fld "$r" 4)"
  printf -- '- **authority:** `%s`\n' "$(fld "$r" 12)"
  printf -- '- **evidence:** `%s`\n' "$(fld "$r" 13)"
  printf -- '- **supersedes:** `%s`\n' "$(fld "$r" 15)"
  printf -- '- **payload:** `%s`\n' "$(fld "$r" 21)"
  printf '\n%s object=%s version=%s namespace=%s hash=%s -->\n' "$CANON_MARK" "$id" "$ver" "$(fld "$r" 4)" "$(fld "$r" 20)"
}

# `project` IS A READ, and every read in this module identifies actor, surface and
# namespace. It renders the object's whole envelope INCLUDING ITS PAYLOAD, so a
# subcommand that took no actor would be a cross-namespace RETRIEVAL wearing a
# projection's clothes — the one thing v0 refuses by default, escaping through the
# only path that never asked who was calling.
do_project(){
  req --object "$O_OBJECT"; req --actor "$O_ACTOR"; req --surface "$O_SURFACE"
  local pr; pr="$(obj_current_row "$O_OBJECT")" || refuse "OBJECT-UNKNOWN $O_OBJECT is not an object."
  authorise "$O_ACTOR" "$O_SURFACE" "$(fld "$pr" 4)"
  if [ -n "$O_OUT" ]; then project_object "$O_OBJECT" > "$O_OUT"; printf 'RECEIPT: memory-kernel project\n  object: %s -> %s (generated projection; edit the store, never this file)\n  actor: %s  surface: %s  namespace: %s\n' "$O_OBJECT" "$O_OUT" "$O_ACTOR" "$O_SURFACE" "$(fld "$pr" 4)"
  else project_object "$O_OBJECT"; fi
}

do_parse_projection(){
  req --file "$O_FILE"
  [ -f "$O_FILE" ] || refuse "PROJECTION-MISSING $O_FILE does not exist."
  local line id ver ns h r
  line="$(grep -m1 -F "$CANON_MARK" "$O_FILE" || true)"
  [ -n "$line" ] || refuse "PROJECTION-UNBOUND $O_FILE carries no canonical footer. A projection that does not name the object and version it was generated from cannot be checked against anything, and an uncheckable copy is a second truth."
  id="$(printf '%s' "$line"  | sed -n 's/.*object=\([^ ]*\).*/\1/p')"
  ver="$(printf '%s' "$line" | sed -n 's/.*version=\([^ ]*\).*/\1/p')"
  ns="$(printf '%s' "$line"  | sed -n 's/.*namespace=\([^ ]*\).*/\1/p')"
  h="$(printf '%s' "$line"   | sed -n 's/.* hash=\([^ ]*\).*/\1/p')"
  r="$(obj_row_at "$id" "$ver")" || refuse "PROJECTION-DIVERGED $O_FILE claims $id@$ver, which the canonical store does not carry at that version."
  [ "$(fld "$r" 4)" = "$ns" ] || refuse "PROJECTION-DIVERGED $O_FILE claims namespace $ns; the store says $(fld "$r" 4)."
  [ "$(fld "$r" 20)" = "$h" ] || refuse "PROJECTION-DIVERGED $O_FILE claims content_hash $h; the store says $(fld "$r" 20). The copy has been edited, or the canonical object moved and the copy did not."
  printf 'object_id: %s\nversion: %s\nnamespace: %s\ncontent_hash: %s\nround_trip: MATCH\n' "$id" "$ver" "$ns" "$h"
}

# THE CHATGPT HANDOFF EXPORT. Rendered from the handoff and its context package
# and from NOTHING ELSE — there is no transcript in this path, and a reader who
# has never seen the Claude session can answer every question it claims to
# answer. Truth states are printed per object rather than flattened into prose,
# because "the suite is green" and "a model believes the suite is green" are
# different claims and only one of them is checkable.
# THE HANDOFF'S STATE LIVES IN THE LEDGER, NOT IN ITS ROW. `acknowledge-handoff`
# deliberately does not rewrite the row — the store is append-only and a status
# rewritten in place would erase the fact that the handoff was ever open — so the
# row reads `created` forever and reading it back would tell a second consumer
# that a CLAIMED handoff is unclaimed, contradicting this module's own ledger. The
# last HandoffAccepted/HandoffRefused event naming the handoff is the state.
# (`HandoffRefused` is not yet in EVENT_TYPES and so cannot be written in v0; the
# branch is here because the derivation is over the vocabulary, not over what one
# release happens to emit, and widening an enum is a governance act.)
ho_status(){ # <handoff-id> -> one of $HANDOFF_STATUS
  local last
  last="$(rows "$F_EV" "EVT-" | awk -F'\t' -v h="$1" \
    '($2=="HandoffAccepted" || $2=="HandoffRefused") && $14==h {print $2}' | tail -1)"
  case "$last" in
    HandoffAccepted) printf 'accepted' ;;
    HandoffRefused)  printf 'refused' ;;
    *) fld "$(row_by_id "$F_HO" "$1")" 15 ;;
  esac
}

# THE PACKAGE'S BINDING IS THE EXPORT'S BINDING. A package binds (object,
# version) pairs; every section of this document renders at those versions and at
# no others. Rendering the body at the CURRENT version while the binding table
# names the BOUND one produces a document whose two halves describe different
# states while every id in it resolves — `resolvability is not identity`,
# reproduced inside the artifact built to refuse it.
pkg_bound_version(){ # <package-row> <object-id> -> the bound version, or non-zero
  local ids vers n=1 id
  ids="$(fld "$1" 7)"; vers="$(fld "$1" 8)"
  for id in $(printf '%s' "$ids" | tr ';' ' '); do
    [ "$id" = "$2" ] && { printf '%s' "$(printf '%s' "$vers" | cut -d';' -f"$n")"; return 0; }
    n=$((n+1))
  done
  return 1
}

export_handoff(){ # <handoff-id> <package-id>
  local h p state id ver n i r
  h="$(row_by_id "$F_HO" "$1")" || refuse "HANDOFF-UNKNOWN $1 is not a handoff."
  p="$(row_by_id "$F_CP" "$2")" || refuse "PACKAGE-UNKNOWN $2 is not a context package."
  [ "$(fld "$h" 5)" = "$(fld "$p" 3)" ] || refuse "NAMESPACE-REFUSED handoff $1 is in namespace $(fld "$h" 5) and package $2 is in $(fld "$p" 3). An export that mixed two namespaces would be the cross-namespace read this kernel refuses, performed one layer up."
  state="$(pkg_state "$p")"

  printf '# Handoff `%s` — %s -> `%s`\n\n' "$1" "$(fld "$h" 2)" "$(fld "$h" 4)"
  printf '> **This document is consumable without the originating transcript.** Every\n'
  printf '> claim below names the object and version it came from, and every claim is\n'
  printf '> labelled with how it is known. Nothing here is a paraphrase of a chat log.\n\n'
  printf -- '- **context package:** `%s` — **state: %s**\n' "$2" "${state%% *}"
  printf -- '- **namespace:** `%s` (closure-scoped; nothing outside it is included)\n' "$(fld "$h" 5)"
  printf -- '- **from surface:** `%s`\n' "$(fld "$h" 3)"
  printf -- '- **compiled at:** `%s`  **handoff created:** `%s`  **status:** `%s`\n\n' "$(fld "$p" 2)" "$(fld "$h" 14)" "$(ho_status "$1")"

  printf '## 1. Objective\n\n%s\n\n' "$(fld "$h" 6)"

  printf '## 2. What was completed\n\n'
  export_objects "$(fld "$h" 7)" "$p" || printf 'None recorded.\n'
  printf '\n## 3. Current state\n\n'
  export_objects "$(fld "$h" 8)" "$p" || printf 'None recorded.\n'
  printf '\n## 4. What remains open — the unresolved decisions\n\n'
  export_objects "$(fld "$h" 9)" "$p" || printf 'None recorded.\n'

  printf '\n## 5. Evidence\n\n'
  printf '| artifact | kind | resolves to | anchor |\n|---|---|---|---|\n'
  for i in $(evid_list "$(fld "$h" 10)"); do
    r="$(row_by_id "$F_AR" "$i")" || continue
    printf '| `%s` | %s | %s | `%s` |\n' "$i" "$(fld "$r" 3)" "$(art_resolves "$i")" "$(fld "$r" 5)"
  done

  printf '\n## 6. Authority in force\n\n'
  printf -- '- **declared on the handoff:** `%s`\n' "$(fld "$h" 11)"
  printf -- '- **derived from the package:** `%s`\n' "$(fld "$p" 13)"
  printf -- '- **contradictions detected:** `%s`\n' "$(fld "$p" 14)"

  printf '\n## 7. The next decision required\n\n%s\n\n' "$(fld "$h" 12)"
  printf '**Acceptance criteria:** %s\n' "$(fld "$h" 13)"

  printf '\n## 8. What was deliberately NOT included\n\n'
  if [ "$(fld "$p" 11)" = "-" ]; then
    printf 'Nothing was omitted from the package AT COMPILE TIME. That is a statement\n'
    printf 'about the objects the compiler considered when it ran, and it is NOT a claim\n'
    printf 'that nothing has been recorded since: the freshness check compares the BOUND\n'
    printf 'versions and an object created in this namespace after the compile is outside\n'
    printf 'what it can see.\n'
  else
    printf '| omitted object | reason |\n|---|---|\n'
    for i in $(evid_list "$(fld "$p" 12)"); do
      printf '| `%s` | %s |\n' "${i%%=*}" "${i#*=}"
    done
  fi

  printf '\n## 9. The binding — read this before acting\n\n'
  printf 'This export is bound to exact source versions. If any of them has advanced,\n'
  printf 'this document is HISTORY and not the present, and `read-context-package\n'
  printf -- '--as-current` will refuse it rather than let it be mistaken for current state.\n\n'
  printf '| source object | version | truth state | type |\n|---|---|---|---|\n'
  n=1
  for id in $(printf '%s' "$(fld "$p" 7)" | tr ';' ' '); do
    ver="$(printf '%s' "$(fld "$p" 8)" | cut -d';' -f"$n")"; n=$((n+1))
    r="$(obj_row_at "$id" "$ver")" || continue
    printf '| `%s` | %s | `%s` | %s |\n' "$id" "$ver" "$(fld "$r" 19)" "$(fld "$r" 2)"
  done
  printf '\n**Truth-state vocabulary:** `observed` (measured in this tree) · `reported`\n'
  printf '(stated by a source) · `inferred` (a model concluded it; NOT an observation) ·\n'
  printf '`decided` (an authority chose it) · `verified` (independently re-measured) ·\n'
  printf '`refuted` (measurement contradicted the claim) · `unknown`.\n'
  printf '\n%s handoff=%s package=%s namespace=%s hash=%s -->\n' "$CANON_MARK" "$1" "$2" "$(fld "$h" 5)" "$(fld "$p" 16)"
}

export_objects(){ # <;-separated object ids> <context-package-row> -> a table at the
                  # package's BOUND versions, or non-zero when the list is empty
  local i r v any=0
  for i in $(evid_list "$1"); do
    # Tier-1 mandatory inclusion puts every object the handoff names into the
    # package, and BUDGET-BELOW-MANDATORY refuses a compilation that could not
    # hold them — so an unbound id here is a store that broke that guarantee, and
    # rendering it at whatever version happens to be current is exactly the defect
    # this function was changed to close.
    v="$(pkg_bound_version "$2" "$i")" || refuse "EXPORT-UNBOUND handoff object $i is not bound by context package $(fld "$2" 1) at any version. The export renders at the package's bound versions and has no version to render this at; rendering it at the current one would put an unbound claim in a document whose whole purpose is that every claim names its version."
    r="$(obj_row_at "$i" "$v")" || continue
    [ "$any" = "0" ] && printf '| object | v | type | status | truth state | authority | evidence |\n|---|---|---|---|---|---|---|\n'
    any=1
    printf '| `%s` | %s | %s | %s | `%s` | `%s` | `%s` |\n' \
      "$(fld "$r" 1)" "$(fld "$r" 5)" "$(fld "$r" 2)" "$(fld "$r" 6)" "$(fld "$r" 19)" "$(fld "$r" 12)" "$(fld "$r" 13)"
  done
  [ "$any" = "1" ] || return 1
  printf '\n'
  for i in $(evid_list "$1"); do
    v="$(pkg_bound_version "$2" "$i")" || continue
    r="$(obj_row_at "$i" "$v")" || continue
    printf -- '- `%s@%s` — %s\n' "$(fld "$r" 1)" "$(fld "$r" 5)" "$(fld "$r" 21)"
  done
}

do_export_handoff(){
  req --handoff "$O_HANDOFF"; req --package "$O_PACKAGE"
  if [ -n "$O_OUT" ]; then
    export_handoff "$O_HANDOFF" "$O_PACKAGE" > "$O_OUT"
    printf 'RECEIPT: memory-kernel export-handoff\n  handoff: %s  package: %s -> %s\n  note: this file is a PROJECTION. `reconcile` regenerates it and refuses any hand edit.\n' \
      "$O_HANDOFF" "$O_PACKAGE" "$O_OUT"
  else
    export_handoff "$O_HANDOFF" "$O_PACKAGE"
  fi
}

# RECONCILIATION — the proof that the projection is not a second writable truth.
# Every export under exports/ is regenerated from the stores and compared byte
# for byte. A hand edit to the readable copy does not become an opinion; it
# becomes an exit 2.
do_reconcile(){
  local f base n=0 bad=0 line hid pid
  [ -d "$EXPORTS" ] || refuse "PROJECTION-MISSING no exports directory at $EXPORTS. There is nothing to reconcile, and an absent projection set is not a clean one."
  # NOT `local`: the EXIT trap runs after this function has returned, and a
  # local would be unbound by the time the trap tried to clean it up.
  tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
  for f in "$EXPORTS"/*.md; do
    [ -f "$f" ] || continue
    base="$(basename "$f")"; n=$((n+1))
    line="$(grep -m1 -F "$CANON_MARK" "$f" || true)"
    [ -n "$line" ] || { printf '  PROJECTION-UNBOUND %s carries no canonical footer\n' "$base"; bad=$((bad+1)); continue; }
    hid="$(printf '%s' "$line" | sed -n 's/.*handoff=\([^ ]*\).*/\1/p')"
    pid="$(printf '%s' "$line" | sed -n 's/.*package=\([^ ]*\).*/\1/p')"
    if [ -n "$hid" ] && [ -n "$pid" ]; then
      export_handoff "$hid" "$pid" > "$tmp" 2>/dev/null
      if cmp -s "$tmp" "$f"; then printf '  RECONCILED %s (handoff=%s package=%s)\n' "$base" "$hid" "$pid"
      else printf '  PROJECTION-DIVERGED %s differs from what the canonical stores generate\n' "$base"; bad=$((bad+1)); fi
    else
      local oid; oid="$(printf '%s' "$line" | sed -n 's/.*object=\([^ ]*\).*/\1/p')"
      [ -n "$oid" ] || { printf '  PROJECTION-UNBOUND %s names neither an object nor a handoff\n' "$base"; bad=$((bad+1)); continue; }
      project_object "$oid" > "$tmp" 2>/dev/null
      if cmp -s "$tmp" "$f"; then printf '  RECONCILED %s (object=%s)\n' "$base" "$oid"
      else printf '  PROJECTION-DIVERGED %s differs from what the canonical stores generate\n' "$base"; bad=$((bad+1)); fi
    fi
  done
  printf 'memory-kernel: %s projection(s) checked, %s divergent\n' "$n" "$bad"
  [ "$n" -gt 0 ] || refuse "PROJECTION-MISSING exports/ holds no projections, so this reconciliation certified nothing."
  [ "$bad" = "0" ] || exit 2
}

case "$CMD" in
  validate)              validate ;;
  record-namespace)      do_record_namespace ;;
  record-actor)          do_record_actor ;;
  record-artifact)       do_record_artifact ;;
  record-object)         do_record_object ;;
  record-event)          do_record_event ;;
  record-relationship)   do_record_relationship ;;
  create-handoff)        do_create_handoff ;;
  acknowledge-handoff)   do_acknowledge_handoff ;;
  compile-context)       do_compile_context ;;
  read-context-package)  do_read_context_package ;;
  export-handoff)        do_export_handoff ;;
  project)               do_project ;;
  parse-projection)      do_parse_projection ;;
  reconcile)             do_reconcile ;;
esac
exit 0
