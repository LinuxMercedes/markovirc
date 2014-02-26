require 'cinch'
require 'sqlite3' 

require_relative "utils.rb"
require_relative 'commands.rb'
require_relative 'logic.rb'

$db = SQLite3::Database.open "markovirc.db"

bot = Cinch::Bot.new do
  configure do |c|
    $set = Settings.new

    c.server = $set['server']
    c.channels = $set['channels'].keys.map{ |k| "#"+k }
    c.nick = $set['nick']
    c.user = $set['user']
    
    c.delimeter = "!"
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
  
  on :message, /^[A-Za-z0-9]/ do |msg|
    logHandle $db, msg
  end
end

bot.start
