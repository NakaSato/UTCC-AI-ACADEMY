# Runbooks

> [System Development Flow Master](../system-development-flow-master.md) ·
> [Runbook Template](../templates/runbook.md)

Create a runbook from the [runbook template](../templates/runbook.md) before
operating a production dependency or recovery procedure.

## Runbooks

- [RB-0001 — Verify production-shaped password reset through Mailpit staging](rb-mailpit-staging-verification.md) — draft; non-production SMTP evidence only
- [RB-0002 — Triage critical failure telemetry](rb-critical-failure-observability.md) — draft; provider-neutral contract and controlled verification only
- [RB-0003 — Verify backup freshness and isolated restore evidence](rb-backup-restore-verification.md) — draft; provider-neutral contract and synthetic drill verification only
- [RB-0004 — Deploy and roll back the Render production image](rb-render-deployment.md) — draft; target and release procedure, no live credentials
- [RB-0005 — Upgrade the production PostgreSQL database from 17 to 18](rb-postgres-18-upgrade.md) — draft; provider-dashboard procedure, dev/test already on 18
- [RB-0006 — Put the academy into maintenance mode and take it out again](rb-maintenance-mode.md) — draft; 503 is wired and off, 502/504 are not customisable on Render, and the page is inert until the documentation site publishes
