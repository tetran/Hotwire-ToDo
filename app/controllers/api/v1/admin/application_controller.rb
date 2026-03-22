module Api
  module V1
    module Admin
      class ApplicationController < ::ApplicationController
        protect_from_forgery with: :exception

        skip_before_action :require_login
        before_action :require_admin_access

        private

          def require_admin_access
            unless admin_logged_in?
              render json: { error: "Unauthorized" }, status: :unauthorized
              return
            end

            return if current_admin.can_read?("Admin")

            render json: { error: "Forbidden" }, status: :forbidden
          end

          def handle_authorization_failure(_resource_type = nil, _action = nil, _redirect_path = nil)
            render json: { error: "Forbidden" }, status: :forbidden
          end

          def require_user_write_access
            render json: { error: "Forbidden" }, status: :forbidden unless current_admin.can_write?("User")
          end

          def require_user_delete_access
            render json: { error: "Forbidden" }, status: :forbidden unless current_admin.can_delete?("User")
          end

          def require_manage_access
            render json: { error: "Forbidden" }, status: :forbidden unless current_admin.admin?
          end

          def require_llm_provider_read_access
            render json: { error: "Forbidden" }, status: :forbidden unless current_admin.can_read?("LlmProvider")
          end

          def require_llm_provider_write_access
            render json: { error: "Forbidden" }, status: :forbidden unless current_admin.can_write?("LlmProvider")
          end

          def require_llm_provider_delete_access
            render json: { error: "Forbidden" }, status: :forbidden unless current_admin.can_delete?("LlmProvider")
          end
      end
    end
  end
end
