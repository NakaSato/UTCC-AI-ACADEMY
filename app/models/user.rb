class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  # Sign-up never asks for a role — everyone starts a student, and an admin grants
  # the rest from /admin. `validate: true` keeps a role posted from that form a
  # validation failure rather than an ArgumentError.
  ROLES = %w[ student instructor admin ].freeze

  enum :role, ROLES.index_by(&:itself), default: "student", validate: true

  normalizes :student_id, with: ->(id) { id.strip.downcase }
  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, presence: true, length: { maximum: 60 }
  # The student ID is what sign-in authenticates on, so it is the required
  # identifier: exactly 13 digits, as printed on the student card. allow_blank on
  # format: presence already reports a blank one, and without it the student sees
  # the same field flagged twice.
  STUDENT_ID_FORMAT = /\A\d{13}\z/

  validates :student_id, presence: true,
                         uniqueness: { case_sensitive: false },
                         format: { with: STUDENT_ID_FORMAT, allow_blank: true }
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

  def display_affiliation
    [ faculty.presence, (study_year ? "ปีที่ #{study_year}" : nil) ].compact.join(" · ")
  end

  def initials
    name.to_s.strip.split(/\s+/).first(2).map { |part| part[0] }.join.upcase
  end

  private
    # Each rule adds its own message, so a student fixing one problem is not
    # ambushed by the next one on the following submit.
    def password_is_hard_to_guess
      errors.add(:password, :missing_letter) unless password.match?(/[[:alpha:]]/)
      errors.add(:password, :missing_digit) unless password.match?(/\d/)
      errors.add(:password, :too_common) if COMMON_PASSWORDS.include?(password.downcase)
      errors.add(:password, :contains_student_id) if student_id.present? && password.include?(student_id)
    end
end
