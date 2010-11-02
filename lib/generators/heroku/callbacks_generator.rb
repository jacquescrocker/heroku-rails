module Heroku
  module Generators
    class CallbacksGenerator < ::Rails::Generators::Base
      desc "Generates the rake tasks (lib/tasks/heroku.rake) that let you override heroku deploy callbacks"

      def self.source_root
        @_heroku_gen_source_root ||= File.expand_path("../../templates", __FILE__)
      end

      def create_callbacks_rake_file
        template 'heroku.rake', File.join('lib', 'tasks', "heroku.rake")
      end
    end
  end
end