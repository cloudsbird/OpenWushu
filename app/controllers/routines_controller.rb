class RoutinesController < ApplicationController
  allow_unauthenticated_access
  before_action :set_routine, only: %i[show movements]

  def index
    @routines = Routine.ordered.includes(:movements).group_by(&:style)
    @query = params[:q].to_s.strip
    @results = MovementSearch.new(@query).results if @query.present?
  end

  # Learn tab: video, carpet path and movement list in sync. ?m=12 opens movement 12.
  def show
    @movements = @routine.movements.to_a
    @selected = @movements.find { |m| m.number == params[:m].to_i }
  end

  # Movements tab (动作名称): the full list by section, each linking into Learn
  def movements
    @movements = @routine.movements.to_a
  end

  private

  def set_routine
    @routine = Routine.published.find_by!(slug: params[:id])
  end
end
