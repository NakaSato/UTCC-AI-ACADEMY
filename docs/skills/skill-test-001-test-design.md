---
id: SKILL-TEST-001
name: Test Design
category: testing
phases: [2, 4]
roles: [qa, sdet, spec-owner, backend-engineer]
required_level: expert
agent_delegable: false
agent_trend: rising-critical
related: [SKILL-SPEC-002, SKILL-TEST-002]
review_by: 2027-01-31
---

# Test Design

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-SPEC-002 — Invariant Identification](skill-spec-002-invariant-identification.md) · [SKILL-TEST-002 — Property-Based Thinking](skill-test-002-property-thinking.md)

## Definition
The ability to design a test suite that **proves the system is correct** rather than merely **showing that it runs**, and to choose what should be tested at which level.

## Why It Matters Now
When agents write most of the implementation, tests become the only definition of "correct" still under human control. If agents write the tests as well, the system becomes entirely self-certifying — which is why acceptance tests must always sit under human CODEOWNERS.

## Levels
### Foundation
- Writes tests for the cases stated in the ACs
- Understands the test pyramid

### Proficient
- Designs test cases using systematic techniques (equivalence partitioning, boundary values, decision tables)
- Chooses the level of testing that pays off, rather than testing everything at E2E
- Designs tests that, on failure, say immediately what broke

### Expert
- Designs suites that catch classes of bug nobody thought of
- Assesses the quality of the test suite itself (mutation testing, not just coverage)
- Judges which parts are not worth testing

## How to Assess
Give a discount calculation function with 4 levels of nested conditions and have them design test cases.
- Writes what the spec's examples show = Foundation
- Uses boundary values and a decision table covering every branch = Proficient
- Adds property tests and states what the example tests cannot catch = Expert

Additional check: run mutation testing against the suite they wrote — the mutation score tells more truth than coverage.

## Development Path
1. Learn systematic test-case design techniques rather than writing by instinct
2. Run mutation testing against the current suite and see how many mutants survive
3. Every time a bug escapes to production, ask "what kind of test would have caught this?" and add it
4. Practise writing tests before code for complex logic

## Relationship with Agents
- **Agents can do:** Write large numbers of unit tests, build test data, turn test cases into code
- **Agents cannot do:** **Design acceptance tests and contract tests** — because those are the definition of "correct". If an agent writes them, it optimises for the tests passing, not for the system being right

## Signals the Team Lacks This Skill
- High coverage but plenty of bugs still escaping
- Failing tests that leave nobody any wiser about what broke
- Every test covers the happy path
