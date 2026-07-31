# Entitlement — what you are paying for, and what you may do with it

**ClaudeOrchestrator (Build OS for Claude Code) is proprietary software. It is
not open source.** Copyright (c) 2026 Samuel Kestenbaum. All Rights Reserved.

This document is the plain-English companion to [`LICENSE`](../LICENSE). Where
the two differ, **`LICENSE` and your signed agreement win** — this file has no
legal effect of its own. Every claim below is pinned against the actual text of
`LICENSE` by `tests/entitlement_tests.sh`, so if the licence changes and this
document does not, the suite goes red.

---

## What you are buying

You are buying **access to the private repository**, and with it a licence
granted by a separate signed agreement. There is nothing else to buy: no
activation code to redeem, no seat to provision in someone's dashboard, no
service to sign in to. The product is the repository's contents — five agents,
three commands, two hooks, the memory/maintenance layer, the installers, and the
test suites that prove they work.

Concretely, what lands on your machine is a self-contained local system:

- it runs entirely on your machine, inside your Claude Code sessions;
- it stores its state in your own repositories, under `build-os/`;
- its metrics are local and operator-owned — yours, and only visible to you;
- it never reports back to the Owner, because there is nothing on the other end.

## What access grants

**Repository access is the entitlement mechanism.** The repository is private and
access-gated. Somebody who has not been granted access cannot clone it; somebody
who has been granted access can install it wherever their agreement allows.

That is the whole mechanism, and it is deliberate. The alternative — keys,
activation, expiry checks — would make a local, offline, operator-owned tool
depend on a server being reachable, and would put a network call inside a system
whose entire value proposition is that your build state stays yours.

Access alone, though, is **not** a licence. `LICENSE` is explicit about this,
because it is the single most common misreading of a repository you can see:

<!-- LICENSE-QUOTE:START -->
> No right or license of any kind is granted to you by this file.
> Making the Software visible — including publishing this repository or providing access to it — is not a license and does not waive any right.
> All rights not expressly granted in a signed written agreement are reserved by the Owner.
> The Owner's names, logos, and trademarks are not licensed by this file.
<!-- LICENSE-QUOTE:END -->

So: **access lets you obtain the Software; the signed agreement is what lets you
use it.** In practice the two arrive together — access is granted because an
agreement was signed — but they are separate things, and if you ever hold one
without the other, the one you hold is not the one that matters.

## What the licence permits

`LICENSE` on its own permits **nothing**. It grants no rights at all, by design.
Read literally, it is a reservation, not a grant.

Your permissions come from one place: **the separate written commercial agreement
signed by the Owner.** Whatever that agreement says — how many machines, how many
people, which projects, for how long, with what support — is the entire scope of
what is allowed. If a permission is not in that agreement, you do not have it,
and nothing in this document creates it.

If you are unsure whether something is covered, the answer is to ask for it in
writing and get it added to the agreement. That is cheap. Assuming is not.

## What the licence forbids

Absent a signed agreement that says otherwise, `LICENSE` withholds every one of
these — the list is quoted from the licence's own sentence, not paraphrased:

> use, copy, reproduce, install, execute, modify, adapt, translate, create
> derivative works of, merge, publish, distribute, sublicense, sell, lease, lend,
> host, or otherwise exploit the Software, in whole or in part, in any form or by
> any means

and you may not permit a third party to do any of it either. Note that `use`,
`install` and `execute` are on that list: this is not a "look but don't
redistribute" licence, it is a "nothing without an agreement" licence.

Two practical consequences worth stating plainly:

- **Do not re-publish it.** Pushing this repository, or a vendored copy of the
  engine, to a public host is the clearest breach available and the easiest to
  discover.
- **Vendoring into your own repo is normal — publishing that repo is not.**
  `install-project.sh` deliberately copies the engine into your project so it
  works at clone time. That copy carries the same licence (see
  `build-os/BUILD-OS-LICENSE`, written beside it at install). Keep the repo you
  vendored it into as private as your agreement requires.

## Teams, seats, and organisations

**`LICENSE` is silent on seats, teams, and organisations.** It does not say
"per-seat", it does not say "per-organisation", and it sets no user count. It
says only that rights come from a signed written agreement — so the answer to
"how many people may use it?" is *whatever your agreement says*, and nothing
else.

This is flagged rather than filled in on purpose. Inventing a seat model here
that no signed document supports would be worse than the ambiguity: a buyer's
counsel would find the mismatch, and the invented term would be unenforceable
anyway. If you need a per-seat, per-organisation, per-project or site-wide scope,
that belongs in the agreement, and it should be negotiated there.

What is *technically* true, and separate from what is *permitted*: nothing in the
software counts users, and nothing stops a second person from installing a copy
they were given. See "What is NOT enforced technically" below.

## How to verify an installed copy is genuine

Every install stamps the copy it produced, so a session — human or agent — can
answer "which version, which licence, and is this actually what was installed?"
with no one to ask. Two artefacts are written into each installed root:

