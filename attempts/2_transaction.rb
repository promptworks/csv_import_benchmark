ActiveRecord::Base.transaction do
  CSV.read(Utils.file, headers: true).each do |row|
    Thing.create!(row.to_h)
  end
end
