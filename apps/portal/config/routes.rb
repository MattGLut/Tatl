Rails.application.routes.draw do
  devise_for :users

  mount LetterOpenerWeb::Engine, at: "/letters" if Rails.env.development?

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
