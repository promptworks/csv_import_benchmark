module Utils
  extend self

  def file
    File.expand_path('../data.csv', __FILE__)
  end
end

class DB
  def self.setup(name)
    new(name).setup
  end

  def initialize(name)
    @spec = { adapter: 'postgresql', database: name }
  end

  def setup
    connect database: 'postgres'
    create
    connect
    migrate
  end

  def connect(opts = {})
    ActiveRecord::Base.establish_connection(@spec.merge(opts))
  end

  def create
    ActiveRecord::Base.connection.create_database(@spec[:database])
  rescue => err
    raise unless err.message =~ /exists/
    ActiveRecord::Base.connection.drop_database(@spec[:database])
    retry
  end

  def migrate
    ActiveRecord::Schema.define do
      create_table :things do |t|
        t.string :one
        t.string :two
        t.string :three
        t.string :four
        t.string :five
      end
    end
  end
end

desc 'Generate data'
task :generate, [:count, :file] do |_, args|
  require 'csv'
  require 'securerandom'

  args.with_defaults(
    count: 100_000,
    file: 'data.csv'
  )

  CSV.open(args[:file], 'wb') do |csv|
    csv << ['id', 'one', 'two', 'three', 'four', 'five']

    args[:count].times do |id|
      # Generate 5 random values
      cols = Array.new(5).map do
        SecureRandom.hex(rand(5..20))
      end

      csv << [id, *cols]
    end
  end
end

Dir.glob('attempts/*.rb').each do |file|
  name = File.basename(file, '.*')

  desc "Run '#{file}'"
  task name do
    require 'benchmark'
    require 'active_record'

    puts '==>> Setting up the database'
    DB.setup(name)

    puts "==>> Starting the attempt..."

    bm = Benchmark.measure do
      require_relative File.join('attempts', "#{name}.rb")
    end

    puts "==>> Okay, the results are in:"
    puts bm
  end
end
