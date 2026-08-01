---
id: SKILL-BLD-003
name: Release Risk Assessment
category: build
phases: [6]
roles: [tech-lead, sre, release-manager, product-owner]
required_level: expert
agent_delegable: false
agent_trend: rising
related: [SKILL-BLD-004, SKILL-OPS-002]
review_by: 2027-01-31
---

# Release Risk Assessment

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-BLD-004 — Database Operations](skill-bld-004-database-operations.md) · [SKILL-OPS-002 — Incident Response](skill-ops-002-incident-response.md)

## Definition
The ability to assess, before deploying, what might break, who it would affect and how badly, how quickly we would find out, and whether we could really roll back.

## Why It Matters Now
As the number of changes per release rises sharply, reading every diff before shipping becomes impossible. The skill shifts from "read all of it" to "know where to read", and Change Failure Rate becomes the most important metric in the DORA set.

## Levels
### Foundation
- Follows the existing release checklist
- Knows who to notify before deploying

### Proficient
- Can identify which change in this release is riskiest, and why
- Verifies that the rollback plan actually works rather than merely existing on paper
- Defines clear post-deploy verification criteria

### Expert
- Assesses risk from the interaction between several changes, not one at a time
- Decides when to split a release and when changes can ship together
- Knows which risks are worth accepting

## How to Assess
Give a release of 12 PRs including one migration and one config change, then ask:
1. Which is riskiest, and why?
2. If it breaks, how many minutes until we know, and what tells us?
3. Which of these cannot actually be rolled back?

Anyone who does not flag that the migration cannot be rolled back = not yet Proficient.

## Development Path
1. Run a pre-mortem before a large release: assume it has already broken — what could have caused it?
2. Test a real rollback in staging at least once a quarter
3. Review past release-caused incidents — what signals were missed?
4. Practise writing release docs whose verification criteria are numbers, not "check that it looks normal"

## Relationship with Agents
- **Agents can do:** Summarise the changes in a release, generate the changelog, check whether there are migrations or config changes
- **Agents cannot do:** Decide whether to ship — that is accepting risk, and a human has to own it

## Signals the Team Lacks This Skill
- Change Failure Rate above 15%
- A rollback plan that says "revert the commit" for a release containing a migration
- No numeric post-deploy verification criteria
