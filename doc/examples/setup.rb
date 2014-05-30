require "pp"

project_root = File.expand_path("#{File.dirname(__FILE__)}/../../")
$:.unshift "#{project_root}/lib"

require "bitvault"
require "#{project_root}/test/helpers/mockchain"
require "#{project_root}/test/helpers/bitcoin"
require "#{project_root}/test/helpers/testnet_assets"

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
