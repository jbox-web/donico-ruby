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

  s.required_ruby_version = ">= 3.3.0"

  s.files = Dir[
    "README.md",
    "lib/**/*.rb",
    "lib/**/*.erb",
    "lib/**/*.rake",
    "exe/*",
    "bash/*.sh"
  ]

  s.bindir      = "exe"
  s.executables = ["inspec"]

  s.add_dependency "bundler",  "~> 4.0"
  s.add_dependency "dotenv",   "3.2.0"
  s.add_dependency "rake",     "13.3.1"
  s.add_dependency "zeitwerk", "2.7.5"
end
