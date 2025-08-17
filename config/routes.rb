# config/routes.rb
Rails.application.routes.draw do
  root "purchases#new"

  resources :purchases do
    collection do
      post  :preview
      delete :destroy_all          # elimina TODAS
      delete :destroy_filtered     # elimina SOLO las filtradas actualmente
    end
  end
end
