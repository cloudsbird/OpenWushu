class User < ApplicationRecord
  LOCALES = %w[en id].freeze

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
end
