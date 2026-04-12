module Api
  module V1
    module Admin
      class UsersController < ApplicationController
        before_action :set_user, only: %i[show update]
        before_action -> { require_capability!("User", "read") }, only: %i[index show]
        before_action -> { require_capability!("User", "write") }, only: %i[create update]

        def index
          scope = User.non_admin_accounts.search(params[:q]).order(:id)
          pagy, records = paginate(scope)
          render json: {
            users: records.as_json(only: %i[id email name created_at updated_at]),
            meta: pagination_meta(pagy),
          }
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

        private

          def set_user
            @user = User.non_admin_accounts.find_by(id: params[:id])
            render json: { error: "Not found" }, status: :not_found unless @user
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
