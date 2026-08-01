---
id: SKILL-TEST-003
name: Test Data Management
category: testing
phases: [4]
roles: [qa, sdet, backend-engineer, data-engineer]
required_level: proficient
agent_delegable: true
agent_trend: rising
related: [SKILL-TEST-001, SKILL-ARCH-004]
review_by: 2027-01-31
---

# Test Data Management

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-TEST-001 — Test Design](skill-test-001-test-design.md) · [SKILL-ARCH-004 — Threat Modeling](skill-arch-004-threat-modeling.md)

## Definition
The ability to source and manage test data that is **realistic enough to trust** and **deterministic enough to reproduce**, without violating privacy.

## Why It Matters Now
Agents run the test suite repeatedly in a self-verify loop. If the test data is not deterministic, tests turn flaky, which sends the agent round in circles fixing code that was never wrong, burning both time and budget.

## Levels
### Foundation
- Uses the existing factories/fixtures
- Creates test data for simple cases

### Proficient
- Designs composable, deterministic factories (fixed seed)
- Isolates data between tests so nothing leaks across
- Manages data for integration tests that need a real DB

### Expert
- Designs a system-wide data strategy, including anonymising real data
- Manages data for testing migrations and backward compatibility
- Makes the suite runnable in parallel without collisions

## How to Assess
Ask: "this test passes on its own but fails when the whole suite runs — what could cause that?"
A good answer covers: shared state, run order, data not being cleaned up, time/randomness not frozen, assumptions about autoincrement ids.

## Development Path
1. Audit the current suite for tests that depend on run order
2. Freeze time and the random seed in every test
3. Make the suite run in parallel and see what breaks — what breaks is the hidden shared state
4. Adopt a policy against using production data containing PII, even masked

## Relationship with Agents
- **Agents can do:** Build factories, generate synthetic data, find tests that depend on shared state
- **Agents cannot do:** Judge what data is realistic enough, set PII policy

## Signals the Team Lacks This Skill
- Flaky tests fixed by adding retries
- Tests that only pass when run in a specific order
- Production data copied over for testing
