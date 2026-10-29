---
name: refine-action
description: Drafts proposals for a course of action, has blind critics tear them down, answers and rewrites, and repeats until no new fatal objections appear. Works from an already-diagnosed situation to find a move that is not just symptom relief. Triggers on "refine this plan", "pule esta decisión", "run critics on this proposal".
user-invocable: true
---

# refine-action (iterative refinement of a course of action)

Draft a proposal, have **fresh critics** tear it down, answer and rewrite. Repeat **until no new fatal objections appear**.

The subject is a course of action — what to build, where to intervene. Not the code itself, but the decision made before touching code.

## Why iterate

One round is not enough. The first proposal usually **takes the shape of the symptom just seen**: pulled along by the log or report in front of you, it settles into **symptom relief** that plugs only that spot. Rewritten after criticism, the next proposal reaches one level deeper, but now carries "the side effects of intervening at that deeper level". Only the next round's critic, looking at **the rewritten proposal**, can catch those.

The writer keeps the reasons for writing it that way, so they cannot see their own assumptions. **A fresh critic catches them.** That is the core of the loop; more rounds are not the goal in themselves.

## Four ways this loop breaks

Left alone, self-criticism turns into ritual. Know the failure shapes first.

1. **It rounds off.** Answering every criticism shaves off the proposal's sharp edges one by one, until what is left is a safe plan nobody objects to. Safe plans usually do not work.
2. **It falls to "do nothing" by elimination.** Any proposal that acts has side effects and costs, so criticism always lands somewhere. Doing nothing has zero side effects, zero cost and is fully reversible, so criticism barely lands. Put "do nothing" among the candidates and it gets picked as the survivor once the acting proposals fall one by one.
3. **It swaps instead of polishing.** Throwing proposals away each round and drafting new ones means each gets only one round of criticism. It looks like many rounds, but it is really one batch critique repeated.
4. **Criticism turns into feelings.** "Be more careful" or "there is risk" changes not one letter of the proposal.

## Entry gate

Iterate only **once the current situation is pinned down as fact**. This skill does not diagnose. Iterating without being able to say what is happening, since when and how often means critique and revision both run on imagination, and the more rounds, the more the imagination looks like fact.

If facts are missing, **go get them before iterating** (logs, data, events, issue history). Write down what cannot be obtained as "not obtained", and from then on treat any objection that rests on it as a **bet**.

## Steps

### 1. Fix the problem, the criteria and the baseline

- Write the **problem to solve** in one sentence. The thing to solve, not the symptom
- Choose **2-4 evaluation criteria**: what to optimize and what may be sacrificed
- Write the **baseline**: what actually happens if nothing is done, with frequency and denominator. This is not a proposal but the yardstick every proposal is compared to
- Show these to the user and **get tacit approval. This is the only place to stop.** If the criteria are wrong, every round is wasted, so a cheap check prevents an expensive redo

From here on, criteria and baseline do not move. Adding a criterion midway invalidates every earlier round's judgment.

Decide here, looking at the baseline, whether acting is worth it at all. If it is not, stop before iterating and say so.

**Done when**: the problem statement, criteria and baseline are written and the user has seen them.

### 2. Seed the first proposals

- Draft **3 structurally different proposals**. Make them differ in "which layer they intervene in". All 3 must act
- Bring each down to an **executable level of detail**. "Improve X" cannot be criticized; "remove Y and replace it with Z" can
- A proposal that only adds measurement counts only if it states what the measurement decides (which value sends you which way)

If the user brings a proposal, make it proposal 1 and fill in the rest.

**This is the only place to diverge.** From round 2 on is the polishing phase; do not add new lines of attack, or it will not converge.

**Done when**: 3 acting proposals are written at an executable level of detail.

### 3. Run a round

Each round:

1. **Launch critics in parallel.** One subagent per lens — `Agent` with `subagent_type: "general-purpose"` and `model: "fable"`, told to stay read-only — **all in a single message**. Give each only **the facts of the situation, the baseline, the proposal, the criteria and the ledger**, plus the scope of its lens
2. **Prune the objections** that come back (next section)
3. **Rewrite the proposal** to answer what survives
4. **Update the ledger.** Always record the **aims dropped** this round

**Never give the critics the reasoning that led to the proposal.** The moment you do, they inherit the writer's blind spots, and once the blindness breaks, the whole value of this loop is gone.

Round 1 criticizes all 3 proposals and **narrows to 1** (2 at most if the outcome splits on which criterion wins). From round 2 on, keep fixing that proposal and send **only the lenses that bear on the parts rewritten in the previous round**. Later rounds' hits concentrate there.

