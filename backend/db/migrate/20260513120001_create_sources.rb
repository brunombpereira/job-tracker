class CreateSources < ActiveRecord::Migration[7.1]
  def change
    create_table :sources do |t|
      t.string :name, null: false
      t.string :color, default: "#4a90b8"

      t.timestamps
    end

    add_index :sources, :name, unique: true
  end
end
