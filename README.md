# Project Bible

A working set of architectural principles, hygiene rules, and AI-collaboration
patterns to apply at the **start of every project** — before the codebase
gets complex enough that bad foundations become expensive to fix.

These are not theoretical. Every rule here was earned by something going
wrong in a real project. Cross-references to anti-patterns and industry
names are deliberate — they're search handles for going deeper.

---

## 0. Philosophy

Three sentences that everything else hangs from:

1. **The cheapest bug is the one a type system catches; the next cheapest
   is the one a test catches; the most expensive is the one that runs
   silently and only surfaces when the output is incoherent.**
2. **Working with an LLM is like working with a fast, capable, talented
   junior engineer who has no memory between sessions.** They need
   scaffolding (memory files, CLAUDE.md, plan mode, task lists) to stay
   coherent across time. Without it, they drift.
3. **The friction of a small architectural change today is always
   smaller than the friction of unwinding the architectural debt of
   skipping it.** SSOT, types, tags, small commits — they feel like
   overhead at the start. They are not overhead. They are the project.

---

## 1. Day-0 Checklist

Do these on the day a project is created, before any feature code is
written. Each item takes < 15 minutes. Together they save weeks.

### 1.1 Version control
- [ ] `git init` (or clone). Default branch is `main`.
- [ ] First commit is a `README.md` describing what the project IS in
      one paragraph. Future-you needs this; so does Claude in session 50.
- [ ] `.gitignore` populated for the languages/tools in use, plus a
      block for local working artifacts (`outputs/`, `dist/`, `.env`,
      `*.local`).
- [ ] `git tag -a project-start -m "Project bootstrapped"`. Every
      project gets a baseline bookmark.

### 1.2 CLAUDE.md (project memory)
- [ ] Create `CLAUDE.md` at the project root. This file auto-loads at
      every Claude Code session start.
- [ ] First section: **"What this project is"** — one paragraph, same
      as README but framed for an AI agent.
- [ ] Second section: **"Locked decisions"** — anything explicitly
      ruled in or out. Style, tech stack, scope. Stops re-litigation.
- [ ] Third section: **"How I want to work with you"** — terseness,
      commit cadence, when to ask vs. when to act.
- [ ] Keep CLAUDE.md under 150 lines. Beyond that, Claude's auto-truncation
      kicks in and load-bearing rules get clipped.

### 1.3 Permission posture
- [ ] Create `.claude/settings.json` with `"defaultMode": "plan"` if the
      project is one where you can't review every line in real time.
      Plan mode forces a propose-before-act loop.
- [ ] Add `permissions.deny` for paths Claude should NEVER touch
      automatically (production data files, secrets, deployment scripts).
- [ ] If the project has destructive operations, add a `PreToolUse` hook
      that blocks `Bash` calls matching `rm -rf|git push --force|git reset --hard`
      unless you've explicitly approved.

### 1.4 SSOT scaffolding
- [ ] Create a `shared/` (or framework-equivalent: `src/lib/config`,
      `_shared/`, etc.) directory. **Empty is fine.** Its existence is
      the architectural commitment.
- [ ] Add `shared/README.md` (or a comment in the first file) that
      explains: "Anything that appears in more than one place goes here."

### 1.5 Memory pre-flight
- [ ] If using Claude with persistent memory, create a project pre-flight
      memory file documenting the load-bearing creative or architectural
      surfaces. Pattern: name the 5–10 files an AI must read and audit
      for consistency before touching anything creative.

---

## 2. Single Source of Truth (SSOT)

### 2.1 The rule
Any fact that appears in two places is a bug-in-waiting. The two copies
will drift. When they drift, the system breaks silently — code runs,
output is wrong.

### 2.2 What goes in SSOT
- **Config**: URLs, API keys (or key references), provider IDs, model
  names, magic numbers (`MAX_X`, `RETRY_COUNT`, `TIMEOUT_MS`).
