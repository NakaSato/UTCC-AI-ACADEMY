---
id: SKILL-TEST-004
name: Contract Testing
category: testing
phases: [1, 4]
roles: [qa, sdet, backend-engineer, architect]
required_level: proficient
agent_delegable: assisted
agent_trend: rising
related: [SKILL-CODE-002, SKILL-ARCH-002]
review_by: 2027-01-31
---

# Contract Testing

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-CODE-002 — API Design](skill-code-002-api-design.md) · [SKILL-ARCH-002 — Boundary & Module Design](skill-arch-002-boundary-design.md)

## Definition
The ability to define and enforce the agreement between two systems so that provider and consumer can both test against it without running at the same time.

## Why It Matters Now
As agents change many parts of the code at once and faster, changes that break consumers happen more often. Contract tests are the gate that catches them in CI rather than in an integration environment, or worse, in production.

## Levels
### Foundation
- Understands how a contract test differs from an integration test
- Can run the existing contract tests

### Proficient
- Writes contracts from the consumer side and has the provider verify them
- Uses tooling (Pact, rswag, OpenAPI validators) in CI
- Manages contract versioning when there are several consumers

### Expert
- Designs contracts loose enough not to be brittle but strict enough to be useful
- Manages contracts across teams and across organisations
- Uses contracts as a design tool, not merely a testing tool

## How to Assess
Ask: "if we add a new field to the response, does that break consumers? And what if we change the type of an existing field?"
The answer should distinguish what is backward compatible from what is not, and which of them contract tests should catch.

## Development Path
1. Set up contract tests between the two services that talk to each other most, first
2. Practise writing the OpenAPI spec before the implementation, then generating tests from it
3. Make a deliberate breaking change and see whether the contract tests catch it
4. Study the difference between consumer-driven and provider-driven contracts

## Relationship with Agents
- **Agents can do:** Write contract tests from a spec, generate them from OpenAPI, check compatibility between versions
- **Agents cannot do:** Decide what belongs in the contract and what should stay an internal detail free to change

## Signals the Team Lacks This Skill
- Integrations frequently break at deploy time
- Several services always have to be deployed together
- Nobody knows who is using which endpoint
