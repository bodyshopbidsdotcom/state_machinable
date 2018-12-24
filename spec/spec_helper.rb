require "bundler/setup"
require "state_machinable"
require "pry"
require "active_record"
require "statesman"

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

load File.dirname(__FILE__) + "/schema.rb"

SPEC_ROOT = Pathname.new(File.expand_path('../', __FILE__))

Dir[SPEC_ROOT.join('support/models/*.rb')].each{|f| require f }
Dir[SPEC_ROOT.join('support/state_machines/*.rb')].each{|f| require f }

# Clients have to do this. Maybe it should be wrapped by state_machinable
Statesman.configure do
  storage_adapter(::Statesman::Adapters::ActiveRecord)
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
