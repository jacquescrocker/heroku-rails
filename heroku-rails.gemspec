Gem::Specification.new do |s|
  s.name = "heroku-rails"
  s.version = "0.0.1"

  s.authors = ["Elijah Miller", "Glenn Roberts", "Jacques Crocker"]
  s.summary = "A bunch of useful Rake tasks for managing your Heroku apps"
  s.description = "Manage multiple Heroku instances/apps for a single Rails app using Rake"

  s.email = "railsjedi@gmail.com"
  s.homepage = "http://github.com/railsjedi/heroku-rails"
  s.rubyforge_project = "none"

  s.require_paths = ["lib"]
  s.files = Dir['lib/**/*',
                'spec/**/*',
                'heroku-rails.gemspec',
                'Gemfile',
                'Gemfile.lock',
                'CHANGELOG',
                'LICENSE',
                'Rakefile',
                'README.md',
                'TODO']

  s.test_files = Dir['spec/**/*']
  s.rdoc_options = ["--charset=UTF-8"]
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md",
    "TODO",
    "CHANGELOG"
  ]

  s.add_runtime_dependency("heroku")
  s.add_development_dependency "rspec", "~> 2.0"
end

