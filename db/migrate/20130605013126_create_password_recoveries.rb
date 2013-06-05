class CreatePasswordRecoveries < ActiveRecord::Migration
  def change
    create_table :password_recoveries do |t|
      t.integer :user_id
      t.string :token
      t.datetime :expires_at

      t.timestamps
    end
  end
end
