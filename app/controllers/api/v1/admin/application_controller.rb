module Api
  module V1
    module Admin
      class ApplicationController < ::ApplicationController
        include Paginatable

        protect_from_forgery with: :exception

        skip_before_action :require_login
        before_action :require_admin_access

        private

          def handle_unverified_request
            render json: { error: "CSRF token invalid" }, status: :unprocessable_entity
          end

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

          def require_capability!(resource, action)
            permitted = case action
                        when "read"   then current_admin.can_read?(resource)
                        when "write"  then current_admin.can_write?(resource)
                        when "delete" then current_admin.can_delete?(resource)
                        when "manage" then current_admin.can_manage?(resource)
                        else false
                        end
            render json: { error: "Forbidden" }, status: :forbidden unless permitted
          end

          def require_manage_access
            render json: { error: "Forbidden" }, status: :forbidden unless current_admin.admin?
          end
      end
    end
  end
end
