class Routine < ApplicationRecord
  include Translatable

  STYLES = %w[taiji chang nan].freeze
  STATUSES = %w[published in_progress awaiting].freeze
  CARPET_WIDTH = 14
  CARPET_DEPTH = 8

  has_many :movements, -> { order(:number) }, dependent: :destroy, inverse_of: :routine
  has_one_attached :video

  translates :name

  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }
  validates :style, inclusion: { in: STYLES }
  validates :status, inclusion: { in: STATUSES }
  validates :name_zh, :name_pinyin, :name_en, :name_id, presence: true
  validate :publishable, if: :published?
  validate :acceptable_video, if: -> { video.attached? && attachment_changes["video"] }
  validate :recognised_youtube_url
  validate :embeddable_youtube_video, if: -> { youtube_id_changed? && youtube_id.present? }
  validates :video_author_url, format: { with: %r{\Ahttps?://\S+\z}i }, allow_blank: true

  before_save :clear_video_credit, if: -> { youtube_id_changed? && youtube_id.nil? && !video.attached? }

  # Looks a YouTube video up (swapped out in tests so they never reach the network)
  class_attribute :youtube_lookup, default: ->(id) { YoutubeVideo.lookup(id) }

  VIDEO_TYPES = %w[video/mp4 video/webm].freeze
  VIDEO_MAX_SIZE = 2.gigabytes
  YOUTUBE_ID = /\A[\w-]{11}\z/
  YOUTUBE_HOSTS = %w[youtube.com www.youtube.com m.youtube.com music.youtube.com youtube-nocookie.com www.youtube-nocookie.com].freeze

  # The video ID from any common YouTube link (watch, youtu.be, shorts, embed, live) or a bare ID
  def self.youtube_id_from(url)
    return url if url.match?(YOUTUBE_ID)

    uri = URI.parse(url.start_with?("http") ? url : "https://#{url}")
    id = if uri.host == "youtu.be"
      uri.path.delete_prefix("/")
    elsif YOUTUBE_HOSTS.include?(uri.host)
      Rack::Utils.parse_query(uri.query)["v"] || uri.path[%r{\A/(?:shorts|embed|live|v)/([^/]+)}, 1]
    end
    id if id.to_s.match?(YOUTUBE_ID)
  rescue URI::InvalidURIError
    nil
  end

  scope :ordered, -> { order(:position, :id) }
  scope :published, -> { where(status: "published") }

  def to_param = slug

  # Sets each movement's start from { "number" => seconds } (as typed in the timing editor); a movement
  # ends where the next starts and the last at finish. Returns false, with an error, if the times are
  # missing, negative or out of order.
  def retime(starts, finish)
    times = movements.map { |m| Float(starts.fetch(m.number.to_s)) } << Float(finish)
    unless times.first >= 0 && times.each_cons(2).all? { |a, b| b >= a }
      errors.add(:base, :timings_order)
      return false
    end

    transaction do
      movements.each_with_index { |m, i| m.update!(start_sec: times[i].round(1), end_sec: times[i + 1].round(1)) }
    end
    true
  rescue ArgumentError, TypeError, KeyError
    errors.add(:base, :timings_order)
    false
  end

  # An uploaded video takes priority over a YouTube link
  def video? = video.attached? || youtube_id.present?

  def youtube? = !video.attached? && youtube_id.present?

  # What the admin typed (shown again if it was not recognised), otherwise a link to the saved video
  def youtube_url = @youtube_url.presence || (youtube_id && "https://www.youtube.com/watch?v=#{youtube_id}")

  def youtube_url=(url)
    @youtube_url = url.to_s.strip
    self.youtube_id = @youtube_url.empty? ? nil : self.class.youtube_id_from(@youtube_url)
  end

  def published? = status == "published"

  def duration_sec = movements.maximum(:end_sec).to_f

  # Numbered 段 only: 起势 and 收势 groups are not counted
  def section_count = movements.where(section: 1...Movement::CLOSING).distinct.count(:section)

  private

  # The Learn tab needs the movement list (names and timings) before a routine can be shown
  def publishable
    errors.add(:status, :no_movements) if movements.empty?
  end

  def clear_video_credit
    return if video_title_changed? || video_author_changed?

    self.video_title = self.video_author = self.video_author_url = nil
  end

  def recognised_youtube_url
    errors.add(:youtube_url, :youtube) if @youtube_url.present? && youtube_id.nil?
  end

  # A new link fills in the credit from YouTube, unless the admin typed a credit in the same save.
  # When YouTube can't be reached the link is still accepted and the credit can be typed by hand.
  def embeddable_youtube_video
    case details = youtube_lookup.(youtube_id)
    when :not_embeddable, :not_found
      errors.add(:youtube_url, details)
    when YoutubeVideo::Details
      return if video_title_changed? || video_author_changed?

      self.video_title, self.video_author, self.video_author_url = details.title, details.author, details.author_url
    end
  end

  def acceptable_video
    errors.add(:video, :video_type) unless VIDEO_TYPES.include?(video.blob.content_type)
    errors.add(:video, :video_size, max: VIDEO_MAX_SIZE / 1.gigabyte) if video.blob.byte_size > VIDEO_MAX_SIZE
  end
end
