require_relative 'lib/round/version'

Gem::Specification.new do |s|
  s.name = 'round'
  s.version = Round::VERSION
  s.license = 'MIT'
  s.authors = [
    'Matthew King',
    'Julian Vergel de Dios'
  ]
  s.email = [
    'matthew@pandastrike.com',
    'julian@gem.co'
  ]
  s.homepage = 'https://github.com/GemHQ/round-rb'
  s.summary = 'Ruby client for the Gem API'

  s.files = %w[
    LICENSE
    README.md
  ] + Dir['lib/**/*.rb']
  s.require_path = 'lib'
  s.cert_chain = ['certs/jvergeldedios.pem']

  s.add_dependency('patchboard', '~> 0.5.2')
  s.add_dependency('http', '0.6.0')
  s.add_dependency('rbnacl', '~> 3.1.0')
  s.add_dependency('rbnacl-libsodium', '~> 1.0.0')
  s.add_dependency('coin-op', '~> 0.2')

  # RSpec test suite deps
  s.add_development_dependency('rspec', '~> 3.0')
  s.add_development_dependency('webmock', '~> 1.18')
  s.add_development_dependency('vcr', '~> 2.9.3')
  s.add_development_dependency('pry')

  # Demo script deps
  s.add_development_dependency('term-ansicolor', '~> 1.3')
end
