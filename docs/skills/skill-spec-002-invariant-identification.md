---
id: SKILL-SPEC-002
name: Invariant Identification
category: specification
phases: [2]
roles: [spec-owner, architect, qa, backend-engineer]
required_level: expert
agent_delegable: false
agent_trend: rising-critical
related: [SKILL-SPEC-001, SKILL-TEST-002, SKILL-ARCH-003]
review_by: 2027-01-31
---

# Invariant Identification

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-SPEC-001 — Spec Writing](skill-spec-001-spec-writing.md) · [SKILL-TEST-002 — Property-Based Thinking](skill-test-002-property-thinking.md) · [SKILL-ARCH-003 — Data Modeling](skill-arch-003-data-modeling.md)

## Definition
The ability to identify **what must always be true**, whatever state the system is in, and to write it in a form that can be tested or enforced.

## Why It Matters Now
Acceptance criteria test "the cases we thought of", while invariants cover "the cases we did not" — which is exactly where agents fail most. They are very good at making the given examples pass, but have no domain understanding of what must never go wrong.

## Levels
### Foundation
- Understands the difference between "the expected result" and "what must always be true"

### Proficient
- Identifies entity-level invariants, e.g. a balance must never go negative
- Turns invariants into database constraints or property tests

### Expert
- Identifies cross-entity invariants, e.g. a double-entry ledger must always net to zero
- Identifies invariants under concurrency and partial failure
- Knows which invariants belong in the DB, which in the application, and which in tests

## How to Assess
Present a system that transfers money between accounts and ask what the invariants are.
- "The balance must be correct" = not an invariant, that is a wish
- "The sum across all accounts before and after a transfer must be equal" = Proficient
- Adding "even if the transaction fails midway" and "even with two simultaneous requests using the same key" = Expert

## Development Path
1. Take a domain you know well, write 10 invariants, then have someone else try to violate each one
2. Practise writing property-based tests instead of example-based ones for complex logic
3. Every time a bug occurs, ask "which invariant, had it existed, would have caught this?"
4. Study double-entry bookkeeping — the best-designed invariant in history

## Relationship with Agents
- **Agents can do:** Write property tests from given invariants, translate invariants into SQL constraints
- **Agents cannot do:** Identify what the invariants are — because they come from domain understanding, not from the text

## Signals the Team Lacks This Skill
- "Data in an impossible state" bugs occurring periodically
- All tests are example-based
- Specs have ACs but no invariants section at all
