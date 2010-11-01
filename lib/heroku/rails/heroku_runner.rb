require 'heroku/client'

module Heroku
  module Rails
    class HerokuRunner
      def initialize(config)
        @config = config
        @environments = []
      end

      def authorize
        return if @heroku

        # setup heroku username and password so we can start up a heroku client
        credentials_path = File.expand_path("~/.heroku/credentials")

        # read in the username,password so we can build the client
        if File.exists?(credentials_path)
          auth = File.read(credentials_path)
          username, password = auth.split("\n")
          @heroku = Heroku::Client.new(username, password)
        else
          puts "Heroku not set up. Run `heroku list` in order to input your credentials and try again"
          exit(1)
        end
      end

      # add a specific environment to the run list
      def add_environment(env)
        @environments << env
      end

      # use all environments
      def all_environments
        @environments = @config.app_environments
      end

      # setup apps (create if necessary)
      def setup_apps
        authorize unless @heroku

        # get a list of all my current apps on Heroku (so we don't create dupes)
        @my_apps = @heroku.list.map{|a| a.first}

        each_heroku_app do |heroku_env, app_name, repo|
          next if @my_apps.include?(app_name)

          stack = @config.stack(heroku_env)
          stack_option = " --stack #{stack}" if stack.to_s.size > 0
          system_with_echo "heroku create #{app_name}#{stack_option} --remote #{app_name}"
        end
      end

      # setup the stacks for each app (migrating if necessary)
      def setup_stacks
        authorize unless @heroku
        each_heroku_app do |heroku_env, app_name, repo|
          # get the intended stack setting
          stack = @config.stack(heroku_env)

          # get the remote info about the app from heroku
          heroku_app_info = @heroku.info(app_name) || {}

          # if the stacks don't match, then perform a migration
          if stack != heroku_app_info[:stack]
            puts "Migrating the app: #{app_name} to the stack: #{stack}"
            system_with_echo "heroku stack:migrate #{stack} --app #{app_name}"
          end
        end
      end

      # setup the list of collaborators
      def setup_collaborators
        authorize unless @heroku
        each_heroku_app do |heroku_env, app_name, repo|
          # get the remote info about the app from heroku
          heroku_app_info = @heroku.info(app_name) || {}

          # get the intended list of collaborators to add
          collaborator_emails = @config.collaborators(heroku_env)

          # get existing collaborators
          existing_emails = heroku_app_info[:collaborators].to_a.map{|c| c[:email]}

          # get the list of collaborators to delete
          existing_emails.each do |existing_email|
            # check to see if we need to delete this person
            unless collaborator_emails.include?(existing_email)
              # delete that collaborator if they arent on the approved list
              system_with_echo "heroku sharing:remove #{existing_email} --app #{app_name}"
            end
          end

          # get the list of collaborators to add
          collaborator_emails.each do |collaborator_email|
            # check to see if we need to add this person
            unless existing_emails.include?(collaborator_email)
              # add the collaborator if they are not already on the server
              system_with_echo "heroku sharing:add #{collaborator_email} --app #{app_name}"
            end
          end
        end
      end

      # setup configuration
      def setup_config
        authorize unless @heroku
        each_heroku_app do |heroku_env, app_name, repo|
          # get the configuration that we are aiming towards
          new_config = @config.config(heroku_env)

          # get the existing config from heroku's servers
          existing_config = @heroku.config_vars(app_name) || {}

          # find the config variables to add
          add_config = {}
          new_config.each do |new_key, new_val|
            add_config[new_key] = new_val unless existing_config[new_key] == new_val
          end

          # persist the changes onto heroku
          unless add_config.empty?
            # add the config
            set_config = ""
            add_config.each do |key, val|
              set_config << "#{key}='#{val}' "
            end

            system_with_echo "heroku config:add #{set_config} --app #{app_name}"
          end
        end
      end

      # setup the addons for heroku
      def setup_addons
        authorize unless @heroku
        each_heroku_app do |heroku_env, app_name, repo|
          # get the addons that we are aiming towards
          addons = @config.addons(heroku_env)

          # add "custom_domains" if that addon doesnt already exist
          # and we have domains configured for this app
          unless @config.domains(heroku_env).empty? or addons.include?("custom_domains")
            addons << "custom_domains"
          end

          # get the addons that are already on the servers
          existing_addons = (@heroku.installed_addons(app_name) || []).map{|a| a["name"]}

          # remove the addons that need to be removed
          existing_addons.each do |existing_addon|
            # check to see if we need to delete this addon
            unless addons.include?(existing_addon)
              # delete this addon if they arent on the approved list
              system_with_echo "heroku addons:remove #{existing_addon} --app #{app_name}"
            end
          end

          # add the addons that dont exist already
          addons.each do |addon|
            # check to see if we need to add this addon
            unless existing_addons.include?(addon)
              # add this addon if they are not already added
              system_with_echo "heroku addons:add #{addon} --app #{app_name}"
            end
          end
        end
      end

      # setup the domains for heroku
      def setup_domains
        authorize unless @heroku
        each_heroku_app do |heroku_env, app_name, repo|
          # get the domains that we are aiming towards
          domains = @config.domains(heroku_env)

          # get the domains that are already on the servers
          existing_domains = (@heroku.list_domains(app_name) || []).map{|a| a[:domain]}

          # remove the domains that need to be removed
          existing_domains.each do |existing_domain|
            # check to see if we need to delete this domain
            unless domains.include?(existing_domain)
              # delete this domain if they arent on the approved list
              system_with_echo "heroku domains:remove #{existing_domain} --app #{app_name}"
            end
          end

          # add the domains that dont exist already
          domains.each do |domain|
            # check to see if we need to add this domain
            unless existing_domains.include?(domain)
              # add this domain if they are not already added
              system_with_echo "heroku domains:add #{domain} --app #{app_name}"
            end
          end
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