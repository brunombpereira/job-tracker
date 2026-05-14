class CreateProfileDocuments < ActiveRecord::Migration[7.1]
  # CV PDFs and cover-letter templates, stored as bytes in Postgres
  # rather than on disk. The deploy target (Render) has an ephemeral
  # filesystem, so disk-stored uploads would vanish on every redeploy;
  # the DB persists. Volume is tiny — at most six small files per
  # instance — so a bytea column is the simplest durable home.
  #
  # One row per `kind` slot (cv_pt_visual, template_en, ...); uploading
  # replaces the row for that slot.
  def change
    create_table :profile_documents do |t|
      t.string :kind,         null: false
      t.string :filename,     null: false
      t.string :content_type, null: false
      t.binary :data,         null: false
      t.timestamps
    end

    add_index :profile_documents, :kind, unique: true
  end
end
