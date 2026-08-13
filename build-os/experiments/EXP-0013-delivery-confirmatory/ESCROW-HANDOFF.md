# EXP-0013 mapping escrow — OWNER HANDOFF CHECKLIST (prepared; not yet executed)

Purpose: make the precommitment PROOF (sealed arm orders + rerun orders +
blinding salt) survive container loss. Executed evidence already shows
post-launch ANALYZABILITY does not depend on these stores (cell records
carry arm identity); what escrow preserves is the ability to prove the
orders were fixed before execution.

Order of operations (after the publication push, before spend authorization):

1. Owner opens a shell on this machine in the repo root.
2. `node build-os/experiments/EXP-0013-delivery-confirmatory/harness/escrow-cli.mjs create`
   - passphrase typed twice with echo DISABLED — it never appears on
     screen, in shell history, in chat, or in any file;
   - minimum 12 characters (shorter is a typed refusal);
   - the tool writes ciphertext ONLY to `corpus/mapping-escrow.json`,
     proves decryptability by silent byte-identical round trip, and prints
     the ciphertext sha256.
3. Commit `corpus/mapping-escrow.json` (ciphertext is safe to publish; the
   blinded adjudicator/analyst views never reference it) and push under a
   scoped go. Record the printed ciphertext digest in that go.
4. **Owner retention duty**: store the passphrase OUTSIDE this container
   (password manager or written record), retained AT MINIMUM until Stage-A
   reveal is complete and the audit record is closed. Loss of the
   passphrase = loss of precommitment proof if the container is also lost;
   the study remains analyzable either way.
5. Optional at any later time: `escrow-cli.mjs check` re-proves
   decryptability (no labels shown, wrong key/tamper are typed refusals).

Explicitly NOT happening in this leg: no passphrase entry, no escrow file
creation, no request for the secret in chat — the CLI exists and is tested
against SYNTHETIC mappings only. Role isolation remains PROCEDURAL (one OS
identity); the ciphertext adds durability, not a new isolation boundary.
