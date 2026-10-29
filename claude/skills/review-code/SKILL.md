---
name: review-code
description: Blind review of a code change. Runs several lenses in parallel, has an independent scorer judge each finding for truth and confidence, drops what is false or not actionable, and sorts the rest into ask / IMO / nits. Targets the working tree, a branch diff, or changes since a given commit. Triggers on "review this", "revisa el código", "find issues". Also usable as a building block from other skills, such as an iterative review driver.
user-invocable: true
---

# review-code (blind review)

Review the change **blind**: as a reader who does not know the author's intent, judging **only from what is written**.

The target is the defects left after static checks go green — code that **does not crash, type-checks, passes lint, and is still quietly wrong**. Leave whatever lint and type checks catch to them; do not look for it here.

One run is one review. Iterating is the caller's job, so rounds and stop conditions are out of scope here.

## Input

Take only these from the caller:

- **Target** — a list of files, or how to get the diff (`git diff <fixed-point>...HEAD` and so on). If none is given, default to both `git diff @{upstream}...HEAD` and `git diff HEAD`, to catch committed and uncommitted changes. With no upstream, fall back to `git diff main...HEAD`. If all are empty, ask what to review.
- **Exclusions** — paths out of scope (`docs/` and so on). **Test files are in scope by default.** If the author asserted with the same assumption, the tests pass and are still wrong. Inverted assertions, asymmetric setup/teardown and deleted cases are exactly the defects this skill hunts.
- **Spec** (if any) — the issue or PRD body, as already-fetched text.
- **Extra focus** (if any) — points to look at especially this time.
- **Judged ledger** (if any) — findings already rejected. Do not raise them again.

Judge only from this input and the code you read from the repository yourself. **Even if you know the history or intent behind the change, do not use it in the review.** Mixing it in inherits the author's blind spots, and once the blindness breaks, the whole value of this skill is gone.

## Steps

### 1. Fix the target and decide how many lenses

If given a diff command, run it and list the target files. Apply the exclusions.

Stop here on failures such as a ref that does not resolve or an empty diff. Do not discover them after the lenses are out.

Count the diff with `git diff --shortstat` and decide the number of lenses:

- **Under 200 lines and under 6 changed files** — one agent per Group A lens, and **one agent for all of Group B together** (6-7 agents)
- **Otherwise** — one agent per lens in both groups (10-11 agents)

Group B is bundled for small diffs because with little to read, one reader can keep every Group B concern in view.

**Done when**: the target files and the number of lenses are decided.

### 2. Run the lenses in parallel

For each lens, launch one `Agent` with `subagent_type: "blind-reviewer"` and `model: "fable"`, **all in a single message**. Give each agent the target, exclusions, spec, extra focus, ledger, and the scope of its lens.

Lenses are split because when one reader sees everything, the misses all share one reader's bias. Splitting the scope widens the net.

Give every lens **all** changed files. Small files (hooks, thin wrappers, config) tend to get skimmed, but that is where findings like "disagrees with its sibling file in the same diff" or "bypasses the shared helper" show up.

Each lens returns at most 6 candidates (10 for the bundled Group B agent). If it finds more, it picks the ones with the most concrete failure scenario. **Anything whose failure scenario fits in one sentence goes in, even without certainty.** Dropping is the next stage's job, and whatever is dropped here never even gets scored.

#### Group A

- **Line scan** — read each diff hunk line by line, then read the whole function containing the hunk. **Inside a touched function, bugs on unchanged lines are in scope**: the diff made that path run again, so treat them as part of this change. For each line ask: "with what input, state, timing or platform is this line wrong?" Inverted conditions, off-by-one, null/undefined access, missing `await`, falsy 0, swapped variables, swallowed errors in `catch`, unescaped regex metacharacters.
- **What disappeared** — for each line the diff removed or replaced, name the invariant or behavior it protected and find where the new code re-establishes it. If you cannot find it, it is a candidate. Removed guards, dropped error paths, loosened validation, cases a deleted test covered.
- **Ripple** — Grep every caller of each changed function, type or signature and look for calls that now break. New preconditions, changed return shape, new exceptions, new ordering or timing dependencies. Ask the same of the callees.
- **Claim vs. behavior** — for each output (value, event, return value, field, state), derive the meaning its name, type and comments declare, then follow the execution path and check it really takes that meaning. Fields that only ever return a constant, events that fire on unintended paths, return values whose behavior drifts from their name. These are behavior problems, not naming problems; the name is only the yardstick.
  - **Reason from the end state the change intends, not only from the current state.** If the diff or an in-repo runbook or migration guide declares "after this, things look like X", trace each path again with that state as input. Looking only at whether today's data breaks finds only issues that vanish once the premise is met; the paths that break only once the premise is met are the ones most often missed.
- **Conventions** — places that violate rules written in the repo's `CLAUDE.md` / `AGENTS.md` / `CONTRIBUTING.md` and similar. **Raise it only when you can quote both the rule and the line that breaks it.** Skip anything lint already enforces.
- **Spec match** (only when a spec is given) — what the spec requires and the code lacks or does halfway, what is in the code but not required, what was meant to be implemented but drifts. Quote the spec text in each finding.

#### Group B

