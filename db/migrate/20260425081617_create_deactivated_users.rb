class CreateDeactivatedUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :deactivated_users do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.string :original_email, null: false
      t.text :reason
      t.references :deactivated_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :deactivated_at, null: false
      t.timestamps
      t.index :deactivated_at
    end
  end
end
