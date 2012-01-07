require 'heroku/client'

module HerokuRails
  class Runner
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
        creation_command "heroku create #{app_name}#{stack_option} --remote #{app_name}"
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
          creation_command "heroku stack:migrate #{stack} --app #{app_name}"
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

        # add current user to collaborator list (always)
        collaborator_emails << @heroku.user unless collaborator_emails.include?(@heroku.user)
        collaborator_emails << heroku_app_info[:owner] unless collaborator_emails.include?(heroku_app_info[:owner])

        # get existing collaborators
        existing_emails = heroku_app_info[:collaborators].to_a.map{|c| c[:email]}

        # get the list of collaborators to delete
        existing_emails.each do |existing_email|
          # check to see if we need to delete this person
          unless collaborator_emails.include?(existing_email)
            # delete that collaborator if they arent on the approved list
            destroy_command "heroku sharing:remove #{existing_email} --app #{app_name}"
          end
        end

        # get the list of collaborators to add
        collaborator_emails.each do |collaborator_email|
          # check to see if we need to add this person
          unless existing_emails.include?(collaborator_email)
            # add the collaborator if they are not already on the server
            creation_command "heroku sharing:add #{collaborator_email} --app #{app_name}"
          end
        end

        # display the destructive commands
        output_destroy_commands(app_name)
      end
    end

    # setup configuration
    def setup_config
      authorize unless @heroku
      each_heroku_app do |heroku_env, app_name, repo|
        # get the configuration that we are aiming towards
        new_config = @config.config(heroku_env)

        # default RACK_ENV to the heroku_env (unless its manually set to something else)
        unless new_config["RACK_ENV"].to_s.length > 0
          new_config["RACK_ENV"] = heroku_env
        end

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

          creation_command "heroku config:add #{set_config} --app #{app_name}"
        end
      end
    end

    # setup the addons for heroku
    def setup_addons
      authorize unless @heroku
      each_heroku_app do |heroku_env, app_name, repo|
        # get the addons that we are aiming towards
        addons = @config.addons(heroku_env)

        # get the addons that are already on the servers
        existing_addons = (@heroku.installed_addons(app_name) || []).map{|a| a["name"]}

        # all apps need the shared database
        addons << "shared-database:5mb" unless addons.index("shared-database:5mb") || addons.index("shared-database:20gb")

        # add "custom_domains" if that addon doesnt already exist
        # and we have domains configured for this app
        addons << "custom_domains:basic" unless @config.domains(heroku_env).empty? or
                                                addons.any?{|a| a =~ /custom_domains/} or
                                                existing_addons.any?{|a| a =~ /custom_domains/}

        # remove the addons that need to be removed
        existing_addons.each do |existing_addon|
          # check to see if we need to delete this addon
          unless addons.include?(existing_addon)
            # delete this addon if they arent on the approved list
            destroy_command "heroku addons:remove #{existing_addon} --app #{app_name}"
          end
        end

        # add the addons that dont exist already
        addons.each do |addon|
          # check to see if we need to add this addon
          unless existing_addons.include?(addon)
            # add this addon if they are not already added
            creation_command "heroku addons:add #{addon} --app #{app_name}"
          end
        end

        # display the destructive commands
        output_destroy_commands(app_name)
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
            destroy_command "heroku domains:remove #{existing_domain} --app #{app_name}"
          end
        end

        # add the domains that dont exist already
        domains.each do |domain|
          # check to see if we need to add this domain
          unless existing_domains.include?(domain)
            # add this domain if they are not already added
            creation_command "heroku domains:add #{domain} --app #{app_name}"
          end
        end

        # display the destructive commands
        output_destroy_commands(app_name)
      end
    end

    # cycles through each configured heroku app
    # yields the environment name, the app name, and the repo url
    def each_heroku_app

      if @config.apps.size == 0
        puts "\nNo heroku apps are configured. Run:
          rails generate heroku:config\n\n"
        puts "this will generate a default config/heroku.yml that you should edit"
        puts "and then try running this command again"

        exit(1)
      end

      if @environments.blank? && @config.apps.size == 1
        @environments = [@config.app_environments.first]
      end

      if @environments.present?
        @environments.each do |heroku_env|
          app_name = @config.apps[heroku_env]
          yield(heroku_env, app_name, "git@heroku.com:#{app_name}.git")
        end
      else
        puts "\nYou must first specify at least one Heroku app:
          rake <app> [<app>] <command>
          rake production restart
          rake demo staging deploy"

        puts "\n\nYou can use also command all Heroku apps for this project:
          rake all heroku:setup\n"

        exit(1)
      end
    end

    def system_with_echo(*args)
      puts args.join(' ')
      command(*args)
    end

    def creation_command(*args)
      system_with_echo(*args)
    end

    def destroy_command(*args)
      # puts args.join(' ')
      @destroy_commands ||= []
      @destroy_commands << args.join(' ')
    end

    def output_destroy_commands(app)
      puts "The #{app} had a few things removed from the heroku.yml."
      puts "If they are no longer neccessary, then run the following commands:\n\n"
      (@destroy_commands || []).each do |destroy_command|
        puts destroy_command
      end
      puts "\n\nthese commands may cause data loss so make sure you know that these are necessary"
      # clear destroy commands
      @destroy_commands = []
    end

    def command(*args)
      system(*args)
    end

  end
end