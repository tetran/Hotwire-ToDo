module Api
  module V1
    module Admin
      class PermissionsController < ApplicationController
        before_action :set_permission, only: [:show]

        def index
          scope = Permission.order(:id)
          pagy, records = paginate(scope)
          render json: {
            permissions: records.as_json(only: %i[id resource_type action description]),
            meta: pagination_meta(pagy),
          }
        end

        def show
          render json: @permission.as_json(
            only: %i[id resource_type action description],
            include: { roles: { only: %i[id name description system_role] } },
          )
        end

        private

          def set_permission
            @permission = Permission.find_by(id: params[:id])
            render json: { error: "Not found" }, status: :not_found unless @permission
          end
      end
    end
  end
end
