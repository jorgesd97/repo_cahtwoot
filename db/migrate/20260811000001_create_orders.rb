class CreateOrders < ActiveRecord::Migration[7.0]
  def change
    create_table :orders do |t|
      t.references :account, null: false, foreign_key: true
      t.references :contact, null: true, foreign_key: true
      t.references :inbox, null: true, foreign_key: true

      t.string :order_number, null: false
      t.string :status, null: false, default: 'pendiente'
      t.string :delivery_type, default: 'delivery'
      t.datetime :delivery_date
      t.string :delivery_address
      t.string :delivery_reference
      t.string :customer_name
      t.string :customer_phone
      t.string :customer_email

      t.decimal :total_amount, precision: 10, scale: 2, default: 0
      t.text :items_json
      t.text :notes

      t.timestamps
    end

    add_index :orders, [:account_id, :order_number], unique: true
    add_index :orders, [:account_id, :status]
  end
end