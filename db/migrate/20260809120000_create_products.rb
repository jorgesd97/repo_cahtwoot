class CreateProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :products do |t|
      t.references :account, null: false, foreign_key: true
      t.string :title, null: false
      t.string :product_type, null: false, default: 'Físico'
      t.text :description
      t.text :featuresclar
      t.string :image_url
      t.integer :stock, default: 0
      t.decimal :cost, precision: 10, scale: 2, default: 0
      t.decimal :price, precision: 10, scale: 2, default: 0
      t.timestamps
    end
  end
end