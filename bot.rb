require 'cinch'
require 'pg'

require_relative "utils.rb"

$bot = Markovirc.new do
  configure do |c|
    c.server = self.set['server']
    c.channels = self.set['channels'].keys.map{ |k| "#"+k }
    c.nick = self.set['nick']
    c.user = self.set['user'] 
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
    msg.connect
    commandHandle command, args, msg
  end
  
  on :message, /^[^!]/ do |msg|
    msg.connect
    logHandle msg
  end

  on :message, /^[^!](.*)/ do |msg, text|
    msg.connect
    speakRandom msg
  end
end

require_relative 'commands.rb'
require_relative 'logic.rb'

$bot.start
