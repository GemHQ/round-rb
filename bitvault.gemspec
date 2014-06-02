Gem::Specification.new do |s|
  s.name = "bitvault"
  s.version = "0.0.1"
  s.license = "MIT"
  s.authors = [
    "Matthew King"
  ]
  s.email = [
    "matthew@pandastrike.com"
  ]
  s.homepage = "https://github.com/bitvault/bitvault-rb"
  s.summary = "Ruby client for the BitVault API"

  s.files = %w[
    LICENSE
    README.md
  ] + Dir["lib/**/*.rb"]
  s.require_path = "lib"

  s.add_dependency("patchboard", "0.4.2")
  s.add_dependency("bitcoin-ruby", "0.0.5")
  s.add_dependency("money-tree", "0.8.6")
  s.add_dependency("rbnacl", "~> 2.0")
  s.add_dependency("coin-op", "0.1.0")

  s.add_development_dependency("starter")
  s.add_development_dependency("hashie", "~> 2.1.1")
  s.add_development_dependency("sequel", "~> 4.8")
  s.add_development_dependency("sqlite3", "~> 1.3")
  s.add_development_dependency("minitest-reporters", "~> 1.0")
  s.add_development_dependency("term-ansicolor")
  s.add_development_dependency("rspec")
  s.add_development_dependency("webmock")
  s.add_development_dependency("vcr")
end

