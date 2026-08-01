---
id: SKILL-ARCH-003
name: Data Modeling
category: architecture
phases: [1, 2]
roles: [architect, backend-engineer, data-engineer]
required_level: expert
agent_delegable: assisted
agent_trend: rising
related: [SKILL-SPEC-002, SKILL-BLD-004]
review_by: 2027-01-31
---

# Data Modeling

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-SPEC-002 — Invariant Identification](skill-spec-002-invariant-identification.md) · [SKILL-BLD-004 — Database Operations](skill-bld-004-database-operations.md)

## Definition
The ability to design data structures that reflect the real rules of the domain, and to enforce correctness at the schema level rather than in code.

## Why It Matters Now
Bad code can be fixed; bad data cannot be recovered — and agents very easily write code that bypasses validation (`update_column`, `insert_all`, raw SQL). Database-level constraints have therefore become the real last line of defence.

## Levels
### Foundation
- Can design tables from clearly defined entities
- Can use foreign keys and basic indexes

### Proficient
- Normalises/denormalises for a reason rather than by formula
- Adds constraints (unique, check, not null) that reflect business rules
- Designs for change without needing a large migration every time

### Expert
- Designs state machines that can be enforced at the data level
- Handles temporal data, soft deletes, and audit trails correctly
- Anticipates performance problems from query patterns before they occur

## How to Assess
Give the requirement: "an order can only be cancelled while it has not yet been captured", then ask how they would enforce it.
- Answering "validate in the service layer" = Foundation
- Answering "check constraint + state column + unique index on the idempotency key" = Proficient or above
- Being able to explain what happens with two concurrent requests = Expert

## Development Path
1. Take 5 business rules in the current system and check how many are actually enforced in the DB
2. Practise writing check constraints and partial unique indexes
3. Study isolation levels and reproduce a real race condition locally
4. Read the transaction chapters of *Designing Data-Intensive Applications*

## Relationship with Agents
- **Agents can do:** Write migrations from an already-designed schema, suggest indexes from query patterns, check that schema and models agree
- **Agents cannot do:** Decide which business rules must become constraints, assess the impact of a schema change on existing data

## Signals the Team Lacks This Skill
- The database contains states that are "impossible" under the business rules
- Validation exists only in code, never in the schema
- Data-repair scripts have to be written regularly
