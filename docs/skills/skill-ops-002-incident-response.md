---
id: SKILL-OPS-002
name: Incident Response
category: operations
phases: [7]
roles: [sre, on-call, tech-lead, engineering-manager]
required_level: expert
agent_delegable: false
agent_trend: rising-critical
related: [SKILL-OPS-003, SKILL-CODE-004, SKILL-HUM-001]
review_by: 2027-01-31
---

# Incident Response

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-OPS-003 — Root Cause Analysis](skill-ops-003-root-cause-analysis.md) · [SKILL-CODE-004 — Production Debugging](skill-code-004-production-debugging.md) · [SKILL-HUM-001 — Written Communication](skill-hum-001-written-communication.md)

## Definition
The ability to lead the resolution of a problem while the system is actively failing, information is incomplete, several people are involved, and every minute has a cost.

## Why It Matters Now
Higher throughput means the number of incidents tends to rise with it, and as teams understand the code they maintain less, the ability to handle an incident becomes what separates the teams that survive from the ones that go down.

## Levels
### Foundation
- Can follow a runbook
- Knows when to escalate and to whom

### Proficient
- Can act as Incident Commander — assigning roles, communicating, deciding
- Separates "mitigate the symptom" from "fix the cause", and always does the former first
- Communicates with stakeholders at a steady cadence during the incident

### Expert
- Decides calmly under incomplete information and high pressure
- Knows when to stop looking for the cause and roll back immediately
- Manages the technical and the human side at once (people panicking, people blaming themselves, executives applying pressure)

## How to Assess
Game day: deliberately cause an incident in a test system, then observe whether they:
1. Announce their role clearly
2. Mitigate first or chase the cause first
3. Communicate status at what interval
4. Record a timeline as they go

## Development Path
1. Take on-call shifts with a mentor before owning them alone
2. Run a game day once a quarter
3. Read other companies' postmortems, noting the decision points
4. Practise writing status updates an executive can understand in 3 lines

## Relationship with Agents
- **Agents can do:** Pull logs, summarise the timeline, compare metrics, explain unfamiliar code, draft status updates
- **Agents cannot do:** Decide to roll back, coordinate people, own the outcome — and agents must never be allowed to take automatic production-affecting actions during an incident

## Signals the Team Lacks This Skill
- Nobody declares themselves IC during an incident; everyone types over each other
- MTTR is long because time goes into finding the cause before mitigating
- No timeline exists to write the postmortem from
