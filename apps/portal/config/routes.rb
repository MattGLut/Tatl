Rails.application.routes.draw do
  devise_for :users

  resources :properties do
    resources :memberships, only: %i[new create edit update destroy]
  end

  resources :documents, only: %i[index show new create destroy]

  mount LetterOpenerWeb::Engine, at: "/letters" if Rails.env.development?

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
