---
id: SKILL-CODE-002
name: API Design
category: coding
phases: [1, 3]
roles: [backend-engineer, architect, frontend-engineer]
required_level: proficient
agent_delegable: assisted
agent_trend: stable
related: [SKILL-ARCH-002, SKILL-TEST-004]
review_by: 2027-01-31
---

# API Design

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-ARCH-002 — Boundary & Module Design](skill-arch-002-boundary-design.md) · [SKILL-TEST-004 — Contract Testing](skill-test-004-contract-testing.md)

## Definition
The ability to design interfaces that are easy to use, hard to misuse, and changeable without breaking existing consumers — both external APIs and interfaces between internal modules.

## Why It Matters Now
Its importance is unchanged, but the context is not: when agents write the code calling these APIs, an interface that is easy to misuse gets misused in many places at once within a day, rather than going wrong gradually one site at a time.

## Levels
### Foundation
- Follows the REST/gRPC conventions the team already uses
- Names endpoints and fields meaningfully

### Proficient
- Designs for "hard to misuse" — types that enforce correctness, safe defaults
- Handles versioning and backward compatibility
- Designs error responses that callers can genuinely act on

### Expert
- Designs APIs that reflect the domain rather than the table structure
- Anticipates the direction of change and leaves room without over-engineering
- Handles idempotency, pagination, and partial failure correctly

## How to Assess
Ask them to design an endpoint for "cancel an order", and see whether they mention:
- an idempotency key
- what happens on a repeated call / two simultaneous calls
- how many distinct error cases there are, and how a caller tells them apart

Never mentioning idempotency = not yet Proficient for work that touches money.

## Development Path
1. Read the APIs of well-designed services (Stripe, GitHub) and note how they handle errors and versioning
2. Practise writing the OpenAPI spec before the implementation
3. Use your own API as a genuine external client
4. Review breaking changes you have made — where did the design go wrong?

## Relationship with Agents
- **Agents can do:** Generate OpenAPI from code, generate clients, write handlers against a contract
- **Agents cannot do:** Decide how resources should be divided along domain lines

## Signals the Team Lacks This Skill
- Frequent breaking changes
- Every error comes back as the same 500 or 400
- Every client has to write the same workaround
