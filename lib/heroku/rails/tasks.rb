require 'heroku-rails'

HEROKU_CONFIG_FILE = File.join(HerokuRails::Config.root, 'config', 'heroku.yml')
HEROKU_CONFIG = HerokuRails::Config.new(HEROKU_CONFIG_FILE)
HEROKU_RUNNER = HerokuRails::Runner.new(HEROKU_CONFIG)

# create all the the environment specific tasks
(HEROKU_CONFIG.apps).each do |heroku_env, app_name|
  desc "Select #{heroku_env} Heroku app for later commands"
  task heroku_env do

    # callback switch_environment
    @heroku_app = {:env => heroku_env, :app_name => app_name}
    Rake::Task["heroku:switch_environment"].reenable
    Rake::Task["heroku:switch_environment"].invoke

    HEROKU_RUNNER.add_environment(heroku_env)
  end
end

desc 'Select all Heroku apps for later command'
task :all do
  HEROKU_RUNNER.all_environments
end

namespace :heroku do
  def system_with_echo(*args)
    HEROKU_RUNNER.system_with_echo(*args)
  end

  desc 'Add git remotes for all apps in this project'
  task :remotes => :all do
    HEROKU_RUNNER.each_heroku_app do |heroku_env, app_name, repo|
      system_with_echo("git remote add #{heroku_env} #{repo}")
    end
  end

  desc 'Lists configured apps'
  task :apps => :all do
    puts "\n"
    HEROKU_RUNNER.each_heroku_app do |heroku_env, app_name, repo|
      puts "#{heroku_env} maps to the Heroku app #{app_name} located at:"
      puts "  #{repo}"
      puts
    end
  end

  desc "Get remote server information on the heroku app"
  task :info do
    HEROKU_RUNNER.each_heroku_app do |heroku_env, app_name, repo|
      system_with_echo "heroku info --app #{app_name}"
      puts "\n"
    end
  end

  desc "Deploys, migrates and restarts latest code"
  task :deploy => "heroku:before_deploy" do
    HEROKU_RUNNER.each_heroku_app do |heroku_env, app_name, repo|
      puts "\n\nDeploying to #{app_name}..."
      # set the current heroku_app so that callbacks can read the data
      @heroku_app = {:env => heroku_env, :app_name => app_name, :repo => repo}
      Rake::Task["heroku:before_each_deploy"].reenable
      Rake::Task["heroku:before_each_deploy"].invoke

      branch = `git branch`.scan(/^\* (.*)\n/).flatten.first.to_s
      if branch.present?
        @git_push_arguments ||= []
        system_with_echo "git push #{repo} #{@git_push_arguments.join(' ')} #{branch}:master && heroku rake --app #{app_name} db:migrate && heroku restart --app #{app_name}"
      else
        puts "Unable to determine the current git branch, please checkout the branch you'd like to deploy"
        exit(1)
      end
      Rake::Task["heroku:after_each_deploy"].reenable
      Rake::Task["heroku:after_each_deploy"].invoke
      puts "\n"
    end
    Rake::Task["heroku:after_deploy"].invoke
  end

  # Callback before all deploys
  task :before_deploy do
  end

  # Callback after all deploys
  task :after_deploy do
  end

  # Callback before each deploy
  task :before_each_deploy do
  end

  # Callback after each deploy
  task :after_each_deploy do
  end

  # Callback for when we switch environment
  task :switch_environment do
  end

  desc "Force deploys, migrates and restarts latest code"
  task :force_deploy do
    @git_push_arguments ||= []
    @git_push_arguments << '--force'
    Rake::Task["heroku:deploy"].execute
  end

  desc "Captures a bundle on Heroku"
  task :capture do
    HEROKU_RUNNER.each_heroku_app do |heroku_env, app_name, repo|
      system_with_echo "heroku bundles:capture --app #{app_name}"
    end
  end

  desc "Opens a remote console"
  task :console do
    HEROKU_RUNNER.each_heroku_app do |heroku_env, app_name, repo|
      system_with_echo "heroku console --app #{app_name}"
    end
  end

  desc "Shows the Heroku logs"
  task :logs do
    HEROKU_RUNNER.each_heroku_app do |heroku_env, app_name, repo|
      system_with_echo "heroku logs --app #{app_name}"
    end
  end

  desc "Restarts remote servers"
  task :restart do
    HEROKU_RUNNER.each_heroku_app do |heroku_env, app_name, repo|
      system_with_echo "heroku restart --app #{app_name}"
    end
  end

  namespace :setup do

    desc "Creates the apps on Heroku"
    task :apps do
      HEROKU_RUNNER.setup_apps
    end

    desc "Setup the Heroku stacks from heroku.yml config"
    task :stacks do
      HEROKU_RUNNER.setup_stacks
    end

    desc "Setup the Heroku collaborators from heroku.yml config"
    task :collaborators do
      HEROKU_RUNNER.setup_collaborators
    end

    desc "Setup the Heroku environment config variables from heroku.yml config"
    task :config do
      HEROKU_RUNNER.setup_config
    end

    desc "Setup the Heroku addons from heroku.yml config"
    task :addons do
      HEROKU_RUNNER.setup_addons
    end

    desc "Setup the Heroku domains from heroku.yml config"
    task :domains do
      HEROKU_RUNNER.setup_domains
    end
  end

  desc "Setup Heroku deploy environment from heroku.yml config"
  task :setup => [
    "heroku:setup:apps",
    "heroku:setup:stacks",
    "heroku:setup:collaborators",
    "heroku:setup:config",
    "heroku:setup:addons",
    "heroku:setup:domains",
  ]

  namespace :db do
    desc "Migrates and restarts remote servers"
    task :migrate do
      HEROKU_RUNNER.each_heroku_app do |heroku_env, app_name, repo|
        system_with_echo "heroku rake --app #{app_name} db:migrate && heroku restart --app #{app_name}"
      end
    end

    desc "Pulls the database from heroku and stores it into db/dumps/"
    task :pull do
      HEROKU_RUNNER.each_heroku_app do |heroku_env, app_name, repo|
        system_with_echo "heroku pgdumps:capture --app #{app_name}"
        dump = `heroku pgdumps --app #{app_name}`.split("\n").last.split(" ").first
        system_with_echo "mkdir -p #{HerokuRails::Config.root}/db/dumps"
        file = "#{HerokuRails::Config.root}/db/dumps/#{dump}.sql.gz"
        url = `heroku pgdumps:url --app #{app_name} #{dump}`.chomp
        system_with_echo "wget", url, "-O", file

        # TODO: these are a bit distructive...
        # system_with_echo "rake db:drop db:create"
        # system_with_echo "gunzip -c #{file} | #{HerokuRails::Config.root}/script/dbconsole"
        # system_with_echo "rake jobs:clear"
      end
    end
  end
end