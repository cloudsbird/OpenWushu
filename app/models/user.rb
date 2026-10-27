class User < ApplicationRecord
  LOCALES = %w[en id].freeze
  # maintainer is reserved for reviewing contributions; it gives no extra access yet
  ROLES = %w[member maintainer admin].freeze

  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :display_name, :club, with: ->(s) { s.squish.presence }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :display_name, presence: true, length: { maximum: 40 }
  validates :club, length: { maximum: 80 }
  validates :locale, inclusion: { in: LOCALES }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :guidelines_accepted_at, presence: { message: :accept_guidelines }
  validates :role, inclusion: { in: ROLES }

  scope :admins, -> { where(role: "admin") }
  scope :active, -> { where(suspended_at: nil) }

  # A new address has to be verified again
  before_update -> { self.verified_at = nil }, if: :will_save_change_to_email_address?

  # The link in the verification email; changing the address makes old links invalid
  generates_token_for :email_verification, expires_in: 24.hours do
    email_address
  end

  # The checkbox on the sign-up form; stored as the time the guidelines were accepted
  def accept_guidelines=(value)
    self.guidelines_accepted_at = ActiveModel::Type::Boolean.new.cast(value) ? Time.current : nil
  end

  # Unverified members can read and sign in, but not post
  def verified?
    verified_at.present?
  end

  def verify!
    update!(verified_at: Time.current) unless verified?
  end

  def admin? = role == "admin"

  def suspended? = suspended_at.present?

  # Suspended members cannot sign in, and their open sessions stop working
  def suspend!
    transaction do
      update!(suspended_at: Time.current)
      sessions.destroy_all
    end
  end

  def unsuspend!
    update!(suspended_at: nil)
  end

  # The only active admin left cannot be demoted, suspended or deleted
  def last_admin?
    admin? && !suspended? && User.admins.active.where.not(id: id).none?
  end
end
