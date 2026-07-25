class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, presence: true, length: { maximum: 60 }
  validates :email_address, presence: true,
                            uniqueness: { case_sensitive: false },
                            format: { with: URI::MailTo::EMAIL_REGEXP }
  # has_secure_password enforces presence; this adds a floor without breaking
  # updates that leave the password untouched.
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :study_year, inclusion: { in: 1..8 }, allow_nil: true

  def display_affiliation
    [ faculty.presence, (study_year ? "ปีที่ #{study_year}" : nil) ].compact.join(" · ")
  end

  def initials
    name.to_s.strip.split(/\s+/).first(2).map { |part| part[0] }.join.upcase
  end
end
