# Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
Rails.application.routes.draw do
  # Defines the root path route ("/")
  root "projects#index"

  get "login" => "sessions#new", as: :login
  post "login" => "sessions#create"
  delete "logout" => "sessions#destroy", as: :logout
  get "signup" => "users#new", as: :signup
  post "signup" => "users#create"

  resources :projects, only: [:index, :show, :new, :create, :edit, :update] do
    resource :archive, only: [:create, :destroy], module: :projects
    resources :members, only: [:create, :destroy], module: :projects
  end
  namespace :tasks do
    resources :suggestions, only: [:create]
    resources :batches, only: [:create]
    resources :completes, only: [:index]
  end
  resources :tasks do
    resources :comments, only: [:new, :create, :edit, :update, :destroy], module: :tasks
    resource :complete, only: [:create, :destroy], module: :tasks
    resource :assign, only: [:create, :destroy], module: :tasks
  end

  resource :user, only: [:show, :update, :destroy]
  resource :email, only: [:edit, :update]
  resource :password, only: [:edit, :update]
  resources :email_verifications, only: [:show, :create]
  resources :password_resets, only: [:new, :create, :edit, :update]
  namespace :totp do
    resource :setting, only: [:show, :create, :update]
    resource :challenge, only: [:new, :create]
  end

  # Admin routes
  namespace :admin do
    root "dashboard#index"
    
    # RESTful user management
    resources :users, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
      resource :status, only: [:update], controller: 'user_statuses'
      resource :roles, only: [:show, :update], controller: 'user_roles'
    end
    
    # RESTful role management
    resources :roles, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
      resource :permissions, only: [:show, :update], controller: 'role_permissions'
    end
    
    # Permissions are read-only for admin interface
    resources :permissions, only: [:index, :show]
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
