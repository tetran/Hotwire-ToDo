module Admin
  class UsersController < Admin::ApplicationController
    before_action :set_user, only: %i[show edit update destroy]
    before_action :authorize_user_management

    def index
      @users = User.includes(:roles)
                   .order(:created_at)

      return if params[:search].blank?

      search_term = "%#{params[:search]}%".downcase
      @users = @users.where("LOWER(email) LIKE ? OR LOWER(name) LIKE ?",
                            search_term,
                            search_term)
    end

    def show
      @user_projects = @user.projects.includes(:tasks)
      @user_tasks_count = @user.assigned_tasks.count
    end

    def new
      @user = User.new
    end

    def edit; end

    def create
      @user = User.new(user_params)

      if @user.save
        flash[:success] = I18n.t("admin.users.created_successfully", default: "ユーザーを作成しました")
        redirect_to admin_user_path(@user)
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @user.update(user_params)
        flash[:success] = I18n.t("admin.users.updated_successfully", default: "ユーザー情報を更新しました")
        redirect_to admin_user_path(@user)
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @user.force_destroy
        flash[:success] = I18n.t("admin.users.deleted_successfully", default: "ユーザーを削除しました")
        redirect_to admin_users_path
      else
        flash[:error] = I18n.t("admin.users.delete_failed", default: "ユーザーの削除に失敗しました")
        redirect_to admin_user_path(@user)
      end
    end

    private

      def set_user
        @user = User.find(params[:id])
      end

      def user_params
        permitted_params = %i[name email time_zone locale]
        permitted_params += %i[password password_confirmation] if action_name == "create"
        params.expect(user: permitted_params)
      end

      def authorize_user_management
        # All user management operations require Admin:read access to admin area
        authorize_admin_read!

        case action_name
        when "index", "show"
          authorize_user_read!
        when "new", "create", "edit", "update"
          authorize_user_write!
        when "destroy"
          authorize_user_delete!
        end
      end
  end
end
