module RoutinesHelper
  # Carpet SVG units: 100 per metre, 14 m × 8 m, with the judges' table drawn below the carpet
  CARPET_SCALE = 100
  # 5 judges each side of the head judge, as in the prototype
  JUDGE_XS = [ 320, 410, 500, 590, 810, 900, 990, 1080 ].freeze

  STYLE_NAMES = { "taiji" => %w[太极拳 Tàijíquán], "chang" => %w[长拳 Chángquán], "nan" => %w[南拳 Nánquán] }.freeze

  def clock(seconds)
    seconds = seconds.to_i
    format("%d:%02d", seconds / 60, seconds % 60)
  end

  def carpet_point(x, y)
    [ (x * CARPET_SCALE).round, (y * CARPET_SCALE).round ]
  end

  def carpet_path(points)
    points.each_with_index.map { |(x, y), i| "#{i.zero? ? "M" : "L"}#{x} #{y}" }.join(" ")
  end

  def carpet_grid
    vertical = (100...1400).step(100).map { |x| "M#{x} 0 V800" }
    horizontal = (100...800).step(100).map { |y| "M0 #{y} H1400" }
    (vertical + horizontal).join(" ")
  end

  # Start point followed by the end point of every movement that has one
  def carpet_points(routine, movements)
    start = routine.start_x && carpet_point(routine.start_x, routine.start_y)
    [ start, *movements.select(&:end_x).map { |m| carpet_point(m.end_x, m.end_y) } ].compact
  end

  def routine_tabs(routine, current)
    tabs = { learn: [ "学习", routine_path(routine) ], movements: [ "动作名称", movements_routine_path(routine) ] }
    tag.nav(class: "tabs", "aria-label": t("routines.header.sections")) do
      safe_join(tabs.map do |key, (zh, path)|
        link_to "#{zh} · #{t("routines.header.#{key}")}", path, class: "segmented__item", "aria-current": (key == current ? "page" : nil)
      end)
    end
  end
end
