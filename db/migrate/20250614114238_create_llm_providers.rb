class CreateLlmProviders < ActiveRecord::Migration[7.2]
  def change
    create_table :llm_providers do |t|
      t.string :name, null: false
      t.string :api_endpoint
      t.text :api_key_encrypted
      t.string :organization_id
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :llm_providers, :name, unique: true
  end
end
