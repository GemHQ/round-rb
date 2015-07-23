require_relative 'lib/round/version'

Gem::Specification.new do |s|
  s.name = 'round'
  s.version = Round::VERSION
  s.license = 'MIT'
  s.authors = [
    'Matthew King',
    'Julian Vergel de Dios',
    'James Larisch'
  ]
  s.email = [
    'matthew@pandastrike.com',
    'julian@gem.co',
    'james@gem.co'
  ]
  s.homepage = 'https://github.com/GemHQ/round-rb'
  s.summary = 'Ruby client for the Gem API'
  s.description = 'Gem is a full-stack Bitcoin API that makes it easy to build powerful blockchain apps with beautiful, elegant code.'

  s.files = %w[
    LICENSE
    README.md
  ] + Dir['lib/**/*.rb']
  s.require_path = 'lib'

    # used with gem i coin-op -P HighSecurity
  s.cert_chain  = ["certs/jvergeldedios.pem"]
  # Sign gem when evaluating spec with `gem` command
  #  unless ENV has set a SKIP_GEM_SIGNING
  if ($0 =~ /gem\z/) and not ENV.include?("SKIP_GEM_SIGNING")
    s.signing_key = File.join("/Volumes/IRONKEY/gem-private_key.pem")
  end

  s.add_dependency('patchboard', '~> 0.5')
  s.add_dependency('http', '0.6.0')
  s.add_dependency('rotp', '2.1.0')
  s.add_dependency('rbnacl', '~> 3.1.0')
  s.add_dependency('rbnacl-libsodium', '~> 1.0.0')
  s.add_dependency('coin-op', '0.4.4')

  # RSpec test suite deps
  s.add_development_dependency('rspec', '~> 3.0')
  s.add_development_dependency('webmock', '~> 1.18')
  s.add_development_dependency('vcr', '~> 2.9')
  s.add_development_dependency('pry', '~> 0')
  s.add_development_dependency('rake', '~> 0')

  # Demo script deps
  s.add_development_dependency('term-ansicolor', '~> 1.3')
end
