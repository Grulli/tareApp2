TareApp2::Application.routes.draw do
  resources :users
  
  
	root :to => 'home#index', :as => :home
	
	match 'login' => 'home#login', :as => :login
	match 'login_2' => 'home#login_2', :as => :login_2
	match 'logout' => 'home#logout', :as => :logout
	match 'profile/:user_id' => 'users#profile'
	match 'edit_profile' => 'users#edit_profile', :via => :get, :as => :edit_profile
	
end
