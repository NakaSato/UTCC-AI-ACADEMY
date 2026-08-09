class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :topic_completions, dependent: :destroy
  has_many :prior_knowledges, dependent: :destroy
  has_many :submissions, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :created_organizations, class_name: "Organization", foreign_key: :creator_id,
                                   dependent: :restrict_with_exception, inverse_of: :creator
  has_many :organization_memberships, dependent: :restrict_with_exception,
                                      inverse_of: :user
  has_many :organizations, through: :organization_memberships
  has_many :sent_organization_invitations, class_name: "OrganizationInvitation", foreign_key: :inviter_id,
                                           dependent: :restrict_with_exception, inverse_of: :inviter
  has_many :received_organization_invitations, class_name: "OrganizationInvitation", foreign_key: :invitee_id,
                                               dependent: :restrict_with_exception, inverse_of: :invitee
  has_many :created_recruitment_job_posts, class_name: "Recruitment::JobPost", foreign_key: :creator_id,
                                           dependent: :restrict_with_exception, inverse_of: :creator
  has_many :requested_job_post_suggestions, class_name: "Recruitment::JobPostSuggestion", foreign_key: :requested_by_id,
                                            dependent: :restrict_with_exception, inverse_of: :requested_by
  has_many :reviewed_job_post_suggestions, class_name: "Recruitment::JobPostSuggestion", foreign_key: :reviewed_by_id,
                                           dependent: :nullify, inverse_of: :reviewed_by
  has_many :created_internship_programs, class_name: "Recruitment::InternshipProgram", foreign_key: :creator_id,
                                        dependent: :restrict_with_exception, inverse_of: :creator
  has_many :mentored_internship_programs, class_name: "Recruitment::InternshipProgram", foreign_key: :mentor_id,
                                         dependent: :nullify, inverse_of: :mentor
  has_many :internship_applications, class_name: "Recruitment::InternshipApplication", foreign_key: :student_id,
                                    dependent: :restrict_with_exception, inverse_of: :student
  has_many :reviewed_internship_applications, class_name: "Recruitment::InternshipApplication", foreign_key: :reviewed_by_id,
                                              dependent: :nullify, inverse_of: :reviewed_by
  has_many :job_applications, class_name: "Recruitment::JobApplication", foreign_key: :candidate_id,
                             dependent: :restrict_with_exception, inverse_of: :candidate
  has_many :reviewed_job_applications, class_name: "Recruitment::JobApplication", foreign_key: :reviewed_by_id,
                                      dependent: :nullify, inverse_of: :reviewed_by
  has_many :job_application_events, class_name: "Recruitment::JobApplicationEvent", foreign_key: :actor_id,
                                   dependent: :restrict_with_exception, inverse_of: :actor
  has_many :sent_job_application_messages, class_name: "Recruitment::JobApplicationMessage", foreign_key: :sender_id,
                                           dependent: :restrict_with_exception, inverse_of: :sender
  has_many :internship_evaluations, class_name: "Recruitment::InternshipEvaluation", foreign_key: :evaluator_id,
                                   dependent: :restrict_with_exception, inverse_of: :evaluator
  has_many :requested_internship_program_suggestions, class_name: "Recruitment::InternshipProgramSuggestion",
                                                     foreign_key: :requested_by_id, dependent: :restrict_with_exception,
                                                     inverse_of: :requested_by
  has_many :reviewed_internship_program_suggestions, class_name: "Recruitment::InternshipProgramSuggestion",
                                                    foreign_key: :reviewed_by_id, dependent: :nullify,
                                                    inverse_of: :reviewed_by
  has_one :candidate_profile, dependent: :destroy, inverse_of: :user
  has_many :requested_resume_analyses, class_name: "Recruitment::CandidateResumeAnalysis", foreign_key: :requested_by_id,
                                      dependent: :restrict_with_exception, inverse_of: :requested_by
  has_many :reviewed_resume_analyses, class_name: "Recruitment::CandidateResumeAnalysis", foreign_key: :reviewed_by_id,
                                     dependent: :nullify, inverse_of: :reviewed_by
  has_many :saved_jobs, class_name: "Recruitment::SavedJob", dependent: :destroy, inverse_of: :user
  has_many :job_discovery_dismissals, class_name: "Recruitment::JobDiscoveryDismissal", dependent: :destroy,
                                      inverse_of: :user
  has_one :job_discovery_preference, class_name: "Recruitment::JobDiscoveryPreference", dependent: :destroy,
                                     inverse_of: :user
  has_many :academic_posts, foreign_key: :owner_id, dependent: :destroy,
                            inverse_of: :owner
  has_many :academic_post_memberships, dependent: :destroy,
                                       inverse_of: :user
  has_many :collaborating_academic_posts, through: :academic_post_memberships,
                                          source: :academic_post
  has_many :sent_academic_post_invitations, class_name: "AcademicPostInvitation",
                                            foreign_key: :inviter_id, dependent: :restrict_with_exception,
                                            inverse_of: :inviter
  has_many :received_academic_post_invitations, class_name: "AcademicPostInvitation",
                                                foreign_key: :invitee_id, dependent: :restrict_with_exception,
                                                inverse_of: :invitee
  has_many :academic_post_revisions, foreign_key: :author_id, dependent: :restrict_with_exception,
                                     inverse_of: :author
  has_many :proposal_requests, dependent: :destroy, inverse_of: :user

  has_many :owned_business_cases, class_name: "BusinessCase", foreign_key: :owner_id,
                                  dependent: :restrict_with_exception, inverse_of: :owner
  has_many :business_case_participations, class_name: "BusinessCaseParticipant",
                                          dependent: :restrict_with_exception, inverse_of: :user
  has_many :assigned_business_case_participants, class_name: "BusinessCaseParticipant",
                                                 foreign_key: :assigned_by_id,
                                                 dependent: :restrict_with_exception, inverse_of: :assigned_by
  has_many :sent_business_case_invitations, class_name: "BusinessCaseInvitation",
                                            foreign_key: :inviter_id, dependent: :restrict_with_exception,
                                            inverse_of: :inviter
  has_many :received_business_case_invitations, class_name: "BusinessCaseInvitation",
                                                foreign_key: :invitee_id, dependent: :restrict_with_exception,
                                                inverse_of: :invitee
  has_many :business_case_submissions, foreign_key: :author_id, dependent: :restrict_with_exception,
                                       inverse_of: :author
  has_many :business_case_comments, foreign_key: :author_id, dependent: :restrict_with_exception,
                                    inverse_of: :author
  has_many :internship_requests, foreign_key: :student_id, dependent: :restrict_with_exception,
                                 inverse_of: :student
  has_many :decided_internship_requests, class_name: "InternshipRequest", foreign_key: :decided_by_id,
                                         dependent: :nullify, inverse_of: :decided_by
  has_many :internship_placements, foreign_key: :student_id, dependent: :restrict_with_exception,
                                   inverse_of: :student
  has_many :acknowledged_internship_progress_reports, class_name: "InternshipProgressReport",
                                                     foreign_key: :acknowledged_by_id, dependent: :nullify,
                                                     inverse_of: :acknowledged_by

  has_many :enrollments, dependent: :destroy
  has_many :sections, through: :enrollments
  # The other side of the same table: what this user teaches, not what they take.
  has_many :sections_taught, class_name: "Section", foreign_key: :instructor_id,
                             dependent: :nullify, inverse_of: :instructor

  # Sign-up never asks for a role — everyone starts a student, and an admin grants
  # the rest from /admin. `validate: true` keeps a role posted from that form a
  # validation failure rather than an ArgumentError.
  ROLES = %w[ student instructor admin ].freeze

  enum :role, ROLES.index_by(&:itself), default: "student", validate: true

  # Not a column: the password-change form on /profile asks for the password in
  # force before it will set a new one, and ProfilesController reports a wrong
  # answer as an error on this name. Active Model reads an attribute back while
  # building that message, so the accessor has to exist or `errors.add` raises
  # NoMethodError instead of reporting anything. Nothing assigns it.
  attr_accessor :current_password

  # `presence` matters as much as the downcasing: each of these columns carries a
  # unique index and each is now optional, so a cleared field has to come back as
  # NULL. Stored as "" it would collide with every other account that cleared
  # it — and `allow_blank` on the uniqueness validations means nothing would
  # catch it before the index did. Same for faculty, which is free text a
  # student can empty out on the profile screen.
  normalizes :student_id, with: ->(id) { id.strip.downcase.presence }
  normalizes :username, with: ->(u) { u.strip.downcase.presence }
  normalizes :email_address, with: ->(e) { e.strip.downcase.presence }
  normalizes :faculty, with: ->(f) { f.strip.presence }

  validates :name, presence: true, length: { maximum: 60 }
  # The student ID is what a learner signs in with: exactly 13 digits, as printed
  # on the student card. It is required at sign-up — the `:registration` context
  # is what RegistrationsController saves in — and optional everywhere else,
  # because an instructor, an administrator, or a company member has no student
  # card and is created by an admin rather than by signing up.
  STUDENT_ID_FORMAT = /\A\d{13}\z/
  # 3–30 characters of lowercase letters, digits, dot, dash, and underscore,
  # starting and ending with a letter or digit. The lookahead requires at least
  # one letter, and that is load-bearing rather than cosmetic: console sign-in
  # reads an all-digit entry as a student ID, so an all-digit username would be
  # a name nobody could sign in with.
  USERNAME_FORMAT = /\A(?=[a-z0-9._-]*[a-z])[a-z0-9][a-z0-9._-]{1,28}[a-z0-9]\z/

  validates :student_id, presence: true, on: :registration
  validates :student_id, uniqueness: { case_sensitive: false },
                         format: { with: STUDENT_ID_FORMAT }, allow_blank: true
  validates :username, uniqueness: { case_sensitive: false },
                       format: { with: USERNAME_FORMAT }, allow_blank: true
  # Three columns can name an account and at least one of them must, or nothing
  # can sign in as it and no screen has anything to print beside its name.
  validate :is_identifiable
  # Sign-up does not ask for an email, so most accounts have none. The column
  # stays unique for the accounts that do — password reset is the only thing
  # that needs it, and it can only reach a student who has one.
  validates :email_address, uniqueness: { case_sensitive: false },
                            format: { with: URI::MailTo::EMAIL_REGEXP },
                            allow_blank: true
  # A good password is 8–72 characters with at least one letter and one digit,
  # is not one of the handful everyone tries first, and is not the student's own
  # ID. 72 is bcrypt's ceiling: it silently ignores anything past it, so a longer
  # password would be a lie rather than extra security.
  PASSWORD_LENGTH = 8..72
  # Lowercased; the check downcases before comparing.
  COMMON_PASSWORDS = %w[
    password password1 password123 passw0rd 12345678 123456789 1234567890
    qwerty123 qwertyuiop iloveyou1 admin123 student1 utcc1234 abc12345
  ].freeze

  # has_secure_password enforces presence; these add a floor without breaking
  # updates that leave the password untouched.
  validates :password, length: { in: PASSWORD_LENGTH }, allow_nil: true
  validate :password_is_hard_to_guess, if: -> { password.present? }

  validates :study_year, inclusion: { in: 1..8 }, allow_nil: true

  # The instructor dashboard is staff-wide: admin is a superset of instructor, so
  # a gate written against this predicate needs no second rule for admins.
  def staff? = instructor? || admin?

  # A revoked membership is not a membership — `active` is what keeps a former
  # recruiter out of the company screens their organization still owns.
  def company_member? = organization_memberships.active.exists?

  # Who /console is for: an account with work outside the student experience,
  # either because an admin granted it a staff role or because a company added
  # it to an organization. Everyone else is a learner and signs in at /login.
  def console_access? = staff? || company_member?

  # What to print where a screen used to print the student ID. A learner still
  # shows their ID; a console account shows the handle it signs in with.
  def identifier = student_id.presence || username.presence || email_address

  # The first password of an admin-created console account, shown to the admin
  # once and never stored in the clear. Built rather than taken straight from
  # `alphanumeric` so it always satisfies the policy above — a run of twelve
  # letters would be rejected for having no digit.
  def self.generate_temporary_password
    letter = ("a".."z").to_a[SecureRandom.random_number(26)]
    "#{letter}#{SecureRandom.alphanumeric(10)}#{SecureRandom.random_number(10)}"
  end

  # Every progress figure the app shows, counted off this user's completions.
  # Memoised per instance: one request asks it for six different cuts.
  def progress = @progress ||= LearnerProgress.new(self)

  # The greeting is on first-name terms; Thai names are written given name first.
  def first_name = name.to_s.strip.split(/\s+/).first.to_s

  def display_affiliation
    [ faculty.presence, (study_year ? "ปีที่ #{study_year}" : nil) ].compact.join(" · ")
  end

  def initials
    name.to_s.strip.split(/\s+/).first(2).map { |part| part[0] }.join.upcase
  end

  private
    def is_identifiable
      return if student_id.present? || username.present? || email_address.present?

      errors.add(:base, :missing_identifier)
    end

    # Each rule adds its own message, so a student fixing one problem is not
    # ambushed by the next one on the following submit.
    def password_is_hard_to_guess
      errors.add(:password, :missing_letter) unless password.match?(/[[:alpha:]]/)
      errors.add(:password, :missing_digit) unless password.match?(/\d/)
      errors.add(:password, :too_common) if COMMON_PASSWORDS.include?(password.downcase)
      errors.add(:password, :contains_student_id) if student_id.present? && password.include?(student_id)
    end
end
