---
id: SKILL-SPEC-003
name: Ambiguity Detection
category: specification
phases: [2]
roles: [spec-owner, business-analyst, qa, tech-lead]
required_level: expert
agent_delegable: true
agent_trend: rising-critical
related: [SKILL-SPEC-001, SKILL-AI-001]
review_by: 2027-01-31
---

# Ambiguity Detection

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-SPEC-001 — Spec Writing](skill-spec-001-spec-writing.md) · [SKILL-AI-001 — Context Engineering](skill-ai-001-context-engineering.md)

## Definition
The ability to read a document and see **what has not been written** — edge conditions, empty cases, conflicting cases, and the points where two people will read it differently.

## Why It Matters Now
Ambiguity that reaches the implementation layer costs exponentially more, and it costs more now than it used to, because an agent will turn ambiguity into good-looking code within minutes. That makes it harder to catch than when a human wrote slowly and came over to ask.

## Levels
### Foundation
- Asks questions when something is not understood

### Proficient
- Checks systematically: empty cases, negative values, duplicates, timeouts, concurrency, permissions
- Spots contradictions between two paragraphs of the same document

### Expert
- Spots what was never written at all and should have been (missing requirements, not just unclear ones)
- Ranks ambiguities by impact on scope rather than by the order they were found
- Knows which ambiguities to resolve now and which can wait until they actually come up

## How to Assess
Give a spec with 8 planted holes (some of them missing requirements) and allow 15 minutes.
- Finds 3–4 = Proficient
- Finds 6+ and ranks them by impact = Expert
- Finds only the ambiguously worded parts and misses what is absent = not yet Expert

## Development Path
1. Build a personal checklist: null/empty, boundaries, duplicates, concurrency, timeouts, permissions, i18n, migration of existing data
2. Every time a bug comes from a requirement, add that pattern to the checklist
3. **Use an agent as a sparring partner** — have it find gaps in your spec, and see what it spots that you did not
4. Practise reading other people's specs with a target of finding 5 gaps before commenting

## Relationship with Agents
- **Agents can do:** **This is something agents do very well and should be used for fully** — the highest-return prompt is "read this spec and tell me what is still unanswered, ordered by impact on scope, without writing any code yet"
- **Agents cannot do:** Decide which ambiguity matters enough to stop work over

## Signals the Team Lacks This Skill
- Most questions arise during implementation rather than during spec review
- Very low agent block rate (it guesses instead of asking, because nothing signals ambiguity)
