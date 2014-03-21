require "pp"

project_root = File.expand_path("#{File.dirname(__FILE__)}/../")
$:.unshift "/Users/matthew/projects/oss/patchboard-rb/lib"
$:.unshift "#{project_root}/lib"

require "bitvault"
require_relative "helpers/mockchain.rb"