- **Domain language**: type definitions, schema shapes, enum values.
- **Creative direction** (for projects that have one): style guides,
  brand voice, tone rules — anything an LLM prompt embeds.
- **Cross-cutting utilities**: base64 encoders, date formatters, error
  shapes — any helper that gets reimplemented in 3+ files.

### 2.3 What does NOT go in SSOT
- Business logic specific to one consumer.
- Anything used by exactly one file, ever. Premature abstraction is
  also an anti-pattern (Sandi Metz: "duplication is far cheaper than
  the wrong abstraction").
- Anything that "might be reused someday." Move things to SSOT when
  the second use case appears, not before.

### 2.4 The anti-pattern this prevents
**Shotgun surgery** (Martin Fowler, *Refactoring*): a single conceptual
change requires edits in many scattered places. Symptoms: changing
"we now use model X" turns into a grep-and-replace across 12 files,
some of which are comments that mislead the next reader.

### 2.5 The deeper goal
**Make illegal states unrepresentable** (Yaron Minsky, *Effective ML*).
If your types literally cannot express the wrong shape, the wrong
shape can't happen. Strong types + SSOT + integration tests turn whole
classes of bugs into compile errors.

---

## 3. Version Control Hygiene

### 3.1 Commits
- **One concern per commit.** A commit fixes one bug, or adds one
  feature, or refactors one thing. Never "fix bug X and also some
  cleanup."
- **Subject line as search bait.** Write commit subjects as if you'll
  be `git log --grep`-ing for them in 6 months. Use distinctive nouns.
- **Body explains WHY, not WHAT.** The diff shows what changed. The
  body explains why this change, why now, what alternatives were
  rejected.
- **Co-authored-by** lines for AI assistance. Honest provenance helps
  future debugging.

### 3.2 Tags as bookmarks
- **`project-start`** on the first commit.
- **`hard-pivot-N`** before each major architectural turn. Annotated,
  with a body explaining the diagnosis and the next direction. Lets
  you `git checkout hard-pivot-3` to inspect any historical state.
- **`v0.1.0`, `v0.2.0`...** for shippable milestones. Even if there's
  no semver semantics — tags are just bookmarks.
- Tags are **local until pushed**. Move them freely while local;
  treat them as immutable once shared.

### 3.3 Branches
- For solo projects, prefer **trunk-based development**: one main
  branch, small commits, rare branches. Branches are for parallel
  AI subagent work or genuinely risky experiments.
- When you do branch, **rebase before merge** (linear history is
  easier to reason about) UNLESS the branch represents a logical
  unit you want preserved as a merge commit.

### 3.4 Deletions
- **Delete with intent.** Every removal references the commit/tag
  where the deleted code last existed and why it's superseded.
- **Git is the archive.** The working tree is for what's load-bearing
  NOW. Don't keep dead code "just in case" — it carries cognitive cost
  forever.
- Recovery pattern: `git log --all --full-history -- <path>` finds any
  file's history even after deletion. Then `git show <sha>:<path>`
  reads it back.

### 3.5 The mental model
Git is **a structured journal of every state the project has ever
been in**, queryable by content, time, author, message, and file. You
don't memorize SHAs. You learn the search vocabulary:
- `git log -S "<string>"` — pickaxe, find commits that touched a string
- `git log --grep "<text>"` — search commit messages
- `git log --since="2 months ago"` — search by time
- `git log --all --full-history -- <path>` — find deleted files

---

## 4. Working with AI (Claude Code, specifically)

### 4.1 The failure modes to design against
1. **Drift mid-task.** AI sees something "interesting" and rabbit-holes.
2. **Context compaction.** Long sessions auto-summarize; detail blurs.
3. **Multi-session amnesia.** Between sessions, conversation context is gone.
4. **Sycophancy.** AI tends to agree; needs to be pressure-tested.
5. **Hallucinated authority.** AI summaries sometimes confidently describe
   things that didn't actually happen. Verify against the artifact.

### 4.2 The mechanisms that mitigate each
1. Drift → **TaskCreate / task lists**, visible to both sides, status
   updated as each step lands.
2. Compaction → **Small commits with clear messages.** Git history is
   the fallback when in-session memory blurs.
3. Multi-session → **Memory files + CLAUDE.md + plans on disk.**
   Anything that needs to survive sessions must be in a file.
4. Sycophancy → Explicit instruction: "pressure-test before agreeing.
   Argue the 'we don't need this' side first." Save as a feedback memory.
5. Hallucination → **Trust but verify.** Read the actual file/diff/output,
   not the AI's summary of it. In multi-stage pipelines, treat each stage's
   output as a claim to verify before passing downstream.

### 4.3 Plan mode
For any non-trivial change, use plan mode: AI proposes, you approve,
then AI executes. The propose step costs nothing and catches scope
mismatches before code is written. Set as project default via
`.claude/settings.json`.

### 4.4 Subagents
Use a subagent when:
- A task is genuinely independent of what you're doing on main thread
- The task involves heavy research/exploration that would clutter main context
- You want isolation so a risky change doesn't disturb working code

Run subagents in **worktrees** (isolated git checkout). They commit on
a branch; you review and merge. No conflicts because the branches are
genuinely isolated.

### 4.5 Mentor mode
Configure the AI to **teach as it works**. Name principles, surface
trade-offs, connect to industry-standard terminology, link to anti-pattern
names. The collaboration is paired engineering, not task offloading.
Win condition: you read diffs with more confidence each week and start
catching things the AI misses.

### 4.6 What NOT to delegate
- **Architectural decisions** — name them yourself, even if the AI
  proposes options. The AI should expand your menu, not replace your
  judgment.
- **Understanding** — never write "based on your findings, implement it."
  That phrase outsources synthesis. Read the findings, then write specific
  instructions referencing files and line numbers.
- **Trust boundaries** — what gets pushed to production, what runs with
  elevated permissions, what touches user data. Always your call.

---

## 5. Pipeline & Architecture Rules

### 5.1 Convergence over divergence
If two code paths produce conceptually the same thing (UI flow + CLI
flow, dev flow + prod flow), they should **call the same functions**.
The moment they diverge, you're maintaining two systems. The moment
the user notices a behavior difference, you have a bug in one or both.

### 5.2 Read source, not summary
In any multi-stage pipeline — especially LLM pipelines — verify
against raw ground truth at each stage. The summary at stage N+1 is
not the same artifact as the output of stage N. If stage N has a bug,
every downstream stage carries the error forward, and the final summary
looks plausible but is wrong.

### 5.3 Don't rewrite from scratch
**Joel Spolsky, *Things You Should Never Do, Part I* (2000).** Code
is where bug fixes live. Every weird edge case has a story; a rewrite
discards all of it and re-discovers them the hard way. Rewrites
inflate 2-5x in time and introduce bugs the original had solved.

The disciplined alternative: **salvage with discipline.** Add the
foundation that should have been there as a layer ON TOP of existing
code, then bring existing files into alignment one at a time. Small
commits, each reversible.

### 5.4 Types as contracts
A type isn't "this is a string" — it's a promise between the function
that produces a value and the function that consumes it. **The more
precise your types, the more bugs become structurally impossible.**

TypeScript adds *static* type checking on top of JavaScript's *dynamic*
weak typing. The cost: a build step (or a `// @ts-check` JSDoc comment
on plain JS). The benefit: classes of bugs disappear at compile time.

For any project with >3 modules talking to each other, the type-system
overhead is worth it.

### 5.5 One responsibility per file
A file that does two unrelated things will get edited for two unrelated
reasons, by two different agents (you, AI, future-you), at two
different times. Each edit risks breaking the other concern.

The principle: **separation of concerns** (Dijkstra). The signal that
it's violated: you find yourself describing a file with "and" in the
middle. "This file handles auth AND parses URLs." Split it.

---

## 6. Code Hygiene

### 6.1 Comments
- **Default: write none.** Well-named identifiers do the work.
- **Exception: WHY, not WHAT.** Subtle invariants, workarounds for
  specific bugs, hidden constraints. Things that would surprise a reader.
- **Never write what the code does.** "Increments counter by 1" tells
  no one anything they didn't already see.
- **Never reference the current task in code.** "Used by feature X",
  "added for ticket Y" — that belongs in the PR/commit description.
  It rots in code.

### 6.2 Naming
- **Same concept → same name everywhere.** If one file calls it `user`
  and another calls it `account`, the cognitive link drops. Either
  rename one or document the distinction.
- **Boolean: prefix with `is_`, `has_`, `should_`.** `is_active`
  reads correctly in conditionals; `active` is ambiguous.
- **Function names are verbs; types are nouns; predicates are
  questions** (`is_valid`, not `validate` — those mean different things).

### 6.3 Dead code
- If it's not imported, called, or executed, **delete it**.
- "Just in case" is rarely true. The code you'll need someday is
  usually different from the code you saved.
- Anything you genuinely want to preserve goes in `archive/` with a
  README explaining context, OR lives only in git history. Both
  acceptable.

### 6.4 Tests
- **Integration tests catch the most expensive bugs.** Unit tests
  catch the cheapest. Allocate test effort accordingly.
- A single end-to-end test that runs the real pipeline is worth more
  than 50 mocked unit tests.
- Tests that test mocks are not tests. They test the mocks.

---

## 7. Memory & Persistence (Claude Code-specific)

### 7.1 Three layers, three purposes
1. **CLAUDE.md** (project memory, in-repo, version-controlled).
   Loaded automatically every session. Per-project rules, locked
   decisions, working agreement.
2. **Auto memory** (Claude's notes, per-user, not in repo).
   Cross-session preferences, working habits, mistakes-not-to-repeat.
   Indexed by `MEMORY.md`.
3. **Plans** (in-conversation, not durable). For single-session work.
   When work spans sessions, promote the plan to a `docs/<plan>.md`
   file.

### 7.2 What goes where
- "My team uses TypeScript with strict null checks" → user memory.
- "This project's locked art direction is X" → CLAUDE.md (project memory).
- "I'm working on feature Y this week" → conversation only.

### 7.3 Memory hygiene
- **Update memories when reality changes.** Stale memories actively
  mislead. Worse than no memory.
- **Reference the source.** When a memory says "use library X," include
  WHY (the alternative, the rejected option, the constraint that drove
  the choice). Future-you needs to know whether to revisit.
- **Use `[[wiki-style-links]]` between memories** so related rules
  surface together when one fires.

### 7.4 The pre-flight pattern
For projects with high-stakes load-bearing surfaces (creative direction,
API contracts, schema shapes), write a "pre-flight check" memory:
- List the 5-10 files an AI must read before touching anything creative
- For each, name the specific conflicts to watch for
- Reference the locked direction explicitly so it can't be re-litigated

This is the single highest-leverage memory file. It catches drift
before the AI does any damage.

---

## 8. When Things Go Wrong

### 8.1 Identify the failure type
- **Silent wrong output?** Bug in the pipeline. Walk it stage by stage,
  read each stage's output as ground truth.
- **Loud crash?** Read the stack trace. Find the exact line. Fix that
  line, not the surrounding code.
- **AI keeps drifting?** Add a feedback memory naming the drift pattern,
  or strengthen CLAUDE.md, or switch to plan mode for the rest of the
  session.
- **Codebase feels tangled?** Don't rewrite. Identify the SSOT layer
  that's missing; add it; bring existing code into alignment one
  file at a time.

### 8.2 The rollback toolkit
- `git checkout <tag>` — explore any historical state read-only.
- `git restore --source=<sha> <path>` — bring one file back to a
  prior state without disturbing the rest.
- `git revert <sha>` — make a NEW commit that undoes a prior one
  (preserves history; safer than reset).
- `git reset --hard <tag>` — destructive; nukes commits since the
  tag. Only use when local-only and you're sure.

### 8.3 The pivot pattern
When something is fundamentally not working:
1. **Stop coding.** Diagnose first.
2. **Tag the current state** (`hard-pivot-N-prep`) so it's recoverable.
3. **Write down the diagnosis** as a commit body or design doc.
4. **Propose the new direction** explicitly. Get buy-in (from yourself
   in a solo project, from collaborators otherwise).
5. **Execute small commits**, each independently reversible.
6. **Tag the new state** (`hard-pivot-N`) when stable.

The whole sequence becomes searchable later via `git log --grep="HARD PIVOT"`.

### 8.4 The "I told the AI X but only Y changed" pattern
This means the architectural decision wasn't applied to all the places
it should have been. The fix is structural, not procedural:
- Move the contested fact into SSOT.
- Refactor existing files to read from SSOT.
- Future changes touch one file.

The procedural fix (telling the AI "and update all files") is fragile
and recurring. The structural fix (SSOT) makes it impossible to forget.

---

## 9. The North Star

**Every architectural decision should make the next decision easier.**

If a refactor today means you can ship faster next week, do it. If a
type system overhead today means a class of bugs becomes impossible
forever, do it. If a `shared/config.js` today means swapping providers
is a one-file change, do it.

The instinct to skip foundation work to ship faster is almost always
wrong. The instinct to skip features to nail foundation is also wrong.
The discipline is to **invest in foundation in proportion to how often
you'll lean on it**. Used often = foundation; used rarely = skip the
abstraction.

---

## 10. Apply This At Project Start

Open this file. Walk Section 1 (Day-0 Checklist) before writing feature
code. Reference Sections 2-7 when the relevant question arises. Use
Section 8 when things go wrong.

The bible grows. When you learn a new principle the hard way, add it
here. When a principle stops being load-bearing, prune it. This is a
living document, not a contract.

---

## Appendix: Industry Terms Worth Knowing

These are search handles. When something in your project resembles one
of these, you can find decades of literature on how to handle it.

- **Single Source of Truth (SSOT)** — one canonical place per fact.
- **Shotgun surgery** — anti-pattern: one change requires many edits.
- **Magic numbers / magic strings** — literals that should be named constants.
- **Make illegal states unrepresentable** — type-system discipline.
- **Type-driven development** — design types before logic.
- **Separation of concerns (Dijkstra)** — one responsibility per module.
- **YAGNI** — "You Aren't Gonna Need It." Don't build for hypothetical futures.
- **DRY** ("Don't Repeat Yourself") / **WET** ("Write Everything Twice") —
  duplication is a smell, but premature abstraction is worse.
- **Joel Spolsky's "Never Rewrite"** — salvage over rewrite, always.
- **Trunk-based development** — one main branch, small commits, rare branches.
- **Pickaxe search** (`git log -S`) — find code by content, not filename.
- **Annotated tag** — git bookmark with a message body.
- **Plan mode / propose-before-act** — AI proposes, human approves, AI executes.
- **Pre-flight check** — read load-bearing files for consistency before editing.
- **Trust but verify** — agent describes intent, not necessarily what landed.
- **Sycophancy** — LLM tendency to agree; design against it.
- **Hallucinated authority** — LLM confidently describes things that didn't happen.
- **Pressure-testing** — argue the opposing side before agreeing.
- **Worktree isolation** — parallel branches without disturbing main checkout.
- **Linear history** — rebase-then-merge for cleaner reasoning.
- **Search bait** — commit messages written to be findable via grep.
