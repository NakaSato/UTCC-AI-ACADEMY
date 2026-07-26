class Current < ActiveSupport::CurrentAttributes
  attribute :session
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
end
