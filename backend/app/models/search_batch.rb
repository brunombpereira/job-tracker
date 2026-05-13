class SearchBatch < ApplicationRecord
  STATUSES = %w[pending running succeeded partial failed].freeze
  TERMINAL = %w[succeeded partial failed].freeze

  has_many :scraper_runs, dependent: :nullify

  validates :status, inclusion: { in: STATUSES }

  scope :recent, -> { order(created_at: :desc) }

  def duration_seconds
    return nil unless started_at && finished_at
    (finished_at - started_at).round(1)
  end

  def progress
    children = scraper_runs.to_a
    total = sources_requested.size.nonzero? || children.size
    {
      total:     total,
      done:      children.count { |r| %w[succeeded failed].include?(r.status) },
      running:   children.count { |r| r.status == "running" },
      pending:   total - children.size + children.count { |r| r.status == "pending" }
    }
  end

  # Recompute status from children. Called after every ScraperRun transition
  # so the batch's status stays in sync with its constituents.
  #
  # Rules:
  #   - any child still pending/running → "running" (and stamp started_at)
  #   - all children finished, all succeeded → "succeeded"
  #   - all children finished, all failed   → "failed"
  #   - all children finished, mix          → "partial"
  def refresh_status!
    children = scraper_runs.reload.to_a
    return if children.empty? && sources_requested.any?

    if children.any? { |r| %w[pending running].include?(r.status) } ||
       children.size < sources_requested.size
      update!(status: "running", started_at: started_at || Time.current)
      return
    end

    succeeded_count = children.count { |r| r.status == "succeeded" }
    failed_count    = children.count { |r| r.status == "failed" }

    final_status =
      if failed_count.zero?
        "succeeded"
      elsif succeeded_count.zero?
        "failed"
      else
        "partial"
      end

    update!(
      status:         final_status,
      finished_at:    Time.current,
      offers_found:   children.sum(&:offers_found),
      offers_created: children.sum(&:offers_created),
      offers_skipped: children.sum(&:offers_skipped)
    )
  end

  def terminal?
    TERMINAL.include?(status)
  end
end
