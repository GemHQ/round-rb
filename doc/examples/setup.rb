require "pp"
require "uri"
require "yaml"

project_root = File.expand_path("#{File.dirname(__FILE__)}/../../")
$:.unshift "#{project_root}/lib"

require "bitvault"
gem "coin-op", "~> 0.2.0"
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

def bitvault_url
  ARGV[0] || "http://bitvault.pandastrike.com/"
end

def saved_file
  host = URI.parse(bitvault_url).hostname
  "demo-#{host}.yaml"
end

def bitvault
  ## API discovery
  #
  # The BitVault server provides a JSON description of its API that allows
  # the client to generate all necessary resource classes at runtime.
  # We initialize the BitVault client with a block that returns an object
  # that will be used as a "context", a place to store needful things.
  # At present, the only requirement for a context object is that it
  # implements a method named `authorizer`, which must return a credential
  # for use in the HTTP Authorization headers.
  @bitvault ||= begin
    puts "Connecting to #{bitvault_url}"
    BitVault::Client.discover(bitvault_url) { BitVault::Client::Context.new }
  end
end

