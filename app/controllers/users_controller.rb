class UsersController < ApplicationController
  include VerifyEmail

  skip_before_action :require_login, only: %i[new create]
  before_action :require_logout, only: %i[new create]

  def show; end

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

  def update
    respond_to do |format|
      current_user.assign_attributes(update_params)
      locale_changed = current_user.locale_changed?
      if current_user.save
        format.html { redirect_to projects_url, success: "Your profile has been updated!" }
        unless locale_changed
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
      params.expect(user: %i[email password])
    end

    def update_params
      params.expect(user: %i[name avatar time_zone locale])
    end
end
