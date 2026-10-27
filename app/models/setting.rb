# Site-wide settings edited in the admin panel. One row, read fresh on every request.
class Setting < ApplicationRecord
  SMTP_PORTS = [ 587, 465, 25, 2525 ].freeze

  encrypts :smtp_password

  validates :site_name, presence: true, length: { maximum: 60 }
  validates :contact_email, :mail_from, length: { maximum: 120 }
  validates :contact_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :source_url, presence: true, format: { with: %r{\Ahttps?://\S+\z} }
  validates :notice_en, :notice_id, length: { maximum: 300 }
  validates :footer_en, :footer_id, length: { maximum: 500 }
  validates :smtp_port, numericality: { only_integer: true, in: 1..65_535 }, allow_nil: true
  validates :smtp_port, presence: true, if: -> { smtp_address.present? }

  normalizes :notice_en, :notice_id, :footer_en, :footer_id, :contact_email, :mail_from,
             :smtp_address, :smtp_username, with: ->(s) { s.strip.presence }

  def self.current
    first_or_create!
  end

  # The admin form leaves the password field empty; empty means "keep the saved one"
  def smtp_password=(value)
    super(value) if value.present?
  end

  def clear_smtp_password!
    update_column(:smtp_password, nil)
  end

  # Text in the current translation (notice, footer); nil when not set
  def notice = translated(:notice)
  def footer = translated(:footer)

  def smtp_configured?
    smtp_address.present? && smtp_port.present?
  end

  # Options for Mail's SMTP delivery: 465 is TLS from the start, other ports upgrade with STARTTLS
  def smtp_options
    {
      address: smtp_address,
      port: smtp_port,
      user_name: smtp_username,
      password: smtp_password,
      authentication: (smtp_username.present? ? :plain : nil),
      tls: smtp_port == 465,
      enable_starttls_auto: smtp_port != 465,
      open_timeout: 10,
      read_timeout: 10
    }.compact
  end

  private

  def translated(field)
    public_send("#{field}_#{I18n.locale}").presence
  end
end
