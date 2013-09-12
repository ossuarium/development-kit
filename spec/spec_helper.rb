require 'kit'
require 'database_cleaner'
require 'factory_girl'
require 'factories'

RSpec.configure do |c|

  c.include FactoryGirl::Syntax::Methods

  c.before :suite do
    Kit.new('config.yml').db_create!.db_connect.db_migrate
    Kit.open 'config.yml'
    DatabaseCleaner.strategy = :truncation
  end

  c.after :each do
    DatabaseCleaner.clean
  end

  c.after :suite do
    Kit.open('config.yml').db_destroy!
  end
end
