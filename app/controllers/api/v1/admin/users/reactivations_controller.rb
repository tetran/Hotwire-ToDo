module Api
  module V1
    module Admin
      module Users
        # Pre-Fork stub. Phase 1A overwrites with the real implementation.
        # API contract:
        #   POST /api/v1/admin/users/:user_id/reactivation
        #   Request body: { new_email?: string }
        #   Responses:
        #     - 204 No Content on success
        #     - 401 / 403 on auth failure (Admin "User" write capability required)
        #     - 404 when target user is not found within User.non_admin_accounts
        #     - 422 on email conflict, body shapes:
        #         { errors: [...], original_email_conflict: true }   # new_email omitted, original email is taken
        #         { errors: [...] }                                  # new_email provided but conflicts
        class ReactivationsController < Admin::ApplicationController
          before_action -> { require_capability!("User", "write") }

          def create
            render json: { error: "Not Implemented" }, status: :not_implemented
          end
        end
      end
    end
  end
end
