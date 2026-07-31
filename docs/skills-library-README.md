---
title: Skill Library
---

# Skill Library
### Skills for the System Development Flow, referenced by specs, tasks, and roles

> [Skill Directory](skills/README.md) ·
> [Project Development Flow](development-flow.md) ·
> [System Development Flow Master](system-development-flow-master.md) ·
> [Workflow Guide for All Roles](system-development-flow-role-guide.md) ·
> [Skill Authoring Template](skills/template.md)

> Every skill is a Markdown file with an `id` that other documents can reference
> in their frontmatter. For example, `spec-pay-1042.md` can declare
> `requires_skills: ["SKILL-SPEC-001", "SKILL-TEST-001"]`, allowing the team to
> decide who should perform a task from explicit evidence instead of intuition.
> Every detailed skill links to the project, role, and master flows, and each
> flow links back to all 34 skills.

---

## Skill Level Definitions

| Level | Meaning | Assessment Standard |
| --- | --- | --- |
| **Foundation (F)** | Can follow an established approach with review | Completes work successfully when a close example exists |
| **Proficient (P)** | Can perform most work independently and knows when to ask | Handles cases without an exact precedent |
| **Expert (E)** | Can design approaches for others and make decisions under uncertainty | Others regularly seek this person's guidance |

**Rule:** Work with `required_level: expert` must not be assigned to someone at
the Proficient level without Expert review. Work with
`agent_delegable: false` must never be delegated to an agent.

---

## Trends in the AI-Agent Era

| Symbol | Meaning |
| --- | --- |
| 🆕 | A newly relevant skill |
| ⬆️⬆️ | Much more important; prioritize investment |
| ⬆️ | More important |
| → | Unchanged |
| ⬇️ | Declining in value, but a minimum level remains necessary |

---

## Complete Skill Index (34)

### Product
| ID | Skill | Phase | Level | Agent | Trend |
|---|---|---|---|---|---|
| SKILL-PROD-001 | [Problem Framing](skills/skill-prod-001-problem-framing.md) | 0 | E | ❌ | ⬆️ |
| SKILL-PROD-002 | [Metric Design](skills/skill-prod-002-metric-design.md) | 0, 8 | P | ⚠️ | ⬆️ |
| SKILL-PROD-003 | [User Research](skills/skill-prod-003-user-research.md) | 0 | P | ⚠️ | → |
| SKILL-PROD-004 | [Prioritization](skills/skill-prod-004-prioritization.md) | 0 | E | ❌ | ⬆️ |

### Architecture
| ID | Skill | Phase | Level | Agent | Trend |
|---|---|---|---|---|---|
| SKILL-ARCH-001 | [Trade-off Analysis](skills/skill-arch-001-tradeoff-analysis.md) | 1 | E | ⚠️ | ⬆️⬆️ |
| SKILL-ARCH-002 | [Boundary & Module Design](skills/skill-arch-002-boundary-design.md) | 1, 3 | E | ❌ | ⬆️⬆️ |
| SKILL-ARCH-003 | [Data Modeling](skills/skill-arch-003-data-modeling.md) | 1, 2 | E | ⚠️ | ⬆️ |
| SKILL-ARCH-004 | [Threat Modeling](skills/skill-arch-004-threat-modeling.md) | 1 | P | ⚠️ | ⬆️ |

### Specification
| ID | Skill | Phase | Level | Agent | Trend |
|---|---|---|---|---|---|
| SKILL-SPEC-001 | [Spec Writing](skills/skill-spec-001-spec-writing.md) | 2 | E | ⚠️ | ⬆️⬆️ |
| SKILL-SPEC-002 | [Invariant Identification](skills/skill-spec-002-invariant-identification.md) | 2 | E | ❌ | ⬆️⬆️ |
| SKILL-SPEC-003 | [Ambiguity Detection](skills/skill-spec-003-ambiguity-detection.md) | 2 | E | ✅ | ⬆️⬆️ |

### Coding
| ID | Skill | Phase | Level | Agent | Trend |
|---|---|---|---|---|---|
| SKILL-CODE-001 | [Language Proficiency](skills/skill-code-001-language-proficiency.md) | 3 | P | ✅ | ⬇️ |
| SKILL-CODE-002 | [API Design](skills/skill-code-002-api-design.md) | 1, 3 | P | ⚠️ | → |
| SKILL-CODE-003 | [Concurrency & Distributed Systems](skills/skill-code-003-concurrency.md) | 3 | E | ⚠️ | ⬆️ |
| SKILL-CODE-004 | [Production Debugging](skills/skill-code-004-production-debugging.md) | 7 | E | ⚠️ | ⬆️⬆️ |

### Testing
| ID | Skill | Phase | Level | Agent | Trend |
|---|---|---|---|---|---|
| SKILL-TEST-001 | [Test Design](skills/skill-test-001-test-design.md) | 2, 4 | E | ❌ | ⬆️⬆️ |
| SKILL-TEST-002 | [Property-Based Thinking](skills/skill-test-002-property-thinking.md) | 2, 4 | P | ⚠️ | ⬆️⬆️ |
| SKILL-TEST-003 | [Test Data Management](skills/skill-test-003-test-data.md) | 4 | P | ✅ | ⬆️ |
| SKILL-TEST-004 | [Contract Testing](skills/skill-test-004-contract-testing.md) | 1, 4 | P | ⚠️ | ⬆️ |

### Build & Release
| ID | Skill | Phase | Level | Agent | Trend |
|---|---|---|---|---|---|
| SKILL-BLD-001 | [CI/CD Engineering](skills/skill-bld-001-cicd-engineering.md) | 5 | P | ⚠️ | → |
| SKILL-BLD-002 | [Supply Chain Security](skills/skill-bld-002-supply-chain-security.md) | 5 | P | ⚠️ | ⬆️ |
| SKILL-BLD-003 | [Release Risk Assessment](skills/skill-bld-003-release-risk-assessment.md) | 6 | E | ❌ | ⬆️ |
| SKILL-BLD-004 | [Database Operations](skills/skill-bld-004-database-operations.md) | 6 | E | ⚠️ | ⬆️ |

