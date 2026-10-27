Rails.application.routes.draw do
  root "routines#index"

  resources :routines, only: %i[index show] do
    get :movements, on: :member
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
