---
id: SKILL-BLD-002
name: Supply Chain Security
category: build
phases: [5]
roles: [devops, security-engineer, platform-engineer]
required_level: proficient
agent_delegable: assisted
agent_trend: rising
related: [SKILL-ARCH-004, SKILL-BLD-001]
review_by: 2027-01-31
---

# Supply Chain Security

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-ARCH-004 — Threat Modeling](skill-arch-004-threat-modeling.md) · [SKILL-BLD-001 — CI/CD Engineering](skill-bld-001-cicd-engineering.md)

## Definition
The ability to control and audit everything that ends up in the final artifact — dependencies, base images, build tools — and to prove that what is deployed is what was meant to be built.

## Why It Matters Now
Agents add dependencies faster than humans can review them, and tend to propose a new package every time they hit a problem, so the attack surface grows far faster than it used to. The SBOM has gone from a compliance document to an operational tool that can answer, within minutes, "where do we have the vulnerable version?"

## Levels
### Foundation
- Runs a dependency scanner and understands the results
- Can update a dependency that has a CVE

### Proficient
- Produces and uses an SBOM in the pipeline
- Sets policy on which severity level blocks a build
- Uses lockfiles and pins versions correctly

### Expert
- Signs and verifies artifacts (cosign, SLSA provenance)
- Assesses the risk of a dependency before adopting it (maintainers, update cadence, number of transitive deps)
- Designs the response process for a critical CVE in a dependency used across the whole system

## How to Assess
Ask: "if tomorrow there is a severity-10 CVE in a widely used library, how many minutes until we know which of our systems are affected, and how long to fix it?"
No answer = there is no SBOM in real use.

## Development Path
1. Generate an SBOM of the current project with syft and see how many dependencies there really are
2. Add a gate that blocks Critical CVEs in CI
3. Adopt a policy that every new dependency needs a recorded rationale (Gemfile/package.json are Tier C)
4. Try signing artifacts with cosign and verifying before deploy

## Relationship with Agents
- **Agents can do:** Generate SBOMs, summarise CVEs, propose safe versions, configure scanners
- **Agents cannot do:** Decide whether to take on a new dependency — and agents are themselves the source of new dependencies that needs controlling

## Signals the Team Lacks This Skill
- Nobody knows how many dependencies there are
- Lockfiles are not committed
- Nobody can say which commit the deployed artifact was built from
