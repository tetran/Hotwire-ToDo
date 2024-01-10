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
  resources :tasks do
    resources :comments, only: [:new, :create, :edit, :update, :destroy], module: :tasks
    resource :complete, only: [:create, :destroy], module: :tasks
    resource :assign, only: [:create, :destroy], module: :tasks
  end
  namespace :tasks do
    resources :suggestions, only: [:create]
    resources :batches, only: [:create]
  end

  resource :user, only: [:show, :update, :destroy]
  resource :email_verification, only: [:show]

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
