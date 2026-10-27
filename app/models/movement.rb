class Movement < ApplicationRecord
  include Translatable

  SECTION_NAMES = { 1 => "第一段", 2 => "第二段", 3 => "第三段", 4 => "第四段" }.freeze

  belongs_to :routine

  translates :name, :facing
  translates_list :steps, :key_points, :mistakes

  validates :number, numericality: { only_integer: true, greater_than: 0 }, uniqueness: { scope: :routine_id }
  validates :name_zh, :name_pinyin, :name_en, :name_id, presence: true
  validates :end_sec, comparison: { greater_than_or_equal_to: :start_sec }

  def described? = steps_tr.any?

  def section_name = SECTION_NAMES.fetch(section, "第#{ChineseNumeral.call(section)}段")

  def cn_number = ChineseNumeral.call(number)

  def duration_sec = end_sec - start_sec

  # Data the routine player needs in the browser
  def player_data
    { n: number, start: start_sec, end: end_sec, x: end_x, y: end_y, zh: name_zh, py: name_pinyin, tr: name_tr }
  end
end
