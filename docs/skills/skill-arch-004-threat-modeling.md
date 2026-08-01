---
id: SKILL-ARCH-004
name: Threat Modeling
category: architecture
phases: [1]
roles: [security-engineer, architect, tech-lead]
required_level: proficient
agent_delegable: assisted
agent_trend: rising
related: [SKILL-BLD-002, SKILL-AI-004]
review_by: 2027-01-31
---

# Threat Modeling

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-BLD-002 — Supply Chain Security](skill-bld-002-supply-chain-security.md) · [SKILL-AI-004 — Agent Orchestration](skill-ai-004-agent-orchestration.md)

## Definition
The ability to look at a system from an attacker's point of view — identifying what is valuable enough to be attacked, where the ways in are, and whether the things we treat as "trusted" really are.

## Why It Matters Now
Systems with AI agents add a whole new attack surface — prompt injection via ticket/PR comments, credentials the agent can reach, dependencies the agent adds on its own, egress nobody restricts. This is no longer only the security team's concern.

## Levels
### Foundation
- Knows the OWASP Top 10 and can spot known risky patterns in code

### Proficient
- Can run STRIDE or an equivalent framework over a new feature
- Can clearly identify the trust boundaries in the system
- Separates authentication from authorization in the design

### Expert
- Sees vulnerabilities that arise from the composition of parts that are each individually secure
- Assesses which controls are worth the cost and which are ritual
- Designs systems that limit the damage after a breach, not just prevent one

## How to Assess
Ask them to design: "an agent reads a ticket from Jira and writes code accordingly", then ask what the risks are.
- Never mentions prompt injection = Foundation
- Mentions injection and proposes separating instructions from data = Proficient
- Mentions egress control, credential scope, and limiting post-breach damage = Expert

## Development Path
1. Threat-model the feature you are about to build, in 30 minutes, using STRIDE
2. Draw the trust boundaries of the current system, then ask of each line: "if that side is taken over, what happens?"
3. Read one other company's incident report every month
4. Practise attacking your own system in a test environment

## Relationship with Agents
- **Agents can do:** Detect known patterns, summarise CVEs, draft a first-pass threat model from an architecture diagram
- **Agents cannot do:** Judge what is valuable enough to be attacked in our business context, decide what level of risk is acceptable

## Signals the Team Lacks This Skill
- Security first gets involved just before release
- Nobody can say what the agents have access to
- People assume "internal system" means safe
