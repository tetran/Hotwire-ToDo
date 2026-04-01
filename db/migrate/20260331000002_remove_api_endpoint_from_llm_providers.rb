class RemoveApiEndpointFromLlmProviders < ActiveRecord::Migration[8.0]
  def up
    remove_column :llm_providers, :api_endpoint
  end

  def down
    add_column :llm_providers, :api_endpoint, :string
  end
end
