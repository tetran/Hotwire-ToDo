class ChangeDefaultLocaleToJa < ActiveRecord::Migration[8.1]
  def change
    change_column_default :users, :locale, from: "en", to: "ja"
  end
end
