# Install prerequisites

What must already be true before anything is installed. Derived from the
dependency lines of the shipped tools, not from a wish list.

## 1. Required for the runtime itself

| requirement | why | checked by |
|---|---|---|
| **bash** (5.x; the tools use arrays and `set -uo pipefail`) | the gate hook and every routing tool are bash | `bash --version` |
| **node** (stdlib only — no packages are installed, ever) | mode selection, manifest handling, and the dashboard renderer are node scripts | `node --version` |
| **git** | the runtime records source commit and branch; the window recorder derives durable output from git | `git --version` |
| **coreutils** incl. `sha256sum`, `find`, `awk`, `sed`, `cmp` | file identity, receipt parsing, ledger reading | `sha256sum --version` |
| **Claude Code, with hooks enabled** | the gate IS a Claude Code hook; without hooks nothing observes and nothing blocks | see §3 |

`gravito-runtime.sh` states its own dependency line as "bash, node, git,
coreutils. Nothing else." That is accurate for the runtime.

## 2. Additionally required for the intake and preflight tools

| requirement | why |
|---|---|
| **python3** | `build-os/intake/repo-intake.sh` parses `package.json` and emits `intake.json` with python3; `build-os/intake/install-preflight.sh` parses your existing `.claude/settings.json` with python3 |

This is a real prerequisite and it is easy to miss, because it applies to the
*look-before-you-install* step rather than to the runtime. If python3 is
absent, the preflight cannot check your settings file and the intake cannot
read your `package.json`.

**No package is ever installed into your project.** No npm dependency, no pip
package, no lockfile change. If an install ever proposes to add a dependency to
your manifest, something has gone wrong.

## 3. The provider situation, stated honestly

Task-entry governance is host-independent doctrine. What a given AI host can
actually **see** and **stop** is a property of the adapter for that host, and
the honest table is in `build-os/memory/provider_adapter_contract.md`:

### Claude Code hooks — the one verified adapter

Everything works: the gate observes tool calls (PreToolUse / PostToolUse), it
can **block** a pending call before it executes with a model-visible reason,
and every counted event binds to the open receipt. Dispatch counts, tool
events, and elapsed time are EXACT. The token proxy is an ESTIMATE and is
labeled as one everywhere. Live tokens and cost are UNAVAILABLE in interactive
sessions.

**Hooks load at session start.** The session in which you install is *not*
governed by what you just installed. Protection begins with the next session.

### Codex / OpenAI — interface-unverified

The adapter contract records this as **UNVERIFIED**: the host was unreachable
from the environment where verification was attempted (403 at the proxy on
every attempt), and its hook surface has deliberately **not** been guessed.
Until a real call succeeds, Codex sessions are **outside the boundary** and
must be treated as ungoverned — not "probably fine".

### Any other provider

There is no adapter. A row in the capability table may claim a capability only
with an executed demonstration in the test suite; a row without evidence is
written UNVERIFIED, because an unverified adapter is information, not coverage.
So: **if your team does AI-assisted work on a host other than Claude Code, that
work is not governed by this**, and the receipts will not know it happened.

**Practical consequence for a pilot:** the measured comparison only means
something if the work being measured actually runs on the governed host. Mixed
usage across hosts is not a blocker, but it must be recorded in the
success-metric form, or the numbers quietly describe a different population
than the one you think they do.

## 4. Repository preconditions

- **A git repository.** Not a requirement of the hook, but the runtime records
  commit/branch and the measured-window recorder derives durable output from
  git; without git several fields simply read `unavailable`.
- **A clean tree at install time.** Not enforced by the installer, but strongly
  advised: it is how you can see exactly what the install did with
  `git status`.
- **Write access to `.claude/` and `build-os/`** in the target repository.
- **No file collisions.** The installer refuses rather than overwriting: if any
  file it would place already exists with different content, it stops and
  copies nothing. Find out before you try —
  see [`READ_ONLY_PREFLIGHT.md`](READ_ONLY_PREFLIGHT.md).

## 5. Human preconditions

- Someone named who approves external mutations
  (see [`AUTHORITY_WORKSHEET.md`](AUTHORITY_WORKSHEET.md)).
- Someone willing to take two meter readings per measured window and to judge
  task acceptance honestly, including "no"
  (see [`BASELINE_CAPTURE.md`](BASELINE_CAPTURE.md)).
- Agreement on what would count as success, in writing, **before** the pilot
  starts (see [`SUCCESS_METRIC_TEMPLATE.md`](SUCCESS_METRIC_TEMPLATE.md)).

## 6. Order of operations

1. Read [`UNSUPPORTED_DISCLOSURE.md`](UNSUPPORTED_DISCLOSURE.md) first. If it
   is a dealbreaker, everything after this is wasted effort on both sides.
2. Run the read-only preflight and intake — nothing is written.
3. Resolve any collision the preflight reported.
4. Fill in the authority worksheet.
5. Capture the baseline **before** installing.
6. Install.
7. Start a **new** session — the gate is live from there, not before.
