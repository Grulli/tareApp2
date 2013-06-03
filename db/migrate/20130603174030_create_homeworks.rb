class CreateHomeworks < ActiveRecord::Migration
  def change
    create_table :homeworks do |t|
      t.string :name
      t.string :filename
      t.string :description
      t.boolean :active
      t.datetime :expires_at

      t.timestamps
    end
  end
end
