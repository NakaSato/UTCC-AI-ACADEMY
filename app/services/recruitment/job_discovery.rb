module Recruitment
  class JobDiscovery
    Recommendation = Data.define(:job_post, :reasons, :uncertainty)
    FILTERS = %w[ query category employment_type location remote_policy ].freeze

    def self.search(params)
      new(params:).search
    end

    def self.recommend(user:, limit: 5)
      new(user:).recommend(limit:)
    end

    def initialize(params: {}, user: nil)
      @params = params
      @user = user
    end

    def search
      scope = JobPost.published_for_candidates.includes(:organization)
      query = normalized(:query)
      if query.present?
        term = "%#{ActiveRecord::Base.sanitize_sql_like(query.downcase)}%"
        scope = scope.where(
          "LOWER(recruitment_job_posts.title) LIKE :term OR LOWER(recruitment_job_posts.summary) LIKE :term OR " \
          "LOWER(recruitment_job_posts.description) LIKE :term OR LOWER(recruitment_job_posts.category) LIKE :term OR " \
          "LOWER(recruitment_job_posts.department) LIKE :term OR LOWER(recruitment_job_posts.team) LIKE :term OR " \
          "LOWER(recruitment_job_posts.location) LIKE :term",
          term:
        )
      end
      scope = scope.where(category: normalized(:category)) if normalized(:category).present?
      scope = scope.where(employment_type: normalized(:employment_type)) if normalized(:employment_type).present?
      scope = scope.where(remote_policy: normalized(:remote_policy)) if normalized(:remote_policy).present?
      scope = scope.where("LOWER(recruitment_job_posts.location) LIKE ?", "%#{normalized(:location)}%") if normalized(:location).present?
      scope.order(published_at: :desc, id: :desc)
    end

    def recommend(limit: 5)
      return [] unless @user&.student?

      profile = @user.candidate_profile
      preference = @user.job_discovery_preference
      dismissed_ids = @user.job_discovery_dismissals.pluck(:job_post_id)
      saved_ids = @user.saved_jobs.pluck(:job_post_id)
      facts = profile ? profile.facts.where(kind: %w[ skill experience certification ]).to_a : []
      jobs = JobPost.published_for_candidates.includes(:organization).where.not(id: dismissed_ids + saved_ids)

      jobs.filter_map do |job|
        reasons = reasons_for(job, facts:, profile:, preference:)
        next if reasons.empty?

        Recommendation.new(job, reasons, "Advisory rules-based preview; review the full job before applying.")
      end.first(limit)
    end

    private
      def normalized(key)
        (@params[key] || @params[key.to_s]).to_s.strip.downcase
      end

      def reasons_for(job, facts:, profile:, preference:)
        text = [ job.title, job.summary, job.description, job.category, job.department, job.team ].join(" ").downcase
        reasons = []
        facts.each do |fact|
          next if fact.title.blank? || !text.include?(fact.title.downcase)

          reasons << "Matches your #{fact.kind}: #{fact.title} (profile evidence)"
        end
        if profile&.preferred_location.present? && job.location.downcase.include?(profile.preferred_location.downcase)
          reasons << "Matches your preferred location: #{profile.preferred_location}"
        end
        if preference&.location.present? && job.location.downcase.include?(preference.location)
          reasons << "Matches your discovery location preference: #{preference.location}"
        end
        if preference&.employment_type.present? && job.employment_type == preference.employment_type
          reasons << "Matches your employment preference: #{job.employment_type}"
        end
        if preference&.remote_policy.present? && job.remote_policy == preference.remote_policy
          reasons << "Matches your work-mode preference: #{job.remote_policy}"
        end
        if preference&.search_query.present? && text.include?(preference.search_query)
          reasons << "Matches your saved discovery phrase: #{preference.search_query}"
        end
        reasons
      end
  end
end
