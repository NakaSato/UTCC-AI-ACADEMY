---
id: SKILL-HUM-003
name: Review Feedback
category: human
phases: [3]
roles: [tech-lead, engineering-manager, backend-engineer, frontend-engineer]
required_level: proficient
agent_delegable: false
agent_trend: rising
related: [SKILL-AI-002, SKILL-HUM-001]
review_by: 2027-01-31
---

# Review Feedback

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-AI-002 — Agent Output Verification](skill-ai-002-agent-output-verification.md) · [SKILL-HUM-001 — Written Communication](skill-hum-001-written-communication.md)

## Definition
The ability to comment on someone else's work in a way that makes the work better and leaves them wanting to keep working — separating comments that must be acted on from comments that are taste.

## Why It Matters Now
The role has changed in two ways. First: time that used to go into writing code has moved into reviewing, so this skill takes up a larger share of the job. Second: when someone submits an agent-written diff, feedback has to distinguish between critiquing a person's decisions and critiquing a machine's output — which changes both the tone and the substance of what should be said.

## Levels
### Foundation
- Points out problems clearly
- Uses polite language

### Proficient
- Distinguishes levels of comment: must fix / worth considering / just an opinion (nit)
- Explains the reasoning instead of just asking for a change
- Also praises what was done well rather than only flagging problems

### Expert
- Gives feedback that teaches a principle rather than fixing one case
- Knows when to switch to a voice conversation instead of typing (when the disagreement is structural)
- Builds a culture where people feel safe showing unfinished work

## How to Assess
Look back at 20 review comments and count:
- what % state a level of importance
- what % explain the reasoning
- what % are pure taste but are written as though mandatory

## Development Path
1. Prefix every comment: `[must]` `[consider]` `[nit]`
2. Force yourself to write at least one sentence of reasoning per comment
3. Review afterwards: how many of your comments actually made the work better?
4. Ask the people receiving feedback which comments were most useful and which were noise

## Relationship with Agents
- **Agents can do:** Flag technical problems that can be checked automatically (which should become linter rules rather than comments)
- **Agents cannot do:** Teach, build trust, decide whether a point is worth insisting on

## Signals the Team Lacks This Skill
- Most review comments are about formatting a linter should catch
- People are afraid to open a PR
- Taste-based comments leave PRs stalled for days
