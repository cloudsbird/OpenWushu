# After sign-up: "check your email", resend, and the link from the email.
class EmailVerificationsController < ApplicationController
  allow_unauthenticated_access only: :update
  rate_limit to: 3, within: 10.minutes, only: :create, with: -> { redirect_to email_verification_path, alert: t("sessions.rate_limited") }

  def show
    redirect_to root_path if Current.user.verified?
  end

  def create
    EmailVerificationMailer.verify(Current.user).deliver_later unless Current.user.verified?
    redirect_to email_verification_path, notice: t(".sent")
  end

  # The link only verifies; it never signs anyone in, so a forwarded email cannot open the account
  def update
    if (user = User.find_by_token_for(:email_verification, params[:token]))
      user.verify!
      redirect_to authenticated? ? root_path : new_session_path, notice: t(".verified")
    else
      redirect_to authenticated? ? email_verification_path : new_session_path, alert: t(".invalid")
    end
  end
end
