class ProfileDocument < ApplicationRecord
  # A CV PDF or a cover-letter template, stored as bytes. Exactly one
  # row per `kind` slot — see CreateProfileDocuments.

  CV_KINDS       = %w[cv_pt_visual cv_pt_ats cv_en_visual cv_en_ats].freeze
  TEMPLATE_KINDS = %w[template_pt template_en].freeze
  KINDS          = (CV_KINDS + TEMPLATE_KINDS).freeze

  validates :kind, inclusion: { in: KINDS }, uniqueness: true
  validates :filename, :content_type, presence: true
  validates :data, presence: true

  def self.for_kind(kind)
    find_by(kind: kind.to_s)
  end
end
