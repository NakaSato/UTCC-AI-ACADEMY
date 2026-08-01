---
id: SKILL-AI-001
name: Context Engineering
category: ai-era
phases: [3]
roles: [backend-engineer, frontend-engineer, agent-orchestrator, spec-owner]
required_level: proficient
agent_delegable: false
agent_trend: new
related: [SKILL-SPEC-001, SKILL-AI-002]
review_by: 2027-01-31
---

# Context Engineering

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-SPEC-001 — Spec Writing](skill-spec-001-spec-writing.md) · [SKILL-AI-002 — Agent Output Verification](skill-ai-002-agent-output-verification.md)

## Definition
The ability to prepare the context an agent needs to do the work correctly — deciding what belongs in context and what does not, the sequence that produces the best results, and how to size the work so the agent handles it well.

## Why It Matters Now
An entirely new skill, and a multiplier on everything an agent does. The gap between someone who has it and someone who does not shows up as a several-fold difference in output from the very same agent.

## Levels
### Foundation
- Writes clear instructions that state the desired outcome and output format
- Attaches the relevant files

### Proficient
- **Breaks work down small enough to be verifiable** — the single most important indicator at this level
- Selects genuinely relevant context instead of dumping the whole repo (lowers token cost and reduces confusion)
- Uses the right sequence: find the gaps first → confirm → then implement
- Provides examples of what is wanted and what is not

### Expert
- Designs an `AGENTS.md` / working agreement that improves results for the whole team, not just themselves
- Knows which kinds of work to hand to an agent and which are faster to do by hand
- Structures the repo and its documentation so agents work well from the start (frontmatter, boundaries, naming)

## How to Assess
Give the same task to two people, using the same agent, then measure:
- Number of correction rounds before the result is usable
- Size of the resulting diff (too large = poor decomposition)
- Number of questions the agent asked back (zero on complex work = not enough context, so it guessed)

## Development Path
1. Start every task with "read this spec and tell me what is still unanswered" before ever asking for an implementation
2. Practise splitting work so no diff exceeds 300 lines at a time
3. Write an `AGENTS.md` for your own project, then measure whether rework drops
4. Track which kinds of work need the most correction after an agent does them, then stop delegating those

## Relationship with Agents
- **Agents can do:** Nothing — this is the skill of using agents
- **Note:** an agent can help improve its own prompts, but judging whether the result actually got better remains a human call

## Signals the Team Lacks This Skill
- Agent diffs so large nobody wants to review them
- The same work has to be redone over several rounds
- Rework rate above 25%
