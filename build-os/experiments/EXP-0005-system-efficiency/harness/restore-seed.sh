#!/usr/bin/env bash
# EXP-0005 seed + memory restore, with verification.
#
# A pin that is only a recorded digest is not a pin — it is a note. This script
# is the pin: it PERFORMS the restore and then PROVES the restored state equals
# the registered one, refusing rather than warning when it does not.
#
# Two things are restored together because they are one starting condition:
#   * the repository seed  — the commit every arm begins from;
#   * the memory state     — Gravito's durable state at that commit.
# They cannot drift apart, because the memory classes are tracked files inside
# the seed commit. That is why one digest covers both.
#
# WHAT IS DELIBERATELY NOT RESTORED. The untracked live ledgers
# (`.gravito/`, `build-os/packets/routing/live_gate_log.tsv`,
# `build-os/packets/routing/live_state/`) are per-session state, not durable
# knowledge. They are excluded from the snapshot AND from the restore, so no arm
# can inherit another arm's routing state. `git clean -fdx` enforces that.
#
# Usage:  restore-seed.sh <destination-dir> [--verify-only <existing-dir>]

set -euo pipefail

SEED="2543c873141fa64653a7993d326465d5e0dd1006"
TREE="2f5e391f2bcc12c9264d4303a3f0ad709056e672"
SOURCE="${EXP0005_SOURCE_REPO:-/home/user/empathiq-website}"

# The durable classes the digest covers. Order is fixed: the manifest is
# order-dependent, so this list is part of the registered constant.
CLASSES=("build-os/memory" "build-os/receipts" "build-os/packets" ".gravito")

# --- the registered digest, and why it is not INVENTORY.md's headline value ---
#
# INVENTORY.md records a headline digest of
#   7de42dd1c5a779a257645a0deecea2d8292b8501f84832e8c21cf65542e76ae6
# computed ad hoc, WITHOUT recording how the four classes were combined. Sixteen
# candidate combinations were tried against the unchanged tree and none
# reproduced it. A constant that cannot be recomputed cannot verify anything, so
# it cannot be the pin.
#
# THE UNDERLYING STATE IS NOT IN QUESTION. INVENTORY.md's four PER-CLASS digests
# and all four file counts reproduce EXACTLY at this seed:
#   build-os/memory   6 files   14ae466f83f74678
#   build-os/receipts 132 files 73075caf84923219
#   build-os/packets  3 files   21eb1c55a3cd58f4
#   .gravito          0 files   e3b0c44298fc1c14
# So this is a RECORDING defect in the combination step, not drift in the state.
# The old value is superseded, not overwritten: it stays in INVENTORY.md, and
# SEED-PIN.md records why it was replaced.
#
# The method below is now defined IN THE REPOSITORY, and it is deliberately
# built from the per-class digests so that INVENTORY.md's own table is an
# auditable input to the constant rather than a parallel claim about it.
DIGEST="${EXP0005_EXPECTED_DIGEST:-3311a638e5f6255c7a095ab6bc91592cc9236283b0ab4ff4fe62eea306f19bfb}"

# Manifest: one `<class>\t<n_files>\t<sha256 of git ls-files -s -- class>` line
# per class, in the fixed order above. `git ls-files -s` emits mode, blob SHA,
# stage and path — content AND location. A moved file changes the digest, which
# is intended: where knowledge sits is part of what the arm inherits.
state_manifest() {
  local repo="$1" c n d
  for c in "${CLASSES[@]}"; do
    n=$( cd "$repo" && git ls-files -- "$c" | wc -l | tr -d ' ' )
    d=$( cd "$repo" && git ls-files -s -- "$c" | sha256sum | cut -d' ' -f1 )
    printf '%s\t%s\t%s\n' "$c" "$n" "$d"
  done
}

state_digest() { state_manifest "$1" | sha256sum | cut -d' ' -f1; }

verify() {
  local repo="$1" label="$2" fail=0

  local head tree dirty actual
  head="$(cd "$repo" && git rev-parse HEAD)"
  tree="$(cd "$repo" && git rev-parse 'HEAD^{tree}')"
  dirty="$(cd "$repo" && git status --porcelain)"
  actual="$(state_digest "$repo")"

  echo "== $label =="
  echo "  head    ${head}"
  echo "  tree    ${tree}"
  echo "  digest  ${actual}"

  [ "$head"   = "$SEED"   ] || { echo "  REFUSED: head is not the registered seed ($SEED)"; fail=1; }
  [ "$tree"   = "$TREE"   ] || { echo "  REFUSED: tree hash differs from the registered tree ($TREE)"; fail=1; }
  [ "$actual" = "$DIGEST" ] || { echo "  REFUSED: durable-state digest differs from the registered digest ($DIGEST)"; fail=1; }
  [ -z "$dirty" ]           || { echo "  REFUSED: working tree is not clean:"; echo "$dirty" | sed 's/^/    /'; fail=1; }

  # The exclusions are load-bearing in the NEGATIVE direction: their presence in
  # an ARM tree would mean that arm inherited live session state.
  #
  # The SOURCE repository legitimately carries these — they are the working
  # machine's own live ledgers, and their presence there is not a defect. That
  # is the ONLY reason the exemption exists, and it is a flag rather than a
  # silent skip so that using it on an arm tree is a visible act.
  if [ "$ALLOW_LIVE_LEDGERS" = "1" ]; then
    echo "  note: live-ledger exclusion check SKIPPED (--allow-live-ledgers). Valid for the source repo ONLY; an arm tree checked this way is not verified."
  else
    for leaked in ".gravito" "build-os/packets/routing/live_gate_log.tsv" "build-os/packets/routing/live_state"; do
      [ -e "$repo/$leaked" ] && { echo "  REFUSED: excluded live ledger present after restore: $leaked"; fail=1; }
    done
  fi

  if [ "$fail" -eq 0 ]; then echo "  VERIFIED: restored state equals the registered pin."; return 0; fi
  echo "  PIN VIOLATED — this is not a warning. Do not execute an arm against this tree."
  return 1
}

ALLOW_LIVE_LEDGERS=0
for a in "$@"; do [ "$a" = "--allow-live-ledgers" ] && ALLOW_LIVE_LEDGERS=1; done

if [ "${1:-}" = "--verify-only" ]; then
  verify "${2:?--verify-only needs a directory}" "verify-only"
  exit $?
fi

DEST="${1:?usage: restore-seed.sh <destination-dir> | --verify-only <dir>}"

if [ -e "$DEST" ]; then
  echo "REFUSED: $DEST already exists. Restoring over an existing tree can silently keep a stale file."
  exit 2
fi

git clone --no-checkout --quiet "$SOURCE" "$DEST"
( cd "$DEST"
  git checkout --quiet --detach "$SEED"
  git reset  --hard --quiet "$SEED"
  git clean  -fdxq )

verify "$DEST" "restore -> $DEST"
