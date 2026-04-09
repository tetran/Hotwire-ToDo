module Api
  module V1
    module Admin
      class SuggestionConfigsController < ApplicationController
        before_action :set_suggestion_config, only: %i[show update]
        before_action -> { require_capability!("LlmProvider", "read") }, only: %i[index show]
        before_action -> { require_capability!("LlmProvider", "write") }, only: %i[create update]

        def index
          configs = SuggestionConfig.includes(entries: %i[llm_model prompt_set]).order(id: :desc)
          render json: configs.map { |c| config_json(c) }
        end

        def show
          render json: config_json(@suggestion_config)
        end

        def create
          config = SuggestionConfig.create_with_entries!(entries_attributes: entries_create_params)
          render json: config_json(config), status: :created
        rescue ActiveRecord::RecordInvalid => e
          render json: { errors: e.record.errors }, status: :unprocessable_entity
        end

        def update
          unless @suggestion_config.active?
            render json: { error: "Only active suggestion configs can be updated" }, status: :unprocessable_entity
            return
          end

          if @suggestion_config.update(suggestion_config_params)
            render json: config_json(@suggestion_config)
          else
            render json: { errors: @suggestion_config.errors }, status: :unprocessable_entity
          end
        end

        private

          def set_suggestion_config
            @suggestion_config = SuggestionConfig.find(params[:id])
          rescue ActiveRecord::RecordNotFound
            render json: { error: "Not found" }, status: :not_found
          end

          def entries_create_params
            raw = params.dig(:suggestion_config, :entries_attributes)
            return [] if raw.blank?

            Array.wrap(raw).filter_map do |entry|
              next unless entry.respond_to?(:permit)

              entry.permit(:llm_model_id, :prompt_set_id, :weight).to_h.symbolize_keys
            end
          end

          def suggestion_config_params
            params.expect(
              suggestion_config: [{ entries_attributes: [%i[id llm_model_id prompt_set_id weight _destroy]] }],
            )
          end

          def config_json(config)
            config.as_json(
              only: %i[id active created_at updated_at],
              include: {
                entries: {
                  only: %i[id weight llm_model_id prompt_set_id],
                  include: {
                    llm_model: { only: %i[id name display_name] },
                    prompt_set: { only: %i[id name] },
                  },
                },
              },
            )
          end
      end
    end
  end
end
