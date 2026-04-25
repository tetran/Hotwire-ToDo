module Api
  module V1
    module Admin
      class UsersController < ApplicationController
        before_action :set_user, only: %i[show update]
        before_action -> { require_capability!("User", "read") }, only: %i[index show]
        before_action -> { require_capability!("User", "write") }, only: %i[create update]

        def index
          scope = build_users_scope.includes(deactivation: :deactivated_by).order(:id)
          pagy, records = paginate(scope)
          render json: {
            users: records.map { |u| user_json(u) },
            meta: pagination_meta(pagy),
          }
        end

        def show
          render json: user_json(@user)
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

          def build_users_scope
            base = User.non_admin_accounts
            case params[:status]
            when "deactivated" then base.search_deactivated(params[:q])
            when "all"         then all_users_scope(base)
            else                    base.active.search(params[:q])
            end
          end

          def all_users_scope(base)
            active_ids = base.active.search(params[:q]).select(:id)
            deact_ids  = base.search_deactivated(params[:q]).select(:id)
            base.where(id: active_ids).or(base.where(id: deact_ids))
          end

          def user_json(user)
            deactivation = user.deactivation
            {
              id: user.id,
              email: deactivation ? deactivation.original_email : user.email,
              name: user.name,
              created_at: user.created_at,
              updated_at: user.updated_at,
              original_email: deactivation&.original_email,
              deactivated_at: deactivation&.deactivated_at&.iso8601,
              deactivation_reason: deactivation&.reason,
              deactivated_by: deactivated_by_json(deactivation),
            }
          end

          def deactivated_by_json(deactivation)
            performer = deactivation&.deactivated_by
            return nil unless performer

            { id: performer.id, name: performer.name }
          end

          def set_user
            @user = User.non_admin_accounts.includes(deactivation: :deactivated_by).find_by(id: params[:id])
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
