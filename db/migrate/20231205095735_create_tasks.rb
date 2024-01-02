class CreateTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :tasks do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.date :due_date
      t.boolean :completed
      t.datetime :completed_at

      t.timestamps
    end
  end
end
