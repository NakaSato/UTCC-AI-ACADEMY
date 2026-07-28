# Slack, and what it is allowed to carry

**Slack is a system of engagement, not a system of record.** Anything that has to be retrievable later has a real home elsewhere — a decision goes in `docs/decisions/` (see `docs/mdlc.md`), the process goes in `docs/process.md`, and the code is the code. Slack carries a link and a sentence saying who does what next.

The test: **if the workspace vanished tomorrow, the development system still works.** That is trivially true of this project today, and the purpose of this file is to keep it true as things get wired up.

> **This is a policy written before there is anything to enforce it on**, and that is deliberate — it is the one part of a Slack design that is cheap while the channel list is empty and expensive once forty bot messages a day have taught everyone to mute. Nothing here is wired up. Section 1 is the honest inventory; section 7 is the order to unlock the rest in.

## 1. What there is to notify from

| Would notify about | Source in this repo | State today |
| --- | --- | --- |
| Test/lint/security failures | `.github/workflows/ci.yml` | **Wired.** One message per failed run on `main`, from a `notify` job that needs all five others |
| Dependency CVEs | Dependabot | Available, and needs no code — GitHub's own Slack app delivers it. Read the note below on why its `github-actions` half used to be noise |
| Deploys | Kamal (`config/deploy.yml`) or Render (`render.yaml`) | Kamal's server is still the placeholder `192.168.0.1`; Render can post natively once it is the chosen target |
| Site down | — | No monitor. `/up` exists and is excluded from both the https redirect and host authorization precisely so something outside can reach it |
| Errors | — | No Sentry, no APM, no log aggregation |
| Incidents | — | No on-call, no pager, and no production incident has happened |
| Work items | — | No Jira, no Azure Boards. The backlog is prose at the end of `docs/process.md` |

**Dependabot was a partly false source until the workflow came back.** `.github/dependabot.yml` declares a `github-actions` ecosystem, and the workflow it was written for was deleted in `5b510e6` — so three of the four pull requests this repo has ever received bumped the versions of actions that nothing here ran, and the fourth bumped a gem that is no longer in the Gemfile. All four were closed unmerged, correctly. Restoring `.github/workflows/ci.yml` makes that ecosystem entry honest again: the actions it watches are now actions this repo really runs. **The `bundler` half is the one worth routing** — a gem CVE is a P1 nobody would otherwise see until they next ran `bin/ci`.

**A local `bin/ci` result still must not be posted, and that is not a "not yet".** `docs/process.md` makes "green on your machine" the definition of done on purpose, but a message posted *from* that run proves only that somebody ran something on their own machine — a green tick with no independent authority behind it is worse than silence, because it reads as a gate. The workflow is the authority; the laptop is not, and adding a webhook to `config/ci.rb` would blur exactly that line.

**The app's own notifications have nothing to do with this.** `Notification.notify` and `NotificationBell` push a frame to a signed-in browser and deliberately store a *kind* rather than a sentence, so a line reads in the language of whoever reads it. Slack has no reader locale, so bridging that table to a webhook would mean choosing one language for everyone and writing copy outside the locale files — the exact thing `CLAUDE.md` forbids in two separate places. If a student's award ever needs to reach Slack, it is a new message written for Slack, not a re-render of a bell.

## 2. Channels — one squad, so start with two

The convention is `<scope>-<domain>-<purpose>`, and the hard rule survives at any size: **one channel = one purpose = one audience = one expected action.** If you cannot say what a reader is supposed to *do*, the channel should not exist.

| Channel | Type | Holds | Create when |
| --- | --- | --- | --- |
| `squad-academy` | human | the team talking; blockers named at the Daily Scrum and chased afterwards; **the only channel `@Claude` is invited to** | now |
| `academy-alerts` | bot-only, no conversation, replies in-thread | CI failures on `main`, Dependabot, and later the uptime monitor and deploys | it has a source |
| `inc-YYYYMMDD-NN` | ephemeral | one incident, exported before archiving | the first incident |

