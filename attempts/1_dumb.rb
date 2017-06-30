require 'csv'

class Thing < ActiveRecord::Base
end

puts 'Reading CSV file...'
rows = CSV.read(Utils.file, headers: true)

i = 0
rows.each do |row|
  puts "Loaded #{i} records" if i % 500 == 0
  Thing.create!(row.to_h)
  i += 1
end

puts "Done. Loaded #{i} records."
