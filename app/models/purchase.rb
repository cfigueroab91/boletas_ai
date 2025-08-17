class Purchase < ApplicationRecord
  has_one_attached :document

  validates :total, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
