# Run using bin/ci

CI.run do
  step "Setup", "bin/setup --skip-server"

  step "Docs: Backlog, schema, and references", "bin/docs"

  step "Style: Ruby", "bin/rubocop"

  step "Security: Gem audit", "bin/bundler-audit"
  step "Security: Importmap vulnerability audit", "bin/importmap audit"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"
  # The island bundle is built here rather than left to the test suite's
  # auto-build, so a broken Vite config fails as itself instead of as a puzzling
  # system-test failure ten minutes later. `npm audit` is the JavaScript half of
  # the gate bundler-audit and importmap audit already cover for gems and pins —
  # a Vite dependency tree is the one supply chain none of them saw. See
  # ADR-0053.
  step "Security: npm audit", "npm audit --audit-level=high --omit=dev"
  step "Assets: Vite island bundle", "bin/vite build"
  step "Tests: Rails", "bin/rails test"
  step "Tests: Seeds", "env RAILS_ENV=test bin/rails db:seed:replant"

  step "Tests: System", "bin/rails test:system"

  # Optional: set a green GitHub commit status to unblock PR merge.
  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  # if success?
  #   step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  # else
  #   failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  # end
end
