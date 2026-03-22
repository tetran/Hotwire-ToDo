module Api
  module V1
    module Admin
      class UsersController < ApplicationController
        before_action :set_user, only: %i[show update destroy]
        before_action :require_user_read_access, only: %i[index show]
        before_action :require_write_access, only: %i[create update]
        before_action :require_delete_access, only: %i[destroy]

        def index
          users = User.includes(:roles).order(:id)
          render json: users.as_json(
            only: %i[id email name created_at updated_at],
            include: { roles: { only: %i[id name] } }
          )
        end

        def show
          render json: @user.as_json(only: %i[id email name created_at updated_at])
        end

        def create
          user = User.new(user_params)
          if user.save
            render json: user.as_json(only: %i[id email name created_at updated_at]), status: :created
          else
            render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          if @user.update(user_update_params)
            render json: @user.as_json(only: %i[id email name created_at updated_at])
          else
            render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          if @user == current_admin
            render json: { error: "Cannot delete yourself" }, status: :forbidden
            return
          end

          @user.force_destroy
          head :no_content
        end

        private

          def set_user
            @user = User.find_by(id: params[:id])
            render json: { error: "Not found" }, status: :not_found unless @user
          end

          def require_user_read_access
            handle_authorization_failure unless current_admin.can_read?("User")
          end

          def user_params
            params.expect(user: %i[email password name])
          end

          def user_update_params
            params.expect(user: %i[email name])
          end
      end
    end
  end
end
