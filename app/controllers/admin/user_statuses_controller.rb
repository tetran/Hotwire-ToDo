class Admin::UserStatusesController < Admin::ApplicationController
  before_action :set_user, only: [:update]

  # PATCH /admin/users/:user_id/status
  def update
    if @user.update(status_params)
      redirect_to admin_user_path(@user), notice: 'ユーザーステータスが更新されました。'
    else
      redirect_to admin_user_path(@user), alert: 'ユーザーステータスの更新に失敗しました。'
    end
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  def status_params
    # Assuming we have a status field - adjust as needed
    params.require(:user).permit(:active)
  end
end