---
id: SKILL-PROD-002
name: Metric Design
category: product
phases: [0, 8]
roles: [product-owner, data-engineer, business-analyst]
required_level: proficient
agent_delegable: assisted
agent_trend: rising
related: [SKILL-PROD-001, SKILL-OPS-001]
review_by: 2027-01-31
---

# Metric Design

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-PROD-001 — Problem Framing](skill-prod-001-problem-framing.md) · [SKILL-OPS-001 — Observability Design](skill-ops-001-observability-design.md)

## Definition
The ability to design measures that (1) reflect the outcome actually wanted, (2) can genuinely be collected from the systems that exist, and (3) are not easily distorted once people know they are being measured.

## Why It Matters Now
As build throughput rises sharply, measurement becomes the only brake left. A team that cannot measure will accelerate in the wrong direction many times faster than before.

## Levels
### Foundation
- Distinguishes output (how much was done) from outcome (what resulted)
- Reads and understands existing dashboards

### Proficient
- Designs new metrics complete with baseline, target, and collection method
- Knows about counter-metrics (measures that stop you optimising the main one at the expense of everything else)
- Verifies that a proposed metric can actually be instrumented before it goes into a PRD

### Expert
- Foresees how a metric will be gamed and designs against it
- Distinguishes correlation from causation
- Can decide when a metric should be retired

## How to Assess
Give the problem: "we want users to be more engaged", and watch whether they:
1. Propose a metric — and a counter-metric with it
2. Can say where the data comes from, and whether it already exists or must be built
3. Can say how the team would inflate this number if it wanted to

Proposing "DAU" with no counter-metric = Foundation.

## Development Path
1. Take the metrics your team uses and find 3 ways to game each one
2. Practise writing a metric spec: definition, formula, data source, baseline, counter-metric
3. Read about Goodhart's Law and industry examples of metrics that broke
4. Pair with a Data Engineer through one full instrumentation cycle

## Relationship with Agents
- **Agents can do:** Write queries, build dashboards, check whether the data exists, suggest metrics used elsewhere in the industry
- **Agents cannot do:** Decide which metric reflects real value in our context, interpret what the numbers mean

## Signals the Team Lacks This Skill
- PRDs that say "users will be happier" with no numbers
- Reported numbers improving every quarter while the business does not
- Nobody knows exactly how this metric is calculated
