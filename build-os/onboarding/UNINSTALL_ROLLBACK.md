# Uninstall and rollback

Derived from `build-os/runtime/gravito-runtime.sh` and its JSON helper — the
actual behaviour of the actual commands, not an intention.

**This page is deliberately available on day one.** A customer who cannot see
the exit before entering is being asked for trust they have no basis to give.

---

## 1. What was installed in the first place

The runtime manifest (`build-os/runtime/MANIFEST.json`, v0.1.0) names **eight
files**, plus two merge surfaces:

| installed file |
|---|
| `.claude/hooks/routing-gate.sh` |
| `build-os/tools/route-task.sh` |
| `build-os/tools/mode-select.mjs` |
| `build-os/tools/routing-check.sh` |
| `build-os/tools/record-degradation.sh` |
| `build-os/memory/routing_contract.md` |
| `build-os/memory/routing_contract_live.md` |
| `build-os/memory/provider_adapter_contract.md` |

Plus: two hook entries merged into `.claude/settings.json` (one `PreToolUse`,
one `PostToolUse`), and a small stanza appended to `.gitignore`.

The install is **no-overwrite and all-or-nothing**: it checks every target file
*before* touching anything, and if any of them exists with different content it
refuses and copies nothing. There is no partial install to unwind.

---

## 2. `uninstall` — what is removed

```bash
build-os/runtime/gravito-runtime.sh uninstall /path/to/your-repo
```

For each of the eight files, using the install record
(`build-os/runtime/INSTALLED_VERSION.json`):

| condition | action |
|---|---|
| file is byte-identical to what the install put there | **removed** |
| file has been **locally modified** | **kept** — "locally modified — customer-owned now" |
| file already absent | recorded `already-absent` |

Then:

- **Settings:** only hook entries that are **deep-equal** to the ones the
  install added are removed. An entry you edited does not match and is left
  alone. If an event's array becomes empty it is dropped; if `hooks` becomes
  empty it is dropped. **Every other top-level key in your `settings.json` is
  untouched.**
- **`.gitignore`:** only **exact line matches** of the installed stanza are
  removed. Your own lines are not touched.
- **`INSTALLED_VERSION.json`** is removed.
- A receipt of the uninstall is written to `build-os/runtime/receipts/`.

If no install record exists, it falls back to the manifest paths and still
removes **only** files whose content matches what it would have installed.

### What uninstall deliberately preserves

- **Every routing receipt** (`build-os/packets/routing/*.md`)
- **The activity ledger** and all live-state files
- **Every runtime receipt** (`build-os/runtime/receipts/*.json`)
- **Every backup** (`build-os/runtime/backup/`)
- **Every file you wrote or modified**, including any of the eight you edited
- **Every other key in your settings**, and every other line in your
  `.gitignore`

The tool's own closing line: *"runtime files and our settings entries removed;
receipts and customer files preserved."* **The audit trail is yours.** If you
want it gone, delete those directories yourself — they are plain text files and
nothing depends on them.

---

## 3. `rollback` — returning to the previous version

```bash
build-os/runtime/gravito-runtime.sh rollback /path/to/your-repo
```

Restores every file from the **most recent** backup directory under
`build-os/runtime/backup/<timestamp>/`, preserving timestamps, and writes a
rollback receipt. If there is no backup, it refuses and says so rather than
doing something approximate.

**Backups are created by `upgrade`, not by `install`.** A first install has
nothing to roll back to — the reversal of a first install is `uninstall`.

---

## 4. `upgrade` — and the two protections that matter

```bash
build-os/runtime/gravito-runtime.sh upgrade /path/to/your-repo [--force-theirs]
```

- **It refuses to upgrade over locally modified files.** If any installed file
  has drifted from what was recorded, the upgrade stops and names each one.
- **`--force-theirs`** proceeds, but **backs every affected file up first**
  into a fresh timestamped backup directory, then replaces it. The backup path
  is printed and recorded in the receipt.
- Upgrading is **always explicit.** Installed copies never auto-update; drift
  from the source is expected until you deliberately re-sync. Every installed
  document carries a header saying exactly that.

---

## 5. `status` — knowing where you stand before you do anything

```bash
build-os/runtime/gravito-runtime.sh status /path/to/your-repo
```

Prints one of three states per file, and a summary count:

| state | meaning |
|---|---|
| `current` | matches both the install record and the canonical source |
| `drifted-local` | you (or something) changed it after install |
| `upgrade-available` | unchanged locally, but the source has moved on |

Exit code `3` means not installed. **Run this before an upgrade or an
uninstall**, so you know in advance which files will be kept as customer-owned.

---

## 6. Full manual removal

If you would rather not run anything of ours to remove ours:

1. Delete the eight files listed in §1.
2. Remove the two hook entries from `.claude/settings.json` (they are the ones
   whose commands end in `routing-gate.sh`). Leave every other key.
3. Remove the Gravito stanza from `.gitignore`.
4. Delete `build-os/runtime/` if you do not want the receipts and backups.
5. Delete `build-os/packets/routing/` if you do not want the audit trail.
6. Delete `build-os/memory/`, `build-os/tools/` and any other `build-os/`
   subdirectory you do not want to keep.
7. Remove the managed block from `CLAUDE.md` — it is delimited by
   `BUILD-OS:START` / the matching end marker. **Everything outside those
   markers is yours and was never touched.**
8. Start a new session. Hooks load at session start, so the gate stops applying
   from the next one, not from the moment of deletion.

Nothing in this list requires our involvement, our permission, or a network
connection.

---

## 7. What removal does not do

- **It does not undo work the agents did.** Commits made during the pilot are
  ordinary commits in your history; revert them with git like any others.
- **It does not affect your AI provider relationship**, your plan, or your
  spend. Gravito was never in that path.
- **It does not delete anything outside the repository you name.** Every
  subcommand operates on one target directory and refuses to operate on the
  canonical source repository itself.
- **It does not phone anywhere.** There is no licence to release, no account to
  close, and no record of your install anywhere but in your own repository.
