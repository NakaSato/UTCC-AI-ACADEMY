---
id: SKILL-OPS-001
name: Observability Design
category: operations
phases: [1, 7]
roles: [sre, backend-engineer, architect, devops]
required_level: proficient
agent_delegable: assisted
agent_trend: rising
related: [SKILL-CODE-004, SKILL-PROD-002]
review_by: 2027-01-31
---

# Observability Design

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-CODE-004 — Production Debugging](skill-code-004-production-debugging.md) · [SKILL-PROD-002 — Metric Design](skill-prod-002-metric-design.md)

## Definition
The ability to design a system so it can answer questions that have not been asked yet — through metrics, logs, and traces put in place at design time, not during an incident.

## Why It Matters Now
When most of the code is written by agents and the team's understanding of the system declines, observability becomes the primary way of understanding your own system, in place of knowledge held in people's heads.

## Levels
### Foundation
- Adds logs and metrics following the team's existing patterns
- Can use the existing dashboards

### Proficient
- Designs metrics using the RED/USE method
- Emits structured logs carrying a correlation id along the whole path
- Sets alerts tied to symptoms users feel, not to causes
- Links metrics, logs, and traces through the same service, environment, version, release,
  trace, and correlation identifiers
- Assigns an owner and a runbook link to every alert that requires action

### Expert
- Designs SLOs that reflect real user experience, and uses the error budget in decisions
- Designs traces that can answer cross-system questions
- Reduces alert noise systematically without reducing safety
- Designs sampling, redaction, access control, and retention so that no credentials,
  request bodies, student data, or direct identifiers are written to telemetry

## How to Assess
Ask: "if a user says the payment page is slow, can you answer within 5 minutes whether it really is slow, where it is slow, and how many users are affected?"
No answer = observability is insufficient, no matter how many dashboards exist.

## Development Path
1. Write one SLO for a service you own, then measure it for real for a month
2. Audit all alerts: delete any that fire and nobody acts on
3. Practise carrying a correlation id along the request path, then trace a real problem with it
4. Run a game day and see whether the available data is enough to find the cause
5. Run a controlled failure and verify that dashboards can split by release, traces link
   through to logs, and alerts reach on-call together with a runbook

## Relationship with Agents
- **Agents can do:** Add standard instrumentation, build dashboards, write queries, create alert rules
- **Agents cannot do:** Decide what counts as "a good experience" for our users, which is the basis of any SLO

## Signals the Team Lacks This Skill
- You learn the system is broken from users, not from alerts
- So many alerts that people mute notifications
- Plenty of logs, but nothing findable when you need it
