module Api
  module V1
    module Admin
      class RolesController < ApplicationController
        before_action :set_role, only: %i[show update destroy]
        before_action :require_manage_access, only: %i[create update destroy]
        before_action :protect_system_role, only: %i[update destroy]

        def index
          roles = Role.order(:id)
          render json: roles.as_json(only: %i[id name description system_role created_at updated_at])
        end

        def show
          render json: @role.as_json(
            only: %i[id name description system_role created_at updated_at],
            include: { permissions: { only: %i[id resource_type action description] } },
          )
        end

        def create
          role = Role.new(role_params)
          if role.save
            render json: role.as_json(only: %i[id name description system_role created_at updated_at]), status: :created
          else
            render json: { errors: role.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          if @role.update(role_params)
            render json: @role.as_json(only: %i[id name description system_role created_at updated_at])
          else
            render json: { errors: @role.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          @role.destroy
          head :no_content
        end

        private

          def set_role
            @role = Role.find_by(id: params[:id])
            render json: { error: "Not found" }, status: :not_found unless @role
          end

          def role_params
            params.expect(role: %i[name description])
          end

          def protect_system_role
            render json: { error: "Forbidden" }, status: :forbidden if @role&.system_role?
          end
      end
    end
  end
end
