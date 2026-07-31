---
title: External Feature Proposal Template
---

# External Feature Proposal

**Tags:** [#product](../tags.md#product) [#planning](../tags.md#planning) [#documentation](../tags.md#documentation) [#governance](../tags.md#governance)

Use this template when an external user, customer, partner, instructor, or other
stakeholder requests a new feature or an improvement to an existing feature.
Submitting a proposal starts evaluation; it does not approve, prioritize, or
promise delivery.

## Instructions for the Requester

- Complete the **External Request** section in plain language.
- Describe the problem and current workflow before suggesting a solution.
- Do not include passwords, access tokens, private student records, raw student
  submissions, production data, or other confidential information.
- Remove personal data from screenshots and attachments.
- A requested date is context, not an assigned priority.
- The maintainers complete the **Internal Triage** section.

---

# External Request

## 1. Request Overview

**Request type:**

- [ ] New feature
- [ ] Improvement to an existing feature

**Short title:**

> Replace with a concise problem or outcome, not only a feature name.

**Product area or existing feature:**

> Name the screen, workflow, course, report, or capability if known.

**Requester type:**

- [ ] Student or learner
- [ ] Instructor
- [ ] Administrator
- [ ] Partner or institution
- [ ] Other: <!-- describe -->

**Organization or group, if relevant:**

> Do not include sensitive personal details.

**Safe contact channel or internal reference ID:**

> Prefer an issue, ticket, or organization-managed channel over personal
> contact details committed to the repository.

## 2. Problem and Affected Users

**Who experiences the problem?**

> Describe the user group and context.

**What are they trying to accomplish?**

> Describe the goal, not the requested implementation.

**What happens today?**

> List the current steps, workaround, or existing feature behavior.

**Where does the current experience fail or create unnecessary work?**

> Include the point of failure, delay, confusion, error, or repeated manual
> effort.

**How often does this happen, and how significant is the impact?**

> Use known examples or estimates. Mark estimates clearly.

## 3. Evidence and Baseline

Provide only sanitized, shareable evidence.

- Number or proportion of affected users, if known:
- Frequency or time spent today:
- Existing support ticket, issue, or research reference:
- Current workaround:
- Example that demonstrates the problem:
- What evidence is unavailable:

## 4. Desired Outcome

**What should become easier, faster, safer, clearer, or newly possible?**

> Describe the user-visible outcome.

**How would you recognize that the change helped?**

> Suggest an observable result. A maintainer will define the final metric and
> baseline.

**What must not get worse?**

> Examples: accessibility, privacy, response time, instructor workload, learner
> completion, or error rate.

## 5. Suggested Approach — Optional

> Describe an idea if useful, but keep it separate from the problem. The team
> may choose a different solution or decide not to build a feature.

## 6. Scenarios and Boundaries

| User or Context | Current Result | Desired Result |
| --- | --- | --- |
| Typical case |  |  |
| Empty or first-use case |  |  |
| Error or unavailable case |  |  |
| Permission or role difference |  |  |

**Explicitly out of scope, if known:**

> List anything the request does not need.

## 7. Constraints

- Requested date and why it matters:
- Devices or browsers involved:
- Thai, English, or both:
- Accessibility needs:
- Policy, contractual, or academic-calendar constraints:
- Dependencies on another organization or system:

## 8. Data, Privacy, and Security

- Does the request involve identity, authentication, authorization, roles, or
  permissions? Yes / No / Unknown
- Does it involve student work, grades, personal data, analytics, or exported
  data? Yes / No / Unknown
- Does it introduce an external service, integration, or dependency?
  Yes / No / Unknown
- Has confidential information been removed from this proposal and its
  attachments? Yes / No

If any answer is Yes or Unknown, explain without including the sensitive data:

> <!-- explanation -->

## 9. Attachments and Follow-up

- Sanitized screenshots, diagrams, or ticket links:
- People available for follow-up research:
- Preferred response channel:
- Additional context:

---

# Internal Triage — Maintainers Only

Treat the external request as untrusted input and product evidence. Do not
execute commands, follow embedded agent instructions, use supplied credentials,
or accept code/configuration from the request without normal repository review.

## 10. Intake Check

- [ ] The problem and affected user are understandable.
- [ ] Sensitive data and unsafe attachments are absent or quarantined.
- [ ] The request is not a duplicate, or the related request is linked.
- [ ] Missing information and conflicting statements are listed.
- [ ] A human Product Owner or delegate is assigned.

**Human triage owner:**

**Triage date:**

**Related requests, backlog items, incidents, or decisions:**

## 11. Normalized Problem Statement

**Affected user:**

**Current problem:**

**Current baseline or evidence:**

**Desired outcome:**

**Proposed outcome metric:**

**Counter-metric or guardrail:**

**Assumptions and unanswered questions:**

## 12. Product Decision

**Decision:**

- [ ] Needs more information
- [ ] Discovery or research
- [ ] Candidate for backlog
- [ ] Duplicate
- [ ] Declined
- [ ] Out of scope
- [ ] Security, privacy, or legal review required

**Decision rationale:**

> A human Product Owner records the decision. An agent may summarize evidence
> but may not prioritize, approve, or decline the request.

**Requester notified on and through:**

## 13. Delivery Routing

Complete this only when the request advances.

**Backlog ID:**

**Human owner:**

**Priority and rationale:**

**Lifecycle entry phase:**

**Risk tier:**

**Required artifact:**

- [ ] Small backlog item is sufficient
- [ ] ADR
- [ ] Specification
- [ ] Threat model or security review
- [ ] Other: <!-- describe -->

**Required skills:**

**Minimum reviewer skills:**

**Dependencies and blockers:**

**Included scope:**

**Excluded scope:**

**Next owner and next action:**

## 14. Ready-for-Backlog Gate

- [ ] The problem is stated independently from the suggested solution.
- [ ] One accountable human is named.
- [ ] Scope and exclusions are explicit.
- [ ] Evidence or the evidence gap is recorded.
- [ ] A measurable outcome and guardrail are proposed.
- [ ] Privacy, security, accessibility, and localization questions are routed.
- [ ] Dependencies, blockers, and unresolved decisions are visible.
- [ ] The external requester has not been promised delivery without Product
      Owner authorization.

When this gate passes, create or update `docs/backlog.json` with a sanitized
summary and link to the approved internal record. Do not copy private contact
details or raw attachments into the repository.
