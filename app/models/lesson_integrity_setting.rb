# Whether the student-facing integrity log is visible for one lesson. The
# setting is deliberately separate from Proctoring: hiding the sidebar must not
# stop the browser from reporting incidents or remove the audit trail.
class LessonIntegritySetting < ApplicationRecord
  belongs_to :course

  validates :enabled, inclusion: { in: [ true, false ] }
  validates :topic_key, presence: true, uniqueness: { scope: :course_id }
  validates :lock_version, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  class << self
    def enabled?(course:, topic_key:)
      find_by(course:, topic_key:)&.enabled != false
    end

    def rows_for(course)
      settings = where(course:, topic_key: Syllabus.topic_keys(course.code)).index_by(&:topic_key)

      Syllabus.topic_keys(course.code).map do |topic_key|
        settings[topic_key] || new(course:, topic_key:, enabled: true, lock_version: 0)
      end
    end

    def parse_boolean(value)
      case value.to_s
      when "true", "1" then true
      when "false", "0" then false
      end
    end

    def update!(course:, topic_key:, enabled:, expected_lock_version:)
      setting = find_or_initialize_by(course:, topic_key:)
      expected = Integer(expected_lock_version, exception: false)
      raise ActiveRecord::StaleObjectError, setting if expected.nil? || expected != setting.lock_version

      setting.update!(enabled:)
      setting
    end
  end
end
