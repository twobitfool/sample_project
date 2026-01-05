class CreateDevices < ActiveRecord::Migration[8.1]
  def change
    create_table :devices do |t|
      t.string :uid, null: false

      t.timestamps
    end
    add_index :devices, :uid, unique: true
  end
end
