---
id: SKILL-CODE-003
name: Concurrency & Distributed Systems
category: coding
phases: [3]
roles: [backend-engineer, architect, sre]
required_level: expert
agent_delegable: assisted
agent_trend: rising
related: [SKILL-ARCH-003, SKILL-CODE-004]
review_by: 2027-01-31
---

# Concurrency & Distributed Systems

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-ARCH-003 — Data Modeling](skill-arch-003-data-modeling.md) · [SKILL-CODE-004 — Production Debugging](skill-code-004-production-debugging.md)

## Definition
The ability to write and review code that runs along several paths at once, or is distributed across machines, with an understanding of what cannot be guaranteed.

## Why It Matters Now
This is an area where agents fail often and invisibly — code with a race condition passes every test on a dev machine and only breaks under real load. No static analysis catches all of it, which leaves human review by someone with this skill as the only defence.

## Levels
### Foundation
- Understands the difference between concurrency and parallelism
- Uses basic primitives (mutex, channel, async/await) by following examples

### Proficient
- Identifies critical sections and picks appropriate protection mechanisms
- Understands transaction isolation levels and what each one implies
- Designs safe retries (idempotent + backoff + jitter)

### Expert
- Analyses the failure modes of distributed systems (partial failure, network partition, clock skew)
- Designs a consistency model that fits the actual requirement rather than reaching for strong consistency every time
- Reads code and sees race conditions that have not happened yet

## How to Assess
Give code with a planted race condition (for example check-then-act on a balance) and ask them to find it within 10 minutes.
Follow up: "if two requests arrive at once, what happens, and how would you fix it without locking the whole table?"

## Development Path
1. Reproduce a real race condition locally with a load test — you have to see it to understand it
2. Study the isolation levels of the DB you use, and experiment with each
3. Read *Designing Data-Intensive Applications*, chapters 7–9
4. Practise writing property tests that run the same code in parallel and check invariants

## Relationship with Agents
- **Agents can do:** Write async code following standard patterns, add retry/backoff, convert sync to async
- **Agents cannot do:** Verify that the code they wrote is safe under concurrency — a human with this skill must read it every time for Tier C work

## Signals the Team Lacks This Skill
- Bugs that "happen sometimes" and get closed by adding a retry
- Nobody can say which isolation level is in use
