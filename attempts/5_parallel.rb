enum = CSV.foreach(Utils.file, headers: true)

Parallel.each enum.each_slice(5000) do |chunk|
  things = chunk.map do |row|
    Thing.new(row.to_h)
  end

  Thing.import(things)
end
