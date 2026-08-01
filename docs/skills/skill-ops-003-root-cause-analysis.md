---
id: SKILL-OPS-003
name: Root Cause Analysis
category: operations
phases: [7]
roles: [sre, tech-lead, engineering-manager, architect]
required_level: expert
agent_delegable: assisted
agent_trend: rising-critical
related: [SKILL-OPS-002, SKILL-CODE-004, SKILL-HUM-002]
review_by: 2027-01-31
---

# Root Cause Analysis

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-OPS-002 — Incident Response](skill-ops-002-incident-response.md) · [SKILL-CODE-004 — Production Debugging](skill-code-004-production-debugging.md) · [SKILL-HUM-002 — Decision Documentation](skill-hum-002-decision-documentation.md)

## Definition
The ability to analyse an incident afterwards to find systemic rather than personal causes, and to turn that into changes that genuinely prevent recurrence.

## Why It Matters Now
As code gets produced faster, failure patterns repeat faster too. Good RCA turns one bug into a fitness function or a gate that blocks the whole class of it — which is the only way quality keeps up with volume.

## Levels
### Foundation
- Can write a complete timeline of the incident
- Can identify the immediate cause

### Proficient
- Uses techniques like 5 Whys without stopping at "someone made a mistake"
- Distinguishes contributing factors from the root cause
- Proposes action items that are measurable and have an owner

### Expert
- Analyses systemically: why did the process allow this to happen?
- Sees patterns across several incidents that look unrelated
- Turns findings into automated gates rather than reminders to be careful

## How to Assess
Give them a postmortem concluding "the developer forgot to add an index", then ask how they would take the analysis further.
- Accepting that conclusion = Foundation
- Asking why the system allowed it to be deployed unnoticed = Proficient
- Proposing an automated gate that checks query plans in CI = Expert

## Development Path
1. Write a postmortem every time, even for small incidents, and force yourself through five levels of "why"
2. Audit action items from old postmortems — what % were actually done, and what % became automation?
3. Look for patterns across the last 10 incidents
4. Practise writing blameless postmortems — the language used determines whether people tell the truth

## Relationship with Agents
- **Agents can do:** Assemble the timeline from logs and chat, find correlations, draft the document, search for similar past incidents
- **Agents cannot do:** Analyse organisational causes, decide which action items are worth doing

## Signals the Team Lacks This Skill
- Postmortems ending in "we will be more careful"
- The same kind of incident recurring within six months
- Action items left outstanding with nobody doing them
