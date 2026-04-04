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
          return handle_totp_challenge if totp_challenge_pending?

          user = authenticate_admin_user
          return unless user

          if user.totp_enabled?
            initiate_totp_challenge(user)
          else
            complete_admin_login(user)
          end
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

          def handle_unverified_request
            render json: { error: "CSRF token invalid" }, status: :unprocessable_entity
          end

          def totp_challenge_pending?
            session[:admin_pending_user_id].present? && params[:email].blank?
          end

          def authenticate_admin_user
            user = User.authenticate_by(email: params[:email], password: params[:password])
            return user if user&.can_read?("Admin")

            render json: { error: "Invalid email or password" }, status: :unauthorized
            nil
          end

          def initiate_totp_challenge(user)
            session[:admin_pending_user_id] = user.id
            render json: { totp_required: true }, status: :ok
          end

          def handle_totp_challenge
            user = User.find_by(id: session[:admin_pending_user_id])

            unless user&.can_read?("Admin")
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
            record_admin_login(user)
            loaded_user = User.includes(roles: :permissions).find(user.id)
            render json: { user: user_json(loaded_user), csrf_token: form_authenticity_token }
          end

          def record_admin_login(user)
            user.admin_login_histories.create!(ip_address: request.remote_ip, user_agent: request.user_agent)
          end

          def user_json(user)
            capabilities = Permission::RESOURCE_TYPES.index_with do |resource|
              {
                read: user.can_read?(resource),
                write: user.can_write?(resource),
                delete: user.can_delete?(resource),
                manage: user.can_manage?(resource),
              }
            end
            { id: user.id, email: user.email, name: user.name,
              is_admin: user.admin?, capabilities: capabilities }
          end
      end
    end
  end
end
