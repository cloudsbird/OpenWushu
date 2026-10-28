class Movement < ApplicationRecord
  include Translatable

  # 预备势, 起势 and 收势 stand outside the numbered 段 in some routines (e.g. 长拳, 太极剑),
  # so they get their own sections
  PREPARATION = -1
  OPENING = 0
  CLOSING = 99
  SECTION_NAMES = {
    PREPARATION => "预备势", OPENING => "起势",
    1 => "第一段", 2 => "第二段", 3 => "第三段", 4 => "第四段",
    CLOSING => "收势"
  }.freeze
  # Text contributors can change. Chinese names, pinyin and order are facts from the reference book;
  # timings, the carpet path and figures get their own editors later.
  EDITABLE = %w[name_en name_id facing_en facing_id steps key_points mistakes reference].freeze
  LISTS = %w[steps key_points mistakes].freeze

  belongs_to :routine
  has_many :revisions, dependent: :destroy

  translates :name, :facing
  translates_list :steps, :key_points, :mistakes

  validates :number, numericality: { only_integer: true, greater_than: 0 }, uniqueness: { scope: :routine_id }
  validates :name_zh, :name_pinyin, :name_en, :name_id, presence: true
  validates :end_sec, comparison: { greater_than_or_equal_to: :start_sec }

  def described? = steps_tr.any?

  # The editable fields as stored, with lists always shaped { "en" => [...], "id" => [...] }
  def snapshot
    EDITABLE.index_with do |field|
      value = public_send(field)
      LISTS.include?(field) ? %w[en id].index_with { |lang| Array(value.to_h[lang]) } : value
    end
  end

  def to_param = number.to_s

  def section_name = SECTION_NAMES.fetch(section, "第#{ChineseNumeral.call(section)}段")

  # Movements the book leaves unnumbered (e.g. 剑术's 起势) show their name instead of a numeral
  def numbered? = book_number.present? || (1...CLOSING).cover?(section)

  # The numeral printed in the book, which restarts within 起势 and 收势
  def cn_number = numbered? ? ChineseNumeral.call(book_number || number) : name_zh.first

  def cn_label = numbered? ? "第#{cn_number}式" : name_zh

  def duration_sec = end_sec - start_sec

  # Data the routine player needs in the browser
  def player_data
    { n: number, cn: cn_label, start: start_sec, end: end_sec, x: end_x, y: end_y, zh: name_zh, py: name_pinyin, tr: name_tr }
  end
end
