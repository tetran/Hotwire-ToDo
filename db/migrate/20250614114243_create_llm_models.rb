class CreateLlmModels < ActiveRecord::Migration[7.2]
  def change
    create_table :llm_models do |t|
      t.references :llm_provider, null: false, foreign_key: true
      t.string :name, null: false
      t.string :display_name
      t.boolean :active, default: true
      t.boolean :default_model, default: false

      t.timestamps
    end

    add_index :llm_models, [:llm_provider_id, :name], unique: true
    add_index :llm_models, :default_model
  end
end
