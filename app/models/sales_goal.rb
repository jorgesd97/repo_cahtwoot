class SalesGoal < ApplicationRecord
  belongs_to :account

  validates :year, presence: true, numericality: { only_integer: true }
  validates :month, presence: true, numericality: { only_integer: true, in: 1..12 }
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :month, uniqueness: { scope: [:account_id, :year], message: 'ya tiene una meta configurada' }

  scope :for_month, ->(year, month) { where(year: year, month: month) }
  scope :for_year, ->(year) { where(year: year) }
end
