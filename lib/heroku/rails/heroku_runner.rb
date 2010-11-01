require 'heroku/client'

module Heroku
  module Rails
    class HerokuRunner
      def initialize(config)
        @config = config
        @environments = []

        # setup heroku username and password so we can start up a heroku client
        credentials_path = File.expand_path("~/.heroku/credentials")

        if File.exists?(credentials_path)
          auth = File.read(credentials_path)
          username, password = auth.split("\n")
          @heroku = Heroku::Client.new(username, password)
        else
          puts "Heroku not set up. Run `heroku list` in order to input your credentials and try again"
          exit(1)
        end

        # get a list of all my current apps on Heroku
        @my_apps = @heroku.list.map{|a| a.first}
      end

      # add a specific environment to the run list
      def add_environment(env)
        @environments << env
      end

      # use all environments
      def all_environments
        @environments = @config.app_environments
      end

      # create apps
      def create_apps
        each_heroku_app do |heroku_env, heroku_app_name, repo|
          next if @my_apps.include?(heroku_app_name)

          stack = @config.stack(heroku_env)
          stack_option = " --stack #{stack}" if stack.to_s.size > 0
          system_with_echo "heroku create #{heroku_app_name}#{stack_option} --remote #{heroku_app_name}"
        end
      end

      # cycles through each configured heroku app
      # yields the environment name, the app name, and the repo url
      def each_heroku_app
        if @environments.blank? && @config.apps.size == 1
          puts "Defaulting to #{env} app since only one app is defined"
          @environments = [@config.app_environments.first]
        end

        if @environments.present?
          @environments.each do |heroku_env|
            app_name = @config.apps[heroku_env]
            yield(heroku_env, app_name, "git@heroku.com:#{app_name}.git")
          end
        else
          puts "You must first specify at least one Heroku app:
            rake <app> [<app>] <command>
            rake production restart
            rake demo staging deploy"

          puts "\nYou can use also command all Heroku apps for this project:
            rake all heroku:share"

          exit(1)
        end
      end

      def system_with_echo(*args)
        puts args.join(' ')
        command(*args)
      end

      def command(*args)
        system(*args)
      end

    end
  end
end