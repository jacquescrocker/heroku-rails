require 'heroku-rails'
require 'bundler/setup'


RSpec.configure do |c|
  # setup fixtures path
  c.before(:all) do
    @fixture_path = Pathname.new(File.join(File.dirname(__FILE__), "/fixtures"))
    raise "Fixture folder not found: #{@fixture_path}" unless @fixture_path.directory?
  end

  # returns the file path of a fixture setting file
  def config_path(filename)
    @fixture_path.join(filename)
  end

end

