class CreateSearchBatches < ActiveRecord::Migration[7.1]
  def change
    create_table :search_batches do |t|
      t.string   :status, default: "pending", null: false
      t.string   :sources_requested, array: true, default: [], null: false
      t.integer  :offers_found,   default: 0, null: false
      t.integer  :offers_created, default: 0, null: false
      t.integer  :offers_skipped, default: 0, null: false
      t.datetime :started_at
      t.datetime :finished_at

      t.timestamps
    end

    add_index :search_batches, :created_at
    add_index :search_batches, :status

    add_reference :scraper_runs, :search_batch,
                  foreign_key: { on_delete: :nullify },
                  null: true,
                  index: true
  end
end
