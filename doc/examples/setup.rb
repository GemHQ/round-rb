require "pp"

project_root = File.expand_path("#{File.dirname(__FILE__)}/../../")
$:.unshift "#{project_root}/lib"

require "bitvault"
gem "coin-op", "~> 0.1.0"
require "coin-op"

require "term/ansicolor"
String.send :include, Term::ANSIColor

# colored output to make it easier to see structure
def log(message, data=nil)
  if data.is_a? String
    puts "#{message.yellow} => #{data.dump.cyan}"
  elsif data.nil?
    puts "#{message.yellow}"
  else
    begin
      puts "#{message.yellow} => #{JSON.pretty_generate(data).cyan}"
    rescue
      puts "#{message.yellow} => #{data.inspect.cyan}"
    end
  end
  puts
end

def mask(hash, *keys)
  out = {}
  keys.each do |key|
    out[key] = hash[key]
  end
  out[:etc] = "..."
  out
end

