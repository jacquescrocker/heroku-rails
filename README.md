Heroku Rails
=============

Easier configuration and deployment of Rails apps on Heroku

Configure your Heroku environment via a YML file (config/heroku.yml) that defines all your environments, addons, and environment variables.

Heroku Rails also handles asset packaging (via jammit), deployment of assets to s3 (via jammit-s3).

## Install

### Rails 3

Add this to your Gemfile:

    group :development do
      gem 'heroku-rails'
    end

### Rails 2

To install add the following to config/environment.rb:

    config.gem 'heroku-rails'

Rake tasks are not automatically loaded from gems, so you’ll need to add the following to your Rakefile:

    begin
      require 'heroku/rails/tasks'
    rescue LoadError
      STDERR.puts "Run `rake gems:install` to install heroku-rails"
    end

## Configure

In config/heroku.yml you will need add the Heroku apps that you would like to attach to this project. You can generate this file and edit it by running:

    rails generate heroku:config

Then edit config/heroku.yml with your project's heroku configurations. To persist the changes onto Heroku, just run:

    rake all heroku:setup

This will create the heroku apps you have defined, and create the settings for each.

## Usage

After configuring your Heroku apps you can use rake tasks to control the
apps.

    rake production heroku:deploy

A rake task with the shorthand name of each app is now available and adds that
server to the list that subsequent commands will execute on. Because this list
is additive, you can easily select which servers to run a command on.

    rake demo staging heroku:restart

A special rake task 'all' is created that causes any further commands to
execute on all heroku apps.

Need to add remotes for each app?

    rake all heroku:remotes

A full list of tasks provided:

    rake all                        # Select all Heroku apps for later command
    rake heroku:deploy              # Deploys, migrates and restarts latest code.
    rake heroku:apps                # Lists configured apps
    rake heroku:info                # Queries the heroku status info on each app
    rake heroku:console             # Opens a remote console
    rake heroku:capture             # Captures a bundle on Heroku
    rake heroku:remotes             # Add git remotes for all apps in this project
    rake heroku:migrate             # Migrates and restarts remote servers
    rake heroku:restart             # Restarts remote servers

    rake heroku:setup               # runs all heroku setup scripts
    rake heroku:setup:addons        # sets up the heroku addons
    rake heroku:setup:collaborators # sets up the heroku collaborators
    rake heroku:setup:config        # sets up the heroku config env variables
    rake heroku:setup:domains       # sets up the heroku domains
    rake heroku:setup:stacks        # sets the correct stack for each heroku app

    rake heroku:db:setup            # Migrates and restarts remote servers

You can easily alias frequently used tasks within your application's Rakefile:

    task :deploy =>  ["heroku:deploy"]
    task :console => ["heroku:console"]
    task :capture => ["heroku:capture"]

With this in place, you can be a bit more terse:

    rake staging console
    rake all deploy

### Deploy Hooks

You can easily hook into the deploy process by defining any of the following rake tasks:

You can generate these automatically within lib/tasks/heroku.rake by running:

    rails generate heroku:callbacks


Then edit the rake tasks to provide custom logic for each of these steps

    namespace :heroku do

      # runs before all the deploys complete
      task :before_deploy do

      end

      # runs before each push to a particular heroku deploy environment
      task :before_each_deploy do

      end

      # runs after each push to a particular heroku deploy environment
      task :after_each_deploy do

      end

      # runs after all the deploys complete
      task :after_deploy do

      end

    end




## About Heroku Rails

### Links

Homepage:: <http://github.com/railsjedi/heroku-rails>

Issue Tracker:: <http://github.com/railsjedi/heroku-rails/issues>

### License

License:: Copyright (c) 2010 Jacques Crocker <railsjedi@gmail.com> released under the MIT license.

## Forked from Heroku Sans

Heroku Rails is a fork and rewrite/reorganiziation of Heroku Sans, and a nice simple set of Rake tasks for managing Heroku environments. Check out that project here: <http://github.com/fastestforward/heroku_san>

### Heroku Sans Contributors

* Elijah Miller (elijah.miller@gmail.com)
* Glenn Roberts (glenn.roberts@siyelo.com)
* Damien Mathieu (42@dmathieu.com)

### Heroku Sans License

License:: Copyright (c) 2009 Elijah Miller <elijah.miller@gmail.com>, released under the MIT license.
