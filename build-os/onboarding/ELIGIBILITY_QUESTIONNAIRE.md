# Eligibility questionnaire — candidate repository

**Questions only.** There is no scoring, no weighting, and no threshold at the
bottom of this page. A score would turn a judgment into an assessment, and
nothing here has been calibrated against an outcome — because no external
repository has ever run this software. The answers inform a decision made by
people, in writing.

Answer what you can. **"I don't know" is a useful answer** and should be
written down as such rather than guessed; a guess recorded as a fact is the one
thing that makes this form worse than useless.

---

## 1. The repository itself

1. What is the repository, in one sentence — what does the code do?
2. Roughly how many files, and roughly how many lines?
3. Is it a single project or a monorepo / workspace with several packages?
4. What languages are in it, and roughly in what proportion?
5. Which directories hold the code that actually matters — where does a change
   most often need to be made?
6. Are there large vendored, generated, or checked-in build directories?
7. How old is it, and how much of it is still actively changed?

## 2. Stack and toolchain

8. Which package/dependency manifests exist at the repository root
   (`package.json`, `pyproject.toml`, `requirements.txt`, `go.mod`,
   `Cargo.toml`, `Gemfile`, `pom.xml`, Gradle files, something else)?
9. What is the exact command that builds it?
10. What is the exact command that runs the tests?
11. What is the exact command that type-checks or lints it, if any?
12. Are those commands written down anywhere in the repository (a README,
    a CONTRIBUTING file, a Makefile), or do they live in people's heads?
13. Does a fresh checkout build and test successfully today, on a clean
    machine, with no undocumented steps?

## 3. Test posture

14. Do the tests currently pass on the main branch? If not, which fail and for
    how long have they failed?
15. How long does the full suite take?
16. Is there a faster subset a developer runs before pushing?
17. Roughly what proportion of the code has tests you would call meaningful?
    (An honest "we don't know" is expected and fine.)
18. Are any tests flaky? Which, and how often?
19. Do the tests need network access, a database, credentials, or a container
    to run?
20. Is there a coverage measurement, and do you trust it?

## 4. CI and delivery

21. What runs CI (GitHub Actions, GitLab, Jenkins, CircleCI, something else)?
22. What does CI do on a pull request, and what does it do on merge?
23. Does CI deploy anything automatically? To where?
24. Who can merge to the main branch? Is that enforced by branch protection or
    by convention?
25. What is the release cadence, and is a release reversible?

## 5. Authority-sensitive areas

*(The intake tool flags these by directory and file NAME only. It never opens a
secret-shaped file. These questions are how we learn what the name heuristic
cannot see.)*

26. Which directories, if changed carelessly, would cause real damage —
    migrations, infrastructure, payment paths, auth, anything regulated?
27. Where do database migrations live, and what is the process for adding one?
28. Where does infrastructure-as-code live, and who owns it?
29. Which files or directories must **never** be edited by an AI agent under
    any circumstances?
30. Are there compliance obligations that touch this code (regulatory audit,
    data residency, customer contractual terms)? Which parts of the tree?
31. Where do secrets live in practice — environment files, a secret manager,
    CI variables, a developer's machine?
32. Are there any files in the repository right now that contain a real
    credential? (If yes, that is a finding to fix regardless of Gravito.)

## 6. Approval and authority

33. Who approves a push to a shared branch?
34. Who approves a merge to the main branch?
35. Who approves a deployment?
36. Who approves spending money — new infrastructure, a paid service, an
    increase in AI provider spend?
37. Who approves anything that leaves the company — an outbound message, a
    published artifact, a customer-facing change?
38. Are those the same person? If a single person holds several of those, say
    so plainly; it changes what the gate is protecting against.
39. Is there an existing change-approval process this must fit inside, and what
    is it called internally?

## 7. AI usage today

40. Which AI coding tools are in use, by whom, and how often?
41. Which provider, and on which plan or contract?
42. Does the current provider agreement permit this code to be sent to that
    provider? Who confirmed that?
43. Is anyone measuring what AI-assisted work currently costs or produces? How?
44. Has AI-assisted work caused a problem in this repository — a bad merge, a
    runaway session, a change nobody could explain afterwards? What happened?

## 8. The pilot itself

45. Which one or two repositories would the pilot cover?
46. Over what period, and who on your side would be involved?
47. Who takes the two meter readings that bound each measured window
    (see [`BASELINE_CAPTURE.md`](BASELINE_CAPTURE.md))?
48. Who judges whether a task's output was acceptable, and are they willing to
    say "no" in writing when it was not?
49. What would have to be true at the end for you to call the pilot worth
    having done? (This becomes the success-metric form —
    [`SUCCESS_METRIC_TEMPLATE.md`](SUCCESS_METRIC_TEMPLATE.md) — and it is
    agreed **before** the pilot starts, not after.)
50. What would make you stop it early?

---

## What we will tell you back

- What the read-only preflight and intake found, verbatim, including
  everything they could not determine
  (see [`READ_ONLY_PREFLIGHT.md`](READ_ONLY_PREFLIGHT.md)).
- Which parts of your stack the tooling can actually read, and which parts it
  is blind to (see [`SUPPORTED_STACKS.md`](SUPPORTED_STACKS.md)).
- The full limitations list, unedited
  (see [`UNSUPPORTED_DISCLOSURE.md`](UNSUPPORTED_DISCLOSURE.md)).
- Whether we think this is a good fit, and why — as an opinion, labeled as an
  opinion.
