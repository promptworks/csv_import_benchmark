DATA_FILE  = 'data.csv'
COUNT      = ENV.fetch('COUNT', 100_000).to_i
COLUMNS    = %w(one two three four five)
VALUES     = %w(one two three four five)

require_relative 'setup'

class Model < ActiveRecord::Base
end

Benchmark.bm 50 do |x|
  x.extend ReportFiltering
  x.extend ReportWithPadding
  x.extend DatabaseSetup

  x.report '1. CSV.read' do
    rows = CSV.read(DATA_FILE, headers: true)
    rows.each { |row| Model.create!(row.to_h) }
  end

  x.report '2. CSV.foreach' do
    CSV.foreach(DATA_FILE, headers: true) do |row|
      Model.create!(row.to_h)
    end
  end

  x.report '3. Model.transaction' do
    Model.transaction do
      CSV.foreach(DATA_FILE, headers: true) do |row|
        Model.create!(row.to_h)
      end
    end
  end

  x.report '4. Model.import' do
    csv     = CSV.foreach(DATA_FILE, headers: true)
    batches = csv.each_slice(5000)

    batches.each do |batch|
      things = batch.map do |row|
        Model.new(row.to_h)
      end

      Model.import(things)
    end
  end

  x.report '5. Model.bulk_insert' do
    csv     = CSV.foreach(DATA_FILE)
    rows    = csv.lazy.drop(1)
    columns = csv.first

    Model.bulk_insert(*columns) do |worker|
      rows.each do |row|
        worker.add(row)
      end
    end
  end

  x.report '6. PG::Connection#copy_data' do
    csv     = CSV.foreach(DATA_FILE)

    table   = Model.table_name
    columns = csv.first.join(', ')
    sql     = "COPY #{table} (#{columns}) FROM STDIN"

    conn    = Model.connection.raw_connection
    encoder = PG::TextEncoder::CopyRow.new
    rows    = csv.lazy.drop(1)

    conn.copy_data sql, encoder do
      rows.each do |row|
        conn.put_copy_data(row)
      end
    end
  end

  x.report '7. PG::Connection#copy_data (CSV)' do
    csv     = File.foreach(DATA_FILE)

    table   = Model.table_name
    columns = CSV.parse_line(csv.first).join(', ')
    sql     = "COPY #{table} (#{columns}) FROM STDIN CSV"

    conn    = Model.connection.raw_connection
    rows    = csv.lazy.drop(1)

    conn.copy_data sql do
      rows.each do |row|
        conn.put_copy_data(row)
      end
    end
  end
end
