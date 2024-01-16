class UserMailer < ApplicationMailer
  def email_verification
    @user = params[:user]
    @sid = @user.generate_token_for(:email_verification)

    mail to: @user.email, subject: "Verify your email"
  end

  def password_reset
    @user = params[:user]
    @sid = @user.generate_token_for(:password_reset)

    mail to: @user.email, subject: "Reset your password"
  end
end
