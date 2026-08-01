---
id: SKILL-HUM-002
name: Decision Documentation
category: human
phases: [1, 2]
roles: [architect, tech-lead, product-owner, engineering-manager]
required_level: proficient
agent_delegable: assisted
agent_trend: rising-critical
related: [SKILL-ARCH-001, SKILL-HUM-001]
review_by: 2027-01-31
---

# Decision Documentation

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-ARCH-001 — Trade-off Analysis](skill-arch-001-tradeoff-analysis.md) · [SKILL-HUM-001 — Written Communication](skill-hum-001-written-communication.md)

## Definition
The ability to record a decision so that someone in the future (including yourself in six months) understands **why** it was made that way, and under what context and constraints.

## Why It Matters Now
Two separate reasons. First: as code gets produced far faster, the context behind decisions is lost just as fast. Second: agents read these documents as context — an unrecorded decision is a decision the agent will unknowingly violate.

## Levels
### Foundation
- Records what was decided

### Proficient
- Records the options considered and why they were not chosen
- States the constraints and context at the time
- States the consequences, both the benefits and the costs accepted

### Expert
- Links decisions to fitness functions that are actually enforced
- Writes so that someone who was not there can tell when the decision should be revisited
- Manages superseded ADRs systematically, without deleting history

## How to Assess
Take an ADR they wrote 6 months ago, give it to someone new, and ask:
1. Do you understand why this was chosen?
2. Do you know what would have to change for it to be revisited?

Unable to answer either = still Foundation.

## Development Path
1. Write retrospective ADRs for 5 hard-to-reverse decisions
2. Require an Alternatives section in every ADR — an ADR without one is just meeting notes
3. Tie each ADR to a test that actually enforces it
4. Review old ADRs every quarter to see which should be superseded

## Relationship with Agents
- **Agents can do:** Draft ADRs from a conversation, structure them, find prior art, check that all sections are present
- **Agents cannot do:** State the real reason behind a choice, especially organisational reasons that never appear in writing

## Signals the Team Lacks This Skill
- Asking "why was it done this way?" and nobody can answer
- The same decision gets remade every 6 months
- ADRs contain only a Decision, with no Context or Alternatives
