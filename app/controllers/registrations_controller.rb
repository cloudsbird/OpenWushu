class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  before_action :redirect_if_authenticated
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_registration_path, alert: t("sessions.rate_limited") }

  def new
    @user = User.new(locale: I18n.locale.to_s)
  end

  def create
    @user = User.new(registration_params)
    if @user.save
      start_new_session_for @user
      cookies.permanent[:locale] = @user.locale
      EmailVerificationMailer.verify(@user).deliver_later
      redirect_to email_verification_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.expect(user: %i[display_name email_address password locale club accept_guidelines])
  end
end
