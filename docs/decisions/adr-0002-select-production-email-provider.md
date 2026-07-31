---
id: ADR-0002
type: adr
title: Select the production transactional-email provider
status: draft
owners: ["@product-owner"]
created: 2026-07-31
updated: 2026-07-31
review_by: 2026-08-07
supersedes: []
superseded_by: []
depends_on: []
implemented_by: []
touches:
  - app/mailers/application_mailer.rb
  - config/environments/production.rb
  - config/deploy.yml
  - render.yaml
enforced_by: []
agent_writable: true
---

# Select the Production Transactional-Email Provider

**Tags:** [#decisions](../tags.md#decisions) [#roadmap](../tags.md#roadmap) [#security](../tags.md#security) [#operations](../tags.md#operations)

> [Milestone 1](../roadmap.md#milestone-1--reliable-account-recovery) ·
> [Worked Example](../examples/milestone-1-reliable-account-recovery.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Decision Records](README.md)

> **Decision state:** No provider has been selected. This agent-prepared draft
> organizes current evidence; the Product Owner must choose the provider,
> approve the cost and privacy trade-off, and name the credential custodian.

## Context

The application already:

- generates password-reset messages through Rails Action Mailer;
- queues those messages through Solid Queue;
- uses `https://academy.boring9.dev` in reset links;
- sends from `no-reply@academy.boring9.dev`; and
- preserves account-enumeration resistance in the public reset response.

Production has no delivery method or SMTP credentials, so the message is
enqueued but cannot reach a student. `MAIL-001` is blocked until a human owns
the provider, domain, credential, cost, privacy, and operating decisions.

The smallest architectural change is a standards-based SMTP relay configured
through environment-backed secrets. It uses Rails' existing mailer interface
and does not require a new gem. Provider webhooks or event destinations may be
added later only through an accepted specification and threat review.

## Decision Drivers

1. Reliable delivery of low-volume password-reset messages to Thai students.
2. No provider credential in Git, logs, fixtures, documentation, or agent
   context.
3. TLS-protected SMTP without adding an application dependency.
4. SPF and DKIM authentication for an organization-controlled sending domain;
   DMARC must be reviewed before production use.
5. Operator-visible rejection, bounce, complaint, delay, and provider-health
   information.
6. Least-privilege credentials that can be rotated without a code change.
7. An explicit owner for the provider account, DNS records, credentials,
   billing, privacy review, and incident escalation.
8. Minimal retention and exposure of message bodies, reset links, and student
   email addresses.
9. A documented path out of trial or sandbox restrictions before production
   verification.

Expected volume, budget, institutional procurement rules, and required data
residency are not yet known. Those missing inputs prevent a responsible final
choice.

## Options

The facts below were checked against provider documentation on 2026-07-31.
Pricing and service terms can change; the Product Owner must verify them when
accepting this decision.

| Option | Fit for the current Rails app | Delivery evidence | Material trade-off |
| --- | --- | --- | --- |
| **Postmark SMTP** | Configuration-only SMTP integration with STARTTLS; a token can be scoped to a transactional message stream | Delivery and bounce dashboards plus webhooks | Lowest operating complexity, but paid production capacity starts above the developer tier and full message history is retained by default |
| **Amazon SES SMTP, Singapore** | Configuration-only SMTP through the `ap-southeast-1` endpoint with a dedicated IAM-derived SMTP identity | Bounce/complaint email, SNS, or event publishing | Regional endpoint and fine-grained IAM control, but sandbox removal, IAM, notifications, and AWS operations add setup burden |
| **Resend SMTP, Tokyo** | Configuration-only SMTP using an API key as the SMTP password | Email table plus signed webhooks for delivery, delay, failure, bounce, and complaint events | Generous pilot tier and simple setup, but account metadata, logs, and API records are stored in the United States; SMTP server logs are not exposed |
| **Keep production delivery unconfigured** | No work | No delivery evidence | Rejected as an end state because account recovery remains broken |

### Option A — Postmark SMTP

Postmark supports SMTP using a transactional message-stream token, recommends
TLS, and documents delivery and bounce webhooks. Its published pricing includes
a developer tier of 100 messages per month and a paid Basic tier starting at
USD 15 per month. Its pricing page also states that full message content is
retained for 45 days by default, with configurable retention on eligible plans.

Official evidence:

- [SMTP integration and token scope](https://postmarkapp.com/developer/user-guide/send-email-with-smtp)
- [Pricing and message-retention details](https://postmarkapp.com/pricing/)
- [Delivery and bounce webhook model](https://postmarkapp.com/developer/webhooks/webhooks-overview)

Security note: Postmark's webhook documentation says it does not currently
provide HMAC signature verification. A future inbound webhook would therefore
need the documented HTTP authentication and IP controls, payload validation,
idempotency, and an explicit threat review. The first production increment may
instead use the provider dashboard and an accountable operator while that
inbound boundary is specified.

### Option B — Amazon SES SMTP in Asia Pacific (Singapore)

Amazon SES exposes the regional SMTP endpoint
`email-smtp.ap-southeast-1.amazonaws.com` and requires encrypted SMTP
connections. Dedicated SMTP credentials are derived from IAM credentials and
can be constrained to sending actions and approved sender identities. SES can
report bounces and complaints through email, SNS, or event publishing.

New accounts begin in a region-specific sandbox and cannot send to arbitrary
student addresses until production access is granted. AWS documentation
currently lists pay-as-you-go outbound sending, while AWS also announced new
SES pricing plans for new or returning accounts in July 2026. Procurement must
confirm which terms apply to the institution rather than relying on this ADR
for a quote.

Official evidence:

- [Singapore SMTP endpoint](https://docs.aws.amazon.com/general/latest/gr/ses.html)
- [TLS SMTP connection requirements](https://docs.aws.amazon.com/ses/latest/dg/smtp-connect.html)
- [SMTP credential and IAM model](https://docs.aws.amazon.com/ses/latest/dg/send-email-concepts-credentials.html)
- [Sandbox and production-access requirements](https://docs.aws.amazon.com/ses/latest/dg/request-production-access.html)
- [Bounce and complaint notifications](https://docs.aws.amazon.com/ses/latest/dg/monitor-sending-activity-using-notifications.html)
- [Published SES pricing](https://aws.amazon.com/ses/pricing/)
- [July 2026 pricing-plan announcement](https://aws.amazon.com/about-aws/whats-new/2026/07/amazon-ses-pricing-plans/)

### Option C — Resend SMTP in Asia Pacific (Tokyo)

Resend supports SMTP with TLS and uses an API key as the SMTP password. Its
published free transactional tier includes 3,000 messages per month with a
100-message daily limit; its paid Pro tier starts at USD 20 per month for
50,000 messages. It exposes delivery, delay, failure, bounce, and complaint
webhook events with a webhook signing secret.

Tokyo is Resend's closest selectable sending region to Thailand. Region choice
controls dispatch, not storage: Resend documents that account metadata, logs,
and API records remain in the United States. Resend also states that SMTP
server logs are not available to customers, although sent messages appear in
the email table. Institutional privacy review is therefore a hard gate.

Official evidence:

- [SMTP integration](https://resend.com/docs/send-with-smtp)
- [Transactional pricing](https://resend.com/docs/knowledge-base/what-is-resend-pricing)
- [Domain authentication](https://resend.com/docs/dashboard/domains/introduction)
- [Regions and data residency](https://resend.com/docs/dashboard/domains/regions)
- [Webhook event types](https://resend.com/docs/webhooks/event-types)

## Decision

Pending human completion:

```text
Selected provider and plan:
Reason this option wins:
Meaningful losing alternative:
Provider-account owner:
Credential custodian and rotation owner:
DNS owner:
Sending domain:
From address:
Provider region:
Expected monthly and peak daily volume:
Budget/procurement approval:
Privacy/data-residency approval:
Message and event retention setting:
Bounce/complaint/delay visibility path:
Provider incident escalation owner:
Decision date and approver:
```

Selection guidance:

- prefer **Postmark** when minimizing operational complexity is more important
  than the monthly minimum and its privacy/retention terms are accepted;
- prefer **Amazon SES Singapore** when regional control, IAM, or an existing
  institutional AWS operating model outweighs the additional setup burden;
- prefer **Resend Tokyo** for a low-cost pilot only when United States storage
  of provider account metadata and logs is explicitly accepted; and
- do not select any provider until DNS ownership, credential custody, privacy,
  billing, and provider incident escalation each have a named human owner.

## Alternatives

### Use a provider-specific HTTP API immediately

Deferred. It would add either a dependency or custom HTTP integration before
SMTP has proved insufficient. SMTP meets the current single-message use case
and keeps provider substitution comparatively reversible.

### Run an institutional SMTP server

Viable only if UTCC already supplies a supported transactional relay, an
accountable mail administrator, sending-domain authentication, delivery
feedback, and an incident path. Those facts are not present in the repository.
The Product Owner should add this option if the institution confirms them.

### Send through a personal or shared mailbox account

Rejected. Personal credentials, weak custody, unclear quotas, and absent
delivery operations are incompatible with a production recovery path.

## Consequences

- A third party will process student email addresses and password-reset links;
  privacy review and minimized retention are required.
- DNS changes and sender reputation become operating dependencies.
- SMTP acceptance proves only that the provider accepted a message, not that a
  mailbox received it. Delivery and bounce evidence remain mandatory.
- The selected provider becomes a production dependency with a human account
  owner, credential rotation procedure, incident route, and exit plan.
- Standard SMTP keeps the application boundary stable and makes provider
  replacement easier, but provider-specific event handling will still require
  a later specification.

## Fitness Functions

These become binding only after human acceptance and must be mapped to a
specification and tests before implementation:

1. Production refuses to boot or send when required non-secret SMTP settings
   are invalid; no fallback silently discards messages.
2. SMTP credentials enter the runtime only through the selected deployment
   platform's secret store and can rotate without a commit.
3. The sending domain passes provider SPF and DKIM verification, and DMARC is
   explicitly reviewed.
4. A controlled rejection or bounce becomes visible through the approved
   operator path without recording message content or direct identifiers in
   application telemetry.
5. Reset requests for known and unknown addresses retain indistinguishable
   public behavior.
6. A real reset message reaches a controlled mailbox with an HTTPS production
   link; the token expires and session invalidation still passes.
7. Focused tests and `bin/verify` pass locally, followed by independent CI.

## Human Review Checklist

- [ ] Product Owner selected the provider and plan.
- [ ] Repository Owner / Tech Lead reviewed the implementation and exit cost.
- [ ] Security/Privacy reviewer accepted data handling, retention, webhook,
      credential, and DNS controls.
- [ ] Platform owner accepted account administration and secret rotation.
- [ ] Operations owner accepted delivery visibility and escalation.
- [ ] Finance or institutional owner accepted the current commercial terms.
- [ ] The ADR status was changed by a human, not an agent.
