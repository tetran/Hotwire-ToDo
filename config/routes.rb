# Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
Rails.application.routes.draw do
  # Defines the root path route ("/")
  root "projects#index"

  get "login" => "sessions#new", as: :login
  post "login" => "sessions#create"
  delete "logout" => "sessions#destroy", as: :logout
  get "signup" => "users#new", as: :signup
  post "signup" => "users#create"

  resources :projects, only: %i[index show new create edit update] do
    resource :archive, only: %i[create destroy], module: :projects
    resources :members, only: %i[create destroy], module: :projects
  end
  namespace :tasks do
    resources :suggestions, only: [:create]
    resources :batches, only: [:create]
    resources :completes, only: [:index]
  end
  resources :tasks, only: %i[show new create edit update destroy] do
    resources :comments, only: %i[new create edit update destroy], module: :tasks
    resource :complete, only: %i[create destroy], module: :tasks
    resource :assign, only: %i[create destroy], module: :tasks
  end

  resource :user, only: %i[show update destroy]
  resource :email, only: %i[edit update]
  resource :password, only: %i[edit update]
  resources :email_verifications, only: %i[show create]
  resources :password_resets, only: %i[new create edit update]
  namespace :totp do
    resource :setting, only: %i[show create update]
    resource :challenge, only: %i[new create]
  end

  # Admin routes
  namespace :admin do
    root "dashboard#index"

    # RESTful user management
    resources :users, only: %i[index show new create edit update destroy] do
      resource :roles, only: %i[show update], controller: "user_roles"
    end

    # RESTful role management
    resources :roles, only: %i[index show new create edit update destroy] do
      resource :permissions, only: %i[show update], controller: "role_permissions"
    end

    # Permissions are read-only for admin interface
    resources :permissions, only: %i[index show]

    # LLM management
    resources :llm_providers, only: %i[index show edit update] do
      resources :llm_models
      resources :available_models, only: [:index]
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
