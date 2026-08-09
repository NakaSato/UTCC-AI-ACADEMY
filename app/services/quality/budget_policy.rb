module Quality
  module BudgetPolicy
    ACCESSIBILITY_TARGET = "WCAG 2.2 AA"
    LOCALES = %w[ en th ].freeze

    ACCESSIBILITY_CHECKS = %i[
      keyboard
      focus
      screen_reader
      text_scaling
      contrast
      reduced_motion
      bilingual
      learning_critical
    ].freeze

    SUPPORTED_MATRIX = [
      {
        name: "desktop-current-browser",
        browsers: %w[ current_desktop ],
        input: %w[ mouse keyboard ],
        assistive_technology: %w[ none ],
        locales: LOCALES,
        viewport: "desktop",
        network: "baseline"
      }.freeze,
      {
        name: "mobile-current-browser",
        browsers: %w[ current_mobile ],
        input: %w[ touch keyboard ],
        assistive_technology: %w[ none ],
        locales: LOCALES,
        viewport: "mobile",
        network: "throttled_mobile"
      }.freeze,
      {
        name: "keyboard-screen-reader",
        browsers: %w[ current_desktop ],
        input: %w[ keyboard ],
        assistive_technology: %w[ screen_reader ],
        locales: LOCALES,
        viewport: "desktop",
        network: "baseline"
      }.freeze
    ].freeze

    CRITICAL_JOURNEYS = [
      {
        key: :authentication,
        paths: %w[ /login /forgot-password ],
        data_states: %i[ empty typical growth ],
        owner: "Product Owner / QA Owner"
      }.freeze,
      {
        key: :catalog_course_lesson,
        paths: %w[ / /courses/:code /lesson ],
        data_states: %i[ empty typical growth ],
        owner: "Product Owner / Tech Lead"
      }.freeze,
      {
        key: :progress_map,
        paths: %w[ /my-learning /progress /knowledge-map ],
        data_states: %i[ empty typical growth ],
        owner: "Product Owner / QA Owner"
      }.freeze,
      {
        key: :leaderboard,
        paths: %w[ /leaderboard ],
        data_states: %i[ empty typical growth ],
        owner: "Product Owner / Tech Lead"
      }.freeze,
      {
        key: :instructor_admin,
        paths: %w[ /instructor /admin ],
        data_states: %i[ empty typical growth ],
        owner: "Tech Lead / QA Owner"
      }.freeze,
      {
        key: :academic_reader_editor,
        paths: %w[ /academic /academic/new /academic/:id ],
        data_states: %i[ empty typical growth ],
        owner: "Product Owner / Academic Owner"
      }.freeze,
      {
        key: :syllabus_pdf,
        paths: %w[ /courses/:code/syllabus.pdf ],
        data_states: %i[ empty typical growth ],
        owner: "Tech Lead / QA Owner"
      }.freeze,
      {
        key: :notification_frame,
        paths: %w[ /notifications ],
        data_states: %i[ empty typical growth ],
        owner: "Tech Lead / Platform Owner"
      }.freeze
    ].freeze

    PERFORMANCE_BUDGETS = {
      initial_interaction_p75_ms: 2_000,
      initial_interaction_p95_ms: 4_000,
      initial_transfer_p75_bytes: 1_500_000,
      initial_transfer_p95_bytes: 3_000_000,
      measurement_environment: "ci_browser_and_throttled_mobile",
      cache_state: "documented_consistently"
    }.freeze

    QUERY_GROWTH = {
      rule: "constant_cost",
      fixture_states: %i[ empty typical growth ],
      baseline: "docs/performance.md#the-per-screen-query-budget",
      existing_enforcement: "test/models/query_budget_test.rb"
    }.freeze

    FAILURE_RESPONSE = {
      blocking: %i[ accessibility authorization academic_integrity learning_critical ],
      warning_with_expiring_waiver: %i[ lower_risk_performance cosmetic ],
      waiver_fields: %i[ owner evidence reason remediation_due expires_at ]
    }.freeze

    OBSERVABILITY = {
      dimensions: %i[ route locale device network release ],
      required_context: %i[ environment request_id ],
      forbidden_fields: %i[ learner_answers credentials cookies reset_links direct_identifiers ]
    }.freeze
  end
end
