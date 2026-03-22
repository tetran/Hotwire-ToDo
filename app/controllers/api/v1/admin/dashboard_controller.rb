module Api
  module V1
    module Admin
      class DashboardController < ApplicationController
        def index
          render json: {
            status: "ok",
            stats: {
              users_count: User.count,
              roles_count: Role.count,
              llm_providers_count: LlmProvider.count,
              llm_models_count: LlmModel.count,
            },
            recent_users: recent_users_json,
          }
        end

        private

          def recent_users_json
            return [] unless current_admin.can_read?("User")

            User.order(created_at: :desc).limit(5).as_json(only: %i[id name email created_at])
          end
      end
    end
  end
end
