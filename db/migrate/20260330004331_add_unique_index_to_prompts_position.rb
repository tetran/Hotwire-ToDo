class AddUniqueIndexToPromptsPosition < ActiveRecord::Migration[8.1]
  def change
    add_index :prompts, %i[prompt_set_id position], unique: true
  end
end
