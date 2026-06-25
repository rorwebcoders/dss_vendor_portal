Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  devise_for :users,
  skip: [:registrations],
  controllers: {
    sessions: "users/sessions",
    passwords: "users/passwords"
  }

  resource :account, only: [:edit, :update]
  resources :purchase_orders, only: [:index, :show, :update] do
    member do
      patch :accept
      patch :reject
      patch :update
      get :print_label
      get :download_label
    end
  end

  namespace :api do
    namespace :v1 do
      namespace :skumonster do
        get :non_dropshipping_orders, to: 'non_dropshippings#index'
      end
    end
  end

  namespace :admin do
    post "api_token/update", to: "api_token#update", as: :api_token_update
  end

  authenticated :user do
    root "purchase_orders#index", as: :authenticated_root
  end

  root "purchase_orders#index"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
