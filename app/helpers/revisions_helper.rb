module RevisionsHelper
  # Line-by-line diff of two lists: [[:same | :del | :ins, text], ...] in reading order
  def diff_lines(before, after)
    before = Array(before)
    after = Array(after)
    # Longest common subsequence table, filled from the end
    lcs = Array.new(before.size + 1) { Array.new(after.size + 1, 0) }
    (before.size - 1).downto(0) do |i|
      (after.size - 1).downto(0) do |j|
        lcs[i][j] = before[i] == after[j] ? lcs[i + 1][j + 1] + 1 : [ lcs[i + 1][j], lcs[i][j + 1] ].max
      end
    end
    i = j = 0
    result = []
    while i < before.size && j < after.size
      if before[i] == after[j]
        result << [ :same, before[i] ]
        i += 1
        j += 1
      elsif lcs[i + 1][j] >= lcs[i][j + 1]
        result << [ :del, before[i] ]
        i += 1
      else
        result << [ :ins, after[j] ]
        j += 1
      end
    end
    result + before[i..].map { [ :del, it ] } + after[j..].map { [ :ins, it ] }
  end

  # Each changed field of a revision as [label, [[kind, text], ...]]; lists are split by language
  def revision_changes(revision)
    revision.changed_fields.flat_map do |field|
      before = revision.before[field]
      after = revision.after[field]
      if Movement::LISTS.include?(field)
        %w[en id].filter_map do |lang|
          next if before.to_h[lang] == after.to_h[lang]

          [ t("revisions.fields.#{field}_#{lang}"), diff_lines(before.to_h[lang], after.to_h[lang]) ]
        end
      else
        [ [ t("revisions.fields.#{field}"), [ ([ :del, before ] if before.present?), ([ :ins, after ] if after.present?) ].compact ] ]
      end
    end
  end

  def person(user)
    user ? user.display_name : t("revisions.deleted_account")
  end
end
