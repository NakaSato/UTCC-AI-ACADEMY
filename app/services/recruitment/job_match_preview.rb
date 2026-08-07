module Recruitment
  class JobMatchPreview
    Factor = Data.define(:key, :state, :evidence, :source, :uncertainty)
    Preview = Data.define(:job_post, :factors, :uncertainty)

    FACTOR_KEYS = %w[ skill_fit experience_fit salary_fit location_fit preference_fit learning_fit ].freeze
    STATES = %w[ match partial mismatch unknown ].freeze
    UNCERTAINTY = "Advisory rules-based preview only. It is not a hiring score, eligibility decision, or probability of hiring. Review the full job and correct your profile preferences before applying."

    def self.call(user:, job_post:)
      new(user:, job_post:).call
    end

    def initialize(user:, job_post:)
      @user = user
      @job_post = job_post
    end

    def call
      return unless @user&.student? && @job_post&.visible_to_candidates?

      profile = @user.candidate_profile
      preference = @user.job_discovery_preference
      Preview.new(@job_post, [
        skill_factor(profile),
        experience_factor(profile),
        salary_factor(profile),
        location_factor(profile, preference),
        preference_factor(preference),
        learning_factor
      ], UNCERTAINTY)
    end

    private
      def skill_factor(profile)
        facts = profile&.facts&.where(kind: "skill")&.to_a || []
        job_text = [ @job_post.title, @job_post.summary, @job_post.description, @job_post.category,
                     @job_post.department, @job_post.team ].join(" ").downcase
        matched = facts.filter { |fact| fact.title.present? && job_text.include?(fact.title.downcase) }
        return Factor.new("skill_fit", "unknown", "No structured skill evidence is available for this preview.", "candidate_profile", "Skill requirements were not normalized by an approved provider.") if facts.empty?
        return Factor.new("skill_fit", "unknown", "No profile skill was found in the job text; this is not a rejection.", "candidate_profile + job_post", "Text overlap is a limited signal and may miss equivalent skills.") if matched.empty?

        Factor.new("skill_fit", matched.length == facts.length ? "match" : "partial",
                   "Matched profile skills: #{matched.map(&:title).join(", ")}", "candidate_profile + job_post",
                   "Text overlap is a limited signal and may miss equivalent skills.")
      end

      def experience_factor(profile)
        facts = profile&.facts&.where(kind: "experience")&.to_a || []
        return Factor.new("experience_fit", "unknown", "No structured experience evidence is available for this preview.", "candidate_profile", "Experience quality and seniority cannot be determined from record count.") if facts.empty?

        Factor.new("experience_fit", "partial", "Profile contains #{facts.size} experience entr#{facts.size == 1 ? "y" : "ies"}; this job lists #{ @job_post.seniority.presence || "an unspecified" } seniority.",
                   "candidate_profile + job_post", "The preview does not judge scope, quality, or seniority equivalence.")
      end

      def salary_factor(profile)
        return Factor.new("salary_fit", "unknown", "Salary expectations or the job range are incomplete.", "candidate_profile + job_post", "No salary conclusion is drawn from missing ranges.") if profile&.salary_expectation_min.blank? || profile.salary_expectation_max.blank? || @job_post.salary_min.blank? || @job_post.salary_max.blank?

        overlaps = profile.salary_expectation_min <= @job_post.salary_max && @job_post.salary_min <= profile.salary_expectation_max
        Factor.new("salary_fit", overlaps ? "match" : "mismatch",
                   "Candidate expectation: #{profile.salary_expectation_min}–#{profile.salary_expectation_max} #{profile.salary_currency}; job range: #{@job_post.salary_min}–#{@job_post.salary_max} #{@job_post.currency}.",
                   "candidate_profile + job_post", "Currency conversion and total compensation are not evaluated.")
      end

      def location_factor(profile, preference)
        location = preference&.location.presence || profile&.preferred_location
        return Factor.new("location_fit", "unknown", "No preferred location is set.", "candidate_profile + discovery_preference", "Work authorization, relocation, and commute are not evaluated.") if location.blank?

        matched = @job_post.location.downcase.include?(location.downcase) || @job_post.remote_policy == "remote"
        Factor.new("location_fit", matched ? "match" : "mismatch", "Preferred location: #{location}; job location: #{@job_post.location}; work mode: #{@job_post.remote_policy}.",
                   "candidate_profile + job_post + discovery_preference", "Remote and location labels do not establish work authorization or suitability.")
      end

      def preference_factor(preference)
        return Factor.new("preference_fit", "unknown", "No explicit employment or work-mode preference is set.", "discovery_preference", "Preferences are optional and can be corrected.") if preference.blank? || (preference.employment_type.blank? && preference.remote_policy.blank?)

        matches = []
        matches << "employment type #{preference.employment_type}" if preference.employment_type.present? && preference.employment_type == @job_post.employment_type
        matches << "work mode #{@job_post.remote_policy}" if preference.remote_policy.present? && preference.remote_policy == @job_post.remote_policy
        state = matches.empty? ? "mismatch" : (matches.size == 2 ? "match" : "partial")
        Factor.new("preference_fit", state, matches.present? ? "Matches: #{matches.join(", ")}." : "The job does not match the selected employment or work-mode preference.",
                   "discovery_preference + job_post", "A preference mismatch is not an eligibility decision.")
      end

      def learning_factor
        Factor.new("learning_fit", "unknown", "Learning or growth fit is not evaluated in this preview.", "job_post", "Learning goals and opportunity quality require human review.")
      end
  end
end
