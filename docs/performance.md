# Performance: what was measured, and what it cost

Sized for a classroom, not a public site, and the design leans on that throughout. `CLAUDE.md` holds the rules that follow from this file — one query per learner folded in Ruby, a cohort loaded once, one writer. **This is the working underneath them:** the numbers, the regressions that produced each rule, and the reasoning that will be needed again the first time one of these screens gets slow.

Read it before changing how any screen loads its data. Nothing here is a rule on its own; the rules are in `CLAUDE.md` under "Performance and scale", and they are short precisely because the evidence lives here.

## The per-screen query budget

Measured per render against the seeds:

| Screen | Queries |
| --- | --- |
| landing | 2 |
| map, profile | 6 |
| leaderboard shell | 6 |
| leaderboard board frame | 6 again (10 in one response before the frame existed) |
| course, lesson, My Learning | 12 |
| catalog | 13 |
| progress | 14 |
| instructor | 16 |
| admin | 12–20 |

**Every screen is constant-cost in the size of the data it folds**, and `test/models/query_budget_test.rb` is what keeps it that way — it grows a section and asserts the roster's query count does not move. The figures above are a snapshot; the test is the guarantee. If you change a screen's loading and the count moves, that is the thing to explain, not to update quietly.

## A cohort is loaded once, never once per member

`Leaderboard#completions` and `InstructorReport#done_keys` are the same move — one `where(user: …)` grouped by `user_id` and folded in Ruby.

`InstructorReport` did not start there. It built a `LearnerProgress` per roster row, which cost three queries a student and made `/instructor` **3n + 12** — **273 queries for an 87-student section**. It reads one thing from that object, so it now reads one query for the section instead.

That is the shape of the mistake to watch for: an object that is cheap for one learner, constructed once per learner.

## One `LearnerProgress` per user per request

`User#progress` memoises one and `ApplicationController#progress` hands the view that same instance, which is why `CourseCatalog.for` goes through `user.progress` rather than `LearnerProgress.new(user)`. Building a second one loaded the learner's completions twice on every course and lesson screen.

## The known hotspot: `LearnerProgress.standings`

Two grouped counts over the **entire** `topic_completions` table.

It is memoised on `Current.standings` for the length of a request, because `/progress` asks for a rank more than once and used to pay for all of it twice. `TopicCompletion.record` calls `LearnerProgress.forget_standings` — the same contract `LandingText.forget` and `Landing.forget_cards` carry, and the thing to remember when adding any other whole-table memo.

Correct and cheap at a few thousand rows. The per-request memo is what buys time before it has to be cached or denormalised. `Leaderboard`'s university tab does the same shape of work — every student's rows, folded per learner — so the two share that fate and will need the same answer.

### Which is why the board is deferred rather than optimised

`/leaderboard`'s shell no longer folds the cohort at all. The four queries behind `Leaderboard#entries` moved into a lazy frame, so the screen paints on the viewer's own rows and the whole-table fold happens behind a skeleton.

**It buys perceived latency, not queries** — the total is unchanged and the frame costs a second round trip. Nothing else in the app is split this way, and a screen should only be split when the deferred half is genuinely the expensive half. `test/controllers/leaderboard_frame_test.rb` asserts both halves, since neither is visible from the other.

## The bell's socket

One subscription per open page, and **one poller per process**. `solid_cable` polls its own database every 100ms for new messages — once per Puma process, not once per subscriber — so a section of ninety students is ninety in-memory fan-outs off the same poll rather than ninety pollers.

It polls **the same database the screens read from**, and on the same connection pool. That used to be a database of its own — on SQLite the separation was what stopped a poll every 100ms competing with the single writer. Two things changed it: Postgres has no single-writer contention to avoid, and the managed instance has a connection ceiling that a pool per database blows straight through (see `config/database.yml`). What keeps the poll cheap now is `message_retention: 1.day` and the index on `created_at`, not isolation.

**The pool is therefore the thing to watch.** A poller holding a connection every 100ms is one of the handful the app gets; `pool` has to leave room for it, for Puma's threads and for the Solid Queue supervisor at the same time.

The broadcast itself is **synchronous** rather than `_later`: it renders nothing (the payload is a constant frame), so there is no rendering cost to move off the request, and enqueuing it would make the admin path the second thing in the app to need Solid Queue.

## Caching, and the ceiling

- **Nothing uses `Rails.cache`.** `stale_when_importmap_changes` gives HTML responses an etag; Thruster handles asset caching and compression.
- **The CSP nonce is `SecureRandom`, so HTML bodies are not byte-identical between requests** and `Rack::ETag` stops answering 304 for them. That is a deliberate cost — see the CSP notes in `CLAUDE.md` for why a session-derived nonce would break the landing page for signed-out visitors.
- **One process.** Single Puma, workers in-process, `numInstances: 1` on both deploy targets. Postgres takes concurrent writers where the SQLite file did not, so horizontal scale is no longer barred by the database — but nothing here is deployed that way, and a memo that is correct per-request is not correct per-cluster. Adding a second instance is a decision to make on purpose, not to assume.
- **The only enqueued work in the whole app is the password-reset email** (`deliver_later`). Solid Queue is wired up for it in production and nothing else uses it.
