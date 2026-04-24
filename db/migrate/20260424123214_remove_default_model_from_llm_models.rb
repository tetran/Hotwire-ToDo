class RemoveDefaultModelFromLlmModels < ActiveRecord::Migration[8.0]
  def up
    remove_column :llm_models, :default_model
  end

  def down
    add_column :llm_models, :default_model, :boolean, default: false, null: false
    add_index :llm_models, :default_model
  end
end
