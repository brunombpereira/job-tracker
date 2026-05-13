class CreateOffers < ActiveRecord::Migration[7.1]
  def change
    create_table :offers do |t|
      t.string  :title,         null: false
      t.string  :company,       null: false
      t.string  :location
      t.string  :modality
      t.string  :stack, array: true, default: []
      t.string  :url
      t.string  :status,        null: false, default: "new"
      t.integer :match_score
      t.string  :salary_range
      t.string  :company_size
      t.date    :posted_date
      t.date    :found_date,    null: false
      t.date    :applied_date
      t.text    :description
      t.boolean :archived,      null: false, default: false

      t.references :source, foreign_key: true, type: :bigint

      t.timestamps
    end

    add_index :offers, :status
    add_index :offers, :match_score
    add_index :offers, :found_date
    add_index :offers, :url, unique: true, where: "url IS NOT NULL"
    add_index :offers, :stack, using: :gin
  end
end
