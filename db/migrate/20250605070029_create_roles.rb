class CreateRoles < ActiveRecord::Migration[7.2]
  def change
    create_table :roles do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :system_role, default: false, null: false

      t.timestamps
    end
    
    add_index :roles, :name, unique: true
    add_index :roles, :system_role
  end
end
