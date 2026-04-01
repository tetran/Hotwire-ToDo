module Api
  module V1
    module Admin
      class PromptSetsController < ApplicationController
        before_action :set_prompt_set, only: %i[show update]
        before_action -> { require_capability!("LlmProvider", "read") }, only: %i[index show]
        before_action -> { require_capability!("LlmProvider", "write") }, only: %i[create update]

        def index
          prompt_sets = PromptSet.order(:id)
          render json: prompt_sets.as_json(include: { prompts: { except: %i[created_at updated_at] } })
        end

        def show
          render json: @prompt_set.as_json(include: { prompts: { except: %i[created_at updated_at] } })
                                  .merge(in_use: in_use?)
        end

        def create
          prompt_set = PromptSet.new(prompt_set_params)
          if prompt_set.save
            render json: prompt_set.as_json(include: { prompts: { except: %i[created_at updated_at] } }),
                   status: :created
          else
            render json: { errors: prompt_set.errors }, status: :unprocessable_entity
          end
        end

        def update
          if @prompt_set.update(prompt_set_params)
            render json: @prompt_set.as_json(include: { prompts: { except: %i[created_at
                                                                              updated_at] } }).merge(in_use: in_use?)
          else
            render json: { errors: @prompt_set.errors }, status: :unprocessable_entity
          end
        end

        private

          def set_prompt_set
            @prompt_set = PromptSet.find(params[:id])
          rescue ActiveRecord::RecordNotFound
            render json: { error: "Not found" }, status: :not_found
          end

          def prompt_set_params
            params.expect(prompt_set: [:name, :active, { prompts_attributes: [%i[id role body position _destroy]] }])
          end

          def in_use?
            @prompt_set.suggestion_config_entries
                       .joins(:suggestion_config)
                       .exists?(suggestion_configs: { active: true })
          end
      end
    end
  end
end
