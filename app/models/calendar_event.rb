class CalendarEvent < ApplicationRecord
  belongs_to :account, optional: true

  validates :year, presence: true, numericality: { only_integer: true }
  validates :date, presence: true
  validates :name, presence: true
  validates :event_type, presence: true

  # Nacionales: account_id IS NULL
  # Propios: account_id = X

  scope :for_year, ->(year) { where(year: year) }
  scope :for_account, ->(account_id) { where(account_id: account_id).or(where(account_id: nil)) }
  scope :national, -> { where(account_id: nil) }
  scope :own, ->(account_id) { where(account_id: account_id) }
  scope :by_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :by_date, ->(date) { where(date: date) }
  scope :by_event_type, ->(event_type) { where(event_type: event_type) }
end
