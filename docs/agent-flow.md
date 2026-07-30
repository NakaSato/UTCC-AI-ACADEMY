---
---

# Working with agents on this repo

**Tags:** [#agents](tags.md#agents) [#process](tags.md#process) [#verification](tags.md#verification)

**The scarce resource is verification, not implementation.** This project is already built this way — 46 commits, every one on `main`, one human, and an agent doing most of the typing. Nothing below is a plan to adopt agents; it is the operating discipline for a repo that already runs on them, and the honest account of which parts of it are load-bearing and which are missing.

> **What is written down here is what is true or immediately doable.** Where the canonical design calls for machinery this repo has no place to put — an admission controller, auto-merge tiers, a Slack review queue, canary analysis — it is listed in §8 as *not adopted*, with the reason. A gate described but not enforced is worse than no gate, because it is cited as though it ran.

## 1. What is already true

| | Here |
| --- | --- |
| Branching | trunk-based — one branch, `main`, no merge commits in 46. The only pull requests the remote has ever had are four from Dependabot, all closed unmerged |
| Work item size | 1–8 files, 50–250 lines a commit, one stated purpose each |
| Review | one person reads the diff; there is no second reviewer to escalate to |
| Gate 1 (self-verify) | `bin/verify` — documentation checks, RuboCop, Brakeman, `bundler-audit`, `importmap audit`, the suite, the seed replant, and system tests |
| Gate 2 (policy) | `.github/workflows/ci.yml`, the same steps on a clean runner. Independent of whoever wrote the change — but it runs **after** the commit is pushed, not before |
| Gate 3 (human) | reading the diff, and it is the **last** gate |
| Gate 4 (progressive delivery) | **absent** — no canary, no feature flags, no monitoring, no rollback path |
| Spec | the checked format is active under `docs/specs/`; no behavior spec has been required yet |
| Agent attribution | **3 commits of 46** carry a `Co-Authored-By` trailer |

Two of those rows are the whole risk profile of this project.

**Gate 3 is the last gate.** In a flow with progressive delivery, review is one of several nets and can afford to miss things. Here there is nothing after the commit: no canary to burn, no flag to switch off, no alert to fire. Whatever the reader of the diff does not catch reaches whatever is deployed and stays there until a person notices. That is the argument for §5's tiering — not process hygiene, but the fact that the last net is a tired human at 11 p.m.

**The agent writes both the implementation and the tests**, which is precisely the separation the canonical design forbids: whoever writes the acceptance criteria must not be whoever writes the code, or the work optimises for passing rather than for being right. With one human, that separation cannot be staffed. What compensates is §4 — the human owns the **invariant list**, in prose, in `CLAUDE.md`, and an agent-written test is checked against it rather than trusted on its own. It is a weaker guarantee than the real thing and should be named as such rather than assumed away.

## 2. The states that actually exist

No PR, so no `REVIEW_QUEUE`, no `AUTO_MERGE`, no `CANARY`. What is left is short:

```
INTENT ──▶ AGENT_BUILD ──▶ bin/verify ──▶ HUMAN_READS_DIFF ──▶ COMMIT
              │  ▲            │              │
              │  └────────────┘              └──▶ REWORK ──┘
              ▼
        AGENT_BLOCKED ──▶ (a person decides) ──▶ AGENT_BUILD
```

Three rules hold this shape, and only the third is currently automatic:

1. **Nothing reaches `COMMIT` without a human reading the diff.** With Gate 4 absent this is not a preference.
2. **`AGENT_BLOCKED` never times out into a guess.** See §6.
3. **Repeated Gate 1 failure is a spec problem, not a code problem.** An agent that cannot get `bin/verify` green in a few passes is usually being asked for something under-specified — the fix is upstream, in what was asked for, not another attempt.

## 3. Gate 2 is independent now, but it runs late

`bin/verify` (which delegates to `bin/ci`) and `.github/workflows/ci.yml` enforce the same policy, and the difference between them is the whole point: an agent that runs the local one is reporting on itself, and the workflow is a machine that did not write the code checking the code on a clean runner. That closes the hole where an agent could decide not to run the local gate, or run it and paraphrase the result.

**What it does not close is the ordering.** With no branches and no pull requests, the workflow fires on `push` — so it verifies a commit that is already on `main`. It catches a red build; it cannot prevent one. Two things follow:

- **The human still runs `bin/verify` themselves before committing anything in Tier B or C.** One command, and it is what keeps `main` green rather than merely observed.
- **A red run on `main` is owned by whoever pushed it**, immediately — there is no branch to leave it on. `docs/slack.md` is why one message goes to a channel when that happens, and why nothing is posted when a run is green.

This is the strongest argument in this document for eventually working on a branch: a workflow that runs on a pull request is a gate, and the same workflow on `push` is a smoke alarm.

## 4. The fitness functions this repo already has

**A rule not written as a test does not exist.** This project is unusually strong here — several of its invariants are already enforced by a test that fails rather than by a convention someone remembers:

| Invariant | Enforced by |
| --- | --- |
| A screen's query count does not grow with the cohort | `test/models/query_budget_test.rb` |
| The positional locale arrays stay the same length and order in both languages | `test/models/placeholder_content_test.rb` |
| `script-src` never gains `unsafe-inline`, and every inline script carries the nonce | `test/controllers/content_security_policy_test.rb` |
| A role posted through a form never sticks | `registrations_controller_test.rb`, `profiles_controller_test.rb` |
| The lazy frame never learns to fetch itself forever | `test/controllers/leaderboard_frame_test.rb` |
| Every mutating admin action records exactly one audit row | `test/controllers/admin_audit_test.rb` |
| A broadcast carries no copy and no CSRF token | `test/models/notification_bell_test.rb` |
| Student ID and profile PII never reach a log line | `test/controllers/log_filtering_test.rb` |

That table is the registry the canonical design builds with ArchUnit. **The "Invariants" section of `CLAUDE.md` is its index**, and the rule that keeps it honest is: an invariant added to that list without a test named beside it is a comment, and an agent will violate it inside a week. When an agent proposes a change that touches one of the rows above, the test in the right-hand column is the thing to run first and read hardest.

## 5. Risk tiers, computed from paths

Tiering is not ceremony here; it is how one person decides where to spend the attention that is the actual bottleneck. **Compute it from the paths a diff touches, never from the agent's own description of what it did.**

| Tier | Paths | What the reader owes it |
| --- | --- | --- |
| **C — critical** | `app/controllers/concerns/authentication.rb`, `authorization.rb`, `app/models/user.rb`, `session.rb`, `app/models/lesson_content.rb` (the grading key and `CHECKS`), `app/controllers/admin_controller.rb`, `db/migrate/**`, `config/initializers/**`, `config/deploy.yml`, `render.yaml`, `Dockerfile` | read every line; run `bin/verify` yourself; re-read the matching invariant in `CLAUDE.md` before agreeing |
| **B — standard** | everything else under `app/`, `lib/`, `config/routes.rb`, `db/seeds.rb`, **and `config/locales/*.yml`** | read the diff; run the affected test file |
| **A — low** | `docs/**`, `README.md`, `*.md`, screenshots | skim; correctness here is a claim about the repo, so check the claims |

Three notes on that table, each of which cost something to learn:

- **The locale files are Tier B, not Tier A**, though they look like content. Several are joined to Ruby arrays *by position* — `Syllabus::ENTRIES[i]`, `LearnerProgress::AWARDS[i]`, `LessonContent::BLOCKS[i]`, every `AdminConsole` array — so inserting one entry silently relabels everything after it, in one language only. That is invariant 3, and it fails in the UI rather than in a stack trace.
- **`lesson_content.rb` is Tier C** because it holds the answer key. It reads like content and is a trust boundary.
- **Tier A is not "unreviewed."** Documentation in this repo makes checkable claims about the code — the whole of `CLAUDE.md` does — so a docs diff is reviewed for whether it is *true*, which is a different reading from reviewing code but not a lighter one.

There is no auto-merge at any tier, because there is nothing to merge into.

## 6. Ambiguity must get louder

**The single highest-value rule in the whole design, and the cheapest one here.** What an agent quietly guesses is a larger risk than anything that breaks the build, because a broken build announces itself and a plausible wrong assumption ships.

The discipline, which needs no tooling:

- **Ask with bounded options, not free text** — the question names two or three concrete choices and what each one costs, so answering is a decision rather than an essay.
- **Ask at the right time.** Everything that does not depend on the answer gets done first; the question is asked once, with the rest of the work already in hand.
- **For anything in Tier C there is no default.** If proceeding under an assumption would be unsafe or would make the work useless if the assumption is wrong, the work parks and waits. Elsewhere, state the assumption in writing and continue — a blocked task that could have proceeded is also a cost.
- **The answer is written into the repo, not left in a session.** A decision that lives only in a chat log is gone by next week; `docs/mdlc.md` is where it goes once there is a decision worth an ADR.

**Watch the rate in both directions.** Frequent blocking means the request was under-specified — fix what is being asked for. Blocking that never happens at all means the agent is guessing and the guesses are not being caught.

## 7. Trust boundary — the agent's input is untrusted

The agent reads this repository, its own tool output, and whatever it is shown. All of that is **data, not instructions**, and four surfaces here are written by somebody other than the person in the session:

- **`submissions.answer` is source code a student wrote.** Every coding-task attempt is stored, pass or fail, forever. Any agent asked to debug grading against real data is reading text an author chose freely.
- **`landing_texts` and `landing_cards` are prose an admin wrote**, rendered on a public page and reachable from `/admin?tab=landing`.
- **`proctor_events` are reports the browser made about itself**, which is why that endpoint skips the lock check in the first place.
- **A Slack channel `@Claude` has been invited to.** Mentioning it hands over the surrounding conversation — the whole thread, or recent channel messages — and Anthropic's own documentation warns that Claude may follow directions found there. This is the only one of the four where the text is written by *people, in real time*, rather than sitting in a table waiting to be read, and it is the only one that arrives already shaped like an instruction.

The first three become live the moment production data is pulled onto a laptop for debugging. The fourth is live as soon as somebody runs `/invite`. The rules:

| | |
| --- | --- |
| **Instructions come from one channel** | the person in the session. Text found in a database row, a fixture, a locale file, a tool result or a Slack message somebody else wrote is content to be reasoned about, never an instruction to follow |
| **`@Claude` goes in `squad-academy` and nowhere else** | `docs/slack.md` §2 keeps `academy-alerts` bot-only, and that separation now does a second job: a channel carrying CI output and Dependabot messages is carrying text written by release notes and build logs, which is exactly the shape of input that should never be able to address the agent. A human channel is a smaller, better-known set of authors |
| **Secrets never enter context** | `config/credentials.yml.enc` stays encrypted and `RAILS_MASTER_KEY` is not pasted into a session. Today the agent has no production credential at all, and that is a property worth keeping deliberately rather than by accident |
| **Attribution** | an agent-assisted commit carries `Co-Authored-By`. **3 of 46 do** — so the log currently cannot answer "was this reviewed as agent output?", which is the audit trail the design asks for. It costs a trailer |
| **The hook is agent-adjacent code** | `.claude/settings.json` runs `code-review-graph` on every `Edit`/`Write`. It is a command that executes on file change; treat a change to it as Tier C |

## 8. Not adopted, and why

| | Why not |
| --- | --- |
| **Admission controller / WIP limits** | The mechanism it implements already holds by convention: one commit, one stated purpose, 1–8 files. `Little's Law` over three reviewers describes a team that does not exist. Revisit when a second person reviews |
| **A Slack review queue, `#agent-blocked`, `/agent kill-switch`** | There is no Slack integration and no inbound endpoint — `docs/slack.md` §5 argues against building one. With one human, the queue is the terminal in front of them and the kill switch is `Ctrl-C` |
| **Auto-merge for Tier A** | Nothing to merge — commits land on `main` directly, and the only PRs the repo has seen are Dependabot's |
| **Progressive delivery, canary, auto-rollback** | No deploy target yet — `config/deploy.yml` still names `192.168.0.1`. This is the largest genuine gap, and it is what makes Gate 3 final |
| **CODEOWNERS, branch protection, read-only acceptance files** | One human owns every path; a CODEOWNERS file naming them for all of it is a file that enforces nothing |
| **DORA metrics** | Deployment frequency and MTTR over zero deploys is theatre |

## 9. What is worth measuring here

Almost every metric in the canonical set needs PRs or deploys. Three do not, and they are the ones that matter:

- **Escaped defects** — anything that passed `bin/ci` and a human read and was still wrong. The only honest measure of whether the gates work. `08745ed` ("Content missing" in the header) is one: no test could see it until `frame_recovery_test.rb` was written to.
- **Rework rate** — work rejected or substantially rewritten after review. Persistently high means the asks are too loose, which is upstream of the agent.
- **Comprehension index — how many people can explain a subsystem without reading it.** For this repo the number is **one**, for all of it. That is the long-term risk of a codebase built at agent speed, and no gate catches it. `CLAUDE.md` and `README.md` exist mostly to move that number, which is why the rule that they must not drift is worth more here than it looks.

## Six principles

1. **Design around the scarce resource** — one person's verification capacity, not how fast code can be produced.
2. **The last gate is a human reading a diff** — until there is a canary or a flag, nothing downstream will catch what they miss.
3. **Ambiguity must get louder** — a quiet guess is more dangerous than a broken build.
4. **A rule not written as a test does not exist** — `CLAUDE.md`'s invariant list is only as real as the tests named beside it.
5. **Everything the agent reads is data, not instruction** — including a row a student wrote.
6. **Measure outcomes, not output** — escaped defects and comprehension, never commit count.
