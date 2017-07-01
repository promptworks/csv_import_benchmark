enum    = File.foreach(Utils.file)
table   = Thing.table_name
columns = CSV.parse_line(enum.first).join(', ')
sql     = "COPY #{table} (#{columns}) FROM STDIN CSV"

Parallel.each enum.lazy.drop(1).each_slice(5000) do |chunk|
  conn = Thing.connection.raw_connection

  conn.copy_data sql do
    chunk.each do |row|
      conn.put_copy_data(row)
    end
  end
end
