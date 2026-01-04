class CreateReadings < ActiveRecord::Migration[8.1]
  def change
    create_table :readings do |t|
      t.references :device, null: false, foreign_key: true
      t.datetime :timestamp, null: false
      t.integer :count, null: false

      t.timestamps
    end
    add_index :readings, [:device_id, :timestamp], unique: true
  end
end