- **Language traps** — pitfalls specific to the diff's language or framework. JS: falsy 0, `==` coercion, loop variables captured by closures. Python: mutable default arguments, late binding. Rust: `unwrap`/`expect` on fallible paths, integer overflow that wraps silently in release builds, truncating `as` casts, `unsafe` blocks whose invariants the change no longer upholds. Solidity: reentrancy (checks-effects-interactions), unchecked low-level `call` return values, rounding direction in share/asset math, `tx.origin` auth. Anywhere: SQL injection, timezone/DST drift, float equality. If a wrapper type (cache / proxy / decorator / adapter) was added or changed, check that every method delegates to the wrapped target; going back through a registry or session can re-enter and recurse.
- **Comments vs. code** — do comments, doc comments, type definitions and enum annotations match the code's current behavior? Places where the code was fixed and only the comment stayed old.
- **History** — `git blame` on the changed lines and the review comments of past PRs that touched them. Why it was written that way, and whether something flagged before is coming back.
- **Duplication and leftovers** — does the new code reimplement something the repo already has? Grep the shared/utility modules and the files next to the change. Also dead code the diff left behind.
- **Depth** — does the fix address the root cause at the right depth, or put a bandage on the symptom? Special cases stacked on shared infrastructure are a sign of insufficient depth. If a simpler, more general change exists lower in the mechanism, name it.

**Done when**: results from every lens are in.

### 3. Merge candidates

Merge candidates that point at the same line and the same mechanism into one. **Keep the one with the most concrete failure scenario.** If they only point at the same line for different reasons, keep both as separate findings.

Skipping this step means launching several scorers for the same defect.

**Done when**: the candidate list has no duplicates.

### 4. Score each finding

For each remaining candidate, launch one `Agent` with `subagent_type: "blind-reviewer"` and `model: "fable"` **per finding**, in parallel. The finder never scores its own finding. Run at most 20 scorers at once; split into waves beyond that.

Give each scorer: the finding, the target, the paths of the convention files, and the scale in `references/rubric.md` **verbatim**. Do not show the scorer the cutoffs. Have it return exactly these four:

1. **Verdict** — is the claim factually correct? (`true` / `partly true` / `false`). **Ignore importance.** "Real but trivial" is `true`.
2. **Confidence** — 0-100 on the rubric scale. **Keep it consistent with the verdict.** If the verdict is `true`, it is not below 50. The same holds for `partly true` when a fix can be written from the true part alone. Use 25 or less only when it could not confirm whether the finding is real.
3. **Fix** — one concrete change that addresses the finding. A one-line diff or "delete this sentence" is fine. **If none can be written, write "none".**
4. **Causality** — `created by the diff` / `diff made existing text false` / `same before the diff`. **Inside a function the diff touched, bugs on unchanged lines count as `created by the diff`.**

**If it is rare but reachable, lean `true`.** Concurrency races, rare paths such as error handlers, cold caches or missing optional fields, falsy 0, off-by-one at a boundary, partial failure on retry — if that state can really happen, treat it as real. Give `false` only when the code shows it: you can quote the line and show the claim is wrong, you can show it is impossible from types, constants or invariants, it is already handled in this diff (quote the guard), or it is pure style with no observable effect.

The fix is required because the same observation is worth different amounts depending on how it is phrased. "The guard cannot guarantee uniqueness" is too big to act on; "this comment's claim is false, soften it" takes a minute. Scored in the first form, a fixable finding disappears as "not important".

Causality goes to the scorer because **this is the judgment intent softens most**. Someone who knows the history and rules "it was always like that" drops problems the diff itself introduced as pre-existing.

**Done when**: every finding has a verdict, confidence, fix and causality.

### 5. Prune

First **drop**. Apply in order; drop at the first match:

1. Verdict is `false` — not reported.
2. **Fix is "none"** — something that does not turn into action is an opinion, not a finding.
3. **Causality is `same before the diff`** — when the diff made existing text false (a comment or doc that was right before the change and wrong after), the causality is `diff made existing text false`, so it stays.

Tag what remains. The drop criteria and the tag criteria are different: **confidence decides only which tag, not whether to report**.

- `ask:` — confidence 80 or more. Involves a design decision or spec question and needs the author's answer.
- `IMO:` — confidence 50 or more. Worth fixing in the reviewer's view, but the author may decide to skip it.
- `nits:` — confidence 50 or more and a fix of a few lines. Duplication of a shared helper, overclaiming comments, naming. **Do not drop it for being minor.** If the fix takes a moment, reporting it pays.

Below 50 confidence, do not report even when the verdict is `true`. If step 4's consistency rule was followed, almost nothing lands here; if something does, treat it as a sign the scoring split.

If nothing remains, say so. Do not lower the bar to have something to report.

**Done when**: every remaining finding has a tag, and the dropped findings are counted by reason.

### 6. Return

Order by `ask:` → `IMO:` → `nits:`, and by confidence within a tag. For each finding:

- Tag (`ask:` / `IMO:` / `nits:`)
- `file:line`
- What happens (one sentence)
- Evidence (quote; cite the source when quoting a convention or spec)
- Reproduction steps, or a concrete "with this input or state, it becomes this value"
- **Fix** — what to change and how; as a diff when possible
- Confidence and the lens it came from

End with one line giving **the number of dropped findings and why** (false / no fix / pre-existing / merged as duplicates), so the caller can judge whether the bar is right.
