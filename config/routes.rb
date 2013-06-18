TareApp2::Application.routes.draw do
  resources :archives


  resources :homeworks


  resources :users
  
  
	root :to => 'home#index', :as => :home
	
	match 'login' => 'home#login', :as => :login
	match 'login_2' => 'home#login_2', :as => :login_2
	match 'featured_users' => 'home#featured_users', :as => :featured_users
	match 'logout' => 'home#logout', :as => :logout
	match 'profile/:user_id' => 'users#profile'
	match 'edit_profile' => 'users#edit_profile', :via => :get, :as => :edit_profile
	match 'edit_profile' => 'users#edit_profile_post', :via => :post, :as => :edit_profile_post
	match 'change_password'=> 'users#change_password', :via => :get, :as => :change_password
	match 'change_password'=> 'users#change_password_post', :via => :post, :as => :change_password_post
	match 'users_index/:status' => 'users#index'
	match 'admin' => 'home#admin', :as => :admin
	match 'admin_create' => 'users#admin_create', :as => :admin_create
	match 'search_users' => 'users#search', :as => :search_users
	match 'homework/invite/:id' => 'homeworks#invite', :as => :id
	match 'save_homework_invites/:id' => 'homeworks#saveinvites', :as => :id
	match 'homeworks/:homework_id/upload' => 'homeworks#upload'
	match 'activate/:activation_id/:token' => 'users#activate'
	match 'homeworks/manageinvites/:id' => 'homeworks#manageinvites'
	match 'uninvite/:homework_id/:user_id' => 'homeworks#uninvite'
	match 'recover/:recover_id/:token' => 'users#recover_password'
	match 'recover' => 'users#recover', :via => :get, :as => :recover
	match 'recover' => 'users#recover_post', :via => :post, :as => :recover_post
	match 'recover_password' => 'users#recover_password_post', :via => :post, :as => :recover_password_post
	match 'activate_first/:activation_id/:token'  => 'users#activate_first', :via => :get
	match 'activate_first/:activation_id/:token'  => 'users#activate_first_post', :via => :post
	match 'homeworks/:homework_id/viewfiles' => 'homeworks#viewfiles'
	match 'homeworks/:homework_id/viewfiles/:user_id' => 'homeworks#viewfiles'
	match 'example_file.txt' => 'homeworks#example_file', :as => :example_file
	
	match 'facebook' => 'oauth#new_facebook', :as => :facebook_login

	match 'facebook_login' => 'oauth#facebook_login'
	
	match 'shared_files/:owner_id/:homework_id/:enunciado' => 'file#enunciado'
	match 'shared_files/:owner_id/:homework_id/:user_id/:version/zip' => 'file#version_file'
	match 'shared_files/:owner_id/:homework_id/:user_id/:version/:file' => 'file#single_file'
	match 'latest/:homework_id' => 'file#latest'
	
	
end
