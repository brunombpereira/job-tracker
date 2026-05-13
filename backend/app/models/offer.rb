class Offer < ApplicationRecord
  STATUSES = %w[new interested applied interview offer rejected archived].freeze
  MODALITIES = %w[presencial hibrido remoto].freeze
  SORTABLE = %w[match_score found_date posted_date company title].freeze

  belongs_to :source, optional: true
  has_many :notes,           dependent: :destroy
  has_many :status_changes,  dependent: :destroy

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

  scope :active, -> { where(archived: false) }
  scope :pipeline, -> { active.where.not(status: %w[rejected]) }
  scope :recent,   ->(days = 7) { where(found_date: days.days.ago..) }

  before_validation :set_defaults, on: :create

  private

  def set_defaults
    self.status ||= "new"
    self.found_date ||= Date.current
    self.stack ||= []
  end
end
