module HerokuSan
  class Config

    attr_accessor :settings

    def initialize(config_filepath)
      if File.exists?(config_filepath)
        self.settings = YAML.load_file(HEROKU_CONFIG_FILE)
      else
        self.settings = {}
      end
    end

    # pull out the stack setting for a particular app environment
    def stack(app = 'all')
      # TODO
    end

    # pull out the config setting hash for a particular app environment
    def config(app = 'all')
      # TODO
    end

    # return a list of collaborators for a particular app environment
    def collaborators(app = 'all')
      # TODO
    end

    # return a list of domains for a particular app environment
    def domains(app = 'all')
      # TODO
    end

    # return a list of addons for a particular app environment
    def addons(app = 'addons')
      # TODO
    end

  end
end