require "starter/tasks/gems"
require "starter/tasks/git"

task "test" => %w[ test:unit ]

task "test:unit" do
  puts "Running unit tests"
  unit_test_files.each do |file|
    sh "ruby #{file}"
  end
end

def unit_test_files
  FileList["test/unit/*.rb"].exclude(/setup.rb$/)
end

def functional_test_files
  FileList["test/functional/*.rb"].exclude(/setup.rb$/)
end

