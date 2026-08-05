---
id: RB-0001
type: runbook
title: Verify production-shaped password reset through Mailpit staging
status: draft
owners: ["@repository-owner"]
created: 2026-08-05
updated: 2026-08-05
review_by: 2026-08-12
depends_on: [ADR-0003, ADR-0004]
touches:
  - compose.yml
  - config/environments/development.rb
  - app/mailers/passwords_mailer.rb
enforced_by:
  - test/controllers/passwords_controller_test.rb
agent_writable: true
---

# Verify production-shaped password reset through Mailpit staging

> This runbook validates a non-production SMTP path only. Mailpit must never
> be exposed as the real production email provider: it cannot deliver to real
> mailboxes and has no production-grade authentication or delivery evidence.

## Preconditions

- The work is being performed in local development or an isolated staging
  environment, never against the production database.
- `compose.yml` uses the pinned `axllent/mailpit:v1.30.0` image.
- Mailpit SMTP and UI ports are loopback-only or otherwise isolated from public
  traffic.
- The recipient is synthetic, such as `mock@example.invalid`; do not use a
  learner's real address or production reset token.
- No production SMTP credentials, DNS changes, or provider configuration are
  required for this procedure.

## Trigger and Symptoms

Run before a production email-provider decision when the team needs evidence
that Rails can render and deliver a password-reset message through SMTP. A
failure may appear as a connection error, a missing Mailpit message, or a reset
link that does not use the production HTTPS host.

## Procedure

1. Validate and start the isolated services:

   ```bash
   docker compose config --quiet
   docker compose up -d --wait
   ```

2. Send a reset message using a temporary synthetic account. Set the mailer
   host to `academy.boring9.dev` with HTTPS for this probe, and destroy the
   temporary account after delivery. Never print the token or message body in
   command output.

3. Open `http://127.0.0.1:8025` or query the local Mailpit API. Confirm that
   the reset message arrived for the synthetic recipient.

4. Confirm the message contains an HTTPS link to
   `academy.boring9.dev/reset-password/...`; do not follow it against a real
   production service during this mock verification.

5. Run the application-level reset regression suite:

   ```bash
   bin/rails test test/controllers/passwords_controller_test.rb
   ```

6. Record the date, Mailpit image version, environment, checks performed, and
   result in the change or handoff. Record no credentials, reset tokens,
   learner addresses, or message bodies.

## Rollback

Stop the local/staging Mailpit service if it is no longer needed. Recreating
the container clears captured messages because the service has no persistent
volume:

```bash
docker compose rm -sf mailpit
```

This procedure does not alter production email configuration or the accepted
production deferral in ADR-0004.

## Verification

Evidence from the 2026-08-05 run:

- `docker compose config --quiet` passed.
- Pinned Mailpit and PostgreSQL services became healthy.
- A synthetic reset message was delivered through the Rails SMTP transport.
- Mailpit received the message and its body contained the HTTPS production-
  shaped reset URL.
- Password-reset controller tests passed: 10 tests, 45 assertions, 0 failures.

This evidence proves application-to-SMTP behavior only. It does not prove real
mailbox delivery, SPF/DKIM/DMARC, bounce handling, provider availability, or
production readiness.

## Escalation

- SMTP or Mailpit failure: Repository Owner.
- Reset-link or application behavior failure: Tech Lead.
- Production provider, credential, DNS, privacy, or delivery decision:
  Product Owner and the named Platform/Security owners.
