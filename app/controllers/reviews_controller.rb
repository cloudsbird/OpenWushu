# Review queue (审核): maintainers and admins approve, send back or reject contributors' changes.
# Nobody reviews their own submission.
class ReviewsController < ApplicationController
  before_action :require_reviewer
  before_action :set_revision, except: :index
  before_action :forbid_own, :require_pending, except: %i[index show]

  def index
    @pending = Revision.pending.includes(:author, movement: :routine).order(:created_at)
    @decided = Revision.where.not(status: "pending").where.not(reviewer_id: nil).where.not(author_id: nil)
                       .where("reviewer_id <> author_id").includes(:author, :reviewer, movement: :routine).order(reviewed_at: :desc).limit(20)
  end

  def show
  end

  def approve
    @revision.publish!(Current.user)
    RevisionMailer.decided(@revision).deliver_later if @revision.author
    redirect_to reviews_path, notice: t("reviews.approved")
  rescue Revision::Stale
    redirect_to review_path(@revision), alert: t("reviews.stale")
  end

  def request_changes = decide("changes_requested")

  def reject = decide("rejected")

  private

  def require_reviewer
    raise ActionController::RoutingError, "Not Found" unless Current.user.can_review?
  end

  def set_revision
    @revision = Revision.includes(:author, movement: :routine).find(params[:id])
  end

  def forbid_own
    redirect_to review_path(@revision), alert: t("reviews.own") if @revision.author == Current.user
  end

  def require_pending
    redirect_to review_path(@revision), alert: t("reviews.already_decided") unless @revision.pending?
  end

  # Sending back or rejecting always tells the contributor why
  def decide(status)
    note = params[:note].to_s.strip
    return redirect_to(review_path(@revision), alert: t("reviews.note_required")) if note.blank?

    @revision.decide!(status, reviewer: Current.user, note: note)
    RevisionMailer.decided(@revision).deliver_later if @revision.author
    redirect_to reviews_path, notice: t("reviews.#{status}")
  end
end
