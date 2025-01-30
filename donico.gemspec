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

  s.add_dependency "bundler",  ">= 2.3"
  s.add_dependency "dotenv",   "3.1.7"
  s.add_dependency "rake",     "13.2.1"
  s.add_dependency "zeitwerk", "2.6.18"
end
