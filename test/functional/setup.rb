require_relative "../setup"

gem "minitest"
gem "minitest-reporters"

require "minitest/autorun"
require "minitest/reporters"
Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new()]