| Artefact | What it is |
|---|---|
| `build-os-identity` | machine-readable stamp: version, source commit, source tree state, licence name, sha256 of the licence, install scope, and a sha256 of every file the installer placed |
| `BUILD-OS-LICENSE` | a byte-identical copy of `LICENSE`, so the terms travel with the copy |

Where they land:

```
~/.claude/build-os-identity          + ~/.claude/BUILD-OS-LICENSE          (global install, engine)
~/build-os/build-os-identity         + ~/build-os/BUILD-OS-LICENSE         (global install, tools)
<repo>/.claude/build-os-identity     + <repo>/.claude/BUILD-OS-LICENSE     (project install, engine)
<repo>/build-os/build-os-identity    + <repo>/build-os/BUILD-OS-LICENSE    (project install / scaffold)
```

To check a copy:

```bash
bash <root>/.claude/hooks/build-os-identity.sh verify <root>
# exit 0 = verified, 1 = DRIFT (this copy is not what its stamp claims), 2 = unstamped
```

Every Claude Code session that starts with the Build OS hooks installed prints
the same verdict as **one line**:

```
Build OS: v0.1.0 (da4ae81e5e45, clean) - licence: Proprietary, All Rights Reserved (access-gated) - identity: OK (14/14 files verified, project scope)
```

The stamp carries **no timestamp and no install path**, so it is reproducible:
the same source commit always stamps to the same bytes. Re-running an installer
leaves the tree byte-identical, a vendored copy does not churn in your diffs, and
two machines claiming the same commit can be compared directly — if their stamps
differ, one of them is not what it says it is.

**What the stamp proves:** that the files beside it are byte-for-byte the ones a
particular version and commit installed, and which licence that version shipped
under. A half-finished upgrade, a hand-patched agent file, a stamp copied next to
somebody else's code, or an edited version claim all show up as `DRIFT`.

**What the stamp does not prove:** that you are licensed. It is drift detection,
not proof of entitlement, and there is no secret and no signature behind it — the
digest is plain sha256 over plain files, so a determined person can recompute a
consistent stamp. It is built to catch the failure that actually happens
(installs that quietly stopped matching their own version claim), not to defeat
an adversary. A stamp that claimed more than that would be the dishonest kind.

## What is NOT enforced technically

Stated plainly, because implying a protection that does not exist is worse than
having none:

- There is **no licence key**, no serial, and no code to enter.
- There is **no activation**: nothing to unlock, nothing that can fail to unlock.
- There is **no telemetry**. The software **does not phone home**, at install, at
  session start, or ever. Nothing about your usage is transmitted to the Owner,
  because there is no endpoint to transmit it to.
- There is **no usage metering and no user counting.** Nothing observes how many
  people or machines are running it.
- There is **no expiry.** A copy does not stop working when an agreement ends,
  and there is no kill switch.
- The identity stamp described above **blocks nothing.** It reports; it never
  refuses to run.

**So what actually stops an unlicensed person using this? Repository access — and
nothing else.** Somebody who was never granted access cannot get a copy. Somebody
who obtains a copy anyway is stopped only by the licence itself, which is to say
by law and by the agreement, not by the software. That is the honest description
of this product's protection, and it is the same one every serious source-shipped
developer tool gives once you read past the marketing.

The trade is deliberate: a tool that watches you is a different product, with
different buyer objections, and it is not this one.

## What the LICENSE leaves ambiguous

Things `LICENSE` does not settle, listed rather than invented. Each is a question
for the signed agreement:

1. **Seat / user / organisation scope** — the file is silent (see above).
2. **Machine count** — nothing says whether a licence follows a person, a
   machine, or a repository.
3. **Term and renewal** — no duration, no renewal, no termination mechanics.
4. **Whether vendored copies inside your own private repositories are covered** —
   `install-project.sh` produces exactly that by design, so it is worth naming in
   the agreement explicitly.
5. **Contractors, subsidiaries, and clients** — "you may not permit any third
   party" is broad; who counts as your organisation is not defined.
6. **Support, updates, and what a version bump entitles you to** — the licence
   says nothing, and neither does this document.
7. **Where enquiries go** — `LICENSE` says only "contact the Owner" and gives no
   address.

## If your access ends

Repository access can be revoked; a copy already on your disk cannot be. Nothing
in the software reaches out to check, and nothing expires (see above).

What that means in practice: when an agreement ends, what ends is the permission,
not the bytes. Continuing to run a copy after the agreement that permitted it has
ended is a licence breach, not a technical impossibility, and it is exactly the
situation where the stamp is useful in the mundane direction — it tells an
auditor, or you, precisely which version and commit a machine is running.

Uninstall paths for both scopes are documented in
[`INSTALL.md`](../INSTALL.md#uninstalling). Removing the engine removes the
identity stamp and the licence copy with it; your own `build-os/` memory is
yours and is left in place.

---

*Licensing enquiries: contact the Owner (Samuel Kestenbaum), per `LICENSE`.*
