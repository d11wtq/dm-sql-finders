require "dm-migrations"
require "dm-aggregates"
require "dm-sql-finders"

DataMapper.setup(:default, "sqlite::memory:")

Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each { |file| require file }

RSpec.configure do |config|
  config.mock_with :rspec

  config.before(:suite) do
    DataMapper.finalize
  end

  config.before(:each) do
    DataMapper.auto_migrate!
  end

  config.after(:each) do
  end
end
