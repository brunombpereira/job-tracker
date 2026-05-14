class CreateScraperRuns < ActiveRecord::Migration[7.1]
  def change
    create_table :scraper_runs do |t|
      t.string  :source_name, null: false # "adzuna", "itjobs", ...
      t.string  :status,      null: false, default: "pending"
      # pending | running | succeeded | failed
      t.integer :offers_found,   null: false, default: 0
      t.integer :offers_created, null: false, default: 0
      t.integer :offers_skipped, null: false, default: 0
      t.jsonb   :params,         null: false, default: {}
      t.text    :error_message
      t.datetime :started_at
      t.datetime :finished_at

      t.timestamps
    end

    add_index :scraper_runs, :source_name
    add_index :scraper_runs, :status
    add_index :scraper_runs, :created_at
  end
end
