class StatusChange < ApplicationRecord
  belongs_to :offer

  validates :to_status, presence: true
end
