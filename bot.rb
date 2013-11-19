require 'cinch'

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.freenode.org"
    c.channels = ["##test"]
    c.nick = "markovirc"
    c.user = "markovirc"
  end

  on :message, /('?sup|he[y]+|hello)[\s]*([a-z0-9_-]*)/i do |m, greeting, text|
    if text != "" and text != bot.nick
      next
    end
    
    if m.user.nick == "lae"
      m.reply "Hey Musee!"
    else
      m.reply "Hello #{m.user.nick}"
    end
  end
end

bot.start