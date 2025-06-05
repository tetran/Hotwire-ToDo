class CreatePermissions < ActiveRecord::Migration[7.2]
  def change
    create_table :permissions do |t|
      t.string :resource_type, null: false
      t.string :action, null: false
      t.text :description

      t.timestamps
    end
    
    add_index :permissions, [:resource_type, :action], unique: true
  end
end
