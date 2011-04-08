module Heroku
  module Rails
    class Railtie < ::Rails::Railtie
      rake_tasks do
        HerokuRails::Config.root = Rails.root
        load 'heroku/rails/tasks.rb'
      end
    end
  end
end
