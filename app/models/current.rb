class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :request_id, :job_id
  delegate :user, to: :session, allow_nil: true

  # The whole syllabus, held for the length of one request. Reference data that
  # nearly every render reads several times — a catalog asks for the topic count
  # once per card — so it is read once and folded in Ruby.
  #
  # Here rather than in a Syllabus ivar on purpose. A module-level memo lives as
  # long as the process, which outlives the database it was read from: the
  # parallel test runner forks workers that each switch to their own database,
  # and a memo built in the parent before the fork is inherited empty by every
  # one of them. CurrentAttributes is reset around each request and each test,
  # so the cache cannot outlive what it was read from.
  attribute :syllabus
  attribute :syllabi

  # The landing page's copy overrides, held the same way and for the same
  # reasons — one query for a page that reads a hundred strings, and a cache that
  # cannot outlive the database it was read from. See LandingText.overrides.
  attribute :landing_texts

  # And the landing page's cards, grouped by collection — one query for the five
  # collections the page renders. See Landing.cards.
  attribute :landing_cards

  # Every student's XP, ranked. Two grouped counts over the whole of
  # topic_completions, and /progress asks for a rank more than once per render —
  # so without this the most expensive query pair in the app ran twice for one
  # page. Held here for the same reason as the syllabus: a module-level memo
  # would outlive the database it was read from. TopicCompletion.record clears
  # it; see LearnerProgress.forget_standings.
  attribute :standings
end
