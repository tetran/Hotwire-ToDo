class CreatePrompts < ActiveRecord::Migration[8.1]
  def change
    create_table :prompts do |t|
      t.references :prompt_set, null: false, foreign_key: true
      t.string :role, null: false
      t.text :body, null: false
      t.integer :position, null: false

      t.timestamps
    end
  end
end
