class Note < ApplicationRecord
  belongs_to :offer

  validates :content, presence: true
end
