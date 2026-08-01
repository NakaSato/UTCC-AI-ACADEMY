---
id: SKILL-BLD-001
name: CI/CD Engineering
category: build
phases: [5]
roles: [devops, platform-engineer, tech-lead]
required_level: proficient
agent_delegable: assisted
agent_trend: stable
related: [SKILL-BLD-002, SKILL-BLD-003]
review_by: 2027-01-31
---

# CI/CD Engineering

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-BLD-002 — Supply Chain Security](skill-bld-002-supply-chain-security.md) · [SKILL-BLD-003 — Release Risk Assessment](skill-bld-003-release-risk-assessment.md)

## Definition
The ability to build a pipeline that checks and delivers every change consistently — fast enough that nobody wants to skip it, and reliable enough that nobody doubts its results.

## Why It Matters Now
One thing about the context has changed significantly: agents run the pipeline many times over for a single task, so **CI speed has gone from a convenience to a direct multiplier on cost**. A pipeline that takes 15 minutes makes every agent iteration several times more expensive.

## Levels
### Foundation
- Can modify an existing pipeline
- Can read the log and understand which step failed

### Proficient
- Designs new pipelines with caching, parallelisation, and fail-fast
- Separates fast stages from slow ones for a reason
- Handles secrets in the pipeline safely

### Expert
- Makes builds genuinely reproducible
- Designs pipelines that scale with team size without needing to be torn down
- Measures and improves CI time systematically

## How to Assess
Give them a pipeline that takes 20 minutes and ask how they would get it to 5.
A good answer: split jobs that can run in parallel, cache dependencies, run only the affected tests, move slow jobs to post-merge, and find the real bottleneck before changing anything.

## Development Path
1. Measure the time of each step in the current pipeline, then find the real bottleneck
2. Run the build twice and compare hashes — is it reproducible?
3. Add a cache layer, then measure how much it actually saves
4. Study the pipelines of large open source projects

## Relationship with Agents
- **Agents can do:** Write YAML config, add steps, fix syntax, propose cache strategies
- **Agents cannot do:** Decide which gates should block and which should merely warn — that is a question of the risk the organisation accepts

## Signals the Team Lacks This Skill
- CI takes over 10 minutes and nobody is trying to fix it
- People rerun jobs because "sometimes it passes"
- Secrets live in environment variables that can end up in logs