**Do not create a channel before its event source exists.** An empty bot channel is a channel people learn to ignore, and they do not un-learn it when it finally has something to say. Three channels is the whole list until there is production traffic; the eleven-channel taxonomy is what a platform org with per-service ownership needs, and this is one Puma process over one SQLite file.

### `@Claude` is a third Slack surface, and the only inbound one

Two of the three things called "Slack" here only ever send: the CI `notify` job, and GitHub's app for Dependabot. **`@Claude` reads**, which makes it a different kind of decision.

- **Channel membership is the access control.** It is added to nothing on install and responds only where it has been `/invite`d, so which channels it is in *is* the permission model — not a convenience. It does not work in DMs at all.
- **It is invited to `squad-academy` only.** Mentioning it hands over the surrounding thread or the recent channel messages, and Claude may act on directions found in them. `academy-alerts` carries build output, dependency release notes and, later, deploy and monitor messages — text written by systems and strangers, which is the last thing that should be able to address an agent with commit access. `docs/agent-flow.md` §7 counts this as the fourth untrusted input surface in the project.
- **Mention it inside a thread.** In a thread it reads the whole conversation; in a channel it sweeps only recent messages. For a bug already discussed, the thread is most of the context.
- **Sessions run under the mentioning person's own Claude account**, against the repositories *they* connected, on *their* rate limits. It is not a shared team identity, and one session opens at most one pull request.
- **Slack is still not the record.** What comes back is a summary plus buttons; the transcript lives in the session on the web and the change lives in the commit. A decision reached in that thread is subject to `docs/mdlc.md` like any other.

## 3. Signal classes

| Class | Means | Delivery | Mentions | Here that would be |
| --- | --- | --- | --- | --- |
| **P0** | act within minutes | push + `#inc-*` | `@here` permitted | `academy.boring9.dev` down; the `storage/` disk unmounted — without it `db:prepare` recreates an empty database on deploy, which is data loss that looks like a fresh install |
| **P1** | act, but not now | channel, or a DM to one person | named individuals only | a critical CVE from Dependabot; a failed deploy |
| **P2** | nice to know | one daily digest | none | a Dependabot PR opened; the `review_by` staleness list from `docs/mdlc.md` §6 |

Four rules, in the order they stop mattering:

1. **`@channel` is never used.** Not for P1, not for a release. One habitual `@channel` and people turn notifications off for the whole workspace, which costs you the P0 you were saving it for.
2. **Thread-first.** Everything about one entity — a PR, an incident, a deploy — belongs in one thread. A second top-level message about the same thing is how a channel becomes unreadable.
3. **Auto-resolve by editing.** When a problem clears, the bot edits the original message rather than posting a new one. Two messages for one event doubles the volume and halves the trust.
4. **Success is not news.** A green deploy is the default state. If it is worth seeing at all it is worth seeing once a day in a digest.

**The measure of whether this is working is that nobody has muted anything.** When someone mutes a channel, the routing is wrong — not the person.

## 4. Ceremonies — which of the four go async

`docs/process.md` fixes the four events. The dividing line is the one in the source design: **ceremonies that require joint decision-making stay live; ceremonies that only report status go async.**

| Event | Stays live? | What Slack may carry |
| --- | --- | --- |
| **Sprint Planning** | yes — it decides the sprint goal | the backlog slice posted the day before, so nobody arrives reading it cold |
| **Daily Scrum** | **yes**, and it is the one most often mistaken for async-able | nothing about the meeting. The blockers it surfaces are chased *afterwards* — that is the thread |
| **Sprint Review** | yes — `process.md` requires demonstrating the running app, not slides | the recording link and what changed |
| **Retrospective** | yes | an anonymous form beforehand, and **nothing afterwards** |

Two of those need their reason stated, because both look like easy wins:

- **The Daily Scrum is a planning meeting run by the developers, not a status report** (`process.md` says so in as many words). A Workflow Builder form that collects three sentences a day converts it into exactly the status report it is defined as not being, and the fifteen minutes it saves are the fifteen minutes where someone says "I am stuck" out loud.
- **A retro leaves no transcript.** `process.md`: retrospectives only work if it is safe to be honest in them, and nothing said is used against anyone afterwards. A bot that captures, summarises or exports a retro breaks that promise permanently and silently. The action items leave the room; the discussion does not.

