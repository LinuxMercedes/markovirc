require 'cinch'

class Speak
  include Cinch::Plugin

  match /(speak|unquiet)/, method: :execute

  def execute( m )
    return if m.canSpeak? or m.canRespond? or $bot.set['channels'][m.channel].has_key? '-commands'

    $bot.set['channels'][m.channel].delete 'silent'

    m.reply "OK"
  end

end

