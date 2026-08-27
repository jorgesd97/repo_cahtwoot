class CreateSalesGoals < ActiveRecord::Migration[7.1]
  def change
    create_table :sales_goals do |t|
      t.references :account, null: false, foreign_key: true
      t.integer :year, null: false
      t.integer :month, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false, default: 0
      t.string :currency, default: 'S/', null: false

      t.timestamps
    end

    add_index :sales_goals, [:account_id, :year, :month], unique: true
    add_index :sales_goals, [:year, :month]
  end
end
