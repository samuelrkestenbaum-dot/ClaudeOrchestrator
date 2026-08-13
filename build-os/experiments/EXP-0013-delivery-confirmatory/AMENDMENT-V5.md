# EXP-0013 AMENDMENT v5 — release-candidate audit corrections

An owner-authorized publication-candidate audit of 607c0bd..123ab36 found
two material defects and one hygiene defect. Fixed here, disclosed, frozen
under FREEZE-MANIFEST-v5.json; v1 verifies live, v2/v3/v4 manifests are
byte-identical history inside v5.

1. **ORACLE PATH IDENTITY (launch-fatal).** tsc embeds ABSOLUTE module
   specifiers in some error messages (5 of 781 baseline lines, e.g.
   `import("/…/scratchpad/exp0013-corpus-baseline/drizzle/schema")`).
   The frozen baseline was produced in the corpus scratch directory; every
   measured after-run happens in a per-sequence worktree with a different
   absolute path — those 5 identities would differ, register as NEW error
   identities, and the global regression check would have REJECTED EVERY
   MEASURED CELL. Prior suites missed it because their synthetic oracle
   texts carried no absolute paths. Fix: oracle identities are now
   tree-root-free (`normalizeMsg` maps any absolute prefix before a known
   top-level tree dir to `<TREE>`), proven root-invariant by test; the
   committed baseline is normalized to `<TREE>` (5 lines; counts, tasks and
   clusters unchanged; sequences.json records old→new digest and the
   reason). This also removes the committed container-path/session-id leak
   the secret audit flagged.
2. **WORKER-ENVIRONMENT INSTALL CLOSURE (freeze coverage).** `gravito init`
   installs engine bytes into the measured worktree (install-project.sh:
   .claude agents/commands/hooks + allowlist + settings-merge;
   init-build-os.sh: templates/build-os seeds + maintenance layer +
   identity stamp). Those bytes shape worker sessions (hooks fire inside
   the worker) and were OUTSIDE v4. v5 freezes the complete closure:
   install-project.sh, init-build-os.sh, goal-check/route-task/mode-select,
   and the RECURSIVE TREES templates/, .claude/agents/, .claude/commands/,
   .claude/hooks/, build-os/maintenance/ — per-file sha256 + mode, with
   unexpected/missing tree files as typed refusals.
3. **COMMITTED EVIDENCE HYGIENE.** Rehearsal request digests recorded the
   raw scratch cwd. Digests now record a stable display form
   (`<ISO>/<seq>/worktree`); evidence regenerated. The incident record's
   deliberate quotation of its own session log path remains — that is
   forensic evidence, intentionally disclosed.

Also added, per the release audit: tests/exp0013_release_tests.sh (release
manifest, secret-absence, corpus/evidence path hygiene, oracle
root-invariance, publish-gate dry run), and OWNER-GUIDE.md (plain-language
owner handoff). The v5 supersession follows the same rule as v3/v4:
superseded manifests refuse on the changed files — that refusal is the
disclosure.
