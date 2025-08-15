class UsersController < ApplicationController
  include VerifyEmail

  skip_before_action :require_login, only: [:new, :create]
  before_action :require_logout, only: [:new, :create]

  def new
    @user = User.new
  end

  def create
    @user = User.new(creation_params)
    if @user.save
      sign_in(@user)
      send_email_verification(@user)
      redirect_to project_url(@user.inbox_project.id), success: "Welcome! You have signed up successfully!"
    else
      render :new, status: :unprocessable_content
    end
  end

  def show
  end

  def update
    respond_to do |format|
      current_user.assign_attributes(update_params)
      locale_changed = current_user.locale_changed?
      if current_user.save
        if locale_changed
          format.html { redirect_to projects_url, success: "Your profile has been updated!" }
        else
          format.html { redirect_to projects_url, success: "Your profile has been updated!" }
          format.json { render :show, status: :ok }
          format.turbo_stream
        end
      else
        render :show, status: :unprocessable_content
      end
    end
  end

  private

    def creation_params
      params.require(:user).permit(:email, :password)
    end

    def update_params
      params.require(:user).permit(:name, :avatar, :time_zone, :locale)
    end
end
