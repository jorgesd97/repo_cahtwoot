class CreateCalendarEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :calendar_events do |t|
      t.references :account, null: true, foreign_key: true   # null = feriado nacional
      t.integer :year, null: false
      t.date :date, null: false
      t.string :name, null: false
      t.string :event_type, default: 'nacional', null: false
      t.text :description
      t.string :color, default: '#f59e0b'
      t.string :bg
      t.string :border
      t.string :text_color
      t.string :label

      t.timestamps
    end

    add_index :calendar_events, [:year, :date]
    add_index :calendar_events, [:account_id, :year, :date]
    add_index :calendar_events, [:year, :event_type]
  end
end
