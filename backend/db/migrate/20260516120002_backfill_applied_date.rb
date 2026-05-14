class BackfillAppliedDate < ActiveRecord::Migration[7.1]
  # Nothing wrote to offers.applied_date before the follow-up reminder
  # feature, so existing "applied" offers have it blank. Recover the date
  # from the earliest status_change into "applied" — the authoritative
  # record of when the application happened. Offers created directly as
  # "applied" (no status_change) keep a blank date; the model stamps it
  # going forward.
  def up
    execute <<~SQL.squish
      UPDATE offers
      SET applied_date = sub.applied_on
      FROM (
        SELECT offer_id, MIN(created_at)::date AS applied_on
        FROM status_changes
        WHERE to_status = 'applied'
        GROUP BY offer_id
      ) AS sub
      WHERE offers.id = sub.offer_id
        AND offers.applied_date IS NULL
    SQL
  end

  def down
    # Irreversible: we can't tell a backfilled date from one set later.
  end
end
