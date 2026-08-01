---
id: SKILL-AI-002
name: Agent Output Verification
category: ai-era
phases: [3, 4]
roles: [backend-engineer, frontend-engineer, tech-lead, qa, agent-orchestrator]
required_level: expert
agent_delegable: false
agent_trend: new
related: [SKILL-CODE-001, SKILL-AI-003, SKILL-TEST-001]
review_by: 2027-01-31
---

# Agent Output Verification

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-CODE-001 — Language Proficiency](skill-code-001-language-proficiency.md) · [SKILL-AI-003 — Review at Scale](skill-ai-003-review-at-scale.md) · [SKILL-TEST-001 — Test Design](skill-test-001-test-design.md)

## Definition
The ability to read an agent's output and judge whether it actually did what was intended — above all, catching **code that looks correct but does not match the intent**.

## Why It Matters Now
This is the most important skill in the AI-era group and the new bottleneck for the whole system. The main risk is not broken code — broken code gets caught by CI. It is code that **passes every gate and is still wrong**, because it answers the problem the agent understood rather than the problem we meant.

## Levels
### Foundation
- Reads and understands the code an agent wrote
- Checks whether tests and lint pass

### Proficient
- Checks against the spec point by point instead of skimming
- Knows where agents repeatedly slip: empty cases, error paths, off-by-one at boundaries, concurrency, overly broad exception catching, adding unnecessary dependencies
- Also checks what was **not** done, not just what was

### Expert
- Catches "technically correct but wrong for the domain" code
- Assesses the long-term consequences of any pattern that was introduced
- Knows when to throw the diff away and start over instead of patching it

## How to Assess
Provide an agent diff with 5 planted problems, 2 of which are domain issues rather than syntax, and where all tests pass.
- Finds only the technical ones = Proficient
- Finds the domain ones as well = Expert
- Says "looks good" = not yet ready to review Tier C work

## Development Path
1. Have an agent write code where you already know the answer, then find where it drifts. Repeat until the patterns become visible
2. **Keep a personal log of where agents went wrong**, then build a checklist from the recurring patterns
3. Practise reading a diff line by line against the spec, not just reading the code
4. Keep writing some code yourself — this skill is built only from the experience of getting it wrong firsthand

## Relationship with Agents
- **Agents can do:** No — an agent checking an agent's work is a self-certifying system
- **Note:** a second agent can help flag suspicious spots, but the judgement must be human

## Signals the Team Lacks This Skill
- Review depth (review time ÷ diff size) steadily declining
- Approvals within minutes on large diffs
- Escaped defects rising despite high coverage