**Done when**: results from every lens sent are in, the ledger is updated and the proposal is rewritten.

### 4. Prune

First **drop**. Apply in order; drop at the first match:

1. **Not on the criteria** — an objection tied to none of the fixed criteria. Even if correct, do not raise it when it does not change this decision
2. **No concrete answer can be written** — if you cannot write in one line how the proposal would change, it is a **feeling**, not an objection
3. **Already set aside in the ledger** — the same thing coming back

Grade what remains.

- **Fatal** — the proposal cannot stand. A false premise, does not reach the root, unacceptable side effects, worse than the baseline
- **Hole** — the proposal lives, but cannot be executed until this is filled
- **Ambiguity** — settled by deciding, but not decided yet

How to treat an **objection whose answer erases the proposal's core** depends on the round.

- **Round 1**: treat it as **rejecting the proposal**, not revising it, and move to the remaining proposals. Handling it as a revision is how proposals round off
- **Round 2 on**: do not throw the proposal away; the appearance of a core-erasing objection is itself a reason to stop (section 5). Swapping to another proposal here is swapping instead of polishing

**Done when**: every objection is either dropped or graded.

### 5. Decide whether to stop

Stopping is allowed only **after criticism of the revised version has come back**. Never stop right after a rewrite, before criticizing it. The latest rewrite of the proposal you return must have been through criticism at least once.

Then stop on any of:

- **Zero new fatal objections this round** — known items in the ledger do not count as new
- **Revisions only produce the same kind of change as last round** — a dead end within the criteria
- **From round 2 on, a core-erasing objection appeared** — the limit of this proposal
- **All 3 proposals rejected in round 1** — new lines of attack are needed
- **4 rounds done**

Do not aim for zero fatal objections. **Only check whether they have dried up.** If you stop before they do, say so in the report.

**If you stop with no proposal left, return the remaining fatal objections and what decided them, and hand the decision to act or not to the user**, with the baseline alongside as material.

### 6. Return

Lead with **the loop's progress**, one line per round:

- Which round, which proposal, which lenses (how many)
- Number of new fatal objections and holes
- That round's decision (reject / revise) and the gist of the revision
- The aims dropped that round

The last line gives **why it stopped** (dried up / dead end / core erased / all rejected / round limit) and **whether the latest rewrite went through criticism**.

Then:

- **The proposal** — if it converged, that one. If the conclusion splits on which criterion wins, **present them side by side, still split. Do not force one.** The split is itself decision material. If no proposal survived, the last surviving one and the fatal objection that killed it
- **Comparison with the baseline** — what this proposal changes, and by how much, versus doing nothing
- **Criticism that landed, and how it was answered**
- **Criticism set aside, and why**
- **Rejected proposals, and what decided it**
- **Remaining bets** — unverified premises. Every course of action contains bets

## Critic lenses

Lenses are split because when one reader sees everything, the misses all share one reader's bias.

- **Root vs. symptom** — is it just plugging the symptom in front of you? Enumerate the other symptoms with the same cause and say how many this proposal removes. If only one, it is **symptom relief**
- **Premises** — list what must be true for the proposal to work, and split them into verified and **bets**. A bet at the proposal's foundation is fatal
- **Side effects** — find the other paths sharing what the proposal touches, and say concretely how their behavior changes. "It might have an impact" is not an objection
- **Cost and reversibility** — the real effort, whether it can be rolled back, and if not, what gets locked in
- **Instrumentation** — can you tell afterwards whether it worked? If not, what would you add so you could?
- **Difference from baseline** — say, with real frequency and denominator data, how much harm this proposal removes compared to the baseline. If the baseline numbers themselves disagree with the facts, point that out too

What to require from each critic:

- For each objection, **what happens**, in one sentence
- **Evidence** — which fact of the situation it draws on. Count what can be counted
- **How the proposal changes** — if it cannot be written, do not raise it

Do not let them re-raise objections handed over as already judged.

## Ledger

Carried across rounds. Without it, set-aside objections come back every round and you cannot tell what is new.

Each entry:

- A summary of the objection (precise enough to recognize it as the same one)
- Lens and grade
- Decision (**adopted** / **set aside** / **proposal rejected**) and why
- Which round it is from

Also add one line per round: **the aims this round's revision dropped** — aims the original proposal had that disappeared while answering criticism. **Whether the proposal is rounding off only becomes visible as these lines pile up.** Include this line in the progress report of section 6.

Give the ledger to the next round's critics. **Include adopted items too**, so objections that would undo them without reason do not come in.
