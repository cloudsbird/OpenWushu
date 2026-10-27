class Admin::UsersController < Admin::BaseController
  PER_PAGE = 50
  FILTERS = %w[admin maintainer unverified suspended].freeze

  before_action :set_user, except: :index
  before_action :protect_self_and_last_admin, only: %i[update suspend destroy]

  def index
    @query = params[:q].to_s.strip
    @filter = params[:filter].presence_in(FILTERS)
    users = filtered(User.order(created_at: :desc))
    @total = users.count
    @page = [ params[:page].to_i, 1 ].max
    @users = users.limit(PER_PAGE).offset((@page - 1) * PER_PAGE)
    @counts = {
      all: User.count,
      unverified: User.where(verified_at: nil).count,
      suspended: User.where.not(suspended_at: nil).count,
      week: User.where(created_at: 1.week.ago..).count
    }
  end

  def show
  end

  def update
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: t("admin.users.saved")
    else
      render :show, status: :unprocessable_entity
    end
  end

  def suspend
    @user.suspend!
    redirect_to admin_user_path(@user), notice: t("admin.users.suspended")
  end

  def unsuspend
    @user.unsuspend!
    redirect_to admin_user_path(@user), notice: t("admin.users.unsuspended")
  end

  def verify
    @user.verify!
    redirect_to admin_user_path(@user), notice: t("admin.users.verified")
  end

  def sign_out_everywhere
    @user.sessions.destroy_all
    redirect_to admin_user_path(@user), notice: t("admin.users.signed_out")
  end

  def password_reset
    PasswordsMailer.reset(@user).deliver_later
    redirect_to admin_user_path(@user), notice: t("admin.users.reset_sent")
  end

  def destroy
    @user.destroy!
    redirect_to admin_users_path, notice: t("admin.users.deleted", name: @user.display_name), status: :see_other
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.expect(user: %i[display_name email_address club locale role])
  end

  def filtered(users)
    users = case @filter
    when "admin", "maintainer" then users.where(role: @filter)
    when "unverified" then users.where(verified_at: nil)
    when "suspended" then users.where.not(suspended_at: nil)
    else users
    end
    return users if @query.blank?

    pattern = "%#{User.sanitize_sql_like(@query.downcase)}%"
    users.where("LOWER(display_name) LIKE :q OR email_address LIKE :q OR LOWER(club) LIKE :q", q: pattern)
  end

  # Admins cannot lock themselves out, and the panel always keeps one active admin
  def protect_self_and_last_admin
    demoting = action_name == "update" && params.dig(:user, :role).present? && params.dig(:user, :role) != "admin"
    return unless action_name != "update" || demoting

    if @user == Current.user
      redirect_to admin_user_path(@user), alert: t("admin.users.not_yourself")
    elsif @user.last_admin?
      redirect_to admin_user_path(@user), alert: t("admin.users.last_admin")
    end
  end
end
