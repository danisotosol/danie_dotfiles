# Confidence rubric

Give the English scale below to the scorer subagents **verbatim**. Do not summarize, translate or paraphrase it. The source says to give this rubric to the agent verbatim; the wording of each step is the standard.

One reading changes: the source was written for GitHub pull requests. **Read "the PR" as the change under review (the working-tree diff or the branch diff).**

## Scale (verbatim)

> Score each issue on a scale from 0-100, indicating your level of confidence. For issues that were flagged due to CLAUDE.md instructions, double check that the CLAUDE.md actually calls out that issue specifically. The scale is:
>
> a. 0: Not confident at all. This is a false positive that doesn't stand up to light scrutiny, or is a pre-existing issue.
> b. 25: Somewhat confident. This might be a real issue, but may also be a false positive. The agent wasn't able to verify that it's a real issue. If the issue is stylistic, it is one that was not explicitly called out in the relevant CLAUDE.md.
> c. 50: Moderately confident. The agent was able to verify this is a real issue, but it might be a nitpick or not happen very often in practice. Relative to the rest of the PR, it's not very important.
> d. 75: Highly confident. The agent double checked the issue, and verified that it is very likely it is a real issue that will be hit in practice. The existing approach in the PR is insufficient. The issue is very important and will directly impact the code's functionality, or it is an issue that is directly mentioned in the relevant CLAUDE.md.
> e. 100: Absolutely certain. The agent double checked the issue, and confirmed that it is definitely a real issue, that will happen frequently in practice. The evidence directly confirms this.

## How this scale is used

**Confidence decides only which tag a finding gets, not whether it is reported.** Whether it is reported is decided by the three cuts in SKILL.md (verdict is false / no fix can be written / pre-existing).

Note that the scale **mixes importance into its steps**. 50 is defined as "verified real, **but** maybe a nitpick and not very important in this change", so **a verified, correct, minor finding structurally cannot score above 50**. A flat cut at 80 would therefore wipe out every correct finding that takes a minute to fix, such as "this comment overclaims, soften it" or "this duplicates an existing helper". That is why scorers return a **verdict** (true or false, importance ignored) separately from confidence, and the cuts use the verdict.

The opposite trap exists too. The 25 step means "might be real but could not be verified", so findings that are **real but hard to verify** — concurrency races, rare but reachable paths — tend to land on 25. A cut below 50 would delete the hardest-to-find bugs first. That is why SKILL.md requires scorers to keep confidence consistent with the verdict ("if the verdict is `true`, confidence is not below 50"). The 50 cut is a backstop that shows when verdict and confidence disagree, not an independent cut.

## Source

Step 5 of `commands/code-review.md` in Anthropic's official `code-review` plugin (`claude-plugins-official` marketplace).

Copyright Anthropic, PBC. Licensed under the Apache License, Version 2.0.
<http://www.apache.org/licenses/LICENSE-2.0>

That plugin is not the same as Claude Code's built-in `/code-review`. According to the author of this skill (dim0627/dotfiles), the built-in one does not use the 0-100 score with an 80 cut; it uses a three-way CONFIRMED / PLAUSIBLE / REFUTED verdict. The scale is kept here because a continuous value makes it easier to sort findings into three tags, not to follow the source's cut.
