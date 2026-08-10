# The corrected re-baseline — the contamination is gone, and nothing else moved

**12 arms, T01–T04 × 3 reps, config `corrected`. Frozen.**
Raw output: `corrected-baseline.txt` (regenerate with `threeway.mjs`).

`corrected` applies **no lean changes**. Identical doctrine, identical gate,
identical controls, identical administered CODE. The only difference from the
contaminated baseline is that `build-os/motion/queue.json` and
`build-os/learning/dispositions/EXP-0004.json` no longer reach the worker.

## Headline

**The correction eliminated the contamination and did not make Gravito cheaper.**

| vs the frozen native reference | contaminated | corrected |
|---|---|---|
| turns | 1.54× | 1.55× |
| cost USD | 2.48× | **2.43×** |
| uncached tokens | 2.33× | 2.42× |
| tool calls | 1.21× | 1.58× |
| output/turn | 1.42× | 1.86× |
| context/turn | 1.70× | 1.51× |

36/36 arms accepted, across all three groups.

## The separation test, because a mean over 4 tasks is not a result

Within-cell CV runs 6–45% on turns and 9–69% on cost. At that spread a ratio of
means says nothing. So per task: do the three corrected reps fall **entirely** on
one side of the three contaminated reps? Complete separation of six exchangeable
values in a named direction is 1/C(6,3) = 0.05; two-sided 0.10. Four tasks
separating the same way, two-sided, is 2 × 0.05⁴ = 1.25e-5.

| metric | T01 | T02 | T03 | T04 | verdict |
|---|---|---|---|---|---|
| queue refs | LOWER | LOWER | LOWER | LOWER | **4/4 LOWER, p=1.3e-5** |
| turns | overlap | overlap | overlap | overlap | inside the noise |
| cost USD | overlap | overlap | overlap | overlap | inside the noise |
| uncached tok | overlap | overlap | overlap | overlap | inside the noise |
| text-only turns | overlap | overlap | overlap | overlap | inside the noise |
| context/turn | overlap | overlap | overlap | overlap | inside the noise |
| tool calls | HIGHER | overlap | overlap | overlap | not consistent |
| output/turn | HIGHER | overlap | HIGHER | overlap | not consistent |
| impl reads | HIGHER | overlap | overlap | overlap | not consistent |
| routing+authority | HIGHER | HIGHER | overlap | overlap | not consistent |

Waiting-posture turns went 2.0/arm → **0.0 across all twelve corrected arms**.
The two surviving queue references are the worker observing the *absence*:

> "No `queue.json` exists, so continuation falls through — the concession check
> is the only live gate."

## Two interim claims, withdrawn

At rep 1 (n=4) this looked favourable. It was not.

1. **"Removing contamination removed about a third of the turn tax."** Text-only
   turns 20.5 → 16.3 with **complete overlap on every task**. The Step-1
   attribution of ~6.7 turns/arm to the foreign queue is **refuted at n=12**.
2. **"The corrected arms are markedly less variable."** An artifact of nine arms.
   T02 rep 3 landed at 77 turns and T03 rep 3 at 43 turns / $3.54; corrected CV
   is now 13–35% on turns, 9–56% on cost — indistinguishable from contaminated.

Both were favourable readings taken before the data supported them. That is the
second time this session the same within-cell variance has produced a confident
wrong answer at low n.

## The residual has a direction, and it is not the favourable one

**No metric separated LOWER except queue refs.** Four separated HIGHER on at
least one task. Two of four tasks is not consistency, so this is not a finding —
but the asymmetry is not what noise looks like either.

Weak supporting hypothesis: **deferring to the foreign queue suppressed real
work**, so the contaminated baseline was artificially cheap and the correction
removed a discount rather than adding a cost. Within the two tasks that have a
contrast (`deferral-suppression.mjs`):

```
T01  deferred n=2  24.5 tools $2.19 | did-not-defer n=1  31.0 tools $4.07
T02  deferred n=1  23.0 tools $1.92 | did-not-defer n=2  35.0 tools $2.83
```

n=3 with within-task controls. Directionally consistent; not established. It
echoes EXP-0006's measured finding that the substrate *suppressed* 7 calls of
real verification per arm.

## Confounds closed before any number above was quoted

- **Administered CODE is byte-identical across the two eras.** 26 administered
  paths (24 `build-os/*` dirs + `.claude` + `CLAUDE.md`); `git diff` from both
  the screening-era commit (`0ec110f`) and the r3-era commit (`42a6f09`) to
  `d74a74c` reports no change, and no untracked or ignored file lives inside
  them, so the working tree the harness copies matches the committed tree.
  `queue.json` is tracked and unchanged since `4e65306` — before either era —
  so both eras carried the *same* contaminating content.
- **Acceptance is comparable across all 36 arms.** The adjudicator changed once
  (`3c3348e`, +33/−1, entirely inside condition 2). The new `newElsewhere` is a
  strict subset of the old one, so the change is monotone-permissive: an arm
  that passed under the older adjudicator cannot fail under the newer one. No
  re-adjudication was needed, and none was performed.

## What this does to EXP-0006

It **strengthens** it, which is the opposite of what was predicted when the
contamination was found. The prediction was that EXP-0006's 18.15 vs 10.36 was
no longer a clean estimate of the intended architecture. On this evidence the
contamination was not what made Gravito expensive — removing it moved cost by
2.48× → 2.43× against native, inside the noise. **EXP-0006 stands as measured.**

## What this constrains about LEAN_MANIFEST

**The tax is not the foreign queue.** A lean design cannot claim credit for
removing an administration defect, because removing it bought nothing
measurable. The target is unchanged and still unexplained:

- **1.55× turns**, **2.43× cost**, **2.42× uncached tokens** against native
- of which the largest single component remains **~10.5 text-only turns/arm**
  carrying no tool call at all, which no intervention tried so far has moved

The corrected baseline is frozen as the comparator. It is frozen *knowing* it is
economically indistinguishable from the contaminated one — which is precisely
why a lean build measured against it cannot borrow credit it did not earn.
