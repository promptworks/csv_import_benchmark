require 'csv'
require 'benchmark'
require 'active_support/all'
require 'active_record'
require 'parallel'
require 'activerecord-import'
require 'bulk_insert'

ActiveRecord::Migration.verbose = false

CONNECT = lambda do
  ActiveRecord::Base.establish_connection(
    database: 'csv_import',
    adapter: 'postgresql'
  )
end.tap(&:call)

# Generate a CSV file
CSV.open(DATA_FILE, 'wb') do |csv|
  csv << COLUMNS
  COUNT.times { csv << VALUES }
end

module ReportFiltering
  def report(msg, *args)
    only, except = ENV.values_at('ONLY', 'EXCEPT')

    return if except && msg =~ /#{except}/i
    return if only && msg !~ /#{only}/i
    super(msg, *args)
  end
end

# Create schema, drop if exists
module DatabaseSetup
  def report(*)
    ActiveRecord::Schema.define do
      create_table :models, force: true do |t|
        COLUMNS.each do |column|
          t.string(column)
        end
      end
    end

    CONNECT.call
    super
  end
end

module ReportWithPadding
  def report(msg, *args)
    super(msg.ljust(50), *args)
  end
end
