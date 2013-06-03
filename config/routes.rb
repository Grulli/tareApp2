TareApp2::Application.routes.draw do
  resources :homeworks


  resources :users
  
  
	root :to => 'home#index', :as => :home
	
	match 'login' => 'home#login', :as => :login
	match 'login_2' => 'home#login_2', :as => :login_2
	match 'logout' => 'home#logout', :as => :logout
	match 'profile/:user_id' => 'users#profile'
	match 'edit_profile' => 'users#edit_profile', :via => :get, :as => :edit_profile
	match 'edit_profile' => 'users#edit_profile_post', :via => :post, :as => :edit_profile_post
	match 'change_password'=> 'users#change_password', :via => :get, :as => :change_password
	match 'change_password'=> 'users#change_password_post', :via => :post, :as => :change_password_post
	match 'users_index/:status' => 'users#index'
	match 'admin' => 'home#admin', :as => :admin
	
end
