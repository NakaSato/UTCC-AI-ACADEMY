---
id: ADR-0003
type: adr
title: Use Mailpit for local email capture
status: accepted
owners: ["@repository-owner"]
created: 2026-07-31
updated: 2026-08-09
review_by: 2026-10-29
supersedes: []
superseded_by: []
depends_on: []
implemented_by: []
touches:
  - compose.yml
  - config/environments/development.rb
  - bin/setup
  - README.md
  - CLAUDE.md
enforced_by: []
agent_writable: false
---

# Use Mailpit for Local Email Capture

**Tags:** [#decisions](../tags.md#decisions) [#development](../tags.md#development) [#security](../tags.md#security) [#testing](../tags.md#testing)

> [Decision Records](README.md) ·
> [Production Provider Decision](adr-0002-select-production-email-provider.md) ·
> [Milestone 1](../roadmap.md#milestone-1--reliable-account-recovery) ·
> [Project Development Flow](../development-flow.md)

> **Approval state:** A human Repository Owner accepted this dependency on
> 2026-08-01. Mailpit is development tooling and does not resolve `MAIL-001`
> or deliver production email.

## Context

The application can render and enqueue a password-reset message, but local
development has no SMTP receiver. Developers can use the Rails mailer preview,
but that does not exercise SMTP delivery through the same interface that
production will use.

The repository already uses Docker Compose for development PostgreSQL and
`bin/setup` starts the declared services. A local mail catcher fits that model,
but adding a container image is a dependency and changing container
configuration is Tier C work.

The proposed tool is Mailpit, an SMTP testing server that captures messages and
shows them in a browser. Its defaults are SMTP port 1025 and web UI port 8025.
The default SMTP listener has no encryption or authentication, so both exposed
ports must bind only to the developer machine's loopback interface.

Official evidence checked on 2026-07-31:

- [Mailpit Docker installation](https://mailpit.axllent.org/docs/install/docker/)
- [SMTP configuration and default security](https://mailpit.axllent.org/docs/configuration/smtp/)
- [Web UI configuration](https://mailpit.axllent.org/docs/configuration/http/)
- [Mailpit v1.30.0 security release](https://github.com/axllent/mailpit/releases/tag/v1.30.0)

## Decision

Add Mailpit as development-only infrastructure with these constraints:

1. Pin the image to `axllent/mailpit:v1.30.0`; do not use a floating `latest`
   tag.
2. Publish SMTP as `127.0.0.1:${MAILPIT_SMTP_PORT:-1025}:1025` and the web UI as
   `127.0.0.1:${MAILPIT_UI_PORT:-8025}:8025`.
3. Do not configure SMTP authentication, TLS, external relay, message release,
   inbound webhooks, or public access.
4. Do not persist captured messages in a named volume. Recreating the container
   must remove local reset links and student email addresses.
5. Configure development Action Mailer to use SMTP at
   `${SMTP_HOST:-127.0.0.1}:${SMTP_PORT:-1025}` and raise delivery errors.
6. Keep test delivery on Rails' `:test` adapter and leave production settings
   unchanged.
7. Document `http://127.0.0.1:8025` as a local inbox and state explicitly that
   it cannot prove real-mailbox delivery.

## Alternatives

### Continue using only Rails mailer previews

No dependency, but it does not exercise delivery through SMTP and makes local
reset-flow verification less representative.

### Use file delivery

No running service, but raw message files provide a poorer inspection workflow
and still do not exercise an SMTP connection.

### Use a hosted email sandbox

It can exercise network delivery, but it sends test addresses and reset links
to a third party, introduces credentials, and makes basic local development
depend on internet access.

### Run a full local mail-transfer agent

Rejected for development. Postfix or an equivalent introduces DNS, relay,
queue, abuse, and host-administration concerns that are unnecessary for
capturing test messages.

## Consequences

- Developers gain a disposable browser inbox for password-reset messages.
- Local setup downloads and runs one additional container image.
- The project accepts responsibility for tracking Mailpit security releases and
  updating the pinned version through a reviewed ADR update.
- Messages may contain student email addresses and active development reset
  links, so the UI and SMTP ports must remain loopback-only and storage must be
  ephemeral.
- A green local Mailpit test proves application-to-SMTP behavior only. It does
  not prove sender authentication, internet deliverability, bounce handling, or
  production mailbox receipt.
- `ADR-0002` and `MAIL-001` remain the authority for production email.

## Fitness Functions

After human acceptance and implementation:

1. `docker compose config` resolves the pinned Mailpit service and shows both
   published ports bound to `127.0.0.1`.
2. `docker compose up -d --wait` starts PostgreSQL and Mailpit successfully.
3. A development mailer delivery appears in Mailpit's API and browser inbox.
4. Restarting with a recreated Mailpit container removes captured messages.
5. The test environment still uses `config.action_mailer.delivery_method =
   :test`.
6. Production configuration, Render, and Kamal do not reference Mailpit.
7. `bin/verify` passes, followed by human review of every Tier C line.

## Human Review Checklist

- [ ] Repository Owner accepts the pinned Mailpit dependency.
- [ ] Security reviewer accepts loopback-only unauthenticated local SMTP.
- [ ] Human reviewer confirms Mailpit cannot enter production configuration.
- [ ] Human reviewer confirms captured mail is ephemeral.
- [ ] The ADR status is changed by a human, not an agent.
