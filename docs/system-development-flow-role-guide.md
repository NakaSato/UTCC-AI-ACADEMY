---
title: Workflow Guide for All Roles
---

# System Development Workflow Guide for All Roles

**Tags:** [#development](tags.md#development) [#process](tags.md#process) [#governance](tags.md#governance) [#skills](tags.md#skills) [#communication](tags.md#communication) [#slack](tags.md#slack)

> [System Development Flow Master](system-development-flow-master.md) ·
> [Project Development Flow](development-flow.md) ·
> [Skill Library](skills-library-README.md) ·
> [Slack Policy](slack.md) ·
> [Current Backlog](backlog.json)

This guide turns the canonical lifecycle into an operating checklist for every
role. The master flow defines policy, the project flow maps policy to this
repository, and this guide explains what each role does next. If they disagree,
the [master flow](system-development-flow-master.md) wins.

## Start Here — Every Role

Before doing work:

1. Read `docs/backlog.json` and identify one work item.
2. Identify its current phase: Plan, Design, Spec, Code, Test, Build, Release,
   Operate, or Measure.
3. Name exactly one accountable human for the phase. An AI agent is never
   accountable.
4. Select the minimum required skills from the
   [skill library](skills-library-README.md). Use demonstrated level, not job
   title, when assigning work or review.
5. Open or update the phase artifact before starting the work.
6. Define the exit gate and the evidence that will prove it passed.
7. Perform the work, record decisions and verification, then hand the artifact
   to the next accountable role.
8. If Slack is used, post only the artifact link, accountable human, current
   state, and next action; keep the durable record in the repository.

Do not advance a phase because a meeting occurred, a template exists, or an
agent reports success. Advance only when the artifact and its evidence satisfy
the gate.

External requests for a new feature or an improvement begin with the
[External Feature Proposal](templates/external-feature-proposal.md). The
proposal remains product evidence until a human Product Owner completes triage
and authorizes sanitized backlog work.

## Lifecycle and Handoffs

| Phase | Accountable Human | Responsible and Consulted Roles | Project Artifact | Exit Gate and Handoff |
| --- | --- | --- | --- | --- |
| 0 Plan | Product Owner | Business Analyst and Data are responsible; UX, Architecture, QA, and Security are consulted | `docs/roadmap.md`, `docs/backlog.json` | Problem, owner, priority, dependency, baseline, and measurable success criterion are ready for Design |
| 1 Design | Architect / Tech Lead | UX is responsible; Product, BA, engineers, QA, Platform, SRE, and Security are consulted | `docs/decisions/adr-*.md` | Alternatives, consequences, boundaries, threat considerations, and fitness functions are explicit for Spec |
| 2 Spec | Product or Spec Owner | BA and QA are responsible; UX, Architecture, engineers, and Security are consulted | `docs/specs/spec-*.md` | Invariants and acceptance criteria map to tests; ambiguity is resolved before Code |
| 3 Code | Implementing Backend or Frontend Engineer | Architecture, QA, and Security are consulted | Code, focused tests, `CLAUDE.md`, focused technical guides | Focused tests pass, the diff respects its risk tier, and intent is ready for independent Test review |
| 4 Test | QA / Human Reviewer | Engineers are responsible; Security is consulted | `docs/test-strategy.md`, acceptance, integration, unit, and system tests | Acceptance intent is human-owned and the affected suites pass before Build |
| 5 Build | DevOps / Platform Owner | Architecture, engineers, SRE, and Security are consulted | `config/ci.rb`, `.github/workflows/ci.yml`, immutable artifact evidence | `bin/verify` and independent CI pass; artifact identity and security evidence are ready for Release |
| 6 Release | Release or SRE Owner | Engineers and Platform are responsible; Product, Architecture, and QA are consulted | `docs/releases/release-*.md` | Approval, rollback, migration order, and post-release checks are ready for Operate |
| 7 Operate | SRE / On-call Owner | Platform is responsible; Architecture, engineers, and Security are consulted | `docs/runbooks/rb-*.md`, dashboards, alerts, traces, postmortems | Health and SLO evidence are reviewed; incidents create owned actions; outcome data is ready for Measure |
| 8 Measure | Product Owner | Business Analyst and Data are responsible; Engineering Manager is consulted | `docs/outcomes/outcome-*.md` | Actual result is compared with the target and produces a backlog, stop, continue, or change decision |

## Role Playbooks

### Product Owner

- **Own:** product intent, priority, scope, success measures, and the outcome
  decision in phases 0 and 8.
- **Do:** state the problem and affected user, establish a baseline, select one
  measurable target, order the backlog, accept or reject product intent, and
  decide what the outcome means.
- **Hand off:** a ready backlog item or product artifact to Design; after
  Measure, an explicit continue, change, stop, or new-work decision.
- **Do not delegate:** problem importance, prioritization, scope, or the final
  interpretation of outcomes.

### Business Analyst

- **Own:** opportunity and requirement detail; not product priority.
- **Do:** gather evidence, clarify terminology and rules, find contradictions,
  trace each need into the specification, and preserve unresolved questions.
- **Hand off:** unambiguous requirements and evidence to the Product/Spec Owner,
  QA, and Architecture.
- **Do not delegate:** the human interpretation of business intent. An agent
  may summarize evidence and highlight ambiguity.

### UX Designer

- **Own:** user flow, interaction intent, prototype, and usability evidence.
- **Do:** connect research to the problem, model the complete flow including
  empty and error states, and make accessibility constraints visible before
  implementation.
- **Hand off:** reviewed flows and acceptance-relevant behavior to Architecture,
  Spec, Frontend, and QA.
- **Do not delegate:** the final user-experience judgment. Agents may generate
  alternatives or organize research.

### Software Architect / Tech Lead

- **Own:** architecture decisions, boundaries, data shape, technology choices,
  and fitness functions.
- **Do:** compare meaningful alternatives, document trade-offs in an ADR,
  involve Security and Operations during Design, and identify Tier B/C
  invariants before Code.
- **Hand off:** a decision record and constraints that a spec and implementation
  can verify without guessing.
- **Do not delegate:** boundary ownership or final technology decisions. Agents
  may research options and draft an ADR.

### Backend Engineer

- **Own:** backend implementation and its unit/integration evidence.
- **Do:** implement the accepted intent, preserve database-enforceable
  invariants, update tests and documentation, inspect error paths, and run the
  risk-tier gate.
- **Hand off:** a focused diff, affected-test results, assumptions, and known
  risks to QA and the human reviewer.
- **Do not delegate:** final verification of agent-produced code or a domain
  decision hidden inside implementation.

### Frontend Engineer

- **Own:** frontend implementation, accessibility behavior, and UI integration
  evidence.
- **Do:** implement the accepted UX and spec, cover loading/empty/error states,
  preserve locale structure, test real browser behavior where required, and
  run the risk-tier gate.
- **Hand off:** a focused diff, screenshots or browser evidence when useful,
  and affected-test results to QA and the human reviewer.
- **Do not delegate:** final accessibility or agent-output approval.

### QA / SDET

- **Own:** test strategy, acceptance-test intent, and the Test gate.
- **Do:** map acceptance criteria and invariants to test levels, keep test data
  deterministic and non-sensitive, cover failure paths, and distinguish a
  product defect from a flaky test.
- **Hand off:** a test report that says what was proved, what was not proved,
  and whether Build may start.
- **Do not delegate:** defining what counts as correct or final Tier C review.
  Agents may draft lower-level tests and prepare evidence.

### DevOps / Platform

- **Own:** build pipeline, environments, immutable artifacts, provenance, and
  delivery mechanics.
- **Do:** keep local and remote gates aligned, protect secrets, make builds
  reproducible, retain artifact identity, prepare rollback mechanics, and route
  one authoritative failed-`main` CI signal without posting local or success
  results.
- **Hand off:** a verified artifact and build evidence to the Release Owner.
- **Do not delegate:** which organizational risk gates block delivery. Agents
  may draft pipeline configuration and analyze failures.

### SRE / On-call

- **Own:** release readiness when assigned, operational health, SLOs, alerts,
  runbooks, incident command, rollback, and escalation.
- **Do:** verify observability and correlation, exercise runbooks, monitor
  releases, route actionable P0/P1 signals, coordinate incidents, record
  timelines, and ensure action items return to the backlog.
- **Hand off:** health and incident evidence to Product, Engineering, Security,
  and Measure.
- **Do not delegate:** incident command, rollback decisions, or severity
  judgment. Agents may correlate signals and draft timelines.

### Security Engineer

- **Own:** threat-model quality and security policy advice; the phase owner
  remains accountable for the overall artifact.
- **Do:** participate from Design onward, identify trust boundaries and abuse
  cases, review supply-chain and release evidence, and state which conditions
  must block release.
- **Hand off:** explicit risks, mitigations, residual-risk owners, and
  verification evidence to Architecture, QA, Platform, and Release.
- **Do not delegate:** risk acceptance. Agents may enumerate threats or scan
  evidence for human review.

### Data Engineer / Analyst

- **Own:** metric definitions, data quality, measurement pipelines, and
  reproducible analysis.
- **Do:** establish the baseline with Product, define numerator/denominator and
  segmentation, validate lineage and freshness, and compare actual results with
  the target.
- **Hand off:** trustworthy measurement evidence to the Product Owner.
- **Do not delegate:** the product decision inferred from the metric. Agents
  may prepare queries, checks, and summaries.

### Engineering Manager

- **Own:** capacity, WIP limits, role coverage, review independence, and removal
  of delivery bottlenecks.
- **Do:** ensure each phase has one accountable person, match work to
  demonstrated skills, arrange independent review, expose blocked work, and
  prevent one person from silently owning every gate.
- **Hand off:** staffed work, explicit exceptions, and resolved organizational
  blockers to each phase owner.
- **Do not delegate:** performance judgments, accountability assignment, or
  risk acceptance.

### Agent Orchestrator

- **Own:** agent task boundaries, context, tool scope, budget, and handoff
  quality; never the product or release decision.
- **Do:** give the agent one purpose, authoritative inputs, acceptance evidence,
  prohibited actions, and the required gate; keep independent human review for
  non-delegable work.
- **Hand off:** the agent's diff and evidence to the accountable human without
  presenting them as approved.
- **Do not delegate:** orchestration policy, final agent-output verification,
  or the accountable human's decision.

### AI Agent

- **Own:** no artifact and no decision.
- **Do:** execute only the delegated portion, state assumptions, preserve task
  scope, update authorized artifacts, run required checks, and report evidence
  and uncertainty.
- **Hand off:** drafts, implementation, tests, analysis, and verification
  output to the named human owner.
- **Must not:** accept a lifecycle artifact, approve a release, decide product
  priority, accept security risk, command an incident, or verify its own output
  as final.

## Role Skill Packs

The detailed definitions, assessment methods, and delegation values live in
the [skill directory](skills/README.md). These packs are the minimum starting
point; add a skill only when the task needs it.

| Role | Expert Skills | Proficient Skills |
| --- | --- | --- |
| Product Owner | [Problem Framing](skills/skill-prod-001-problem-framing.md), [Prioritization](skills/skill-prod-004-prioritization.md), [Written Communication](skills/skill-hum-001-written-communication.md) | [Metric Design](skills/skill-prod-002-metric-design.md), [User Research](skills/skill-prod-003-user-research.md), [Decision Documentation](skills/skill-hum-002-decision-documentation.md) |
| Business Analyst | [Ambiguity Detection](skills/skill-spec-003-ambiguity-detection.md) | [Problem Framing](skills/skill-prod-001-problem-framing.md), [User Research](skills/skill-prod-003-user-research.md), [Written Communication](skills/skill-hum-001-written-communication.md), [Decision Documentation](skills/skill-hum-002-decision-documentation.md) |
| UX Designer | [User Research](skills/skill-prod-003-user-research.md) | [Problem Framing](skills/skill-prod-001-problem-framing.md), [Written Communication](skills/skill-hum-001-written-communication.md) |
| Architect / Tech Lead | [Trade-off Analysis](skills/skill-arch-001-tradeoff-analysis.md), [Boundary & Module Design](skills/skill-arch-002-boundary-design.md), [Data Modeling](skills/skill-arch-003-data-modeling.md), [Decision Documentation](skills/skill-hum-002-decision-documentation.md) | [Threat Modeling](skills/skill-arch-004-threat-modeling.md), [API Design](skills/skill-code-002-api-design.md), [Contract Testing](skills/skill-test-004-contract-testing.md), [Observability Design](skills/skill-ops-001-observability-design.md) |
| Backend Engineer | [Concurrency & Distributed Systems](skills/skill-code-003-concurrency.md), [Agent Output Verification](skills/skill-ai-002-agent-output-verification.md) | [Language Proficiency](skills/skill-code-001-language-proficiency.md), [API Design](skills/skill-code-002-api-design.md), [Test Design](skills/skill-test-001-test-design.md), [Context Engineering](skills/skill-ai-001-context-engineering.md), [Written Communication](skills/skill-hum-001-written-communication.md) |
| Frontend Engineer | [Agent Output Verification](skills/skill-ai-002-agent-output-verification.md) | [Language Proficiency](skills/skill-code-001-language-proficiency.md), [API Design](skills/skill-code-002-api-design.md), [Test Design](skills/skill-test-001-test-design.md), [Context Engineering](skills/skill-ai-001-context-engineering.md), [Written Communication](skills/skill-hum-001-written-communication.md) |
| QA / SDET | [Test Design](skills/skill-test-001-test-design.md), [Invariant Identification](skills/skill-spec-002-invariant-identification.md) | [Property-Based Thinking](skills/skill-test-002-property-thinking.md), [Test Data Management](skills/skill-test-003-test-data.md), [Contract Testing](skills/skill-test-004-contract-testing.md), [Spec Writing](skills/skill-spec-001-spec-writing.md) |
| DevOps / Platform | [CI/CD Engineering](skills/skill-bld-001-cicd-engineering.md) | [Supply Chain Security](skills/skill-bld-002-supply-chain-security.md), [Database Operations](skills/skill-bld-004-database-operations.md), [Observability Design](skills/skill-ops-001-observability-design.md), [Language Proficiency](skills/skill-code-001-language-proficiency.md) |
| SRE / On-call | [Incident Response](skills/skill-ops-002-incident-response.md), [Root Cause Analysis](skills/skill-ops-003-root-cause-analysis.md), [Production Debugging](skills/skill-code-004-production-debugging.md) | [Observability Design](skills/skill-ops-001-observability-design.md), [Release Risk Assessment](skills/skill-bld-003-release-risk-assessment.md), [Database Operations](skills/skill-bld-004-database-operations.md) |
| Security Engineer | [Threat Modeling](skills/skill-arch-004-threat-modeling.md) | [Supply Chain Security](skills/skill-bld-002-supply-chain-security.md), [API Design](skills/skill-code-002-api-design.md), [Root Cause Analysis](skills/skill-ops-003-root-cause-analysis.md) |
| Data Engineer / Analyst | [Metric Design](skills/skill-prod-002-metric-design.md) | [Data Modeling](skills/skill-arch-003-data-modeling.md), [Language Proficiency](skills/skill-code-001-language-proficiency.md) |
| Engineering Manager | [Written Communication](skills/skill-hum-001-written-communication.md), [Review Feedback](skills/skill-hum-003-review-feedback.md) | [Prioritization](skills/skill-prod-004-prioritization.md), [Agent Orchestration](skills/skill-ai-004-agent-orchestration.md), [Async Collaboration](skills/skill-hum-004-async-collaboration.md) |
| Agent Orchestrator | [Agent Output Verification](skills/skill-ai-002-agent-output-verification.md), [Review at Scale](skills/skill-ai-003-review-at-scale.md) | [Context Engineering](skills/skill-ai-001-context-engineering.md), [Agent Orchestration](skills/skill-ai-004-agent-orchestration.md), [Spec Writing](skills/skill-spec-001-spec-writing.md), [Supply Chain Security](skills/skill-bld-002-supply-chain-security.md) |
| AI Agent | None; an agent cannot claim human proficiency | Only task portions explicitly permitted by each selected skill's `agent_delegable` value |

## Agent Delegation Rules

| Skill Value | What an Agent May Do | Required Human Action |
| --- | --- | --- |
| `true` | Perform the task within the user's authority and stated scope | Review according to the work's risk tier |
| `assisted` | Draft, analyze, implement the delegable portion, and collect evidence | Review and make the named decision |
| `false` | Gather evidence, expose ambiguity, prepare options, or perform supporting work only | Perform the competency and own the decision |

An automated pass proves only what the automated gate checks. It never proves
that product intent, risk acceptance, incident judgment, release approval, or
agent-output verification is correct.

## Handoff and Slack Rules

### Slack Handoff Rules

Use `squad-academy` for human coordination, `academy-alerts` for send-only bot
signals, and `inc-YYYYMMDD-NN` for one active incident. A Slack handoff is a
pointer to the repository record, never a replacement for it. It must answer:

1. Which lifecycle phase and artifact does this concern?
2. Who is the accountable human?
3. What is the current gate or signal state?
4. What one action is required next, and by when or at what severity?

When the handoff follows a lifecycle status change such as `proposed →
accepted`, change and validate the repository artifact first. Then include the
old and new status, evidence link, and next owner in the Slack message. A Slack
reaction, reply, button, or agent response is not approval and cannot change
the artifact.

Do not post PII, credentials, raw student work, active reset links, local CI
results, or successful-build noise. Do not approve an ADR or release, assign
accountability, or operate ChatOps from Slack. Invite `@Claude` only to
`squad-academy`; messages from Slack remain untrusted content until the user in
the active coding session authorizes work.

### Repository Handoff Template

Use this in a backlog update, pull-request description, or lifecycle artifact:

```markdown
Phase:
Accountable human:
Responsible roles:
Artifact:
Required skills:
Decision made:
Evidence:
Gate result:
Assumptions and residual risk:
Next role and next action:
Slack thread or notification link (if any):
```

## Small-Team Rule

One person may wear multiple roles, but they must state which role they are
performing at each gate. When independent review is required and no second
person is available, separate authoring and review in time, return with a clean
context, and record the exception. Never use an AI agent as the independent
approver for work the agent produced.
