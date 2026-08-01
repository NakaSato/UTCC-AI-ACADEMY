---
id: SKILL-AI-004
name: Agent Orchestration
category: ai-era
phases: [3]
roles: [agent-orchestrator, tech-lead, platform-engineer]
required_level: proficient
agent_delegable: false
agent_trend: new
related: [SKILL-AI-001, SKILL-AI-003, SKILL-ARCH-004]
review_by: 2027-01-31
---

# Agent Orchestration

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-AI-001 — Context Engineering](skill-ai-001-context-engineering.md) · [SKILL-AI-003 — Review at Scale](skill-ai-003-review-at-scale.md) · [SKILL-ARCH-004 — Threat Modeling](skill-arch-004-threat-modeling.md)

## Definition
The ability to configure and control how agents operate at the system level — tool scope, permissions, budgets, concurrency, and emergency stop mechanisms.

## Why It Matters Now
A new skill that nobody teaches yet, but one that becomes necessary the moment more than one agent is running, or an agent runs without someone watching it continuously — a state every team will reach within a few months.

## Levels
### Foundation
- Can set an agent up to work with a repo
- Knows what the agent has access to

### Proficient
- Defines tool scope and restricted credentials on least-privilege lines
- Sets budget and concurrency ceilings tied to review capacity
- Gives agents a separate identity so the audit trail can be distinguished from humans'

### Expert
- Designs admission control and backpressure that actually work
- Designs a kill switch that works even when other systems are down, and tests it regularly
- Prevents prompt injection at the architectural level (separating instructions from data, egress allowlists)

## How to Assess
Ask:
1. "If an agent started doing the wrong thing right now, how many seconds would it take you to stop it?"
2. "What credentials do your agents hold, and can they reach production?"
3. "If someone planted text in a file the agent reads, telling it to do something else, what happens?"

Unable to answer question 3 = not yet Proficient for systems where agents run autonomously.

## Development Path
1. Audit what the agents on your current project can actually reach
2. Set up separate identities and credentials for agents
3. Cap the number of open PRs, then watch whether team behaviour changes
4. Test the kill switch as a game day every quarter

## Relationship with Agents
- **Agents can do:** Should not be delegated — an agent that defines its own boundaries is a structural risk
- **Note:** an agent can help write the config, but approval must be human

## Signals the Team Lacks This Skill
- No kill switch, or one that has never been tested
- Agents using the same credentials as humans
- No budget ceiling
