require 'cinch'

class Quiet
  include Cinch::Plugin

  match /(shutup|quiet)/, method: :execute

  def execute( m )
    return if not m.useCommands?
    return if not m.canSpeak? and not m.canRespond?

    $bot.set['channels'][m.channel] << 'silent'

    m.reply "OK"
  end

end

