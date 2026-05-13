class ScraperRun < ApplicationRecord
  STATUSES = %w[pending running succeeded failed].freeze

  validates :source_name, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :recent,    -> { order(created_at: :desc) }
  scope :succeeded, -> { where(status: "succeeded") }
  scope :failed,    -> { where(status: "failed") }

  def duration_seconds
    return nil unless started_at && finished_at
    (finished_at - started_at).round(1)
  end

  def mark_running!
    update!(status: "running", started_at: Time.current)
  end

  def mark_succeeded!(found:, created:, skipped:)
    update!(
      status:         "succeeded",
      offers_found:   found,
      offers_created: created,
      offers_skipped: skipped,
      finished_at:    Time.current
    )
  end

  def mark_failed!(message)
    update!(
      status:        "failed",
      error_message: message.to_s[0, 1000],
      finished_at:   Time.current
    )
  end
end
