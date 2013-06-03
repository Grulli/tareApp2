class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :email
      t.string :name
      t.string :lastname
      t.integer :deleted
      t.string :hashed_password
      t.string :salt
      t.boolean :admin
      t.string :session_token
      t.string :profile
      t.datetime :last_login_date
      t.string :last_login_server

      t.timestamps
    end
  end
end
