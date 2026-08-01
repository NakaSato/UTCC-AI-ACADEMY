---
id: SKILL-CODE-004
name: Production Debugging
category: coding
phases: [7]
roles: [sre, backend-engineer, tech-lead]
required_level: expert
agent_delegable: assisted
agent_trend: rising-critical
related: [SKILL-OPS-001, SKILL-OPS-003]
review_by: 2027-01-31
---

# Production Debugging

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-OPS-001 — Observability Design](skill-ops-001-observability-design.md) · [SKILL-OPS-003 — Root Cause Analysis](skill-ops-003-root-cause-analysis.md)

## Definition
The ability to find the cause of a problem in a live system that cannot be reproduced, with incomplete information, under time pressure.

## Why It Matters Now
**This is the skill whose value is rising most sharply, and most quietly.** As teams understand the code they maintain less and less (comprehension decay from agent-written code), the ability to debug a system you did not write becomes what separates the teams that survive from the ones that go down at three in the morning.

## Levels
### Foundation
- Reads logs and stack traces
- Follows the existing runbook

### Proficient
- Forms a hypothesis, then systematically gathers evidence to prove or disprove it
- Combines metrics, traces, and logs to narrow the problem down
- Knows when to stop looking for the cause and mitigate the symptom first

### Expert
- Finds causes in systems they did not write
- Separates correlation from causation under pressure
- Knows when a *missing* piece of data is itself the important clue

## How to Assess
Give the scenario: "p99 latency went from 200ms to 3s forty minutes ago, and there was no deploy in that window", then ask what they would look at, in order.
- Guesses a cause and goes straight to fixing it = Foundation
- Systematically narrows the scope (all endpoints or some / all regions or some / DB or app) = Proficient or above
- Asks about what changed outside our system (traffic pattern, upstream, cron, data growth) = Expert

## Development Path
1. Join incidents even for systems you do not own — learn from people who are better at it
2. Practise reading flame graphs and distributed traces
3. Run game days: deliberately break something in a test system and have the team find the cause
4. Read another company's postmortem every month, and try to guess the cause before reading the summary

## Relationship with Agents
- **Agents can do:** Pull logs, summarise timelines, compare metrics across time windows, explain unfamiliar code
- **Agents cannot do:** Form good hypotheses from context that is not in the data, decide when to stop investigating and roll back

## Signals the Team Lacks This Skill
- MTTR steadily increasing
- Incidents frequently ending in "restarted it and it went away"
- One person everyone has to call when the system breaks
