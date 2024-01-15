class SessionsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]
  before_action :require_logout, only: [:new, :create]

  def new
  end

  def create
    user = User.authenticate_by(email: params[:email], password: params[:password])
    if user
      sign_in(user)
      redirect_to root_url, success: "Logged in!"
    else
      redirect_to login_path(email_hint: params[:email]), error: "Email or password is invalid"
    end
  end

  def destroy
    reset_session
    redirect_to login_url
  end
end
