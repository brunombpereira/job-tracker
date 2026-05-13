class Source < ApplicationRecord
  has_many :offers, dependent: :nullify

  validates :name, presence: true, uniqueness: true
end
