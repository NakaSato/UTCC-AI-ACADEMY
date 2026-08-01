---
id: SKILL-HUM-001
name: Written Communication
category: human
phases: [0, 1, 2, 3, 4, 5, 6, 7, 8]
roles: [all]
required_level: expert
agent_delegable: assisted
agent_trend: rising-critical
related: [SKILL-HUM-002, SKILL-SPEC-001]
review_by: 2027-01-31
---

# Written Communication

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-HUM-002 — Decision Documentation](skill-hum-002-decision-documentation.md) · [SKILL-SPEC-001 — Spec Writing](skill-spec-001-spec-writing.md)

## Definition
The ability to write so that someone who was not part of the conversation understands without having to ask — in the shortest form that is still complete.

## Why It Matters Now
When the entire process is markdown and asynchronous, this ability directly sets the pace of the whole team. And when agents read our documents as context, an ambiguously written document becomes wrong code immediately — a skill once dismissed as "soft" is now a technical requirement.

## Levels
### Foundation
- Explains what was done in a way people understand
- Uses structure (headings, bullets) to aid reading

### Proficient
- Writes starting from the conclusion rather than from the background
- Adjusts depth to the reader (executives vs engineers)
- Writes complex things briefly without losing meaning

### Expert
- Writes documents that let readers decide immediately, without a meeting
- Anticipates the reader's questions and answers them in advance, in the right order
- Writes clearly about things they are unsure of, stating the uncertainty plainly

## How to Assess
Have them write an ADR or status update, then give it to someone not involved in the topic.
- More than 2 follow-up questions = not yet Proficient
- The reader can act on it immediately = Expert

## Development Path
1. Practise making the first paragraph the conclusion, every time (BLUF — bottom line up front)
2. Write, then cut 30% without losing meaning; do this for every document for a month
3. Ask for feedback on where readers had to re-read — that is where the writing is unclear
4. Read well-written ADRs and RFCs in open source projects

## Relationship with Agents
- **Agents can do:** Polish the language, restructure, condense, translate, flag ambiguity
- **Agents cannot do:** Know what the reader actually needs, decide what is important enough to write — and text an agent has polished until it is too smooth can bury uncertainty that ought to be communicated

## Signals the Team Lacks This Skill
- Meetings are needed to explain what has already been written
- Documents are long but nobody finishes them
- The same question gets asked over and over
