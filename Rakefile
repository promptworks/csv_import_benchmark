require 'csv'
require 'benchmark'
require 'active_support/all'
require 'active_record'
require 'parallel'
require 'activerecord-import'

module Utils
  extend self

  def file
    File.expand_path('../data.csv', __FILE__)
  end

  def run(name)
    Benchmark.measure do
      require_relative File.join('attempts', "#{name}.rb")
    end
  end
end

module DB
  extend self

  SPEC = { adapter: 'postgresql' }

  def setup(name)
    connect('postgres')
    create(name)
    connect(name)
    migrate
  end

  def connect(name)
    ActiveRecord::Base.establish_connection(SPEC.merge(database: name))
  end

  def create(name)
    ActiveRecord::Base.connection.create_database(name)
  rescue => err
    raise unless err.message =~ /exists/
    ActiveRecord::Base.connection.drop_database(name)
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

class Thing < ActiveRecord::Base
end

desc 'Generate data'
task :generate, [:count, :file] do |_, args|
  require 'csv'
  require 'securerandom'

  CSV.open(ENV.fetch('FILE', 'data.csv'), 'wb') do |csv|
    csv << %w(id one two three four five)

    ENV.fetch('COUNT', 100_000).to_i.times do |id|
      cols = Array.new(5).map do
        SecureRandom.hex(rand(5..20))
      end

      csv << [id, *cols]
    end
  end
end

desc 'Run attempts'
task :run do
  filter   = Regexp.new ENV.fetch('ATTEMPTS', '.*')
  basename = ->(file) { File.basename(file, '.*') }
  attempts = Dir.glob('attempts/*.rb').map(&basename).grep(filter)

  puts '==>> Setting up...'
  attempts.each { |name| DB.setup(name) }

  puts "\n==>> Benchmarking..."
  Benchmark.bm(attempts.max.length + 1) do |x|
    attempts.each do |name|
      x.report "#{name}:" do
        DB.connect(name)
        Utils.run(name)
      end
    end
  end
end

task default: :run
