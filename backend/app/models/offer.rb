class Offer < ApplicationRecord
  STATUSES = %w[new interested applied interview offer rejected archived].freeze
  MODALITIES = %w[presencial hibrido remoto].freeze
  SORTABLE = %w[match_score found_date posted_date company title].freeze

  # An "applied" offer left untouched for this many days is surfaced as
  # needing a follow-up nudge.
  FOLLOWUP_DAYS = 7

  # Valid forward transitions. Any status can transition to `archived` via
  # archive!. `rejected` is terminal except for archiving.
  TRANSITIONS = {
    "new"        => %w[interested applied rejected archived],
    "interested" => %w[applied rejected archived],
    "applied"    => %w[interview rejected archived],
    "interview"  => %w[offer rejected archived],
    "offer"      => %w[rejected archived],
    "rejected"   => %w[archived],
    "archived"   => []
  }.freeze

  belongs_to :source, optional: true
  has_many :notes,           -> { order(created_at: :desc) }, dependent: :destroy
  has_many :status_changes,  -> { order(created_at: :asc) },  dependent: :destroy

  validates :title, :company, presence: true
  validates :url, uniqueness: { allow_blank: true }
  validates :match_score,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 1,
              less_than_or_equal_to: 5
            },
            allow_nil: true
  validates :status,   inclusion: { in: STATUSES }
  validates :modality, inclusion: { in: MODALITIES }, allow_nil: true

  scope :active,   -> { where(archived: false) }
  scope :pipeline, -> { active.where.not(status: %w[rejected]) }
  scope :recent,   ->(days = 7) { where(found_date: days.days.ago..) }
  # Applications sitting in "applied" past the follow-up window.
  scope :needs_followup, lambda {
    active.where(status: "applied")
          .where(applied_date: ..FOLLOWUP_DAYS.days.ago.to_date)
  }

  before_validation :set_defaults, on: :create
  before_save :stamp_applied_date

  # Move the offer through the status state machine. Validates the
  # transition is allowed by TRANSITIONS, records a StatusChange, and
  # archives the offer if moving to "archived".
  #
  # Raises ArgumentError if the transition is not allowed.
  def transition_to!(new_status, reason: nil)
    new_status = new_status.to_s
    raise ArgumentError, "unknown status: #{new_status}" unless STATUSES.include?(new_status)

    from_status = status
    allowed = TRANSITIONS.fetch(from_status, [])
    unless from_status == new_status || allowed.include?(new_status)
      raise ArgumentError,
            "cannot transition from '#{from_status}' to '#{new_status}'"
    end

    transaction do
      update!(status: new_status, archived: new_status == "archived" || archived)
      status_changes.create!(
        from_status: from_status,
        to_status:   new_status,
        reason:      reason
      )
    end
  end

  # True when this is an "applied" offer that has gone quiet — the UI
  # uses it to nudge the user to follow up. Mirrors the needs_followup scope.
  def needs_followup
    !archived &&
      status == "applied" &&
      applied_date.present? &&
      applied_date <= FOLLOWUP_DAYS.days.ago.to_date
  end

  # Always expose the computed needs_followup flag in JSON, on top of
  # whatever methods/includes the caller asked for.
  def as_json(options = {})
    super(options.merge(methods: Array(options[:methods]) | [ :needs_followup ]))
  end

  private

  def set_defaults
    self.status ||= "new"
    self.found_date ||= Date.current
    self.stack ||= []
  end

  # Record when an offer first entered "applied" so the follow-up nudge
  # has a date to count from. Fires on any save that changes status —
  # the state-machine path (transition_to!) and a direct form edit alike.
  def stamp_applied_date
    self.applied_date ||= Date.current if status == "applied" && status_changed?
  end
end