### Operations
| ID | Skill | Phase | Level | Agent | Trend |
|---|---|---|---|---|---|
| SKILL-OPS-001 | [Observability Design](skills/skill-ops-001-observability-design.md) | 1, 7 | P | ⚠️ | ⬆️ |
| SKILL-OPS-002 | [Incident Response](skills/skill-ops-002-incident-response.md) | 7 | E | ❌ | ⬆️⬆️ |
| SKILL-OPS-003 | [Root Cause Analysis](skills/skill-ops-003-root-cause-analysis.md) | 7 | E | ⚠️ | ⬆️⬆️ |

### AI-Era
| ID | Skill | Phase | Level | Agent | Trend |
|---|---|---|---|---|---|
| SKILL-AI-001 | [Context Engineering](skills/skill-ai-001-context-engineering.md) | 3 | P | ❌ | 🆕 |
| SKILL-AI-002 | [Agent Output Verification](skills/skill-ai-002-agent-output-verification.md) | 3, 4 | E | ❌ | 🆕⬆️⬆️ |
| SKILL-AI-003 | [Review at Scale](skills/skill-ai-003-review-at-scale.md) | 3 | E | ❌ | 🆕 |
| SKILL-AI-004 | [Agent Orchestration](skills/skill-ai-004-agent-orchestration.md) | 3 | P | ❌ | 🆕 |

### Human
| ID | Skill | Phase | Level | Agent | Trend |
|---|---|---|---|---|---|
| SKILL-HUM-001 | [Written Communication](skills/skill-hum-001-written-communication.md) | Every phase | E | ⚠️ | ⬆️⬆️ |
| SKILL-HUM-002 | [Decision Documentation](skills/skill-hum-002-decision-documentation.md) | 1, 2 | P | ⚠️ | ⬆️⬆️ |
| SKILL-HUM-003 | [Review Feedback](skills/skill-hum-003-review-feedback.md) | 3 | P | ❌ | ⬆️ |
| SKILL-HUM-004 | [Async Collaboration](skills/skill-hum-004-async-collaboration.md) | Every phase | P | ❌ | ⬆️ |

*(Agent: ✅ delegable · ⚠️ assisted with human review · ❌ not delegable)*

---

## Role → Skill Map

| Role | Skills Required at Expert | Skills Required at Proficient |
| --- | --- | --- |
| **Product Owner** | PROD-001, PROD-004, HUM-001 | PROD-002, PROD-003, HUM-002 |
| **Business Analyst** | SPEC-003 | PROD-001, PROD-003, HUM-001, HUM-002 |
| **UX Designer** | PROD-003 | PROD-001, HUM-001 |
| **Architect / Tech Lead** | ARCH-001, ARCH-002, ARCH-003, HUM-002 | ARCH-004, CODE-002, TEST-004, OPS-001 |
| **Backend Engineer** | CODE-003, AI-002 | CODE-001, CODE-002, TEST-001, AI-001, HUM-001 |
| **Frontend Engineer** | AI-002 | CODE-001, CODE-002, TEST-001, AI-001, HUM-001 |
| **QA / SDET** | TEST-001, SPEC-002 | TEST-002, TEST-003, TEST-004, SPEC-001 |
| **DevOps / Platform** | BLD-001 | BLD-002, BLD-004, OPS-001, CODE-001 |
| **SRE / On-call** | OPS-002, OPS-003, CODE-004 | OPS-001, BLD-003, BLD-004 |
| **Security Engineer** | ARCH-004 | BLD-002, CODE-002, OPS-003 |
| **Data Engineer** | PROD-002 | ARCH-003, CODE-001 |
| **Engineering Manager** | HUM-001, HUM-003 | PROD-004, AI-004, HUM-004 |
| **Agent Orchestrator** | AI-002, AI-003 | AI-001, AI-004, SPEC-001, BLD-002 |

---

## Using Skills in the Documentation System

```yaml
# In spec-pay-1042.md
requires_skills:
  - SKILL-SPEC-002   # invariant identification
  - SKILL-ARCH-003   # data modeling
  - SKILL-TEST-001   # test design
min_reviewer_skills:
  - SKILL-AI-002     # requires an Expert agent-output reviewer
```

`bin/docs` verifies that IDs, metadata, index links, and related-skill links
remain consistent. Verifying whether a reviewer possesses the skills required
by a spec will need people metadata and an approval policy that the project has
not added yet.

### Repository-local Codex application

Codex applies this library through the
[project skill router](https://github.com/NakaSato/UTCC-AI-ACADEMY/blob/main/.agents/skills/use-project-skill-library/SKILL.md).
The router is stored under `.agents/skills`, so it is discovered only while
working in this repository. It selects the minimum relevant detailed skill
files and enforces `agent_delegable`: fully delegable work may be executed,
assisted work requires human review, and non-delegable decisions remain with
the accountable human.

---

## Skill-Library Anti-Patterns

| Anti-Pattern | Consequence | Remedy |
| --- | --- | --- |
| Use it for individual performance reviews or compensation | People overstate their level and the library loses credibility | Use it only for matching work to people and planning development |
| Rely on self-assessment alone | Confidence replaces demonstrated ability | Use the practical assessment in each skill file rather than a questionnaire |
| Attempt all 34 skills at once | Nobody starts | Begin with the five skills currently constraining the team |
| Never update it | The library becomes obsolete within six months | Use each file's `review_by` date and a staleness report |
