class Admin::UserRolesController < Admin::ApplicationController
  before_action :set_user, only: [:show, :update]

  # GET /admin/users/:user_id/roles
  def show
    @available_roles = Role.all
    @assigned_roles = @user.roles
  end

  # PATCH /admin/users/:user_id/roles
  def update
    role_ids = params[:role_ids] || []
    @user.roles = Role.where(id: role_ids)
    
    if @user.save
      redirect_to admin_user_path(@user), notice: 'ユーザーのロールが更新されました。'
    else
      redirect_to admin_user_path(@user), alert: 'ロールの更新に失敗しました。'
    end
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end
end