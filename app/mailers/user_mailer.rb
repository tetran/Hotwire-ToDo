class UserMailer < ApplicationMailer
  def email_verification
    @user = params[:user]
    @sid = @user.generate_token_for(:email_verification)

    I18n.with_locale(@user.locale) do
      mail to: @user.email, subject: t(".subject")
    end
  end

  def password_reset
    @user = params[:user]
    @sid = @user.generate_token_for(:password_reset)

    I18n.with_locale(@user.locale) do
      mail to: @user.email, subject: t(".subject")
    end
  end
end
