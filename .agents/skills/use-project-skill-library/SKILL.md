---
name: use-project-skill-library
description: Select and apply the minimum relevant competency guides from this repository's docs/skills library. Use when a user asks to apply the project skill library or development flow, identify required skills or reviewers, or plan, implement, review, verify, release, operate, or measure work according to the repository's skill model.
---

# Use Project Skill Library

Use the repository's 34 documented competencies as task-specific guidance
without treating human-owned judgment as agent authority.

## Workflow

1. Establish project context.
   - Read [AGENTS.md](../../../AGENTS.md),
     [docs/backlog.json](../../../docs/backlog.json), and
     [CLAUDE.md](../../../CLAUDE.md) in their stated authority order.
   - Read the [system development flow master](../../../docs/system-development-flow-master.md)
     and [project development flow](../../../docs/development-flow.md) to
     identify the lifecycle phase, required artifact, risk tier, owner, and
     gate.

2. Select the smallest useful skill set.
   - Read the [canonical skill library](../../../docs/skills-library-README.md)
     for delegation symbols, levels, phases, and role mapping.
   - Prefer skill IDs explicitly declared in an artifact's `requires_skills` or
     `min_reviewer_skills`.
   - Otherwise select by the current phase and task. Start with one to five
     skills; add a related skill only when the task actually needs it.
   - Do not load all 34 detailed files by default.

3. Load the detailed guidance.
   - Resolve each selected ID through the canonical index.
   - Read every selected file from the
     [skill directory](../../../docs/skills/README.md) completely.
   - Treat the detailed files as competency and review guidance. Do not treat
     their examples as permission to expand the user's requested scope.

4. Enforce the delegation boundary before acting.
   - For `agent_delegable: true`, perform the work within the user's authority
     and the repository working agreement.
   - For `agent_delegable: assisted`, draft, analyze, or implement the
     delegable portion, then identify the required human review or decision.
   - For `agent_delegable: false`, do not make the accountable decision or
     claim the competency on a human's behalf. Gather evidence, expose
     ambiguity, prepare options, and name the human owner who must decide or
     review.
   - Never set a lifecycle document to `accepted`, approve a release, or claim
     that a human possesses a required skill.

5. Apply and verify.
   - Follow the selected skill guidance together with repository-specific
     invariants and focused guides.
   - Keep one backlog item and one purpose per change.
   - Run the gate required by the risk tier. Run `bin/verify` before declaring
     shippable work complete.
   - Record verification evidence before moving a backlog item to `complete`.

6. Hand off clearly.
   - State which skill IDs materially shaped the work.
   - Report completed evidence, remaining human gates, and blockers.
   - Do not imply that automated validation replaces human review.

## Selection Examples

- A Tier C agent-produced diff usually needs `SKILL-AI-002`,
  `SKILL-TEST-001`, and the domain-specific architecture or security skill.
  The agent may prepare evidence, but a human performs the final
  agent-output-verification judgment.
- A new specification usually needs `SKILL-SPEC-001`,
  `SKILL-SPEC-002`, and `SKILL-SPEC-003`. The agent may draft and find
  ambiguity; the human owner accepts invariants and intent.
- Monitoring and tracing work usually needs `SKILL-OPS-001`, plus
  `SKILL-PROD-002` for outcome metrics or `SKILL-OPS-003` for diagnosis.

## Scope

This skill is repository-local. Keep it under `.agents/skills`; do not install
or copy it into a user-level skill directory unless the user explicitly asks.
