class CreateSuggestionConfigs < ActiveRecord::Migration[8.1]
  def change
    create_table :suggestion_configs do |t|
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :suggestion_configs, :active, unique: true, where: "active = 1",
                                            name: "index_suggestion_configs_unique_active"
  end
end
