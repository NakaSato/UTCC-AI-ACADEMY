# How this team works

**Tags:** [#process](tags.md#process) [#scrum](tags.md#scrum) [#governance](tags.md#governance)

We use **Scrum**: an agile framework for solving complex problems through short work cycles called sprints, a small set of roles, and a fixed rhythm of meetings. The point is not the ceremony — it is that every sprint ends with something that actually works, and with an honest look at how the sprint went.

> **Two things in this document are proposals, not decisions:** the sprint length and the roster in [Roles](#roles). Agree them as a team and edit this file.

## Sprints

A sprint is a fixed-length cycle — one month or less, **two weeks** here — that produces a working increment of the app. Its length never changes to fit the work; the work is scoped to fit the length.

- A sprint has a **goal**: one sentence saying what it is for. "Course and Topic become real tables" is a goal. "Various fixes" is not.
- **Scope is negotiable, the deadline is not.** If the work turns out larger than it looked, the scope shrinks. The sprint does not get extended.
- A new sprint starts the moment the previous one ends. There is no gap to "catch up" in.

## Roles

| Role | Who | Owns |
| --- | --- | --- |
| **Product Owner** | *to be agreed* | The product backlog and its order — what gets built next, and why that before this |
| **Scrum Master** | *to be agreed* | That the process is actually followed, and that whatever is blocking the team gets removed |
| **Developers** | everyone building the app | How the work gets done, the sprint backlog, and the quality of the increment |

Titles are about accountability, not seniority. A Product Owner decides *what*; developers decide *how*; nobody outside the team adds work to a sprint once it has started.

## The four events

### Sprint Planning — *what will we do this cycle?*

Opens the sprint. Time-boxed to **4 hours** for a two-week sprint.

Three questions, in order:

1. **Why is this sprint valuable?** → the sprint goal.
2. **What can be finished?** → items pulled off the product backlog into the sprint backlog.
3. **How will it get done?** → enough of a plan that nobody starts the sprint guessing.

An item is only pulled in if the team believes it can meet the [definition of done](#definition-of-done) within the sprint. Half-finished work at the sprint boundary counts as not done.

### Daily Scrum — *are we still on track for the goal?*

**15 minutes, same time, every working day.** For the developers, run by the developers.

It is a planning meeting, not a status report to a manager. The useful shape:

- What moved us toward the sprint goal since yesterday?
- What will move us toward it today?
- What is in the way?

Anything that needs longer than the 15 minutes gets taken outside the meeting by the people who care about it. Blockers get named here and chased afterwards — the Daily Scrum surfaces them; it does not solve them.

### Sprint Review — *here is what we built*

At the end of the sprint, time-boxed to **2 hours**. The team shows the working increment to stakeholders — for this project, that means the people who will teach with it and the students who will use it — and collects feedback.

- **Demonstrate the running app, not slides.** If it cannot be shown working, it is not done and it is not in the review.
- Feedback here changes the *product backlog*, not the sprint that just ended.
- This is a working session, not a sign-off ritual.

### Sprint Retrospective — *how do we get better?*

Closes the sprint, after the review. Time-boxed to **90 minutes**.

The team inspects **itself** — how it worked, not what it built: what went well, what went badly, what to change. The output is **one or two concrete improvements carried into the next sprint**, owned by someone. A retrospective that produces a list of complaints and no change has not finished.

Retrospectives only work if it is safe to be honest in them. Nothing said in a retro is used against anyone afterwards — which is why `docs/slack.md` rules out any bot that captures, summarises or exports one. All four of these events stay live; that file says which parts of them may go async and which may not.

## Artifacts

- **Product backlog** — everything known to be wanted, ordered by the Product Owner. Always exists; never finished.
- **Sprint backlog** — the slice pulled in for this sprint, plus the plan for delivering it. Owned by the developers, who may adjust it mid-sprint as they learn.
- **Increment** — the working software at the end of the sprint. It must meet the definition of done to count.

## Definition of done

Work is done when it is **shippable**, not when it is written. In this repo that means all of:

- `bin/ci` passes locally — setup, RuboCop, bundler-audit, `importmap audit`, Brakeman, the test suite, and the seed replant. Green on your machine is what "done" means; `.github/workflows/ci.yml` then runs the same steps on a clean runner, and a red one on `main` is a broken build whoever pushed it owns.
- New behaviour has a test, and copy changes have not broken the locale assertions.
- Both `th.yml` and `en.yml` were updated together, with any positionally-indexed arrays kept the same length and order.
- The change does not break an invariant listed under "Software system design" in `CLAUDE.md`.
- It can be demonstrated by walking the app signed in — which is what the Sprint Review will do.

## Ordering the backlog

**This section is now history, and that is the point of leaving it here.** The dependency order below was the backlog, and every item on it is finished:

1. ~~**Course and Topic tables**~~ — they anchored the strings everything else already referenced.
2. ~~**Submissions**~~ — the prerequisite for moving lesson grading off the client, which was the app's one known trust gap.
3. ~~**Sections / cohorts**~~ — the leaderboard and the instructor report were both blocked on a concept `users` did not have.
4. ~~**Projects, awards, notifications**~~ — the last of the placeholder surfaces.

A sprint goal that takes one placeholder module and makes it real was a good sprint goal: a vertical slice, demonstrable at the review, and `LearnerProgress` is the worked example of how to do it without changing a single view. That well is now dry — **there is one placeholder left and it is not a modelling job.** So the next Product Owner decision is a genuine one rather than a reading of this list, and it should be made at planning rather than inferred here.

What is known to be wanted, unordered, for whoever orders it:

- **A working mailer.** SMTP is unconfigured, so password reset enqueues a message that reaches nobody — the one broken user-facing path in production, and the only route back in for an account whose owner forgot their password. It needs credentials, which is a decision and not a commit.
- **Lesson content per topic.** The prose, quiz and coding task are the same whichever topic is open. Sixteen topics × two languages is a writing job with an engineering seam already built for it; scope it as content, and do not let it masquerade as a sprint of code.
- **Whether hearts gate anything at zero.** `LearnerProgress#hearts` counts down and the display stops there, deliberately, because nobody has decided whether an empty set should block an attempt. That is a pedagogy decision.
- **Revocation better than a 30-day cap.** With no mailer, `Session::MAX_AGE` is the only thing that ends a stolen session.

Whichever it is, it is the first decision on this project that has a losing alternative worth recording — `docs/mdlc.md` proposes where that record goes and what it has to contain.

See `CLAUDE.md` for the engineering conventions, and `README.md` for how to run the app.
