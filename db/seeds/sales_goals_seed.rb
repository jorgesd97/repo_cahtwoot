# db/seeds/sales_goals.rb
# Uso: rails runner db/seeds/sales_goals.rb

account = Account.find(1)

# Meta de agosto 2026 (como en tu foto)
goal = account.sales_goals.find_or_initialize_by(year: 2026, month: 8)
goal.amount = 15000
goal.currency = 'S/'
goal.save!

puts "✅ Meta creada: #{goal.currency} #{goal.amount} para #{goal.month}/#{goal.year}"
