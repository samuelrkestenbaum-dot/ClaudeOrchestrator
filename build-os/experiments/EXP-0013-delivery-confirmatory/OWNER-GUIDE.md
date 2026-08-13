# EXP-0013 — Owner guide (plain language, no prior conversation assumed)

This guide explains the three separate decisions in front of you, in order.
Nothing in it runs the experiment or spends money.

## 1. Why publication comes first

Everything the experiment will do at spend time is defined by files in this
repository, sealed under a freeze manifest (currently v5). Publishing them
first means the frozen contract exists on the remote BEFORE any money is
spent, so nobody — including the tooling — can quietly change the rules
between your authorization and the run. Publication is just `git push` of
audited commits. **Pushing does not run the experiment, does not call any
model, and spends nothing.**

## 2. What will be pushed, and what will not

Pushed: the EXP-0013 experiment directory (harness code, frozen corpus,
preregistration, freeze manifests v1–v5, amendment and incident records,
rehearsal evidence with no container paths), its test suites, and two small
in-scope files (the planner seam, a registry entry). Verified free of
secrets by pattern and semantic scan.

NOT pushed, ever: the sealed arm-order/rerun/blinding salts (they live
outside the repository), your future escrow passphrase (never stored
anywhere), any spend authorization, and any provider credentials.

## 3. Publication: exact steps

Give the scoped push authorization (the template names the exact old tip,
new tip, commit count, branch, fast-forward-only, one push). After the
push, verification is: fetch independently, confirm the remote tip equals
the named new tip with zero divergence, confirm the local tree is clean,
and run `node …/harness/freeze.mjs verify` and `node …/harness/freeze5.mjs
verify` in a fresh checkout of the pushed tip. If the remote tip is NOT the
expected old tip when the push is attempted, the push is refused and
nothing changes — you re-issue against the true state after review.

## 4. Escrow: what it is and how to do it (after publication)

The experiment's arm order was drawn in advance and sealed; the sealed
files live only on this machine and die with it. The escrow encrypts them
so a copy can safely live in the repository. **What the passphrase
protects:** only the ability to PROVE later that the order was fixed in
advance. If the passphrase (or the machine) is lost, the study is still
fully analyzable — you lose only that proof.

How to run it (on this machine, in the repo root, after the push):

    node build-os/experiments/EXP-0013-delivery-confirmatory/harness/escrow-cli.mjs create

- It prompts for a passphrase twice with the terminal echo DISABLED —
  nothing you type appears on screen, in shell history, or in any file.
  The passphrase is never given on the command line, so `ps` and history
  cannot capture it. **Never paste the passphrase into Claude, chat, or
  any file.**
- Minimum 12 characters. Store it in your password manager (or a written
  record you control), and keep it at least until the study's reveal step
  is complete and audited.
- The tool writes ONLY ciphertext (`corpus/mapping-escrow.json`), silently
  proves it can be decrypted (without showing any content), and prints the
  ciphertext's digest. Success looks like: "decryptability: PROVEN" plus a
  digest line. You can re-check any time with `escrow-cli.mjs check`.
- **Committing that ciphertext file needs its own scoped authorization**
  quoting the printed digest — the escrow run itself changes nothing
  remote.

## 5. The measured run stays a separate, later decision

Nothing above authorizes any model call. When (and only when) you issue
the separate spend authorization, the run is bound to: model
claude-opus-5, 10 planned calls (2 unmeasured seeds + 8 measured cells),
a hard maximum of 16 calls, strictly one call at a time (serial), a hard
$100 ceiling enforced before every call, a 1200-second per-call time
limit, and automatic stop on: any empty delivery (voids the stage), a
second seed failure in a sequence, a second infrastructure failure, rerun
budget exhaustion, a wrong provider model id, any ledger or freeze
verification failure, or a budget projection breach.

## 6. How to abort safely, at any point

Before the push: do nothing — nothing has left this machine. After the
push but before spend: do nothing further — published files are inert
without a spend authorization. During a measured run: kill the controller
process; every call already made is settled or conservatively charged in
the ledger, no new call can start without re-passing every gate, and a
restarted controller re-reads the ledger rather than resetting it.
