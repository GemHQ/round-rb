API_HOST = 'http://localhost:8999'

require_relative '../lib/bitvault'
require 'webmock/rspec'
require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
end

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.include WebMock::API

  config.before(:each) do
    BitVault::Patchboard.class_variable_set(:@@patchboard, nil)
    namespace = BitVault::Patchboard::Resources
    namespace.constants.select { |c|
      namespace.const_get(c).is_a? Class
    }.each { |c|
      namespace.send(:remove_const, c)
    }
  end

  config.order = 'random'
end