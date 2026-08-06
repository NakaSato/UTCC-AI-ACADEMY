module Observability
  module Redactor
    REDACTED = "[REDACTED]"

    SENSITIVE_KEYS = %r{
      \A(?:password|password_confirmation|current_password|passw|secret|token|cookie|session_id|
      authorization|request_body|body|answer|learner_answer|student_id|learner_id|user_id|account_id|
      email|name|faculty|study_year|ip|ip_address|remote_ip|reset_link|reset_url|headers?)\z
    }ix

    SENSITIVE_VALUES = %r{
      (?:/reset-password/|/password-reset/|https?://[^\s"']+/(?:reset-password|password-reset)/)
    }ix

    module_function

    def call(value = nil, key: nil, **keywords)
      value = keywords if value.nil? && keywords.present?
      return REDACTED if key && key.to_s.match?(SENSITIVE_KEYS)

      case value
      when Hash
        value.each_with_object({}) do |(child_key, child_value), result|
          result[child_key.to_s] = call(child_value, key: child_key)
        end
      when Array
        value.map { |child_value| call(child_value) }
      when String
        value.match?(SENSITIVE_VALUES) ? REDACTED : value
      else
        value
      end
    end
  end
end
