require 'cinch'

class Speak
  include Cinch::Plugin

  match /(speak|unquiet)/, method: :execute

  def execute( m, word )
    return if m.canSpeak? or m.canRespond?

    channel = $bot.set['channels'][m.channel].delete 'silent'

    m.reply "OK"
  end

end

