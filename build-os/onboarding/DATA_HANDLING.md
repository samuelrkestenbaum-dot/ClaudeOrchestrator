# Data handling

Everything below is derived from what the shipped code does, and every claim
names the file you can read to check it. Nothing here is a policy statement
about what we intend; it is a description of what the software does, which you
can verify yourself in an afternoon — the installed runtime is around two
thousand lines of plain text.

## 1. The gate runs locally, in your repository

The routing gate is a shell hook that your AI host executes on your machine:
`.claude/hooks/routing-gate.sh`. It reads the tool-call JSON the host hands it,
classifies the call, decides allow or block, and appends a row to a file inside
your repository. That is the whole loop. There is no daemon, no agent process,
and no service.

## 2. It makes no network calls

The installed runtime is eight files
(`build-os/runtime/MANIFEST.json` lists them exactly): the gate hook, four
routing tools, and three contract documents. **None of them opens a socket.**

Verify it in one command against your own installed copy:

```bash
grep -rInE '\b(curl|wget|nc |ssh |scp |https?://)' \
  .claude/hooks/routing-gate.sh build-os/tools/ build-os/shell/ \
  build-os/runtime/gravito-runtime.sh
```

On the canonical source that grep returns nothing. If it ever returns something
on your installed copy, that is a finding, and you should treat it as one.

The intake and preflight tools (`build-os/intake/`) are the same: they read
your files, write a report, and make no network call.

## 3. Everything it records stays in your repository

| what | where it lands |
|---|---|
| routing receipts, one per task | `build-os/packets/routing/*.md` |
| the append-only activity ledger | `build-os/packets/routing/live_gate_log.tsv` |
| per-task live activity rows | `build-os/packets/routing/live_state/<receipt>.tsv` |
| install / upgrade / rollback / uninstall receipts | `build-os/runtime/receipts/*.json` |
| the record of what version is installed | `build-os/runtime/INSTALLED_VERSION.json` |
| backups taken before a forced upgrade | `build-os/runtime/backup/<timestamp>/` |

All of it is inside the repository you already control, in plain text you can
read, diff, and delete. **Nothing leaves your infrastructure via Gravito**,
because there is nothing in it that could send anything anywhere.

The install adds a `.gitignore` stanza that keeps the *receipts* tracked — in a
product install the receipts are the evidence — and leaves only the two
high-churn live ledgers untracked. You can change that; it is your
`.gitignore`.

## 4. Secrets: flagged by name, never read

The intake tool searches for secret-**shaped** file names — `.env`, `.env.*`,
`*secret*`, `*credential*`, `*.pem`, `*.key`, `id_rsa*`, `*.p12`, `*.keystore`
— to a depth of two directories, and reports **the path and nothing else**
(`build-os/intake/repo-intake.sh`). The `find` that locates them matches names;
no code path after it opens one. The value never enters the process, so it
cannot be printed, summarised, or written to a report.

Two honest bounds on that:

- **A name match is not a security audit.** A secret in a file called
  `config.yaml` is not flagged. **Absence of a flag is not clearance.**
- The gate reads the *tool-call metadata* your AI host provides — the command
  text and file paths of the call being attempted — in order to classify it. If
  a developer types a secret into a shell command, that command text is what
  the gate sees and what the ledger records, exactly as your shell history
  would. Gravito does not create that exposure and does not remove it.

## 5. What Gravito does **not** govern: your AI provider

This is the most important paragraph on the page.

**The AI provider's own data handling is governed by your agreement with that
provider. Gravito does not alter it, does not intercept it, and cannot improve
it.** When your AI host sends your code to a model, it sends it under your
provider contract, on your provider's infrastructure, subject to your
provider's retention and training terms. A gate that runs after the host has
already decided to make a call is not in that path and has no view of it.

If your obligation is "this code must not reach that provider", Gravito is not
the control that satisfies it. Your provider agreement and your host
configuration are.

## 6. Not a sandbox

The platform's permission system is your security boundary. The gate is
discipline for honest agents plus an audit trail; its command classification is
a named heuristic that a hostile command evades trivially
(`build-os/memory/routing_contract_live.md` names the evasions, including
`sh -c`). See [`UNSUPPORTED_DISCLOSURE.md`](UNSUPPORTED_DISCLOSURE.md) — the
full list is there, not softened.

## 7. Who can see what

- **Us:** nothing, unless you show it to us. There is no telemetry, no
  licence check, no phone-home, and no account. During a service-assisted
  pilot we see what you screen-share, send, or grant us access to — the same
  as any consultant.
- **Your team:** everything, because it is all plain text in your repository,
  and readable with `gravito tasks` / `gravito task <id>` /
  `gravito activity` (`build-os/shell/gravito`, a read-only command).
- **Your provider:** whatever your AI host sends it, under your agreement with
  them, unchanged by any of this.

## 8. Deleting it

Every artifact listed in §3 is a file. `rm` removes it. Uninstalling the
runtime deliberately *preserves* your receipts and backups, because the audit
trail is yours — see [`UNINSTALL_ROLLBACK.md`](UNINSTALL_ROLLBACK.md) for
exactly what a removal touches and what it leaves.
