require 'csv'
require 'benchmark'
require 'active_support/all'
require 'active_record'
require 'parallel'
require 'activerecord-import'
require 'bulk_insert'

DATA_FILE  = 'data.csv'
COLUMNS    = %w(one two three four five)
VALUES     = %w(one two three four five)
COUNT      = 100_000
BATCH_SIZE = 5000

require_relative 'setup'

class Model < ActiveRecord::Base
end

Benchmark.bm do |x|
  x.extend ReportFiltering
  x.extend ReportWithPadding
  x.extend DatabaseSetup

  x.report '1 - CSV.read' do
    CSV.read(DATA_FILE, headers: true) do |row|
      Model.create!(row.to_h)
    end
  end

  x.report '2 - CSV.foreach' do
    CSV.foreach(DATA_FILE, headers: true) do |row|
      Model.create!(row.to_h)
    end
  end

  x.report '3 - Model.transaction' do
    Model.transaction do
      CSV.foreach(DATA_FILE, headers: true) do |row|
        Model.create!(row.to_h)
      end
    end
  end

  x.report '4 - Model.bulk_insert' do
    csv  = CSV.foreach(DATA_FILE)
    table = Model.table_name

    Model.bulk_insert(*csv.first) do |worker|
      csv.lazy.drop(1).each do |row|
        worker.add(row)
      end
    end
  end

  x.report '5 - Model.import' do
    CSV.foreach(DATA_FILE, headers: true).each_slice(BATCH_SIZE) do |chunk|
      things = chunk.map do |row|
        Model.new(row.to_h)
      end

      Model.import(things)
    end
  end

  x.report '6 - Parallel.each -> Model.import' do
    csv = CSV.foreach(DATA_FILE, headers: true)

    Parallel.each csv.each_slice(BATCH_SIZE) do |chunk|
      things = chunk.map do |row|
        Model.new(row.to_h)
      end

      Model.import(things)
    end
  end

  x.report '7 - Parallel.each -> PG::Connection#copy_data' do
    csv    = CSV.foreach(DATA_FILE)
    table   = Model.table_name
    columns = csv.first.join(', ')
    sql     = "COPY #{table} (#{columns}) FROM STDIN"

    Parallel.each csv.lazy.drop(1).each_slice(BATCH_SIZE) do |chunk|
      conn    = Model.connection.raw_connection
      encoder = PG::TextEncoder::CopyRow.new

      conn.copy_data sql, encoder do
        chunk.each do |row|
          conn.put_copy_data(row)
        end
      end
    end
  end

  x.report '8 - Parallel.each -> PG::Connection#copy_data (CSV)' do
    csv     = File.foreach(DATA_FILE)
    table   = Model.table_name
    columns = CSV.parse_line(csv.first).join(', ')
    sql     = "COPY #{table} (#{columns}) FROM STDIN CSV"

    Parallel.each csv.lazy.drop(1).each_slice(BATCH_SIZE) do |chunk|
      conn = Model.connection.raw_connection

      conn.copy_data sql do
        chunk.each do |row|
          conn.put_copy_data(row)
        end
      end
    end
  end
end
