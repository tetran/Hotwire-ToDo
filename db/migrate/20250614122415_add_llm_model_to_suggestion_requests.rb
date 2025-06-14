class AddLlmModelToSuggestionRequests < ActiveRecord::Migration[7.2]
  def up
    # まずnullableでカラムを追加
    add_reference :suggestion_requests, :llm_model, null: true, foreign_key: true
    
    # OpenAIプロバイダーとデフォルトモデルを作成
    openai_provider = LlmProvider.find_or_create_by!(name: "OpenAI") do |provider|
      provider.api_endpoint = "https://api.openai.com/v1"
      provider.api_key = ENV.fetch("OPENAI_ACCESS_TOKEN", "dummy-key-for-migration")
      provider.organization_id = ENV["OPENAI_ORGANIZATION_ID"]
      provider.active = true
    end
    
    default_model = openai_provider.llm_models.find_or_create_by!(name: "gpt-3.5-turbo-1106") do |model|
      model.display_name = "GPT-3.5 Turbo (Legacy)"
      model.active = true
      model.default_model = true
    end
    
    # 既存のレコードにデフォルトモデルを設定
    SuggestionRequest.where(llm_model_id: nil).update_all(llm_model_id: default_model.id)
    
    # カラムをnot nullに変更
    change_column_null :suggestion_requests, :llm_model_id, false
  end
  
  def down
    remove_reference :suggestion_requests, :llm_model, foreign_key: true
  end
end
