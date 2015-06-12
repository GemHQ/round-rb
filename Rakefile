begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

Bundler::GemHelper.install_tasks

require "rspec/core/rake_task"

RSpec::Core::RakeTask.new

task :default => :spec
task :test => :spec

task :release_checksum do
  require 'digest/sha2'
  built_gem_path = "round-#{Round::VERSION}.gem" 
  checksum = Digest::SHA512.new.hexdigest(File.read(built_gem_path))
  checksum_path = "checksum/#{built_gem_path}.sha512"
  File.open(checksum_path, 'w' ) {|f| f.write(checksum) }
end
