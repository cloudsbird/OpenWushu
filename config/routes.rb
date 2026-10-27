Rails.application.routes.draw do
  root "routines#index"

  resources :routines, only: %i[index show] do
    get :movements, on: :member
  end

  # Accounts: reading never needs one; discussing and contributing do
  resource :registration, only: %i[new create]
  resource :session, only: %i[new create destroy]
  resources :passwords, param: :token, only: %i[new create edit update]
  resource :email_verification, only: %i[show create]
  get "email_verification/:token", to: "email_verifications#update", as: :verify_email

  get "up" => "rails/health#show", as: :rails_health_check
end
