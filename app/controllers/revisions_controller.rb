# History of a movement (open to everyone) and the form to change its text (contributors and up).
# Maintainers' and admins' changes are published at once; contributors' wait in the review queue.
class RevisionsController < ApplicationController
  allow_unauthenticated_access only: :index
  before_action :set_movement
  before_action :require_contributor, only: %i[new create]
  before_action :require_reviewer, only: :restore
  rate_limit to: 20, within: 1.hour, only: :create, with: -> { redirect_to new_routine_movement_revision_path(@routine, @movement), alert: t("sessions.rate_limited") }

  def index
    @revisions = @movement.revisions.published.includes(:author, :reviewer, :restored_from).order(:reviewed_at, :id).to_a
  end

  def new
    @revision = @movement.revisions.new(after: @movement.snapshot)
  end

  def create
    @revision = @movement.revisions.new(
      author: Current.user, before: @movement.snapshot, after: proposed_snapshot,
      summary: params.dig(:revision, :summary), source: params.dig(:revision, :source)
    )
    return render(:new, status: :unprocessable_entity) unless @revision.valid?

    if Current.user.can_review?
      @revision.save!
      @revision.publish!(Current.user)
      redirect_to routine_path(@routine, m: @movement.number), notice: t("revisions.create.published")
    else
      @revision.save!
      reviewers.each { |reviewer| RevisionMailer.submitted(@revision, reviewer).deliver_later }
      redirect_to contributions_path, notice: t("revisions.create.submitted")
    end
  end

  # Saves the movement as it was after an earlier revision (or before it, for the original text)
  # as a new revision, so nothing is lost
  def restore
    target = @movement.revisions.published.find(params[:id])
    original = params[:to] == "before"
    revision = @movement.revisions.new(
      author: Current.user, before: @movement.snapshot, after: original ? target.before : target.after, restored_from: target,
      summary: original ? t("revisions.restore.original") : t("revisions.restore.summary", number: revision_number(target))
    )
    if revision.save
      revision.publish!(Current.user)
      redirect_to routine_movement_revisions_path(@routine, @movement), notice: t("revisions.restore.done")
    else
      redirect_to routine_movement_revisions_path(@routine, @movement), alert: t("revisions.restore.same")
    end
  end

  private

  def set_movement
    @routine = Routine.published.find_by!(slug: params[:routine_id])
    @movement = @routine.movements.find_by!(number: params[:movement_number])
  end

  def require_contributor
    if !Current.user.role_at_least?("contributor")
      raise ActionController::RoutingError, "Not Found"
    elsif !Current.user.can_contribute?
      redirect_to email_verification_path, alert: t("revisions.verify_first")
    end
  end

  def require_reviewer
    raise ActionController::RoutingError, "Not Found" unless Current.user&.can_review?
  end

  # r1, r2 … in the order they were published, as on the history page
  def revision_number(revision)
    @movement.revisions.published.order(:reviewed_at, :id).pluck(:id).index(revision.id) + 1
  end

  def reviewers
    User.active.where(role: %w[maintainer admin]).where.not(id: Current.user.id)
  end

  # The form sends lists as text with one item per line
  def proposed_snapshot
    form = params.fetch(:revision, {})
    Movement::EDITABLE.index_with do |field|
      if Movement::LISTS.include?(field)
        %w[en id].index_with { |lang| form["#{field}_#{lang}"].to_s.lines.map(&:squish).compact_blank }
      else
        form[field].to_s.squish.presence
      end
    end
  end
end
