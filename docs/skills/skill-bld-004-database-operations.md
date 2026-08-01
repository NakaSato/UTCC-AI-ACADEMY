---
id: SKILL-BLD-004
name: Database Operations
category: build
phases: [6]
roles: [backend-engineer, sre, dba, devops]
required_level: expert
agent_delegable: assisted
agent_trend: rising
related: [SKILL-ARCH-003, SKILL-BLD-003]
review_by: 2027-01-31
---

# Database Operations

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-ARCH-003 — Data Modeling](skill-arch-003-data-modeling.md) · [SKILL-BLD-003 — Release Risk Assessment](skill-bld-003-release-risk-assessment.md)

## Definition
The ability to change schema and data on a live system without causing downtime and without corrupting data.

## Why It Matters Now
Migrations are **the one thing in most systems that genuinely cannot be rolled back**, and they are something agents write very quickly and often get wrong — for example `add_index` without `concurrently`, which locks the whole table in production. This is why migrations should automatically be Tier C every time.

## Levels
### Foundation
- Writes basic migrations and runs them on dev
- Understands what an index is

### Proficient
- Separates schema changes from code changes (expand → migrate → contract)
- Uses `concurrently` and understands which operations lock what
- Reads explain plans and assesses impact before running

### Expert
- Backfills large volumes of data incrementally without affecting production
- Assesses the impact of a migration on a large table from real data, not from dev
- Designs schema changes that can be deployed while two versions of the code run side by side

## How to Assess
Give the problem: "rename the column `amount` to `amount_cents` on a table with 50 million rows, and the system must not go down."
- Answering `rename_column` = dangerous, not yet Proficient
- Answering with multiple phases (add the new column → write to both → backfill incrementally → read from the new one → drop the old one in a later release) = Proficient or above
- Also specifying the backfill batch size and checking replication lag = Expert

## Development Path
1. Install tooling that blocks dangerous migrations (strong_migrations or equivalent)
2. Practise running migrations against a dataset close to production size
3. Practise reading explain plans and experiment with which operations lock what
4. Study the expand-migrate-contract pattern and run through one full cycle for real

## Relationship with Agents
- **Agents can do:** Draft migrations, write backfill scripts, generate rollback migrations
- **Agents cannot do:** Judge whether a migration is safe against real data — a human has to read the explain plan every time

## Signals the Team Lacks This Skill
- Downtime has been caused by a migration before
- Migrations are always deployed together with code changes
- Nobody knows the size of the table about to be changed
