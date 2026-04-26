Rails.application.routes.draw do
  devise_for :users

  resources :properties do
    resources :memberships, only: %i[new create edit update destroy]
  end

  resources :documents, only: %i[index show new create destroy]

  namespace :accounting do
    resources :accounts
    resources :transactions
    resources :dues_assessments, path: "dues" do
      resources :payments, controller: "dues_payments", only: %i[new create destroy]
    end
    resources :budget_lines, only: %i[index new create edit update destroy]
    get "reports/summary", to: "reports#summary"
    get "reports/dues_aging", to: "reports#dues_aging"
    get "reports/reserve_balance", to: "reports#reserve_balance"
  end

  use_doorkeeper do
    skip_controllers :applications, :authorized_applications
  end
  use_doorkeeper_openid_connect

  mount LetterOpenerWeb::Engine, at: "/letters" if Rails.env.development?

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
