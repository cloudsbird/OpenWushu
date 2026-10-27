# 1 → 一, 12 → 十二, 42 → 四十二 (enough for movement and section numbers below 100)
module ChineseNumeral
  DIGITS = %w[零 一 二 三 四 五 六 七 八 九 十].freeze

  def self.call(n)
    return DIGITS[n] if n <= 10
    return "十#{DIGITS[n % 10]}" if n < 20

    "#{DIGITS[n / 10]}十#{DIGITS[n % 10] unless (n % 10).zero?}"
  end
end
