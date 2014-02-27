require 'cinch'
require 'sqlite3' 

require_relative "utils.rb"

$set = Settings.new
$db = SQLite3::Database.open "markovirc.db"

require_relative 'commands.rb'
require_relative 'logic.rb'

bot = Cinch::Bot.new do
  configure do |c|
    c.server = $set['server']
    c.channels = $set['channels'].keys.map{ |k| "#"+k }
    c.nick = $set['nick']
    c.user = $set['user'] 
  end

  on :message, /^('?sup|he[y]+|hello|hi)[\s]*([a-z0-9_-]*)?/i do |m, greeting, text|
    if text != "" and text != bot.nick
      next
    end
    
    if m.user.nick == "lae"
      m.reply "Hey Musee!"
    elsif m.user.nick == 'brodes'
      m.reply "/xe/ billy!"
    else
      m.reply "Hello #{m.user.nick}"
    end
  end

  on :message, /^!([a-z]*)(.*)/i do |msg, command, args|
    commandHandle command, args, msg
  end
  
  on :message, /^[^!]/ do |msg|
    logHandle $db, msg
  end

  # This won't respond to pings to markovirc
  on :message, /^(?!#{$set['nick']}[:,])|[^!]/ do |msg|
    speakRandom msg
  end

  on :message, /#{$set['nick']}[:,\.]/ do |msg|
    speakRandom msg, true
  end
end

bot.start
