class CreatePromptSets < ActiveRecord::Migration[8.1]
  def change
    create_table :prompt_sets do |t|
      t.string :name, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :prompt_sets, :name, unique: true
  end
end
