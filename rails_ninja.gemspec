require_relative "lib/rails_ninja/version"

Gem::Specification.new do |spec|
  spec.name = "rails_ninja"
  spec.version = RailsNinja::VERSION
  spec.authors = ["Benjamin Urrutia"]
  spec.summary = "Django Ninja-inspired API framework for Ruby/Rails"
  spec.description = "Define API endpoints with a decorator-like DSL, schema validation, and automatic OpenAPI spec generation."
  spec.homepage = "https://github.com/benjaminurrutia/rails-ninja"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.files = Dir["lib/**/*", "LICENSE.txt"]
  spec.require_paths = ["lib"]

  spec.add_dependency "rack", ">= 2.0"
  spec.add_dependency "multi_json", "~> 1.15"
  spec.add_dependency "mustermann", "~> 3.0"
end
