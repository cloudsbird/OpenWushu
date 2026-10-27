Rails.application.routes.draw do
  root "routines#index"

  resources :routines, only: %i[index show] do
    get :movements, on: :member
    # A movement's history (修订) and the form to change its text
    resources :movements, only: [], param: :number do
      resources :revisions, only: %i[index new create] do
        post :restore, on: :member
      end
    end
  end

  # Review queue (审核) for maintainers and admins, and each contributor's own submissions
  resources :reviews, only: %i[index show] do
    member do
      post :approve
      post :request_changes
      post :reject
    end
  end
  resources :contributions, only: :index

  # Accounts: reading never needs one; discussing and contributing do
  resource :registration, only: %i[new create]
  resource :session, only: %i[new create destroy]
  resources :passwords, param: :token, only: %i[new create edit update]
  resource :email_verification, only: %i[show create]
  get "email_verification/:token", to: "email_verifications#update", as: :verify_email

  # Admin panel: users, routines and site settings. Admins only; others get a 404.
  namespace :admin do
    root to: redirect("/admin/users")
    resources :users, only: %i[index show update destroy] do
      member do
        post :suspend
        post :unsuspend
        post :verify
        post :sign_out_everywhere
        post :password_reset
      end
    end
    resources :routines, only: %i[index edit update] do
      delete :video, on: :member, action: :destroy_video
    end
    resource :settings, only: %i[show update] do
      post :test_email
      delete :smtp_password, action: :destroy_smtp_password
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
