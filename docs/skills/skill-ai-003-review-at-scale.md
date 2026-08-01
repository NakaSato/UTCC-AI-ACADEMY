---
id: SKILL-AI-003
name: Review at Scale
category: ai-era
phases: [3]
roles: [tech-lead, agent-orchestrator, engineering-manager]
required_level: expert
agent_delegable: false
agent_trend: new
related: [SKILL-AI-002, SKILL-BLD-003]
review_by: 2027-01-31
---

# Review at Scale

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-AI-002 — Agent Output Verification](skill-ai-002-agent-output-verification.md) · [SKILL-BLD-003 — Release Risk Assessment](skill-bld-003-release-risk-assessment.md)

## Definition
The ability to manage review when the volume of work exceeds anyone's capacity to read all of it — deciding **where to read closely and where automation is trustworthy enough**.

## Why It Matters Now
Once throughput rises 5–10×, reading every diff closely becomes impossible. Most teams drift into rubber-stamping without anyone deciding to. This skill makes the allocation of human attention deliberate rather than an act of surrender.

## Levels
### Foundation
- Reviews PRs one at a time in arrival order

### Proficient
- Prioritises by risk rather than by submission time
- Uses the results of upstream gates so as not to re-check what automation already checked
- Asks for work to be split when a diff is too large to review meaningfully

### Expert
- Designs risk tiers and policies that put human attention where it pays off most
- Manages capacity: knows how many items the team can actually review per day, and sets WIP limits from that number
- Detects rubber-stamping signals in the team and fixes the system rather than the people

## How to Assess
Give the scenario: 25 PRs are waiting, and the team has 4 hours total today. Ask how they would handle it.
- Reviews them in order = Foundation
- Prioritises by risk and asks for oversized work to be split = Proficient
- Asks why there are 25 PRs when capacity is 9, and proposes backpressure = Expert

## Development Path
1. Measure how many items the team really reviews per day, then cap open PRs at that number
2. Assign risk tiers for the current repo based on the paths touched
3. Measure review depth (time ÷ diff size) weekly and watch the trend
4. Try auto-merge for Tier A with audit sampling, then measure escaped defects

## Relationship with Agents
- **Agents can do:** Summarise diffs, flag suspicious spots, group PRs by risk, check policy automatically
- **Agents cannot do:** Decide what is trustworthy enough — because that is accepting risk

## Signals the Team Lacks This Skill
- PRs persistently backed up beyond capacity
- Review depth falling every month
- Every PR gets equal attention regardless of what it touches
