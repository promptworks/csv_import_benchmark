enum    = CSV.foreach(Utils.file)
table   = Thing.table_name
columns = enum.first.join(', ')
sql     = "COPY #{table} (#{columns}) FROM STDIN"

Parallel.each(enum.lazy.drop(1).each_slice(5000)) do |chunk|
  conn    = Thing.connection.raw_connection
  encoder = PG::TextEncoder::CopyRow.new

  conn.copy_data sql, encoder do
    chunk.each do |row|
      conn.put_copy_data(row)
    end
  end
end
