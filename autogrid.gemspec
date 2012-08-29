$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "autogrid/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "autogrid"
  s.version     = Autogrid::VERSION
  s.authors     = ["Christopher Thornton"]
  s.email       = ["rmdirbin@gmail.com"]
  s.homepage    = "https://github.com/cgthornt/autogrid"
  s.summary     = "Autogrid automatically creates grids for your models"
  s.description = "Want an easy way to create data grids? Now you can easily with autogrid!"

  s.files = Dir["{app,lib,vendor}/**/*"] + ["Rakefile", "README.md"]

  s.add_dependency "rails", "~> 3.2.8"
  s.add_dependency "jquery-datatables-rails", "~> 1.10.0"

  s.add_development_dependency "sqlite3"
end
