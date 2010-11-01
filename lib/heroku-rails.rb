module Heroku
  module Rails
    class Railtie < ::Rails::Railtie
      rake_tasks do
        load 'heroku/rails/tasks.rb'
      end
    end
  end
end
