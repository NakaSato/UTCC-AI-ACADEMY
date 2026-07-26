# One attempt at a graded step, and what the server made of it.
#
# The distinction from TopicCompletion is worth holding onto: a completion is the
# outcome and there is exactly one per learner per topic, while a submission is
# the trying and there are as many as it took. Keeping the failures is the point
# — they are what "share failing on first attempt" is counted from, and what the
# Teaching console's average score is a mean of.
#
# `score` is stored rather than re-derived from `answer`, and the difference
# matters: `LessonContent::CHECKS` can change in a deploy, and re-running it over
# old work would retroactively re-mark it under rules that did not exist when it
# was submitted. A grade is a fact about a moment. (The mirror of Notification,
# which stores a kind so the *reader's* present wins — here the writer's past
# must.) NULL means "graded before there was a score", never zero.
#
# Grading is not here. LessonContent owns the answer key and the patterns, this
# owns the record of what was sent and what came back.
class Submission < ApplicationRecord
  belongs_to :user
  belongs_to :course
  belongs_to :topic

  # The exercise and the coding task — the lesson's two graded steps. Each maps
  # to the half of a completion it fills: passing the quiz is having learned the
  # topic, passing the coding task is having applied it.
  KINDS = %w[ quiz code ].freeze
  COMPLETION_KINDS = { "quiz" => :learned, "code" => :applied }.freeze

  validates :kind, inclusion: { in: KINDS }
  # A quiz answer can be "0", so presence would reject a legitimate one; the
  # column is NOT NULL and an empty coding task is a fail, not a bad request.
  validates :answer, exclusion: { in: [ nil ] }

  scope :passed, -> { where(passed: true) }
  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  def completion_kind = COMPLETION_KINDS.fetch(kind)

  # Records the attempt, and the completion it earns. A pass is the only thing
  # that writes a completion, and TopicCompletion.record stays idempotent, so
  # passing twice still leaves one row and the first timestamp.
  # `score` is read with `[]` rather than `fetch`: a verdict that carries none
  # writes NULL, which is the honest record of an attempt nothing scored, and is
  # what the pre-column rows already say.
  def self.record(user:, course:, topic:, kind:, answer:, verdict:)
    submission = create!(user:, course:, topic:, kind:, answer: answer.to_s,
                         passed: verdict.fetch(:passed), score: verdict[:score])

    if submission.passed?
      TopicCompletion.record(user:, course_code: course.code, topic_key: topic.key,
                             kind: submission.completion_kind)
    end

    submission
  end
end
