# frozen_string_literal: true

require_relative "lib/donico/version"

Gem::Specification.new do |s|
  s.name        = "donico"
  s.version     = Donico::VERSION::STRING
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Nicolas Rodriguez"]
  s.email       = ["nicolas.rodriguez.externe@seetickets.fr"]
  s.homepage    = "https://gitlab.digitick.net/infra/donico"
  s.summary     = "A gem to easily build Docker Images"
  s.description = "A gem to easily build Docker Images (like Kaniko)"
  s.license     = "MIT"

  s.required_ruby_version = ">= 3.0.0"

  s.files = ["donico.gemspec", "README.md"] + %x(git ls-files | grep -E '^(bash|lib|exe)').split("\n")

  s.bindir      = "exe"
  s.executables = ["inspec"]

  s.add_runtime_dependency "bundler",  ">= 2.3"
  s.add_runtime_dependency "dotenv",   "2.8.1"
  s.add_runtime_dependency "rake",     "13.0.6"
  s.add_runtime_dependency "zeitwerk", "2.6.7"

  # We don't want development dependencies in our final gem file
  unless ENV.fetch("DONICO_RELEASE", nil) == "true"
    s.add_development_dependency "guard-rspec"
    s.add_development_dependency "rspec"
    s.add_development_dependency "rubocop"
    s.add_development_dependency "simplecov"
  end
end
