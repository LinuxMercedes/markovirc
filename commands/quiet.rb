require 'cinch'

class Quiet
  include Cinch::Plugin

  match /(shutup|quiet)/, method: :execute

  def execute( m, word )
    return if not m.useCommands?
    return if not m.canSpeak? and not m.canRespond?

    channel = $bot.set['channels'][m.channel] << 'silent'

    m.reply "OK"
  end

end