## 5. What every remaining layer is blocked on

| Layer | Blocked on | Cheapest unlock |
| --- | --- | --- |
| CI notifications | — **done**, see §1 | — |
| Deploy notifications | a real deploy target | pick Kamal or Render; Render posts natively, Kamal needs a hook |
| Alerting | anything watching | an uptime monitor on `/up` |
| Incident channels | an incident | — |
| DORA metrics | deploys to count | — |
| ChatOps (`/deploy`, `/status`) | see below | — |

**ChatOps is the one to rule out rather than defer.** Authorisation in this app is `allow_only` over `users.role`, resolved from a signed session cookie — a Slack user id is not a `User` and there is no mapping between them. Accepting a command would also mean a public unauthenticated route in an app where `require_authentication` is a global `before_action` and exactly three controllers opt out. That is a real attack surface bought for a convenience nobody has asked for, on a deploy that takes one command in a terminal.

## 6. Governance — the three that bite at any size

- **Never send PII.** `test/controllers/log_filtering_test.rb` exists because a student ID and the profile fields must not reach a log line; Slack is a log with worse retention and a wider audience. A payload naming a student breaks the same promise that test guards. Send a link to a screen behind the login instead.
- **A bot token is a credential.** It belongs in `config/credentials.yml.enc` or in the platform's environment, next to `RAILS_MASTER_KEY` — never in the repo, never in a script on a laptop. That is also the second reason local `bin/ci` cannot post: it would put a workspace-write token on every machine that clones this repo.
- **Signature verification is not applicable, because nothing is inbound.** If that ever changes, the rule is HMAC over `v0:<timestamp>:<body>`, a 5-minute skew window, and a constant-time comparison — an unverified endpoint means anyone who learns the URL can act as the bot. Section 5 is the argument for not building it.

## 7. Adoption order

1. **This file.** Costs nothing and is the only step that gets harder later.
2. **`squad-academy`.** People, no bots.
3. **`academy-alerts`, with the CI `notify` job pointed at it** — set `SLACK_BOT_TOKEN` as a repository secret and `SLACK_CI_CHANNEL` as a repository variable, and the workflow does the rest. Nothing is posted until both exist, so a fork stays quiet.
4. **GitHub's Slack app, subscribed to Dependabot alerts**, into the same channel. Costs no code.
5. **An uptime monitor on `/up`** once the site is actually deployed. The first P0 that can exist.
6. **Deploy notifications** from whichever target is chosen.
7. **Stop.** Everything past this needs an inbound endpoint, and §5 is why that is a bad trade here.

Do not jump to 6. A team that wires deploy tooling before writing a notification policy ends up able to deploy production from a channel nobody reads.

## Anti-patterns, of the ones that can happen here

| Anti-pattern | Consequence | Instead |
| --- | --- | --- |
| Notifying on every event | mute → the P0 is missed | classify P0/P1/P2, digest the P2s |
| Deciding something in a channel | unfindable in three months | the decision is an ADR; Slack carries the link |
| Posting a local `bin/ci` result | a gate that is not a gate | only the workflow posts; `config/ci.rb` stays silent |
| One message per failed job | five red jobs, five notifications | the `notify` job needs all five and posts once |
| Assigning work by DM | no trail, and the team loses the context | a channel and a thread |
| A channel with no source yet | learned as ignorable, permanently | create it the day it has something to say |
| Inviting `@Claude` to a bot channel | build output and release notes become instructions to an agent | `squad-academy` only; `academy-alerts` stays send-only |

## Five principles

1. **System of engagement, not of record** — if you will need it later, it lives somewhere else and Slack links to it.
2. **Every notification answers "who does what next?"** — if it cannot, it is a dashboard, not a message.
3. **Authorisation lives in the app** — Slack is a thin, untrusted UI, and here it is not even that.
4. **Async by default, except where the meeting is the point** — planning, blockers spoken aloud, and a retro nobody transcribes.
5. **Nobody muting is the success metric** — a muted channel is a design defect.
