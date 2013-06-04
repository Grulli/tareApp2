class CreateArchives < ActiveRecord::Migration
  def change
    create_table :archives do |t|
      t.string :name
      t.integer :version
      t.integer :ip
      t.integer :participation_id

      t.timestamps
    end
  end
end
