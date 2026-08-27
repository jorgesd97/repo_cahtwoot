# db/seeds/calendar_events.rb
# Uso: rails runner db/seeds/calendar_events.rb

require 'json'

path = Rails.root.join('config', 'calendars', 'peru_calendar_2026.json')

unless File.exist?(path)
  puts "❌ No se encontró #{path}"
  exit
end

data = JSON.parse(File.read(path))
categories = data['categories'] || {}
year = data['year']

# Borrar SOLO los feriados nacionales del año (los propios de cada cuenta NO se tocan)
deleted = CalendarEvent.where(year: year, account_id: nil).delete_all
puts "🗑️  #{deleted} feriados nacionales del #{year} eliminados"

created = 0
data['holidays'].each do |h|
  cat = categories[h['category']] || {}

  CalendarEvent.create!(
    account_id: nil,          # null = nacional (visible para todas las cuentas)
    year: year,
    date: h['date'],
    name: h['title'],
    event_type: h['category'],
    color: cat['color'] || '#f59e0b',
    bg: cat['bg'],
    border: cat['border'],
    text_color: cat['text'],
    label: cat['label']
  )
  created += 1
end

puts "✅ #{created} feriados nacionales del #{year} cargados en la DB"
