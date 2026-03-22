module Api
  module V1
    module Admin
      class SessionsController < ::ApplicationController
        protect_from_forgery with: :exception

        skip_before_action :require_login

        # GET /api/v1/admin/session
        def show
          unless admin_logged_in?
            render json: { error: "Unauthorized" }, status: :unauthorized
            return
          end

          unless current_admin.can_read?("Admin")
            render json: { error: "Forbidden" }, status: :forbidden
            return
          end

          loaded_admin = User.includes(roles: :permissions).find(current_admin.id)
          render json: { user: user_json(loaded_admin) }
        end

        # POST /api/v1/admin/session
        def create
          if session[:admin_pending_user_id].present? && params[:email].blank?
            handle_totp_challenge
            return
          end

          user = User.authenticate_by(email: params[:email], password: params[:password])

          unless user&.can_read?("Admin")
            render json: { error: "Invalid email or password" }, status: :unauthorized
            return
          end

          if user.totp_enabled?
            session[:admin_pending_user_id] = user.id
            render json: { totp_required: true }, status: :ok
            return
          end

          complete_admin_login(user)
        end

        # DELETE /api/v1/admin/session
        def destroy
          unless admin_logged_in?
            render json: { error: "Unauthorized" }, status: :unauthorized
            return
          end

          user_id = session[:user_id]
          reset_session
          session[:user_id] = user_id if user_id
          head :no_content
        end

        private

          def handle_totp_challenge
            user = User.find_by(id: session[:admin_pending_user_id])

            unless user
              session.delete(:admin_pending_user_id)
              render json: { error: "Invalid email or password" }, status: :unauthorized
              return
            end

            totp = ROTP::TOTP.new(user.totp_secret, issuer: "Hobo Todo")
            unless totp.verify(params[:totp_code], drift_ahead: 15, drift_behind: 15)
              render json: { error: "Invalid TOTP code" }, status: :unauthorized
              return
            end

            session.delete(:admin_pending_user_id)
            complete_admin_login(user)
          end

          def complete_admin_login(user)
            user_id = session[:user_id]
            reset_session
            session[:user_id] = user_id if user_id
            admin_sign_in(user)
            loaded_user = User.includes(roles: :permissions).find(user.id)
            render json: { user: user_json(loaded_user), csrf_token: form_authenticity_token }
          end

          def user_json(user)
            capabilities = Permission::RESOURCE_TYPES.each_with_object({}) do |resource, hash|
              hash[resource] = {
                read:   user.can_read?(resource),
                write:  user.can_write?(resource),
                delete: user.can_delete?(resource),
                manage: user.can_manage?(resource)
              }
            end
            { id: user.id, email: user.email, name: user.name,
              is_admin: user.admin?, capabilities: capabilities }
          end
      end
    end
  end
end
