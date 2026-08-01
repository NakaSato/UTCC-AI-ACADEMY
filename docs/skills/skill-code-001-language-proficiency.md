---
id: SKILL-CODE-001
name: Language Proficiency
category: coding
phases: [3]
roles: [backend-engineer, frontend-engineer, devops]
required_level: proficient
agent_delegable: true
agent_trend: declining
related: [SKILL-CODE-002, SKILL-AI-002]
review_by: 2027-01-31
---

# Language Proficiency

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-CODE-002 — API Design](skill-code-002-api-design.md) · [SKILL-AI-002 — Agent Output Verification](skill-ai-002-agent-output-verification.md)

## Definition
Fluency in the language and ecosystem in use — its idioms, standard library, tooling, community-accepted patterns, and the constraints you have to know about.

## Why It Matters Now
**This skill is losing value on the production side** but **remains non-negotiable on the verification side** — if you cannot read the code an agent wrote, you cannot verify it, and once verification fails the whole flow collapses.

An important caveat: verification skill is built only from the experience of getting it wrong yourself. Anyone who skips writing code entirely will never develop SKILL-AI-002.

## Levels
### Foundation
- Writes working code by following available examples
- Reads and understands other people's code in that language

### Proficient
- Writes idiomatic code without needing examples
- Knows the runtime's constraints (GC, GIL, memory model, async model)
- Chooses data structures that fit the problem

### Expert
- Understands how the code is actually compiled and executed at a lower level
- Tunes performance on the basis of measurement, not guesswork
- Knows which idioms to break, and when

## How to Assess
Give them 150 lines of agent-written code and ask them to point out the problems within 10 minutes.
Measure **reading ability**, not writing ability — that is what has changed.

## Development Path
1. Read the source of the libraries you use most
2. Write code without an agent once a week, to keep a feel for what is hard and what is easy
3. Review other people's code more than you write your own
4. Study the runtime of your language at least one layer deeper than you currently work

## Relationship with Agents
- **Agents can do:** Write implementations, refactor, port between languages, boilerplate, unit tests — nearly all of it
- **Agents cannot do:** Judge whether the code they wrote is correct

## Signals the Team Lacks This Skill
- Reviews take unusually little time relative to diff size
- Nobody can explain how this part of the code works
