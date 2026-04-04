class SessionsController < ApplicationController
  skip_before_action :require_login, only: %i[new create]
  before_action :require_logout, only: %i[new create]
  before_action :authenticate, only: :create
  before_action :handle_auth_failure, only: :create

  def new; end

  def create
    if @user.totp_enabled?
      redirect_to new_totp_challenge_path(token: @user.generate_token_for(:totp_verification))
    else
      sign_in(@user)
      redirect_to project_url(@user.inbox_project.id), success: t("controllers.sessions.create.success")
    end
  end

  def destroy
    reset_session
    redirect_to login_url
  end

  private

    def authenticate
      @user = User.authenticate_by(email: params[:email], password: params[:password])
    end

    def handle_auth_failure
      return if @user

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("notification",
                                                   partial: "shared/notification",
                                                   locals: { status: "error",
                                                             message: t("controllers.sessions.create.failure") }),
                 status: :unprocessable_content
        end
        format.html do
          redirect_to login_path(email_hint: params[:email]),
                      flash: { error: t("controllers.sessions.create.failure") },
                      status: :unprocessable_content
        end
      end
    end
end
