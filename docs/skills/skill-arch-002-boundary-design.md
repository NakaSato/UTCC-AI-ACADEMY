---
id: SKILL-ARCH-002
name: Boundary & Module Design
category: architecture
phases: [1, 3]
roles: [architect, tech-lead]
required_level: expert
agent_delegable: false
agent_trend: rising-critical
related: [SKILL-ARCH-001, SKILL-ARCH-003, SKILL-CODE-002]
review_by: 2027-01-31
---

# Boundary & Module Design

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-ARCH-001 — Trade-off Analysis](skill-arch-001-tradeoff-analysis.md) · [SKILL-ARCH-003 — Data Modeling](skill-arch-003-data-modeling.md) · [SKILL-CODE-002 — API Design](skill-code-002-api-design.md)

## Definition
The ability to divide a system into parts with clear boundaries that can change independently, and to enforce those boundaries with tooling rather than with agreements.

## Why It Matters Now
This is the fastest-appreciating skill in the architecture group — agents work very well within narrow boundaries and clear interfaces, but will spread the wrong pattern across an entire repo within a day if the boundaries are loose. A badly designed boundary now costs several times what it used to.

## Levels
### Foundation
- Works within the existing structure without breaking it
- Knows what each layer is supposed to do

### Proficient
- Divides modules by domain rather than by technical type
- Designs public interfaces that genuinely hide internal detail
- Sets up fitness functions (ArchUnit / NetArchTest / Packwerk) to enforce boundaries

### Expert
- Sees where boundaries should sit from historical change patterns rather than from theory
- Decides when modules should be merged and when they should be split
- Designs a migration path off the old structure without halting development

## How to Assess
Give a real codebase and ask: "if we had to change how fees are calculated, how many files and how many modules would we touch?"
Someone who answers immediately with "one module" = the system has good boundaries and they understand it.
Someone who has to go and look = the boundaries are loose, or they cannot yet see the shape of the system.

## Development Path
1. Set up one fitness function in the current project, then see how many violations exist
2. Analyse the git log: which files are always changed together — that is the real boundary, not the drawn one
3. Read up on Domain-Driven Design, focusing on bounded contexts rather than tactical patterns
4. Practise writing a `package.yml` / module descriptor with the rationale for every dependency

## Relationship with Agents
- **Agents can do:** Detect violations, refactor code to fit already-defined boundaries, build adapters
- **Agents cannot do:** Decide where a boundary should sit — because that requires knowing where the business is heading

## Signals the Team Lacks This Skill
- A tiny change requires editing 15 files across 5 modules
- No fitness functions of any kind in the project
- Folder structure divided by type (controllers/, services/, models/) in an already-large system
