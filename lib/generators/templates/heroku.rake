# ### Shortcuts: uncomment these for easier to type deployments
# ### e.g. rake deploy (instead of rake heroku:deploy)
# ###
# task :deploy =>  ["heroku:deploy"]
# task :console => ["heroku:console"]
# task :setup =>   ["heroku:setup"]
# task :logs =>    ["heroku:logs"]
# task :restart => ["heroku:restart"]

# Heroku Deploy Callbacks
namespace :heroku do

  # runs before all the deploys complete
  task :before_deploy do

  end

  # runs before each push to a particular heroku deploy environment
  task :before_each_deploy, [:app_name] do |t,args|

  end

  # runs after each push to a particular heroku deploy environment
  task :after_each_deploy, [:app_name] do |t,args|

  end

  # runs after all the deploys complete
  task :after_deploy do

  end

end
