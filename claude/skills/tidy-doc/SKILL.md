---
name: tidy-doc
description: Inventories staleness in a long document (GitHub issue or in-repo Markdown such as a README or docs/) and proposes a cleanup. Triggers on "tidy this doc", "ordena el README", "is this issue outdated?".
user-invocable: true
allowed-tools: Bash(gh issue view*), Bash(gh issue edit*), Bash(gh pr view*), Bash(gh api repos*), Bash(git log*), Bash(git show*), Read, Edit, Grep, Glob
---

Inventory the **staleness** left in a long document that grew by local additions. Only content consistency is fixed; formatting such as heading levels or emoji is out of scope.

## Steps

### 1. Fetch

Tell the backend from the argument (URL / number / file path) and fetch the whole body and all comments. If nothing matches, ask the user.

| Backend | Pattern | Fetch |
| --- | --- | --- |
| GitHub issue | `github.com` URL / `owner/repo#N` / `#N` / bare number | `gh issue view <ref> --json number,title,body,url` + `gh issue view <ref> --comments` |
| Markdown | path to a `.md` file | `Read` |

### 2. Inventory

Apply 4 lenses to every section.

- **🔁 Duplicates**: the same fact appears in more than one place
- **🔢 Numbers**: counts disagree between the summary, body, recommended steps and so on (e.g. summary "13 minor" / body "12 minor")
- **📅 State**: the timeline contradicts itself ("Phase A planned" next to "Phase A done"), or text whose job ended with a finished step is still there
- **📛 References**: mentions of PRs, commits, files, functions or comment IDs that no longer match reality. This lens compares the document with the outside world, so check each mention against the real thing one by one with `gh pr view` / `git log` / `git show` / `Glob` / `Grep`

Settle each disagreement with the **source of truth**: for numbers, a recount of the detailed section; for state and references, the result of checking the real thing. Items with no clear source of truth go to ❓ Needs confirmation.

Done when: every section has been through the 4 lenses and every 📛 mention has been checked against the real thing.

### 3. Present the cleanup plan

Omit lenses with no hits. Give each item its **evidence** (the recount, the PR state, the commit and so on).

```markdown
## 🧹 Document cleanup plan

**Target**: [title] (URL or path)

**🔁 Duplicates**
- Sections X and Y both say "○○ done" → merge into X, remove from Y

**🔢 Numbers**
- Summary "13 minor" / detail "12 minor" → recounting the detail gives 12 → use 12

**📅 State**
- "Phase A planned" next to "Phase A done" → keep "done"
- TODO list from before phases 1-3 → phase 3 is done → remove

**📛 References**
- "PR #XXX OPEN" → merged (commit abc123) → update to "merged"

**❓ Needs confirmation**
- [disagreements with no clear source of truth, and what is needed to decide]

Proposed diff:
[before / after per item]
```

After presenting, wait for the user's approval. Misjudgments are possible, so apply only the approved items.

### 4. Apply

Rewrite only the approved spots and leave all other text and structure as it was.

| Backend | Write back |
| --- | --- |
| GitHub issue | `gh issue edit <number or URL> --body-file <temp file>` (comments: `gh api repos/{owner}/{repo}/issues/comments/{id} -X PATCH -f body=...`) |
| Markdown file | `Edit` |
