class AddDeliveryHourToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :orders, :delivery_hour, :string
  end
end
