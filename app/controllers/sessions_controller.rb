class SessionsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]
  before_action :require_logout, only: [:new, :create]

  def new
  end

  def create
    user = User.authenticate_by(email: params[:email], password: params[:password])
    unless user
      redirect_to login_path(email_hint: params[:email]), error: "Email or password is invalid", status: :unprocessable_entity
      return
    end

    if user.totp_enabled?
      redirect_to new_totp_challenge_path(token: user.generate_token_for(:totp_verification))
    else
      sign_in(user)
      redirect_to project_url(user.inbox_project.id), success: "Logged in!"
    end
  end

  def destroy
    reset_session
    redirect_to login_url
  end
end
