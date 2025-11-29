Rails.application.routes.draw do
  get "handicap_calculations/new"
  get "handicap_calculations/create"
  get "handicap_calculations/show"
  get "golf_rounds/new"
  get "golf_rounds/create"
  get "golf_rounds/index"
  get "training_plans/new"
  get "training_plans/create"
  get "training_plans/show"
  get "training_plans/index"
  # Root path - landing page
  root "home#index"

  # Authentication routes
  get    "/signup",  to: "users#new"
  post   "/signup",  to: "users#create"
  get    "/login",   to: "sessions#new"
  post   "/login",   to: "sessions#create"
  delete "/logout",  to: "sessions#destroy"

  # User resources
  resources :users, only: [ :show ]

  # Golf rounds - for score upload
  resources :golf_rounds, only: [ :new, :create, :index ]

  # Handicap calculations
  resources :handicap_calculations, only: [ :new, :create, :show ]

  # Training plans
  resources :training_plans, only: [ :new, :create, :show, :index ]

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
