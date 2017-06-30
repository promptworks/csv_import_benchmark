enum = CSV.foreach(Utils.file, headers: true)

Parallel.each(enum.each_slice(5000)) do |chunk|
  ActiveRecord::Base.transaction do
    chunk.each do |row|
      Thing.create!(row.to_h)
    end
  end
end
