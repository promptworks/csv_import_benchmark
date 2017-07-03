DATA_FILE  = 'data.csv'
COUNT      = 100_000
BATCH_SIZE = 5000
COLUMNS    = %w(one two three four five)
VALUES     = %w(one two three four five)

require_relative 'setup'

class Model < ActiveRecord::Base
end

Benchmark.bm do |x|
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
    batches = csv.each_slice(BATCH_SIZE)

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

  x.report '7. Parallel.each -> Model.bulk_insert' do
    csv     = CSV.foreach(DATA_FILE)
    batches = csv.lazy.drop(1).each_slice(BATCH_SIZE)
    columns = csv.first

    Parallel.each batches do |batch|
      Model.bulk_insert(*columns) do |worker|
        batch.each do |row|
          worker.add(row)
        end
      end
    end
  end

  x.report '8. Parallel.each -> PG::Connection#copy_data' do
    csv     = CSV.foreach(DATA_FILE)
    table   = Model.table_name
    columns = csv.first.join(', ')
    sql     = "COPY #{table} (#{columns}) FROM STDIN"
    batches = csv.lazy.drop(1).each_slice(BATCH_SIZE)

    Parallel.each batches do |batch|
      conn    = Model.connection.raw_connection
      encoder = PG::TextEncoder::CopyRow.new

      conn.copy_data sql, encoder do
        batch.each do |row|
          conn.put_copy_data(row)
        end
      end
    end
  end

  x.report '9. Parallel.each -> PG::Connection#copy_data (CSV)' do
    csv     = File.foreach(DATA_FILE)
    table   = Model.table_name
    columns = CSV.parse_line(csv.first).join(', ')
    sql     = "COPY #{table} (#{columns}) FROM STDIN CSV"
    batches = csv.lazy.drop(1).each_slice(BATCH_SIZE)

    Parallel.each batches do |batch|
      conn = Model.connection.raw_connection

      conn.copy_data sql do
        batch.each do |row|
          conn.put_copy_data(row)
        end
      end
    end
  end
end
