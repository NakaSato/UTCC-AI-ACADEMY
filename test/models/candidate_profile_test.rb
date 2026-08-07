require "test_helper"

class CandidateProfileTest < ActiveSupport::TestCase
  test "defaults a student profile to private visibility" do
    profile = CandidateProfile.create!(user: users(:one))

    assert_equal "private", profile.visibility
    assert_not profile.application_data_reuse_consent?
  end

  test "records and clears application reuse consent independently" do
    profile = CandidateProfile.create!(user: users(:one), visibility: "searchable", application_data_reuse_consent: true)

    assert profile.consent_given_at
    profile.update!(application_data_reuse_consent: false)
    assert_nil profile.reload.consent_given_at
  end

  test "rejects invalid profile URLs and salary ranges" do
    profile = CandidateProfile.new(user: users(:one), github_url: "not-a-url", salary_expectation_min: 100,
                                   salary_expectation_max: 50)

    assert_not profile.valid?
    assert_predicate profile.errors[:github_url], :any?
    assert_predicate profile.errors[:salary_expectation_max], :any?
  end

  test "allows only one profile per user" do
    CandidateProfile.create!(user: users(:one))
    duplicate = CandidateProfile.new(user: users(:one))

    assert_not duplicate.valid?
    assert_predicate duplicate.errors[:user_id], :any?
  end

  test "rejects staff profiles" do
    profile = CandidateProfile.new(user: users(:instructor))

    assert_not profile.valid?
    assert_predicate profile.errors[:user], :any?
  end
end
