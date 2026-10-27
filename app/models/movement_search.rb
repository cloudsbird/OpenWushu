# Finds movements by Chinese name, pinyin with or without tone marks ("lan que wei"), or translation.
class MovementSearch
  def initialize(query)
    @needle = self.class.normalize(query)
  end

  def results
    return [] if @needle.blank?

    Movement.joins(:routine).merge(Routine.published).includes(:routine).order(:routine_id, :number).select do |m|
      [ m.name_zh, m.name_pinyin, m.name_en, m.name_id ].any? { |field| self.class.normalize(field).include?(@needle) }
    end
  end

  def self.normalize(text)
    text.to_s.unicode_normalize(:nfd).gsub(/\p{Mn}/, "").downcase.gsub(/[^a-z0-9\p{Han}]/, "")
  end
end
