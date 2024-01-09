class UsersController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]
  before_action :require_logout, only: [:new, :create]

  def new
    @user = User.new
  end

  def create
    @user = User.new(creation_params)
    if @user.save
      sign_in(@user)
      redirect_to root_url
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def update
    respond_to do |format|
      if current_user.update(update_params)
        format.html { redirect_to projects_url }
        format.json { render :show, status: :ok }
        format.turbo_stream
      else
        render :show, status: :unprocessable_entity
      end
    end
  end

  private

    def creation_params
      params.require(:user).permit(:email, :password)
    end

    def update_params
      params.require(:user).permit(:name, :avatar)
    end
end
