class UserMailer < ApplicationMailer
  def email_verification
    @user = params[:user]
    @sid = @user.generate_token_for(:email_verification)

    mail to: @user.email, subject: "Verify your email"
  end
end
