# A signed-in member's own submitted changes, with their status and the reviewer's note
class ContributionsController < ApplicationController
  def index
    @revisions = Current.user.revisions.includes(:reviewer, movement: :routine).recent_first
  end
end
