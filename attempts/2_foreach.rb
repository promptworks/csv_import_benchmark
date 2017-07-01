CSV.foreach Utils.file, headers: true do |row|
  Thing.create!(row.to_h)
end
