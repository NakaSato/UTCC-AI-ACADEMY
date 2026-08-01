---
id: SKILL-ARCH-001
name: Trade-off Analysis
category: architecture
phases: [1]
roles: [architect, tech-lead, security-engineer]
required_level: expert
agent_delegable: assisted
agent_trend: rising-critical
related: [SKILL-ARCH-002, SKILL-HUM-002]
review_by: 2027-01-31
---

# Trade-off Analysis

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-ARCH-002 — Boundary & Module Design](skill-arch-002-boundary-design.md) · [SKILL-HUM-002 — Decision Documentation](skill-hum-002-decision-documentation.md)

## Definition
The ability to compare technical options by identifying **what is being given up to gain what**, and to decide even when every option has drawbacks.

## Why It Matters Now
Agents are very good at proposing options, and propose more of them than a human would come up with alone. But they do not know the team's context, the organisation's constraints, or what we can realistically carry. That makes this the real new bottleneck.

## Levels
### Foundation
- Can compare options when given a table to fill in
- Can identify the obvious pros and cons

### Proficient
- Creates comparison criteria that fit the problem rather than using generic ones
- Identifies long-term costs (operational cost, cognitive load), not just the cost of building
- Distinguishes decisions that are easy to reverse from those that are hard to reverse

### Expert
- Can assess which option will break first and under what conditions
- Decides quickly on easily reversible matters and slows down on hard-to-reverse ones
- Sees options nobody proposed, including "do nothing at all"

## How to Assess
Give a real problem the team has already decided on — for example "which message queue should we use" — and watch whether they:
1. Ask about throughput, ordering guarantees, and what the team has experience with, before naming a product
2. Talk about long-term maintenance cost, not just features
3. Can state how hard it would be to change course if the choice turns out wrong

Anyone who opens with a product name = not yet Proficient.

## Development Path
1. Write retrospective ADRs for 5 decisions already made, forcing an Alternatives section into each
2. Practise asking "so what are we giving up?" of every proposal in the team
3. Follow up on old decisions 6 months later — which ones were wrong, and what was misjudged
4. Have an agent propose options, then practise finding the drawbacks it did not mention

## Relationship with Agents
- **Agents can do:** Find existing options, build a first-pass comparison table, find prior art in the codebase
- **Agents cannot do:** Weigh things against team context, live with the consequences of the choice, know what the organisation can carry

## Signals the Team Lacks This Skill
- ADRs contain only a Decision and no Alternatives
- Technology chosen by whatever is currently in fashion
- Every decision takes the same amount of time, whether it is easy or hard to reverse
