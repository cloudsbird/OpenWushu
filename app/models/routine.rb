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

  VIDEO_TYPES = %w[video/mp4 video/webm].freeze
  VIDEO_MAX_SIZE = 2.gigabytes

  scope :ordered, -> { order(:position, :id) }
  scope :published, -> { where(status: "published") }

  def to_param = slug

  def published? = status == "published"

  def duration_sec = movements.maximum(:end_sec).to_f

  # Numbered 段 only: 起势 and 收势 groups are not counted
  def section_count = movements.where(section: 1...Movement::CLOSING).distinct.count(:section)

  private

  # The Learn tab needs the movement list (names and timings) before a routine can be shown
  def publishable
    errors.add(:status, :no_movements) if movements.empty?
  end

  def acceptable_video
    errors.add(:video, :video_type) unless VIDEO_TYPES.include?(video.blob.content_type)
    errors.add(:video, :video_size, max: VIDEO_MAX_SIZE / 1.gigabyte) if video.blob.byte_size > VIDEO_MAX_SIZE
  end
end
