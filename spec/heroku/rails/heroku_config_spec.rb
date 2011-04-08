require 'spec_helper'

module HerokuRails
  describe Config do
    before(:each) do
      @config = Config.new(config_path("heroku-config.yml"))
    end

    it "should read the configuration file" do
      @config.settings.should_not be_empty
    end

    describe "#apps" do
      it "should return the list of apps defined" do
        @config.apps.should have(2).apps
        @config.apps.should include("production" => "awesomeapp")
        @config.apps.should include("staging" => "awesomeapp-staging")
      end
    end

    describe "#app_names" do
      it "should return the list of apps defined" do
        @config.app_names.should have(2).names
        @config.app_names.should include("awesomeapp")
        @config.app_names.should include("awesomeapp-staging")
      end
    end

    describe "#app_environments" do
      it "should return a list of the environments defined" do
        @config.app_environments.should have(2).environments
        @config.app_environments.should include("production")
        @config.app_environments.should include("staging")
      end
    end

    describe "#stack" do
      it "should return the associated stack for an environment" do
        @config.stack("staging").should == "bamboo-ree-1.8.7"
      end

      it "should default to the all setting if not explicitly defined" do
        @config.stack("production").should == "bamboo-mri-1.9.2"
      end
    end

    describe "#config" do
      context "staging environment" do
        before(:each) do
          @config = @config.config("staging")
        end
        it "should include configs defined in 'staging'" do
          @config["STAGING_CONFIG"].should == "special-staging"
        end

        it "should include configs defined in 'all'" do
          @config["BUNDLE_WITHOUT"].should == "test:development"
        end

        it "should use configs defined in 'staging' ahead of configs defined in 'all'" do
          @config["CONFIG_VAR1"].should == "config1-staging"
        end
      end
    end

    describe "#collaborators" do
      context "staging environment" do
        before(:each) do
          @collaborators = @config.collaborators('staging')
        end

        it "should include the collaborators defined in 'all'" do
          @collaborators.should include('all-user1@somedomain.com')
          @collaborators.should include('all-user2@somedomain.com')
          @collaborators.should have(3).collaborators
        end

        it "should include collaborators defined in 'staging'" do
          @collaborators.should include('staging-user@somedomain.com')
        end

        it "should not include collaborators defined in 'production'" do
          @collaborators.should_not include('production-user@somedomain.com')
        end
      end
    end

    describe "#domains" do
      context "staging environment" do
        before(:each) do
          @domains = @config.domains('staging')
        end

        it "should include the domains defined in 'staging'" do
          @domains.should include('staging.awesomeapp.com')
        end

        it "should not include the domains defined in 'production'" do
          @domains.should_not include('awesomeapp.com')
          @domains.should_not include('www.awesomeapp.com')
        end
      end

      context "production environment" do
        it "should include the domains defined in 'production'" do
          @domains = @config.domains('production')
          @domains.should include('awesomeapp.com')
          @domains.should include('www.awesomeapp.com')
        end
      end
    end

    describe "#addons" do
      context "staging environment" do
        before(:each) do
          @addons = @config.addons('staging')
        end

        it "should include addons defined in 'all'" do
          @addons.should include('custom_domains:basic')
          @addons.should include('newrelic:bronze')
        end

        it "should not include addons defined in 'production'" do
          @addons.should_not include('ssl:piggyback')
        end
      end
    end

  end
end