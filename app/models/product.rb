class Product < ApplicationRecord
  belongs_to :account
  
  validates :title, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  
  def margin
    return 0 if price.zero?
    ((price - cost) / price * 100).round(1)
  end
end