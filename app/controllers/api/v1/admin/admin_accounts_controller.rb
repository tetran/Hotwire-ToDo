module Api
  module V1
    module Admin
      class AdminAccountsController < ApplicationController
        before_action :set_admin_account, only: %i[destroy]
        before_action -> { require_capability!("Admin", "read") }, only: %i[index]
        before_action -> { require_capability!("User", "write") }, only: %i[create]
        before_action -> { require_capability!("User", "delete") }, only: %i[destroy]
        before_action :protect_privilege_escalation, only: %i[create]
        before_action :validate_and_set_roles, only: %i[create]

        def index
          admin_accounts = User.admin_accounts.includes(:roles).search(params[:q]).order(:id)
          render json: admin_accounts.as_json(
            only: %i[id email name created_at updated_at],
            include: { roles: { only: %i[id name] } },
          )
        end

        def create
          user = User.new(admin_account_params.except(:role_ids))
          User.transaction do
            user.save!
            user.roles = @roles
          end

          render json: user.as_json(
            only: %i[id email name created_at updated_at],
            include: { roles: { only: %i[id name] } },
          ), status: :created
        rescue ActiveRecord::RecordInvalid
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end

        def destroy
          if @admin_account == current_admin
            render json: { error: "Cannot delete yourself" }, status: :forbidden
            return
          end

          @admin_account.force_destroy
          head :no_content
        end

        private

          def set_admin_account
            @admin_account = User.admin_accounts.find_by(id: params[:id])
            render json: { error: "Not found" }, status: :not_found unless @admin_account
          end

          def admin_account_params
            params.expect(admin_account: [:email, :name, :password, { role_ids: [] }])
          end

          def validate_and_set_roles
            role_ids = parsed_role_ids
            return render_role_error("At least one role is required") if role_ids.empty?

            @roles = Role.where(id: role_ids)
            return render_role_error("Some roles were not found") unless @roles.count == role_ids.count
            return if roles_have_admin_access?

            render_role_error("At least one role with admin access is required")
          end

          def roles_have_admin_access?
            @roles.joins(:permissions)
                  .exists?(permissions: { resource_type: "Admin", action: %w[read manage] })
          end

          def render_role_error(message)
            render json: { error: message }, status: :unprocessable_entity
          end

          def parsed_role_ids
            admin_account_params[:role_ids]&.compact_blank&.map(&:to_i) || []
          end

          def protect_privilege_escalation
            role_ids = params.dig(:admin_account, :role_ids)&.compact_blank&.map(&:to_i) || []
            return if role_ids.empty?

            escalated = escalated_permission_ids(role_ids)
            return if escalated.empty?

            render json: { error: "Forbidden" }, status: :forbidden
          end

          def escalated_permission_ids(role_ids)
            new_ids = RolePermission.where(role_id: role_ids).pluck(:permission_id).uniq
            return [] if new_ids.empty?

            admin_ids = current_admin.roles.joins(:permissions).pluck("permissions.id").uniq
            new_ids - admin_ids
          end
      end
    end
  end
end
