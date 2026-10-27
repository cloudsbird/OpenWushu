# A proposed or published change to a movement's text. `before` and `after` hold every editable field,
# so a revision can be shown as a diff, checked against later edits, and restored.
class Revision < ApplicationRecord
  STATUSES = %w[pending published changes_requested rejected].freeze
  LIST_LIMIT = 30
  ITEM_LIMIT = 600

  class Stale < StandardError; end

  belongs_to :movement
  belongs_to :author, class_name: "User", optional: true
  belongs_to :reviewer, class_name: "User", optional: true
  belongs_to :restored_from, class_name: "Revision", optional: true

  validates :status, inclusion: { in: STATUSES }
  validates :summary, presence: true, length: { maximum: 200 }
  validates :source, presence: true, length: { maximum: 300 }, unless: :restored_from
  validates :note, length: { maximum: 2000 }
  validate :changes_something, on: :create
  validate :proposed_text, on: :create

  normalizes :summary, :source, :note, with: ->(s) { s.squish.presence }

  scope :pending, -> { where(status: "pending") }
  scope :published, -> { where(status: "published") }
  scope :recent_first, -> { order(created_at: :desc) }

  def pending? = status == "pending"
  def published? = status == "published"

  def changed_fields
    Movement::EDITABLE.select { |field| before[field] != after[field] }
  end

  # True when the movement was edited after this was submitted, in a field this also changes
  def stale?
    current = movement.snapshot
    changed_fields.any? { |field| current[field] != before[field] }
  end

  def publish!(reviewer)
    transaction do
      lock!
      raise Stale if stale?

      movement.update!(after.slice(*changed_fields))
      update!(status: "published", reviewer: reviewer, reviewed_at: Time.current)
    end
  end

  def decide!(status, reviewer:, note:)
    update!(status: status, reviewer: reviewer, note: note, reviewed_at: Time.current)
  end

  private

  def changes_something
    errors.add(:base, :no_changes) if changed_fields.empty?
  end

  def proposed_text
    %w[name_en name_id].each { |field| errors.add(:base, :name_required) if after[field].blank? }
    %w[steps key_points mistakes].each do |field|
      after[field].to_h.each_value do |items|
        errors.add(:base, :too_many_items, count: LIST_LIMIT) if items.size > LIST_LIMIT
        errors.add(:base, :item_too_long, count: ITEM_LIMIT) if items.any? { |item| item.size > ITEM_LIMIT }
      end
    end
    errors.uniq!
  end
end
