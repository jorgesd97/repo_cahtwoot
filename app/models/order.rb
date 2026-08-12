class Order < ApplicationRecord
  belongs_to :account
  belongs_to :contact, optional: true
  belongs_to :inbox, optional: true

  validates :order_number, presence: true, uniqueness: { scope: :account_id }
  validates :status, inclusion: { in: %w[pendiente enviado entregado cancelado] }

  before_validation :generate_order_number, on: :create

  private

  def generate_order_number
    return if order_number.present?

    date_prefix = Time.current.strftime('%y%m%d')
    random_suffix = SecureRandom.alphanumeric(4).upcase
    self.order_number = "ORD-#{date_prefix}-#{random_suffix}"
  end
end