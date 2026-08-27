# lib/tasks/calendar.rake
namespace :calendar do
  desc 'Cargar feriados nacionales desde JSON a la DB (borra los del mismo año)'
  task load_national: :environment do
    year = ENV['YEAR'] || Date.current.year
    file = ENV['FILE'] || "peru_calendar_#{year}.json"
    path = Rails.root.join('config', 'calendars', file)

    unless File.exist?(path)
      puts "❌ Archivo no encontrado: #{path}"
      next
    end

    data = JSON.parse(File.read(path))
    categories = data['categories'] || {}

    # Borrar nacionales del año (propios de cuentas NO se tocan)
    deleted = CalendarEvent.where(year: year, account_id: nil).delete_all
    puts "🗑️  #{deleted} feriados nacionales del #{year} eliminados"

    created = 0
    data['holidays'].each do |h|
      cat = categories[h['category']] || {}
      CalendarEvent.create!(
        account_id: nil,
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

    puts "✅ #{created} feriados nacionales del #{year} cargados"
  end

  desc 'Borrar TODOS los eventos del calendario (⚠️ incluye propios)'
  task reset: :environment do
    count = CalendarEvent.delete_all
    puts "🗑️  #{count} eventos eliminados"
  end
end