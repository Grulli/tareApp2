class CreateParticipations < ActiveRecord::Migration
  def change
    create_table :participations do |t|
      t.integer :homework_id
      t.integer :user_id

      t.timestamps
    end
  end
end
