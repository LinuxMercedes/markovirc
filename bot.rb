require 'cinch'
require 'sqlite3' 

require_relative 'commands.rb'
require_relative 'logic.rb'

$db = SQLite3::Database.open "markovirc.db"

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.freenode.net"
    c.channels = ["##ircbottesting"]
    c.nick = "markovirc"
    c.user = "markovirc"
    
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
