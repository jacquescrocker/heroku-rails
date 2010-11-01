require 'spec_helper'

describe Heroku::Rails::Config do
  it "should exist" do
    defined?(Heroku::Rails::Config).should be_true
  end
end
