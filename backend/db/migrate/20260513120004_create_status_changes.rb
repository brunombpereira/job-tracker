class CreateStatusChanges < ActiveRecord::Migration[7.1]
  def change
    create_table :status_changes do |t|
      t.references :offer, null: false, foreign_key: true
      t.string :from_status
      t.string :to_status, null: false
      t.text :reason

      t.timestamps
    end

    add_index :status_changes, %i[offer_id created_at]
  end
end
