Rails.application.routes.draw do
  get 'welcome/index'
  
  resources :pages
  resources :movies
  resources :results
  post 'new' => 'movies#new', as: :new
  
  root 'welcome#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
