# Everything under /admin. Visitors are asked to sign in; signed-in members who are not admins
# get a 404, so the panel does not advertise itself.
class Admin::BaseController < ApplicationController
  before_action :require_admin

  private

  def require_admin
    raise ActionController::RoutingError, "Not Found" unless Current.user&.admin?
  end
end
