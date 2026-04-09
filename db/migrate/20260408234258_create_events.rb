class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :event_name, null: false
      t.datetime :occurred_at, null: false
      t.references :user, null: false, foreign_key: { on_delete: :nullify }
      t.references :project, foreign_key: { on_delete: :nullify }
      t.references :task, foreign_key: { on_delete: :nullify }
      t.string :feature_category, null: false
      t.json :metadata, default: {}
      t.timestamps
    end

    add_index :events, :event_name
    add_index :events, :occurred_at
    add_index :events, :feature_category
  end
end
