---
id: SKILL-SPEC-001
name: Spec Writing
category: specification
phases: [2]
roles: [spec-owner, product-owner, tech-lead, qa]
required_level: expert
agent_delegable: assisted
agent_trend: rising-critical
related: [SKILL-SPEC-002, SKILL-SPEC-003, SKILL-TEST-001]
review_by: 2027-01-31
---

# Spec Writing

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-SPEC-002 — Invariant Identification](skill-spec-002-invariant-identification.md) · [SKILL-SPEC-003 — Ambiguity Detection](skill-spec-003-ambiguity-detection.md) · [SKILL-TEST-001 — Test Design](skill-test-001-test-design.md)

## Definition
The ability to turn requirements written in adjectives ("easy", "fast", "reliable") into statements a **machine can verify**, leaving no room for two readings.

## Why It Matters Now
This is the highest-return skill in the whole library, because an agent's value varies directly with the quality of the spec — the best agent in the world, given a vague spec, simply produces the wrong thing faster. Investment here pays off many times more than investment in agent tooling.

## Levels
### Foundation
- Writes user stories from a template
- Separates acceptance criteria from general description

### Proficient
- Writes ACs that each point to a test file that actually exists
- States non-goals clearly (what is deliberately not being done)
- States the rollback plan and the observability required

### Expert
- Writes specs someone else can execute without a single follow-up question
- Writes invariants that catch bugs the test examples cannot
- Knows when a detailed spec is warranted and when writing one is a waste of time

## How to Assess
Give a vague requirement, such as "users should be able to cancel an order easily", and have them write a spec within 20 minutes.
Passing criteria:
- Every AC names a verified-by test file
- At least one non-goal
- An invariant that is more than a restatement of the ACs
- A rollback plan

Then give that spec to an agent to implement and see how many questions it gets stuck on — the fewer, the better the spec.

## Development Path
1. Take an old requirement the team misread, rewrite it with invariants + ACs pointing to tests. Repeat 10 times
2. Before writing any code, have an agent read the spec and ask "what is still unanswered?" — the questions it asks are your leaks
3. Practise always producing at least one non-goal
4. Read real RFCs or standards specs (the HTTP RFCs, for instance) and note how they use MUST/SHOULD/MAY

## Relationship with Agents
- **Agents can do:** Draft specs from a PRD, generate test skeletons from ACs, **point out the gaps a spec has not answered (the most valuable of these)**
- **Agents cannot do:** Define invariants, decide what is in scope, be accountable when the spec is wrong

## Signals the Team Lacks This Skill
- Unusually low agent block rate (meaning it is guessing, not that the spec is good)
- Rework rate above 25%
- Many questions during implementation, of a kind that should have been answered up front
