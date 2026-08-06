# Context Compiler — entry (the CONTEXT-MODE SEAM)

The point at which a task acquires its **starting context**, and the place where
`AB_PREREGISTRATION.md` **AMENDMENT 2** stops being prose and becomes an
arithmetic check on a record.

**SHIPS INERT.** These three tools are invoked by hand, are wired into no
execution path, and are called by nothing — per the SEAMS.md non-goal ("v0
ships INERT ... so PILOT-0002's frozen environment is untouched"). That is not a
promise: `tests/context_mode_tests.sh` section 8 greps `.claude/hooks/**`,
`.claude/settings.json`, `build-os/tools/**`, `build-os/runtime/**` and every
`build-os/compiler/**` directory except this one, asserts **zero** references to
these files and **zero** occurrences of the mode name, and carries a positive
control proving the grep finds the string when it is there.

Bash + Node stdlib only. No dependencies, no network, no environment variables.

## The product need

Arm B was written as "the worker receives the compiled capsule and may buy more
context through the expansion protocol". That says what B RECEIVES and never
forbids what B **also** receives. If the harness delivers the ordinary broad
context *and* the capsule, arm B's tokens rise by construction, the capsule
becomes pure overhead, and the run measures an **addition** while claiming to
test a **substitution**. A compression thesis cannot be tested by adding bytes.

AMENDMENT 2 closed that gap in words. This directory closes it in code.

## `context-mode.mjs` — the seam itself

```
context-mode.mjs prepare --mode <standard_context|compiled_context>
  --task <task.json> --out <record.json>
  [--capsule <file>]... [--prefix <file>]
  [--initial <file> [--initial-label <label>]]...
  [--starting-context <file>] [--repo <dir>] [--repo-commit <sha>]
  [--now <iso>] [--expect-capsule-sha256 <hex>]
```

**Exactly two modes, both explicit.** No default, nothing inferred.

- `standard_context` — arm A, unchanged. It does not compile, requires no
  capsule, and **breadth never confounds it**: receiving the whole repository IS
  its contract. It records its own starting bytes so arm B has something to be
  compared against. A capsule reaching this mode *is* a confound —
  "the capsule leaks into arm A" is a preregistered stop condition.
- `compiled_context` — immutable prefix (SEAM 5) + compiled capsule (SEAM 2) +
  **nothing else**. Every further byte must arrive through a recorded SEAM 3
  expansion request.

**Mark, do not repair.** A violating task gets a written record, named reasons,
`confounded: true`, `registered_conclusion: "result confounded"`, and exit 3.
The tool never strips the extra context, never substitutes a conforming input,
and never re-runs the task. Each of those would destroy the evidence that the
harness broke the arm contract, and the preregistration requires the task be
**excluded from the aggregate — not fixed into looking clean**.

Confound codes: `non_permitted_initial_context`, `undeclared_initial_artifact`,
`duplicated_capsule_content`, `duplicated_prefix_content`, `mutable_prefix`,
`capsule_digest_mismatch`, `starting_bytes_mismatch`,
`capsule_leaked_into_standard_context`.

**Prefix immutability is verified, not assumed** — against both the capsule's
declared `provenance.prefix_sha256` and the compiler's pinned `PREFIX_SHA256`.
A prefix that varies per task is not a prefix: it invalidates the cached prefix
of every other task, which is the one cost SEAM 5 exists to avoid.

Exit: `0` prepared clean · `2` usage/read refusal · `3` CONFOUNDED (record still
written).

## `admit.mjs` — eligibility-gated admission

```
admit.mjs admit --mode-requested <mode>
  ( --index <index.json> [--capsule <capsule.json>] | --report <report.json> )
  --out <admission.json> [--now <iso>]
```

It **consumes** `build-os/compiler/capability/report.mjs` — live, or a recorded
run of it — and never recomputes the verdict. A second derivation of the one
number AMENDMENT 1 is measured on is exactly the ambiguity that reporter's
derivation-parity note exists to prevent.

**The rule is conjunctive:** `ELIGIBLE` **and** a recommended use state other
than `bypass`. They are not the same test — an index can pass the no_parser
share and still extract **zero symbols** across the admitted-candidate set:
eligible by the letter of the amendment, blind in fact.

**NO OVERRIDE, by construction.** No flag, argument or environment variable can
force `compiled_context` past a refusal during EXP-0004. `--force`,
`--override` and `--allow-bypass` are recognised **only** to produce a named
refusal — refusal paths, not escape hatches — and no tool here reads
`process.env`, because an environment variable is the override channel nobody
documents. If you think the verdict is wrong, fix the **index** and measure
again: that changes the evidence, which is the only thing allowed to change the
answer.

Run against **this** repository it refuses: `392/418 (93.8%)` no-parser,
`bypass`, `NOT-ELIGIBLE` → downgraded to `standard_context`, exit 4.

Exit: `0` requested mode granted · `4` refused and downgraded · `2` usage.

## `activation.mjs` — the boundary

```
activation.mjs check <activation.json>
```

It **activates nothing**. It starts no run, writes no state, wires no path, and
holds no mutating capability. A tool that could both check and activate would
eventually do the second because the first passed.

All five preconditions must hold, and **every unmet one is named individually**
— a refusal that reports only the first failure sends the operator round a
fix-and-retry loop, discovering the next problem one round at a time:

1. an **eligible repository**, on recorded evidence (binds *both* arms: arm A
   run on a repository arm B cannot see is not a comparison);
2. a **published EXP-0004 freeze**, whose file digest equals the declared one;
3. an **explicit arm**, A or B — never inferred, never defaulted;
4. the **exact 40-hex seed commit**, equal to the record's;
5. a **valid starting-context contract** — an unconfounded record whose mode
   matches the arm.

Exit: `0` all hold · `2` refused.

## Tests

`tests/context_mode_tests.sh` — **177 assertions**, standalone, deterministic,
mktemp fixtures only. The adversarial set is the point, and it also pins the
three properties that keep the experiment honest in the other direction:
expansion stays permitted and measured and **cannot rewrite the initial record**;
an incomplete capsule is allowed to **fail honestly** with nothing topping it
up; and **a smaller starting prompt is never a win by itself** — grep-negative
over every emitted record key and over the non-comment sources.

## Limitations (stated, not buried)

- **Provider-added hidden context is NOT OBSERVABLE** from any artifact this
  seam can read — system prompts, injected reminders, tool preambles,
  provider-side retrieval. Nothing here measures it and nothing here bounds it.
  There is deliberately **no test** for it: a green check over an unmeasured
  thing is worse than an admitted blind spot. The record carries the limitation
  in words instead.
- Byte counts are of the artifacts handed in, not of provider tokenization: an
  `ESTIMATE` in SEAM 5's tier vocabulary, never billing truth.
- `--initial-label` is operator-supplied and unverified. This seam records what
  it was told a file is and never infers a file's kind from its contents.
- Eligibility is a statement about the **index**, not a prediction that any
  capsule compiled from it is correct. An eligible repository can still produce
  a capsule that loses — which is what outcome 4 exists to record.

## Preregistration ambiguities found while building this

Recorded rather than resolved silently:

1. **AMENDMENT 2 says "starting bytes equal the rendered capsule plus prefix",
   but `render-capsule.mjs` emits the prefix INSIDE the rendered capsule.** Read
   literally, prefix + rendered-capsule double-counts the prefix. This tool
   treats the two as separate segments and flags the overlap as
   `duplicated_prefix_content` rather than silently subtracting it. Which
   artifact the harness is supposed to hand the worker — `capsule.json`, the
   rendered `capsule.md`, or a prefix-stripped render — is **not specified** and
   should be fixed before the run.
2. **"The capsule's declared prefix digest" has no home in SEAM 2's schema.**
   `compile-task.mjs` happens to write `provenance.prefix_sha256`; the seam
   contract does not require it. Capsules from any other producer may declare
   nothing, in which case only the pinned constant can be compared.
3. **Outcome 5 is `result confounded` (a space) in the preregistration and
   `result_confounded` in common use.** The record emits the preregistered
   wording verbatim plus machine-readable codes, so the two cannot drift.
4. **AMENDMENT 1's eligibility precondition does not say whether it binds the
   RUN or only arm B.** `activation.mjs` reads it as binding the run (both
   arms), on the argument in §5 above. If the operator intends otherwise, that
   is a preregistration amendment, not a code change.
5. **Nothing preregisters what a task's starting context may contain in arm A.**
   `standard_context` therefore records breadth without judging it, which is the
   only reading consistent with "arm A is unchanged".
