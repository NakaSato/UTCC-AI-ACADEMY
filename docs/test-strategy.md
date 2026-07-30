---
title: Test Strategy
---

# Test Strategy

**Tags:** [#development](tags.md#development) [#verification](tags.md#verification) [#security](tags.md#security)

The project uses Minitest, Rails controller/model/task tests, and browser-driven
system tests. Test ownership follows risk rather than a universal coverage
percentage.

## Test Levels

| Level | Purpose | Primary Author | Human Obligation |
| --- | --- | --- | --- |
| Acceptance / invariant | Define what correct means | Human Spec Owner | Own intent; do not let implementation redefine it |
| Integration / controller | Verify Rails boundaries and collaboration | Developer or agent | Review authorization, persistence, and error paths |
| Unit / model | Exercise domain behavior quickly | Developer or agent | Check meaningful boundaries, not implementation trivia |
| System | Protect critical browser-only journeys | QA-minded developer or agent draft | Review stability, cost, and user-visible assertions |

The agent may draft any test, but an agent is never the accountable owner of
acceptance intent.

## Risk-Based Policy

- **Tier C:** test the happy path, denial path, invalid input, persistence
  invariant, and rollback/migration behavior where applicable. Run
  `bin/verify`.
- **Tier B:** add focused model/controller/integration coverage and run the
  affected test file before the full gate.
- **Tier A:** validate documentation claims and generated documentation.

Coverage numbers are diagnostic, not the definition of quality. A high
percentage does not replace explicit invariant tests.

## Test Data

- Use fixtures or deterministic factories with fixed inputs.
- Never copy production PII into a test fixture, even when masked.
- Keep Thai and English positional structures aligned.
- Make time, randomness, and external delivery deterministic at the boundary.
- A test must fail for the intended reason before its implementation is trusted.

## Flaky-Test Policy

- A test that flakes twice within 30 days is quarantined immediately and gets a
  backlog item with an owner.
- Quarantine means isolating it from the shipping signal while preserving a
  visible failing job or focused reproduction path.
- Do not add automatic retries to hide flakiness.
- Fix or replace the test before restoring it to the required gate.

## Commands

```bash
bin/rails test
bin/rails test test/models/example_test.rb
bin/rails test test/models/example_test.rb:42
bin/rails test:system
bin/verify
```

The invariant-to-test registry remains in `docs/agent-flow.md` and
`CLAUDE.md`. New architectural invariants must name the test that enforces them.
