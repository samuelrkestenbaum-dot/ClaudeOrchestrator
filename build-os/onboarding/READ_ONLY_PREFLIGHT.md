# Read-only preflight and intake

Two tools answer "what would this do to my repository?" **without writing a
byte into it.** Run both before anything is installed. You can run them
yourself; nothing needs us present.

---

## Tool 1 — `install-preflight.sh`

```bash
build-os/intake/install-preflight.sh /path/to/your-repo
```

**Writes nothing, anywhere, under any outcome.** It compares every file the
installer would place against what is already there, previews the three files
the installer *merges* into rather than replaces, and exits.

### The four verdicts, per file

| verdict | meaning |
|---|---|
| `WOULD-CREATE` | absent in your repo; installing would create it |
| `IDENTICAL` | already present and byte-identical; installing would be a no-op there |
| `WOULD-REFUSE` | **present with different content.** The preflight's contract is to refuse rather than let customer bytes be eaten silently. Resolve it — rename, remove, or accept the overwrite explicitly — before installing |
| `KEPT` | a customer-owned seed file (memory, tasks, receipts) the installer never overwrites |

### The three merge previews

- **`SETTINGS-MERGE:`** — what would happen to `.claude/settings.json`: whether
  each hook entry is already present or would be added, and **how many of your
  existing top-level keys the merge preserves**. If that file is not valid
  JSON, the preflight refuses and says so, because the real installer would
  otherwise fail halfway through it.
- **`CLAUDE-MD:`** — whether `CLAUDE.md` would be created, whether an existing
  managed block would be replaced, or whether the block would be appended.
  **Bytes outside the managed block are preserved** in every case.
- **`GITIGNORE:`** — whether the archive-visibility line is already present or
  would be appended.

### Exit codes

| code | meaning |
|---|---|
| `0` | `PREFLIGHT: CLEAR` — nothing written; the installer may proceed |
| `2` | `PREFLIGHT: WOULD-REFUSE` — nothing written; resolve the collisions first |

The summary line always states the counts: `N would-create, N identical, N kept
(customer), N refusal(s)`.

### One thing to know about how it stays honest

The list of maintenance files it checks is **read out of the installer itself**
at run time, not copied into the preflight. If that list changes, the preflight
follows it automatically; if the preflight cannot extract it, it says the
maintenance layer is **not covered by this run** and counts that as a refusal
rather than reporting a clean sheet it cannot vouch for.

---

## Tool 2 — `repo-intake.sh`

```bash
build-os/intake/repo-intake.sh /path/to/your-repo --out /tmp/intake-report
```

**Reads your repository; writes only into the report directory.** With no
`--out`, the report goes to a fresh temporary directory and your repository is
never a write target. Two artifacts come out:

- `INTAKE_REPORT.md` — the human-readable intake
- `intake.json` — the same findings, machine-readable

### How to read each section

**Language & framework detection.** Every row carries a `[CONFIDENCE: ...]`
label. A manifest being present is `HIGH` confidence for the language; a
dependency *name* in that manifest is `MEDIUM` for a framework hint. A
repository matching nothing gets an explicit `UNRECOGNIZED` line — **not a
silent best guess**.

**Command discovery.** Every command is labeled:

- `DISCOVERED` — read out of a manifest your repository wrote. Trustworthy.
- `GUESSED` — an ecosystem convention this script supplied. **A guess is never
  presented as a discovery.** `pytest` for a Python project is a guess.
  `npm test` read from your `scripts.test` is a discovery.

**Repo-local instructions.** Presence/absence of `CLAUDE.md`, `.claude/`,
`.claude/settings.json`, `.claude/hooks/` (with a count), a CONTRIBUTING file,
and whether your README has build/test headings.

**Mutation-surface map.** Every top-level directory classified as test /
source / docs / config / generated / migration / infra / unknown, **with the
naming heuristic printed on each row so you can reject it.** A directory that
matches nothing is listed `unknown` and becomes a candidate task to explore
rather than an assumption.

**AUTHORITY-SENSITIVE rows.** Migration and infrastructure directories, CI
configuration files, and secret-shaped file paths. Read these carefully and
note the bound printed with them: these are **name matches, not a security
audit, and absence of a flag is not clearance.** Secret-shaped files are
reported as paths only; their contents are never read.

**Baseline.** By default this section says `BASELINE: NOT MEASURED` and makes
**no red/green claim at all**, because a baseline nobody ran is not a baseline.
Passing `--run-baseline` executes the discovered/guessed test and typecheck
commands inside your repository with a timeout (default 120s,
`INTAKE_BASELINE_TIMEOUT`) and reports each exit code. **That flag is opt-in
precisely because those commands do whatever your test command does** — if your
test suite touches a database or the network, so will this. Do not pass it
without deciding to.

**Task graph seed.** Candidate first tasks. The report says it plainly: these
are **CANDIDATES, not commitments**. A red baseline command becomes a candidate
("a red baseline is the first honest task"), as does every unrecognised
directory.

**Unsupported assumptions.** The section to read first if you only read one.
It lists what the intake could *not* determine, including its standing limits:
framework hints come from a fixed list of six names and anything else goes
undetected; monorepo layouts are not analysed (only the root's manifests are
consulted); directory classification is a name heuristic and a misnamed
directory is misclassified; authority flags are name matches, not an audit.

---

## What to do with the output

1. **Read the "Unsupported assumptions" section first.** It is the shortest
   route to knowing how much of the rest to trust.
2. **Correct the guesses.** If `GUESSED` commands are wrong, write the right
   ones down. That correction is worth more than anything the tool inferred.
3. **Check the authority-sensitive list against reality** — the questionnaire's
   section 5 exists because the name heuristic cannot see intent.
4. **Resolve every `WOULD-REFUSE`** before anyone attempts an install.
5. **Keep both reports.** They are the honest record of what the repository
   looked like before anything changed.
