require 'erb'

module HerokuRails
  class Config

    class << self
      def root
        @heroku_rails_root || ENV["RAILS_ROOT"] || "."
      end
      def root=(root)
        @heroku_rails_root = root
      end
    end

    attr_accessor :settings

    def initialize(config_filepath)
      if File.exists?(config_filepath)
        self.settings = YAML.load(ERB.new(File.read(config_filepath)).result) || {}
      else
        self.settings = {}
      end
    end

    def apps
      self.settings['apps'] || {}
    end

    def app_names
      apps.values
    end

    def app_environments
      apps.keys
    end

    # return the stack setting for a particular app environment
    def stack(app_env)
      stacks = self.settings['stacks'] || {}
      stacks[app_env] || stacks['all']
    end

    def rake_cmd(app_env)
      if self.stack(app_env) =~ /cedar/i
        'heroku run rake'
      else
        'heroku rake'
      end
    end

    # pull out the config setting hash for a particular app environment
    def config(app_env)
      config = self.settings['config'] || {}
      all = config['all'] || {}

      # overwrite all configs with the environment specific ones
      all.merge(config[app_env] || {})
    end

    # return a list of domains for a particular app environment
    def domains(app_env)
      domains = self.settings['domains'] || {}
      domains[app_env] || []
    end

    # return a list of collaborators for a particular app environment
    def collaborators(app_env)
      app_setting_list('collaborators', app_env)
    end

    # return a list of addons for a particular app environment
    def addons(app_env)
      app_setting_list('addons', app_env)
    end

    protected

    def app_setting_list(setting_key, app)
      setting = self.settings[setting_key] || {}
      all = setting['all'] || []

      # add in collaborators from app environment to the ones defined in all
      (all + (setting[app] || [])).uniq
    end
  end
end
