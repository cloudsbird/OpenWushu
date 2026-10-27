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

  scope :ordered, -> { order(:position, :id) }
  scope :published, -> { where(status: "published") }

  def to_param = slug

  def published? = status == "published"

  def duration_sec = movements.maximum(:end_sec).to_f

  def section_count = movements.distinct.count(:section)
end
