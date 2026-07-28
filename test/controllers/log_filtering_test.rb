require "test_helper"

# `Parameters:` is logged at info, which is the level production runs at, so
# anything absent from filter_parameters is written into log retention on every
# request that posts it. The student ID is the credential a student signs in
# with and the rest is the PII /profile collects; the app publishes a PDPA
# notice at /privacy, and this is part of meaning it.
class LogFilteringTest < ActiveSupport::TestCase
  def filtered(params)
    ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters).filter(params)
  end

  test "the sign-in payload keeps neither the credential nor the identifier" do
    result = filtered("student_id" => "2011071730901", "password" => "hunter2A")

    assert_equal "[FILTERED]", result["student_id"]
    assert_equal "[FILTERED]", result["password"]
  end

  test "the profile payload is filtered inside the nested user hash too" do
    result = filtered("user" => {
      "name" => "นักศึกษา หนึ่ง", "faculty" => "วิศวกรรมศาสตร์",
      "study_year" => 2, "email_address" => "one@example.com"
    })

    assert_equal %w[ [FILTERED] ] * 4, result["user"].values_at(
      "name", "faculty", "study_year", "email_address"
    )
  end

  # Guarding the list itself: these are the keys the app actually posts, and a
  # key dropped from the initializer is a silent regression — nothing on screen
  # would ever show it.
  test "every attribute the auth and profile forms post is on the list" do
    %i[ student_id password email_address name faculty study_year ].each do |key|
      assert_equal "[FILTERED]", filtered(key.to_s => "x")[key.to_s],
        "#{key} should never reach the log"
    end
  end
end
