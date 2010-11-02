module Heroku
  module Generators
    class ConfigGenerator < ::Rails::Generators::Base
      desc "Generates a Heroku Config file at config/heroku.yml"

      def self.source_root
        @_heroku_gen_source_root ||= File.expand_path("../../templates", __FILE__)
      end

      def create_config_file
        template 'heroku.yml', File.join('config', "heroku.yml")
      end

      def create_rake_file
        template 'heroku.rake', File.join('lib', 'tasks', "heroku.rake")
      end
    end
  end
end