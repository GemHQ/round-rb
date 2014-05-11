require_relative "../setup"

require "term/ansicolor"
String.send :include, Term::ANSIColor

# colored output to make it easier to see structure
def log(message, data)
  if data.is_a? String
    puts "#{message.yellow.underline} => #{data.dump.cyan}"
  else
    begin
      puts "#{message.yellow.underline} => #{JSON.pretty_generate(data).cyan}"
    rescue
      puts "#{message.yellow.underline} => #{data.inspect.cyan}"
    end
  end
  puts
end

## plain output for gisting
#def log(message, data)
  #begin
    #puts "#{message} ---\n#{JSON.pretty_generate data}"
  #rescue
    #puts "#{message} ---\n#{data}"
  #end
  #puts
#end

