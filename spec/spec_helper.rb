#API_HOST = 'http://localhost:8999'

require 'pry'
require_relative '../lib/round'
require 'webmock/rspec'
require 'vcr'
require_relative 'helpers/developer'
require_relative 'helpers/auth'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.allow_http_connections_when_no_cassette = true
end

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.include WebMock::API
  config.include Round::TestHelpers::Developer
  config.include Round::TestHelpers::Auth

  config.order = 'random'
end
