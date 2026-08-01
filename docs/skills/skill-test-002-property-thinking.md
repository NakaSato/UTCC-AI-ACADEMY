---
id: SKILL-TEST-002
name: Property-Based Thinking
category: testing
phases: [2, 4]
roles: [qa, sdet, backend-engineer, architect]
required_level: proficient
agent_delegable: assisted
agent_trend: rising-critical
related: [SKILL-SPEC-002, SKILL-TEST-001]
review_by: 2027-01-31
---

# Property-Based Thinking

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-SPEC-002 — Invariant Identification](skill-spec-002-invariant-identification.md) · [SKILL-TEST-001 — Test Design](skill-test-001-test-design.md)

## Definition
The ability to think in terms of **properties that must hold for every input** rather than in terms of one example at a time.

## Why It Matters Now
Example-based tests only test the cases the author thought of — the same set the agent thought of while writing the code. The result is a fully passing suite over a system that is still wrong in the cases nobody imagined. Property tests are the only tool that escapes this trap.

## Levels
### Foundation
- Understands the difference between an example test and a property test

### Proficient
- Identifies checkable properties: round-trip (encode then decode returns the original), idempotency, commutativity, invariants that hold after an operation
- Writes property tests with the library the team uses (proptest, QuickCheck, Hypothesis, jqwik)
- Designs generators that produce meaningful inputs

### Expert
- Finds properties in domains where it is not obvious there are any
- Uses shrinking to reduce a failing case to the smallest example, then interprets it
- Uses property tests to check concurrency and state machines

## How to Assess
Give the function `merge_orders(a, b)` and ask what the properties are.
- Answering with example inputs/outputs = Foundation
- Answering "merge(a,b) = merge(b,a)" and "merge(a, empty) = a" = Proficient
- Adding "the sum of items after merging = the sum before merging" and seeing properties tied to business invariants = Expert

## Development Path
1. Take 5 pure functions in the system and write 3 properties for each
2. Practise looking for the standard properties: round-trip, idempotent, invariant, oracle (comparison against a slow but certainly correct implementation)
3. Apply property tests to business logic that touches money first
4. Read the property tests of the libraries used in real projects

## Relationship with Agents
- **Agents can do:** Write property tests once the properties are given, build generators, tune shrinking
- **Agents cannot do:** Identify what the properties are — that is domain knowledge, not pattern matching

## Signals the Team Lacks This Skill
- Every test in the repo is example-based
- The most common bug report is "we didn't think of this case"
