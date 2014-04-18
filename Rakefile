project_root = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift "#{project_root}/../starter/lib"

require "starter/tasks/gems"
require "starter/tasks/git"
require "starter/markdown/extender"


task "test" => %w[ test:unit ]

task "test:unit" do
  puts "Running unit tests"
  unit_test_files.each do |file|
    sh "ruby #{file}"
  end
end


task "doc" => %w[ doc:readme doc:examples ] do
  doc_files.each do |file|
    extend_markdown(file)
  end
end


task "doc:examples" do
  examples = FileList["doc/examples/*.{rb,py,js,coffee}"]

  examples.each do |path|
    extension = File.extname(path)
    base = File.basename(path)

    text_output = "#{base}.output.txt"

    screen_cap "ruby -I lib #{path}", "./doc/examples/#{base}.png"
    system "ruby -I lib #{path} > ./doc/examples/#{text_output}"
  end
end


task "doc:readme" do
  extend_markdown("doc/raw/README.md", "README.md")
end


task "watch" => "doc:readme" do
  require "filewatcher"
  FileWatcher.new("doc/raw/README.md").watch do |file|
    begin
      extend_markdown(file, "README.md")
    rescue => error
      puts error
    end
  end
end


## Helper methods


def extend_markdown(file, output)
  output ||= file.sub "doc/raw/", "doc/"
  puts "Converted #{file} and wrote to #{output}"

  Starter::Markdown::Extender.process(
    :file => file,
    :output => output
  )
end

def doc_files
  FileList["doc/raw/*.md"].exclude("doc/raw/README.md")
end

def unit_test_files
  FileList["test/unit/*.rb"].exclude(/setup.rb$/)
end

def functional_test_files
  FileList["test/functional/*.rb"].exclude(/setup.rb$/)
end

def screen_cap(command, file)
  # OS X only
  system "clear"
  puts "$ #{command}"
  system command
  system "screencapture -l$(osascript -e 'tell app \"Terminal\" to id of window 1') -o #{file}"
end


