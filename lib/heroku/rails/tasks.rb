HEROKU_CONFIG_FILE = Rails.root.join('config', 'heroku.yml')
HEROKU_CONFIG = Heroku::Rails::HerokuConfig.new(HEROKU_CONFIG_FILE)

(HEROKU_CONFIG.apps).each do |heroku_env, heroku_app_name|
  desc "Select #{heroku_env} Heroku app for later commands"
  task heroku_env do
    @heroku_environments ||= []
    @heroku_environments << heroku_env
  end
end

desc 'Select all Heroku apps for later command'
task :all do
  @heroku_environments = HEROKU_CONFIG.app_environments
end

namespace :heroku do
  desc "Creates the Heroku app"
  task :create do
    each_heroku_app do |heroku_env, heroku_app_name, repo|

      # TODO: use the right stack
      system_with_echo "heroku create #{heroku_app_name}"
    end
  end

  desc 'Add git remotes for all apps in this project'
  task :remotes do
    each_heroku_app do |heroku_env, heroku_app_name, repo|
      system("git remote add #{heroku_app_name} #{repo}")
    end
  end

  desc 'Adds a collaborator'
  task :share do
    print "Email address of collaborator to add: "
    $stdout.flush
    email = $stdin.gets
    each_heroku_app do |heroku_env, heroku_app_name, repo|
      system_with_echo "heroku sharing:add --app #{heroku_app_name} #{email}"
    end
  end

  desc 'Adds a collaborator'
  task :unshare do
    print "Email address of collaborator to remove: "
    $stdout.flush
    email = $stdin.gets
    each_heroku_app do |heroku_env, heroku_app_name, repo|
      system_with_echo "heroku sharing:remove --app #{heroku_app_name} #{email}"
    end
  end

  desc 'Lists configured apps'
  task :apps => :all do
    each_heroku_app do |heroku_env, heroku_app_name, repo|
      puts "#{heroku_env} maps to the Heroku app #{heroku_app_name} located at:"
      puts "  #{repo}"
      puts
    end
  end

  desc 'Creates an example configuration file'
  task :create_config do
    example = File.join(File.dirname(__FILE__), '..', 'templates', 'heroku.example.yml')
    if File.exists?(HEROKU_CONFIG_FILE)
      puts "config/heroku.yml already exists"
    else
      puts "Copied example config to config/heroku.yml"
      FileUtils.cp(example, HEROKU_CONFIG_FILE)
      system_with_echo("#{ENV['EDITOR']} #{HEROKU_CONFIG_FILE}")
    end
  end

  desc "Deploys, migrates and restarts latest code"
  task :deploy => "heroku:before_deploy" do
    each_heroku_app do |heroku_env, heroku_app_name, repo|

      # set the current heroku_app so that callbacks can read the data
      @heroku_app = {:env => heroku_env, :app_name => heroku_app_name, :repo => repo}
      Rake::Task["heroku:before_each_deploy"].invoke

      branch = `git branch`.scan(/^\* (.*)\n/).flatten.first.to_s
      if branch.present?
        @git_push_arguments ||= []
        system_with_echo "git push #{repo} #{@git_push_arguments.join(' ')} #{branch}:master && heroku rake --app #{heroku_app_name} db:migrate && heroku restart --app #{heroku_app_name}"
      else
        puts "Unable to determine the current git branch, please checkout the branch you'd like to deploy"
        exit(1)
      end
      Rake::Task["heroku:after_each_deploy"].invoke
    end
    Rake::Task["heroku:after_deploy"].execute
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

  desc "Force deploys, migrates and restarts latest code"
  task :force_deploy do
    @git_push_arguments ||= []
    @git_push_arguments << '--force'
    Rake::Task["heroku:deploy"].execute
  end

  desc "Captures a bundle on Heroku"
  task :capture do
    each_heroku_app do |heroku_env, heroku_app_name, repo|
      system_with_echo "heroku bundles:capture --app #{heroku_app_name}"
    end
  end

  desc "Opens a remote console"
  task :console do
    each_heroku_app do |heroku_env, heroku_app_name, repo|
      system_with_echo "heroku console --app #{heroku_app_name}"
    end
  end

  desc "Restarts remote servers"
  task :restart do
    each_heroku_app do |heroku_env, heroku_app_name, repo|
      system_with_echo "heroku restart --app #{heroku_app_name}"
    end
  end

  desc "Migrates and restarts remote servers"
  task :migrate do
    each_heroku_app do |heroku_env, heroku_app_name, repo|
      system_with_echo "heroku rake --app #{heroku_app_name} db:migrate && heroku restart --app #{heroku_app_name}"
    end
  end
end

namespace :db do
  task :pull do
    each_heroku_app do |heroku_env, heroku_app_name, repo|
      system_with_echo "heroku pgdumps:capture --app #{heroku_app_name}"
      dump = `heroku pgdumps --app #{heroku_app_name}`.split("\n").last.split(" ").first
      system_with_echo "mkdir -p #{Rails.root}/db/dumps"
      file = "#{Rails.root}/db/dumps/#{dump}.sql.gz"
      url = `heroku pgdumps:url --app #{heroku_app_name} #{dump}`.chomp
      system_with_echo "wget", url, "-O", file
      system_with_echo "rake db:drop db:create"
      system_with_echo "gunzip -c #{file} | #{Rails.root}/script/dbconsole"
      system_with_echo "rake jobs:clear"
    end
  end
end

def system_with_echo(*args)
  puts args.join(' ')
  system(*args)
end

def each_heroku_app
  if @heroku_environments.blank? && HEROKU_CONFIG.apps.size == 1
    heroku_env = HEROKU_CONFIG.app_environments.first
    puts "Defaulting to #{env} app since only one app is defined"
    @heroku_environments = [heroku_env]
  end

  if @heroku_environments.present?
    @heroku_environments.each do |heroku_env|
      app_name = HEROKU_CONFIG.apps[heroku_env]
      yield(heroku_env, app_name, "git@heroku.com:#{app_name}.git")
    end
    puts
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
