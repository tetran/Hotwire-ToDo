class Admin::UsersController < Admin::ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :authorize_user_management

  def index
    @users = User.includes(:roles)
                 .order(:created_at)
    
    if params[:search].present?
      @users = @users.where("email ILIKE ? OR name ILIKE ?", 
                           "%#{params[:search]}%", 
                           "%#{params[:search]}%")
    end
  end

  def show
    @user_projects = @user.projects.includes(:tasks)
    @user_tasks_count = @user.assigned_tasks.count
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    
    if @user.save
      flash[:success] = I18n.t('admin.users.created_successfully', default: 'ユーザーを作成しました')
      redirect_to admin_user_path(@user)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @user.update(user_params)
      flash[:success] = I18n.t('admin.users.updated_successfully', default: 'ユーザー情報を更新しました')
      redirect_to admin_user_path(@user)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user.destroy
      flash[:success] = I18n.t('admin.users.deleted_successfully', default: 'ユーザーを削除しました')
      redirect_to admin_users_path
    else
      flash[:error] = I18n.t('admin.users.delete_failed', default: 'ユーザーの削除に失敗しました')
      redirect_to admin_user_path(@user)
    end
  end


  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    permitted_params = [:name, :email, :time_zone, :locale]
    permitted_params += [:password, :password_confirmation] if action_name == 'create'
    params.require(:user).permit(permitted_params)
  end

  def authorize_user_management
    case action_name
    when 'index', 'show'
      authorize_read!('User')
    when 'new', 'create', 'edit', 'update'
      authorize_write!('User')
    when 'destroy'
      authorize_delete!('User')
    end
  end
end