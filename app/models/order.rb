class Order < ApplicationRecord
  belongs_to :account
  belongs_to :contact, optional: true
  belongs_to :inbox, optional: true

  validates :order_number, presence: true, uniqueness: { scope: :account_id }
  validates :status, inclusion: { in: %w[pendiente enviado entregado cancelado] }

  # Scopes para filtros
  scope :by_status, ->(status) { where(status: status) if status.present? }

  # Filtro por fecha de creación (created_at) en timezone Lima (UTC-5)
  # Una fecha "2026-08-21" en Lima va desde 2026-08-21 05:00:00 UTC hasta 2026-08-22 04:59:59 UTC
  scope :by_created_date, ->(date) {
    if date.present?
      begin
        parsed = Date.parse(date.to_s)
        start_utc = parsed.beginning_of_day.in_time_zone('America/Lima').utc
        end_utc = parsed.end_of_day.in_time_zone('America/Lima').utc
        where(created_at: start_utc..end_utc)
      rescue ArgumentError
        all
      end
    end
  }

  before_validation :generate_order_number, on: :create

  private

  def generate_order_number
    return if order_number.present?

    date_prefix = Time.current.strftime('%y%m%d')
    random_suffix = SecureRandom.alphanumeric(4).upcase
    self.order_number = "ORD-#{date_prefix}-#{random_suffix}"
  end
end
